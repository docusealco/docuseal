import { resolve } from "path"

const configPath: string =
  process.env.SHAKAPACKER_CONFIG || resolve("config", "shakapacker.yml")

export = configPath
