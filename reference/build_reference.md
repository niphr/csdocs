# Generate Markdown reference documentation for a package

Reads the Rd documentation of a package - either installed, or a local
development package that has not been installed - renders it as
Markdown, and writes one `.md` file per function into `output_dir`. Also
produces a `README.md` (index table of all functions) and a
`_full_reference.md` (every function in one file, meant to be injected
as LLM context, e.g. via `@docs/reference/_full_reference.md` in Claude
Code).

## Usage

``` r
build_reference(
  package = ".",
  output_dir = NULL,
  overwrite = TRUE,
  include_private = TRUE
)
```

## Arguments

- package:

  Name of an installed package, or a path to a local package source
  directory. Defaults to `"."` - the common case of running
  `build_reference()` from within the package you're documenting.

- output_dir:

  Target directory for the generated `.md` files. Created if it does not
  exist. Defaults to `"md-docs"`, but only when `package` resolves to a
  local source directory - for an installed package (e.g. `"dplyr"`)
  there's no similarly obvious default location, so `output_dir` must be
  given explicitly.

- overwrite:

  If `TRUE` (the default), any `.md` files already in `output_dir` are
  removed before writing the new set - this also clears stale files left
  behind by topics that were since renamed or removed from the package.
  If `FALSE`, aborts instead when `output_dir` already contains `.md`
  files, without touching them.

- include_private:

  If `TRUE` (the default), documented topics that aren't part of the
  package's public API (i.e. not in its `NAMESPACE` exports - typically
  internal helpers documented with `@keywords internal` rather than
  `@export`) are included and marked `_(private)_` next to their
  heading, in both the topic file and the index. If `FALSE`, such topics
  are left out of the output entirely. Datasets and other non-callable
  topics are never treated as private, even though they also aren't in
  `NAMESPACE`'s exports - see
  [`.compute_is_private()`](https://niphr.github.io/csdocs/reference/dot-compute_is_private.md).
  When export status can't be determined at all (a dev package that has
  never run
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html),
  so it has no `NAMESPACE` file yet), every topic is treated as public.

## Value

Invisibly, the path to `output_dir`.

## Details

`package` accepts two kinds of input:

- the name of an installed package, e.g. `"dplyr"` - Rd data is read via
  [`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html);

- a path to a local package source directory, e.g. `"."` or
  `"../myotherpkg"` (detected by the presence of a `DESCRIPTION` file at
  that path) - Rd data is read directly from `man/*.Rd`, falling back to
  a live
  [`roxygen2::parse_package()`](https://roxygen2.r-lib.org/reference/parse_package.html)
  parse if `man/` is missing or empty. This mode does **not** require
  the package to be installed.

## Examples

``` r
if (FALSE) { # \dontrun{
# Installed package:
csdocs::build_reference("dplyr", output_dir = "docs/reference")

# Development package, not installed - "." and "md-docs" are both
# defaults, so this is equivalent to just build_reference():
csdocs::build_reference(".", output_dir = "md-docs")

# Public API only, no internal helpers:
csdocs::build_reference("dplyr", output_dir = "docs/reference", include_private = FALSE)
} # }
```
