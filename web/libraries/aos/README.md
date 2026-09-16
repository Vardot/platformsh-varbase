# AOS — Animate On Scroll, as a Drupal library

This repository packages the **distribution build** of
[AOS (Animate On Scroll)](https://github.com/michalsnik/aos) by Michał Sajnóg as a
Composer `drupal-library`, so that a Drupal site can install it with Composer instead of
copying files out of `node_modules`.

Only the files Drupal actually serves are shipped: `aos.css` and `aos.js`.

## Installation

```bash
composer require vardot/aos
```

With `composer/installers` and the usual Drupal `installer-paths`, the files land at:

```
web/libraries/aos/aos.css
web/libraries/aos/aos.js
```

which is where `drupal/varbase_components` expects them.

## Versioning

Tags follow the upstream AOS release they are built from. `2.3.4` here is the
distribution build of [michalsnik/aos v2.3.4](https://github.com/michalsnik/aos).

## Upstream

- Source: https://github.com/michalsnik/aos
- Documentation: https://michalsnik.github.io/aos/
- Licence: MIT (see [LICENSE](LICENSE)) — © 2015 Michał Sajnóg

## Maintainers

- [Vardot](https://github.com/vardot)
