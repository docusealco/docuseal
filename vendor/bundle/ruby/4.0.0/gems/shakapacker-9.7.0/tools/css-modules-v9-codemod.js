#!/usr/bin/env node

/**
 * Shakapacker v9 CSS Modules Codemod
 *
 * This codemod helps migrate CSS module imports from v8 (default exports)
 * to v9 (named exports for JS, namespace imports for TS).
 *
 * Usage:
 *   npx jscodeshift -t tools/css-modules-v9-codemod.js src/
 *   npx jscodeshift -t tools/css-modules-v9-codemod.js --parser tsx src/ (for TypeScript)
 *
 * Options:
 *   --dry                Run in dry mode (no files modified)
 *   --print              Print transformed files to stdout
 *   --parser tsx         Use TypeScript parser
 */

module.exports = function transformer(fileInfo, api) {
  const j = api.jscodeshift
  const root = j(fileInfo.source)
  let hasChanges = false

  // Detect if this is a TypeScript file
  const isTypeScript = fileInfo.path.match(/\.tsx?$/)

  // Find all CSS module imports
  root
    .find(j.ImportDeclaration, {
      source: {
        value: (value) =>
          value && value.match(/\.module\.(css|scss|sass|less)$/)
      }
    })
    .forEach((path) => {
      const importDecl = path.node

      // Check if it's a default import (v8 style)
      const defaultSpecifier = importDecl.specifiers.find(
        (spec) => spec.type === "ImportDefaultSpecifier"
      )

      if (!defaultSpecifier) {
        // Already using named or namespace imports, skip
        return
      }

      const defaultImportName = defaultSpecifier.local.name

      if (isTypeScript) {
        // For TypeScript: Convert to namespace import (import * as styles)
        const namespaceSpecifier = j.importNamespaceSpecifier(
          j.identifier(defaultImportName)
        )

        // Replace the import specifiers
        importDecl.specifiers = [namespaceSpecifier]
        hasChanges = true
      } else {
        // For JavaScript: Convert to named imports
        // First, we need to find all usages of the imported object
        const usages = new Set()

        // Find all member expressions using the imported default
        root
          .find(j.MemberExpression, {
            object: {
              type: "Identifier",
              name: defaultImportName
            }
          })
          .forEach((memberPath) => {
            // Handle both dot notation (styles.className) and bracket notation (styles['class-name'])
            if (
              memberPath.node.computed &&
              memberPath.node.property.type === "Literal"
            ) {
              // Computed property access: styles['active-button']
              const propertyValue = memberPath.node.property.value
              if (typeof propertyValue === "string") {
                usages.add(propertyValue)
              }
            } else if (
              !memberPath.node.computed &&
              memberPath.node.property.type === "Identifier"
            ) {
              // Dot notation: styles.activeButton
              const propertyName = memberPath.node.property.name
              if (propertyName) {
                usages.add(propertyName)
              }
            }
          })

        if (usages.size > 0) {
          // Create named import specifiers
          const namedSpecifiers = Array.from(usages)
            .sort()
            .map((name) => {
              // Handle kebab-case to camelCase conversion
              const camelCaseName = name.replace(/-([a-z])/g, (g) =>
                g[1].toUpperCase()
              )

              if (camelCaseName !== name) {
                // If conversion happened, we need to alias it
                return j.importSpecifier(
                  j.identifier(camelCaseName),
                  j.identifier(camelCaseName) // css-loader exports it as camelCase
                )
              }

              return j.importSpecifier(j.identifier(name))
            })

          // Replace the import specifiers
          importDecl.specifiers = namedSpecifiers

          // Update all usages in the file
          root
            .find(j.MemberExpression, {
              object: {
                type: "Identifier",
                name: defaultImportName
              }
            })
            .forEach((memberPath) => {
              let propertyName

              // Extract property name from both computed and dot notation
              if (
                memberPath.node.computed &&
                memberPath.node.property.type === "Literal"
              ) {
                propertyName = memberPath.node.property.value
              } else if (
                !memberPath.node.computed &&
                memberPath.node.property.type === "Identifier"
              ) {
                propertyName = memberPath.node.property.name
              }

              if (propertyName && typeof propertyName === "string") {
                // Convert kebab-case to camelCase
                const camelCaseName = propertyName.replace(/-([a-z])/g, (g) =>
                  g[1].toUpperCase()
                )
                // Replace with direct identifier
                j(memberPath).replaceWith(j.identifier(camelCaseName))
              }
            })

          hasChanges = true
        } else if (usages.size === 0) {
          // No usages found, might be passed as a whole object
          // In this case, convert to namespace import for safety
          const namespaceSpecifier = j.importNamespaceSpecifier(
            j.identifier(defaultImportName)
          )

          importDecl.specifiers = [namespaceSpecifier]
          hasChanges = true
        }
      }
    })

  if (!hasChanges) {
    return null // No changes made
  }

  return root.toSource({
    quote: "single",
    trailingComma: true,
    tabWidth: 2
  })
}

// Export the parser to use
module.exports.parser = "tsx"
