# Park Ridge Place Catalog

`park-ridge-places.json` is the hosted catalog consumed by the iOS app through
the `TOWN_PLACE_CATALOG_URL` build setting.

## Publishing

The scheduled GitHub Actions workflow in
`ChrisJDiMarco/park-ridge-connect-catalog` refreshes this JSON daily from
OpenStreetMap/Overpass and commits a new copy only when the catalog changes.
GitHub Pages publishes that public repo's `docs/` folder.

Because the repository is private, do not use a `raw.githubusercontent.com`
URL for App Review unless the repository is made public. Use one of these
public HTTPS options instead:

- GitHub Pages serving the uploaded `Docs/` artifact.
- A public static object URL such as Cloudflare R2, S3, Netlify, Vercel, or a
  borough-owned static host.

For GitHub Pages from the uploaded `Docs/` artifact, the app build setting
should be:

```text
TOWN_PLACE_CATALOG_URL=https://chrisjdimarco.github.io/park-ridge-connect-catalog/place-directory/park-ridge-places.json
```

Current production URL checked on 2026-06-16:

```text
https://chrisjdimarco.github.io/park-ridge-connect-catalog/place-directory/park-ridge-places.json
```

It is hosted from the public `ChrisJDiMarco/park-ridge-connect-catalog`
repository so the app source can remain private while App Review can load the
catalog without authentication.

Before submitting to App Review, open the final URL in a private/incognito
browser and confirm it returns this JSON without authentication.

## Data license

Place data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under the [Open Database License (ODbL 1.0)](https://opendatacommons.org/licenses/odbl/1-0/). Supplemental records in `park-ridge-supplemental-places.json` were curated by Chris DiMarco. Any code license added to this repository does not cover this folder's data.
