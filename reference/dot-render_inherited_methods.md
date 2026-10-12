# Render the R6 "Inherited methods" HTML block as a Markdown list

roxygen2 7 writes each method as a `<span>` with the attributes
`data-topic="C"` and `data-id="m"`. roxygen2 8 writes
`<code>C$m()</code>`. Each method becomes one list item `` `C$m()` ``.
The list has no links, because the HTML links point at the HTML help
pages of other packages.

## Usage

``` r
.render_inherited_methods(html)
```

## Arguments

- html:

  Raw HTML string of one `\\out{}` node.

## Value

A Markdown list, or `NULL` when `html` is not this block.
