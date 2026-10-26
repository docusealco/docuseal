import { Editor, Extension, Node, Mark, ResizableNodeView } from '@tiptap/core'
import { Plugin, PluginKey, NodeSelection } from '@tiptap/pm/state'
import { TableMap, CellSelection, tableEditing, findTable, selectedRect, addRowAfter, addRowBefore, addColumnAfter, addColumnBefore, deleteRow, deleteColumn, mergeCells, splitCell } from '@tiptap/pm/tables'
import { Decoration, DecorationSet } from '@tiptap/pm/view'
import Document from '@tiptap/extension-document'
import Text from '@tiptap/extension-text'
import HardBreak from '@tiptap/extension-hard-break'
import Gapcursor from '@tiptap/extension-gapcursor'
import Dropcursor from '@tiptap/extension-dropcursor'
import { createApp, reactive } from 'vue'
import DynamicArea from './dynamic_area.vue'
import styles from './dynamic_styles.scss'

export const dynamicStylesheet = new CSSStyleSheet()

dynamicStylesheet.replaceSync(styles[0][1])

export const tiptapStylesheet = new CSSStyleSheet()

tiptapStylesheet.replaceSync(
`.ProseMirror {
  word-wrap: break-word;
  white-space: pre-wrap;
  white-space: break-spaces;
  -webkit-font-variant-ligatures: none;
  font-variant-ligatures: none;
  font-feature-settings: "liga" 0;
  display: flex;
  flex-flow: column nowrap;
  flex-grow: 1;
}

.ProseMirror > article:last-of-type {
  margin-bottom: auto;
}

.ProseMirror p.doc-trailing-break::after {
  content: none;
}

.ProseMirror [contenteditable="false"] {
  white-space: normal;
}

.ProseMirror [contenteditable="false"] [contenteditable="true"] {
  white-space: pre-wrap;
}

.ProseMirror pre {
  white-space: pre-wrap;
}

img.ProseMirror-separator {
  display: inline !important;
  border: none !important;
  margin: 0 !important;
  width: 0 !important;
  height: 0 !important;
}

.ProseMirror-gapcursor {
  display: none;
  pointer-events: none;
  position: absolute;
  margin: 0;
}

.ProseMirror-gapcursor:after {
  content: "";
  display: block;
  position: absolute;
  top: -2px;
  width: 20px;
  border-top: 1px solid black;
  animation: ProseMirror-cursor-blink 1.1s steps(2, start) infinite;
}

@keyframes ProseMirror-cursor-blink {
  to {
    visibility: hidden;
  }
}

.ProseMirror-hideselection *::selection {
  background: transparent;
}

.ProseMirror-hideselection *::-moz-selection {
  background: transparent;
}

.ProseMirror-hideselection * {
  caret-color: transparent;
}

.ProseMirror-focused .ProseMirror-gapcursor {
  display: block;
}
[data-resize-container][data-node="image"] {
  display: inline-flex !important;
  max-width: 100%;
  vertical-align: bottom;
}

[data-resize-container][data-node="image"] [data-resize-wrapper] {
  max-width: 100%;
  text-indent: 0;
}

[data-resize-handle] {
  --handle-size: calc(10px / var(--zoom));
  display: none;
  width: var(--handle-size);
  height: var(--handle-size);
  background: #ffffff;
  border: calc(2px / var(--zoom)) solid #3b82f6;
  border-radius: 2px;
  z-index: 1;
}

@media (pointer: coarse) {
  [data-resize-handle]::after {
    content: "";
    position: absolute;
    inset: calc(-8px / var(--zoom));
  }
}

.ProseMirror-selectednode [data-resize-wrapper] {
  outline: 2px solid #3b82f6;
}

.ProseMirror-selectednode [data-resize-handle] {
  display: block;
}

[data-resize-handle="top-left"] { margin: calc(var(--handle-size) / -2) 0 0 calc(var(--handle-size) / -2); cursor: nwse-resize; }
[data-resize-handle="top-right"] { margin: calc(var(--handle-size) / -2) calc(var(--handle-size) / -2) 0 0; cursor: nesw-resize; }
[data-resize-handle="bottom-left"] { margin: 0 0 calc(var(--handle-size) / -2) calc(var(--handle-size) / -2); cursor: nesw-resize; }
[data-resize-handle="bottom-right"] { margin: 0 calc(var(--handle-size) / -2) calc(var(--handle-size) / -2) 0; cursor: nwse-resize; }

/* iOS 27 WebKit drops thin collapsed borders when zoomed out */
[data-zoomed-out] .ProseMirror table {
  border-collapse: separate !important;
  border-spacing: 0 !important;
}

.ProseMirror .selectedCell {
  position: relative;
}

.ProseMirror .selectedCell::after {
  content: "";
  position: absolute;
  inset: 0;
  background: rgba(59, 130, 246, 0.15);
  pointer-events: none;
}

dynamic-variable {
  background-color: #fef3c7;
  word-break: break-all;
  overflow-wrap: anywhere;
}

.pageNumber:empty::before,
.totalPages:empty::before {
  content: "#";
}`)

const DROP_ATTRS = [
  'srcdoc', 'xlink:href', 'srcset', 'action', 'formaction', 'poster',
  'background', 'data', 'cite', 'ping', 'longdesc', 'manifest', 'profile'
]

