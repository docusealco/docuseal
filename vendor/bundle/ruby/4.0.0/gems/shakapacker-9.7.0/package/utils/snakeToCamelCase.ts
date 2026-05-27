function snakeToCamelCase(s: string): string {
  return s.replace(/(_\w)/g, (match) => match[1].toUpperCase())
}

export = snakeToCamelCase
