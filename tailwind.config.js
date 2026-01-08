module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        flodoc: {
          'color-scheme': 'light',
          primary: '#925FF0',        // Brand purple
          secondary: '#A3FDA1',      // Accent green
          accent: '#35A7FF',        // Complementary blue
          neutral: '#0B0B0B',       // Very dark gray/black
          'base-100': '#FFFFFF',    // White background
          'base-200': '#F8F8F8',    // Light gray
          'base-300': '#E8E8E8',    // Medium gray
          'base-content': '#0B0B0B', // Dark text
          info: '#35A7FF',          // Blue
          success: '#A3FDA1',       // Green
          warning: '#FFE74C',       // Yellow
          error: '#FF5964',         // Red/Pink
          '--rounded-btn': '0.75rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
