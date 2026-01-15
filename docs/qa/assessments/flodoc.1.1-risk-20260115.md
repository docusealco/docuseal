# Risk Assessment: Story 1.1 - Database Schema Extension

**Document Type**: Risk Profile
**Story**: 1.1 - Database Schema Extension
**Date**: 2026-01-15
**Assessment Type**: Brownfield Integration Risk Analysis
**Status**: Complete

---

## Executive Summary

This risk assessment analyzes the database schema extension for Story 1.1, which adds three new tables (`institutions`, `cohorts`, `cohort_enrollments`) to the existing DocuSeal codebase. The assessment identifies critical integration risks, data integrity concerns, and rollback complexities inherent in brownfield development.

**Overall Risk Level**: **MEDIUM-HIGH**
**Primary Concerns**: Foreign key dependencies, existing table integration, rollback complexity

---

## Risk Categories

### 1. Technical Risks

| Risk ID | Probability | Impact | Severity | Description |
|---------|-------------|--------|----------|-------------|
| **T-01** | High | High | **CRITICAL** | **Foreign Key Constraint Failures**<br>Foreign keys to `templates` and `submissions` tables may fail if referenced records don't exist during migration or if existing data violates constraints. |
| **T-02** | Medium | High | **HIGH** | **Migration Rollback Complexity**<br>Rollback may fail due to foreign key dependencies or data integrity issues, requiring manual database intervention. |
| **T-03** | Low | High | **MEDIUM** | **Database Compatibility Issues**<br>Schema may not be compatible with all supported databases (PostgreSQL/MySQL/SQLite) due to JSONB usage or specific syntax. |
| **T-04** | Medium | Medium | **MEDIUM** | **Index Creation Performance**<br>Creating indexes on large existing tables may cause significant downtime or locking. |
| **T-05** | Low | Medium | **LOW** | **Schema Version Mismatch**<br>Migration timestamp conflicts with existing migrations in production. |

**Mitigation Strategies:**
- **T-01**: Add `ON DELETE CASCADE` or `ON DELETE SET NULL` to foreign keys; validate existing data before migration
- **T-02**: Test rollback in staging environment; create backup before migration; use transaction wrapper
- **T-03**: Test migration on all three database types; use Rails 7+ compatible syntax
- **T-04**: Create indexes concurrently (PostgreSQL); schedule migration during low-traffic period
- **T-05**: Use unique timestamp prefix; verify migration order in production

---

### 2. Integration Risks

| Risk ID | Probability | Impact | Severity | Description |
|---------|-------------|--------|----------|-------------|
| **I-01** | **HIGH** | **HIGH** | **CRITICAL** | **Template Reference Integrity**<br>`cohorts.template_id` references `templates.id`. If templates are deleted or archived, foreign key constraint may prevent cohort creation or cause orphaned records. |
| **I-02** | **HIGH** | **HIGH** | **CRITICAL** | **Submission Reference Integrity**<br>`cohort_enrollments.submission_id` references `submissions.id`. Existing DocuSeal workflows may delete submissions, breaking enrollment links. |
| **I-03** | Medium | High | **HIGH** | **Account Table Confusion**<br>PRD specifies single `institutions` table, but DocuSeal has `accounts` table. Risk of confusion or unintended cross-references. |
| **I-04** | Medium | Medium | **MEDIUM** | **Existing Query Performance Degradation**<br>New indexes or table locks may slow down existing DocuSeal queries (templates, submissions, submitters). |
| **I-05** | Low | Medium | **LOW** | **Active Storage Conflicts**<br>New tables may conflict with Active Storage naming conventions or attachment behaviors. |

**Mitigation Strategies:**
- **I-01**: Add `restrict_with_exception` to prevent template deletion if cohorts exist; implement soft deletes on templates
- **I-02**: Use `dependent: :restrict_with_exception` on CohortEnrollment submission reference; ensure submission lifecycle is managed
- **I-03**: Document clearly that `institutions` is independent of `accounts`; no foreign key relationship
- **I-04**: Run EXPLAIN ANALYZE on critical queries; monitor query plans after migration
- **I-05**: Verify Active Storage table names don't conflict; use explicit table names if needed

---

### 3. Data Integrity Risks

