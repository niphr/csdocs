# Split the children of an `\\itemize{}`/`\\enumerate{}` node into items

Unlike `\\arguments{}`'s `\\item{name}{description}` (a proper 2-child
container), `\\itemize{}`/`\\enumerate{}`'s `\\item` is a bare marker
with no children of its own — an item's actual content is its *following
sibling nodes*, up to the next `\\item` marker (or the end of the list).
Content before the first `\\item` (leading whitespace) is discarded.

## Usage

``` r
.split_rd_items(children)
```

## Arguments

- children:

  The children of an `\\itemize{}`/`\\enumerate{}` node.

## Value

A list of items, each itself a list of Rd fragments.
