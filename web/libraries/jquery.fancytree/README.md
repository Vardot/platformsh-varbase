# Fancytree — as a Drupal library

This repository packages the **distribution build** of
[Fancytree](https://github.com/mar10/fancytree) by Martin Wendt as a Composer
`drupal-library`, so that a Drupal site can install it with Composer instead of copying
files out of `node_modules`.

`drupal/taxonomy_manager` suggests a `fancytree/fancytree` package, but no such package
exists on Packagist — which is why this one does.

Only the upstream `dist/` tree is shipped: the built scripts, the extension modules and
every skin.

## Installation

```bash
composer require vardot/jquery.fancytree
```

With `composer/installers` and the usual Drupal `installer-paths`, the files land at:

```
web/libraries/jquery.fancytree/dist/jquery.fancytree.min.js
web/libraries/jquery.fancytree/dist/modules/jquery.fancytree.persist.js
web/libraries/jquery.fancytree/dist/skin-lion/ui.fancytree.min.css
```

which is where `drupal/taxonomy_manager` expects them.

## Versioning

Tags follow the upstream Fancytree release they are built from. `2.38.5` here is the
distribution build of [mar10/fancytree v2.38.5](https://github.com/mar10/fancytree).

## Upstream

- Source: https://github.com/mar10/fancytree
- Documentation: https://wwwendt.de/tech/fancytree/doc/jsdoc/
- Licence: MIT (see [LICENSE.txt](LICENSE.txt)) — © Martin Wendt

## Maintainers

- [Vardot](https://github.com/vardot)
