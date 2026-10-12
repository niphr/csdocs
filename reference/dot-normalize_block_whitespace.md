# Collapse a block of prose to paragraphs, preserving paragraph breaks

Rd source hard-wraps prose at some column width for source readability
(see
[`.collapse_whitespace()`](https://niphr.github.io/csdocs/reference/dot-collapse_whitespace.md)
for the single-line equivalent used in table cells) - those line breaks
aren't semantically meaningful and are joined back into flowing text. A
blank line in the source (2+ consecutive newlines), however, *is* a
meaningful paragraph break and is preserved as exactly one blank line.

## Usage

``` r
.normalize_block_whitespace(text)
```

## Arguments

- text:

  A string, typically already passed through
  [`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md).

## Value

`text` with hard-wrapped single newlines joined into spaces and
paragraph breaks normalized to a single blank line, trimmed.
