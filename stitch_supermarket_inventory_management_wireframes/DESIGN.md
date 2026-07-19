---
name: Viridian Ops
colors:
  surface: '#f8f9ff'
  surface-dim: '#d0daee'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff3ff'
  surface-container: '#e6eeff'
  surface-container-high: '#dfe9fc'
  surface-container-highest: '#d9e3f7'
  on-surface: '#121c2a'
  on-surface-variant: '#3f4945'
  inverse-surface: '#273140'
  inverse-on-surface: '#ebf1ff'
  outline: '#6f7974'
  outline-variant: '#bfc9c3'
  surface-tint: '#256955'
  primary: '#00503e'
  on-primary: '#ffffff'
  primary-container: '#246955'
  on-primary-container: '#a1e6cc'
  inverse-primary: '#90d4bb'
  secondary: '#8e4e14'
  on-secondary: '#ffffff'
  secondary-container: '#fca867'
  on-secondary-container: '#763b00'
  tertiary: '#244e3f'
  on-tertiary: '#ffffff'
  tertiary-container: '#3c6656'
  on-tertiary-container: '#b4e2ce'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#acf1d7'
  primary-fixed-dim: '#90d4bb'
  on-primary-fixed: '#002117'
  on-primary-fixed-variant: '#00513f'
  secondary-fixed: '#ffdcc4'
  secondary-fixed-dim: '#ffb781'
  on-secondary-fixed: '#301400'
  on-secondary-fixed-variant: '#703800'
  tertiary-fixed: '#bfedd8'
  tertiary-fixed-dim: '#a3d0bd'
  on-tertiary-fixed: '#002117'
  on-tertiary-fixed-variant: '#244e3f'
  background: '#f8f9ff'
  on-background: '#121c2a'
  surface-variant: '#d9e3f7'
typography:
  headline-lg:
    fontFamily: Bricolage Grotesque
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Bricolage Grotesque
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Bricolage Grotesque
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  headline-lg-mobile:
    fontFamily: Bricolage Grotesque
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-tablet: 32px
---

## Brand & Style

The design system is centered on a **refined minimalist** aesthetic, blending the systematic efficiency of Material Design 3 with a custom, high-end editorial clarity. The target audience consists of supermarket floor managers and logistics personnel who require high-speed data processing without cognitive fatigue.

The emotional response is one of **composed control**. By utilizing a generous whitespace strategy and a sophisticated Viridian-centered palette, the UI feels less like a cluttered inventory sheet and more like a premium productivity suite. The style prioritizes functional beauty—eliminating unnecessary decorative elements in favor of purposeful geometry and subtle tactile cues.

## Colors

The color architecture is built on a "Natural Professionalism" theme. The primary **Viridian (#40826D)** is used for key actions and brand presence, evoking freshness and reliability. 

- **Primary & Tints:** Use Viridian for core interaction points. The Primary Light (#A8D5C2) serves as a soft background for selected states or categories (e.g., "In Stock" badges).
- **Surface Strategy:** The background uses a slightly off-white gray-green (#F7F8F7) to reduce screen glare during long shifts, while the Surface remains pure white to create a distinct layer of information.
- **Accents:** The Saffron-leaning Accent (#F4A261) is reserved strictly for warnings, low-stock alerts, or items requiring immediate managerial attention.
- **Grayscale:** Text Primary is a deep charcoal rather than pure black to maintain a softer, more modern contrast.

## Typography

This design system utilizes a dual-font strategy to balance character with utility. 

**Bricolage Grotesque** is used for headlines. Its unique, slightly quirky terminals add a distinctive "premium tool" feel that differentiates the app from generic enterprise software. **Inter** is used for all body text, data points, and labels to ensure maximum legibility at small sizes, particularly for SKU numbers and pricing.

- **Hierarchy:** Use `headline-md` for screen titles and `label-lg` for section headers within lists.
- **Readability:** For data-heavy views (like inventory lists), use `body-md` with the `text-secondary` color to ensure the primary information (quantities/names) remains the focal point.

## Layout & Spacing

The system follows a strict **8px grid** rhythm. 

- **Mobile Layout:** Uses a fluid 4-column grid with 16px side margins. Elements should align to the 16px "safe zone."
- **Vertical Rhythm:** Components are separated by `md` (16px) or `lg` (24px) spacing. In dense data lists, `sm` (8px) padding is used between line items to maintain high information density without sacrificing touch targets.
- **Touch Targets:** All interactive elements must maintain a minimum height of 48px, even if their visual representation is smaller.

## Elevation & Depth

This design system uses **Tonal Elevation** combined with **Ambient Shadows**. Instead of heavy shadows, we use surface color shifts and extremely soft, diffused blurs to signify depth.

- **Level 0 (Background):** #F7F8F7.
- **Level 1 (Cards/Lists):** Surface White with a 1px border (#E5E7EB) or a very soft shadow (0px 2px 8px rgba(0,0,0,0.04)).
- **Level 2 (Floating Action Buttons/Modals):** Surface White with a more pronounced shadow (0px 8px 24px rgba(0,0,0,0.08)).
- **Interactions:** When an item is pressed, it should transition from its elevation to a slightly darker tonal overlay (5% Primary color tint) rather than a deep shadow.

## Shapes

The shape language is **"Modern Friendly."** We use a consistent medium-high corner radius to soften the professional aesthetic.

- **Standard Components:** Buttons, Input Fields, and Cards use the `rounded-md` (16px) standard.
- **Small Elements:** Tags and Chips use a more aggressive `rounded-xl` (24px) to create a "pill" appearance, making them easily distinguishable from actionable buttons.
- **Containers:** Bottom sheets and large modals use `rounded-xl` only on the top corners to anchor them to the bottom of the viewport.

## Components

### Buttons
- **Primary:** Viridian (#40826D) background, white text, 16px radius. No shadow; high color contrast provides the hierarchy.
- **Secondary:** Viridian tint background (10% opacity) with Viridian text. Used for less critical actions.

### Cards & Lists
- **Inventory Cards:** White surface, 16px radius, subtle 1px border. Use a vertical stack for product images and horizontal layouts for SKU list items.
- **Selection State:** Active list items should use a 2px left-side border in Viridian and a light Primary Light (#A8D5C2) background tint.

### Inputs
- **Search & Fields:** Light gray fill (#F3F4F6) with no border in resting state. On focus, transition to a white background with a 2px Viridian border.
- **Icons:** Use 24px line-icons with a consistent stroke weight (1.5px to 2px) to match the Inter typography weight.

### Feedback & Status
- **Low Stock Chip:** #F4A261 background with dark text.
- **Success Toast:** Viridian background with white text, positioned at the top of the screen to avoid thumb obstruction.