import { target, targetable } from '@github/catalyst/lib/targetable'
import { actionable } from '@github/catalyst/lib/actionable'

function loadTiptap () {
  return Promise.all([
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/core'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-bold'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-italic'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-paragraph'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-text'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-hard-break'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-document'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-link'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extension-underline'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/extensions'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/markdown'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/pm/state'),
    import(/* webpackChunkName: "markdown-editor" */ '@tiptap/pm/view')
  ]).then(([core, bold, italic, paragraph, text, hardBreak, document, link, underline, extensions, markdown, pmState, pmView]) => ({
    Editor: core.Editor,
    Extension: core.Extension,
    Bold: bold.default || bold,
    Italic: italic.default || italic,
    Paragraph: paragraph.default || paragraph,
    Text: text.default || text,
    HardBreak: hardBreak.default || hardBreak,
    Document: document.default || document,
    Link: link.default || link,
    Underline: underline.default || underline,
    UndoRedo: extensions.UndoRedo,
    Markdown: markdown.Markdown,
    Plugin: pmState.Plugin,
    Decoration: pmView.Decoration,
    DecorationSet: pmView.DecorationSet
  }))
}

class LinkTooltip {
  constructor (tooltip, input, saveButton, removeButton, editor) {
    this.tooltip = tooltip
    this.input = input
    this.saveButton = saveButton
    this.removeButton = removeButton
    this.editor = editor
  }

  isVisible () {
    return !this.tooltip.classList.contains('hidden')
  }

  updatePosition () {
    const rect = this.editor.view.coordsAtPos(this.pos)

    this.tooltip.style.left = `${rect.left}px`
    this.tooltip.style.top = `${rect.bottom + 6}px`
  }

  normalizeUrl (url) {
    if (!url) return url
    if (/^{/i.test(url)) return url
    if (/^https?:\/\//i.test(url)) return url
    if (/^mailto:/i.test(url)) return url

    return `https://${url}`
  }

  show (url, pos) {
    this.input.value = url || ''
    this.removeButton.classList.toggle('hidden', !url)
    this.pos = pos

    this.tooltip.classList.remove('hidden')

    this.updatePosition()

    this.saveHandler = () => {
      const inputUrl = this.input.value.trim()

      if (inputUrl) {
        this.editor.chain().focus().extendMarkRange('link').setLink({ href: this.normalizeUrl(inputUrl) }).run()
      }

      this.hide()
    }

    this.removeHandler = () => {
      this.editor.chain().focus().extendMarkRange('link').unsetLink().run()

      this.hide()
    }

    this.keyHandler = (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        this.saveHandler()
      } else if (e.key === 'Escape') {
        e.preventDefault()
        this.hide()
      }
    }

    this.saveButton.addEventListener('click', this.saveHandler, { once: true })
    this.removeButton.addEventListener('click', this.removeHandler, { once: true })
    this.input.addEventListener('keydown', this.keyHandler)

    this.scrollHandler = () => this.updatePosition()
    window.addEventListener('scroll', this.scrollHandler, true)
  }

  hide () {
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler, true)
      this.scrollHandler = null
    }

    if (this.saveHandler) {
      this.saveButton.removeEventListener('click', this.saveHandler)
      this.saveHandler = null
    }

    if (this.removeHandler) {
      this.removeButton.removeEventListener('click', this.removeHandler)
      this.removeHandler = null
    }

    if (this.keyHandler) {
      this.input.removeEventListener('keydown', this.keyHandler)
      this.keyHandler = null
    }

    this.tooltip?.classList.add('hidden')
    this.currentMark = null
  }
}

