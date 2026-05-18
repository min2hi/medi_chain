// postcss.config.mjs
// TailwindCSS v3: plugin key is "tailwindcss"
// TailwindCSS v4: plugin key is "@tailwindcss/postcss"
// We pin tailwindcss@^3.x in package.json, so use v3 config.
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};

export default config;