const SAFE_URL_REGEXP = /^(?:https?:\/\/|data:image\/|blob:|mailto:|tel:|\{|#)/i

function isSafeAttr (name, value) {
  const lowerName = name.toLowerCase()

  if (lowerName.startsWith('on') || DROP_ATTRS.includes(lowerName)) return false
  if ((lowerName === 'href' || lowerName === 'src') && !SAFE_URL_REGEXP.test(value.trim())) return false

  return true
}

function collectDomAttrs (dom) {
  const attrs = {}

  for (let i = 0; i < dom.attributes.length; i++) {
    const { name, value } = dom.attributes[i]

    if (isSafeAttr(name, value)) attrs[name] = value
  }

  return { htmlAttrs: attrs }
}

function collectSpanDomAttrs (dom) {
  const result = collectDomAttrs(dom)

  if (result.htmlAttrs.style) {
    const temp = document.createElement('span')

    temp.style.cssText = result.htmlAttrs.style

    if (['bold', '700'].includes(temp.style.fontWeight)) {
      temp.style.removeProperty('font-weight')
    }

    if (temp.style.fontStyle === 'italic') {
      temp.style.removeProperty('font-style')
    }

    if (['underline', 'line-through'].includes(temp.style.textDecoration)) {
      temp.style.removeProperty('text-decoration')
    }

    if (temp.style.cssText) {
      result.htmlAttrs.style = temp.style.cssText
    } else {
      delete result.htmlAttrs.style
    }
  }

  return result
}

function createBlockNode (name, tag, content, extra = {}) {
  return Node.create({
    name,
    group: 'block',
    content: content || 'block+',
    ...extra,
    addAttributes () {
      return {
        htmlAttrs: { default: {} }
      }
    },
    parseHTML () {
      return [{ tag, getAttrs: collectDomAttrs }]
    },
    renderHTML ({ node }) {
      return [tag, node.attrs.htmlAttrs, 0]
    }
  })
}

const CustomParagraph = Node.create({
  name: 'paragraph',
  group: 'block',
  content: 'inline*',
  addAttributes () {
    return {
      htmlAttrs: { default: {} }
    }
  },
  parseHTML () {
    return [{ tag: 'p', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['p', node.attrs.htmlAttrs, 0]
  }
})

const CustomHeading = Node.create({
  name: 'heading',
  group: 'block',
  content: 'inline*',
  addAttributes () {
    return {
      htmlAttrs: { default: {} },
      level: { default: 1 }
    }
  },
  parseHTML () {
    return [1, 2, 3, 4, 5, 6].map((level) => ({
      tag: `h${level}`,
      getAttrs: (dom) => ({ ...collectDomAttrs(dom), level })
    }))
  },
  renderHTML ({ node }) {
    return [`h${node.attrs.level}`, node.attrs.htmlAttrs, 0]
  }
})

const SectionNode = createBlockNode('section', 'section')
const ArticleNode = createBlockNode('article', 'article', null, { isolating: true })
const HeaderNode = createBlockNode('header', 'header', null, { isolating: true })
const FooterNode = createBlockNode('footer', 'footer', null, { isolating: true })
const DivNode = createBlockNode('div', 'div')
const BlockquoteNode = createBlockNode('blockquote', 'blockquote')
const PreNode = createBlockNode('pre', 'pre')
const OrderedListNode = createBlockNode('orderedList', 'ol', '(listItem | block)+')
const BulletListNode = createBlockNode('bulletList', 'ul', '(listItem | block)+')

const ListItemNode = Node.create({
  name: 'listItem',
  content: 'block+',
  addAttributes () {
    return {
      htmlAttrs: { default: {} }
    }
  },
  parseHTML () {
    return [{ tag: 'li', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['li', node.attrs.htmlAttrs, 0]
  }
})

function collectCellDomAttrs (dom) {
  const { htmlAttrs } = collectDomAttrs(dom)
  const colspan = parseInt(htmlAttrs.colspan) || 1
  const rowspan = parseInt(htmlAttrs.rowspan) || 1

  delete htmlAttrs.colspan
  delete htmlAttrs.rowspan

  return { htmlAttrs, colspan, rowspan }
}

function renderCellAttrs (node) {
  const attrs = { ...node.attrs.htmlAttrs }

  if (node.attrs.colspan > 1) attrs.colspan = node.attrs.colspan
  if (node.attrs.rowspan > 1) attrs.rowspan = node.attrs.rowspan

  return attrs
}

function isRemovableHiddenCell (dom) {
  const isHidden = (cell) => cell.style.display === 'none'

  return isHidden(dom) && [...dom.parentElement.children].some((cell) => !isHidden(cell))
}

function createTableCellNode (name, tag, tableRole) {
  return Node.create({
    name,
    tableRole,
    content: 'block*',
    isolating: true,
    addAttributes () {
      return {
        htmlAttrs: { default: {} },
        colspan: { default: 1 },
        rowspan: { default: 1 },
        colwidth: { default: null }
      }
    },
    parseHTML () {
      return [
        { tag, priority: 60, ignore: true, getAttrs: (dom) => isRemovableHiddenCell(dom) ? null : false },
        { tag, getAttrs: collectCellDomAttrs }
      ]
    },
    renderHTML ({ node }) {
      return [tag, renderCellAttrs(node), 0]
    }
  })
}

const TableNode = Node.create({
  name: 'table',
  group: 'block',
  tableRole: 'table',
  content: 'tableRow+',
  isolating: true,
  addAttributes () {
    return {
      htmlAttrs: { default: {} },
      colgroupAttrs: { default: null },
      cols: { default: [] }
    }
  },
  parseHTML () {
    return [
      {
        tag: 'table',
        getAttrs (dom) {
          const colgroup = dom.querySelector(':scope > colgroup')

          return {
            ...collectDomAttrs(dom),
            colgroupAttrs: colgroup ? collectDomAttrs(colgroup).htmlAttrs : null,
            cols: colgroup ? [...colgroup.querySelectorAll(':scope > col')].map((col) => collectDomAttrs(col).htmlAttrs) : []
          }
        }
      },
      { tag: 'colgroup', ignore: true }
    ]
  },
  renderHTML ({ node }) {
    const { htmlAttrs, colgroupAttrs, cols } = node.attrs

    if (colgroupAttrs || cols.length) {
      return ['table', htmlAttrs, ['colgroup', colgroupAttrs || {}, ...cols.map((col) => ['col', col])], ['tbody', 0]]
    }

    return ['table', htmlAttrs, ['tbody', 0]]
  }
})

const TableRow = Node.create({
  name: 'tableRow',
  tableRole: 'row',
  content: '(tableCell | tableHeader)+',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'tr', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['tr', node.attrs.htmlAttrs, 0]
  }
})

const TableCell = createTableCellNode('tableCell', 'td', 'cell')
const TableHeader = createTableCellNode('tableHeader', 'th', 'header_cell')

const ImageNode = Node.create({
  name: 'image',
  inline: true,
  group: 'inline',
  draggable: true,
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'img', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['img', node.attrs.htmlAttrs]
  }
})

const CustomBold = Mark.create({
  name: 'bold',
  parseHTML () {
    return [{ tag: 'strong' }, { tag: 'b' }, { style: 'font-weight=bold' }, { style: 'font-weight=700' }]
  },
  renderHTML () {
    return ['strong', 0]
  },
  addCommands () {
    return {
      toggleBold: () => ({ commands }) => commands.toggleMark(this.name)
    }
  },
  addKeyboardShortcuts () {
    return {
      'Mod-b': () => this.editor.commands.toggleBold()
    }
  }
})

const CustomItalic = Mark.create({
  name: 'italic',
  parseHTML () {
    return [{ tag: 'em' }, { tag: 'i' }, { style: 'font-style=italic' }]
  },
  renderHTML () {
    return ['em', 0]
  },
  addCommands () {
    return {
      toggleItalic: () => ({ commands }) => commands.toggleMark(this.name)
    }
  },
  addKeyboardShortcuts () {
    return {
      'Mod-i': () => this.editor.commands.toggleItalic()
    }
  }
})

const CustomUnderline = Mark.create({
  name: 'underline',
  parseHTML () {
    return [{ tag: 'u' }, { style: 'text-decoration=underline' }]
  },
  renderHTML () {
    return ['u', 0]
  },
  addCommands () {
    return {
      toggleUnderline: () => ({ commands }) => commands.toggleMark(this.name)
    }
  },
  addKeyboardShortcuts () {
    return {
      'Mod-u': () => this.editor.commands.toggleUnderline()
    }
  }
})

const CustomStrike = Mark.create({
  name: 'strike',
  parseHTML () {
    return [{ tag: 's' }, { tag: 'del' }, { tag: 'strike' }, { style: 'text-decoration=line-through' }]
  },
  renderHTML () {
    return ['s', 0]
  },
  addCommands () {
    return {
      toggleStrike: () => ({ commands }) => commands.toggleMark(this.name)
    }
  },
  addKeyboardShortcuts () {
    return {
      'Mod-Shift-s': () => this.editor.commands.toggleStrike()
    }
  }
})

const EmptySpanNode = Node.create({
  name: 'emptySpan',
  inline: true,
  group: 'inline',
  atom: true,
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{
      tag: 'span',
      priority: 60,
      getAttrs (dom) {
        if (dom.childNodes.length === 0 && dom.attributes.length > 0) {
          return collectDomAttrs(dom)
        }

        return false
      }
    }]
  },
  renderHTML ({ node }) {
    return ['span', node.attrs.htmlAttrs]
  }
})

const SpanMark = Mark.create({
  name: 'span',
  excludes: '',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'span', getAttrs: collectSpanDomAttrs }]
  },
  renderHTML ({ mark }) {
    return ['span', mark.attrs.htmlAttrs, 0]
  }
})

