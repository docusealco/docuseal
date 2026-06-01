/**
 * Client-side shell syntax highlighter for RDoc
 * Highlights: $ prompts, commands, options, strings, env vars, comments
 */

(function() {
  'use strict';

  function escapeHtml(text) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function wrap(className, text) {
    return '<span class="' + className + '">' + escapeHtml(text) + '</span>';
  }

  function highlightLine(line) {
    if (line.trim() === '') return escapeHtml(line);

    var result = '';
    var i = 0;
    var len = line.length;

    // Preserve leading whitespace
    while (i < len && (line[i] === ' ' || line[i] === '\t')) {
      result += escapeHtml(line[i++]);
    }

    // Check for $ prompt ($ followed by space or end of line)
    if (line[i] === '$' && (line[i + 1] === ' ' || line[i + 1] === undefined)) {
      result += wrap('sh-prompt', '$');
      i++;
    }

    // Check for # comment at start
    if (line[i] === '#') {
      return result + wrap('sh-comment', line.slice(i));
    }

    var seenCommand = false;
    var afterSpace = true;

    while (i < len) {
      var ch = line[i];

      // Whitespace
      if (ch === ' ' || ch === '\t') {
        result += escapeHtml(ch);
        i++;
        afterSpace = true;
        continue;
      }

      // Comment after whitespace
      if (ch === '#' && afterSpace) {
        result += wrap('sh-comment', line.slice(i));
        break;
      }

      // Double-quoted string
      if (ch === '"') {
        var end = i + 1;
        while (end < len && line[end] !== '"') {
          if (line[end] === '\\' && end + 1 < len) end += 2;
          else end++;
        }
        if (end < len) end++;
        result += wrap('sh-string', line.slice(i, end));
        i = end;
        afterSpace = false;
        continue;
      }

      // Single-quoted string
      if (ch === "'") {
        var end = i + 1;
        while (end < len && line[end] !== "'") end++;
        if (end < len) end++;
        result += wrap('sh-string', line.slice(i, end));
        i = end;
        afterSpace = false;
        continue;
      }

      // Environment variable (ALLCAPS=)
      if (afterSpace && /[A-Z]/.test(ch)) {
        var match = line.slice(i).match(/^[A-Z][A-Z0-9_]*=/);
        if (match) {
          result += wrap('sh-envvar', match[0]);
          i += match[0].length;
          // Read unquoted value
          var valEnd = i;
          while (valEnd < len && line[valEnd] !== ' ' && line[valEnd] !== '\t' && line[valEnd] !== '"' && line[valEnd] !== "'") valEnd++;
          if (valEnd > i) {
            result += escapeHtml(line.slice(i, valEnd));
            i = valEnd;
          }
          afterSpace = false;
          continue;
        }
      }

      // Option (must be after whitespace)
      if (ch === '-' && afterSpace) {
        var match = line.slice(i).match(/^--?[a-zA-Z0-9_-]+(=[^"'\s]*)?/);
        if (match) {
          result += wrap('sh-option', match[0]);
          i += match[0].length;
          afterSpace = false;
          continue;
        }
      }

      // Command (first word: regular, ./path, ../path, ~/path, /abs/path, @scope/pkg)
      if (!seenCommand && afterSpace) {
        var isCmd = /[a-zA-Z0-9@~\/]/.test(ch) ||
                    (ch === '.' && (line[i + 1] === '/' || (line[i + 1] === '.' && line[i + 2] === '/')));
        if (isCmd) {
          var end = i;
          while (end < len && line[end] !== ' ' && line[end] !== '\t') end++;
          result += wrap('sh-command', line.slice(i, end));
          i = end;
          seenCommand = true;
          afterSpace = false;
          continue;
        }
      }

      // Everything else
      result += escapeHtml(ch);
      i++;
      afterSpace = false;
    }

    return result;
  }

  function highlightShell(code) {
    return code.split('\n').map(highlightLine).join('\n');
  }

  function initHighlighting() {
    var selectors = [
      'pre.bash', 'pre.sh', 'pre.shell', 'pre.console',
      'pre[data-language="bash"]', 'pre[data-language="sh"]',
      'pre[data-language="shell"]', 'pre[data-language="console"]'
    ];

    var blocks = document.querySelectorAll(selectors.join(', '));
    blocks.forEach(function(block) {
      if (block.getAttribute('data-highlighted') === 'true') return;
      block.innerHTML = highlightShell(block.textContent);
      block.setAttribute('data-highlighted', 'true');
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initHighlighting);
  } else {
    initHighlighting();
  }
})();
