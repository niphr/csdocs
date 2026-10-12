# Parse every entry of an Rd database into topic lists

Topics without a name (e.g. purely internal Rd fragments) are dropped;
the result is sorted alphabetically by `name` so that the index and
`_full_reference.md` have a stable order.

## Usage

``` r
.build_topics(db, package, exported_names = NULL)
```

## Arguments

- db:

  Result of
  [`.read_rd_db()`](https://niphr.github.io/csdocs/reference/dot-read_rd_db.md).

- package:

  Package name.

- exported_names:

  Character vector of the package's exported names, or `NULL` if
  unknown - see
  [`.read_exported_names()`](https://niphr.github.io/csdocs/reference/dot-read_exported_names.md)
  and
  [`.compute_is_private()`](https://niphr.github.io/csdocs/reference/dot-compute_is_private.md).

## Value

List of parsed topic lists, sorted by `name`.
