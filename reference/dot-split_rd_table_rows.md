# Split the children of a `\\tabular{}{}` node's body into rows

Like
[`.split_rd_items()`](https://niphr.github.io/csdocs/reference/dot-split_rd_items.md)
for `\\itemize{}`, `\\cr` is a bare row-separator marker (0 children of
its own) rather than a container. Unlike `\\item`, content *before* the
first `\\cr` is significant (it's the first row's content, not
discardable leading whitespace) - `\\tabular{}` has no separate per-row
start marker the way `\\itemize{}`'s `\\item` doubles as both.

## Usage

``` r
.split_rd_table_rows(children)
```

## Arguments

- children:

  The children of a `\\tabular{}{}` node's body (its second argument).

## Value

A list of rows, each itself a list of Rd fragments (to be further split
into cells by
[`.split_rd_table_cells()`](https://niphr.github.io/csdocs/reference/dot-split_rd_table_cells.md)).
