// The Ghostty half of what kitty does in Python: it keeps the splits equal and
// it shows what each Claude Code session is doing, in the only per-tab thing a
// script can change -- the tab title.
//
// 1. Equal splits. Ghostty equalizes when a split opens, because the keybinds
//    in config chain equalize_splits onto new_split, but not when one closes:
//    the freed space goes to the sibling alone. A chain cannot do it, because
//    the chain stops with the surface it ran in, and Ghostty has no event API.
//    Only a tab that lost a surface is equalized, so a tab someone sized by
//    hand is left alone.
//
// 2. A badge on the tab. ring.glsl draws a ring around a working pane, but a
//    pane is only visible while its tab is, and the tab bar is a macOS control
//    no shader reaches. So the tab title gets a badge: a spinner while the
//    model works, a blinking blue dot while a prompt waits to be answered, a
//    green dot when the turn is done. A title set through set_tab_title
//    overrides the one the program in the pane sets, so Claude's own title
//    does not wipe it out; the badge goes in front of that title, read back
//    from the surface.
//
// cc-status writes 1 record per session, naming the terminal it runs in. This
// only reads them. One process polls, so nothing is spawned per tick.
//
// Every question asked of Ghostty is an Apple event, and they are not cheap:
// walking the windows costs about 80 ms and reading a title about 15 ms, while
// setting a title through a reference already in hand costs about 15 ms. So
// the walk is rare, the references and titles it finds are kept, and a frame
// of the spinner is 1 call against a kept reference.
//
// install loads it through ~/Library/LaunchAgents/com.eric.ghostty-agent.plist.
ObjC.import('Foundation');
ObjC.bindFunction('kill', ['int', ['int', 'int']]);

const FRAME_INTERVAL = 0.3;    // the loop, and 1 frame of the spinner, while there is something to watch
const QUIET_INTERVAL = 1.5;    // the loop while Ghostty is in front with no split and no session
const IDLE_INTERVAL = 2.0;     // the loop while Ghostty is not in front
const WALK_INTERVAL = 2.0;     // how often the whole tree is walked anyway, for titles
const IDLE_WALK_INTERVAL = 8.0;
const BLINK_SECONDS = 0.5;
const SPINNER = ['◐', '◓', '◑', '◒'];
const WAITING_BADGE = ['🔵', '⚪'];
const IDLE_BADGE = '🟢';
const PRIORITY = { waiting: 0, working: 1, idle: 2 };
const BADGES = SPINNER.concat(WAITING_BADGE, [IDLE_BADGE]);
// Claude Code puts its own glyph before the title. The badge replaces it.
const LEADING_GLYPH = /^[\s◐◑◒◓✳✻✶✽✢·⏺]+/;
// The title cc-status gives a pane for a moment, to find out which terminal it
// is. A tab is never labelled with it: the session's directory is used instead.
const MARKER = /^\u27e6claude [0-9a-f]+\u27e7$/;

const app = Application('Ghostty');
const environment = $.NSProcessInfo.processInfo.environment;
const temporary = environment.objectForKey('TMPDIR') ? ObjC.unwrap(environment.objectForKey('TMPDIR')) : '/tmp';
const stateDir = $.NSString.stringWithString(temporary + '/claude-ghostty');

let tabsWithSession = []; // { tabId, terminal, title, state } for each tab that has a session
let painted = {};         // tab id -> the title this agent last wrote
let walkedAt = 0;

function records() {
  const names = $.NSFileManager.defaultManager.contentsOfDirectoryAtPathError(stateDir, $());
  if (!names.js) return [];
  const out = [];
  for (const entry of ObjC.unwrap(names)) {
    // The entries come back as ObjC strings, which have no JavaScript methods.
    const name = String(ObjC.unwrap(entry));
    if (!name.endsWith('.json')) continue;
    const path = ObjC.unwrap(stateDir.stringByAppendingPathComponent(name));
    const text = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, $());
    if (!text.js) continue;
    let record;
    try {
      record = JSON.parse(ObjC.unwrap(text));
    } catch (e) {
      continue;
    }
    // A session that was killed leaves its record behind, and its badge would
    // never go away.
    if (record.pid && $.kill(record.pid, 0) !== 0) {
      $.NSFileManager.defaultManager.removeItemAtPathError(path, $());
      continue;
    }
    if (record.terminal && PRIORITY[record.state] !== undefined) out.push(record);
  }
  return out;
}

function signature(sessions) {
  return sessions.map((r) => r.terminal + ':' + r.state).sort().join(',');
}

