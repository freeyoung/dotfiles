#version 440

// A ring of light running clockwise around a rounded rectangle, drawn inside
// the item's bounds. The light is iTerm2's indeterminate progress gradient --
// alpha 0, .5, 1, 1, .5, 0 at even stops -- laid along the outline instead of
// across a bar. One light of LIGHT_SHARE of the perimeter runs round it, and
// the rest of the ring is dark; a full turn takes one run of `phase` from 0
// to 1.
//
// It was 2 lights, each half the perimeter, which left the ring lit end to end.
// A light that grows with the shape it runs on reads as slow however fast it
// goes, the more so on a window outline, which is long. The tab light of the
// Ghostty build in the same setup was changed the same way and for the same
// reason.
//
// Position along the outline is measured by perimeter, not by angle, so the
// light keeps an even pace on a tab that is fifty times wider than it is tall.
//
// Compile with build.sh beside this file, on a host that has Qt 6, and commit
// the blob it writes along with this: a stale blob is a change that does nothing.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float radius;
    float thickness;
    float phase;
    float baseAlpha;
    vec4 ringColor;
};

// How much of the outline the light covers. A quarter leaves three quarters
// dark, which is what makes it read as something running.
const float LIGHT_SHARE = 0.25;

float profile(float v) {
    float x = clamp(v, 0.0, 1.0) * 5.0;
    if (x < 1.0) return 0.5 * x;
    if (x < 2.0) return 0.5 + 0.5 * (x - 1.0);
    if (x < 3.0) return 1.0;
    if (x < 4.0) return 1.0 - 0.5 * (x - 3.0);
    return 0.5 - 0.5 * (x - 4.0);
}

void main() {
    vec2 q = qt_TexCoord0 * itemSize - itemSize * 0.5;
    vec2 halfExtent = max(itemSize * 0.5 - vec2(thickness * 0.5), vec2(0.5));
    float r = min(radius, min(halfExtent.x, halfExtent.y));

    // Signed distance to the rounded rectangle through the middle of the stroke.
    vec2 k = abs(q) - (halfExtent - vec2(r));
    float d = length(max(k, 0.0)) + min(max(k.x, k.y), 0.0) - r;
    float aa = max(fwidth(d), 0.0001);
    float stroke = 1.0 - smoothstep(thickness * 0.5 - aa, thickness * 0.5 + aa, abs(d));

    // Distance along the outline, clockwise from the top-left corner.
    float hx = halfExtent.x;
    float hy = halfExtent.y;
    float s;
    if (hy - abs(q.y) < hx - abs(q.x)) {
        s = q.y < 0.0 ? (q.x + hx) : (3.0 * hx + 2.0 * hy - q.x);
    } else {
        s = q.x > 0.0 ? (2.0 * hx + hy + q.y) : (4.0 * hx + 3.0 * hy - q.y);
    }
    float t = s / (4.0 * (hx + hy));

    // 0 at the head of the light, 1 at the tail of it, dark behind that.
    float along = fract(t - phase) / LIGHT_SHARE;
    float glow = along < 1.0 ? profile(along) : 0.0;
    float a = stroke * max(baseAlpha, glow) * ringColor.a * qt_Opacity;
    fragColor = vec4(ringColor.rgb * a, a);
}