const LayoutSpanMark = SpanMark.extend({
  name: 'layoutSpan',
  parseHTML () {
    return [{
      tag: 'span',
      priority: 55,
      getAttrs (dom) {
        if (['left', 'right'].includes(dom.style.float) || ['inline-block', 'block'].includes(dom.style.display)) {
          return collectSpanDomAttrs(dom)
        }

        return false
      }
    }]
  }
})

const LinkMark = Mark.create({
  name: 'link',
  excludes: '',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'a', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ mark }) {
    return ['a', mark.attrs.htmlAttrs, 0]
  }
})

const SubscriptMark = Mark.create({
  name: 'subscript',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'sub', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ mark }) {
    return ['sub', mark.attrs.htmlAttrs, 0]
  }
})

const SuperscriptMark = Mark.create({
  name: 'superscript',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'sup', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ mark }) {
    return ['sup', mark.attrs.htmlAttrs, 0]
  }
})

const TabHandler = Extension.create({
  name: 'tabHandler',
  addKeyboardShortcuts () {
    return {
      Tab: () => {
        this.editor.commands.insertContent('\t')

        return true
      }
    }
  }
})

const NumberingKeymap = Extension.create({
  name: 'numberingKeymap',
  priority: 110,
  addKeyboardShortcuts () {
    const numberingAtCursor = () => {
      const { empty, $from } = this.editor.state.selection

      return empty && $from.parentOffset === 0 && !!findNumbering($from.parent)
    }

    return {
      Tab: () => {
        const { empty, $from } = this.editor.state.selection

        return (!empty || $from.parentOffset === 0) && this.editor.commands.shiftNumberingLevel(1)
      },
      'Shift-Tab': () => this.editor.commands.shiftNumberingLevel(-1),
      Enter: () => numberingAtCursor() && !this.editor.state.selection.$from.parent.content.size && this.editor.commands.unsetNumbering(),
      Backspace: () => numberingAtCursor() && this.editor.commands.unsetNumbering()
    }
  }
})

export const listsCss = `[class*="doc-list-"]::before {
  display: inline-block;
  min-width: 0.25in;
  text-indent: 0;
  text-align: left;
}

.doc-list-disc-0,
.doc-list-dash-0,
.doc-list-decimal-0 {
  margin-left: 0.5in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-1 0;
}

.doc-list-disc-1,
.doc-list-dash-1,
.doc-list-decimal-1 {
  margin-left: 0.75in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-2 0;
}

.doc-list-disc-2,
.doc-list-dash-2,
.doc-list-decimal-2 {
  margin-left: 1in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-3 0;
}

.doc-list-disc-3,
.doc-list-dash-3,
.doc-list-decimal-3 {
  margin-left: 1.25in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-4 0;
}

.doc-list-disc-4,
.doc-list-dash-4,
.doc-list-decimal-4 {
  margin-left: 1.5in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-5 0;
}

.doc-list-disc-5,
.doc-list-dash-5,
.doc-list-decimal-5 {
  margin-left: 1.75in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-6 0;
}

.doc-list-disc-6,
.doc-list-dash-6,
.doc-list-decimal-6 {
  margin-left: 2in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-7 0;
}

.doc-list-disc-7,
.doc-list-dash-7,
.doc-list-decimal-7 {
  margin-left: 2.25in !important;
  text-indent: -0.25in !important;
  counter-set: doc-list-8 0;
}

.doc-list-disc-8,
.doc-list-dash-8,
.doc-list-decimal-8 {
  margin-left: 2.5in !important;
  text-indent: -0.25in !important;
}

.doc-list-disc-0::before,
.doc-list-disc-3::before,
.doc-list-disc-6::before {
  content: "•";
}

.doc-list-disc-1::before,
.doc-list-disc-4::before,
.doc-list-disc-7::before {
  content: "◦";
}

.doc-list-disc-2::before,
.doc-list-disc-5::before,
.doc-list-disc-8::before {
  content: "▪";
}

[class*="doc-list-dash-"]::before {
  content: "–";
}

.doc-list-decimal-0 {
  counter-increment: doc-list-0;
}

.doc-list-decimal-1 {
  counter-increment: doc-list-1;
}

.doc-list-decimal-2 {
  counter-increment: doc-list-2;
}

.doc-list-decimal-3 {
  counter-increment: doc-list-3;
}

.doc-list-decimal-4 {
  counter-increment: doc-list-4;
}

.doc-list-decimal-5 {
  counter-increment: doc-list-5;
}

.doc-list-decimal-6 {
  counter-increment: doc-list-6;
}

.doc-list-decimal-7 {
  counter-increment: doc-list-7;
}

.doc-list-decimal-8 {
  counter-increment: doc-list-8;
}

.doc-list-decimal-0::before {
  content: counter(doc-list-0) ".";
}

.doc-list-decimal-1::before {
  content: counter(doc-list-1, lower-alpha) ".";
}

.doc-list-decimal-2::before {
  content: counter(doc-list-2, lower-roman) ".";
}

.doc-list-decimal-3::before {
  content: counter(doc-list-3) ".";
}

.doc-list-decimal-4::before {
  content: counter(doc-list-4, lower-alpha) ".";
}

.doc-list-decimal-5::before {
  content: counter(doc-list-5, lower-roman) ".";
}

.doc-list-decimal-6::before {
  content: counter(doc-list-6) ".";
}

.doc-list-decimal-7::before {
  content: counter(doc-list-7, lower-alpha) ".";
}

.doc-list-decimal-8::before {
  content: counter(doc-list-8, lower-roman) ".";
}

:not([class*="doc-list-"]) + .doc-list-decimal-0,
.doc-list-decimal-0:first-child,
.doc-list-disc-0 + .doc-list-decimal-0,
.doc-list-dash-0 + .doc-list-decimal-0 {
  counter-set: doc-list-0 1 doc-list-1 0;
}

[class*="doc-list-"]:has(+ [class*="doc-list-"]) {
  margin-bottom: 0 !important;
}

[class*="doc-list-"] + [class*="doc-list-"] {
  margin-top: 0 !important;
}`

