# Abort when vignettes need rendering and rmarkdown or knitr is missing

Abort when vignettes need rendering and rmarkdown or knitr is missing

## Usage

``` r
.check_render_packages(rmd)
```

## Arguments

- rmd:

  File names of the `.Rmd` vignettes.

## Value

`NULL`, invisibly. Aborts via
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html) if
needed.
