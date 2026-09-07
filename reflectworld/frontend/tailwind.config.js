/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        apple: {
          bg: "#F5F5F7",
          sidebar: "#FFFFFF",
          text: "#1D1D1F",
          secondary: "#86868B",
          accent: "#007AFF",
          border: "#E5E5EA",
          hover: "#F0F0F5",
        },
      },
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          "SF Pro Text",
          "Segoe UI",
          "Roboto",
          "sans-serif",
        ],
      },
    },
  },
  plugins: [],
};
