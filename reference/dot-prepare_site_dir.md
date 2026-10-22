# Check or clear the output folder of a site

Check or clear the output folder of a site

## Usage

``` r
.prepare_site_dir(output_dir, overwrite)
```

## Arguments

- output_dir:

  Target directory. It MUST exist.

- overwrite:

  As passed to
  [`build_site()`](https://niphr.github.io/csdocs/reference/build_site.md).

## Value

`NULL`, invisibly. Aborts via
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html) if
needed.
