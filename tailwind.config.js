module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
	winter: {
          ...require("daisyui/src/theming/themes")["winter"],
	  "base-100": "#010066",
	  "base-200": "#010177",
	  "base-300": "#010277",
	},
        docuseal: {
          'color-scheme': 'light',
          primary: '#e4e0e1',
          secondary: '#ef9fbc',
          accent: '#eeaf3a',
          neutral: '#291334',
          'base-100': '#faf7f5',
          'base-200': '#efeae6',
          'base-300': '#e7e2df',
          'base-content': '#291334',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
