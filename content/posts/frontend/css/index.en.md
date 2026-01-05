---
weight: 2
title: "CSS Practical Guide"
date: 2023-02-06T22:12:56+08:00
lastmod: 2023-02-06T22:12:56+08:00
draft: false
author: "Mohan Li"
images: []
resources:
  - name: "featured-image"
    src: "cover.png"

tags: ["frontend", "working notes"]
categories: ["frontend"]

lightgallery: true

toc:
  auto: false
---

I wrote a CSS quick reference and principles note: from the box model, positioning and document flow, to BFC, layout schemes, performance optimization, and engineering.

<!--more-->

# CSS Knowledge System · More Practical, Clearer Notes

---

## 1) Box Model

**Two kinds of box models:**

| Mode           | `box-sizing`            | Meaning of the specified `width/height` | Actual footprint (total width/height)                         |
| -------------- | ----------------------- | --------------------------------------- | ------------------------------------------------------------- |
| Standard model | `content-box` (default) | `content` only                          | `content + padding + border (+ margin)`                       |
| IE box model   | `border-box`            | `content + padding + border`            | `specified value (already includes padding/border)(+ margin)` |

**Global recommendation: switch all elements to `border-box` for easier sizing:**

```css
*,
*::before,
*::after {
  box-sizing: border-box;
}
```

---

## 2) Document Flow & “Out of Flow”

- **Normal Flow**: block-level from top to bottom; inline from left to right.
- **Float `float`**: element **leaves normal flow**, but still affects text wrapping; parent height may collapse.
- **Absolute positioning `position: absolute`**: fully out of normal flow; **positioned relative to the nearest positioned (non-`static`) ancestor**, or to `html` if none is found.
- **Fixed positioning `position: fixed`**: positioned relative to the **viewport**, does not move on scroll.
- **Sticky positioning `position: sticky`**: behaves as `relative` before threshold, then “sticks” inside the container after threshold.

> `position: static` (default) does not participate in positioning; **`top/left` etc. have no effect on `static`**.

---

## 3) Pseudo-classes & Pseudo-elements

### Pseudo-classes (**single colon** `:`)

Used to select elements in **specific states**:

- Link states: `a:link / :visited / :hover / :active`
- Structural: `:first-child / :last-child / :nth-child(n) / :nth-of-type(n)`
- Interaction: `:focus / :focus-visible / :target / :disabled / :checked`
- Selection helpers: `:not(...) / :is(...) / :where(...)` (`where` does not increase specificity)

### Pseudo-elements (**double colon** `::`)

Used to select **specific parts** of elements or **generate content**:

- `::before / ::after` (often with `content` for decoration)
- `::first-line / ::first-letter`
- `::placeholder` input placeholder
- `::selection` selected text style

---

## 4) Common Centering Methods

### Text horizontal/vertical centering (single line)

```css
.text-center {
  text-align: center; /* horizontal */
  line-height: 40px;
  height: 40px; /* vertical for single-line text */
}
```

### Center any element horizontally & vertically (modern first choice)

**Flex:**

```css
.center {
  display: flex;
  justify-content: center;
  align-items: center;
}
```

**Grid:**

```css
.center {
  display: grid;
  place-items: center; /* equals align-items + justify-items */
}
```

**Absolute positioning (works for unknown size too):**

```css
.center {
  position: absolute;
  inset: 0;
  margin: auto; /* needs constraints other than max-content or child has size */
}
/* or */
.center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}
```

---

## 5) Differences in Hiding Elements

| Method               | Takes space | Clickable/Focusable  | Read by screen readers | Typical use                           |
| -------------------- | ----------- | -------------------- | ---------------------- | ------------------------------------- |
| `display: none`      | ❌ No       | ❌                   | Usually ❌             | Remove from layout/accessibility tree |
| `visibility: hidden` | ✅ Yes      | ❌                   | Usually ❌             | Invisible but keeps space             |
| `opacity: 0`         | ✅ Yes      | ✅ (still clickable) | ✅                     | Visual-only hide, keeps interaction   |

> If you need hidden **and non-clickable**, prefer `display: none` or `visibility: hidden`. For fade animations, use `opacity`.

---

## 6) BFC (Block Formatting Context)

