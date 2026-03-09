const KEYWORDS = ['if', 'else', 'for', 'end']
const TYPE_PRIORITY = { string: 3, number: 2, boolean: 1 }
const AND_OR_REGEXP = /\s+(AND|OR)\s+/i
const COMPARISON_OPERATORS_REGEXP = />=|<=|!=|==|>|<|=/

function buildTokens (elem, acc = []) {
  if (elem.nodeType === Node.TEXT_NODE) {
    if (elem.textContent) {
      const text = elem.textContent
      const re = /[[\]]/g
      let match
      let found = false

      while ((match = re.exec(text)) !== null) {
        found = true

        acc.push({
          elem,
          value: match[0],
          textLength: text.length,
          index: match.index
        })
      }

      if (!found) {
        acc.push({ elem, value: '', textLength: 0, index: 0 })
      }
    }
  } else {
    for (const child of elem.childNodes) {
      buildTokens(child, acc)
    }
  }

  return acc
}

function tokensPair (cur, nxt) {
  if (cur.elem === nxt.elem) {
    return cur.elem.textContent.slice(cur.index + 1, nxt.index).trim() === ''
  } else {
    return cur.elem.textContent.slice(cur.index + 1).trim() === '' &&
           nxt.elem.textContent.slice(0, nxt.index).trim() === ''
  }
}

function buildTags (tokens) {
  const normalized = []

  for (let i = 0; i < tokens.length - 1; i++) {
    const cur = tokens[i]
    const nxt = tokens[i + 1]

    if (cur.value === '[' && nxt.value === '[' && tokensPair(cur, nxt)) {
      normalized.push(['open', cur])
    } else if (cur.value === ']' && nxt.value === ']' && tokensPair(cur, nxt)) {
      normalized.push(['close', nxt])
    }
  }

  const tags = []

  for (let i = 0; i < normalized.length - 1; i++) {
    const [curOp, openToken] = normalized[i]
    const [nxtOp, closeToken] = normalized[i + 1]

    if (curOp === 'open' && nxtOp === 'close') {
      tags.push({ openToken, closeToken, value: '' })
    }
  }

  return tags
}

function findTextNodesInBranch (elements, toElem, acc) {
  if (!elements || elements.length === 0) return acc

  for (const elem of elements) {
    if (elem.nodeType === Node.TEXT_NODE) {
      acc.push(elem)
    } else {
      findTextNodesInBranch(Array.from(elem.childNodes), toElem, acc)
    }

    if (acc.length > 0 && acc[acc.length - 1] === toElem) return acc
  }

  return acc
}

function findTextNodesBetween (fromElem, toElem, acc = []) {
  if (fromElem === toElem) return [fromElem]

  let currentElement = fromElem

  while (true) {
    const parent = currentElement.parentNode

    if (!parent) return acc

    const children = Array.from(parent.childNodes)
    const startIndex = children.indexOf(currentElement)

    if (startIndex === -1) return acc

    const elementsInBranch = children.slice(startIndex)

    findTextNodesInBranch(elementsInBranch, toElem, acc)

    if (acc.length > 0 && acc[acc.length - 1] === toElem) return acc

    let p = elementsInBranch[0].parentNode

    while (p && !p.nextSibling) {
      p = p.parentNode
    }

    if (!p || !p.nextSibling) return acc

    currentElement = p.nextSibling
  }
}

function mapTagValues (tags) {
  for (const tag of tags) {
    const textNodes = findTextNodesBetween(tag.openToken.elem, tag.closeToken.elem)

    for (const elem of textNodes) {
      let part

      if (tag.openToken.elem === elem && tag.closeToken.elem === elem) {
        part = elem.textContent.slice(tag.openToken.index, tag.closeToken.index + 1)
      } else if (tag.openToken.elem === elem) {
        part = elem.textContent.slice(tag.openToken.index)
      } else if (tag.closeToken.elem === elem) {
        part = elem.textContent.slice(0, tag.closeToken.index + 1)
      } else {
        part = elem.textContent
      }

      tag.value += part
    }
  }

  return tags
}

