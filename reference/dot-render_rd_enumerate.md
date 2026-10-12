# Render an `\\enumerate{}` node as a Markdown numbered list

Each item is collapsed to a single line - see
[`.render_rd_itemize()`](https://niphr.github.io/csdocs/reference/dot-render_rd_itemize.md)
for why.

## Usage

``` r
.render_rd_enumerate(x)
```

## Arguments

- x:

  An `\\enumerate{}` Rd node.

## Value

A Markdown string, one `N. item` line per item.
