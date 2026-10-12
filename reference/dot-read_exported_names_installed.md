# Determine an installed package's exported names via its namespace

[`getNamespaceExports()`](https://rdrr.io/r/base/ns-reflect.html) is the
only fully correct way to get this list - it's what R itself resolves
`export()`/`exportPattern()`/etc. down to, so hand-parsing the
`NAMESPACE` file here would mean reimplementing that resolution
(including regex `exportPattern()` matching against the namespace's
actual contents). The cost is that it loads the package's namespace if
not already loaded - unlike
[`.read_rd_db_installed()`](https://niphr.github.io/csdocs/reference/dot-read_rd_db_installed.md)'s
existence check, this is unavoidable here since the actual export list
can only come from the loaded namespace itself. Wrapped in
[`tryCatch()`](https://rdrr.io/r/base/conditions.html) so a package that
fails to load degrades to "unknown" (`NULL`) rather than aborting the
whole reference build - `include_private` simply has nothing to filter
on in that case, same as before this feature existed.

## Usage

``` r
.read_exported_names_installed(package)
```

## Arguments

- package:

  Name of an installed package.

## Value

Character vector of exported names, or `NULL` if the namespace couldn't
be loaded.
