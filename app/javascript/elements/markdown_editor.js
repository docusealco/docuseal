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
  constructor (container, editor) {
    this.container = container
    this.editor = editor

    const template = document.createElement('template')

    template.innerHTML = container.dataset.linkTooltipHtml

    this.tooltip = template.content.firstElementChild

    this.input = this.tooltip.querySelector('input')
    this.saveButton = this.tooltip.querySelector('[data-role="link-save"]')
    this.removeButton = this.tooltip.querySelector('[data-role="link-remove"]')

    container.style.position = 'relative'
    container.appendChild(this.tooltip)
  }

  isVisible () {
    return !this.tooltip.classList.contains('hidden')
  }

  normalizeUrl (url) {
    if (!url) return url
    if (/^{/i.test(url)) return url
    if (/^https?:\/\//i.test(url)) return url
    if (/^mailto:/i.test(url)) return url

    return `https://${url}`
  }

  show (url, pos, { focus = false } = {}) {
    this.input.value = url || ''
    this.removeButton.classList.toggle('hidden', !url)

    this.tooltip.classList.remove('hidden')

    const coords = this.editor.view.coordsAtPos(pos)
    const containerRect = this.container.getBoundingClientRect()

    this.tooltip.style.left = `${coords.left - containerRect.left}px`
    this.tooltip.style.top = `${coords.bottom - containerRect.top + 4}px`

    if (focus) this.input.focus()

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
  }

  hide () {
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

    this.tooltip.classList.add('hidden')
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
    'linkButton'
  ]

  async connectedCallback () {
    if (!this.textarea || !this.editorElement) return

    this.textarea.style.display = 'none'
    this.adjustShortcutsForPlatform()

    const { Editor, Extension, Bold, Italic, Paragraph, Text, HardBreak, UndoRedo, Document, Link, Underline, Markdown, Plugin, Decoration, DecorationSet } = await loadTiptap()

    const buildDecorations = (doc) => {
      const decorations = []
      const regex = /\{\{?[a-zA-Z0-9_.-]+\}\}?/g

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
        HardBreak.extend({
          addKeyboardShortcuts () {
            return {
              Enter: () => this.editor.commands.setHardBreak()
            }
          }
        }),
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
      content: (this.textarea.value || '').trim().replace(/ *\n/g, '<br>'),
      contentType: 'markdown',
      editorProps: {
        attributes: {
          style: 'min-height: 220px',
          dir: 'auto',
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
          if (!this.linkTooltip.tooltip.contains(document.activeElement)) {
            this.linkTooltip.hide()
          }
        }, 0)
      }
    })

    this.linkTooltip = new LinkTooltip(this, this.editor)
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
      this.linkTooltip.show(this.editor.getAttributes('link').href, from, { focus: true })
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
    }
  }
}))
