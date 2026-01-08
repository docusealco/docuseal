# Tech Stack

## Existing Technology Stack

| Category | Current Technology | Version | Usage in Enhancement | Notes |
|----------|-------------------|---------|---------------------|--------|
| **Backend Language** | Ruby | 3.4.2 | ✅ Core backend logic | Existing version maintained |
| **Web Framework** | Rails | 7.x | ✅ Controllers, Models, Views | Existing patterns followed |
| **Frontend Framework** | Vue.js | 3.3.2 | ✅ All three portals | Composition API for new components |
| **CSS Framework** | TailwindCSS | 3.4.17 | ✅ Custom portal styling | Replacing DaisyUI for portals |
| **UI Components** | DaisyUI | 3.9.4 | ⚠️ Legacy DocuSeal UI only | Not used in new portals |
| **Build Tool** | Shakapacker | 8.0 | ✅ Asset compilation | Existing configuration maintained |
| **Database** | PostgreSQL/MySQL/SQLite | Latest | ✅ New cohort tables | DATABASE_URL configuration |
| **Background Jobs** | Sidekiq | Latest | ✅ Email notifications, reminders | Existing queue system |
| **PDF Processing** | HexaPDF | Latest | ✅ Document generation/signing | Core DocuSeal capability |
| **PDF Rendering** | PDFium | Latest | ✅ Document preview | Existing rendering engine |
| **Authentication** | Devise | Latest | ✅ User auth + 2FA | Extended for new roles |
| **Authorization** | Cancancan | Latest | ✅ Role-based access | Extended for cohort permissions |
| **Storage** | Active Storage | Latest | ✅ Document storage | Existing multi-backend support |
| **Job Queue** | Redis | Latest | ✅ Sidekiq backend | Required dependency |
| **API Auth** | JWT | Latest | ✅ API token authentication | Existing mechanism |
| **Email** | SMTP | Latest | ✅ Notifications | Existing infrastructure |

## New Technology Additions

**No new technologies required.** The enhancement leverages existing DocuSeal technology stack entirely. All new functionality will be implemented using current frameworks and libraries.

**Rationale:** Brownfield enhancement should minimize technology changes to reduce risk and maintain compatibility. The existing stack provides all necessary capabilities for the 3-portal cohort management system.

---