function parseTagTypeName (tagString) {
  const val = tagString.replace(/[[\]]/g, '').trim()
  const parts = val.split(':').map((s) => s.trim())

  if (parts.length === 2 && KEYWORDS.includes(parts[0])) {
    return [parts[0], parts[1]]
  } else if (KEYWORDS.includes(val)) {
    return [val, null]
  } else {
    return ['var', val]
  }
}

function isSimpleVariable (str) {
  const s = str.trim()

  return !AND_OR_REGEXP.test(s) &&
    !COMPARISON_OPERATORS_REGEXP.test(s) &&
    !s.includes('(') &&
    !s.includes('!') &&
    !s.includes('&&') &&
    !s.includes('||') &&
    !s.startsWith('"') &&
    !s.startsWith("'") &&
    !/^-?\d/.test(s) &&
    !/^(true|false)$/i.test(s)
}

function tokenizeCondition (str) {
  const tokens = []
  let pos = 0

  str = str.trim()

  while (pos < str.length) {
    const rest = str.slice(pos)
    let m

    if ((m = rest.match(/^\s+/))) {
      pos += m[0].length
    } else if ((m = rest.match(/^(>=|<=|!=|==|>|<|=)/))) {
      tokens.push({ type: 'operator', value: m[1] })
      pos += m[1].length
    } else if (rest[0] === '!') {
      tokens.push({ type: 'not', value: '!' })
      pos += 1
    } else if (rest[0] === '(') {
      tokens.push({ type: 'lparen', value: '(' })
      pos += 1
    } else if (rest[0] === ')') {
      tokens.push({ type: 'rparen', value: ')' })
      pos += 1
    } else if (rest.startsWith('&&')) {
      tokens.push({ type: 'and', value: 'AND' })
      pos += 2
    } else if ((m = rest.match(/^AND\b/i))) {
      tokens.push({ type: 'and', value: 'AND' })
      pos += 3
    } else if (rest.startsWith('||')) {
      tokens.push({ type: 'or', value: 'OR' })
      pos += 2
    } else if ((m = rest.match(/^OR\b/i))) {
      tokens.push({ type: 'or', value: 'OR' })
      pos += 2
    } else if ((m = rest.match(/^"([^"]*)"/) || rest.match(/^'([^']*)'/))) {
      tokens.push({ type: 'string', value: m[1] })
      pos += m[0].length
    } else if ((m = rest.match(/^(-?\d+\.?\d*)/))) {
      tokens.push({ type: 'number', value: m[1].includes('.') ? parseFloat(m[1]) : parseInt(m[1], 10) })
      pos += m[1].length
    } else if ((m = rest.match(/^(true|false)\b/i))) {
      tokens.push({ type: 'boolean', value: m[1].toLowerCase() === 'true' })
      pos += m[1].length
    } else if ((m = rest.match(/^([\p{L}_][\p{L}\p{N}_.]*)/u))) {
      tokens.push({ type: 'variable', value: m[1] })
      pos += m[1].length
    } else {
      pos += 1
    }
  }

  return tokens
}

function parseOrExpr (tokens, pos) {
  let left, right

  ;[left, pos] = parseAndExpr(tokens, pos)

  while (pos < tokens.length && tokens[pos].type === 'or') {
    pos += 1
    ;[right, pos] = parseAndExpr(tokens, pos)
    left = { type: 'or', left, right }
  }

  return [left, pos]
}

function parseAndExpr (tokens, pos) {
  let left, right

  ;[left, pos] = parsePrimary(tokens, pos)

  while (pos < tokens.length && tokens[pos].type === 'and') {
    pos += 1
    ;[right, pos] = parsePrimary(tokens, pos)
    left = { type: 'and', left, right }
  }

  return [left, pos]
}

function parsePrimary (tokens, pos) {
  if (pos >= tokens.length) return [null, pos]

  if (tokens[pos].type === 'not') {
    const [child, p] = parsePrimary(tokens, pos + 1)

    return [{ type: 'not', child }, p]
  }

  if (tokens[pos].type === 'lparen') {
    const [node, p] = parseOrExpr(tokens, pos + 1)

    return [node, p < tokens.length && tokens[p].type === 'rparen' ? p + 1 : p]
  }

  return parseComparisonOrPresence(tokens, pos)
}

