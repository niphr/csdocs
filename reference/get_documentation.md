# Get a package's full reference documentation as a single string

Returns the same Markdown content that
[`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md)
writes to `_full_reference.md` - every topic rendered and concatenated
into one string - without writing anything to disk. Meant for
programmatic consumption, e.g. an LLM agent that wants a package's
complete reference injected directly into its context in one call.

## Usage

``` r
get_documentation(package = ".", include_private = FALSE)
```

## Arguments

- package:

  As in
  [`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md).

- include_private:

  If `TRUE`, documented topics that aren't part of the package's public
  API are included too - see
  [`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md).
  Defaults to `FALSE` here (unlike
  [`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md)'s
  `TRUE`), since the primary use case - handing a package's reference to
  an LLM agent as context - usually wants the public API only.

## Value

A single string: the package's full reference documentation in Markdown.

## Examples

``` r
if (FALSE) { # \dontrun{
# Installed package:
docs <- csdocs::get_documentation("dplyr")

# Development package, not installed:
docs <- csdocs::get_documentation(".")
} # }
```
