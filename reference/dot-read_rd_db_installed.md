# Read the Rd database of an installed package

Thin wrapper around
[`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html) that checks the
package is actually installed first and raises a helpful error
otherwise.

## Usage

``` r
.read_rd_db_installed(package)
```

## Arguments

- package:

  Name of an installed package, e.g. `"dplyr"`.

## Value

A named list of `Rd` objects, as returned by
[`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html).