export default actionable(targetable(class extends HTMLElement {
  static [target.static] = [
    'textarea',
    'editorElement',
    'boldButton',
    'italicButton',
    'underlineButton',
    'linkButton',
    'undoButton',
    'redoButton',
    'linkTooltipElement',
    'linkInput',
    'linkSaveButton',
    'linkRemoveButton'
  ]

  async connectedCallback () {
    if (!this.textarea || !this.editorElement) return

    this.textarea.style.display = 'none'
    this.adjustShortcutsForPlatform()

    const { Editor, Extension, Bold, Italic, Paragraph, Text, HardBreak, UndoRedo, Document, Link, Underline, Markdown, Plugin, Decoration, DecorationSet } = await loadTiptap()

    const buildDecorations = (doc) => {
      const decorations = []
      const regex = /\{[a-zA-Z0-9_.-]+\}/g

      doc.descendants((node, pos) => {
        if (!node.isText) return

        let match

        while ((match = regex.exec(node.text)) !== null) {
          decorations.push(
            Decoration.inline(pos + match.index, pos + match.index + match[0].length, {
              class: 'bg-amber-100 py-0.5 px-1 rounded'
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

    this.editor = new Editor({
      element: this.editorElement,
      extensions: [
        Markdown,
        Document,
        Paragraph,
        Text,
        Bold,
        Italic,
        HardBreak,
        UndoRedo,
        Link.extend({
          inclusive: true,
          addKeyboardShortcuts: () => ({
            'Mod-k': () => {
              this.toggleLink()

              return true
            }
          })
        }).configure({
          openOnClick: false,
          HTMLAttributes: {
            class: 'link',
            'data-turbo': 'false',
            style: 'color: #2563eb; text-decoration: underline; cursor: text;'
          }
        }),
        Underline,
        VariableHighlight
      ],
      content: this.textarea.value || '',
      contentType: 'markdown',
      editorProps: {
        attributes: {
          style: 'min-height: 220px',
          class: 'p-3 outline-none focus:outline-none'
        }
      },
      onUpdate: ({ editor }) => {
        this.textarea.value = editor.getMarkdown()
        this.textarea.dispatchEvent(new Event('input', { bubbles: true }))
      },
      onSelectionUpdate: ({ editor }) => {
        this.updateToolbarState()
        this.handleLinkTooltip(editor)
      },
      onBlur: () => {
        setTimeout(() => {
          if (!this.linkTooltipElement.contains(document.activeElement)) {
            this.linkTooltip.hide()
          }
        }, 0)
      }
    })

    this.linkTooltip = new LinkTooltip(
      this.linkTooltipElement,
      this.linkInput,
      this.linkSaveButton,
      this.linkRemoveButton,
      this.editor
    )

    this.setupToolbar()
  }

  adjustShortcutsForPlatform () {
    if ((navigator.userAgentData?.platform || navigator.platform)?.toLowerCase()?.includes('mac')) {
      this.querySelectorAll('.tooltip[data-tip]').forEach(tooltip => {
        const tip = tooltip.getAttribute('data-tip')

        if (tip && tip.includes('Ctrl')) {
          tooltip.setAttribute('data-tip', tip.replace(/Ctrl/g, '⌘'))
        }
      })
    }
  }

  setupToolbar () {
    this.boldButton?.addEventListener('click', (e) => {
      e.preventDefault()
      this.editor.chain().focus().toggleBold().run()
      this.updateToolbarState()
    })

    this.italicButton?.addEventListener('click', (e) => {
      e.preventDefault()
      this.editor.chain().focus().toggleItalic().run()
      this.updateToolbarState()
    })

    this.underlineButton?.addEventListener('click', (e) => {
      e.preventDefault()
      this.editor.chain().focus().toggleUnderline().run()
      this.updateToolbarState()
    })

    this.linkButton?.addEventListener('click', (e) => {
      e.preventDefault()
      this.toggleLink()
    })

    this.undoButton?.addEventListener('click', (e) => {
      e.preventDefault()
      this.editor.chain().focus().undo().run()
    })

    this.redoButton?.addEventListener('click', (e) => {
      e.preventDefault()
      this.editor.chain().focus().redo().run()
    })
  }

  updateToolbarState () {
    this.boldButton?.classList.toggle('bg-base-200', this.editor.isActive('bold'))
    this.italicButton?.classList.toggle('bg-base-200', this.editor.isActive('italic'))
    this.underlineButton?.classList.toggle('bg-base-200', this.editor.isActive('underline'))
    this.linkButton?.classList.toggle('bg-base-200', this.editor.isActive('link'))
  }

  handleLinkTooltip (editor) {
    const { from } = editor.state.selection
    const mark = editor.state.doc.resolve(from).marks().find(m => m.type.name === 'link')

    if (!mark) {
      if (this.linkTooltip.isVisible()) this.linkTooltip.hide()

      return
    }

    let linkStart = from
    const start = editor.state.doc.resolve(from).start()

    for (let i = from - 1; i >= start; i--) {
      if (editor.state.doc.resolve(i).marks().some(m => m.eq(mark))) {
        linkStart = i
      } else {
        break
      }
    }

    if (this.linkTooltip.isVisible() && this.linkTooltip.currentMark === mark) return

    this.linkTooltip.hide()

    this.linkTooltip.show(mark.attrs.href, linkStart > start ? linkStart - 1 : linkStart)

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
      this.linkTooltip.show(this.editor.getAttributes('link').href, from)
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
    this.linkTooltip.hide()

    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
  }
}))
