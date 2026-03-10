/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./templates/**/*.html",
    "./apps/**/templates/**/*.html",
    "./static/css/input.css"
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#0d6efd',
          light: '#0b5ed7',
          dark: '#0a4ba0'
        }
      }
    },
  },
  plugins: [],
}