# Park Ridge Place Catalog

`park-ridge-places.json` is the hosted catalog consumed by the iOS app through
the `TOWN_PLACE_CATALOG_URL` build setting.

## Publishing

The scheduled GitHub Actions workflow refreshes this JSON daily from
OpenStreetMap/Overpass and commits a new copy only when the catalog changes.
The Pages deployment workflow publishes only the place catalog files into a
small `_site` artifact when Pages is enabled for the repository.

Because the repository is private, do not use a `raw.githubusercontent.com`
URL for App Review unless the repository is made public. Use one of these
public HTTPS options instead:

- GitHub Pages serving the uploaded `Docs/` artifact.
- A public static object URL such as Cloudflare R2, S3, Netlify, Vercel, or a
  borough-owned static host.

For GitHub Pages from the uploaded `Docs/` artifact, the app build setting
should be:

```text
TOWN_PLACE_CATALOG_URL=https://chrisjdimarco.github.io/park-ridge-connect/place-directory/park-ridge-places.json
```

Current remote status checked on 2026-06-16: GitHub Pages is not enabled for
`ChrisJDiMarco/park-ridge-connect` (`GET /repos/.../pages` returned 404).
Enable Pages with GitHub Actions as the source, or publish this JSON to another
public static host.

Before submitting to App Review, open the final URL in a private/incognito
browser and confirm it returns this JSON without authentication.