**BFC is an independent layout environment**: the layout of its inner elements **does not affect** the outside.

**Common triggers:**

- Float: `float` not `none`
- Positioning: `position: absolute/fixed`
- `overflow` not `visible` (e.g., `hidden/auto/scroll`)
- Specific `display`: `inline-block / table-cell / table-caption / flow-root / flex / inline-flex / grid / inline-grid`
- `contain: layout;` (modern)

**Roles & use cases:**

- **Clear internal floats** (parent height includes floating children)
- **Prevent margin collapsing**
- **Adaptive multi-column layouts** (BFC does not overlap floats)

**Recommended ways to clear floats:**

```css
/* Modern: BFC directly */
.parent {
  overflow: auto;
} /* or display: flow-root; */

/* Classic clearfix */
.parent::after {
  content: "";
  display: table;
  clear: both;
}
```

---

## 7) Responsive & Adaptive Solutions

### Percentage-based layout

- Width/height scale relative to container; note `padding` percentages are **calculated against width**.

### Media queries `@media`

```css
@media (max-width: 768px) {
  ...;
}
```

### Viewport units `vh/vw` (and `svh/dvh` to adapt mobile safe-area changes)

```css
.hero {
  min-height: 100svh;
}
```

### `rem` & fluid typography

- `1rem` = root element’s `font-size`.
- **Fluid typography** (recommended):

```css
html {
  font-size: clamp(14px, 1.6vw, 18px);
}
```

### Container queries (modern browsers)

Switch styles based on **container width** instead of viewport:

```css
.container {
  container-type: inline-size;
}
@container (min-width: 600px) {
  ...;
}
```

---

## 8) Unit Comparison: `px / em / rem / vw / vh` (plus `ch / ex`)

- `px`: absolute pixels (affected by zoom)
- `em`: relative to the **current or parent** `font-size` (cascades)
- `rem`: relative to the **root element** `font-size` (globally controllable)
- `vw/vh`: 1/100 of viewport width/height
- `ch`: width of the “0” glyph, good for code/table widths
- `ex`: height of the lowercase `x` (rarely used)

---

## 9) CSS Specificity & Cascade

**Specificity model (simplified):**

- `!important` (breaks normal cascade; use sparingly)
- Inline styles (e.g., `style="..."`)
- `#id` (100)
- `.class / [attr] / :pseudo-class` (10)
- `tag / ::pseudo-element` (1)

**Modern techniques:**

- Wrap selectors in `:where(...)` to **avoid increasing specificity**, easier to override.
- Use **Cascade Layers**:

```css
@layer reset, base, components, utilities;
@layer reset {
  /* lower priority */
}
@layer components {
  /* higher than reset */
}
```

---

## 10) Style Isolation

- **Scoped CSS (e.g., Vue `scoped`)**: injects attributes like `data-v-xxxx` at compile time.
- **CSS Modules**: imported styles are scoped; class names are hashed.
- **Shadow DOM**: true isolation for Web Components (no leakage/contamination).
- **Naming convention (BEM)**: `block__element--modifier` to reduce selector complexity.

---

## 11) Flexbox Essentials

**Container properties:**

- `flex-direction` main axis direction
- `flex-wrap` wrapping
- `justify-content` alignment on main axis
- `align-items` alignment on cross axis
- `align-content` multi-line alignment
- `gap` row/column gap

**Item properties:**

- `order` ordering
- `flex-grow / flex-shrink / flex-basis`
- `flex` shorthand: `flex: 1` equals `1 1 0` (or `1 1 auto`, depending on implementation)
- `align-self` override per-item alignment

**Common layout: two columns**

```css
.container {
  display: flex;
}
.sidebar {
  width: 260px;
  flex: 0 0 260px;
}
.main {
  flex: 1 1 auto;
  min-width: 0;
} /* prevent overflow */
```

---

## 12) Grid Quick Use

**Sandwich layout (header–content–footer)**

```css
.page {
  display: grid;
  grid-template-rows: auto 1fr auto;
  min-height: 100svh;
}
```

**Three columns**

```css
.layout {
  display: grid;
  grid-template-columns: 300px 1fr 300px;
  gap: 16px;
}
```

---

## 13) Classic Layouts

**Two columns:**

