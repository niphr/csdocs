# Detect whether `package` refers to a local package source directory

Used to dispatch between the installed-package path
([`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html)) and the
development-package path (reading `man/*.Rd` directly, or falling back
to a live
[`roxygen2::parse_package()`](https://roxygen2.r-lib.org/reference/parse_package.html)
parse). A path is treated as a package source directory if it exists on
disk and contains a `DESCRIPTION` file.

## Usage

``` r
.is_source_path(package)
```

## Arguments

- package:

  Value passed by the caller to
  [`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md) -
  either an installed package name or a path to a package source
  directory.

## Value

`TRUE` if `package` is a local source directory, `FALSE` otherwise (i.e.
it should be treated as an installed package name).
