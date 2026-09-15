import { defineConfig } from 'vite';

/**
 * The app is one self contained file. There is nothing to bundle and nothing
 * to split, so this config only exists to give Bolt a dev server and a build
 * step it recognises. `vite build` copies index.html into dist/ untouched.
 */
export default defineConfig({
  server: { host: true },
  build: { assetsInlineLimit: 0, cssCodeSplit: false },
});
