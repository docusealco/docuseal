# CSS Modules Export Mode

## Version 9.x (Current Default Behavior)

Starting with Shakapacker v9, CSS Modules are configured with **named exports** (`namedExport: true`) by default to align with Next.js and modern tooling standards.

### JavaScript Usage

In pure JavaScript projects, you can use true named imports:

```js
// v9 - named exports in JavaScript
import { bright, container } from "./Foo.module.css"
;<button className={bright} />
```

### TypeScript Usage

TypeScript cannot statically analyze CSS files to determine the exact export names at compile time. When css-loader generates individual named exports dynamically from your CSS classes, TypeScript doesn't know what those exports will be. Therefore, you must use namespace imports:

```typescript
// v9 - namespace import required for TypeScript
import * as styles from './Foo.module.css';
<button className={styles.bright} />
```

**Why namespace imports?** While webpack's css-loader generates true named exports at runtime (with `namedExport: true`), TypeScript's type system cannot determine these dynamic exports during compilation. The namespace import pattern allows TypeScript to treat the import as an object with string keys, bypassing the need for static export validation while still benefiting from the runtime optimizations of named exports.

### Benefits of v9 Configuration

- Eliminates certain webpack warnings
- Provides better tree-shaking potential
- Aligns with modern JavaScript module standards
- Automatically converts kebab-case to camelCase (`my-button` → `myButton`)

### Important: exportLocalsConvention with namedExport

When `namedExport: true` is enabled (v9 default), css-loader requires `exportLocalsConvention` to be either `'camelCaseOnly'` or `'dashesOnly'`.

**The following will cause a build error:**

```js
modules: {
  namedExport: true,
  exportLocalsConvention: 'camelCase'  // ❌ ERROR: incompatible with namedExport: true
}
```

**Error message:**

```
"exportLocalsConvention" with "camelCase" value is incompatible with "namedExport: true" option
```

**Correct v9 configuration:**

```js
modules: {
  namedExport: true,
  exportLocalsConvention: 'camelCaseOnly'  // ✅ Correct - only camelCase exported
}
```

**exportLocalsConvention options with namedExport:**

When `namedExport: true`, you can use:

- `'camelCaseOnly'` (v9 default): Exports ONLY the camelCase version (e.g., only `myButton`)
- `'dashesOnly'`: Exports ONLY the original kebab-case version (e.g., only `my-button`)

**Not compatible with namedExport: true:**

- `'camelCase'`: Exports both versions (both `my-button` and `myButton`) - only works with `namedExport: false` (v8 behavior)

**Configuration Quick Reference:**

| namedExport | exportLocalsConvention | `.my-button` exports              | Use Case               | Compatible?    |
| ----------- | ---------------------- | --------------------------------- | ---------------------- | -------------- |
| `true`      | `'camelCaseOnly'`      | `myButton`                        | JavaScript conventions | ✅ Valid       |
| `true`      | `'dashesOnly'`         | `'my-button'`                     | Preserve CSS naming    | ✅ Valid       |
| `false`     | `'camelCase'`          | Both `myButton` AND `'my-button'` | v8 compatibility       | ✅ Valid       |
| `false`     | `'asIs'`               | `'my-button'`                     | No transformation      | ✅ Valid       |
| `true`      | `'camelCase'`          | -                                 | -                      | ❌ Build Error |

**When to use each option:**

- Use `'camelCaseOnly'` if you prefer standard JavaScript naming conventions
- Use `'dashesOnly'` if you want to preserve your CSS class names exactly as written
- Use `'camelCase'` (with `namedExport: false`) only if you need both versions available

## Version 8.x and Earlier Behavior

In Shakapacker v8 and earlier, the default behavior was to use a **default export object**:

```js
// v8 and earlier default
import styles from "./Foo.module.css"
;<button className={styles.bright} />
```

---

## Migrating from v8 to v9

When upgrading to Shakapacker v9, you'll need to update your CSS Module imports from default exports to named exports.

### Migration Options

#### Option 1: Update Your Code (Recommended)

**For JavaScript projects:**

