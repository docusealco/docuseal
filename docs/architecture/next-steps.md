# Next Steps

## Story Manager Handoff

**Reference Architecture:** This document provides complete architectural blueprint for 3-portal cohort management enhancement.

**Key Integration Requirements (Validated):**
- **Authentication:** Extend existing Devise + JWT without modification
- **Database:** Additive schema changes only, maintain 100% backward compatibility
- **API:** Extend existing v1 endpoints, follow RESTful patterns
- **UI:** Custom TailwindCSS design system for portals, mobile-first responsive
- **PDF Processing:** Reuse existing HexaPDF and form builder components
- **Email/Notifications:** Leverage existing DocuSeal email infrastructure
- **Storage:** Use existing Active Storage with multi-backend support

**First Story to Implement:** **Story 1.1 - Institution and Admin Management**
- **Why first:** Foundation for multi-tenancy, enables all subsequent stories
- **Integration checkpoints:**
  1. Verify Institution model doesn't conflict with existing Account
  2. Test role-based permissions with existing Cancancan
  3. Ensure admin invitation uses existing Devise patterns
  4. Validate data isolation between institutions
- **Success criteria:** Admin can create institution, invite other admins, manage permissions

**Implementation Sequencing:**
1. **Story 1.1** → Institution & Admin Management (foundation)
2. **Story 1.2** → Cohort Creation & Templates (builds on 1.1)
3. **Story 1.3** → Student Enrollment (requires 1.2)
4. **Story 1.4** → Admin Verification (parallel with 1.3)
5. **Story 1.5** → Student Portal (requires 1.3)
6. **Story 1.6** → Sponsor Portal (requires 1.5)
7. **Story 1.7** → Admin Finalization (requires 1.6)
8. **Story 1.8** → Notifications (can run parallel)
9. **Story 1.9** → Dashboard & Analytics (requires all above)
10. **Story 1.10** → State Management (refinement throughout)

## Developer Handoff

**Architecture Reference:** This document is the source of truth for all architectural decisions.

**Key Technical Constraints (Based on Real Project Analysis):**
- **Ruby 3.4.2, Rails 7.x** - Maintain exact versions
- **Vue 3.3.2, Composition API** - All new components use `<script setup>`
- **TailwindCSS 3.4.17** - No DaisyUI for new portals
- **SQLite dev, PostgreSQL/MySQL prod** - Test with both
- **Sidekiq + Redis** - Required for background jobs
- **HexaPDF** - Core document processing engine

**Integration Requirements (Validated with Real Code):**
- **Models:** Follow existing patterns (strip_attributes, annotations, foreign keys)
- **Controllers:** Use existing base controllers, follow naming conventions
- **API:** Match existing response formats, error handling, pagination
- **Vue:** Use existing API client patterns, component registration
- **Jobs:** Follow existing Sidekiq job patterns, queue naming
- **Tests:** Use existing factories, helpers, matchers

**Critical Verification Steps:**
1. **Run existing test suite** - Must pass before any cohort changes
2. **Test authentication flow** - Verify Devise + JWT works for new roles
3. **Validate database migrations** - Test rollback on production-like data
4. **Check performance** - Monitor response times with large cohorts
5. **Verify mobile responsiveness** - Test all portals on mobile devices
6. **Test existing workflows** - Ensure template creation, submission, signing still work

**Key Files to Reference:**
- `app/models/user.rb` - Authentication patterns
- `app/models/account.rb` - Multi-tenancy structure
- `app/controllers/api/api_base_controller.rb` - API auth patterns
- `lib/submissions/` - Business logic patterns
- `app/javascript/template_builder/` - Form builder integration
- `app/javascript/submission_form/` - Signing form patterns

**Rollback Checklist:**
- [ ] Database backup before migrations
- [ ] Feature flag for cohort routes
- [ ] Monitor error rates post-deployment
- [ ] Have git revert command ready
- [ ] Test rollback procedure on staging

---

**Architecture Document Complete** ✅

This brownfield architecture provides a comprehensive blueprint for implementing the 3-portal cohort management system while maintaining 100% compatibility with existing DocuSeal functionality. All recommendations are based on actual codebase analysis and validated against real project constraints.

## Enhanced Documentation Summary

**All architect checklist gaps have been addressed:**

✅ **Route Tables** - Complete web portal routes for Admin, Student, and Sponsor portals
✅ **Resource Sizing** - Detailed recommendations for development and production environments
✅ **Architectural Decisions** - 6 ADRs documenting key technical choices and rationale
✅ **API Response Schemas** - Complete request/response examples with error handling
✅ **Component Props/Events** - TypeScript interfaces for all Vue components
✅ **UI Mockups** - ASCII wireframes for all portal interfaces
✅ **Error Handling** - Comprehensive error response patterns and codes

**Key Enhancements Added:**
- **Web Portal Routes**: 17 routes across 3 portals with authentication and component mapping
- **Performance Targets**: Specific response time goals for all major operations
- **Decision Records**: Brownfield strategy, UI approach, auth patterns, state management
- **Complete API Examples**: All endpoints with request/response schemas and error cases
- **Component Specifications**: Props, events, and state for 10+ Vue components
- **Visual Mockups**: ASCII wireframes showing exact UI layouts for all portals

**Ready for Implementation** 🚀