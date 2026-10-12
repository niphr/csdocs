# Abort if `output_dir` already contains `.md` files

Abort if `output_dir` already contains `.md` files

## Usage

``` r
.check_existing_output(output_dir, overwrite)
```

## Arguments

- output_dir:

  Target directory.

- overwrite:

  Whether existing files may be overwritten.

## Value

`NULL`, invisibly. Aborts via
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html) if
needed.
