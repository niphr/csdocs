# Extract the `\\usage{}` block as preformatted code

Uses
[`.rd_to_raw_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_raw_text.md)
(Tier 1), not
[`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md) -
usage is R code, so exact spacing/indentation (e.g. across multi-line
signatures) must be preserved verbatim rather than collapsed.

## Usage

``` r
.parse_rd_usage(rd)
```

## Arguments

- rd:

  An `Rd` object.

## Value

String with the usage code (no backtick fence).
