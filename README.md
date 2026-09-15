# GG Survey

Offline site survey app for GG Glass & Glazing field engineers. One self
contained HTML file, no build step required to use it.

## Run it

```bash
npm install
npm run dev
```

## Deploy

`npm run build` outputs to `dist/`. Publish that folder.

## Editing the survey

Every question lives in the `SECTIONS` array near the top of the script in
`index.html`. Change that array and the form, the review screen, the PDF and
the CSV export all follow. Nothing else needs touching.

Engineer names are in `SURVEYORS`. Office email recipients are in
`OFFICE_EMAILS`. Both are near the top of the same script.
