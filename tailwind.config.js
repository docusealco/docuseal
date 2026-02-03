module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'dark',
          primary: '#8fb6ba',
          secondary: '#97b0b4',
          accent: '#8fb6ba',
          neutral: '#2a2a2a',
          'neutral-content': '#ededde',
          'base-100': '#1a1a1a',
          'base-200': '#252525',
          'base-300': '#333333',
          'base-content': '#ededde',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