```js
// Before (v8)
import styles from "./Component.module.css"
;<div className={styles.container}>
  <button className={styles.button}>Click me</button>
</div>

// After (v9) - JavaScript
import { container, button } from "./Component.module.css"
;<div className={container}>
  <button className={button}>Click me</button>
</div>
```

**For TypeScript projects:**

```typescript
// Before (v8)
import styles from './Component.module.css';
<div className={styles.container}>
  <button className={styles.button}>Click me</button>
</div>

// After (v9) - TypeScript
import * as styles from './Component.module.css';
<div className={styles.container}>
  <button className={styles.button}>Click me</button>
</div>
```

Note: TypeScript projects only need to change from default import to namespace import (`* as styles`), the property access remains the same.

#### Option 2: Keep v8 Behavior

If you prefer to keep the v8 default export behavior during migration, you can override the configuration (see below).

---

## Reverting to Default Exports (v8 Behavior)

To use the v8-style default exports instead of v9's named exports, you have several options:

### Option 1: Configuration File (Easiest - Recommended)

The simplest way to restore v8 behavior is to set the `css_modules_export_mode` option in your `config/shakapacker.yml`:

```yaml
# config/shakapacker.yml
default: &default
  # ... other settings ...

  # CSS Modules export mode
  # named (default) - Use named exports with camelCase conversion (v9 default)
  # default - Use default export with both original and camelCase names (v8 behavior)
  css_modules_export_mode: default
```

This configuration automatically adjusts the CSS loader settings:

- Sets `namedExport: false` to enable default exports
- Sets `exportLocalsConvention: 'camelCase'` to export both original and camelCase versions

**Restart your development server** after changing this setting for the changes to take effect.

With this configuration, you can continue using v8-style imports:

```js
// Works with css_modules_export_mode: default
import styles from "./Component.module.css"
;<div className={styles.container}>
  <button className={styles.button}>Click me</button>
  <button className={styles["my-button"]}>Kebab-case</button>
  <button className={styles.myButton}>Also available</button>
</div>
```

### Option 2: Manual Webpack Configuration (Advanced)

If you need more control or can't use the configuration file approach, you can manually modify the webpack configuration that applies to all environments:

```js
// config/webpack/commonWebpackConfig.js
const { generateWebpackConfig, merge } = require("shakapacker")

const baseClientWebpackConfig = generateWebpackConfig()

// Override CSS Modules configuration to use v8-style default exports
const overrideCssModulesConfig = (config) => {
  // Find the CSS rule in the module rules
  const cssRule = config.module.rules.find(
    (rule) => rule.test && rule.test.toString().includes("css")
  )

  if (cssRule && cssRule.use) {
    const cssLoaderUse = cssRule.use.find(
      (use) => use.loader && use.loader.includes("css-loader")
    )

    if (cssLoaderUse && cssLoaderUse.options && cssLoaderUse.options.modules) {
      // Override v9 default to use v8-style default exports
      cssLoaderUse.options.modules.namedExport = false
      cssLoaderUse.options.modules.exportLocalsConvention = "asIs"
    }
  }

  return config
}

const commonOptions = {
  resolve: {
    extensions: [".css", ".ts", ".tsx"]
  }
}

const commonWebpackConfig = () => {
  const config = merge({}, baseClientWebpackConfig, commonOptions)
  return overrideCssModulesConfig(config)
}

module.exports = commonWebpackConfig
```

### Option 3: Create `config/webpack/environment.js` (Alternative)

If you prefer using a separate environment file:

```js
// config/webpack/environment.js
const { environment } = require("@shakacode/shakapacker")
const getStyleRule = require("@shakacode/shakapacker/package/utils/getStyleRule")

// CSS Modules rule for *.module.css with v8-style default export
const cssModulesRule = getStyleRule(/\.module\.css$/i, [], {
  sourceMap: true,
  importLoaders: 2,
  modules: {
    auto: true,
    namedExport: false, // <-- override v9 default
    exportLocalsConvention: "asIs" // keep class names as-is instead of camelCase
  }
})

// Ensure this rule wins for *.module.css
if (cssModulesRule) {
  environment.loaders.prepend("css-modules", cssModulesRule)
}

// Plain CSS rule for non-modules
const plainCssRule = getStyleRule(/(?<!\.module)\.css$/i, [], {
  sourceMap: true,
  importLoaders: 2,
  modules: false
})

if (plainCssRule) {
  environment.loaders.append("css", plainCssRule)
}

module.exports = environment
```

