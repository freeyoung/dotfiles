#version 440

// A ring of light running clockwise around a rounded rectangle, drawn inside
// the item's bounds. The light is iTerm2's indeterminate progress gradient --
// alpha 0, .5, 1, 1, .5, 0 at even stops -- laid along the outline instead of
// across a bar: two copies, each half the perimeter long, end to end, so the
// ring is never dark and a full turn takes one run of `phase` from 0 to 1.
//
// Position along the outline is measured by perimeter, not by angle, so the
// light keeps an even pace on a tab that is fifty times wider than it is tall.
//
// Compile with: /usr/lib/qt6/bin/qsb --glsl "150,330,300 es" -o ring.frag.qsb ring.frag

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

    float glow = profile(fract(2.0 * (t - phase)));
    float a = stroke * max(baseAlpha, glow) * ringColor.a * qt_Opacity;
    fragColor = vec4(ringColor.rgb * a, a);
}