| Risk ID | Probability | Impact | Severity | Description |
|---------|-------------|--------|----------|-------------|
| **D-01** | Medium | **HIGH** | **HIGH** | **Unique Constraint Violations**<br>`cohort_enrollments` has unique constraints on `[cohort_id, student_email]` and `[submission_id]`. Existing data may violate these. |
| **D-02** | Medium | High | **HIGH** | **NOT NULL Constraint Failures**<br>Required fields (`institution_id`, `template_id`, `student_email`) may receive NULL values during bulk operations. |
| **D-03** | Low | High | **MEDIUM** | **JSONB Data Validation**<br>JSONB fields (`required_student_uploads`, `cohort_metadata`, `uploaded_documents`, `values`) may contain invalid JSON or unexpected structures. |
| **D-04** | Low | Medium | **LOW** | **Timestamp Field Consistency**<br>`deleted_at` soft delete pattern may conflict with existing `archived_at` pattern in DocuSeal tables. |
| **D-05** | Medium | Medium | **MEDIUM** | **Default Value Issues**<br>Default values for `status` fields may not align with business logic (e.g., 'draft' vs 'waiting'). |

**Mitigation Strategies:**
- **D-01**: Test unique constraints with duplicate data; add database-level validation before migration
- **D-02**: Add model-level validations; use `null: false` in migration with proper defaults
- **D-03**: Add JSON schema validation in models; use `validate: :json_schema` if available
- **D-04**: Standardize on `deleted_at` for new tables; document pattern for future consistency
- **D-05**: Review business requirements for default states; add comments in migration

---

### 4. Security Risks

| Risk ID | Probability | Impact | Severity | Description |
|---------|-------------|--------|----------|-------------|
| **S-01** | Medium | High | **HIGH** | **Unauthorized Cross-Institution Data Access**<br>If multi-tenancy is accidentally enabled, students/sponsors may access data from other institutions. |
| **S-02** | Low | High | **MEDIUM** | **Email Data Exposure**<br>`sponsor_email` and `student_email` stored in plaintext; may violate privacy policies (POPIA). |
| **S-03** | Medium | Medium | **MEDIUM** | **Foreign Key Privilege Escalation**<br>Malicious user could potentially manipulate foreign keys to access unauthorized submissions or templates. |
| **S-04** | Low | Medium | **LOW** | **Soft Delete Data Leakage**<br>Soft-deleted records (`deleted_at`) may still be queryable by users with direct database access. |

**Mitigation Strategies:**
- **S-01**: Add institution_id validation in all model scopes; enforce single institution in application logic
- **S-02**: Implement email encryption at rest using Rails `encrypts` method; review POPIA compliance
- **S-03**: Implement proper authorization (Cancancan) for all foreign key references; validate ownership
- **S-04**: Implement default scopes to filter deleted records; use paranoia gem for soft deletes

---

### 5. Performance Risks

| Risk ID | Probability | Impact | Severity | Description |
|---------|-------------|--------|----------|-------------|
| **P-01** | Medium | High | **HIGH** | **Query Performance Degradation**<br>Joining new tables with existing tables may slow down critical workflows (cohort dashboard, enrollment lists). |
| **P-02** | Medium | Medium | **MEDIUM** | **Migration Execution Time**<br>Creating tables with multiple indexes and foreign keys may exceed 30-second threshold. |
| **P-03** | Low | Medium | **LOW** | **JSONB Query Performance**<br>Querying JSONB fields (`cohort_metadata`, `values`) may be slower than structured columns. |
| **P-04** | Low | Low | **LOW** | **Index Bloat**<br>Multiple indexes on small tables may cause unnecessary overhead. |

**Mitigation Strategies:**
- **P-01**: Use EXPLAIN ANALYZE to optimize queries; implement eager loading; add composite indexes
- **P-02**: Test migration timing in staging; use `disable_ddl_transaction!` for index creation if needed
- **P-03**: Use JSONB operators efficiently; consider partial indexes on frequently queried JSONB fields
- **P-04**: Monitor index usage after deployment; remove unused indexes

---

### 6. Business Logic Risks

| Risk ID | Probability | Impact | Severity | Description |
|---------|-------------|--------|----------|-------------|
| **B-01** | Medium | High | **HIGH** | **State Machine Complexity**<br>5-step cohort workflow (draft → active → completed) with multiple datetime fields may lead to inconsistent state transitions. |
| **B-02** | Medium | Medium | **MEDIUM** | **Single Institution Constraint**<br>PRD requires single institution per deployment, but schema doesn't enforce this at database level. |
| **B-03** | Low | Medium | **LOW** | **Program Type Validation**<br>`program_type` field accepts free text; may lead to inconsistent data (learnership vs learner-ship). |
| **B-04** | Medium | Medium | **MEDIUM** | **Sponsor Email Uniqueness**<br>Multiple cohorts may share sponsor email; may cause confusion in notifications. |

**Mitigation Strategies:**
- **B-01**: Implement state machine gem (aasm); add validation callbacks; create state transition tests
- **B-02**: Add application-level singleton pattern; database constraint with CHECK or trigger
- **B-03**: Use enum or strict validation for program_type; add enum to model
- **B-04**: Add business logic validation; consider separate sponsor table if needed

