module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#e4e0e1',
          secondary: '#9fcbefff',
          accent: '#eeaf3a',
          neutral: '#291334',
          'base-100': '#ced9ebff',
          'base-200': '#99d3e0ff',
          'base-300': '#87f1c0ff',
          'base-content': '#291334',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
