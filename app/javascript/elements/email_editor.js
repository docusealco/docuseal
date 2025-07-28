import { target, targetable } from '@github/catalyst/lib/targetable'

let loaderPromise = null

function loadCodeMirror () {
  if (!loaderPromise) {
    loaderPromise = Promise.all([
      import(/* webpackChunkName: "email-editor" */ '@codemirror/view'),
      import(/* webpackChunkName: "email-editor" */ '@codemirror/commands'),
      import(/* webpackChunkName: "email-editor" */ '@codemirror/language'),
      import(/* webpackChunkName: "email-editor" */ '@codemirror/lang-html'),
      import(/* webpackChunkName: "email-editor" */ '@specious/htmlflow')
    ]).then(([view, commands, language, html, htmlflow]) => {
      return {
        minimalSetup: [
          commands.history(),
          language.syntaxHighlighting(language.defaultHighlightStyle, { fallback: true }),
          view.keymap.of([...commands.defaultKeymap, ...commands.historyKeymap])
        ],
        EditorView: view.EditorView,
        html: html.html,
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

    const { EditorView, minimalSetup, html, htmlflow } = await loadCodeMirror()

    this.editorView = new EditorView({
      doc: this.input.value,
      parent: this.editorContainer,
      extensions: [
        html(),
        minimalSetup,
        EditorView.lineWrapping,
        EditorView.updateListener.of(update => {
          if (update.docChanged) this.input.value = update.state.doc.toString()
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
