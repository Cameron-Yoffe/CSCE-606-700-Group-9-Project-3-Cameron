// config/tailwind.config.js
module.exports = {
  content: [
    "./app/views/**/*.{erb,html,haml,slim}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/assets/stylesheets/**/*.css",
    "./app/components/**/*.{rb,erb,html}",
    "./config/initializers/**/*.rb",
  ],

  // If you generate any classes dynamically (bg-#{color}-500, etc), safelist patterns here:
  safelist: [
    // common dynamic color utilities
    { pattern: /(bg|text|border|ring)-(slate|gray|zinc|neutral|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900)/ },
    // if you do responsive/dark variants dynamically
    { pattern: /(sm|md|lg|xl|2xl):.*/ },
    { pattern: /dark:.*/ },
  ],
};
