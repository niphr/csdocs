# Read the Rd documentation of a package, installed or in development

Dispatches based on
[`.is_source_path()`](https://niphr.github.io/csdocs/reference/dot-is_source_path.md):
an installed package name goes through
[`.read_rd_db_installed()`](https://niphr.github.io/csdocs/reference/dot-read_rd_db_installed.md),
while a path to a local package source directory goes through
[`.read_rd_db_source()`](https://niphr.github.io/csdocs/reference/dot-read_rd_db_source.md).

## Usage

``` r
.read_rd_db(package)
```

## Arguments

- package:

  Name of an installed package, or a path to a local package source
  directory (detected via a `DESCRIPTION` file at that path).

## Value

A named list of `Rd` objects (one entry per documented topic).
