// The prefix setting seems to have no effect on the generated CSS classes.
module.exports = {
  prefix: 'tw',
  content: [
    './app/components/**/*.{rb,html,erb}',
    './app/views/**/*.{html,erb}',
   './app/views/**/*',
   './app/helpers/**/*.rb',
   './app/javascript/**/*.js',
   './app/components/**/*.{erb,html,rb}'
  ],
  theme: {
    extend: {
      colors: {
        lucasblue: '#007acc',
      },
    },
  },
  plugins: [],
}
