-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Omarchy binds SUPER+ALT+1..5 to the first five windows in a tab group.
-- Extend that to 9; SUPER+ALT+6..9 are otherwise unbound. The keycodes match
-- upstream's own loop (code:10 is the "1" key), so these stay on the physical
-- number row regardless of the active xkb layout.
for index = 6, 9 do
  o.bind(
    "SUPER + ALT + code:" .. tostring(index + 9),
    "Switch to group window " .. index,
    hl.dsp.group.active({ index = index })
  )
end

-- Explicit splits, the way iTerm2's Cmd+D works. The dwindle layout picks the
-- split direction from the focused window's aspect ratio, so the same key
-- splits sideways next to a wide window and downwards next to a tall one.
-- preselect overrides that for the next window only, which puts the direction
-- back in the hands of the key being pressed.
-- A split is only even once the new window exists, and the terminal is
-- launched asynchronously, so the split bindings arm this and window.open
-- below acts on it.
local balance_next_window = false

local function split_into_terminal(direction)
  return function()
    hl.dispatch(hl.dsp.layout("preselect " .. direction))
    balance_next_window = true
    -- Disarm if the terminal never arrives, so an unrelated window opening
    -- later does not rearrange the screen out of nowhere.
    hl.timer(function()
      balance_next_window = false
    end, { timeout = 5000, type = "oneshot" })
    -- The same launcher SUPER+RETURN uses, so this follows the configured
    -- terminal and opens in the active terminal's directory.
    hl.dispatch(hl.dsp.exec_cmd("omarchy-launch-terminal"))
  end
end

-- SUPER+SHIFT+D was Omarchy's Docker TUI. It moves to SUPER+ALT+D below, and
-- is reachable from the Omarchy menu either way.
hl.unbind("SUPER + SHIFT + D")

o.bind("SUPER + D", "Split right into a terminal", split_into_terminal("r"))
o.bind("SUPER + SHIFT + D", "Split down into a terminal", split_into_terminal("d"))
o.bind("SUPER + ALT + D", "Docker", { tui = "omarchy-launch-docker-tui" })

