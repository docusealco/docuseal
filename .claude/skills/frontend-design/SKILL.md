---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, or applications. Generates creative, polished code that avoids generic AI aesthetics.
license: Complete terms in LICENSE.txt
---

This skill guides creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. There are so many flavors to choose from. Use these for inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics; unexpected, characterful font choices. Pair a distinctive display font with a refined body font.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic. Apply creative forms like gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, and grain overlays.

NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices (Space Grotesk, for example) across generations.

**IMPORTANT**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

## FloDoc Design System

**CRITICAL**: When designing and coding frontend for the FloDoc application (including all three portals: Admin, Student, and Sponsor), you MUST adhere to the design system located at `.claude/skills/frontend-design/design-system/`. This folder contains the official design specifications in SVG format.

The design system directory structure is as follows:

- **`.claude/skills/frontend-design/design-system/Atoms/`** - Core UI components and atomic design elements
  - `Buttons/` - Button component variations and states
  - `Checkbox/` - Checkbox input styles
  - `Dropdown/` - Dropdown and select menu components
  - `Inputs Big/` - Large input field variations
  - `Inputs Text/` - Text input field styles
  - `Inputs tags/` - Tag/chip input components
  - `Menu Vertical/` - Vertical navigation menu components
  - `Progress Tags/` - Progress indicators and status tags
  - `Switch/` - Toggle switch components
  - `Switch Mode/` - Mode switching components
  - `Tags/` - Tag and badge components
  - `Text Area/` - Textarea input components

- **`.claude/skills/frontend-design/design-system/Colors and shadows/`** - Color palette and shadow specifications
  - `Brand colors/` - Primary brand color definitions
  - `Complementary colors/` - Secondary and accent colors
  - `Shadows/` - Shadow styles and elevation system

- **`.claude/skills/frontend-design/design-system/Fonts/`** - Typography specifications and font files

- **`.claude/skills/frontend-design/design-system/Icons/`** - Complete icon library organized by category
  - `Arrow/` - Arrow and navigation icons
  - `Building/` - Building and location icons
  - `Business/` - Business and corporate icons
  - `Content, edit/` - Content editing and text icons
  - `Essensial/` - Essential UI icons
  - `Files/` - File and document icons
  - `Grid/` - Layout and grid icons
  - `Money/` - Financial and money icons
  - `Notifications/` - Notification and alert icons
  - `School lerning/` - Education and learning icons
  - `Search/` - Search and discovery icons
  - `Settings/` - Settings and configuration icons
  - `Time/` - Time and calendar icons
  - `Type, pararaph, characterr/` - Text and typography icons
  - `Users/` - User and people icons
  - `archive/` - Archive and storage icons
  - `emails messages/` - Email and messaging icons
  - `security/` - Security and protection icons
  - `support like question/` - Support and help icons

- **`.claude/skills/frontend-design/design-system/Logo/`** - Logo variations and brand marks

- **`.claude/skills/frontend-design/design-system/Typography/`** - Typography scale and font specifications

**MANDATORY**: When working on FloDoc frontend (Admin Portal, Student Portal, or Sponsor Portal), reference this design system folder first. Extract colors, fonts, icons, and component styles from these SVG files. Ensure visual consistency across all three portals by strictly following the established design system. Do not introduce new design elements without referencing this system.