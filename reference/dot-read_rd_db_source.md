# Read the Rd documentation of a package straight from its source tree

Used for development packages that have not been installed. Reads every
`man/*.Rd` file in `path` via
[`tools::parse_Rd()`](https://rdrr.io/r/tools/parse_Rd.html). If `man/`
is missing or empty, falls back to a live, in-memory parse via
`roxygen2::parse_package(path)` — only attempted if the `roxygen2`
namespace is available; otherwise raises an error pointing the user at
[`devtools::document()`](https://devtools.r-lib.org/reference/document.html).

## Usage

``` r
.read_rd_db_source(path)
```

## Arguments

- path:

  Path to a local package source directory (contains a `DESCRIPTION`
  file).

## Value

A named list of `Rd` objects, in the same shape as
[`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html) would return
for an installed package.
