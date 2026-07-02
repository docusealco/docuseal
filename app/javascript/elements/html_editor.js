import { target, targetable } from '@github/catalyst/lib/targetable'
import { actionable } from '@github/catalyst/lib/actionable'
import { LinkTooltip } from './markdown_editor'

async function loadTiptap () {
  const [core, document, text, hardBreak, gapcursor, dropcursor, extensions, pmState, pmView] = await Promise.all([
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/core'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-document'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-text'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-hard-break'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-gapcursor'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-dropcursor'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extensions'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/pm/state'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/pm/view')
  ])

  return {
    Editor: core.Editor,
    Extension: core.Extension,
    Node: core.Node,
    Mark: core.Mark,
    Document: document.default || document,
    Text: text.default || text,
    HardBreak: hardBreak.default || hardBreak,
    Gapcursor: gapcursor.default || gapcursor,
    Dropcursor: dropcursor.default || dropcursor,
    UndoRedo: extensions.UndoRedo,
    Plugin: pmState.Plugin,
    Decoration: pmView.Decoration,
    DecorationSet: pmView.DecorationSet
  }
}

const editorStylesheet = new CSSStyleSheet()

editorStylesheet.replaceSync(`
:host {
  display: block;
  max-height: 360px;
  overflow: auto;
  border-radius: 0 0 1rem 1rem;
}

.ProseMirror {
  word-wrap: break-word;
  -webkit-font-variant-ligatures: none;
  font-variant-ligatures: none;
  font-feature-settings: "liga" 0;
  outline: none;
  min-height: 220px;
  padding: 12px;
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

.variable-highlight {
  background-color: #fef3c7;
  padding: 1px 2px;
  border-radius: 4px;
}
`)

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

