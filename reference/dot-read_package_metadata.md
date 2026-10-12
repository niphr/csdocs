# Resolve package name and version, for either an installed or a source package

For an installed package, name/version come from
[`utils::packageVersion()`](https://rdrr.io/r/utils/packageDescription.html).
For a development package, they are read from the `DESCRIPTION` file in
the source directory via
[`read.dcf()`](https://rdrr.io/r/base/dcf.html) - this deliberately
avoids requiring installation.

## Usage

``` r
.read_package_metadata(package)
```

## Arguments

- package:

  Name of an installed package, or a path to a local package source
  directory.

## Value

A list with fields `name`, `version`.