---

### 7. Rollback & Recovery Risks

| Risk ID | Probability | Impact | Severity | Description |
|---------|-------------|--------|----------|-------------|
| **R-01** | **HIGH** | **HIGH** | **CRITICAL** | **Failed Rollback Due to Data Dependencies**<br>If enrollments reference submissions that are deleted during rollback, migration may fail. |
| **R-02** | Medium | High | **HIGH** | **Data Loss During Rollback**<br>Rollback will drop all new tables, losing any data created during testing or partial deployment. |
| **R-03** | Low | High | **MEDIUM** | **Schema.rb Desynchronization**<br>Failed migration may leave schema.rb out of sync with actual database state. |
| **R-04** | Medium | Medium | **MEDIUM** | **Production Rollback Complexity**<br>Rollback in production requires coordination, downtime, and potential data recovery. |

**Mitigation Strategies:**
- **R-01**: Test rollback with sample data; add `dependent: :restrict_with_exception` to prevent orphaned records
- **R-02**: Create database backup before migration; document data retention policy; test in staging first
- **R-03**: Run `bin/rails db:schema:dump` after failed migration; manually verify schema.rb
- **R-04**: Create detailed rollback playbook; schedule maintenance window; have database administrator on standby

---

## Risk Severity Matrix

### Critical Risks (Immediate Action Required)
1. **T-01**: Foreign Key Constraint Failures
2. **I-01**: Template Reference Integrity
3. **I-02**: Submission Reference Integrity
4. **R-01**: Failed Rollback Due to Data Dependencies

### High Risks (Requires Mitigation Before Deployment)
1. **T-02**: Migration Rollback Complexity
2. **D-01**: Unique Constraint Violations
3. **D-02**: NOT NULL Constraint Failures
4. **S-01**: Unauthorized Cross-Institution Data Access
5. **P-01**: Query Performance Degradation
6. **B-01**: State Machine Complexity

### Medium Risks (Monitor and Address)
1. **T-03**: Database Compatibility Issues
2. **T-04**: Index Creation Performance
3. **I-03**: Account Table Confusion
4. **I-04**: Existing Query Performance Degradation
5. **S-02**: Email Data Exposure
6. **S-03**: Foreign Key Privilege Escalation
7. **P-02**: Migration Execution Time
8. **B-02**: Single Institution Constraint
9. **B-04**: Sponsor Email Uniqueness
10. **R-02**: Data Loss During Rollback
11. **R-04**: Production Rollback Complexity

### Low Risks (Acceptable or Future Mitigation)
1. **T-05**: Schema Version Mismatch
2. **I-05**: Active Storage Conflicts
3. **D-04**: Timestamp Field Consistency
4. **D-05**: Default Value Issues
5. **S-04**: Soft Delete Data Leakage
6. **P-03**: JSONB Query Performance
7. **P-04**: Index Bloat
8. **B-03**: Program Type Validation
9. **R-03**: Schema.rb Desynchronization

---

## Integration Verification Requirements

### IV1: Existing DocuSeal Tables Remain Unchanged
**Risk**: **HIGH** - Accidental modification of existing tables
**Verification**:
- [ ] Run `bin/rails db:schema:dump` and compare with original schema.rb
- [ ] Verify no changes to `templates`, `submissions`, `submitters` tables
- [ ] Check that existing indexes and foreign keys are preserved
- [ ] Run existing DocuSeal test suite to ensure no regression

### IV2: New Tables Reference Existing Tables Correctly
**Risk**: **CRITICAL** - Foreign key failures
**Verification**:
- [ ] Verify `cohorts.template_id` references valid `templates.id`
- [ ] Verify `cohort_enrollments.submission_id` references valid `submissions.id`
- [ ] Test with non-existent IDs to ensure foreign key constraints work
- [ ] Test with deleted/archived templates/submissions to verify behavior

### IV3: Database Performance Not Degraded
**Risk**: **HIGH** - Slow queries affecting user experience
**Verification**:
- [ ] Run EXPLAIN ANALYZE on 5 critical queries before and after migration
- [ ] Measure query execution time (should be < 100ms for simple queries)
- [ ] Verify indexes are being used (check EXPLAIN output)
- [ ] Monitor database CPU/memory usage during migration

### IV4: Rollback Process Works
**Risk**: **CRITICAL** - Failed rollback requiring manual intervention
**Verification**:
- [ ] Test rollback in staging environment with sample data
- [ ] Verify all tables are dropped correctly
- [ ] Verify no orphaned foreign key constraints remain
- [ ] Verify schema.rb is restored to original state

---

## Recommended Mitigation Actions

