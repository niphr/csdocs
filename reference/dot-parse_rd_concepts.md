# Extract all `\\concept{}` entries of an Rd object

roxygen2 writes one `\\concept{}` for each `@family` and each
`@concept`.

## Usage

``` r
.parse_rd_concepts(rd)
```

## Arguments

- rd:

  An `Rd` object.

## Value

Character vector of concepts, possibly empty.
