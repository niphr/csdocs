# Read the `reference:` sections of a source package's `_pkgdown.yml`

Returns `NULL` when the index MUST fall back to `\\concept` grouping.
That is the case for an installed package, a source package without
`_pkgdown.yml`, a file without `reference:` sections, and a session
without the `yaml` package.

## Usage

``` r
.read_pkgdown_sections(package)
```

## Arguments

- package:

  Name of an installed package, or a path to a local package source
  directory.

## Value

A list of `list(title, desc, contents)` in declared order, or `NULL`.