function parseComparisonOrPresence (tokens, pos) {
  if (pos >= tokens.length || tokens[pos].type !== 'variable') return [null, pos]

  const variableName = tokens[pos].value

  pos += 1

  if (pos < tokens.length && tokens[pos].type === 'operator') {
    let operator = tokens[pos].value

    if (operator === '=') operator = '=='

    pos += 1

    if (pos < tokens.length && ['string', 'number', 'variable', 'boolean'].includes(tokens[pos].type)) {
      const valueToken = tokens[pos]

      return [{
        type: 'comparison',
        variableName,
        operator,
        value: valueToken.value,
        valueIsVariable: valueToken.type === 'variable'
      }, pos + 1]
    }
  }

  return [{ type: 'presence', variableName }, pos]
}

function parseCondition (conditionString) {
  const stripped = conditionString.trim()

  if (stripped.startsWith('!') && isSimpleVariable(stripped.slice(1))) {
    return { type: 'not', child: { type: 'presence', variableName: stripped.slice(1) } }
  }

  if (isSimpleVariable(stripped)) {
    return { type: 'presence', variableName: stripped }
  }

  const tokens = tokenizeCondition(stripped)
  const [ast] = parseOrExpr(tokens, 0)

  return ast
}

function extractConditionVariables (node, acc = []) {
  if (!node) return acc

  switch (node.type) {
    case 'or':
    case 'and':
      extractConditionVariables(node.left, acc)
      extractConditionVariables(node.right, acc)
      break
    case 'not':
      extractConditionVariables(node.child, acc)
      break
    case 'comparison':
      acc.push({
        name: node.variableName,
        type: node.valueIsVariable ? null : (typeof node.value === 'boolean' ? 'boolean' : (typeof node.value === 'number' ? 'number' : 'string'))
      })

      if (node.valueIsVariable) {
        acc.push({ name: node.value, type: null })
      }

      break
    case 'presence':
      acc.push({ name: node.variableName, type: 'boolean' })
      break
  }

  return acc
}

function singularize (word) {
  if (word.endsWith('ies')) return word.slice(0, -3) + 'y'
  if (word.endsWith('ches') || word.endsWith('shes')) return word.slice(0, -2)
  if (word.endsWith('ses') || word.endsWith('xes') || word.endsWith('zes')) return word.slice(0, -2)
  if (word.endsWith('s') && !word.endsWith('ss')) return word.slice(0, -1)

  return word
}

function buildOperators (tags) {
  const operators = []
  const stack = [{ children: operators, operator: null }]

  for (const tag of tags) {
    const [type, variableName] = parseTagTypeName(tag.value)

    switch (type) {
      case 'for':
      case 'if': {
        const operator = { type, variableName, tag, children: [] }

        if (type === 'if') {
          try {
            operator.condition = parseCondition(variableName)
          } catch (e) {
            // ignore parse errors
          }
        }

        stack[stack.length - 1].children.push(operator)
        stack.push({ children: operator.children, operator })
        break
      }
      case 'else': {
        const current = stack[stack.length - 1]

        if (current.operator && current.operator.type === 'if') {
          current.operator.elseTag = tag
          current.operator.elseChildren = []
          current.children = current.operator.elseChildren
        }

        break
      }
      case 'end': {
        const popped = stack.pop()

        if (popped.operator) {
          popped.operator.endTag = tag
        }

        break
      }
      case 'var':
        stack[stack.length - 1].children.push({ type, variableName, tag })
        break
    }
  }

  return operators
}

function assignNestedSchema (propertiesHash, parentProperties, keyString, value) {
  const keys = keyString.split('.')
  const lastKey = keys.pop()

  let currentLevel = null

  if (keys.length > 0 && parentProperties[keys[0]]) {
    currentLevel = keys.reduce((current, key) => {
      if (!current[key]) current[key] = { type: 'object', properties: {} }

      return current[key].properties
    }, parentProperties)
  }

  if (!currentLevel) {
    currentLevel = keys.reduce((current, key) => {
      if (!current[key]) current[key] = { type: 'object', properties: {} }

      return current[key].properties
    }, propertiesHash)
  }

  currentLevel[lastKey] = value
}

