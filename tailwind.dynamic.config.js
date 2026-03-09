const path = require('path')

module.exports = {
  content: [
    path.resolve(__dirname, 'app/javascript/template_builder/dynamic_area.vue'),
    path.resolve(__dirname, 'app/javascript/template_builder/dynamic_section.vue')
  ],
  theme: {
    extend: {
      colors: {
        'base-100': '#faf7f5',
        'base-200': '#efeae6',
        'base-300': '#e7e2df',
        'base-content': '#291334'
      }
    }
  }
}
