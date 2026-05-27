const fs = require("fs")
const os = require("os")
const path = require("path")

const ensureManifestExists =
  require("../../../package/utils/ensureManifestExists").default

describe("ensureManifestExists", () => {
  let tmpDir

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "shakapacker-test-"))
  })

  afterEach(() => {
    fs.rmSync(tmpDir, { recursive: true, force: true })
  })

  it("creates the manifest file with {} when it does not exist", () => {
    const manifestPath = path.join(tmpDir, "manifest.json")

    ensureManifestExists(manifestPath)

    expect(fs.existsSync(manifestPath)).toBe(true)
    expect(fs.readFileSync(manifestPath, "utf8")).toBe("{}")
  })

  it("does not overwrite an existing manifest file", () => {
    const manifestPath = path.join(tmpDir, "manifest.json")
    fs.writeFileSync(manifestPath, '{"existing": "data"}')

    ensureManifestExists(manifestPath)

    expect(fs.readFileSync(manifestPath, "utf8")).toBe('{"existing": "data"}')
  })

  it("creates missing parent directories", () => {
    const manifestPath = path.join(
      tmpDir,
      "deep",
      "nested",
      "dir",
      "manifest.json"
    )

    ensureManifestExists(manifestPath)

    expect(fs.existsSync(manifestPath)).toBe(true)
    expect(fs.readFileSync(manifestPath, "utf8")).toBe("{}")
  })
})
