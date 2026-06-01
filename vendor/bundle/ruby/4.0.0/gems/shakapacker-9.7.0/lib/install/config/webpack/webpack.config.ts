// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
import { generateWebpackConfig } from 'shakapacker'
import type { Configuration } from 'webpack'

const webpackConfig: Configuration = generateWebpackConfig()

export default webpackConfig
