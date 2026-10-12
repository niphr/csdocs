# Flatten an Rd fragment to raw, unnormalized text

Like
[`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md),
but performs **no** whitespace normalization (beyond the
[`.leaf_rd_text()`](https://niphr.github.io/csdocs/reference/dot-leaf_rd_text.md)
`USERMACRO` handling) and applies no inline Markdown formatting. This is
"Tier 1" of csdocs's text extraction: use it for code content
(`\\usage{}`, `\\examples{}`, `\\preformatted{}`) where exact spacing
and indentation must survive verbatim. Callers should
[`trimws()`](https://rdrr.io/r/base/trimws.html) the result themselves
to drop leading/trailing edges without touching internal formatting.

## Usage

``` r
.rd_to_raw_text(rd)
```

## Arguments

- rd:

  An Rd fragment or a list of Rd fragments.

## Value

A single string with internal whitespace untouched.

## Details

Also special-cases `\\method{generic}{class}` the same way
[`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md)
does (rendered as `generic.class`) - `\\usage{}` is the main place this
construct appears, and it's Tier 1 content.
