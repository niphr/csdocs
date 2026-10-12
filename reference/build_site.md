# Build a Markdown site for a source package

Writes the reference, every R Markdown vignette and a front page as
Markdown files that read as linked pages on github.com. The output has
this layout:

- `README.md`: the front page. It shows the package name, the version,
  the source commit when known, a list of articles and a link to the
  reference.

- `reference/`: the output of
  [`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md).

- `articles/`: one `<name>.md` file for each `vignettes/*.Rmd` file,
  with its figures in a folder beside it.

## Usage

``` r
build_site(package = ".", output_dir, overwrite = TRUE)
```

## Arguments

- package:

  Path to a package source directory, which MUST contain a `DESCRIPTION`
  file. An installed package name is an error, because an installed
  package has no vignette sources.

- output_dir:

  Target directory. Created if it does not exist.

- overwrite:

  If `TRUE` (the default), `build_site()` deletes the `README.md` file
  and the `reference/` and `articles/` folders in `output_dir` before it
  writes the new set. If `FALSE`, it aborts when `output_dir` contains
  any file or folder.

## Value

Invisibly, the path to `output_dir`.

## Details

`build_site()` copies the whole `vignettes/` folder to `articles/`, so
images and other assets stay beside the articles. It renders each `.Rmd`
file there with `rmarkdown::github_document(html_preview = FALSE)`, in a
new environment whose parent is the global environment. Then it deletes
the copied `.Rmd` files and any `.Rmd.orig` files.

The front page lists each article under the `title` field of its YAML
header, or under its file name when the header has no title. The commit
comes from the `GITHUB_SHA` environment variable, else from
`git rev-parse HEAD` in `package`. The front page shows its first 7
characters. When neither source gives a commit, the front page omits it.

Install the package before you call `build_site()` when a vignette calls
[`library()`](https://rdrr.io/r/base/library.html) on it. The vignettes
run against the installed version, and the reference reads the source.

`build_site()` does not render Quarto (`.qmd`) vignettes. It copies them
unrendered and gives a warning that names each one.

## Examples

``` r
if (FALSE) { # \dontrun{
csdocs::build_site(".", output_dir = "docs-build")
} # }
```
