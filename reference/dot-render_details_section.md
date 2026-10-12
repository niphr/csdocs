# Render the details section, if present

`topic$details` is already multi-paragraph Markdown produced by
[`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md)
(lists, subsections, code blocks may all be present), so it's
interpolated as-is rather than wrapped as a single line.

## Usage

``` r
.render_details_section(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

Markdown string, possibly empty.