function assignNestedSchemaWithPriority (propertiesHash, parentProperties, keyString, newType) {
  const keys = keyString.split('.')
  const lastKey = keys.pop()

  let currentLevel = null

  if (keys.length > 0 && parentProperties[keys[0]]) {
    currentLevel = keys.reduce((current, key) => {
      if (!current[key]) current[key] = { type: 'object', properties: {} }

      return current[key].properties
    }, parentProperties)
  }

  if (!currentLevel) {
    currentLevel = keys.reduce((current, key) => {
      if (!current[key]) current[key] = { type: 'object', properties: {} }

      return current[key].properties
    }, propertiesHash)
  }

  const existing = currentLevel[lastKey]

  if (existing && (TYPE_PRIORITY[newType] || 0) <= (TYPE_PRIORITY[existing.type] || 0)) return

  currentLevel[lastKey] = { type: newType }
}

function processConditionVariables (condition, propertiesHash, parentProperties) {
  const variables = extractConditionVariables(condition)

  for (const varInfo of variables) {
    assignNestedSchemaWithPriority(propertiesHash, parentProperties, varInfo.name, varInfo.type || 'boolean')
  }
}

function processOperators (operators, propertiesHash = {}, parentProperties = {}) {
  if (!operators || operators.length === 0) return propertiesHash

  for (const op of operators) {
    switch (op.type) {
      case 'var': {
        if (!op.variableName.includes('.') && parentProperties[op.variableName]) {
          const item = parentProperties[op.variableName]

          if (item && item.type === 'object' && item.properties && Object.keys(item.properties).length === 0) {
            delete item.properties
            item.type = 'string'
          }
        } else {
          assignNestedSchema(propertiesHash, parentProperties, op.variableName, { type: 'string' })
        }
        break
      }
      case 'if':
        if (op.condition) {
          processConditionVariables(op.condition, propertiesHash, parentProperties)
        }

        processOperators(op.children, propertiesHash, parentProperties)
        processOperators(op.elseChildren, propertiesHash, parentProperties)
        break
      case 'for': {
        const parts = op.variableName.split('.')
        const singularKey = singularize(parts[parts.length - 1])

        let itemProperties = parentProperties[singularKey]?.items
        itemProperties = itemProperties || propertiesHash[parts[0]]?.items
        itemProperties = itemProperties || { type: 'object', properties: {} }

        assignNestedSchema(propertiesHash, parentProperties, op.variableName, { type: 'array', items: itemProperties })
        processOperators(op.children, propertiesHash, { ...parentProperties, [singularKey]: itemProperties })
        break
      }
    }
  }

  return propertiesHash
}

function mergeSchemaProperties (target, source) {
  for (const key of Object.keys(source)) {
    if (!target[key]) {
      target[key] = source[key]
    } else if (target[key].type === 'object' && source[key].type === 'object') {
      if (!target[key].properties) target[key].properties = {}
      if (source[key].properties) {
        mergeSchemaProperties(target[key].properties, source[key].properties)
      }
    } else if (target[key].type === 'array' && source[key].type === 'array') {
      if (source[key].items && source[key].items.properties) {
        if (!target[key].items) {
          target[key].items = source[key].items
        } else if (target[key].items.properties) {
          mergeSchemaProperties(target[key].items.properties, source[key].items.properties)
        }
      } else if (source[key].items && !target[key].items) {
        target[key].items = source[key].items
      }
    } else if ((TYPE_PRIORITY[source[key].type] || 0) > (TYPE_PRIORITY[target[key].type] || 0)) {
      target[key] = source[key]
    }
  }

  return target
}

function buildVariablesSchema (dom) {
  const tokens = buildTokens(dom)
  const tags = mapTagValues(buildTags(tokens))
  const operators = buildOperators(tags)

  return processOperators(operators)
}

export { buildVariablesSchema, mergeSchemaProperties, buildOperators, buildTokens, buildTags, mapTagValues }
