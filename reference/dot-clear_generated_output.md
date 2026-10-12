# Remove every `.md` file already in `output_dir`

Called before (re-)writing a build's output when `overwrite = TRUE`, so
that a topic renamed or removed from the package since the last build
doesn't leave a stale, orphaned `.md` file behind - without this, the
directory only ever grows and drifts from what the current package
actually documents.

## Usage

``` r
.clear_generated_output(output_dir)
```

## Arguments

- output_dir:

  Target directory.

## Value

`NULL`, invisibly.
