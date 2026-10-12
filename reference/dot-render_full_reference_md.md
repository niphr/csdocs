# Render every topic into a single Markdown string

The shared core of `_full_reference.md` (written by
[`.write_full_reference_file()`](https://niphr.github.io/csdocs/reference/dot-write_full_reference_file.md))
and
[`get_documentation()`](https://niphr.github.io/csdocs/reference/get_documentation.md)
(returned directly, no file written) - both want the exact same content,
one to disk and one in memory.

## Usage

``` r
.render_full_reference_md(topics, package, version)
```

## Arguments

- topics:

  List of parsed topic lists.

- package:

  Package name.

- version:

  Package version.

## Value

A single Markdown string.
