// A ring of light around a terminal surface that shows what a Claude Code
// session is doing, the way iTerm2 3.7 rings the tab of a working session.
//
// A shader cannot know what a session is doing, so the hook tells it through
// the palette: it sets color 255 with OSC 4, and this reads iPalette[255].
// The palette is per surface, so 1 shader serves every split, and color 255 is
// the last grayscale slot, which no program draws with in practice.
//
//   #00ff01  working  a light runs around the outline, 1 turn every 3 seconds
//   #0000fe  waiting  the whole outline pulses, twice a second
//   anything else     no ring
//
// The light is iTerm2's indeterminate progress gradient -- alpha 0, .5, 1, 1,
// .5, 0 -- in 2 copies laid end to end, as in omarchy/quickshell/claude-rings.

const vec3 WORKING = vec3(0.0, 1.0, 1.0 / 255.0);
const vec3 WAITING = vec3(0.0, 0.0, 254.0 / 255.0);
const vec3 WORKING_COLOR = vec3(0.0, 1.0, 0.0);
const vec3 WAITING_COLOR = vec3(0.37, 0.53, 1.0);
const float THICKNESS = 3.0;
const float TURN = 3.0;
const float PULSE = 2.0;

float profile(float v) {
    float x = clamp(v, 0.0, 1.0) * 5.0;
    if (x < 1.0) return 0.5 * x;
    if (x < 2.0) return 0.5 + 0.5 * (x - 1.0);
    if (x < 3.0) return 1.0;
    if (x < 4.0) return 1.0 - 0.5 * (x - 3.0);
    return 0.5 - 0.5 * (x - 4.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    vec3 marker = iPalette[255];
    bool working = distance(marker, WORKING) < 0.01;
    bool waiting = distance(marker, WAITING) < 0.01;
    if (!working && !waiting) return;

    vec2 fromEdge = min(fragCoord, iResolution.xy - fragCoord);
    float edge = min(fromEdge.x, fromEdge.y);
    if (edge > THICKNESS) return;

    float alpha;
    vec3 color;
    if (working) {
        // Distance along the outline, so the light keeps an even pace on every edge.
        float w = iResolution.x;
        float h = iResolution.y;
        float s;
        if (fromEdge.x < fromEdge.y) {
            s = fragCoord.x < w * 0.5 ? (h - fragCoord.y) : (w + h + fragCoord.y);
        } else {
            s = fragCoord.y > h * 0.5 ? (h + fragCoord.x) : (2.0 * h + w + (w - fragCoord.x));
        }
        alpha = profile(fract(2.0 * (s / (2.0 * (w + h)) - fract(iTime / TURN))));
        color = WORKING_COLOR;
    } else {
        alpha = 0.35 + 0.65 * (0.5 + 0.5 * sin(6.2831853 * iTime / PULSE));
        color = WAITING_COLOR;
    }

    alpha *= smoothstep(THICKNESS, THICKNESS - 1.5, edge);
    fragColor = vec4(mix(fragColor.rgb, color, alpha), fragColor.a);
}