function buildExtensions ({ Node, Mark, Extension, Plugin, Decoration, DecorationSet }) {
  const blockNode = (name, tag, content, extra = {}) => Node.create({
    name,
    group: 'block',
    content: content || 'block+',
    ...extra,
    addAttributes () {
      return { htmlAttrs: { default: {} } }
    },
    parseHTML () {
      return [{ tag, getAttrs: collectDomAttrs }]
    },
    renderHTML ({ node }) {
      return [tag, node.attrs.htmlAttrs, 0]
    }
  })

  const attrsMark = (name, tag) => Mark.create({
    name,
    addAttributes () {
      return { htmlAttrs: { default: {} } }
    },
    parseHTML () {
      return [{ tag, getAttrs: collectDomAttrs }]
    },
    renderHTML ({ mark }) {
      return [tag, mark.attrs.htmlAttrs, 0]
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

  const toggleMark = (name, renderTag, parseRules, shortcuts) => Mark.create({
    name,
    parseHTML () {
      return parseRules
    },
    renderHTML () {
      return [renderTag, 0]
    },
    addCommands () {
      const commandName = `toggle${name[0].toUpperCase()}${name.slice(1)}`

      return {
        [commandName]: () => ({ commands }) => commands.toggleMark(name)
      }
    },
    addKeyboardShortcuts () {
      return {
        [shortcuts]: () => this.editor.commands.toggleMark(name)
      }
    }
  })

  const Heading = Node.create({
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

  const HrNode = Node.create({
    name: 'horizontalRule',
    group: 'block',
    atom: true,
    addAttributes () {
      return { htmlAttrs: { default: {} } }
    },
    parseHTML () {
      return [{ tag: 'hr', getAttrs: collectDomAttrs }]
    },
    renderHTML ({ node }) {
      return ['hr', node.attrs.htmlAttrs]
    }
  })

  const StyleNode = Node.create({
    name: 'style',
    group: 'block',
    atom: true,
    selectable: false,
    addAttributes () {
      return {
        htmlAttrs: { default: {} },
        css: { default: '' }
      }
    },
    parseHTML () {
      return [{ tag: 'style', getAttrs: (dom) => ({ ...collectDomAttrs(dom), css: dom.textContent }) }]
    },
    renderHTML ({ node }) {
      return ['style', node.attrs.htmlAttrs, node.attrs.css]
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

  const LinkMark = Mark.create({
    name: 'link',
    inclusive: true,
    addAttributes () {
      return { htmlAttrs: { default: {} } }
    },
    parseHTML () {
      return [{ tag: 'a', getAttrs: collectDomAttrs }]
    },
    renderHTML ({ mark }) {
      return ['a', mark.attrs.htmlAttrs, 0]
    },
    addCommands () {
      return {
        setLink: ({ href }) => ({ editor, commands }) => {
          const htmlAttrs = { ...(editor.getAttributes('link').htmlAttrs || {}), href }

          return commands.setMark('link', { htmlAttrs })
        },
        unsetLink: () => ({ commands }) => commands.unsetMark('link', { extendEmptyMarkRange: true })
      }
    }
  })

  const buildDecorations = (doc) => {
    const decorations = []
    const regex = /\{\{?[a-zA-Z0-9_.-]+\}\}?/g

    doc.descendants((node, pos) => {
      if (!node.isText) return

      let match

      while ((match = regex.exec(node.text)) !== null) {
        decorations.push(
          Decoration.inline(pos + match.index, pos + match.index + match[0].length, {
            class: 'variable-highlight'
          })
        )
      }
    })

    return DecorationSet.create(doc, decorations)
  }

  const VariableHighlight = Extension.create({
    name: 'variableHighlight',
    addProseMirrorPlugins () {
      return [new Plugin({
        state: {
          init (_, { doc }) {
            return buildDecorations(doc)
          },
          apply (tr, oldSet) {
            return tr.docChanged ? buildDecorations(tr.doc) : oldSet
          }
        },
        props: {
          decorations (state) {
            return this.getState(state)
          }
        }
      })]
    }
  })

  return [
    blockNode('paragraph', 'p', 'inline*'),
    Heading,
    blockNode('section', 'section'),
    blockNode('article', 'article', null, { isolating: true }),
    blockNode('header', 'header', null, { isolating: true }),
    blockNode('footer', 'footer', null, { isolating: true }),
    blockNode('div', 'div'),
    blockNode('center', 'center'),
    blockNode('blockquote', 'blockquote'),
    blockNode('pre', 'pre'),
    blockNode('orderedList', 'ol', '(listItem | block)+'),
    blockNode('bulletList', 'ul', '(listItem | block)+'),
    blockNode('listItem', 'li', 'block+', { group: null }),
    blockNode('table', 'table', '(colgroup | tableHead | tableBody | tableFoot | tableRow)+'),
    blockNode('tableHead', 'thead', 'tableRow+', { group: null }),
    blockNode('tableBody', 'tbody', 'tableRow+', { group: null }),
    blockNode('tableFoot', 'tfoot', 'tableRow+', { group: null }),
    blockNode('tableRow', 'tr', '(tableCell | tableHeader)+', { group: null }),
    blockNode('tableCell', 'td', 'block*', { group: null }),
    blockNode('tableHeader', 'th', 'block*', { group: null }),
    blockNode('colgroup', 'colgroup', 'col*', { group: null }),
    Node.create({
      name: 'col',
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
    }),
    ImageNode,
    HrNode,
    StyleNode,
    EmptySpanNode,
    SpanMark,
    LinkMark,
    toggleMark('bold', 'strong', [{ tag: 'strong' }, { tag: 'b' }, { style: 'font-weight=bold' }, { style: 'font-weight=700' }], 'Mod-b'),
    toggleMark('italic', 'em', [{ tag: 'em' }, { tag: 'i' }, { style: 'font-style=italic' }], 'Mod-i'),
    toggleMark('underline', 'u', [{ tag: 'u' }, { style: 'text-decoration=underline' }], 'Mod-u'),
    toggleMark('strike', 's', [{ tag: 's' }, { tag: 'del' }, { tag: 'strike' }, { style: 'text-decoration=line-through' }], 'Mod-Shift-s'),
    attrsMark('subscript', 'sub'),
    attrsMark('superscript', 'sup'),
    VariableHighlight
  ]
}

export default actionable(targetable(class extends HTMLElement {
  static [target.static] = [
    'textarea',
    'editorElement',
    'boldButton',
    'italicButton',
    'underlineButton',
    'linkButton',
    'linkTooltipTemplate'
  ]

  async connectedCallback () {
    if (!this.textarea || !this.editorElement) return

    this.textarea.style.display = 'none'
    this.adjustShortcutsForPlatform()

    const tiptap = await loadTiptap()

    const { Editor, Extension, Document, Text, HardBreak, UndoRedo, Gapcursor, Dropcursor } = tiptap

    this.emailDocument = new DOMParser().parseFromString(this.textarea.value, 'text/html')

    const shadow = this.editorElement.attachShadow({ mode: 'open' })

    shadow.adoptedStyleSheets = [editorStylesheet]

    this.emailDocument.head.querySelectorAll('style').forEach((style) => {
      shadow.appendChild(style.cloneNode(true))
    })

    const container = document.createElement('div')
    const bodyStyle = this.emailDocument.body.getAttribute('style')

    if (bodyStyle) container.setAttribute('style', bodyStyle)

    shadow.appendChild(container)

    const LinkShortcut = Extension.create({
      name: 'linkShortcut',
      addKeyboardShortcuts: () => ({
        'Mod-k': () => {
          this.toggleLink()

          return true
        }
      })
    })

    this.editor = new Editor({
      element: container,
      extensions: [
        Document,
        Text,
        HardBreak,
        UndoRedo,
        Gapcursor,
        Dropcursor,
        ...buildExtensions(tiptap),
        LinkShortcut
      ],
      content: this.emailDocument.body.innerHTML,
      injectCSS: false,
      editorProps: {
        attributes: {
          dir: 'auto'
        },
        handleDOMEvents: {
          click: (_, event) => {
            if (event.target.closest('a')) event.preventDefault()

            return false
          }
        }
      },
      onUpdate: ({ editor }) => {
        this.emailDocument.body.innerHTML = editor.getHTML()

        this.textarea.value = this.emailDocument.documentElement.outerHTML
        this.textarea.dispatchEvent(new Event('input', { bubbles: true }))
      },
      onSelectionUpdate: ({ editor }) => {
        this.updateToolbarState()
        this.handleLinkTooltip(editor)
      },
      onBlur: () => {
        setTimeout(() => {
          if (!this.linkTooltip.tooltip.contains(document.activeElement)) {
            this.linkTooltip.hide()
          }
        }, 0)
      }
    })

    this.linkTooltip = new LinkTooltip(this, this.editor, this.linkTooltipTemplate)
  }

  adjustShortcutsForPlatform () {
    if ((navigator.userAgentData?.platform)?.toLowerCase()?.includes('mac')) {
      this.querySelectorAll('.tooltip[data-tip]').forEach(tooltip => {
        const tip = tooltip.getAttribute('data-tip')

        if (tip && tip.includes('Ctrl')) {
          tooltip.setAttribute('data-tip', tip.replace(/Ctrl/g, '⌘'))
        }
      })
    }
  }

  bold (e) {
    e.preventDefault()

    this.editor.chain().focus().toggleBold().run()
    this.updateToolbarState()
  }

  italic (e) {
    e.preventDefault()

    this.editor.chain().focus().toggleItalic().run()
    this.updateToolbarState()
  }

  underline (e) {
    e.preventDefault()

    this.editor.chain().focus().toggleUnderline().run()
    this.updateToolbarState()
  }

  linkSelection (e) {
    e.preventDefault()

    this.toggleLink()
    this.updateToolbarState()
  }

  undo (e) {
    e.preventDefault()

    this.editor.chain().focus().undo().run()
    this.updateToolbarState()
  }

  redo (e) {
    e.preventDefault()

    this.editor.chain().focus().redo().run()
    this.updateToolbarState()
  }

  updateToolbarState () {
    this.boldButton.classList.toggle('bg-base-200', this.editor.isActive('bold'))
    this.italicButton.classList.toggle('bg-base-200', this.editor.isActive('italic'))
    this.underlineButton.classList.toggle('bg-base-200', this.editor.isActive('underline'))
    this.linkButton.classList.toggle('bg-base-200', this.editor.isActive('link'))
  }

  handleLinkTooltip (editor) {
    const { from } = editor.state.selection
    const mark = editor.state.doc.resolve(from).marks().find(m => m.type.name === 'link')

    if (!mark) {
      if (this.linkTooltip.isVisible()) this.linkTooltip.hide()

      return
    }

    if (this.linkTooltip.isVisible() && this.linkTooltip.currentMark === mark) return

    let linkStart = from
    const start = editor.state.doc.resolve(from).start()

    for (let i = from - 1; i >= start; i--) {
      if (editor.state.doc.resolve(i).marks().some(m => m.eq(mark))) {
        linkStart = i
      } else {
        break
      }
    }

    this.linkTooltip.hide()
    this.linkTooltip.show(mark.attrs.htmlAttrs?.href, linkStart > start ? linkStart - 1 : linkStart)
    this.linkTooltip.currentMark = mark
  }

  toggleLink () {
    if (this.editor.isActive('link')) {
      this.linkTooltip.hide()
      this.editor.chain().focus().extendMarkRange('link').unsetLink().run()
      this.updateToolbarState()
    } else {
      const { from } = this.editor.state.selection

      this.linkTooltip.hide()
      this.linkTooltip.show(this.editor.getAttributes('link').htmlAttrs?.href, from, { focus: true })
    }
  }

  insertVariable (e) {
    const variable = e.target.closest('[data-variable]')?.dataset.variable

    if (variable) {
      const { from, to } = this.editor.state.selection

      if (variable.includes('link') && from !== to) {
        this.editor.chain().focus().setLink({ href: `{${variable}}` }).run()
      } else {
        this.editor.chain().focus().insertContent(`{${variable}}`).run()
      }
    }
  }

  disconnectedCallback () {
    this.linkTooltip?.hide()

    if (this.editor) {
      this.editor.destroy()
    }
  }
}))
