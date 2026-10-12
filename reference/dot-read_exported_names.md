# Determine a package's exported names, for flagging private topics

Dispatches based on
[`.is_source_path()`](https://niphr.github.io/csdocs/reference/dot-is_source_path.md),
mirroring
[`.read_rd_db()`](https://niphr.github.io/csdocs/reference/dot-read_rd_db.md).

## Usage

``` r
.read_exported_names(package)
```

## Arguments

- package:

  Name of an installed package, or a path to a local package source
  directory.

## Value

Character vector of exported names, or `NULL` if export status couldn't
be determined (see the installed/source variants for when that
happens) - callers should treat `NULL` as "unknown", not as "no
exports".