Then reference this in your environment-specific configs (development.js, production.js, etc.).

### Option 4: (Optional) Sass Modules

If you also use Sass modules, add similar configuration for SCSS files:

```js
// For Option 2 approach (manual webpack config), extend the overrideCssModulesConfig function:
const overrideCssModulesConfig = (config) => {
  // Handle both CSS and SCSS rules
  const styleRules = config.module.rules.filter(
    (rule) =>
      rule.test &&
      (rule.test.toString().includes("css") ||
        rule.test.toString().includes("scss"))
  )

  styleRules.forEach((rule) => {
    if (rule.use) {
      const cssLoaderUse = rule.use.find(
        (use) => use.loader && use.loader.includes("css-loader")
      )

      if (
        cssLoaderUse &&
        cssLoaderUse.options &&
        cssLoaderUse.options.modules
      ) {
        cssLoaderUse.options.modules.namedExport = false
        cssLoaderUse.options.modules.exportLocalsConvention = "asIs"
      }
    }
  })

  return config
}
```

---

## Detailed Migration Guide

### Migrating from v8 (Default Exports) to v9 (Named Exports)

#### 1. Update Import Statements

```js
// Old (v8 - default export)
import styles from "./Component.module.css"

// New (v9 - named exports)
import { bright, container, button } from "./Component.module.css"
```

#### 2. Update Class References

```js
// Old (v8)
<div className={styles.container}>
  <button className={styles.button}>Click me</button>
  <span className={styles.bright}>Highlighted text</span>
</div>

// New (v9)
<div className={container}>
  <button className={button}>Click me</button>
  <span className={bright}>Highlighted text</span>
</div>
```

#### 3. Handle Kebab-Case Class Names

**Option A: Use camelCase (v9 default)**

With `exportLocalsConvention: 'camelCaseOnly'`, kebab-case class names are automatically converted:

```css
/* styles.module.css */
.my-button { ... }
.primary-color { ... }
```

```js
// v9 default - camelCase conversion
import { myButton, primaryColor } from "./styles.module.css"
;<button className={myButton} />
```

**Option B: Keep kebab-case with 'dashesOnly'**

If you prefer to preserve the original kebab-case names, configure your webpack to use `'dashesOnly'`:

```js
// config/webpack/commonWebpackConfig.js
modules: {
  namedExport: true,
  exportLocalsConvention: 'dashesOnly'
}
```

```js
// With dashesOnly - preserve kebab-case
import * as styles from './styles.module.css';
<button className={styles['my-button']} />

// Or with aliasing:
import { 'my-button': myButton } from './styles.module.css';
<button className={myButton} />
```

**Note:** With both `'camelCaseOnly'` and `'dashesOnly'`, only one version of each class name is exported. The original kebab-case name is NOT available with `'camelCaseOnly'`, and the camelCase version is NOT available with `'dashesOnly'`.

#### 4. Using a Codemod for Large Codebases

For large codebases, you can create a codemod to automate the migration:

```js
// css-modules-v9-migration.js
module.exports = function (fileInfo, api) {
  const j = api.jscodeshift
  const root = j(fileInfo.source)

  // Find CSS module imports
  root
    .find(j.ImportDeclaration, {
      source: { value: (value) => value.endsWith(".module.css") }
    })
    .forEach((path) => {
      const defaultSpecifier = path.node.specifiers.find(
        (spec) => spec.type === "ImportDefaultSpecifier"
      )

      if (defaultSpecifier) {
        // Convert default import to namespace import for analysis
        // Then extract used properties and convert to named imports
        // ... codemod implementation
      }
    })

  return root.toSource()
}
```

Run with:

```bash
npx jscodeshift -t css-modules-v9-migration.js src/
```

---

## Version Comparison