const NUMBERING_CLASS_REGEXP = /^(doc-num-\d+|doc-list-(?:disc|dash|decimal))-(\d+)$/

export function findNumbering (node) {
  for (const className of (node.attrs.htmlAttrs?.class || '').split(' ')) {
    const match = className.match(NUMBERING_CLASS_REGEXP)

    if (match) return { prefix: match[1], level: parseInt(match[2]) }
  }

  return null
}

function withNumberingClass (htmlAttrs, className) {
  const classNames = (htmlAttrs.class || '').split(' ').filter(Boolean)
  const index = classNames.findIndex((name) => NUMBERING_CLASS_REGEXP.test(name))

  if (index === -1) {
    classNames.push(className)
  } else {
    classNames[index] = className
  }

  const attrs = { ...htmlAttrs, class: classNames.filter(Boolean).join(' ') }

  if (!attrs.class) delete attrs.class

  return attrs
}

function selectedTextblocks (state) {
  const blocks = []

  state.selection.ranges.forEach(({ $from, $to }) => state.doc.nodesBetween($from.pos, $to.pos, (node, pos) => {
    if (!node.isTextblock) return

    blocks.push({ node, pos, numbering: findNumbering(node) })

    return false
  }))

  return blocks
}

export function numberingListStyle (view, pos) {
  const { content } = getComputedStyle(view.nodeDOM(pos), '::before')

  if (content.includes('counter(')) return 'decimal'

  return /^"[–-]/.test(content) ? 'dash' : 'disc'
}

function hasNumberingLevel (view, { prefix }, level) {
  if (prefix.startsWith('doc-list-')) return level >= 0 && level <= 8

  const selector = `p.${prefix}-${level}`

  return [...view.dom.getRootNode().styleSheets].some((sheet) => [...sheet.cssRules].some((rule) => rule.selectorText === selector))
}

function updateStyle (style, property, value) {
  const el = document.createElement('span')

  el.style.cssText = style || ''

  if (value) {
    el.style.setProperty(property, value)
  } else {
    el.style.removeProperty(property)
  }

  return el.style.cssText
}

function withStyle (htmlAttrs, property, value) {
  const style = updateStyle(htmlAttrs.style, property, value)
  const attrs = { ...htmlAttrs, style }

  if (!style) delete attrs.style

  return attrs
}

const Formatting = Extension.create({
  name: 'formatting',
  addCommands () {
    return {
      setSpanStyle: (property, value) => ({ state, tr, dispatch }) => {
        const { empty, ranges } = state.selection
        const type = state.schema.marks.span

        if (empty) return false

        if (dispatch) {
          ranges.forEach(({ $from: { pos: from }, $to: { pos: to } }) => state.doc.nodesBetween(from, to, (node, pos) => {
            if (!node.isInline) return

            const start = Math.max(pos, from)
            const end = Math.min(pos + node.nodeSize, to)
            const spans = node.marks.filter((mark) => mark.type === type)
            const hasProperty = (mark) => {
              const el = document.createElement('span')

              el.style.cssText = mark.attrs.htmlAttrs.style || ''

              return !!el.style.getPropertyValue(property)
            }

            const updated = spans.map((mark, index) => {
              let htmlAttrs = hasProperty(mark) ? withStyle(mark.attrs.htmlAttrs, property, null) : mark.attrs.htmlAttrs

              if (value && index === spans.length - 1) {
                htmlAttrs = withStyle(htmlAttrs, property, value)
              }

              return htmlAttrs
            })

            if (value && !spans.length) {
              updated.push({ style: `${property}: ${value}` })
            }

            if (updated.length === spans.length && updated.every((htmlAttrs, index) => htmlAttrs === spans[index].attrs.htmlAttrs)) return

            tr.removeMark(start, end, type)

            updated.forEach((htmlAttrs) => tr.addMark(start, end, type.create({ htmlAttrs })))
          }))
        }

        return true
      },
      setBlockStyle: (property, value) => ({ state, tr, dispatch }) => {
        if (dispatch) {
          state.selection.ranges.forEach(({ $from, $to }) => state.doc.nodesBetween($from.pos, $to.pos, (node, pos) => {
            if (!node.isTextblock) return

            tr.setNodeMarkup(pos, null, { ...node.attrs, htmlAttrs: withStyle(node.attrs.htmlAttrs, property, value) })

            return false
          }))
        }

        return true
      },
      shiftNumberingLevel: (delta) => ({ state, tr, dispatch, view }) => {
        if (!findNumbering(state.selection.$from.parent)) return false

        const blocks = selectedTextblocks(state).filter(({ numbering }) => numbering)

        if (dispatch && blocks.every(({ numbering }) => hasNumberingLevel(view, numbering, numbering.level + delta))) {
          blocks.forEach(({ node, pos, numbering }) => {
            tr.setNodeMarkup(pos, null, { ...node.attrs, htmlAttrs: withNumberingClass(node.attrs.htmlAttrs, `${numbering.prefix}-${numbering.level + delta}`) })
          })
        }

        return true
      },
      setListMarkerStyle: (property, value) => ({ state, tr, dispatch }) => {
        const from = Math.min(...state.selection.ranges.map(({ $from }) => $from.pos))
        const to = Math.max(...state.selection.ranges.map(({ $to }) => $to.pos))
        const blocks = selectedTextblocks(state).filter(({ node, pos, numbering }) => numbering && from <= pos + 1 && to >= pos + node.nodeSize - 1)

        if (!blocks.length) return false

        if (dispatch) {
          blocks.forEach(({ node, pos }) => tr.setNodeMarkup(pos, null, { ...node.attrs, htmlAttrs: withStyle(node.attrs.htmlAttrs, property, value) }))
        }

        return true
      },
      unsetNumbering: () => ({ state, tr, dispatch }) => {
        const blocks = selectedTextblocks(state).filter(({ numbering }) => numbering)

        if (!blocks.length) return false

        if (dispatch) {
          blocks.forEach(({ node, pos }) => tr.setNodeMarkup(pos, null, { ...node.attrs, htmlAttrs: withNumberingClass(node.attrs.htmlAttrs, null) }))
        }

        return true
      },
      toggleList: (listStyle) => ({ state, tr, dispatch, view, commands }) => {
        const { $from } = state.selection

        if (findNumbering($from.parent) && numberingListStyle(view, $from.before()) === listStyle) {
          return commands.unsetNumbering()
        }

        if (dispatch) {
          const blocks = selectedTextblocks(state)
          const $before = state.doc.resolve(blocks[0].pos)
          const $after = state.doc.resolve(blocks.at(-1).pos + blocks.at(-1).node.nodeSize)
          const adjacent = [[$before.nodeBefore, $before.pos - $before.nodeBefore?.nodeSize], [$after.nodeAfter, $after.pos]]
            .map(([node, pos]) => node && findNumbering(node) && numberingListStyle(view, pos) === listStyle && findNumbering(node).prefix)
            .find(Boolean)

          blocks.forEach(({ node, pos, numbering }) => {
            const className = numbering ? `doc-list-${listStyle}-${numbering.level}` : `${adjacent || `doc-list-${listStyle}`}-0`

            tr.setNodeMarkup(pos, null, { ...node.attrs, htmlAttrs: withNumberingClass(node.attrs.htmlAttrs, className) })
          })
        }

        return true
      }
    }
  }
})

