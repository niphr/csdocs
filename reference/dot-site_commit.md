# Find the commit that a site is built from

Reads the `GITHUB_SHA` environment variable, else runs
`git -C <package> rev-parse HEAD`. A failure of git gives `NULL`.

## Usage

``` r
.site_commit(package)
```

## Arguments

- package:

  Path to a package source directory.

## Value

The full commit hash, or `NULL` when no source gives one.
