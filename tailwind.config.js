module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif']
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-out',
        'fade-in-up': 'fadeInUp 0.25s ease-out'
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(4px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        }
      },
      boxShadow: {
        'soft': '0 2px 8px rgba(38, 56, 84, 0.06)',
        'soft-lg': '0 4px 16px rgba(38, 56, 84, 0.08)',
        'soft-xl': '0 8px 24px rgba(38, 56, 84, 0.1)',
        'focus-ring': '0 0 0 3px rgba(31, 224, 179, 0.25)',
        'focus-ring-neutral': '0 0 0 3px rgba(38, 56, 84, 0.15)'
      }
    }
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#1FE0B3',
          'primary-content': '#263854',
          secondary: '#54B0E8',
          'secondary-content': '#FFFFFF',
          accent: '#4E87C8',
          'accent-content': '#FFFFFF',
          neutral: '#263854',
          'neutral-content': '#FFFFFF',
          'base-100': '#FFFFFF',
          'base-200': '#f0f4f8',
          'base-300': '#e2e8f0',
          'base-content': '#263854',
          info: '#54B0E8',
          'info-content': '#FFFFFF',
          '--rounded-btn': '0.5rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem',
          '--rounded-box': '0.75rem'
        }
      }
    ]
  }
}