function deleteTableNode (tr, table) {
  const $table = tr.doc.resolve(table.pos)

  if ($table.parent.childCount === 1) {
    tr.replaceWith(table.pos, table.pos + table.node.nodeSize, tr.doc.type.schema.nodes.paragraph.create())
  } else {
    tr.delete(table.pos, table.pos + table.node.nodeSize)
  }
}

export function isRegularTable (table) {
  return !TableMap.get(table).problems
}

function findEditableTable (state) {
  const table = findTable(state.selection.$head)

  return table && isRegularTable(table.node) ? table : null
}

function tableCellNodes (table) {
  const cells = new Set()

  table.descendants((node) => {
    if (node.type.spec.tableRole === 'cell' || node.type.spec.tableRole === 'header_cell') {
      cells.add(node)

      return false
    }
  })

  return cells
}

function styleNewCells (tr, existingCells) {
  const table = findTable(tr.selection.$head)

  const map = TableMap.get(table.node)
  const cellPositions = [...new Set(map.map)]
  const isNew = (pos) => !existingCells.has(table.node.nodeAt(pos))
  const findReference = (pos) => {
    const { left, top } = map.findCell(pos)

    for (let distance = 1; distance < Math.max(map.width, map.height); distance++) {
      const candidates = [
        [top, left - distance], [top, left + distance],
        [top - distance, left], [top + distance, left]
      ]

      for (const [row, col] of candidates) {
        if (row < 0 || col < 0 || row >= map.height || col >= map.width) continue

        const candidatePos = map.map[row * map.width + col]

        if (!isNew(candidatePos)) return table.node.nodeAt(candidatePos)
      }
    }

    return null
  }

  cellPositions.filter((pos) => isNew(pos) && !table.node.nodeAt(pos).childCount).sort((a, b) => b - a).forEach((pos) => {
    const cell = table.node.nodeAt(pos)
    const reference = findReference(pos)
    const cellPos = table.start + pos

    if (!reference) return

    const paragraph = reference.firstChild?.type.name === 'paragraph' ? reference.firstChild : null

    tr.insert(cellPos + 1, tr.doc.type.schema.nodes.paragraph.create(paragraph?.attrs))
    tr.setNodeMarkup(cellPos, null, { ...cell.attrs, htmlAttrs: reference.attrs.htmlAttrs })
  })
}

function runTableCommand (command, { state, tr, dispatch }, colsUpdate) {
  const table = findEditableTable(state)

  if (!table) return false

  if (!dispatch) return command(state)

  const rect = selectedRect(state)
  const colsMatch = table.node.attrs.cols.length === rect.map.width
  const existingCells = tableCellNodes(table.node)

  if (!command(state, () => {})) return false

  styleNewCells(tr, existingCells)

  if (colsUpdate && colsMatch) {
    const tablePos = tr.mapping.map(table.pos)
    const { attrs } = tr.doc.nodeAt(tablePos)
    const cols = [...attrs.cols]

    colsUpdate(cols, rect)

    tr.setNodeMarkup(tablePos, null, { ...attrs, cols })
  }

  return true
}

const TableCommands = Extension.create({
  name: 'tableCommands',
  extendNodeSchema (extension) {
    return extension.config.tableRole ? { tableRole: extension.config.tableRole } : {}
  },
  addProseMirrorPlugins () {
    const plugin = tableEditing()
    const { handlePaste } = plugin.props

    delete plugin.spec.appendTransaction

    plugin.props.handlePaste = (view, event, slice) => {
      const table = findTable(view.state.selection.$head)

      if (!table) return false
      if (!isRegularTable(table.node)) return view.state.selection instanceof CellSelection

      const existingCells = tableCellNodes(table.node)

      const dispatch = (tr) => {
        styleNewCells(tr, existingCells)

        view.dispatch(tr)
      }

      return handlePaste({ state: view.state, dispatch }, event, slice)
    }

    return [plugin]
  },
  addKeyboardShortcuts () {
    const clearCells = () => {
      const { state, view } = this.editor

      if (!(state.selection instanceof CellSelection)) return false

      const tr = state.tr

      state.selection.forEachCell((cell, pos) => {
        const paragraph = cell.firstChild?.type.name === 'paragraph' ? cell.firstChild : null

        tr.replaceWith(tr.mapping.map(pos + 1), tr.mapping.map(pos + cell.nodeSize - 1), state.schema.nodes.paragraph.create(paragraph?.attrs))
      })

      view.dispatch(tr)

      return true
    }

    return { Backspace: clearCells, Delete: clearCells, 'Mod-Backspace': clearCells, 'Mod-Delete': clearCells }
  },
  addCommands () {
    return {
      addTableRow: (after) => (props) => runTableCommand(after ? addRowAfter : addRowBefore, props),
      addTableColumn: (after) => (props) => runTableCommand(after ? addColumnAfter : addColumnBefore, props, (cols, rect) => {
        const index = after ? rect.right : rect.left

        cols.splice(index, 0, { ...cols[after ? index - 1 : index] })
      }),
      deleteTableRow: () => (props) => {
        const table = findEditableTable(props.state)

        if (!table) return false

        const rect = selectedRect(props.state)

        if (rect.top === 0 && rect.bottom === rect.map.height) {
          if (props.dispatch) deleteTableNode(props.tr, table)

          return true
        }

        return runTableCommand(deleteRow, props)
      },
      deleteTableColumn: () => (props) => {
        const table = findEditableTable(props.state)

        if (!table) return false

        const rect = selectedRect(props.state)

        if (rect.left === 0 && rect.right === rect.map.width) {
          if (props.dispatch) deleteTableNode(props.tr, table)

          return true
        }

        return runTableCommand(deleteColumn, props, (cols, { left, right }) => cols.splice(left, right - left))
      },
      mergeTableCells: () => (props) => runTableCommand(mergeCells, props),
      splitTableCell: () => (props) => runTableCommand(splitCell, props),
      setBlockAlign: (align) => ({ state, tr, dispatch, commands }) => {
        if (state.selection.node?.type.name === 'image') {
          return commands.setBlockStyle('text-align', align)
        }

        const table = findTable(state.selection.$from)

        if (!table) return false

        if (dispatch) {
          const el = document.createElement('table')

          el.style.cssText = table.node.attrs.htmlAttrs.style || ''

          const isFloating = ['left', 'right'].includes(el.style.float)
          let margins = { left: ['0', 'auto'], center: ['auto', 'auto'], right: ['auto', '0'] }[align]
          let htmlAttrs = table.node.attrs.htmlAttrs

          if (isFloating && align !== 'center') {
            const gap = [el.style.marginLeft, el.style.marginRight].find((value) => parseFloat(value)) || '0'

            margins = align === 'left' ? ['0', gap] : [gap, '0']
            htmlAttrs = withStyle(htmlAttrs, 'float', align)
          } else {
            htmlAttrs = withStyle(htmlAttrs, 'float', null)
          }

          htmlAttrs = withStyle(withStyle(htmlAttrs, 'margin-left', margins[0]), 'margin-right', margins[1])

          delete htmlAttrs.align

          tr.setNodeMarkup(table.pos, null, { ...table.node.attrs, htmlAttrs })
        }

        return true
      },
      deleteTable: () => ({ state, tr, dispatch }) => {
        const table = findTable(state.selection.$from)

        if (!table) return false

        if (dispatch) deleteTableNode(tr, table)

        return true
      }
    }
  }
})

