// See the shakacode/shakapacker README and docs directory for advice on customizing your rspackConfig.
import { generateRspackConfig } from 'shakapacker/rspack'
import type { RspackOptions } from '@rspack/core'

const rspackConfig: RspackOptions = generateRspackConfig()

export default rspackConfig
