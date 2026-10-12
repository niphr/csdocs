# Abort if two topics would collide on the filesystem

Two distinct failure modes: (1) a topic whose name is `README` or
`_full_reference` (case-insensitive) would silently overwrite one of
csdocs's own generated meta files; (2) two topics whose names differ
only in letter case (e.g. `Foo`/`foo`) write to the same path on a
case-insensitive filesystem (macOS/Windows default), so the second write
silently clobbers the first. Both are rare but corrupt the output
silently if left unchecked, so they abort the whole build with a clear
message rather than producing an incomplete reference.

## Usage

``` r
.check_topic_name_collisions(topics)
```

## Arguments

- topics:

  List of parsed topic lists.

## Value

`NULL`, invisibly. Aborts via
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html) if
needed.
