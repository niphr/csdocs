# Resolve a topic's name, preferring its `\\name{}` tag

The Rd database's list name (`rd_name`, typically `"function_name.Rd"`)
is usually identical to the topic's own `\\name{}` tag, but not always -
e.g. dplyr's `group_by_prepare.Rd` declares `\\name{distinct_prepare}`.
The `\\name{}` tag is what `?topic` and cross-references actually
resolve against, so it takes priority; the filename-derived name is only
a fallback for the (invalid, but not worth hard-failing on) case where
`\\name{}` is missing.

## Usage

``` r
.parse_rd_name(rd, rd_name)
```

## Arguments

- rd:

  An `Rd` object.

- rd_name:

  Name of the Rd entry (list name from the Rd database).

## Value

A single string.
