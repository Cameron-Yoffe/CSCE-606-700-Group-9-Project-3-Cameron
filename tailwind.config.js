const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./app/views/**/*.{erb,html}",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.{js,ts}",
    "./app/components/**/*.{erb,rb}"
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#eef2ff",
          100: "#dfe3ff",
          200: "#bcc8ff",
          300: "#93a3ff",
          400: "#6875ff",
          500: "#4c56ff",
          600: "#3a3fea",
          700: "#2c30c1",
          800: "#272c99",
          900: "#242a79",
          950: "#151847"
        },
        accent: {
          50: "#fff7ed",
          100: "#ffead0",
          200: "#ffd2a3",
          300: "#ffb166",
          400: "#ff8a29",
          500: "#ff6a05",
          600: "#e25200",
          700: "#b63f03",
          800: "#8c320a",
          900: "#6f2b0c",
          950: "#3d1504"
        },
        neutral: {
          25: "#f8fafc",
          50: "#f3f4f6",
          100: "#e2e8f0",
          200: "#cbd5f5",
          300: "#94a3b8",
          400: "#64748b",
          500: "#475569",
          600: "#334155",
          700: "#1f2933",
          800: "#0f172a",
          900: "#0b1221"
        }
      },
      fontFamily: {
        sans: ["Inter", ...defaultTheme.fontFamily.sans],
        display: ["Space Grotesk", ...defaultTheme.fontFamily.sans]
      },
      boxShadow: {
        card: "0 20px 45px -20px rgba(15, 23, 42, 0.35)"
      },
      borderRadius: {
        "2xl": "1.25rem"
      }
    }
  }
};
