# Extract the `\\examples{}` block as a code string

Uses
[`.rd_to_raw_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_raw_text.md)
(Tier 1), not
[`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md) -
examples are R code, so exact spacing/indentation must be preserved
verbatim rather than collapsed.

## Usage

``` r
.parse_rd_examples(rd)
```

## Arguments

- rd:

  An `Rd` object.

## Value

String with the example code (no backtick fence), empty if no examples
are present.
