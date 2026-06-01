# Shakapacker v9 Migration Tools

## CSS Modules Codemod

A jscodeshift codemod to help migrate CSS module imports from v8 to v9 format.

### What it does

#### For JavaScript files (.js, .jsx):

- Converts `import styles from './styles.module.css'` to `import { className1, className2 } from './styles.module.css'`
- Automatically detects which CSS classes are used in the file
- Handles kebab-case to camelCase conversion (e.g., `my-button` → `myButton`)
- Updates all class references from `styles.className` to `className`

#### For TypeScript files (.ts, .tsx):

- Converts `import styles from './styles.module.css'` to `import * as styles from './styles.module.css'`
- Preserves the same usage pattern (`styles.className`)
- Works around TypeScript's limitation with dynamic named exports

### Installation

```bash
npm install -g jscodeshift
```

### Usage

#### Dry run (see what would change):

```bash
npx jscodeshift -t tools/css-modules-v9-codemod.js src/ --dry
```

#### Apply to JavaScript files:

```bash
npx jscodeshift -t tools/css-modules-v9-codemod.js src/
```

#### Apply to TypeScript files:

```bash
npx jscodeshift -t tools/css-modules-v9-codemod.js --parser tsx src/
```

#### Apply to specific file patterns:

```bash
# Only .jsx files
npx jscodeshift -t tools/css-modules-v9-codemod.js src/**/*.jsx

# Only .tsx files
npx jscodeshift -t tools/css-modules-v9-codemod.js --parser tsx src/**/*.tsx
```

### Options

- `--dry` - Run without modifying files
- `--print` - Print the transformed output
- `--parser tsx` - Use TypeScript parser
- `--verbose` - Show detailed progress

### Examples

#### Before (JavaScript):

```javascript
import styles from "./Button.module.css"

function Button() {
  return (
    <button className={styles.button}>
      <span className={styles["button-text"]}>Click me</span>
    </button>
  )
}
```

#### After (JavaScript):

```javascript
import { button, buttonText } from "./Button.module.css"

function Button() {
  return (
    <button className={button}>
      <span className={buttonText}>Click me</span>
    </button>
  )
}
```

#### Before (TypeScript):

```typescript
import styles from './Button.module.css';

const Button: React.FC = () => {
  return <button className={styles.button}>Click</button>;
};
```

#### After (TypeScript):

```typescript
import * as styles from './Button.module.css';

const Button: React.FC = () => {
  return <button className={styles.button}>Click</button>;
};
```

### Notes

1. **Kebab-case conversion**: CSS classes with kebab-case (e.g., `my-button`) are automatically converted to camelCase (`myButton`) for JavaScript files, matching css-loader's `exportLocalsConvention: 'camelCaseOnly'` setting.

2. **Unused imports**: The codemod only imports CSS classes that are actually used in JavaScript files. If you pass the entire styles object to a component, it will convert to namespace import for safety.

3. **Manual review recommended**: Always review the changes, especially for complex usage patterns or dynamic class name construction.

4. **Backup your code**: Run the codemod on version-controlled code or create a backup first.

### Troubleshooting

**Issue**: Codemod doesn't detect all CSS class usages
**Solution**: For dynamic class names or complex patterns, manual migration may be needed.

**Issue**: TypeScript errors after transformation
**Solution**: Ensure your TypeScript definitions are updated as shown in the [v9 Upgrade Guide](../docs/v9_upgrade.md).

**Issue**: Runtime errors about missing CSS classes
**Solution**: Check if you have kebab-case class names that need camelCase conversion.
