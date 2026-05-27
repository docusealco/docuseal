#!/usr/bin/env node
const fs = require("fs")
const path = require("path")

// Recursively find all .js files in a directory
function findJsFiles(dir) {
  const files = []
  const items = fs.readdirSync(dir, { withFileTypes: true })

  items.forEach((item) => {
    const fullPath = path.join(dir, item.name)
    if (item.isDirectory()) {
      files.push(...findJsFiles(fullPath))
    } else if (item.isFile() && item.name.endsWith(".js")) {
      files.push(fullPath)
    }
  })

  return files
}

// Find all .js files in package directory
const files = findJsFiles("package")

files.forEach((file) => {
  let content = fs.readFileSync(file, "utf8")

  // Remove "use strict" directive with various quote styles and formatting
  // Handles: optional whitespace, single/double/unicode quotes, optional semicolon,
  // and any trailing whitespace/newline sequences
  content = content.replace(
    /^\s*["'\u2018\u2019\u201C\u201D]use\s+strict["'\u2018\u2019\u201C\u201D]\s*;?\s*[\r\n]*/,
    ""
  )

  // Ensure file ends with exactly one newline
  if (!content.endsWith("\n")) {
    content += "\n"
  }

  fs.writeFileSync(file, content, "utf8")
})

console.log(`Removed "use strict" from ${files.length} files`)
