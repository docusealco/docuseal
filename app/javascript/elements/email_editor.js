import { target, targetable } from '@github/catalyst/lib/targetable'

let loaderPromise = null

function loadCodeMirror () {
  if (!loaderPromise) {
    loaderPromise = Promise.all([
      import(/* webpackChunkName: "email-editor" */ '@codemirror/view'),
      import(/* webpackChunkName: "email-editor" */ '@codemirror/commands'),
      import(/* webpackChunkName: "email-editor" */ '@codemirror/language'),
      import(/* webpackChunkName: "email-editor" */ '@codemirror/lang-html'),
      import(/* webpackChunkName: "email-editor" */ '@codemirror/lint'),
      import(/* webpackChunkName: "email-editor" */ '@specious/htmlflow')
    ]).then(([view, commands, language, html, lint, htmlflow]) => {
      return {
        minimalSetup: [
          commands.history(),
          language.syntaxHighlighting(language.defaultHighlightStyle, { fallback: true }),
          view.keymap.of([...commands.defaultKeymap, ...commands.historyKeymap])
        ],
        EditorView: view.EditorView,
        html: html.html,
        htmlLanguage: html.htmlLanguage,
        linter: lint.linter,
        htmlflow: htmlflow.default || htmlflow
      }
    })
  }

  return loaderPromise
}

export default targetable(class extends HTMLElement {
  static [target.static] = [
    'codeViewTab',
    'previewViewTab',
    'editorContainer',
    'previewIframe'
  ]

  connectedCallback () {
    this.mount()

    if (this.input.value) {
      this.showPreviewView()
    } else {
      this.showCodeView()
    }

    this.previewViewTab.addEventListener('click', this.showPreviewView)
    this.codeViewTab.addEventListener('click', this.showCodeView)

    this.form = this.closest('form')
    this.form?.addEventListener('submit', this.validateOnSubmit)
  }

  disconnectedCallback () {
    this.form?.removeEventListener('submit', this.validateOnSubmit)
  }

  validateOnSubmit = (e) => {
    if (!this.htmlLanguage) return

    const bodyType = this.form.querySelector('input[name$="[body_type]"]:checked')?.value

    if (bodyType && bodyType !== 'html') return

    const diagnostics = this.buildDiagnostics(this.input.value)

    if (diagnostics.length === 0) return

    e.preventDefault()

    this.showCodeView()

    const pos = Math.min(diagnostics[0].from, this.editorView.state.doc.length)

    this.editorView.dispatch({ selection: { anchor: pos }, scrollIntoView: true })
    this.editorView.focus()

    alert(diagnostics[0].message)
  }

  buildDiagnostics (value) {
    const diagnostics = []

    if (!value.trim()) return diagnostics

    if (!/^\s*(<!doctype[^>]*>\s*)?<html/i.test(value)) {
      diagnostics.push({
        from: 0,
        to: Math.min(5, value.length),
        severity: 'error',
        message: 'The email template must start with the <html> tag'
      })
    }

    const seen = new Set()

    this.htmlLanguage.parser.parse(value).iterate({
      enter: (node) => {
        if (!node.type.isError || seen.has(node.from) || seen.size >= 20) return

        seen.add(node.from)

        diagnostics.push({
          from: node.from,
          to: Math.min(node.to + 1, value.length),
          severity: 'error',
          message: 'The email template contains invalid HTML'
        })
      }
    })

    return diagnostics
  }

  showCodeView = () => {
    this.editorView.dispatch({
      changes: { from: 0, to: this.editorView.state.doc.length, insert: this.input.value }
    })

    this.previewViewTab.classList.remove('tab-active', 'tab-bordered')
    this.previewViewTab.classList.add('pb-[3px]')
    this.codeViewTab.classList.remove('pb-[3px]')
    this.codeViewTab.classList.add('tab-active', 'tab-bordered')
    this.editorContainer.classList.remove('hidden')
    this.previewIframe.classList.add('hidden')
  }

  showPreviewView = () => {
    this.previewIframe.srcdoc = this.input.value

    this.codeViewTab.classList.remove('tab-active', 'tab-bordered')
    this.codeViewTab.classList.add('pb-[3px]')
    this.previewViewTab.classList.remove('pb-[3px]')
    this.previewViewTab.classList.add('tab-active', 'tab-bordered')
    this.editorContainer.classList.add('hidden')
    this.previewIframe.classList.remove('hidden')
  }

  async mount () {
    this.input = this.querySelector('input[type="hidden"]')
    this.input.style.display = 'none'

    const { EditorView, minimalSetup, html, htmlLanguage, linter, htmlflow } = await loadCodeMirror()

    this.htmlLanguage = htmlLanguage

    this.editorView = new EditorView({
      doc: this.input.value,
      parent: this.editorContainer,
      extensions: [
        html(),
        minimalSetup,
        EditorView.lineWrapping,
        linter((view) => this.buildDiagnostics(view.state.doc.toString()), { delay: 600 }),
        EditorView.updateListener.of(update => {
          if (update.docChanged) {
            this.input.value = update.state.doc.toString()
          }
        }),
        EditorView.theme({
          '&': {
            backgroundColor: 'white',
            color: 'black',
            fontSize: '14px',
            fontFamily: 'monospace'
          },
          '&.cm-focused': {
            outline: 'none'
          },
          '&.cm-editor': {
            borderRadius: '0.375rem',
            border: 'none'
          },
          '.cm-gutters': {
            display: 'none'
          }
        })
      ]
    })

    this.previewIframe.srcdoc = this.editorView.state.doc.toString()

    this.previewIframe.onload = () => {
      const previewIframeDoc = this.previewIframe.contentDocument

      if (previewIframeDoc.body) {
        previewIframeDoc.body.contentEditable = true
      }

      const contentDocument = this.previewIframe.contentDocument || this.previewIframe.contentWindow.document

      contentDocument.body.addEventListener('input', async () => {
        const html = contentDocument.documentElement.outerHTML.replace(' contenteditable="true"', '')
        const prettifiedHtml = await htmlflow(html)

        this.input.value = prettifiedHtml
      })
    }
  }
})
