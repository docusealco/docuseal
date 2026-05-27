/**
 * Client-side C syntax highlighter for RDoc
 */

(function() {
  'use strict';

  // C control flow and storage class keywords
  const C_KEYWORDS = new Set([
    'auto', 'break', 'case', 'continue', 'default', 'do', 'else', 'extern',
    'for', 'goto', 'if', 'inline', 'register', 'return', 'sizeof', 'static',
    'switch', 'while',
    '_Alignas', '_Alignof', '_Generic', '_Noreturn', '_Static_assert', '_Thread_local'
  ]);

  // C type keywords and type qualifiers
  const C_TYPE_KEYWORDS = new Set([
    'bool', 'char', 'const', 'double', 'enum', 'float', 'int', 'long',
    'restrict', 'short', 'signed', 'struct', 'typedef', 'union', 'unsigned',
    'void', 'volatile', '_Atomic', '_Bool', '_Complex', '_Imaginary'
  ]);

  // Library-defined types (typedef'd in headers, not language keywords)
  // Includes: Ruby C API types (VALUE, ID), POSIX types (size_t, ssize_t),
  // fixed-width integer types (uint32_t, int64_t), and standard I/O types (FILE)
  const C_TYPES = new Set([
    'VALUE', 'ID', 'size_t', 'ssize_t', 'ptrdiff_t', 'uintptr_t', 'intptr_t',
    'uint8_t', 'uint16_t', 'uint32_t', 'uint64_t',
    'int8_t', 'int16_t', 'int32_t', 'int64_t',
    'FILE', 'DIR', 'va_list'
  ]);

  // Common Ruby VALUE macros and boolean literals
  const RUBY_MACROS = new Set([
    'Qtrue', 'Qfalse', 'Qnil', 'Qundef', 'NULL', 'TRUE', 'FALSE', 'true', 'false'
  ]);

  const OPERATORS = new Set([
    '==', '!=', '<=', '>=', '&&', '||', '<<', '>>', '++', '--',
    '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '->',
    '+', '-', '*', '/', '%', '<', '>', '=', '!', '&', '|', '^', '~'
  ]);

  // Single character that can start an operator
  const OPERATOR_CHARS = new Set('+-*/%<>=!&|^~');

  function isMacro(word) {
    return RUBY_MACROS.has(word) || /^[A-Z][A-Z0-9_]*$/.test(word);
  }

  function isType(word) {
    return C_TYPE_KEYWORDS.has(word) || C_TYPES.has(word) || /_t$/.test(word);
  }

  /**
   * Escape HTML special characters
   */
  function escapeHtml(text) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  /**
   * Check if position is at line start (only whitespace before it)
   */
  function isLineStart(code, pos) {
    if (pos === 0) return true;
    for (let i = pos - 1; i >= 0; i--) {
      const ch = code[i];
      if (ch === '\n') return true;
      if (ch !== ' ' && ch !== '\t') return false;
    }
    return true;
  }

  /**
   * Highlight C source code
   */
  function highlightC(code) {
    const tokens = [];
    let i = 0;
    const len = code.length;

    while (i < len) {
      const char = code[i];

      // Multi-line comment
      if (char === '/' && code[i + 1] === '*') {
        let end = code.indexOf('*/', i + 2);
        end = (end === -1) ? len : end + 2;
        const comment = code.substring(i, end);
        tokens.push('<span class="c-comment">', escapeHtml(comment), '</span>');
        i = end;
        continue;
      }

      // Single-line comment
      if (char === '/' && code[i + 1] === '/') {
        const end = code.indexOf('\n', i);
        const commentEnd = (end === -1) ? len : end;
        const comment = code.substring(i, commentEnd);
        tokens.push('<span class="c-comment">', escapeHtml(comment), '</span>');
        i = commentEnd;
        continue;
      }

      // Preprocessor directive (must be at line start)
      if (char === '#' && isLineStart(code, i)) {
        let end = i + 1;
        while (end < len && code[end] !== '\n') {
          if (code[end] === '\\' && end + 1 < len && code[end + 1] === '\n') {
            end += 2; // Handle line continuation
          } else {
            end++;
          }
        }
        const preprocessor = code.substring(i, end);
        tokens.push('<span class="c-preprocessor">', escapeHtml(preprocessor), '</span>');
        i = end;
        continue;
      }

      // String literal
      if (char === '"') {
        let end = i + 1;
        while (end < len && code[end] !== '"') {
          if (code[end] === '\\' && end + 1 < len) {
            end += 2; // Skip escaped character
          } else {
            end++;
          }
        }
        if (end < len) end++; // Include closing quote
        const string = code.substring(i, end);
        tokens.push('<span class="c-string">', escapeHtml(string), '</span>');
        i = end;
        continue;
      }

      // Character literal
      if (char === "'") {
        let end = i + 1;
        // Handle escape sequences like '\n', '\\', '\''
        if (end < len && code[end] === '\\' && end + 1 < len) {
          end += 2; // Skip backslash and escaped char
        } else if (end < len) {
          end++; // Single character
        }
        if (end < len && code[end] === "'") end++; // Closing quote
        const charLit = code.substring(i, end);
        tokens.push('<span class="c-value">', escapeHtml(charLit), '</span>');
        i = end;
        continue;
      }

      // Number (integer or float)
      if (char >= '0' && char <= '9') {
        let end = i;

        // Hexadecimal
        if (char === '0' && (code[i + 1] === 'x' || code[i + 1] === 'X')) {
          end = i + 2;
          while (end < len) {
            const ch = code[end];
            if ((ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F')) {
              end++;
            } else {
              break;
            }
          }
        }
        // Octal
        else if (char === '0' && code[i + 1] >= '0' && code[i + 1] <= '7') {
          end = i + 1;
          while (end < len && code[end] >= '0' && code[end] <= '7') end++;
        }
        // Decimal/Float
        else {
          while (end < len) {
            const ch = code[end];
            if ((ch >= '0' && ch <= '9') || ch === '.') {
              end++;
            } else {
              break;
            }
          }
          // Scientific notation
          if (end < len && (code[end] === 'e' || code[end] === 'E')) {
            end++;
            if (end < len && (code[end] === '+' || code[end] === '-')) end++;
            while (end < len && code[end] >= '0' && code[end] <= '9') end++;
          }
        }

        // Suffix (u, l, f, etc.)
        while (end < len) {
          const ch = code[end];
          if (ch === 'u' || ch === 'U' || ch === 'l' || ch === 'L' || ch === 'f' || ch === 'F') {
            end++;
          } else {
            break;
          }
        }

        const number = code.substring(i, end);
        tokens.push('<span class="c-value">', escapeHtml(number), '</span>');
        i = end;
        continue;
      }

      // Identifier or keyword
      if ((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char === '_') {
        let end = i + 1;
        while (end < len) {
          const ch = code[end];
          if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
              (ch >= '0' && ch <= '9') || ch === '_') {
            end++;
          } else {
            break;
          }
        }
        const word = code.substring(i, end);

        if (C_KEYWORDS.has(word)) {
          tokens.push('<span class="c-keyword">', escapeHtml(word), '</span>');
        } else if (isType(word)) {
          // Check types before macros (VALUE, ID are types, not macros)
          tokens.push('<span class="c-type">', escapeHtml(word), '</span>');
        } else if (isMacro(word)) {
          tokens.push('<span class="c-macro">', escapeHtml(word), '</span>');
        } else {
          // Check if followed by '(' -> function name
          let nextCharIdx = end;
          while (nextCharIdx < len && (code[nextCharIdx] === ' ' || code[nextCharIdx] === '\t')) {
            nextCharIdx++;
          }
          if (nextCharIdx < len && code[nextCharIdx] === '(') {
            tokens.push('<span class="c-function">', escapeHtml(word), '</span>');
          } else {
            tokens.push('<span class="c-identifier">', escapeHtml(word), '</span>');
          }
        }
        i = end;
        continue;
      }

      // Operators
      if (OPERATOR_CHARS.has(char)) {
        let op = char;
        // Check for two-character operators
        if (i + 1 < len) {
          const twoChar = char + code[i + 1];
          if (OPERATORS.has(twoChar)) {
            op = twoChar;
          }
        }
        tokens.push('<span class="c-operator">', escapeHtml(op), '</span>');
        i += op.length;
        continue;
      }

      // Everything else (punctuation, whitespace)
      tokens.push(escapeHtml(char));
      i++;
    }

    return tokens.join('');
  }

  /**
   * Initialize C syntax highlighting on page load
   */
  function initHighlighting() {
    const codeBlocks = document.querySelectorAll('pre.c');

    codeBlocks.forEach(block => {
      if (block.getAttribute('data-highlighted') === 'true') {
        return;
      }

      const code = block.textContent;
      const highlighted = highlightC(code);

      block.innerHTML = highlighted;
      block.setAttribute('data-highlighted', 'true');
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initHighlighting);
  } else {
    initHighlighting();
  }
})();