| Feature             | v8 (and earlier)           | v9                                |
| ------------------- | -------------------------- | --------------------------------- |
| Default behavior    | Default export object      | Named exports                     |
| Import syntax       | `import styles from '...'` | `import { className } from '...'` |
| Class reference     | `styles.className`         | `className`                       |
| Export convention   | `asIs` (no transformation) | `camelCaseOnly`                   |
| TypeScript warnings | May show warnings          | No warnings                       |
| Tree-shaking        | Limited                    | Optimized                         |

---

## Benefits of Named Exports (v9 Default)

1. **No Build Warnings**: Eliminates webpack/TypeScript warnings about missing exports
2. **Better Tree-Shaking**: Unused CSS class exports can be eliminated
3. **Explicit Dependencies**: Clear about which CSS classes are being used
4. **Modern Standards**: Aligns with ES modules and modern tooling
5. **Type Safety**: TypeScript can validate individual class imports

## Benefits of Default Exports (v8 Behavior)

1. **Familiar Pattern**: Matches most existing React tutorials
2. **Namespace Import**: All classes available under one import
3. **Less Verbose**: Single import for all classes
4. **Legacy Compatibility**: Works with existing codebases

---

## Verifying the Configuration

### 1. Rebuild Your Packs

After making any configuration changes, rebuild your webpack bundles:

```bash
# For development
NODE_ENV=development bin/shakapacker

# Or with the dev server
bin/shakapacker-dev-server
```

### 2. Test in Your React Component

Verify your imports work correctly:

```js
// v9 default (named exports)
import { bright } from "./Foo.module.css"
console.log(bright) // 'Foo_bright__hash'

// Or if using v8 configuration (default export)
import styles from "./Foo.module.css"
console.log(styles) // { bright: 'Foo_bright__hash' }
```

### 3. Debug Webpack Configuration (Optional)

To inspect the final webpack configuration:

```bash
NODE_ENV=development bin/shakapacker --profile --json > /tmp/webpack-stats.json
```

Then search for `css-loader` options in the generated JSON file.

---

## Troubleshooting

### Build Error: exportLocalsConvention Incompatible with namedExport

If you see this error during build:

```
"exportLocalsConvention" with "camelCase" value is incompatible with "namedExport: true" option
```

**Cause:** Your webpack configuration has `namedExport: true` with `exportLocalsConvention: 'camelCase'`.

**Solution:** Change `exportLocalsConvention` to `'camelCaseOnly'` or `'dashesOnly'`:

```js
// config/webpack/commonWebpackConfig.js or similar
modules: {
  namedExport: true,
  exportLocalsConvention: 'camelCaseOnly'  // or 'dashesOnly'
}
```

Alternatively, if you need the `'camelCase'` option (both original and camelCase exports), you must revert to v8 behavior by setting `namedExport: false` as shown in the "Reverting to Default Exports" section above.

### CSS Classes Not Applying

If your CSS classes aren't applying after the upgrade:

1. **Check import syntax**: Ensure you're using the correct import style for your configuration
2. **Verify class names**: Use `console.log` to see available classes
3. **Check camelCase conversion**: Kebab-case names are converted to camelCase in v9 with `'camelCaseOnly'`
4. **Rebuild webpack**: Clear cache and rebuild: `rm -rf tmp/cache && bin/shakapacker`

### TypeScript Support

#### For v9 (Named Exports)

```typescript
// src/types/css-modules.d.ts
declare module "*.module.css" {
  const classes: { [key: string]: string }
  export = classes
}
```

#### For v8 Behavior (Default Export)

```typescript
// src/types/css-modules.d.ts
declare module "*.module.css" {
  const classes: { [key: string]: string }
  export default classes
}
```

### Build Performance

The configuration changes should not impact build performance significantly. If you experience issues:

1. Check webpack stats: `bin/shakapacker --profile`
2. Verify only necessary rules are being modified
3. Consider using webpack bundle analyzer for deeper insights

---

## Summary

- **v9 default**: Named exports with camelCase conversion
- **v8 default**: Default export object with no conversion
- **Migration path**: Update imports or override configuration
- **Benefits of v9**: No warnings, better tree-shaking, explicit dependencies
- **Keeping v8 behavior**: Override css-loader configuration as shown above
