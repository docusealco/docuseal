# Infrastructure and Deployment Integration

## Existing Infrastructure

**Current Deployment:** Docker-based with Dockerfile and docker-compose.yml
**Infrastructure Tools:** Docker, Sidekiq, Puma, Redis, PostgreSQL/MySQL
**Environments:** Development (SQLite), Production (PostgreSQL/MySQL)

## Enhancement Deployment Strategy

**Deployment Approach:** Incremental feature addition to existing DocuSeal deployment
- **Zero downtime:** Database migrations are additive only
- **Feature flags:** Can disable cohort features if issues arise
- **Rolling deployment:** Deploy new code alongside existing functionality

**Infrastructure Changes:** None required
- ✅ No new services needed
- ✅ No infrastructure configuration changes
- ✅ Existing Docker setup sufficient
- ✅ Redis already configured for Sidekiq

**Pipeline Integration:**
- ✅ Existing CI/CD handles new Ruby code
- ✅ Shakapacker bundles new Vue components automatically
- ✅ Existing test suite extends with new tests
- ✅ No changes to build process

## Rollback Strategy

**Rollback Method:** Standard git revert + database migration rollback
- **Code rollback:** `git revert <commit-hash>` - Reverts to previous state
- **Database rollback:** `bin/rails db:rollback STEP=5` - Rolls back last 5 migrations
- **Asset rollback:** Previous assets remain cached in CDN

**Risk Mitigation:**
1. **Database backups:** Before migrations run in production
2. **Feature flags:** Can disable cohort routes if needed
3. **Gradual rollout:** Deploy to staging first, then production
4. **Monitoring:** Watch error rates and performance metrics

**Monitoring:**
- Extend existing Rails logging with cohort events
- Add cohort-specific metrics to existing monitoring
- Use existing Sidekiq monitoring for new jobs
- Track API response times for new endpoints

## Resource Sizing Recommendations

**Development Environment:**
- **CPU:** 2 cores minimum
- **RAM:** 4GB minimum (8GB recommended)
- **Storage:** 10GB free space
- **Database:** SQLite (file-based, no additional resources)

**Production Environment (Small Scale: 1-5 institutions, <1000 students):**
- **Application Server:** 4 cores, 8GB RAM, 50GB SSD
- **Database:** PostgreSQL 14+, 2GB RAM, 1 CPU core
- **Redis:** 1GB RAM for Sidekiq
- **Concurrent Users:** 50-100
- **Background Workers:** 2 workers (1 core, 1GB RAM each)

**Production Environment (Medium Scale: 5-20 institutions, <5000 students):**
- **Application Server:** 8 cores, 16GB RAM, 100GB SSD
- **Database:** PostgreSQL 14+, 4GB RAM, 2 CPU cores
- **Redis:** 2GB RAM
- **Concurrent Users:** 200-400
- **Background Workers:** 4 workers (2 cores, 2GB RAM each)

**Production Environment (Large Scale: 20+ institutions, 5000+ students):**
- **Application Server:** 16 cores, 32GB RAM, 200GB SSD
- **Database:** PostgreSQL 14+, 16GB RAM, 4 CPU cores (consider read replicas)
- **Redis:** 4GB RAM
- **Concurrent Users:** 500+
- **Background Workers:** 8+ workers (2 cores, 4GB RAM each)

**Performance Targets:**
- **Dashboard load:** < 2 seconds
- **Cohort list (50 cohorts):** < 1 second
- **Student list (100 students):** < 1.5 seconds
- **Excel export (100 students):** < 5 seconds
- **Document preview:** < 2 seconds
- **Bulk signing (50 students):** < 60 seconds

---
