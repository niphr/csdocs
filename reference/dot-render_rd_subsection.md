# Render a `\\subsection{title}{body}` node as a Markdown heading + body

The title is collapsed to a single line via
[`.collapse_whitespace()`](https://niphr.github.io/csdocs/reference/dot-collapse_whitespace.md) -
an ATX heading (`### Title`) can't contain a literal newline either.

## Usage

``` r
.render_rd_subsection(x, heading_level)
```

## Arguments

- x:

  A `\\subsection{}{}` Rd node (2 children: title, body).

- heading_level:

  Heading depth for this subsection's own title.

## Value

A Markdown string: the heading, a blank line, then the recursively
rendered body (nested subsections increase `heading_level` by 1).
