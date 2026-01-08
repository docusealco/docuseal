# Coding Standards

## Existing Standards Compliance

**Code Style:** Follow existing RuboCop configuration (frozen_string_literal, line length, etc.)
**Linting Rules:** RuboCop for Ruby, ESLint for Vue/JavaScript
**Testing Patterns:** RSpec with FactoryBot, existing test helpers
**Documentation Style:** Inline comments for complex logic, model annotations

## Enhancement-Specific Standards

**New Patterns for Cohort Management:**
- **State Management:** Use state machine pattern for cohort/enrollment states
- **Service Objects:** All complex business logic in `lib/cohorts/`
- **Vue Composition API:** All new Vue components use `<script setup>`
- **Custom Design System:** TailwindCSS utilities only (no DaisyUI for portals)
- **Mobile-First:** All portals must be mobile-optimized from start

**Integration Rules:**

**Existing API Compatibility:**
- ✅ All new endpoints return consistent JSON format
- ✅ Authentication uses existing Devise + JWT
- ✅ Error responses match existing patterns
- ✅ Pagination follows existing conventions

**Database Integration:**
- ✅ No modifications to existing tables
- ✅ Foreign keys to existing tables use standard Rails naming
- ✅ New tables include `created_at`, `updated_at` timestamps
- ✅ Use `uuid` for public identifiers where needed

**Error Handling:**
- ✅ Follow existing Rails exception handling patterns
- ✅ Use existing error response format for API
- ✅ Log errors to existing monitoring infrastructure
- ✅ Provide user-friendly messages for portal interfaces

**Logging Consistency:**
- ✅ Use existing Rails logger with structured logging
- ✅ Include cohort_id and enrollment_id in relevant logs
- ✅ Follow existing log format for easy parsing
- ✅ Extend existing log aggregation with cohort events

---
