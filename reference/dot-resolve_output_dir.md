# Resolve `output_dir`, applying the source-package-only default

`"md-docs"` is a reasonable default location next to a package's own
source (the common `build_reference(".")` workflow), but there's no
similarly obvious spot for an installed package's output - defaulting
there too could scatter generated docs into an unexpected/unwanted
location relative to whatever directory the user happened to be in. So
the default only applies when `package` resolves to a local source
directory; otherwise a missing `output_dir` is a clear, actionable error
rather than a surprising write location.

## Usage

``` r
.resolve_output_dir(package, output_dir)
```

## Arguments

- package:

  As passed to
  [`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md).

- output_dir:

  As passed to
  [`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md) -
  `NULL` if the caller didn't supply one.

## Value

The resolved `output_dir` string.
