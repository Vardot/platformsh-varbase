# Dropzone — laid out for Drupal, as a Drupal library

This repository packages the **distribution build** of
[Dropzone](https://github.com/dropzone/dropzone) as a Composer `drupal-library`, laid out under
the filenames `drupal/dropzonejs` actually declares, so that a Drupal site can install it with
Composer instead of copying files out of `node_modules` or extracting a zip by hand.

## Why the layout is repacked

`dropzonejs.libraries.yml` in `drupal/dropzonejs` loads:

```
/libraries/dropzone/dropzone-min.js   { minified: true }
/libraries/dropzone/dropzone.css      { minified: true }
```

**No Dropzone 5 release ships those filenames.** Upstream v5 `dist.zip` gives
`dist/min/dropzone.min.js` and `dist/min/dropzone.min.css`; the flat `dropzone-min.js` naming only
appeared in the Dropzone 6 line, which has not left beta since 2021. So neither an npm copy of
`dropzone@5` nor the upstream v5 zip satisfies the module.

This package resolves that by shipping the **stable 5.9.3 minified build under the names the module
declares**, at the root of the library directory:

| File here | Built from upstream 5.9.3 |
|---|---|
| `dropzone-min.js` | `dist/min/dropzone.min.js` |
| `dropzone.css` | `dist/min/dropzone.min.css` |
| `basic.css` | `dist/min/basic.min.css` |
| `dropzone-amd-module.js` | `dist/min/dropzone-amd-module.min.js` |
| `dropzone.js` | `dist/dropzone.js` (unminified, for debugging) |

Both files the module loads are declared `minified: true`, so serving the minified builds under
those names is what it expects.

## Installation

```bash
composer require vardot/dropzone
```

With `composer/installers` and the usual Drupal `installer-paths`, the files land at
`web/libraries/dropzone/`, which is where `drupal/dropzonejs` looks.

## Versioning

Tags follow the upstream Dropzone release they are built from. `5.9.3` here is the distribution
build of [dropzone/dropzone v5.9.3](https://github.com/dropzone/dropzone/releases/tag/v5.9.3).

The `5.x` branch and the `5.9.3` tag onward carry this layout. Tags up to `v5.1.1`, and the
`master` branch, are the original 2017 full fork and are left untouched.

## Upstream

- Source: https://github.com/dropzone/dropzone
- Documentation: https://docs.dropzone.dev/
- Licence: MIT (see [LICENSE](LICENSE)) — © Matias Meno

## Maintainers

- [Vardot](https://github.com/vardot)
