module.exports = {
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        cupcake: {
          ...require('daisyui/src/colors/themes')['[data-theme=cupcake]'],
          primary: '#E4E0E1'
        }
      }
    ]
  }
}
