# Rollback Strategy for Institution Management

## Overview

This document outlines the rollback procedure for the institution management migrations (20250103000001-20250103000006).

## Migration Sequence

1. `20250103000001` - Add institution_id to account_access (nullable)
2. `20250103000002` - Create institutions table
3. `20250103000003` - Create cohort_admin_invitations table
4. `20250103000004` - Update account_access roles
5. `20250103000005` - Backfill institution data (makes institution_id non-nullable)
6. `20250103000006` - Create security_events table

## Rollback Procedure

### Step 1: Test Rollback on Staging/Development

```bash
# Rollback last migration
bin/rails db:rollback STEP=1

# Rollback all institution migrations
bin/rails db:rollback STEP=6
```

### Step 2: Production Rollback (If Needed)

**⚠️ CRITICAL: Always backup database before rollback**

```bash
# 1. Create database backup
pg_dump -Fc docuseal_production > docuseal_backup_$(date +%Y%m%d_%H%M%S).dump

# 2. Check current migration status
bin/rails db:migrate:status

# 3. Rollback in reverse order
bin/rails db:rollback STEP=1  # Rollback security_events
bin/rails db:rollback STEP=1  # Rollback backfill
bin/rails db:rollback STEP=1  # Rollback account_access roles
bin/rails db:rollback STEP=1  # Rollback cohort_admin_invitations
bin/rails db:rollback STEP=1  # Rollback institutions
bin/rails db:rollback STEP=1  # Rollback institution_id addition

# 4. Verify rollback
bin/rails db:migrate:status
```

### Step 3: Data Safety Verification

**After rollback, verify:**

1. **Existing data intact:**
   ```sql
   SELECT COUNT(*) FROM users;
   SELECT COUNT(*) FROM accounts;
   SELECT COUNT(*) FROM account_accesses;
   SELECT COUNT(*) FROM templates;
   SELECT COUNT(*) FROM submissions;
   ```

2. **No orphaned records:**
   ```sql
   -- Check for orphaned records
   SELECT * FROM account_accesses WHERE account_id NOT IN (SELECT id FROM accounts);
   SELECT * FROM users WHERE account_id NOT IN (SELECT id FROM accounts);
   ```

3. **Existing functionality works:**
   - User login
   - Template creation
   - Submission workflows
   - API access

## Rollback Risks and Mitigations

### Risk 1: Data Loss
**Impact:** High
**Mitigation:**
- Always backup before rollback
- Test rollback on staging first
- Verify data integrity after rollback

### Risk 2: Downtime
**Impact:** Medium
**Mitigation:**
- Schedule rollback during maintenance window
- Have rollback plan ready
- Test procedure beforehand

### Risk 3: Application Errors
**Impact:** High
**Mitigation:**
- Keep application version compatible with database schema
- Have emergency rollback to previous app version ready
- Monitor error logs during rollback

## Emergency Rollback

If critical issues arise during deployment:

1. **Immediate rollback:**
   ```bash
   git revert HEAD
   bin/rails db:rollback STEP=6
   ```

2. **Restore from backup if needed:**
   ```bash
   pg_restore -d docuseal_production docuseal_backup_YYYYMMDD_HHMMSS.dump
   ```

3. **Notify stakeholders** of rollback and reason

## Post-Rollback Verification

After rollback, verify these critical paths:

- [ ] User authentication works
- [ ] Existing templates accessible
- [ ] Submissions can be created
- [ ] API endpoints return correct data
- [ ] No database constraint violations
- [ ] Email notifications work
- [ ] Webhook delivery works

## Rollback Decision Matrix

**Rollback if:**
- Data corruption detected
- Critical security vulnerabilities found
- Major performance degradation (>50%)
- Application crashes on startup
- Cannot fix issues within 2 hours

**Do NOT rollback if:**
- Minor bugs that can be hotfixed
- Performance issues within acceptable range (<10%)
- UI/UX issues only
- Non-critical feature failures

## Contact Information

**Emergency Contacts:**
- Database Administrator: [To be filled]
- DevOps Engineer: [To be filled]
- Security Team: [To be filled]

**Rollback Window:** [To be scheduled]
**Estimated Downtime:** 15-30 minutes