function walk(sessions) {
  const byTerminal = {};
  for (const record of sessions) byTerminal[record.terminal] = record;

  // 1 Apple event each, rather than 1 per window, tab and terminal: asking for
  // a property of a whole specifier costs about 18 ms, where walking the same
  // tree object by object costs about 80 ms.
  const terminalIds = app.windows.tabs.terminals.id();
  const tabIds = app.windows.tabs.id();

  const found = [];
  const seen = {};
  const wanted = [];  // [windowIndex, tabIndex, terminalIndex] of each tab with a session
  for (let w = 0; w < tabIds.length; w++) {
    for (let t = 0; t < tabIds[w].length; t++) {
      const tabId = tabIds[w][t];
      const ids = terminalIds[w][t];
      let best = null;
      let bestIndex = -1;
      for (let i = 0; i < ids.length; i++) {
        const record = byTerminal[ids[i]];
        if (!record) continue;
        if (!best || PRIORITY[record.state] < PRIORITY[best.state]) {
          best = record;
          bestIndex = i;
        }
      }
      if (best) {
        seen[tabId] = true;
        wanted.push([w, t, bestIndex, tabId, best]);
      }
    }
  }

  // The titles are needed only for the tabs that carry a session, and the tab
  // titles only to recognise a badge this agent did not write itself.
  const names = wanted.length ? app.windows.tabs.terminals.name() : null;
  const tabNames = Object.keys(painted).length || wanted.length ? app.windows.tabs.name() : null;
  for (const [w, t, i, tabId, record] of wanted) {
    const name = String(names[w][t][i]);
    found.push({
      tabId: tabId,
      at: [w, t, i],
      title: MARKER.test(name) ? (record.cwd || '') : name.replace(LEADING_GLYPH, '').trim(),
      state: record.state,
    });
  }
  if (tabNames) {
    for (let w = 0; w < tabIds.length; w++) {
      for (let t = 0; t < tabIds[w].length; t++) {
        const tabId = tabIds[w][t];
        if (seen[tabId] || !terminalIds[w][t].length) continue;
        // Only a title this agent wrote is taken back. A badge is recognised by
        // its first character as well, because a restarted agent has forgotten
        // what it wrote and would otherwise leave the old badge on the tab.
        if (painted[tabId] === undefined && !ours(tabNames[w][t])) continue;
        app.performAction('set_tab_title:', { on: terminal([w, t, 0]) });
        delete painted[tabId];
      }
    }
  }
  for (const tabId of Object.keys(painted)) if (!seen[tabId]) delete painted[tabId];
  tabsWithSession = found;
}

function terminal(at) {
  return app.windows[at[0]].tabs[at[1]].terminals[at[2]];
}

function shape() {
  // The cheapest question that still shows a split closing: 1 Apple event for
  // every terminal id in the application, about 18 ms, against about 50 ms for
  // the walk that also reads the tab ids and the titles.
  return app.windows.tabs.terminals.id().map((window) => window.map((tab) => tab.length));
}

function dropped(before, after) {
  // Positions shift when a tab or a window opens or closes, and then the walk
  // that follows re-reads everything anyway, so only a like-for-like drop counts.
  const out = [];
  if (before.length !== after.length) return out;
  for (let w = 0; w < after.length; w++) {
    if (before[w].length !== after[w].length) return [];
    for (let t = 0; t < after[w].length; t++) {
      if (after[w][t] < before[w][t]) out.push([w, t, 0]);
    }
  }
  return out;
}

function ours(title) {
  return BADGES.some((glyph) => String(title).startsWith(glyph));
}

function badge(state, now) {
  if (state === 'working') return SPINNER[Math.floor(now / FRAME_INTERVAL) % SPINNER.length];
  if (state === 'waiting') return WAITING_BADGE[Math.floor(now / BLINK_SECONDS) % WAITING_BADGE.length];
  return IDLE_BADGE;
}

function paint(now) {
  const alive = [];
  for (const tab of tabsWithSession) {
    const title = (badge(tab.state, now) + ' ' + tab.title).trim();
    if (painted[tab.tabId] === title) {
      alive.push(tab);
      continue;
    }
    try {
      app.performAction('set_tab_title:' + title, { on: terminal(tab.at) });
      painted[tab.tabId] = title;
      alive.push(tab);
    } catch (e) {
      // The pane this reference named has closed. The next walk finds what
      // replaced it; dropping it here keeps the rest of the tabs painted.
      delete painted[tab.tabId];
      walkedAt = 0;
    }
  }
  tabsWithSession = alive;
}

let previousShape = [];
let previousSignature = '';
while (true) {
  // Asking a Ghostty that is not running would start it.
  if (!app.running()) {
    previousShape = [];
    painted = {};
    tabsWithSession = [];
    delay(IDLE_INTERVAL);
    continue;
  }
  let front = false;
  try {
    front = app.frontmost();
  } catch (e) {
    front = false;
  }
  const now = Date.now() / 1000;
  const sessions = records();
  const changed = signature(sessions) !== previousSignature;
  try {
    const current = shape();
    for (const at of dropped(previousShape, current)) {
      app.performAction('equalize_splits', { on: terminal(at) });
      console.log('equalized window ' + at[0] + ' tab ' + at[1]);
      walkedAt = 0;
    }
    const structural = JSON.stringify(current) !== JSON.stringify(previousShape);
    previousShape = current;
    if (changed || structural || now - walkedAt >= (front ? WALK_INTERVAL : IDLE_WALK_INTERVAL)) {
      walk(sessions);
      walkedAt = now;
      previousSignature = signature(sessions);
    }
  } catch (e) {
    // A pane can close while its window is being asked about, and then a
    // reference in hand names something that is gone. macOS also asks once for
    // permission to control Ghostty, and until it is given every call fails
    // here. Either way the next tick starts over.
    console.log('ghostty-agent: ' + e);
    previousShape = [];
    walkedAt = 0;
    delay(front ? FRAME_INTERVAL : IDLE_INTERVAL);
    continue;
  }
  paint(now);
  // Ghostty is asked whether it is in front, rather than NSWorkspace, which
  // reports the front application of its own session: from a launch agent that
  // is never Ghostty, and the poll would always be the slow one.
  //
  // The fast loop is only worth its Apple events when there is something to
  // watch: a tab with a split in it, which can be closed, or a session, whose
  // badge moves. A window of single-pane tabs costs almost nothing.
  const watching = previousShape.some((w) => w.some((count) => count > 1)) || sessions.length > 0;
  delay(front ? (watching ? FRAME_INTERVAL : QUIET_INTERVAL) : IDLE_INTERVAL);
}
