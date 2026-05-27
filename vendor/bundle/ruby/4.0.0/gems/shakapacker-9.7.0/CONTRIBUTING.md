# Contributing Guidelines

Thank you for your interest in contributing to Shakapacker! We welcome all contributions that align with our project goals and values. To ensure a smooth and productive collaboration, please follow these guidelines.

## Contents

- [Reporting Issues](#reporting-issues)
- [Submitting Pull Requests](#submitting-pull-requests)
- [Setting Up a Development Environment](#setting-up-a-development-environment)
- [Making sure your changes pass all tests](#making-sure-your-changes-pass-all-tests)
- [Testing the generator](#testing-the-generator)

## Reporting Issues

If you encounter any issues with the project, please first check the existing issues (including closed ones). If the issues is not reported before, please opening an issue on our GitHub repository. Please provide a clear and detailed description of the issue, including steps to reproduce it. Creating a demo repository to demonstrate the issue would be ideal (and in some cases necessary).

If looking to contribute to the project by fixing existing issues, we recommend looking at issues, particularly with the "[help wanted](https://github.com/shakacode/shakapacker/issues?q=is%3Aissue+label%3A%22help+wanted%22)" label.

## Submitting Pull Requests

We welcome pull requests that fix bugs, add new features, or improve existing ones. Before submitting a pull request, please make sure to:

- Open an issue about what you want to propose before start working on.
- Fork the repository and create a new branch for your changes.
- Write clear and concise commit messages.
- Follow our code style guidelines.
- Write tests for your changes and [make sure all tests pass](#making-sure-your-changes-pass-all-tests).
- Update the documentation as needed.
- Update CHANGELOG.md if the changes affect public behavior of the project.
- Update RBS type signatures in `sig/` directory if you modify public APIs.

---

## Git Hooks (Optional)

This project includes configuration for git hooks via `husky` and `lint-staged`, but they are **opt-in for contributors**.

**Why are hooks optional?** As a library project, we don't enforce git hooks because:

- Different contributors may have different workflows
- Forcing hooks can interfere with contributor tooling
- CI/CD handles the final validation

To enable pre-commit hooks locally:

```bash
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"
```

---

## RBS Type Signatures

Shakapacker includes RBS type signatures for all public APIs in the `sig/` directory. These signatures provide static type checking and improved IDE support.

### When to Update RBS Files

Update RBS signatures when you:

- Add new public methods or classes
- Change method signatures (parameters, return types)
- Modify public APIs
- Add or remove public attributes

### RBS File Structure

```
sig/
├── shakapacker.rbs                    # Main Shakapacker module
└── shakapacker/
    ├── configuration.rbs              # Configuration class
    ├── helper.rbs                     # View helper module
    ├── manifest.rbs                   # Manifest class
    ├── compiler.rbs                   # Compiler class
    └── ...                            # Other components
```

### Validating RBS Signatures

To validate your RBS signatures:

```bash
# Install RBS if not already installed
gem install rbs

# Validate all signatures
rbs validate

# Check a specific file
rbs validate sig/shakapacker/configuration.rbs
```

### RBS Best Practices

1. **Use specific types** instead of `untyped` when possible
2. **Document optional parameters** with `?` prefix
3. **Use union types** for methods that can return multiple types (e.g., `String | nil`)
4. **Keep signatures in sync** with implementation changes
5. **Test with type checkers** like [Steep](https://github.com/soutaro/steep) when possible
6. **Use `void` vs `nil` appropriately**:
   - Use `void` when the return value is expected to be discarded (e.g., `initialize`)
   - Use `nil` when a method explicitly returns nil as a meaningful value
7. **Module singleton methods**: For modules using `extend self`, use `module ModuleName : _Singleton` to indicate all methods are module-level singleton methods

### Example RBS Signature

```rbs
# Good: Specific types with documentation
class Shakapacker::Configuration
  def initialize: (
    root_path: Pathname,
    config_path: Pathname,
    env: ActiveSupport::StringInquirer,
    ?bundler_override: String?
  ) -> void

  def source_path: () -> Pathname
  def webpack?: () -> bool
  def assets_bundler: () -> String
end

# Module with singleton methods (using extend self)
module Shakapacker : _Singleton
  def self.config: () -> Configuration
  def self.compile: () -> bool
end

# Avoid: Overly generic types
class Shakapacker::Configuration
  def initialize: (**untyped) -> void
  def source_path: () -> untyped
end
```

---

## Linting and Code Quality

### Running Linters

```bash
# Full linting with type checking (slower but thorough)
yarn lint

# Fast linting without type checking (for quick feedback)
yarn lint:fast

# With caching for better performance
yarn lint --cache
```

**Performance Note:** TypeScript ESLint uses type-aware linting for better type safety, which can be slower on large codebases. Use `yarn lint:fast` during development for quick feedback.

---

## Setting Up a Development Environment

1. Install [Yarn](https://classic.yarnpkg.com/) & [yalc](https://github.com/wclr/yalc)
2. To test your changes on a Rails test project do the following steps:
   - For Ruby gem, update `Gemfile` and point the `shakapacker` to the locally developing Shakapacker project:
     ```ruby
     gem 'shakapacker', path: "relative_or_absolute_path_to_local_shakapacker"
     ```
   - For npm package, use `yalc` with following steps:

     ```bash
     # In Shakapacker root directory
     yalc publish
     # In Rails app for testing
     yalc link shakapacker

     # After every change in shakapacker, run the following in Shakapacker directory
     yalc push # or yalc publish --push
     ```

3. Run the following commands to set up the development environment.
   ```
   bundle install
   yarn install
   yarn prepare:husky  # Set up pre-commit hooks for linting
   ```

## Understanding Optional Peer Dependencies

Shakapacker uses optional peer dependencies (via `peerDependenciesMeta`) for maximum flexibility:

- **All peer dependencies are optional** - Users only install what they need
- **No installation warnings** - Package managers won't warn about missing optional dependencies
- **Version constraints still apply** - When a package is installed, version compatibility is enforced

### TypeScript Declaration Files and Optional Dependencies

When importing types from optional peer dependencies, we use `@ts-ignore` directives:

```typescript
// @ts-ignore: webpack is an optional peer dependency (using type-only import)
import type { Configuration } from "webpack"
```

This ensures that typecheck downstream won't fail if lib checks are on regardless of if `webpack` is available.

### When modifying dependencies:

1. Add new peer dependencies to both `peerDependencies` and `peerDependenciesMeta` (marking as optional)
2. Keep version ranges synchronized between `devDependencies` and `peerDependencies`
3. Test with multiple package managers: `npm`, `yarn`, and `pnpm`
4. If adding type-only imports from optional dependencies, use the `@ts-ignore` pattern shown above

### Testing peer dependency changes:

```bash
# Test with npm (no warnings expected)
cd /tmp && mkdir test-npm && cd test-npm
npm init -y && npm install /path/to/shakapacker

# Test with yarn (no warnings expected)
cd /tmp && mkdir test-yarn && cd test-yarn
yarn init -y && yarn add /path/to/shakapacker

# Test with pnpm (no warnings expected)
cd /tmp && mkdir test-pnpm && cd test-pnpm
pnpm init && pnpm add /path/to/shakapacker
```

## Making sure your changes pass all tests

There are several specs, covering different aspects of Shakapacker gem. You may run them locally or rely on GitHub CI actions configured to test the gem functionality if different Ruby, Rails, and Node environment.

We request running tests locally to ensure the new changes would not break the CI build.

### 1. Check the code for JavaScript style violations

```
yarn lint
```

### 2. Check the code for Ruby style violations

```
bundle exec rubocop
```

### 3. Run the JavaScript test suite

```
yarn test
```

### 4. Run all the Ruby test suite

```
bundle exec rake test
```

Note: For this, you need `yalc` to be installed on your local machine

#### 4.1 Run a single ruby test file

```
bundle exec rspec spec/configuration_spec.rb
```

#### 4.2 Run a single ruby test

```
bundle exec rspec -e "#source_entry_path returns correct path"
```

#### 4.3 Run only Shakapacker gem specs

```
bundle exec rake run_spec:gem
```

#### 4.4 Run only Shakapacker gem specs for backward compatibility

These specs are to check Shakapacker v7 backward compatibility with v6.x

```
bundle exec rake run_spec:gem_bc
```

#### 4.5 Run dummy app test

For this, you need `yalc` to be installed on your local machine

```
bundle exec rake run_spec:dummy
```

#### 4.6 Testing the installer

To ensure that your installer works as expected, either you can run `bundle exec rake run_spec:install`, or take the following manual testing steps:

1. Update the `Gemfile` so that gem `shakapacker` has a line like this, pointing to your developing Shakapacker:
   ```ruby
   gem 'shakapacker', path: "relative_or_absolute_path_to_the_gem"
   ```
2. Run `bundle install` to install the updated gem.
3. Run `bundle exec rails shakapacker:install` to confirm that you got the right changes.

**Note:** Ensure that you use bundle exec otherwise the installed shakapacker gem will run and not the one you are working on.

## CI Workflows

Shakapacker uses GitHub Actions for continuous integration. The CI workflows use **Yarn** as the package manager for consistency and reliability.

### Package Manager Choice

The project uses Yarn in CI workflows for the following reasons:

- Deterministic dependency resolution with `yarn.lock`
- Faster installation with offline mirror support
- Better workspace support for monorepo-style testing
- Consistent behavior across different Node.js versions

### Key CI Workflow Files

- `.github/workflows/test-bundlers.yml` - Tests webpack, rspack, and bundler switching
- `.github/workflows/ruby.yml` - Ruby test suite across Ruby/Rails versions
- `.github/workflows/node.yml` - Node.js test suite across Node versions
- `.github/workflows/generator.yml` - Generator installation tests
- `.github/workflows/dummy.yml` - Dummy app integration tests
- `.github/workflows/eslint-validation.yml` - ESLint configuration validation

All workflows use:

```yaml
- uses: actions/setup-node@v4
  with:
    cache: "yarn"
    cache-dependency-path: spec/dummy/yarn.lock
```

And install dependencies with:

```bash
yarn install
```

### CI Optimization: Path Filtering

To reduce CI costs and execution time, workflows use **path filtering** to run only when relevant files change:

- **Ruby workflow** - Only runs when Ruby files, gemspecs, Gemfile, or RuboCop config changes
- **Node workflow** - Only runs when JS/TS files, package.json, or Node config changes
- **Generator specs** - Only runs when generator-related files change
- **Dummy specs** - Only runs when dummy app or lib files change
- **Test bundlers** - Only runs when code affecting bundler integration changes

This means documentation-only PRs (e.g., only changing `README.md`) will skip all test workflows entirely.

**Important:** The full test suite always runs on pushes to the `main` branch to ensure the main branch is always thoroughly tested.

### Manual Workflow Execution

All workflows can be triggered manually via the GitHub Actions UI using the "Run workflow" button. This is useful for:

- Re-running tests after a temporary CI failure
- Testing workflows on specific branches without creating a PR
- Running full test suites on PRs that would normally skip certain workflows

### Conditional Linting

The Node workflow includes conditional execution of actionlint (GitHub Actions linter):

- Only downloads and runs when `.github/workflows/*` files change
- Saves time by skipping on most PRs
- Includes caching for faster execution when needed

### Testing with Other Package Managers

While CI uses Yarn, the gem supports all major package managers (npm, yarn, pnpm, bun). Generator specs test against all package managers to ensure compatibility.
