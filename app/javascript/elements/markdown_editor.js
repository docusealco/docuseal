import { target, targetable } from '@github/catalyst/lib/targetable'

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
  constructor (tooltip, input, saveButton, removeButton, normalizeUrlFn) {
    this.tooltip = tooltip
    this.input = input
    this.saveButton = saveButton
    this.removeButton = removeButton
    this.normalizeUrl = normalizeUrlFn
    this.targetElement = null
    this.clickOutsideTimeout = null
    this.closeOnClickOutside = null
    this.scrollHandler = null
    this.saveHandler = null
    this.removeHandler = null
    this.keyHandler = null
  }

  updatePosition () {
    const rect = this.targetElement.getBoundingClientRect()
    this.tooltip.style.left = `${rect.left}px`
    this.tooltip.style.top = `${rect.bottom + 5}px`
  }

  setupClickOutside () {
    this.closeOnClickOutside = (e) => {
      if (!this.tooltip.contains(e.target)) {
        this.hide()
      }
    }

    this.clickOutsideTimeout = setTimeout(() => {
      if (this.closeOnClickOutside) {
        document.addEventListener('click', this.closeOnClickOutside)
      }
    }, 100)
  }

  setupScrollTracking () {
    this.scrollHandler = () => this.updatePosition()
    window.addEventListener('scroll', this.scrollHandler, true)
  }

  show ({ url, targetElement, onSave, onRemove }) {
    this.hide()

    this.input.value = url || ''
    this.removeButton.classList.toggle('hidden', !url)
    this.targetElement = targetElement

    this.updatePosition()

    this.tooltip.classList.remove('hidden')
    this.input.focus()
    this.input.select()

    const save = () => {
      const inputUrl = this.input.value.trim()

      this.hide()

      if (inputUrl) {
        onSave(this.normalizeUrl(inputUrl))
      }
    }

    this.saveHandler = () => save()
    this.removeHandler = () => {
      if (onRemove) onRemove()
      this.hide()
    }
    this.keyHandler = (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        save()
      } else if (e.key === 'Escape') {
        e.preventDefault()
        this.hide()
      }
    }

    this.saveButton.addEventListener('click', this.saveHandler, { once: true })
    this.removeButton.addEventListener('click', this.removeHandler, { once: true })
    this.input.addEventListener('keydown', this.keyHandler)

    this.setupScrollTracking()
    this.setupClickOutside()
  }

  hide () {
    if (this.clickOutsideTimeout) {
      clearTimeout(this.clickOutsideTimeout)
      this.clickOutsideTimeout = null
    }

    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler, true)
      this.scrollHandler = null
    }

    if (this.closeOnClickOutside) {
      document.removeEventListener('click', this.closeOnClickOutside)
      this.closeOnClickOutside = null
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
    this.targetElement = null
  }
}

export default targetable(class extends HTMLElement {
  static [target.static] = [
    'textarea',
    'editorElement',
    'variableButton',
    'variableDropdown',
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

    this.linkTooltip = new LinkTooltip(
      this.linkTooltipElement,
      this.linkInput,
      this.linkSaveButton,
      this.linkRemoveButton,
      (url) => this.normalizeUrl(url)
    )

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
          inclusive: false
        }).configure({
          openOnClick: false,
          HTMLAttributes: {
            class: 'link',
            style: 'color: #2563eb; text-decoration: underline; cursor: pointer;'
          }
        }),
        Underline,
        VariableHighlight
      ],
      content: this.textarea.value || '',
      contentType: 'markdown',
      editorProps: {
        attributes: {
          class: 'prose prose-sm max-w-none p-3 outline-none focus:outline-none min-h-[120px]'
        },
        handleClick: (view, pos, event) => {
          const clickedPos = view.posAtCoords({ left: event.clientX, top: event.clientY })

          if (!clickedPos) return false

          const linkMark = view.state.doc.resolve(clickedPos.pos).marks().find(m => m.type.name === 'link')

          if (linkMark) {
            event.preventDefault()

            this.editor.chain().setTextSelection(clickedPos.pos).extendMarkRange('link').run()
            this.toggleLink()

            return true
          }

          return false
        }
      },
      onUpdate: ({ editor }) => {
        this.textarea.value = editor.getMarkdown()
        this.textarea.dispatchEvent(new Event('input', { bubbles: true }))
      },
      onSelectionUpdate: () => {
        this.updateToolbarState()
      }
    })

    this.setupToolbar()

    if (this.variableButton) {
      this.variableButton.addEventListener('click', () => {
        this.variableDropdown.classList.toggle('hidden')
      })

      this.variableDropdown.addEventListener('click', (e) => {
        const variable = e.target.closest('[data-variable]')?.dataset.variable

        if (variable) {
          this.insertVariable(variable)
          this.variableDropdown.classList.add('hidden')
        }
      })

      document.addEventListener('click', (e) => {
        if (!this.variableButton.contains(e.target) && !this.variableDropdown.contains(e.target)) {
          this.variableDropdown.classList.add('hidden')
        }
      })
    }
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

  normalizeUrl (url) {
    if (!url) return url
    if (/^https?:\/\//i.test(url)) return url
    if (/^mailto:/i.test(url)) return url

    return `https://${url}`
  }

  toggleLink () {
    const { from } = this.editor.state.selection

    const rect = this.editor.view.coordsAtPos(from)
    const fakeElement = { getBoundingClientRect: () => rect }

    const previousUrl = this.editor.getAttributes('link').href

    this.linkTooltip.show({
      url: previousUrl,
      targetElement: fakeElement,
      onSave: (url) => {
        this.editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run()
      },
      onRemove: previousUrl
        ? () => { this.editor.chain().focus().extendMarkRange('link').unsetLink().run() }
        : null
    })
  }

  insertVariable (variable) {
    this.editor.chain().focus().insertContent(`{${variable}}`).run()
  }

  disconnectedCallback () {
    this.linkTooltip.hide()

    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
  }
})