function pxToPt (px) {
  return `${Math.round(px * 0.75 * 10) / 10}pt`
}

function tableColumnsRow (tableDom) {
  const rows = [...tableDom.rows]
  const columnsCount = Math.max(...rows.map((row) => [...row.cells].reduce((acc, cell) => acc + cell.colSpan, 0)))

  return rows.find((row) => row.cells.length === columnsCount)
}

function tablePosFromDom (view, tableDom) {
  return view.posAtDOM(tableDom.rows[0], 0) - 2
}

function setTableColumnWidths (view, tableDom, widths) {
  const tablePos = tablePosFromDom(view, tableDom)
  const table = view.state.doc.nodeAt(tablePos)
  const cols = widths.map((width) => ({ style: `width: ${pxToPt(width)}` }))
  const tableStyle = updateStyle(updateStyle(table.attrs.htmlAttrs.style, 'table-layout', 'fixed'), 'width', pxToPt(widths.reduce((acc, width) => acc + width, 0)))

  view.dispatch(view.state.tr.setNodeMarkup(tablePos, null, { ...table.attrs, cols, htmlAttrs: { ...table.attrs.htmlAttrs, style: tableStyle } }))
}

function cellMinHeight (cellDom, zoom, withMargins) {
  const style = getComputedStyle(cellDom)
  const first = cellDom.firstElementChild
  const last = cellDom.lastElementChild
  const chrome = parseFloat(style.paddingTop) + parseFloat(style.paddingBottom) + (parseFloat(style.borderTopWidth) + parseFloat(style.borderBottomWidth)) / 2

  if (!first) return chrome * zoom

  const margins = withMargins ? parseFloat(getComputedStyle(first).marginTop) + parseFloat(getComputedStyle(last).marginBottom) : 0

  return last.getBoundingClientRect().bottom - first.getBoundingClientRect().top + (margins + chrome) * zoom
}

export function tableRowMinHeights (tableDom, zoom, withMargins = true) {
  return [...tableDom.rows].map((row) => Math.max(...[...row.cells].map((cell) => cellMinHeight(cell, zoom, withMargins))))
}

function scaleTableRows (view, tablePos, height, zoom) {
  const tableDom = view.nodeDOM(tablePos)
  const rows = [...tableDom.rows]
  const heights = rows.map((row) => row.getBoundingClientRect().height / zoom)
  const total = heights.reduce((acc, value) => acc + value, 0)
  const tr = view.state.tr
  let newHeights

  if (height >= total) {
    newHeights = heights.map((value) => value * height / total)
  } else {
    let mins = tableRowMinHeights(tableDom, zoom).map((value, index) => Math.min(value / zoom, heights[index]))
    let minTotal = mins.reduce((acc, value) => acc + value, 0)

    if (height < minTotal) {
      mins = tableRowMinHeights(tableDom, zoom, false).map((value, index) => Math.min(value / zoom, heights[index]))
      minTotal = mins.reduce((acc, value) => acc + value, 0)

      tr.doc.nodeAt(tablePos).descendants((node, pos) => {
        if (!node.isTextblock) return

        const htmlAttrs = withStyle(withStyle(node.attrs.htmlAttrs, 'margin-top', '0'), 'margin-bottom', '0')

        tr.setNodeMarkup(tablePos + 1 + pos, null, { ...node.attrs, htmlAttrs })

        return false
      })
    }

    const ratio = total > minTotal ? Math.max(height - minTotal, 0) / (total - minTotal) : 0

    newHeights = heights.map((value, index) => mins[index] + (value - mins[index]) * ratio)
  }

  rows.forEach((rowDom, index) => {
    const rowPos = view.posAtDOM(rowDom, 0) - 1
    const row = tr.doc.nodeAt(rowPos)

    tr.setNodeMarkup(rowPos, null, { ...row.attrs, htmlAttrs: withStyle(row.attrs.htmlAttrs, 'height', pxToPt(newHeights[index])) })
  })

  view.dispatch(tr)
}

export function resizeTable (view, tablePos, { width, height }, zoom) {
  const tableDom = view.nodeDOM(tablePos)
  const tableRect = tableDom.getBoundingClientRect()

  if (Math.round(height) !== Math.round(tableRect.height / zoom)) {
    scaleTableRows(view, tablePos, height, zoom)
  }

  if (Math.round(width) === Math.round(tableRect.width / zoom)) return

  const columnsRow = tableColumnsRow(tableDom)

  if (columnsRow) {
    const widths = [...columnsRow.cells].map((cell) => cell.getBoundingClientRect().width / zoom)
    const scale = width / widths.reduce((acc, value) => acc + value, 0)

    setTableColumnWidths(view, tableDom, widths.map((value) => value * scale))
  } else {
    const table = view.state.doc.nodeAt(tablePos)

    view.dispatch(view.state.tr.setNodeMarkup(tablePos, null, { ...table.attrs, htmlAttrs: withStyle(table.attrs.htmlAttrs, 'width', pxToPt(width)) }))
  }
}

function resizeImage (view, pos, width) {
  const image = view.state.doc.nodeAt(pos)
  const htmlAttrs = { ...image.attrs.htmlAttrs }

  delete htmlAttrs.width
  delete htmlAttrs.height

  htmlAttrs.style = updateStyle(updateStyle(htmlAttrs.style, 'width', pxToPt(width)), 'height', 'auto')

  const tr = view.state.tr.setNodeMarkup(pos, null, { ...image.attrs, htmlAttrs })

  view.dispatch(tr.setSelection(NodeSelection.create(tr.doc, pos)))
}

const variableHighlightKey = new PluginKey('variableHighlight')

