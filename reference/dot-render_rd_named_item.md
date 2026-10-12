# Render one top-level `\\item{name}{desc}` node as a Markdown list item

roxygen2 writes a named list in `\\value{}` as `\\item{name}{desc}`
nodes with no list container around them.

## Usage

``` r
.render_rd_named_item(x)
```

## Arguments

- x:

  An `\\item{}{}` Rd node with 2 children.

## Value

One line, `` - **`name`**: desc ``.
