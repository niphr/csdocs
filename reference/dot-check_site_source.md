# Abort unless `package` is a package source directory

Abort unless `package` is a package source directory

## Usage

``` r
.check_site_source(package)
```

## Arguments

- package:

  As passed to
  [`build_site()`](https://niphr.github.io/csdocs/reference/build_site.md).

## Value

`NULL`, invisibly. Aborts via
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html) if
needed.
