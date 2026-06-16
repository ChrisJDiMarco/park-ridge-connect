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
