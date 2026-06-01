const { moduleExists } = require("../utils/helpers")
const { debug, info, warn } = require("../utils/debug")

debug("Loading Rspack rules configuration...")

const rules = []

// Use Rspack's built-in SWC loader for JavaScript files
debug("Adding JavaScript rule with builtin:swc-loader")
rules.push({
  test: /\.(js|jsx|mjs)$/,
  exclude: /node_modules/,
  // The 'type' field is required for Rspack to properly handle JavaScript modules
  // when using builtin loaders. It ensures correct module parsing and transformation.
  type: "javascript/auto",
  use: [
    {
      loader: "builtin:swc-loader",
      options: {
        jsc: {
          parser: {
            syntax: "ecmascript",
            jsx: true
          },
          transform: {
            react: {
              runtime: "automatic"
            }
          }
        }
      }
    }
  ]
})

// Use Rspack's built-in SWC loader for TypeScript files
debug("Adding TypeScript rule with builtin:swc-loader")
rules.push({
  test: /\.(ts|tsx)$/,
  exclude: /node_modules/,
  // The 'type' field is required for Rspack to properly handle TypeScript modules
  // when using builtin loaders. It ensures correct module parsing and transformation.
  type: "javascript/auto",
  use: [
    {
      loader: "builtin:swc-loader",
      options: {
        jsc: {
          parser: {
            syntax: "typescript",
            tsx: true
          },
          transform: {
            react: {
              runtime: "automatic"
            }
          }
        }
      }
    }
  ]
})

// CSS rules using Rspack's built-in CSS handling
debug("Checking for CSS loader...")
if (moduleExists("css-loader")) {
  debug("css-loader found, loading CSS rule configuration...")
  const css = require("./css")
  if (css) {
    debug("Successfully added CSS rule")
    rules.push(css)
  } else {
    warn("css-loader found but rule configuration returned null")
  }
} else {
  info("Skipping CSS support - css-loader not installed")
}

// Sass rules
debug("Checking for Sass loader...")
if (moduleExists("sass") && moduleExists("sass-loader")) {
  debug("sass and sass-loader found, loading Sass rule configuration...")
  const sass = require("./sass")
  if (sass) {
    debug("Successfully added Sass rule")
    rules.push(sass)
  } else {
    warn("sass and sass-loader found but rule configuration returned null")
  }
} else if (!moduleExists("sass")) {
  info("Skipping Sass support - sass not installed")
} else if (!moduleExists("sass-loader")) {
  info("Skipping Sass support - sass-loader not installed")
}

// Less rules
debug("Checking for Less loader...")
if (moduleExists("less") && moduleExists("less-loader")) {
  debug("less and less-loader found, loading Less rule configuration...")
  const less = require("./less")
  if (less) {
    debug("Successfully added Less rule")
    rules.push(less)
  } else {
    warn("less and less-loader found but rule configuration returned null")
  }
} else if (!moduleExists("less")) {
  info("Skipping Less support - less not installed")
} else if (!moduleExists("less-loader")) {
  info("Skipping Less support - less-loader not installed")
}

// Stylus rules
debug("Checking for Stylus loader...")
if (moduleExists("stylus") && moduleExists("stylus-loader")) {
  debug("stylus and stylus-loader found, loading Stylus rule configuration...")
  const stylus = require("./stylus")
  if (stylus) {
    debug("Successfully added Stylus rule")
    rules.push(stylus)
  } else {
    warn("stylus and stylus-loader found but rule configuration returned null")
  }
} else if (!moduleExists("stylus")) {
  info("Skipping Stylus support - stylus not installed")
} else if (!moduleExists("stylus-loader")) {
  info("Skipping Stylus support - stylus-loader not installed")
}

// ERB template support
debug("Checking for ERB template support...")
const erb = require("./erb")

if (erb) {
  debug("Successfully added ERB rule")
  rules.push(erb)
} else {
  info("Skipping ERB support - rails-erb-loader not installed")
}

// File/asset handling using Rspack's built-in asset modules
// This is a critical rule required for proper asset handling
debug("Adding file/asset handling rule...")
const file = require("./file")

if (!file) {
  throw new Error(
    "CRITICAL: file rule configuration returned null. " +
      "Asset handling is required for proper bundling. " +
      "Please ensure the file rule module exports a valid rule configuration."
  )
}

debug("Successfully added file/asset rule")
rules.push(file)

// Raw file loading
// This is a critical rule required for raw file imports
debug("Adding raw file loading rule...")
const raw = require("./raw")

if (!raw) {
  throw new Error(
    "CRITICAL: raw rule configuration returned null. " +
      "Raw file loading is required for proper bundling. " +
      "Please ensure the raw rule module exports a valid rule configuration."
  )
}

debug("Successfully added raw file rule")
rules.push(raw)

debug(`Rspack rules configuration complete. Total rules: ${rules.length}`)
export = rules
