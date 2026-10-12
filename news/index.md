# Changelog

## Version 2026.10.12

- Forked from pkgmd `61e52b1` and renamed to csdocs.
- In a topic file, a `\link` to a topic of the same package is a
  relative link. `@seealso` keeps its lists, and the footer no longer
  links to `../../pkgmd/`.
- The index `README.md` groups topics under the `reference:` sections of
  `_pkgdown.yml`, or by `\concept` when that file is absent. Topics in
  no group go under `## Other`.
