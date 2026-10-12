# Determine a source package's exported names from its `NAMESPACE` file

Parses explicit `export(name)` directives (line-per-symbol, the
convention `roxygen2::document()` writes) rather than loading the
package - a dev package is often not in a loadable state. Doesn't
resolve `exportPattern()` regexes (rare in roxygen2-generated
`NAMESPACE` files; common only in hand-written classic ones) - a topic
exported only via such a pattern would be misflagged as private, a
known, minor limitation.

## Usage

``` r
.read_exported_names_source(path)
```

## Arguments

- path:

  Path to a local package source directory.

## Value

Character vector of exported names, or `NULL` if no `NAMESPACE` file
exists yet (e.g. a dev package that has never run
[`devtools::document()`](https://devtools.r-lib.org/reference/document.html)) -
export status is simply unknown then, not "nothing is exported".
