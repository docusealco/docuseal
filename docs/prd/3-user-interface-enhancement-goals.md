# 3. User Interface Enhancement Goals

## 3.1 Integration with Existing UI

**Design System Migration**:
The three portals will use a **custom TailwindCSS design system** replacing DaisyUI (CR3), while maintaining the same responsive design principles and mobile-first approach as the existing DocuSeal interface. The new design system will:

- **Preserve Core UX Patterns**: Maintain familiar interaction patterns from DocuSeal (form builders, signing flows, modal dialogs)
- **Enhance Accessibility**: WCAG 2.1 AA compliance for all portals
- **Support Dark/Light Mode**: Consistent with existing DocuSeal theme support
- **Language Support**: Maintain existing i18n infrastructure for 7 UI languages

**Visual Consistency**:
- **Color Palette**: Extend DocuSeal's existing brand colors with cohort-specific accent colors for status indicators
- **Typography**: Use existing font stack for consistency
- **Iconography**: Leverage existing icon library or extend with cohort-specific icons
- **Spacing & Layout**: Follow existing 8px grid system and spacing conventions

**Development Mandate - Design System Compliance**:
**CRITICAL**: During frontend development, the Dev Agent (James) MUST strictly adhere to the FloDoc design system specification located at `.claude/skills/frontend-design/SKILL.md` and the visual assets in `.claude/skills/frontend-design/design-system/`. This includes:

- **Color System**: Extract primary, secondary, neutral, and accent colors from `design-system/Colors and shadows/Brand colors/` and `Complementary colors/` SVG/JPG specifications
- **Typography**: Follow `design-system/Typography/typoraphy.txt` and `design-system/Fonts/fonts.txt` for font families, sizes, weights, and line heights
- **Component Library**: Use atomic design components from `design-system/Atoms/` (Buttons, Inputs, Checkboxes, Menus, Progress Tags, etc.)
- **Iconography**: Source all icons from `design-system/Icons/` organized by category (security, users, files, notifications, etc.)
- **Brand Assets**: Reference `design-system/Logo/` for all logo variations
- **Shadows & Elevation**: Apply shadow styles from `design-system/Colors and shadows/Shadows/`

**Agent Coordination**:
- **Dev Agent (James)**: Must reference the design system folder before writing any frontend code. All Vue components, TailwindCSS classes, and styling decisions must align with the design system specifications.
- **Scrum Master (Bob)**: Must be aware of this design system requirement during story creation and acceptance criteria definition. Frontend stories should include verification that all UI elements conform to the design system specifications.

**Consequences of Non-Compliance**: UI elements not derived from the design system will be rejected during code review. The design system is the single source of truth for all visual decisions.

## 3.2 Modified/New Screens and Views

### TP Portal (Admin Interface)

**New Screens**:
1. **Institution Onboarding** - Single-page form for initial TP setup
2. **Cohort Dashboard** - Main landing with cohort list, status cards, and quick actions
3. **Cohort Creation Wizard** - 5-step multi-form:
   - Step 1: Basic Info (name, program type)
   - Step 2: Student Management (email entry/bulk upload)
   - Step 3: Sponsor Configuration (single email, notification settings)
   - Step 4: Document Upload (SETA agreement + supporting docs)
   - Step 5: Student Upload Requirements (ID, Matric, Tertiary Qualifications)
4. **Document Mapping Interface** - Visual drag-and-drop for signatory assignment
5. **TP Signing Interface** - Single signing flow with "apply to all students" option
6. **Student Enrollment Status** - Bulk invite management and tracking
7. **Sponsor Access Monitor** - Real-time dashboard showing which sponsors have accessed their portal, when they last logged in, which students they've reviewed, and current pending actions. Prevents duplicate email sends and allows TP to intervene if sponsor hasn't accessed after notification.
8. **TP Review Dashboard** - 3-panel review interface:
   - **Left Panel**: Student list with completion status (Waiting for Student, Waiting for Sponsor, Complete)
   - **Middle Panel**: Full document viewer showing the selected student's completed documents
   - **Right Panel**: Verification controls - approve/reject individual documents, add verification notes, mark student as verified
