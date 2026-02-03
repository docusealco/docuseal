module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'dark',
          primary: '#e4e0e1',
          secondary: '#ef9fbc',
          accent: '#93bec7',
          neutral: '#1a1a1a',
          'base-100': '#1a1a1a',
          'base-200': '#ededde',
          'base-300': '#ededde',
          'base-content': '#ededde',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
