const fs = require("fs")
const path = require("path")
const { execSync } = require("child_process")
const os = require("os")

describe("remove-use-strict script", () => {
  let tempDir

  beforeEach(() => {
    // Create a temporary directory for test files
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "remove-use-strict-test-"))
  })

  afterEach(() => {
    // Clean up the temporary directory
    fs.rmSync(tempDir, { recursive: true, force: true })
  })

  function createTestFile(filename, content) {
    const filePath = path.join(tempDir, filename)
    fs.writeFileSync(filePath, content, "utf8")
    return filePath
  }

  function runScript(directory) {
    // Run the script with a custom directory
    const scriptContent = fs.readFileSync(
      "scripts/remove-use-strict.js",
      "utf8"
    )
    // Replace 'package' with our test directory
    const modifiedScript = scriptContent.replace(
      'findJsFiles("package")',
      `findJsFiles("${directory}")`
    )
    const tempScript = path.join(tempDir, "test-script.js")
    fs.writeFileSync(tempScript, modifiedScript, "utf8")
    execSync(`node "${tempScript}"`, { stdio: "pipe" })
  }

  it("removes standard double-quoted use strict with semicolon", () => {
    const filePath = createTestFile("test1.js", '"use strict";\nconst x = 1;')
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
  })

  it("removes single-quoted use strict without semicolon", () => {
    const filePath = createTestFile("test2.js", "'use strict'\nconst x = 1;")
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
  })

  it("removes use strict with leading whitespace", () => {
    const filePath = createTestFile(
      "test3.js",
      '  \t"use strict";\nconst x = 1;'
    )
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
  })

  it("removes use strict with trailing whitespace and multiple newlines", () => {
    const filePath = createTestFile(
      "test4.js",
      '"use strict";  \n\n\nconst x = 1;'
    )
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
  })

  it("removes use strict with unicode quotes", () => {
    const filePath = createTestFile(
      "test5.js",
      "\u201Cuse strict\u201D;\nconst x = 1;"
    )
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
  })

  it("ensures trailing newline when missing", () => {
    const filePath = createTestFile("test6.js", '"use strict";\nconst x = 1')
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1\n")
    expect(result.endsWith("\n")).toBe(true)
  })

  it("preserves content that doesn't start with use strict", () => {
    const filePath = createTestFile(
      "test7.js",
      'const y = 2;\n"use strict";\nconst x = 1;'
    )
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe('const y = 2;\n"use strict";\nconst x = 1;\n')
  })

  it("handles files already ending with newline", () => {
    const filePath = createTestFile("test8.js", '"use strict";\nconst x = 1;\n')
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
    // Should have exactly one trailing newline, not double
    expect(result.match(/\n$/g)).toHaveLength(1)
  })

  it("handles Windows-style line endings", () => {
    const filePath = createTestFile("test9.js", '"use strict";\r\nconst x = 1;')
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
  })

  it("handles use strict with extra spaces", () => {
    const filePath = createTestFile("test10.js", '"use  strict";\nconst x = 1;')
    runScript(tempDir)
    const result = fs.readFileSync(filePath, "utf8")
    expect(result).toBe("const x = 1;\n")
  })
})