- Float: left `float:left`, right side BFC (`overflow:auto`) to avoid overlap
- Flex / Grid: simpler and more maintainable

**Three columns (Holy Grail/Double Wing):**

- Prefer **Flex/Grid** in modern layouts; traditional float/negative margin/positioning are complex and no longer recommended.

**Sticky footer**

```css
.wrapper {
  min-height: 100svh;
  display: grid;
  grid-template-rows: auto 1fr auto;
}
```

---

## 14) Clearing Floats

- BFC: `overflow: auto` / `display: flow-root`
- Clearfix:

```css
.clearfix::after {
  content: "";
  display: table;
  clear: both;
}
```

---

## 15) Reflow & Repaint

- **Repaint**: visual changes (color, etc.), does not affect layout.
- **Reflow**: layout changes (size/position), more expensive. **Reflow always causes repaint**.

**Tips to reduce reflow:**

1. Combine multiple style changes (apply a class once).
2. Separate reads and writes: read first (e.g., `getBoundingClientRect()`), then batch writes; animate with `requestAnimationFrame`.
3. Prefer **`transform` / `opacity`** for transitions/animations (avoid layout thrash).
4. Use `will-change: transform;` for frequently changing elements (use cautiously).
5. Batch DOM changes in a document fragment, then insert once.

---

## 16) CSS Optimization (Engineering & Performance)

- **Inline critical CSS**: inline above-the-fold styles; defer the rest
- **Compress/bundle assets**: use build tools (Webpack/Vite + `cssnano`)
- **Autoprefix**: PostCSS `autoprefixer`
- **Reduce selector nesting**; avoid high specificity
- **Use `content-visibility: auto;`** to improve large-list rendering (defer offscreen rendering)
- **Font optimization**: `font-display: swap;` to reduce FOIT
- **Image optimization**: `<img loading="lazy">`, use `webp/avif`, `srcset/sizes` for responsive images

---

## 17) Preprocessing & Postprocessing & CSS-in-JS

- **Preprocessors**: Sass / Less / Stylus — variables, mixins, functions, nesting, modularization
  - Variable symbols: Less `@`, Sass `$`
- **Postprocessing**: PostCSS (`autoprefixer`, `postcss-pxtorem`, etc.)
- **CSS-in-JS**: styled-components / emotion (component-scoped styles, dynamic theming)

**Example (Sass mixin):**

```scss
@mixin visually-hidden {
  position: absolute !important;
  clip: rect(1px, 1px, 1px, 1px);
  clip-path: inset(50%);
  height: 1px;
  width: 1px;
  overflow: hidden;
  white-space: nowrap;
}
```

---

## 18) Useful Snippets

**1) Single/multi-line ellipsis**

```css
.single-ellipsis {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}
.multi-ellipsis {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  overflow: hidden;
}
```

**2) Intrinsic ratio box (responsive cover)**

```css
.ratio {
  position: relative;
  width: 100%;
  padding-top: 56.25%; /* 16:9 */
}
.ratio > img,
.ratio > iframe {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
```

**3) Safe area (notched screens)**

```css
.main {
  padding: env(safe-area-inset-top) env(safe-area-inset-right) env(
      safe-area-inset-bottom
    ) env(safe-area-inset-left);
}
```

---

## 19) Common Pitfalls (Quick Fix)

- **`opacity:0` ≠ non-clickable** → still receives events; to disable interaction use `pointer-events: none` or `visibility/display`.
- **`line-height = height` only fits single-line text**; for multiple lines use Flex/Grid.
- **Overusing `!important`** hurts maintainability; prefer layers (`@layer`) and low-specificity selectors (`:where`) to design an override path.
- **Animating `top/left` causes reflow**; prefer `transform`.

---

## 20) Summary

- **Prefer Flex/Grid for layout**; floats are only for text wrapping.
- **Use `border-box`** to simplify sizing; `flow-root/overflow` to clear floats.
- **Responsive toolkit**: media queries + viewport units + `rem`/`clamp` + container queries.
- **Performance**: batch style changes, animate via `transform/opacity`, inline critical CSS for first paint.
- **Engineering**: PostCSS, preprocessors, modularization (CSS Modules / Shadow DOM / BEM).
