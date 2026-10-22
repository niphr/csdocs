# Copy the vignettes folder to `articles/` and render each `.Rmd` file

Warns for each `.qmd` file, which stays unrendered.

## Usage

``` r
.render_articles(package, output_dir)
```

## Arguments

- package:

  Path to a package source directory.

- output_dir:

  Target directory of the site.

## Value

A character vector of article titles, named by the relative path of the
`.md` file from `output_dir`.