function buildDecorations (doc) {
  const decorations = []
  const regex = /\[\[[^\]]*\]\]/g

  doc.descendants((node, pos) => {
    if (!node.isText) return

    let match

    while ((match = regex.exec(node.text)) !== null) {
      const from = pos + match.index
      const to = from + match[0].length

      decorations.push(Decoration.inline(from, to, { nodeName: 'dynamic-variable' }))
    }
  })

  return DecorationSet.create(doc, decorations)
}

const VariableHighlight = Extension.create({
  name: 'variableHighlight',
  addProseMirrorPlugins () {
    return [
      new Plugin({
        key: variableHighlightKey,
        state: {
          init (_, { doc }) {
            return buildDecorations(doc)
          },
          apply (tr, oldSet) {
            if (tr.docChanged) {
              return buildDecorations(tr.doc)
            }

            return oldSet
          }
        },
        props: {
          decorations (state) {
            return this.getState(state)
          },
          handleTextInput (view, from, to, text) {
            if (text !== '[') return false

            const { state } = view
            const charBefore = state.doc.textBetween(Math.max(from - 1, 0), from)

            if (charBefore !== '[') return false

            const tr = state.tr.insertText('[]]', from, to)

            tr.setSelection(state.selection.constructor.create(tr.doc, from + 1))

            view.dispatch(tr)

            return true
          }
        }
      })
    ]
  }
})

