module.exports = {
  future: {
    hoverOnlyWhenSupported: true
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#2b2f88',
          'primary-content': '#ffffff',
          secondary: '#283284',
          'secondary-content': '#ffffff',
          accent: '#b45309',
          'accent-content': '#ffffff',
          neutral: '#2b2f88',
          'neutral-content': '#ffffff',
          'base-100': '#ffffff',
          'base-200': '#f2f3fa',
          'base-300': '#e3e4f1',
          'base-content': '#20244d',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
