/*
 * Portions of this file are derived from the Dentaku gem
 * https://github.com/rubysolo/dentaku
 *
 * MIT License
 *
 * Copyright (c) 2012 Solomon White
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Modifications and JavaScript port
 * Copyright (c) 2026 DocuSeal, LLC
 */

class CalculatorError extends Error { constructor (msg) { super(msg); this.name = 'CalculatorError' } }
class ParseError extends CalculatorError { constructor (msg) { super(msg); this.name = 'ParseError' } }
class TokenizerError extends CalculatorError { constructor (msg) { super(msg); this.name = 'TokenizerError' } }
class ArgumentError extends CalculatorError { constructor (msg) { super(msg); this.name = 'ArgumentError' } }
class ZeroDivisionError extends CalculatorError { constructor () { super('divided by 0'); this.name = 'ZeroDivisionError' } }
class UnboundVariableError extends CalculatorError {
  constructor (vars) {
    super('no value provided for variables: ' + vars.join(', '))
    this.name = 'UnboundVariableError'
    this.unbound = vars
  }
}

class Token {
  constructor (category, value, raw) {
    this.category = category
    this.value = value
    this.raw = raw == null ? String(value) : String(raw)
  }

  is (cat) { return this.category === cat }
}

const OPERATOR_NAMES = {
  '^': 'pow',
  '+': 'add',
  '-': 'subtract',
  '*': 'multiply',
  '/': 'divide',
  '%': 'mod',
  '|': 'bitor',
  '&': 'bitand',
  '<<': 'bitshiftleft',
  '>>': 'bitshiftright'
}
const COMPARATOR_NAMES = {
  '<=': 'le',
  '>=': 'ge',
  '!=': 'ne',
  '<>': 'ne',
  '<': 'lt',
  '>': 'gt',
  '==': 'eq',
  '=': 'eq'
}
const GROUPING_NAMES = { '(': 'open', ')': 'close', ',': 'comma' }

