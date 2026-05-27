const {
  YamlSerializer
} = require("../../package/configExporter/yamlSerializer")

describe("YamlSerializer", () => {
  let serializer

  beforeEach(() => {
    serializer = new YamlSerializer({
      annotate: false,
      appRoot: "/test/app"
    })
  })

  describe("serialize", () => {
    test("includes metadata header in serialized output", () => {
      const config = { mode: "development" }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      expect(result).toContain("# Webpack/Rspack Configuration Export")
      expect(result).toContain("# Generated: 2025-01-15T12:00:00Z")
      expect(result).toContain("# Environment: development")
      expect(result).toContain("# Bundler: webpack")
      expect(result).toContain("# Config Type: client")
      expect(result).toContain("mode: development")
    })

    test("includes config count when multiple configs present", () => {
      const config = { mode: "production" }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "production",
        bundler: "rspack",
        configType: "server",
        configCount: 3
      }

      const result = serializer.serialize(config, metadata)

      expect(result).toContain("# Total Configs: 3")
    })

    test("omits config count when only one config present", () => {
      const config = { mode: "production" }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "production",
        bundler: "rspack",
        configType: "server",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      expect(result).not.toContain("# Total Configs:")
    })

    test("serializes simple objects correctly", () => {
      const config = {
        mode: "development",
        devtool: "source-map"
      }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      expect(result).toContain("mode: development")
      expect(result).toContain("devtool: source-map")
    })

    test("serializes nested objects", () => {
      const config = {
        output: {
          path: "/dist",
          filename: "bundle.js"
        }
      }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      expect(result).toContain("output:")
      expect(result).toContain("path: /dist")
      expect(result).toContain("filename: bundle.js")
    })

    test("handles empty objects with constructor names", () => {
      class CustomPlugin {}
      const config = {
        plugins: [new CustomPlugin()]
      }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      expect(result).toContain("plugins:")
      expect(result).toContain("CustomPlugin")
    })

    test("serializes arrays", () => {
      const config = {
        entry: ["./src/index.js", "./src/app.js"]
      }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      expect(result).toContain("entry:")
      expect(result).toContain("- ./src/index.js")
      expect(result).toContain("- ./src/app.js")
    })

    test("handles functions in config", () => {
      const config = {
        output: {
          filename() {
            return "bundle.js"
          }
        }
      }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      expect(result).toContain("output:")
      expect(result).toContain("filename: |")
      expect(result).toContain("filename()")
    })

    test("handles RegExp in config without flags", () => {
      const config = {
        test: /\.js$/
      }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      // RegExp objects serialize as their pattern without slashes
      expect(result).toContain("test: \\.js$")
    })

    test("handles RegExp with flags in config", () => {
      const config = {
        test: /\.js$/i
      }
      const metadata = {
        exportedAt: "2025-01-15T12:00:00Z",
        environment: "development",
        bundler: "webpack",
        configType: "client",
        configCount: 1
      }

      const result = serializer.serialize(config, metadata)

      // RegExp with flags includes flags as inline comment
      expect(result).toContain("test: \\.js$ # flags: i")
    })
  })
})
