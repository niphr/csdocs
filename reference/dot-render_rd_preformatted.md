# Render a `\\preformatted{}` node as a fenced Markdown code block

Uses
[`.rd_to_raw_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_raw_text.md)
(Tier 1) rather than
[`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md),
since preformatted content's exact spacing/indentation must be preserved
verbatim. No language tag is added to the fence, since preformatted
content isn't necessarily R code.

## Usage

``` r
.render_rd_preformatted(x)
```

## Arguments

- x:

  A `\\preformatted{}` Rd node.

## Value

A fenced (```` ``` ````) Markdown code block.
