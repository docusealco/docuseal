import { mkdirSync, writeFileSync } from "fs"
import { dirname } from "path"

// Note: This is only needed for webpack-assets-manifest (used in webpack.ts)
// which crashes with ENOENT when merge: true and the manifest file doesn't
// exist yet. rspack.ts uses rspack-manifest-plugin without merge: true,
// so it is not affected.
const ensureManifestExists = (manifestPath: string): void => {
  mkdirSync(dirname(manifestPath), { recursive: true })
  try {
    writeFileSync(manifestPath, "{}", { flag: "wx" })
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code !== "EEXIST") throw err
  }
}

export default ensureManifestExists
