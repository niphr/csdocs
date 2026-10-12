# Write the `README.md` index file

Write the `README.md` index file

## Usage

``` r
.write_index_file(topics, package, version, output_dir, sections = NULL)
```

## Arguments

- topics:

  List of parsed topic lists.

- package:

  Package name.

- version:

  Package version.

- output_dir:

  Target directory.

- sections:

  Result of
  [`.read_pkgdown_sections()`](https://niphr.github.io/csdocs/reference/dot-read_pkgdown_sections.md),
  or `NULL`.

## Value

Path to the written file, invisibly.