9. **Cohort Analytics** - Completion rates, timeline, bottlenecks
10. **Excel Export Interface** - Data selection and export configuration

**Modified Existing Screens**:
- **Template Builder** - Enhanced with cohort-specific metadata fields
- **User Settings** - Institution role management added

### Student Portal

**New Screens**:
1. **Student Invitation Landing** - Accept cohort invitation, view requirements
2. **Document Upload Interface** - Multi-file upload with validation
3. **Student Signing Flow** - DocuSeal signing form with document preview
4. **Submission Status** - Real-time progress tracking
5. **Completion Confirmation** - Summary of submitted documents

**Modified Existing Screens**:
- **Submission Form** - Rebranded for cohort context, simplified navigation

### Sponsor Portal

**New Screens**:
1. **Cohort Dashboard** - Overview of all students in cohort with bulk signing capability
2. **Student List View** - Searchable, filterable list of students with status indicators
3. **Signature Capture Interface** - Two methods for signature: draw on canvas or type name
4. **Bulk Signing Preview** - Confirmation modal showing all affected students before signing
5. **Success Confirmation** - Post-signing summary with next steps

**Modified Existing Screens**:
- **Signing Form** - Enhanced for bulk cohort signing workflow

## 3.3 UI Consistency Requirements

**Portal-Specific Requirements**:

**TP Portal**:
- **Admin-First Design**: Complex operations made simple through progressive disclosure
- **Bulk Operations**: Prominent "fill once, apply to all" patterns
- **Status Visualization**: Color-coded cohort states (Pending, In Progress, Ready for Sponsor, Complete)
- **Action History**: Audit trail visible within interface

**What is Progressive Disclosure?**
This is a UX pattern that hides complexity until the user needs it. For the TP Portal, this means:
- **Default View**: Show only essential actions (Create Cohort, View Active Cohorts, Export Data)
- **On-Demand Complexity**: Advanced features (detailed analytics, bulk email settings, custom document mappings) are revealed only when users click "Advanced Options" or navigate to specific sections
- **Example**: The Cohort Creation Wizard (5 steps) uses progressive disclosure - each step shows only the fields needed for that step, preventing overwhelming the user with all 20+ fields at once
- **Benefit**: Reduces cognitive load for new users while keeping power features accessible for experienced admins

**Student Portal**:
- **Mobile-First**: Optimized for smartphone access
- **Minimal Steps**: Maximum 3 clicks to complete any document
- **Clear Requirements**: Visual checklist of required vs. optional documents
- **Progress Indicators**: Step-by-step completion tracking

**Sponsor Portal**:
- **Review-Optimized**: Keyboard shortcuts for document navigation
- **Bulk Actions**: "Sign All" and "Bulk Review" modes
- **Document Comparison**: Side-by-side view capability
- **No Account Required**: Email-link only access pattern
- **Progress Tracking**: Persistent progress bar showing completion status (e.g., "3/15 students completed - 20%") with visual indicator
- **Tab-Based Navigation**: Pending/Completed tabs for clear workflow separation

**Cross-Portal Consistency**:
- **Navigation**: All portals use consistent header/navigation patterns
- **Notifications**: Toast notifications for state changes
- **Error Handling**: Consistent error message formatting and recovery options
- **Loading States**: Skeleton screens and spinners for async operations
- **Empty States**: Helpful guidance when no cohorts/students/documents exist

**Mobile Responsiveness**:
- **Breakpoints**: 640px (sm), 768px (md), 1024px (lg), 1280px (xl)
- **Touch Targets**: Minimum 44x44px for all interactive elements
- **Tablet Optimization**: 3-panel sponsor portal collapses to 2-panel on tablets
- **Vertical Layout**: All portals stack vertically on mobile devices

**Accessibility Standards**:
- **Keyboard Navigation**: Full keyboard support for all portals
- **Screen Readers**: ARIA labels and semantic HTML throughout
- **Focus Management**: Clear focus indicators and logical tab order
- **Color Contrast**: Minimum 4.5:1 ratio for all text
- **Reduced Motion**: Respect user's motion preferences

---

