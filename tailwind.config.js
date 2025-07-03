module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#004FCC',
          link: '#004FCC',
          secondary: '#ef9fbc',
          accent: '#eeaf3a',
          neutral: '#291334',
          'base-100': '#f2f2f3',
          'base-200': '#efeae6',
          'base-300': '#e7e2df',
          'base-content': 'rgb(73, 75, 80)',
          'font-size': '16px',
          '--rounded-btn': '4px',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