function buildScanners (caseSensitive) {
  return [
    (s) => {
      const m = /^\s+/.exec(s)
      return m ? { tokens: [], length: m[0].length } : null
    },
    (s) => {
      const m = /^null\b/i.exec(s)
      return m ? { tokens: [new Token('null', null, m[0])], length: m[0].length } : null
    },
    (s) => {
      const m = /^((?:\d+(?:\.\d+)?|\.\d+)(?:[eE][+-]?\d+)?)\b/.exec(s)
      if (!m) return null
      return { tokens: [new Token('numeric', Number(m[0]), m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^0x[0-9a-f]+\b/i.exec(s)
      if (!m) return null
      return { tokens: [new Token('numeric', parseInt(m[0].slice(2), 16), m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^"([^"]*)"/.exec(s)
      if (!m) return null
      return { tokens: [new Token('string', m[1], m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^'([^']*)'/.exec(s)
      if (!m) return null
      return { tokens: [new Token('string', m[1], m[0])], length: m[0].length }
    },
    (s, last) => {
      if (s[0] !== '-') return null
      const ok = last == null ||
        last.is('operator') ||
        last.is('comparator') ||
        last.is('combinator') ||
        last.value === 'open' ||
        last.value === 'comma' ||
        last.value === 'array_start'
      if (!ok) return null
      return { tokens: [new Token('operator', 'negate', '-')], length: 1 }
    },
    (s) => {
      const m = /^(and|or|&&|\|\|)\s/i.exec(s)
      if (!m) return null
      const raw = m[1].toLowerCase()
      const name = raw === '&&' ? 'and' : raw === '||' ? 'or' : raw
      return { tokens: [new Token('combinator', name, m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^(<<|>>|\^|\+|-|\*|\/|%|\||&)/.exec(s)
      if (!m) return null
      return { tokens: [new Token('operator', OPERATOR_NAMES[m[0]], m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^(\(|\)|,)/.exec(s)
      if (!m) return null
      return { tokens: [new Token('grouping', GROUPING_NAMES[m[0]], m[0])], length: m[0].length }
    },
    (s) => {
      if (s[0] === '{') return { tokens: [new Token('array', 'array_start', '{')], length: 1 }
      if (s[0] === '}') return { tokens: [new Token('array', 'array_end', '}')], length: 1 }
      return null
    },
    (s) => {
      const m = /^(<=|>=|!=|<>|==|=|<|>)/.exec(s)
      if (!m) return null
      return { tokens: [new Token('comparator', COMPARATOR_NAMES[m[0]], m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^(true|false)\b/i.exec(s)
      if (!m) return null
      return { tokens: [new Token('logical', m[0].toLowerCase() === 'true', m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^(\w+!?)\s*\(/.exec(s)
      if (!m) return null
      const name = m[1].toLowerCase()
      return {
        tokens: [
          new Token('function', name, m[1]),
          new Token('grouping', 'open', '(')
        ],
        length: m[0].length
      }
    },
    (s) => {
      const m = /^[A-Za-z_][\w.]*\b/.exec(s)
      if (!m) return null
      const value = caseSensitive ? m[0] : m[0].toLowerCase()
      return { tokens: [new Token('identifier', value, m[0])], length: m[0].length }
    },
    (s) => {
      const m = /^`([^`]*)`/.exec(s)
      if (!m) return null
      return { tokens: [new Token('identifier', m[1], m[0])], length: m[0].length }
    }
  ]
}

function tokenize (input, options) {
  options = options || {}
  let remaining = String(input).replace(/\/\*[\s\S]*?\*\//g, '')
  const scanners = buildScanners(options.caseSensitive === true)
  const tokens = []
  let nesting = 0

  while (remaining.length > 0) {
    let matched = false
    for (let i = 0; i < scanners.length; i++) {
      const result = scanners[i](remaining, tokens.length ? tokens[tokens.length - 1] : null)
      if (result) {
        for (const tok of result.tokens) {
          if (tok.category === 'grouping' && tok.value === 'open') nesting++
          if (tok.category === 'grouping' && tok.value === 'close') {
            nesting--
            if (nesting < 0) throw new TokenizerError('too many closing parentheses')
          }
          tokens.push(tok)
        }
        remaining = remaining.slice(result.length)
        matched = true
        break
      }
    }
    if (!matched) throw new TokenizerError("parse error at: '" + remaining + "'")
  }
  if (nesting > 0) throw new TokenizerError('too many opening parentheses')
  return tokens
}

function uniq (arr) {
  const seen = new Set()
  const out = []
  for (const x of arr) { if (!seen.has(x)) { seen.add(x); out.push(x) } }
  return out
}

function toNumber (val) {
  if (typeof val === 'number') return val
  if (typeof val === 'boolean') return val ? 1 : 0
  if (val == null) throw new ArgumentError("'" + val + "' is not coercible to numeric")
  if (typeof val === 'string') {
    if (val.length === 0) throw new ArgumentError("'' is not coercible to numeric")
    const n = Number(val)
    if (isNaN(n)) throw new ArgumentError("'" + val + "' is not coercible to numeric")
    return n
  }
  throw new ArgumentError("'" + val + "' is not coercible to numeric")
}

class Node {
  static precedence = 0
  static arity = null
  static rightAssociative = false
  static resolveClass () { return this }
  static minParamCount () { return this.arity }
  static maxParamCount () { return this.arity }
  value () { return null }
  dependencies () { return [] }
  get type () { return null }
}

class NilNode extends Node { value () { return null } }

class Numeric extends Node {
  constructor (token) { super(); this.v = token.value }
  value () { return this.v }
  get type () { return 'numeric' }
}

class Logical extends Node {
  constructor (token) { super(); this.v = token.value }
  value () { return this.v }
  get type () { return 'logical' }
}

class StringNode extends Node {
  constructor (token) { super(); this.v = token.value }
  value () { return this.v }
  get type () { return 'string' }
}

class Identifier extends Node {
  constructor (token) { super(); this.ident = token.value }
  value (ctx) {
    if (ctx && (this.ident in ctx)) {
      const v = ctx[this.ident]
      if (v instanceof Node) return v.value(ctx)
      if (typeof v === 'function') return v()
      return v
    }
    throw new UnboundVariableError([this.ident])
  }

  dependencies (ctx) {
    if (ctx && (this.ident in ctx)) {
      const v = ctx[this.ident]
      return v instanceof Node ? v.dependencies(ctx) : []
    }
    return [this.ident]
  }
}

class Grouping extends Node {
  constructor (node) { super(); this.node = node }
  value (ctx) { return this.node.value(ctx) }
  get type () { return this.node.type }
  dependencies (ctx) { return this.node.dependencies(ctx) }
}

class Operation extends Node {
  constructor (left, right) { super(); this.left = left; this.right = right }
  dependencies (ctx) {
    const l = this.left ? this.left.dependencies(ctx) : []
    const r = this.right ? this.right.dependencies(ctx) : []
    return uniq(l.concat(r))
  }
}

class Arithmetic extends Operation { get type () { return 'numeric' } }

class Addition extends Arithmetic {
  static precedence = 10
  value (ctx) {
    const l = this.left.value(ctx)
    const r = this.right.value(ctx)
    if (typeof l === 'string' || typeof r === 'string') return String(l) + String(r)
    return toNumber(l) + toNumber(r)
  }
}

class Subtraction extends Arithmetic {
  static precedence = 10
  value (ctx) { return toNumber(this.left.value(ctx)) - toNumber(this.right.value(ctx)) }
}

class Multiplication extends Arithmetic {
  static precedence = 20
  value (ctx) { return toNumber(this.left.value(ctx)) * toNumber(this.right.value(ctx)) }
}

class Division extends Arithmetic {
  static precedence = 20
  value (ctx) {
    const r = toNumber(this.right.value(ctx))
    if (r === 0) throw new ZeroDivisionError()
    return toNumber(this.left.value(ctx)) / r
  }
}

class Modulo extends Arithmetic {
  static arity = 2
  static precedence = 20
  static resolveClass (nextTok) {
    if (!nextTok) return Percentage
    if (nextTok.category === 'operator') return Percentage
    if (nextTok.category === 'comparator') return Percentage
    if (nextTok.category === 'combinator') return Percentage
    if (nextTok.category === 'grouping' && (nextTok.value === 'close' || nextTok.value === 'comma')) return Percentage
    if (nextTok.category === 'array' && nextTok.value === 'array_end') return Percentage
    return Modulo
  }

  value (ctx) {
    const r = toNumber(this.right.value(ctx))
    if (r === 0) throw new ZeroDivisionError()
    return toNumber(this.left.value(ctx)) % r
  }
}

class Percentage extends Arithmetic {
  static arity = 1
  static precedence = 30
  constructor (child) { super(child, null) }
  value (ctx) { return toNumber(this.left.value(ctx)) * 0.01 }
  dependencies (ctx) { return this.left.dependencies(ctx) }
}

class Exponentiation extends Arithmetic {
  static precedence = 30
  static rightAssociative = true
  value (ctx) { return Math.pow(toNumber(this.left.value(ctx)), toNumber(this.right.value(ctx))) }
}

class Negation extends Arithmetic {
  static arity = 1
  static precedence = 40
  static rightAssociative = true
  constructor (node) { super(node, null) }
  value (ctx) { return -toNumber(this.left.value(ctx)) }
  dependencies (ctx) { return this.left.dependencies(ctx) }
}

class BitwiseOr extends Operation {
  static precedence = 10
  value (ctx) { return toNumber(this.left.value(ctx)) | toNumber(this.right.value(ctx)) }
  get type () { return 'numeric' }
}
class BitwiseAnd extends Operation {
  static precedence = 10
  value (ctx) { return toNumber(this.left.value(ctx)) & toNumber(this.right.value(ctx)) }
  get type () { return 'numeric' }
}
class BitwiseShiftLeft extends Operation {
  static precedence = 10
  value (ctx) { return toNumber(this.left.value(ctx)) << toNumber(this.right.value(ctx)) }
  get type () { return 'numeric' }
}
class BitwiseShiftRight extends Operation {
  static precedence = 10
  value (ctx) { return toNumber(this.left.value(ctx)) >> toNumber(this.right.value(ctx)) }
  get type () { return 'numeric' }
}

function cmpCast (v) {
  if (typeof v === 'string' && /^-?\d*\.?\d+$/.test(v)) return Number(v)
  return v
}
class Comparator extends Operation {
  static precedence = 5
  get type () { return 'logical' }
}
class LessThan extends Comparator { value (ctx) { return cmpCast(this.left.value(ctx)) < cmpCast(this.right.value(ctx)) } }
class LessThanOrEqual extends Comparator { value (ctx) { return cmpCast(this.left.value(ctx)) <= cmpCast(this.right.value(ctx)) } }
class GreaterThan extends Comparator { value (ctx) { return cmpCast(this.left.value(ctx)) > cmpCast(this.right.value(ctx)) } }
class GreaterThanOrEqual extends Comparator { value (ctx) { return cmpCast(this.left.value(ctx)) >= cmpCast(this.right.value(ctx)) } }
class NotEqual extends Comparator {
  value (ctx) {
    const l = cmpCast(this.left.value(ctx))
    const r = cmpCast(this.right.value(ctx))
    return l !== r
  }
}
class Equal extends Comparator {
  value (ctx) {
    const l = cmpCast(this.left.value(ctx))
    const r = cmpCast(this.right.value(ctx))
    return l === r
  }
}

class Combinator extends Operation {
  static precedence = 0
  get type () { return 'logical' }
}
class And extends Combinator { value (ctx) { return Boolean(this.left.value(ctx)) && Boolean(this.right.value(ctx)) } }
class Or extends Combinator { value (ctx) { return Boolean(this.left.value(ctx)) || Boolean(this.right.value(ctx)) } }

class ArrayNode extends Node {
  static arity = null
  static minParamCount () { return 0 }
  static maxParamCount () { return Infinity }
  constructor (...items) {
    super()
    this.items = items
  }

  value (ctx) { return this.items.map((i) => i.value(ctx)) }
  dependencies (ctx) {
    return uniq([].concat.apply([], this.items.map((i) => i.dependencies(ctx))))
  }

  get type () { return 'array' }
}

class FunctionNode extends Node {
  static arity = null
  static minParamCount () { return 0 }
  static maxParamCount () { return Infinity }
  constructor (...args) {
    super()
    this.args = args
  }

  dependencies (ctx) {
    return uniq([].concat.apply([], this.args.map((a) => a.dependencies(ctx))))
  }
}

const FUNCTION_REGISTRY = Object.create(null)
function registerFunctionClass (name, cls) { FUNCTION_REGISTRY[name.toLowerCase()] = cls }
function getFunctionClass (name) { return FUNCTION_REGISTRY[name.toLowerCase()] }

function defineFunction (name, spec) {
  const min = spec.min == null ? 0 : spec.min
  const max = spec.max == null ? Infinity : spec.max
  const call = spec.call
  const type = spec.type || 'numeric'
  class F extends FunctionNode {
    static arity = (min === max) ? min : null
    static minParamCount () { return min }
    static maxParamCount () { return max }
    value (ctx) {
      const vals = this.args.map((a) => a.value(ctx))
      return call(vals, ctx)
    }

    get type () { return type }
  }
  registerFunctionClass(name, F)
  return F
}

function flattenNumeric (vals) {
  const out = [];
  (function walk (v) {
    if (Array.isArray(v)) v.forEach(walk)
    else out.push(toNumber(v))
  })(vals)
  return out
}

defineFunction('abs', { min: 1, max: 1, call: (v) => Math.abs(toNumber(v[0])) })
defineFunction('min', { min: 1, call: (v) => Math.min.apply(null, flattenNumeric(v)) })
defineFunction('max', { min: 1, call: (v) => Math.max.apply(null, flattenNumeric(v)) })
defineFunction('sum', { min: 1, call: (v) => flattenNumeric(v).reduce((a, b) => a + b, 0) })
defineFunction('avg', {
  min: 1,
  call: (v) => {
    const nums = flattenNumeric(v)
    if (nums.length === 0) return 0
    return nums.reduce((a, b) => a + b, 0) / nums.length
  }
})
defineFunction('count', {
  min: 1,
  max: 1,
  call: (v) => Array.isArray(v[0]) ? v[0].length : (v[0] == null ? 0 : 1)
})
defineFunction('round', {
  min: 1,
  max: 2,
  call: (v) => {
    const n = toNumber(v[0])
    const p = v.length > 1 ? toNumber(v[1]) : 0
    const f = Math.pow(10, p)
    return Math.round(n * f) / f
  }
})
defineFunction('roundup', {
  min: 1,
  max: 2,
  call: (v) => {
    const n = toNumber(v[0])
    const p = v.length > 1 ? toNumber(v[1]) : 0
    const f = Math.pow(10, p)
    return (n < 0 ? -Math.floor(-n * f) : Math.ceil(n * f)) / f
  }
})
defineFunction('rounddown', {
  min: 1,
  max: 2,
  call: (v) => {
    const n = toNumber(v[0])
    const p = v.length > 1 ? toNumber(v[1]) : 0
    const f = Math.pow(10, p)
    return (n < 0 ? -Math.ceil(-n * f) : Math.floor(n * f)) / f
  }
})

const MATH_FNS = {
  sqrt: Math.sqrt,
  cbrt: Math.cbrt,
  sin: Math.sin,
  cos: Math.cos,
  tan: Math.tan,
  asin: Math.asin,
  acos: Math.acos,
  atan: Math.atan,
  sinh: Math.sinh,
  cosh: Math.cosh,
  tanh: Math.tanh,
  exp: Math.exp,
  log: Math.log,
  log2: Math.log2,
  log10: Math.log10,
  floor: Math.floor,
  ceil: Math.ceil
}
Object.keys(MATH_FNS).forEach((name) => {
  const fn = MATH_FNS[name]
  defineFunction(name, { min: 1, max: 1, call: (v) => fn(toNumber(v[0])) })
})
defineFunction('atan2', { min: 2, max: 2, call: (v) => Math.atan2(toNumber(v[0]), toNumber(v[1])) })
defineFunction('hypot', { min: 1, call: (v) => Math.hypot.apply(null, flattenNumeric(v)) })
defineFunction('pow', { min: 2, max: 2, call: (v) => Math.pow(toNumber(v[0]), toNumber(v[1])) })
defineFunction('pi', { min: 0, max: 0, call: () => Math.PI })
defineFunction('e', { min: 0, max: 0, call: () => Math.E })

defineFunction('not', { min: 1, max: 1, type: 'logical', call: (v) => !v[0] })
defineFunction('and', { min: 1, type: 'logical', call: (v) => v.every((x) => Boolean(x)) })
defineFunction('or', { min: 1, type: 'logical', call: (v) => v.some((x) => Boolean(x)) })
defineFunction('xor', {
  min: 2,
  type: 'logical',
  call: (v) => v.reduce((acc, x) => acc !== Boolean(x), false)
})

class IfFunction extends FunctionNode {
  static arity = 3
  static minParamCount () { return 3 }
  static maxParamCount () { return 3 }
  value (ctx) {
    return this.args[0].value(ctx) ? this.args[1].value(ctx) : this.args[2].value(ctx)
  }

  get type () { return this.args[1].type }
  dependencies (ctx) {
    try {
      return this.args[0].value(ctx) ? this.args[1].dependencies(ctx) : this.args[2].dependencies(ctx)
    } catch (e) {
      return uniq([].concat.apply([], this.args.map((a) => a.dependencies(ctx))))
    }
  }
}
registerFunctionClass('if', IfFunction)

defineFunction('length', { min: 1, max: 1, call: (v) => v[0] == null ? 0 : String(v[0]).length })
defineFunction('upcase', { min: 1, max: 1, type: 'string', call: (v) => String(v[0]).toUpperCase() })
defineFunction('downcase', { min: 1, max: 1, type: 'string', call: (v) => String(v[0]).toLowerCase() })
defineFunction('concat', { min: 1, type: 'string', call: (v) => v.map((x) => String(x)).join('') })
defineFunction('left', {
  min: 2,
  max: 2,
  type: 'string',
  call: (v) => String(v[0]).slice(0, toNumber(v[1]))
})
defineFunction('right', {
  min: 2,
  max: 2,
  type: 'string',
  call: (v) => {
    const n = toNumber(v[1])
    return n === 0 ? '' : String(v[0]).slice(-n)
  }
})
defineFunction('mid', {
  min: 3,
  max: 3,
  type: 'string',
  call: (v) => {
    const s = String(v[0])
    const start = toNumber(v[1]) - 1
    const len = toNumber(v[2])
    return s.slice(start, start + len)
  }
})
defineFunction('trim', { min: 1, max: 1, type: 'string', call: (v) => String(v[0]).trim() })
defineFunction('contains', {
  min: 2,
  max: 2,
  type: 'logical',
  call: (v) => {
    if (Array.isArray(v[0])) return v[0].indexOf(v[1]) !== -1
    return String(v[0]).indexOf(String(v[1])) !== -1
  }
})

const OP_CLASSES = {
  add: Addition,
  subtract: Subtraction,
  multiply: Multiplication,
  divide: Division,
  pow: Exponentiation,
  negate: Negation,
  mod: Modulo,
  bitor: BitwiseOr,
  bitand: BitwiseAnd,
  bitshiftleft: BitwiseShiftLeft,
  bitshiftright: BitwiseShiftRight,
  lt: LessThan,
  gt: GreaterThan,
  le: LessThanOrEqual,
  ge: GreaterThanOrEqual,
  ne: NotEqual,
  eq: Equal,
  and: And,
  or: Or
}

function isOperationClass (cls) {
  return cls && (cls.prototype instanceof Operation)
}

function parse (tokens) {
  if (!tokens || tokens.length === 0) return new NilNode()

  const output = []
  const operations = []
  const arities = []
  const skip = new Set()

  function consume (count) {
    if (count == null) count = 2
    const op = operations.pop()
    if (!op) throw new ParseError('invalid statement')

    const outputSize = output.length
    const opMin = (typeof op.minParamCount === 'function') ? op.minParamCount() : null
    const opMax = (typeof op.maxParamCount === 'function') ? op.maxParamCount() : null

    const actualArgs = (op.arity != null) ? op.arity : count
    const minSize = (op.arity != null) ? op.arity : (opMin != null ? opMin : count)
    const maxSize = (op.arity != null) ? op.arity : (opMax != null ? opMax : count)

    if (outputSize < minSize || actualArgs < minSize) {
      throw new ParseError((op.name || 'operator') + ' has too few operands (given ' + outputSize + ', expected ' + minSize + ')')
    }
    if ((outputSize > maxSize && operations.length === 0) || actualArgs > maxSize) {
      throw new ParseError((op.name || 'operator') + ' has too many operands (given ' + outputSize + ', expected ' + maxSize + ')')
    }

    if (op === ArrayNode && output.length === 0) {
      output.push(new ArrayNode())
      return
    }

    if (outputSize < actualArgs) throw new ParseError('invalid statement')
    const args = []
    for (let i = 0; i < actualArgs; i++) args.unshift(output.pop())

    // eslint-disable-next-line new-cap
    output.push(new op(...args))
  }

  function handleOperator (token, lookahead) {
    let cls = OP_CLASSES[token.value]
    if (!cls) throw new ParseError('Unknown operator ' + token.value)
    if (typeof cls.resolveClass === 'function') cls = cls.resolveClass(lookahead)
    const prec = cls.precedence
    if (cls.rightAssociative) {
      while (operations.length > 0) {
        const top = operations[operations.length - 1]
        if (isOperationClass(top) && prec < top.precedence) consume()
        else break
      }
    } else {
      while (operations.length > 0) {
        const top = operations[operations.length - 1]
        if (isOperationClass(top) && prec <= top.precedence) consume()
        else break
      }
    }
    operations.push(cls)
  }

  function handleFunction (token) {
    const fn = getFunctionClass(token.value)
    if (!fn) throw new ParseError('Undefined function ' + token.value)
    arities.push(0)
    operations.push(fn)
  }

  function handleArray (token) {
    if (token.value === 'array_start') {
      operations.push(ArrayNode)
      arities.push(0)
    } else {
      while (operations.length > 0 && operations[operations.length - 1] !== ArrayNode) consume()
      if (operations[operations.length - 1] !== ArrayNode) throw new ParseError('Unbalanced bracket')
      consume(arities.pop() + 1)
    }
  }

  function handleGrouping (token, lookahead, index) {
    if (token.value === 'open') {
      if (lookahead && lookahead.value === 'close') {
        skip.add(index + 1)
        arities.pop()
        consume(0)
      } else {
        operations.push(Grouping)
      }
    } else if (token.value === 'close') {
      while (operations.length > 0 && operations[operations.length - 1] !== Grouping) consume()
      const lparen = operations.pop()
      if (lparen !== Grouping) throw new ParseError('Unbalanced parenthesis')
      const top = operations[operations.length - 1]
      if (top && (top.prototype instanceof FunctionNode)) consume(arities.pop() + 1)
    } else if (token.value === 'comma') {
      if (arities.length === 0) throw new ParseError('invalid statement')
      arities[arities.length - 1] += 1
      while (operations.length > 0 &&
             operations[operations.length - 1] !== Grouping &&
             operations[operations.length - 1] !== ArrayNode) consume()
    } else {
      throw new ParseError('Unknown grouping token ' + token.value)
    }
  }

  for (let i = 0; i < tokens.length; i++) {
    if (skip.has(i)) continue
    const token = tokens[i]
    const lookahead = tokens[i + 1]

    switch (token.category) {
      case 'numeric': output.push(new Numeric(token)); break
      case 'logical': output.push(new Logical(token)); break
      case 'string': output.push(new StringNode(token)); break
      case 'identifier': output.push(new Identifier(token)); break
      case 'null': output.push(new NilNode()); break
      case 'operator':
      case 'comparator':
      case 'combinator':
        handleOperator(token, lookahead); break
      case 'function': handleFunction(token); break
      case 'array': handleArray(token); break
      case 'grouping': handleGrouping(token, lookahead, i); break
      default:
        throw new ParseError('Not implemented for tokens of category ' + token.category)
    }
  }

  while (operations.length > 0) consume()

  if (output.length !== 1) throw new ParseError('Invalid statement')
  return output[0]
}

class Calculator {
  constructor (options) {
    options = options || {}
    this.caseSensitive = options.caseSensitive === true
    this.memory = Object.create(null)
    this._astCache = Object.create(null)
  }

  key (k) { return this.caseSensitive ? k : String(k).toLowerCase() }

  normalize (data) {
    const out = Object.create(null)
    if (!data) return out
    for (const k of Object.keys(data)) out[this.key(k)] = data[k]
    return out
  }

  store (data) { Object.assign(this.memory, this.normalize(data)); return this }
  bind (data) { return this.store(data) }
  clear () { this.memory = Object.create(null); return this }

  ast (expression) {
    const cached = this._astCache[expression]
    if (cached) return cached
    const node = parse(tokenize(expression, { caseSensitive: this.caseSensitive }))
    this._astCache[expression] = node
    return node
  }

  tokenize (expression) {
    return tokenize(expression, { caseSensitive: this.caseSensitive })
  }

  dependencies (expression) {
    return this.ast(expression).dependencies(this.memory)
  }

  evaluate (expression, data, onError) {
    try {
      return this.evaluateStrict(expression, data)
    } catch (e) {
      if (typeof data === 'function') return data(expression, e)
      if (typeof onError === 'function') return onError(expression, e)
      return undefined
    }
  }

  evaluateStrict (expression, data) {
    const ctx = Object.assign(Object.create(null), this.memory, this.normalize(data))
    const node = this.ast(expression)
    return node.value(ctx)
  }

  addFunction (name, spec) {
    defineFunction(name, {
      min: spec.minArgs == null ? (spec.min == null ? 0 : spec.min) : spec.minArgs,
      max: spec.maxArgs == null ? (spec.max == null ? Infinity : spec.max) : spec.maxArgs,
      type: spec.type || 'numeric',
      call: spec.call
    })
    return this
  }
}

export {
  Calculator,
  tokenize,
  parse,
  CalculatorError,
  ParseError,
  TokenizerError,
  UnboundVariableError,
  ZeroDivisionError,
  ArgumentError
}

export function addFunction (name, spec) { defineFunction(name, spec) }