export function buildEditor ({ dynamicAreaProps, getAttachmentsIndex, renderHtmlForSaveRef, onFieldDrop, onFieldDestroy, onUndo, onRedo, editorOptions }) {
  const FieldNode = Node.create({
    name: 'fieldNode',
    inline: true,
    group: 'inline',
    atom: true,
    draggable: true,
    addAttributes () {
      return {
        uuid: { default: null },
        areaUuid: { default: null },
        width: { default: '124px' },
        height: { default: null },
        verticalAlign: { default: 'text-bottom' },
        display: { default: 'inline-flex' }
      }
    },
    parseHTML () {
      return [{
        tag: 'dynamic-field',
        getAttrs (dom) {
          return {
            uuid: dom.getAttribute('uuid'),
            areaUuid: dom.getAttribute('area-uuid'),
            width: dom.style.width,
            height: dom.style.height,
            display: dom.style.display,
            verticalAlign: dom.style.verticalAlign
          }
        }
      }]
    },
    renderHTML ({ node }) {
      const attrs = {
        uuid: node.attrs.uuid,
        'area-uuid': node.attrs.areaUuid,
        style: `width: ${node.attrs.width}; height: ${node.attrs.height}; display: ${node.attrs.display}; vertical-align: ${node.attrs.verticalAlign};`
      }

      if (!renderHtmlForSaveRef.value) {
        const fieldArea = dynamicAreaProps.findFieldArea(node.attrs.areaUuid)

        if (fieldArea?.field && fieldArea?.area) {
          const field = JSON.parse(JSON.stringify(fieldArea.field))
          const area = JSON.parse(JSON.stringify(fieldArea.area))

          delete field.areas
          delete field.uuid
          delete field.submitter_uuid
          delete area.uuid
          delete area.attachment_uuid

          attrs['data-field'] = JSON.stringify(field)
          attrs['data-area'] = JSON.stringify(area)
          attrs['data-template-id'] = dynamicAreaProps.template.id
        }
      }

      return ['dynamic-field', attrs]
    },
    addNodeView () {
      return ({ node, getPos, editor }) => {
        const dom = document.createElement('span')

        const nodeStyle = reactive({
          width: node.attrs.width,
          height: node.attrs.height,
          verticalAlign: node.attrs.verticalAlign,
          display: node.attrs.display
        })

        dom.dataset.areaUuid = node.attrs.areaUuid

        const shadow = dom.attachShadow({ mode: 'open' })

        shadow.adoptedStyleSheets = [dynamicStylesheet]

        const app = createApp(DynamicArea, {
          fieldUuid: node.attrs.uuid,
          areaUuid: node.attrs.areaUuid,
          nodeStyle,
          getPos,
          editor,
          editable: editorOptions.editable,
          ...dynamicAreaProps
        })

        app.mount(shadow)

        return {
          dom,
          update (updatedNode) {
            if (updatedNode.attrs.areaUuid === node.attrs.areaUuid) {
              nodeStyle.width = updatedNode.attrs.width
              nodeStyle.height = updatedNode.attrs.height
              nodeStyle.verticalAlign = updatedNode.attrs.verticalAlign
              nodeStyle.display = updatedNode.attrs.display
            }
          },
          destroy () {
            onFieldDestroy(node)

            app.unmount()
          }
        }
      }
    }
  })

  const FieldDropPlugin = Extension.create({
    name: 'fieldDrop',
    addProseMirrorPlugins () {
      return [
        new Plugin({
          key: new PluginKey('fieldDrop'),
          props: {
            handleDrop: onFieldDrop
          }
        })
      ]
    }
  })

  const undo = () => {
    onUndo()

    return true
  }

  const redo = () => {
    onRedo()

    return true
  }

  const BuilderHistory = Extension.create({
    name: 'builderHistory',
    addKeyboardShortcuts () {
      return {
        'Mod-z': undo,
        'Shift-Mod-z': redo,
        'Mod-y': redo,
        'Mod-я': undo,
        'Shift-Mod-я': redo
      }
    },
    addProseMirrorPlugins () {
      return [
        new Plugin({
          key: new PluginKey('builderHistory'),
          props: {
            handleDOMEvents: {
              beforeinput (_view, event) {
                const command = { historyUndo: undo, historyRedo: redo }[event.inputType]

                if (!command) return false

                event.preventDefault()

                return command()
              }
            }
          }
        })
      ]
    }
  })

  const RESIZE_HANDLE_PX = 4
  const MIN_SIZE_PX = 16

  function findResizeTarget (view, event) {
    const cellDom = event.target.closest('td, th')

    if (!cellDom) return null

    const rect = cellDom.getBoundingClientRect()
    const isRow = Math.abs(event.clientY - rect.bottom) <= RESIZE_HANDLE_PX
    const isRight = Math.abs(event.clientX - rect.right) <= RESIZE_HANDLE_PX
    const isLeft = Math.abs(event.clientX - rect.left) <= RESIZE_HANDLE_PX

    if (!isRow && !isRight && !isLeft) return null

    const tableDom = cellDom.closest('table')
    const tablePos = tablePosFromDom(view, tableDom)
    const cell = TableMap.get(view.state.doc.nodeAt(tablePos)).findCell(view.posAtDOM(cellDom, 0) - tablePos - 2)

    if (isRow) {
      return { type: 'row', rowDom: tableDom.rows[cell.bottom - 1], tableDom }
    }

    const columnIndex = isRight ? cell.right - 1 : cell.left - 1

    if (columnIndex < 0 || !tableColumnsRow(tableDom)) return null

    return { type: 'column', columnIndex, tableDom }
  }

  function applyColumnResize (view, { tableDom, columnIndex }, delta) {
    const zoom = dynamicAreaProps.getZoom()
    const widths = [...tableColumnsRow(tableDom).cells].map((cell) => cell.getBoundingClientRect().width / zoom)

    if (columnIndex + 1 < widths.length) {
      const change = Math.max(Math.min(delta, widths[columnIndex + 1] - MIN_SIZE_PX), MIN_SIZE_PX - widths[columnIndex])

      widths[columnIndex] += change
      widths[columnIndex + 1] -= change
    } else {
      const maxDelta = (view.dom.parentElement.getBoundingClientRect().right - tableDom.getBoundingClientRect().right) / zoom

      widths[columnIndex] = Math.max(widths[columnIndex] + Math.min(delta, Math.max(maxDelta, 0)), MIN_SIZE_PX)
    }

    setTableColumnWidths(view, tableDom, widths)
  }

  function applyRowResize (view, { rowDom }, delta) {
    const height = Math.max(rowDom.getBoundingClientRect().height / dynamicAreaProps.getZoom() + delta, MIN_SIZE_PX)
    const rowPos = view.posAtDOM(rowDom, 0) - 1
    const row = view.state.doc.nodeAt(rowPos)

    view.dispatch(view.state.tr.setNodeMarkup(rowPos, null, { ...row.attrs, htmlAttrs: withStyle(row.attrs.htmlAttrs, 'height', pxToPt(height)) }))
  }

  function startTableResize (view, event, target) {
    const tableRect = target.tableDom.getBoundingClientRect()
    const isColumn = target.type === 'column'
    const guide = document.createElement('div')

    guide.style.cssText = `position: fixed; z-index: 9999; pointer-events: none; background: #3b82f6; ${isColumn ? `top: ${tableRect.top}px; height: ${tableRect.height}px; width: 1px;` : `left: ${tableRect.left}px; width: ${tableRect.width}px; height: 1px;`}`

    const moveGuide = (e) => {
      if (isColumn) {
        guide.style.left = `${e.clientX}px`
      } else {
        guide.style.top = `${e.clientY}px`
      }
    }

    moveGuide(event)
    document.body.appendChild(guide)
    document.body.style.cursor = isColumn ? 'col-resize' : 'row-resize'

    const onMouseUp = (e) => {
      window.removeEventListener('mousemove', moveGuide)
      window.removeEventListener('mouseup', onMouseUp)

      guide.remove()
      document.body.style.cursor = ''

      const delta = (isColumn ? e.clientX - event.clientX : e.clientY - event.clientY) / dynamicAreaProps.getZoom()

      if (!delta) return

      if (isColumn) {
        applyColumnResize(view, target, delta)
      } else {
        applyRowResize(view, target, delta)
      }
    }

    window.addEventListener('mousemove', moveGuide)
    window.addEventListener('mouseup', onMouseUp)
  }

  const TableResize = Extension.create({
    name: 'tableResize',
    addProseMirrorPlugins () {
      return [
        new Plugin({
          key: new PluginKey('tableResize'),
          props: {
            handleDOMEvents: {
              mousemove (view, event) {
                const target = view.editable && findResizeTarget(view, event)

                view.dom.style.cursor = target ? (target.type === 'column' ? 'col-resize' : 'row-resize') : ''

                return false
              },
              mouseleave (view) {
                view.dom.style.cursor = ''

                return false
              },
              mousedown (view, event) {
                const target = view.editable && event.button === 0 && findResizeTarget(view, event)

                if (!target) return false

                event.preventDefault()

                startTableResize(view, event, target)

                return true
              }
            }
          }
        })
      ]
    }
  })

  class ZoomedResizableNodeView extends ResizableNodeView {
    constructor (options) {
      super(options)

      this.wrapper.addEventListener('touchstart', (event) => {
        if (event.target.closest('[data-resize-handle]')) {
          document.addEventListener('touchend', this.handleTouchEnd)
          document.addEventListener('touchcancel', this.handleTouchEnd)
        }
      }, true)
    }

    handleTouchEnd = () => {
      document.removeEventListener('touchend', this.handleTouchEnd)
      document.removeEventListener('touchcancel', this.handleTouchEnd)
      document.removeEventListener('touchmove', this.handleTouchMove)

      this.handleMouseUp()
    }

    handleResize (deltaX, deltaY) {
      const zoom = dynamicAreaProps.getZoom()

      super.handleResize(deltaX / zoom, deltaY / zoom)
    }
  }

  const DynamicImageNode = ImageNode.extend({
    addProseMirrorPlugins () {
      return [
        new Plugin({
          props: {
            attributes: (state) => state.selection.node?.type.name === this.name ? { inputmode: 'none', style: 'caret-color: transparent' } : {}
          }
        })
      ]
    },
    renderHTML ({ node }) {
      const { loading, ...attrs } = node.attrs.htmlAttrs

      return ['img', attrs]
    },
    addNodeView () {
      return ({ node, getPos, editor }) => {
        const img = document.createElement('img')

        const attrs = { ...node.attrs.htmlAttrs }

        const blobUuid = attrs.src?.startsWith('blob:') && attrs.src.slice(5)
        const attachmentUrl = blobUuid && getAttachmentsIndex()[blobUuid]

        if (attachmentUrl) {
          attrs.src = attachmentUrl
        }

        img.setAttribute('loading', 'lazy')

        Object.entries(attrs).forEach(([k, v]) => img.setAttribute(k, v))

        if (!editorOptions.editable) {
          return { dom: img }
        }

        return new ZoomedResizableNodeView({
          element: img,
          node,
          editor,
          getPos,
          onCommit: (width) => resizeImage(editor.view, getPos(), width),
          onUpdate: (updatedNode) => updatedNode.attrs.htmlAttrs === node.attrs.htmlAttrs,
          options: {
            directions: ['top-left', 'top-right', 'bottom-left', 'bottom-right'],
            min: { width: MIN_SIZE_PX, height: MIN_SIZE_PX },
            preserveAspectRatio: true
          }
        })
      }
    }
  })

  return new Editor({
    extensions: [
      Document,
      Text,
      HardBreak,
      BuilderHistory,
      Gapcursor,
      Dropcursor,
      CustomParagraph,
      CustomHeading,
      SectionNode,
      ArticleNode,
      HeaderNode,
      FooterNode,
      DivNode,
      BlockquoteNode,
      PreNode,
      OrderedListNode,
      BulletListNode,
      ListItemNode,
      TableNode,
      TableRow,
      TableCell,
      TableHeader,
      DynamicImageNode,
      EmptySpanNode,
      LayoutSpanMark,
      LinkMark,
      SpanMark,
      CustomBold,
      CustomItalic,
      CustomUnderline,
      CustomStrike,
      SubscriptMark,
      SuperscriptMark,
      VariableHighlight,
      TabHandler,
      NumberingKeymap,
      Formatting,
      TableCommands,
      FieldNode,
      FieldDropPlugin,
      TableResize
    ],
    editorProps: {
      attributes: {
        style: 'outline: none'
      }
    },
    parseOptions: {
      preserveWhitespace: true
    },
    injectCSS: false,
    ...editorOptions
  })
}
