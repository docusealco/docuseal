import { Editor, Extension, Node, Mark } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import { Decoration, DecorationSet } from '@tiptap/pm/view'
import Document from '@tiptap/extension-document'
import Text from '@tiptap/extension-text'
import HardBreak from '@tiptap/extension-hard-break'
import History from '@tiptap/extension-history'
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
  position: relative;
}

.ProseMirror {
  word-wrap: break-word;
  white-space: pre-wrap;
  white-space: break-spaces;
  -webkit-font-variant-ligatures: none;
  font-variant-ligatures: none;
  font-feature-settings: "liga" 0;
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
dynamic-variable {
  background-color: #fef3c7;
}`)

function collectDomAttrs (dom) {
  const attrs = {}

  for (let i = 0; i < dom.attributes.length; i++) {
    attrs[dom.attributes[i].name] = dom.attributes[i].value
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

    if (temp.style.textDecoration === 'underline') {
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

function createBlockNode (name, tag, content) {
  return Node.create({
    name,
    group: 'block',
    content: content || 'block+',
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
const ArticleNode = createBlockNode('article', 'article')
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

const TableNode = Node.create({
  name: 'table',
  group: 'block',
  content: '(colgroup | tableHead | tableBody | tableRow)+',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'table', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['table', node.attrs.htmlAttrs, 0]
  }
})

const TableHead = Node.create({
  name: 'tableHead',
  content: 'tableRow+',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'thead', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['thead', node.attrs.htmlAttrs, 0]
  }
})

const TableBody = Node.create({
  name: 'tableBody',
  content: 'tableRow+',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'tbody', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['tbody', node.attrs.htmlAttrs, 0]
  }
})

const TableRow = Node.create({
  name: 'tableRow',
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

const TableCell = Node.create({
  name: 'tableCell',
  content: 'block*',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'td', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['td', node.attrs.htmlAttrs, 0]
  }
})

const TableHeader = Node.create({
  name: 'tableHeader',
  content: 'block*',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'th', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['th', node.attrs.htmlAttrs, 0]
  }
})

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

const ColGroupNode = Node.create({
  name: 'colgroup',
  group: 'block',
  content: 'col*',
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'colgroup', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['colgroup', node.attrs.htmlAttrs, 0]
  }
})

const ColNode = Node.create({
  name: 'col',
  group: 'block',
  atom: true,
  addAttributes () {
    return { htmlAttrs: { default: {} } }
  },
  parseHTML () {
    return [{ tag: 'col', getAttrs: collectDomAttrs }]
  },
  renderHTML ({ node }) {
    return ['col', node.attrs.htmlAttrs]
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

export function buildEditor ({ dynamicAreaProps, attachmentsIndex, renderHtmlForSaveRef, onFieldDrop, onFieldDestroy, editorOptions }) {
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

  const DynamicImageNode = ImageNode.extend({
    renderHTML ({ node }) {
      const { loading, ...attrs } = node.attrs.htmlAttrs

      return ['img', attrs]
    },
    addNodeView () {
      return ({ node }) => {
        const dom = document.createElement('img')

        const attrs = { ...node.attrs.htmlAttrs }

        const blobUuid = attrs.src?.startsWith('blob:') && attrs.src.slice(5)

        if (blobUuid && attachmentsIndex[blobUuid]) {
          attrs.src = attachmentsIndex[blobUuid]
        }

        dom.setAttribute('loading', 'lazy')

        Object.entries(attrs).forEach(([k, v]) => dom.setAttribute(k, v))

        return { dom }
      }
    }
  })

  return new Editor({
    extensions: [
      Document,
      Text,
      HardBreak,
      History,
      Gapcursor,
      Dropcursor,
      CustomBold,
      CustomItalic,
      CustomUnderline,
      CustomStrike,
      CustomParagraph,
      CustomHeading,
      SectionNode,
      ArticleNode,
      DivNode,
      BlockquoteNode,
      PreNode,
      OrderedListNode,
      BulletListNode,
      ListItemNode,
      TableNode,
      TableHead,
      TableBody,
      TableRow,
      TableCell,
      TableHeader,
      ColGroupNode,
      ColNode,
      DynamicImageNode,
      EmptySpanNode,
      LinkMark,
      SpanMark,
      SubscriptMark,
      SuperscriptMark,
      VariableHighlight,
      TabHandler,
      FieldNode,
      FieldDropPlugin
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
