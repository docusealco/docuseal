# ESLint Technical Debt Documentation

This document tracks the ESLint errors currently suppressed in the codebase and outlines the plan to address them.

## Current Approach

**As of 2025-10-14**: All TypeScript files in `package/` directory are temporarily excluded from linting via the ignore pattern `package/**/*.ts` in `eslint.config.js`. This allows the project to adopt ESLint configuration without requiring immediate fixes to all existing issues.

**Latest Update**: Auto-fixed 28 style violations in `package/configExporter/cli.ts` including unnecessary type assertions, string concatenation to template literals, and object destructuring (reduced from 77 to 49 errors).

## Current Linting Status

**Files currently linted** (`test/**/*.js`, `scripts/*.js`):

- ✅ **0 errors** (CI passing)
- ⚠️ **3 warnings** (acceptable, won't block CI)
  - 1x unused eslint-disable directive in `scripts/remove-use-strict.js`
  - 2x jest/no-disabled-tests in test files (expected for conditional test skipping)

**TypeScript files** (currently ignored via `package/**/*.ts`):

- **Estimated suppressed errors: ~163** (from sample analysis)
  - TypeScript type-safety issues: ~114 (70%)
  - Style/convention issues: ~49 (30%)

**Target**: Reduce suppressed errors by 50% within Q1 2025
**Last Updated**: 2025-10-18

## Priority Matrix

| Category                             | Impact | Effort | Priority | Count |
| ------------------------------------ | ------ | ------ | -------- | ----- |
| `@typescript-eslint/no-explicit-any` | High   | High   | P1       | 22    |
| `@typescript-eslint/no-unsafe-*`     | High   | High   | P1       | 85    |
| `config.ts` type safety              | High   | Medium | P1       | 7     |
| `no-param-reassign`                  | Medium | Low    | P2       | 0     |
| `class-methods-use-this`             | Low    | Low    | P3       | 0     |
| `no-nested-ternary`                  | Low    | Low    | P3       | 0     |
| `import/prefer-default-export`       | Low    | Medium | P3       | 9     |
| `global-require`                     | Medium | High   | P2       | 3     |
| Other style issues                   | Low    | Low    | P3       | 31    |

## Categories of Suppressed Errors

### 1. TypeScript Type Safety (Requires Major Refactoring)

#### `@typescript-eslint/no-explicit-any` (22 instances)

**Files affected:** `configExporter/`, `config.ts`, `utils/`
**Why suppressed:** These require careful type definitions and potentially breaking API changes
**Fix strategy:** Create proper type definitions for configuration objects and YAML parsing

#### `@typescript-eslint/no-unsafe-*` (85 instances)

- `no-unsafe-assignment`: 47 instances
- `no-unsafe-member-access`: 20 instances
- `no-unsafe-call`: 8 instances
- `no-unsafe-return`: 8 instances
- `no-unsafe-argument`: 7 instances
  **Why suppressed:** These stem from `any` types and dynamic property access
  **Fix strategy:** Requires comprehensive type refactoring alongside `no-explicit-any` fixes

### 2. Module System (Potential Breaking Changes)

#### `global-require` (3 instances)

**Files affected:** `configExporter/cli.ts`
**Why suppressed:** Dynamic require calls are needed for conditional module loading
**Fix strategy:** Would require converting to ES modules with dynamic imports

#### `import/prefer-default-export` (9 instances)

**Files affected:** Multiple single-export modules
**Why suppressed:** Adding default exports alongside named exports could break consumers
**Fix strategy:** Can be fixed non-breaking by adding default exports that match named exports

### 3. Code Style (Can Be Fixed)

#### `class-methods-use-this` (0 instances)

✅ **FIXED** - All FileWriter methods that didn't use instance state have been converted to static methods

#### `no-nested-ternary` (0 instances)

✅ **FIXED** - All nested ternary expressions have been refactored to if-else statements for better readability

#### `no-param-reassign` (0 instances)

✅ **FIXED** - Refactored `applyDefaults` function to return new objects instead of mutating parameters

#### `no-underscore-dangle` (2 instances)

**Fix strategy:** Rename variables or add exceptions for Node internals

### 4. Control Flow

#### `no-await-in-loop` (1 instance)

**Fix strategy:** Use `Promise.all()` for parallel execution

#### `no-continue` (1 instance)

**Fix strategy:** Refactor loop logic

## Recommended Approach

### Phase 1: Non-Breaking Fixes

✅ Completed:

- Fixed `no-use-before-define` by reordering functions
- Fixed redundant type constituents with `string & {}` pattern
- Added proper type annotations for `requireOrError` calls
- Configured appropriate global rule disables (`no-console`, `no-restricted-syntax`)
- ✅ **Fixed `class-methods-use-this`** - Converted FileWriter methods to static methods
- ✅ **Fixed `no-nested-ternary`** - Refactored to if-else statements for better readability
- ✅ **Fixed `no-param-reassign`** - Refactored `applyDefaults` to return new objects instead of mutating parameters
- ✅ **Auto-fixed style violations in cli.ts** (2025-10-18):
  - Removed unnecessary type assertions (`@typescript-eslint/no-unnecessary-type-assertion`)
  - Used object destructuring (`prefer-destructuring`)
  - Converted string concatenation to template literals (`prefer-template`)
  - Removed unused eslint-disable directives
  - Fixed `no-else-return` violations

🔧 Could still fix (low risk):

- `no-useless-escape` - Remove unnecessary escapes
- Unused variables - Remove or prefix with underscore

### Phase 2: Follow-up PRs (Non-Breaking)

- Systematic type safety improvements file by file
- Add explicit type definitions for configuration objects
- Replace `any` with `unknown` where possible

### Phase 3: Future Major Version (Breaking Changes)

- Convert `export =` to `export default`
- Convert `require()` to ES6 imports
- Full TypeScript strict mode compliance
- Provide codemod for automatic migration

## Configuration Strategy

The current approach uses file-specific overrides to suppress errors in affected files while maintaining strict checking elsewhere. This allows:

1. New code to follow strict standards
2. Gradual refactoring of existing code
3. Clear visibility of technical debt

## Issue Tracking

GitHub issues should be created for each category:

1. [ ] Issue: Type safety refactoring for configExporter module
2. [ ] Issue: Type safety for dynamic config loading
3. [ ] Issue: Convert class methods to static where appropriate
4. [ ] Issue: Module system modernization (ES6 modules)
5. [ ] Issue: Create codemod for breaking changes migration

## Notes

- All suppressed errors are documented in `eslint.config.js` with TODO comments
- The suppressions are scoped to specific files to prevent spreading technical debt
- New code should not add to these suppressions
