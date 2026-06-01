// @ts-ignore: webpack is an optional peer dependency (using type-only import)
import type { LoaderDefinitionFunction } from "webpack"

export interface ShakapackerLoaderOptions {
  [key: string]: unknown
}

export interface ShakapackerLoader {
  loader: string
  options?: ShakapackerLoaderOptions
}

export type LoaderResolver = (name: string) => string

export interface LoaderConfig {
  test: RegExp | ((value: string) => boolean)
  use: Array<string | ShakapackerLoader | LoaderDefinitionFunction>
  exclude?: RegExp | string | Array<string>
  include?: RegExp | string | Array<string>
  type?: string
  generator?: {
    filename?: string
    publicPath?: string
  }
}

export function resolveLoader(name: string): string
export function createLoader(config: LoaderConfig): LoaderConfig
