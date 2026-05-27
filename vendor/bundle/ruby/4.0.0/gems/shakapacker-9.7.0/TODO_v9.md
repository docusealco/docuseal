# Shakapacker v9 TODO List

## CSS Modules Configuration Alignment

### Problem

Current CSS modules configuration causes TypeScript/webpack warnings because of default vs named export mismatch.

### Current Behavior (v8)

- CSS modules use default export: `import styles from './styles.module.css'`
- This causes warnings but works at runtime
- Warning example: `export 'default' (imported as 'style') was not found in './HelloWorld.module.css'`

### Proposed v9 Change

Align with Next.js and modern tooling by using named exports:

1. **Update css-loader configuration:**

```javascript
{
  loader: 'css-loader',
  options: {
    modules: {
      namedExport: true,
      exportLocalsConvention: 'camelCaseOnly'  // Must be 'camelCaseOnly' or 'dashesOnly' with namedExport: true
    }
  }
}
```

**Note:** Using `exportLocalsConvention: 'camelCase'` with `namedExport: true` will cause a build error.
css-loader only allows `'camelCaseOnly'` or `'dashesOnly'` when named exports are enabled.

2. **Update TypeScript types:**

- Ensure proper typing for CSS modules with named exports
- May need to update or generate `.d.ts` files for CSS modules

3. **Migration guide for users:**

- Document the breaking change
- Provide codemod or migration script to update imports from:
  ```javascript
  import styles from "./styles.module.css"
  styles.className
  ```
  to:
  ```javascript
  import * as styles from "./styles.module.css"
  // or
  import { className } from "./styles.module.css"
  ```

### Benefits

- Eliminates webpack/TypeScript warnings
- Better tree-shaking potential
- More explicit about what CSS classes are being used
- Easier interoperability with frameworks that support named exports

### Implementation Notes

- This is a BREAKING CHANGE and appropriate for major version bump
- Need to test with both webpack and rspack
- Consider providing a compatibility mode via configuration option

---

## Related Issues from PR #597

### React Component Not Rendering (spec/dummy) - RESOLVED ✅

- **Issue**: React component was not rendering due to CSS module import mismatch
- **Symptoms**:
  - Component wasn't rendering "Hello, Stranger!"
  - Input field not rendered, making interactive test fail
  - Only the static H1 "Hello, World!" was visible
- **Resolution**:
  - Fixed CSS module import syntax from `import style from` to `import * as style from`
  - This matched webpack's named exports configuration for CSS modules
  - Tests now pass with both React 18.3.1 and webpack/rspack configurations
- **Root Cause**: CSS module import/export mismatch
  - Webpack was configured to use named exports for CSS modules
  - TypeScript code was using default import syntax
  - This caused `style` to be undefined, breaking SSR and client rendering
- **Status**: FIXED
  - All tests re-enabled and passing
  - Both SSR and client-side rendering working
  - Interactive functionality restored

### Test Infrastructure

- Successfully implemented dual bundler support (webpack/rspack)
- test-bundler script working well with status command
- Consider adding more comprehensive tests for both bundlers
