---
trigger: always_on
---

\---

name: Viridian Ops

version: 1.0.0



colors:



&#x20; primary: "#40826D"

&#x20; primary-light: "#A8D5C2"

&#x20; primary-dark: "#2F5D50"



&#x20; secondary: "#F4A261"

&#x20; secondary-dark: "#D97706"



&#x20; background: "#F7F8F7"

&#x20; surface: "#FFFFFF"

&#x20; surface-variant: "#F3F5F4"



&#x20; text-primary: "#1F2937"

&#x20; text-secondary: "#6B7280"



&#x20; border: "#E5E7EB"

&#x20; divider: "#D1D5DB"



&#x20; success: "#22C55E"

&#x20; warning: "#F4A261"

&#x20; error: "#DC2626"

&#x20; info: "#3B82F6"



typography:



&#x20; display:

&#x20;   font: Bricolage Grotesque

&#x20;   size: 32

&#x20;   weight: 700

&#x20;   lineHeight: 40



&#x20; headline:

&#x20;   font: Bricolage Grotesque

&#x20;   size: 24

&#x20;   weight: 600

&#x20;   lineHeight: 32



&#x20; title:

&#x20;   font: Bricolage Grotesque

&#x20;   size: 20

&#x20;   weight: 600

&#x20;   lineHeight: 28



&#x20; body:

&#x20;   font: Inter

&#x20;   size: 16

&#x20;   weight: 400

&#x20;   lineHeight: 24



&#x20; body-small:

&#x20;   font: Inter

&#x20;   size: 14

&#x20;   weight: 400

&#x20;   lineHeight: 20



&#x20; label:

&#x20;   font: Inter

&#x20;   size: 14

&#x20;   weight: 600

&#x20;   lineHeight: 20



&#x20; caption:

&#x20;   font: Inter

&#x20;   size: 12

&#x20;   weight: 500

&#x20;   lineHeight: 16



radius:



&#x20; sm: 4

&#x20; md: 8

&#x20; lg: 12

&#x20; xl: 16

&#x20; pill: 9999



spacing:



&#x20; xs: 4

&#x20; sm: 8

&#x20; md: 16

&#x20; lg: 24

&#x20; xl: 32

&#x20; xxl: 40

&#x20; page: 16

&#x20; tablet: 32



shadow:



&#x20; card:

&#x20;   x: 0

&#x20;   y: 2

&#x20;   blur: 8

&#x20;   opacity: 0.04



&#x20; floating:

&#x20;   x: 0

&#x20;   y: 8

&#x20;   blur: 24

&#x20;   opacity: 0.08



\---



\# Viridian Ops Design System



\## Philosophy



Viridian Ops is a clean, modern design system built for an internal Supermarket Management System.



The interface prioritizes speed, readability, and operational efficiency. Decorative elements should never compete with business data.



The experience should feel calm, organized, and trustworthy.



\---



\# Design Principles



1\. Minimal before decorative.

2\. Data first.

3\. Consistent spacing.

4\. Clear visual hierarchy.

5\. One primary action per screen.

6\. Every interaction should provide visual feedback.

7\. Prefer reusable components.



\---



\# Color Rules



Primary color represents the brand.



Use Primary only for:



\- Main buttons

\- Active navigation

\- Selected items

\- Focus states

\- Progress indicators



Secondary color is reserved for attention.



Use Secondary only for:



\- Low stock

\- Promotions

\- Warning badges

\- Important notifications



Do not use multiple accent colors on the same screen.



Cards should remain white.



The application background should remain off-white.



Never use pure black text.



\---



\# Typography Rules



Headlines



Use Bricolage Grotesque.



Body content



Use Inter.



Never mix additional font families.



Maintain consistent hierarchy.



Display



↓



Headline



↓



Title



↓



Body



↓



Caption



\---



\# Layout



Use an 8-point spacing system.



Mobile



\- 16px horizontal padding



Tablet



\- 32px horizontal padding



Touch targets



Minimum height



48dp



Avoid unnecessary nested containers.



\---



\# Elevation



Prefer tonal elevation instead of large shadows.



Cards



\- White surface

\- 1px border

\- Small ambient shadow



Dialogs



\- White surface

\- Floating shadow



Buttons



No shadows.



\---



\# Shape Language



Buttons



16px radius



Cards



16px radius



Input



16px radius



Chips



24px radius



FAB



Circular



\---



\# Components



\## Button



Primary



\- Filled Viridian

\- White text



Secondary



\- Light Viridian background

\- Viridian text



Outlined



\- White background

\- Border



Text



\- No background



\---



\## Card



White surface



16px radius



1px border



Small shadow



\---



\## Text Field



Filled style



No border



On focus



\- White background

\- 2px Primary border



Always include labels.



\---



\## Search Bar



Leading search icon



Rounded



Filled background



Optional trailing filter button.



\---



\## Bottom Navigation



Material 3 NavigationBar



Use only four destinations maximum.



Selected icon



Primary color.



\---



\## Status



Success



Green



Warning



Secondary



Error



Red



Info



Blue



Status should never rely on color alone.



Include an icon or text.



\---



\# Icons



Material Symbols Rounded.



Default size



24dp.



Avoid mixing icon libraries.



\---



\# Motion



Use subtle animations.



Duration



200–300ms.



Prefer



Fade



Scale



Slide



Avoid excessive bouncing animations.



\---



\# Accessibility



Minimum touch target



48dp



WCAG AA contrast



Visible focus state



Readable typography



Support system font scaling.



\---



\# Source of Truth



This document is the single source of truth for all UI decisions.



When generated code conflicts with this document,



this document always takes precedence.


## Material 3

The application MUST use Material Design 3.

Preferred widgets:

- FilledButton
- OutlinedButton
- TextButton
- Card
- NavigationBar
- NavigationRail
- SearchBar
- SearchAnchor
- FilledCard
- FloatingActionButton

Avoid using deprecated Material 2 widgets.