### Pre-Migration (Required)
1. **Create Database Backup**
   ```bash
   pg_dump docuseal_production > backup_20260115.sql
   ```

2. **Validate Existing Data**
   ```ruby
   # Check for potential foreign key violations
   Template.where.not(id: Cohort.pluck(:template_id)).count
   Submission.where.not(id: CohortEnrollment.pluck(:submission_id)).count
   ```

3. **Test on All Database Types**
   - PostgreSQL (production)
   - SQLite (development)
   - MySQL (if supported)

4. **Create Staging Environment**
   - Mirror production schema
   - Test migration and rollback
   - Performance testing

### During Migration
1. **Use Transaction Wrapper**
   ```ruby
   ActiveRecord::Base.transaction do
     create_table :institutions
     create_table :cohorts
     create_table :cohort_enrollments
     # ... indexes and foreign keys
   end
   ```

2. **Monitor Migration Progress**
   - Log execution time
   - Check for locks
   - Monitor error logs

3. **Have Rollback Ready**
   ```bash
   # Immediate rollback if issues detected
   bin/rails db:rollback STEP=1
   ```

### Post-Migration
1. **Verify Schema Integrity**
   ```bash
   bin/rails db:schema:dump
   git diff db/schema.rb
   ```

2. **Run Integration Tests**
   ```bash
   bundle exec rspec spec/integration/cohort_workflow_spec.rb
   bundle exec rspec spec/migrations/20260114000001_create_flo_doc_tables_spec.rb
   ```

3. **Monitor Production**
   - Check query performance
   - Monitor error rates
   - Verify data integrity

---

## Risk Acceptance Criteria

### Acceptable Risks
- **Low-impact performance degradation** (< 5% slowdown on existing queries)
- **Non-critical database compatibility issues** (fixable with migration updates)
- **Soft delete data leakage** (mitigated by application-level scopes)

### Unacceptable Risks (Must Fix Before Merge)
- **Foreign key constraint failures** (CRITICAL)
- **Data loss during rollback** (CRITICAL)
- **Unauthorized data access** (HIGH)
- **Failed migration requiring manual intervention** (HIGH)
- **Broken existing DocuSeal functionality** (HIGH)

---

## Testing Strategy

### Unit Tests (Migration)
- Table creation verification
- Schema validation
- Index creation
- Foreign key constraints
- Reversibility
- Data integrity

### Integration Tests
- Referential integrity with existing tables
- Query performance with joins
- State machine transitions
- Concurrent access scenarios

### Performance Tests
- Migration execution time
- Query performance before/after
- Index usage verification
- Load testing

### Security Tests
- Authorization checks
- Data access validation
- Email encryption (if implemented)

---

## Monitoring & Alerting

### During Migration
- Migration execution time > 30 seconds
- Database lock wait time > 5 seconds
- Error rate > 1%

### Post-Migration
- Query performance degradation > 10%
- Foreign key violation errors
- Data integrity check failures
- User-reported issues

---

## Rollback Plan

### Trigger Conditions
- Migration execution time > 60 seconds
- Any foreign key constraint violation
- Data integrity errors
- User-reported critical issues
- Performance degradation > 20%

### Rollback Steps
1. **Immediate**: Stop migration if in progress
2. **Execute**: `bin/rails db:rollback STEP=1`
3. **Verify**: Check schema.rb matches original
4. **Test**: Run existing DocuSeal tests
5. **Notify**: Alert team if manual intervention needed

### Recovery Time Objective (RTO)
- **Target**: < 5 minutes for rollback
- **Maximum**: 30 minutes (including verification)

---

## Conclusion

Story 1.1 presents **MEDIUM-HIGH** overall risk due to brownfield integration complexity. The primary concerns are:

1. **Foreign key dependencies** on existing DocuSeal tables (CRITICAL)
2. **Rollback complexity** due to data dependencies (CRITICAL)
3. **Performance impact** on existing queries (HIGH)
4. **Data integrity** during migration (HIGH)

**Recommendation**:
- ✅ **Proceed with caution** after implementing all mitigation strategies
- ✅ **Mandatory**: Test rollback in staging environment
- ✅ **Mandatory**: Run integration tests against existing DocuSeal test suite
- ✅ **Mandatory**: Create database backup before production migration
- ⚠️ **Consider**: Phased rollout (migrate schema first, then enable features)

**Next Steps**:
1. Implement all pre-migration validation checks
2. Create comprehensive test coverage
3. Test rollback scenario
4. Schedule production migration during maintenance window
5. Monitor closely post-deployment

---

**Assessment Completed By**: QA Agent
**Date**: 2026-01-15
**Review Status**: Ready for Development Team Review
**Approval Required**: Yes (before branch creation)