-- Balance the tiled windows, the way bspwm's balance and yabai's --balance do.
-- Dwindle halves the focused window on every split, so a third window leaves
-- the first holding half the screen.
--
-- Hyprland has no layout message for this, and the tree that would say which
-- split wants what is not exposed anywhere: not through hyprctl, not on a
-- client, and a window's .layout carries nothing but the layout's name.
-- Geometry cannot stand in for it either, because three windows in a row look
-- identical whether the tree reads (A|B)|C or A|(B|C).
--
-- So each split is asked. Nudging a window along one axis moves exactly the
-- windows under the nearest split on that axis, and moves the two sides in
-- opposite directions, which names the node and both its children at once.
-- Resizing is what reaches them: splitratio only ever moves the split its
-- window sits directly inside, so it cannot see a node whose children are both
-- interior, while a resize walks up to the nearest split that lies along the
-- axis asked for. Every nudge is taken straight back, and Hyprland reports
-- geometry as soon as a dispatch returns rather than when its animation ends,
-- so none of this reaches the screen.
-- With no argument every split on the workspace is evened out. Given a window,
-- only the splits that window sits under are touched, and only for as far up
-- as they keep running the same way as the one it was just put into. Splitting
-- a column in two says nothing about how wide that column should be, so the
-- splits across the row are left exactly as they were found.
local function balance_tiled_windows(scope)
  local workspace = hl.get_active_workspace()
  if not workspace then
    return
  end

  local tiled = {}
  local count = 0
  for _, window in ipairs(hl.get_windows()) do
    if window.mapped
      and not window.floating
      and window.fullscreen == 0
      and window.workspace
      and window.workspace.id == workspace.id
    then
      tiled[window.address] = true
      count = count + 1
    end
  end
  if count < 2 then
    return
  end

  local function snapshot()
    local boxes = {}
    for _, window in ipairs(hl.get_windows()) do
      if tiled[window.address] then
        boxes[window.address] = {
          x = window.at.x,
          y = window.at.y,
          w = window.size.x,
          h = window.size.y,
        }
      end
    end
    return boxes
  end

  local function nudge(address, extent, pixels)
    hl.dispatch(hl.dsp.focus({ window = "address:" .. address }))
    if extent == "w" then
      hl.dispatch(hl.dsp.window.resize({ x = pixels, y = 0, relative = true }))
    else
      hl.dispatch(hl.dsp.window.resize({ x = 0, y = pixels, relative = true }))
    end
  end

  local probe = 60
  local baseline = snapshot()
  local focused = hl.get_active_window()
  local nodes, order = {}, {}

  for address in pairs(tiled) do
    for _, extent in ipairs({ "w", "h" }) do
      nudge(address, extent, probe)
      local nudged = snapshot()
      nudge(address, extent, -probe)

      -- A positive nudge grows the split's first child, so the windows that
      -- grew are one child of it and the ones that shrank are the other.
      local grew, shrank, members = {}, {}, {}
      for member, was in pairs(baseline) do
        if nudged[member][extent] > was[extent] then
          grew[#grew + 1] = member
          members[#members + 1] = member
        elseif nudged[member][extent] < was[extent] then
          shrank[#shrank + 1] = member
          members[#members + 1] = member
        end
      end

      if #grew > 0 and #shrank > 0 then
        table.sort(members)
        local key = extent .. ":" .. table.concat(members, ",")
        if not nodes[key] then
          nodes[key] = {
            grew = grew,
            shrank = shrank,
            extent = extent,
            position = extent == "w" and "x" or "y",
            anchor = address,
          }
          order[#order + 1] = key
        end
      end
    end
  end

  if scope then
    -- Ancestors of a window are nested, so ordering the splits it sits under by
    -- how many windows they hold walks outwards from the one holding it.
    local ancestors = {}
    for _, key in ipairs(order) do
      local node = nodes[key]
      local holds = false
      for _, side in ipairs({ node.grew, node.shrank }) do
        for _, member in ipairs(side) do
          if member == scope then
            holds = true
          end
        end
      end
      if holds then
        ancestors[#ancestors + 1] = {
          key = key,
          size = #node.grew + #node.shrank,
          extent = node.extent,
        }
      end
    end
    table.sort(ancestors, function(a, b) return a.size < b.size end)

    -- Walking out while the splits keep running the same way finds how far the
    -- run of them reaches: that is the row, or the column, the window landed
    -- in, and its outermost split holds everything the run covers.
    local axis = ancestors[1] and ancestors[1].extent
    local container
    for _, ancestor in ipairs(ancestors) do
      if ancestor.extent ~= axis then
        break
      end
      container = nodes[ancestor.key]
    end

    order = {}
    if container then
      local inside = {}
      for _, side in ipairs({ container.grew, container.shrank }) do
        for _, member in ipairs(side) do
          inside[member] = true
        end
      end
      -- Every split running that way anywhere inside it, not only the ones
      -- directly above the new window: a row is only even if all of it is.
      for key, node in pairs(nodes) do
        if node.extent == axis then
          local contained = true
          for _, side in ipairs({ node.grew, node.shrank }) do
            for _, member in ipairs(side) do
              if not inside[member] then
                contained = false
              end
            end
          end
          if contained then
            order[#order + 1] = key
          end
        end
      end
    end
  end

  -- Which windows belong to which split does not change as splits move, but
  -- where they are does, and a resize is asked for in pixels rather than in
  -- shares. So each correction is measured against the layout as it stands at
  -- that moment, not against the snapshot the probing was done on.
  for _, key in ipairs(order) do
    local node = nodes[key]
    local current = snapshot()
    local extent, position = node.extent, node.position
    local node_start, node_end = math.huge, -math.huge
    for _, side in ipairs({ node.grew, node.shrank }) do
      for _, member in ipairs(side) do
        local box = current[member]
        node_start = math.min(node_start, box[position])
        node_end = math.max(node_end, box[position] + box[extent])
      end
    end
    local first_end = -math.huge
    for _, member in ipairs(node.grew) do
      local box = current[member]
      first_end = math.max(first_end, box[position] + box[extent])
    end

    local span = node_end - node_start
    if span > 0 then
      local share = #node.grew / (#node.grew + #node.shrank)
      local wanted = math.floor(node_start + span * share + 0.5)
      local move = wanted - first_end
      -- Pixel geometry cannot express a share more exactly than this, and a
      -- nudge smaller than the borders it moves is not worth the dispatch.
      if math.abs(move) > 2 then
        nudge(node.anchor, extent, move)
      end
    end
  end

  if focused then
    hl.dispatch(hl.dsp.focus({ window = "address:" .. focused.address }))
  end
end

o.bind("SUPER + B", "Balance the tiled windows", balance_tiled_windows)

-- Geometry is already final when this fires -- the window arrives tiled and
-- placed -- so the layout can be evened out on the spot.
hl.on("window.open", function(window)
  if balance_next_window then
    balance_next_window = false
    local opened = window.address
    -- The new window arrives tiled and placed, but the windows it displaced
    -- have not all been given their new geometry yet, and balancing on stale
    -- sizes lands short. One turn of the event loop is enough.
    hl.timer(function()
      balance_tiled_windows(opened)
    end, { timeout = 50, type = "oneshot" })
  end
end)


