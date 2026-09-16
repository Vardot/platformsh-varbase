# Swagger UI — as a Drupal library

This repository packages the **distribution build** of
[Swagger UI](https://github.com/swagger-api/swagger-ui) as a Composer `drupal-library`, so that a
Drupal site gets it in `web/libraries/` with no extra configuration.

Only the upstream `dist/` tree is shipped — the files Drupal actually serves.

## It works out of the box

```bash
composer require vardot/swagger-ui
```

The project needs **nothing added**: with the single generic Drupal installer path every project
already has,

```json
"web/libraries/{$name}": ["type:drupal-library"]
```

the package name puts the files exactly where `drupal/openapi_ui_swagger` looks:

```
web/libraries/swagger-ui/dist/swagger-ui-bundle.js
web/libraries/swagger-ui/dist/swagger-ui-standalone-preset.js
web/libraries/swagger-ui/dist/swagger-ui.css
```

## Why this package exists

`drupal/openapi_ui_swagger` requires `swagger-api/swagger-ui`, which is published as
`type: library` rather than `drupal-library`. `composer/installers` will not place a plain
`library`, so it lands in `vendor/`, where nothing can serve it — and the module's own README works
around that with a second Composer plugin and a per-package installer path.

This package removes both. It declares `type: drupal-library` so the generic rule applies, and:

```json
"replace": { "swagger-api/swagger-ui": "self.version" }
```

so requiring it **satisfies** `drupal/openapi_ui_swagger`'s requirement instead of duplicating it.
The upstream package is then never downloaded, and there is no second copy in `vendor/`.

## Versioning

Tags follow the upstream Swagger UI release they are built from. `5.32.14` here is the
distribution build of
[swagger-api/swagger-ui v5.32.14](https://github.com/swagger-api/swagger-ui/releases/tag/v5.32.14).

Because of the `replace`, the tag must stay a real upstream version: `self.version` means the
replaced constraint is whatever this tag says, and `drupal/openapi_ui_swagger` accepts
`^3.0.17 || ^5.0`.

## Upstream

- Source: https://github.com/swagger-api/swagger-ui
- Documentation: https://swagger.io/tools/swagger-ui/
- Licence: Apache-2.0 (see [LICENSE](LICENSE) and [NOTICE](NOTICE)) — © SmartBear Software

## Maintainers

- [Vardot](https://github.com/vardot)
