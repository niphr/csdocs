# Parse a single Rd object into an internal list

Converts an `Rd` object (from either
[`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html) or
[`tools::parse_Rd()`](https://rdrr.io/r/tools/parse_Rd.html)) into a
flat list consumable by `render_md.R`.
`title`/`arguments[].name`/`arguments[].description`/`value` are
single-line-safe text via
[`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md)
(Tier 2 - table cells and the page title can't contain a literal
newline). `description`/
`details`/`format`/`seealso`/`note`/`source`/`references`/`author`/each
section's body are full multi-paragraph Markdown via
[`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md)
(Tier 3), since they commonly contain `\\itemize{}`, `\\describe{}`,
`\\subsection{}{}`, etc. that Tier 2 would flatten into unreadable
prose.

## Usage

``` r
.parse_rd_topic(rd, rd_name, package, exported_names = NULL)
```

## Arguments

- rd:

  A single `Rd` object.

- rd_name:

  Name of the Rd entry (list name from the Rd database, typically
  `"function_name.Rd"`).

- package:

  Name of the package this topic belongs to.

- exported_names:

  Character vector of the package's exported names (see
  [`.read_exported_names()`](https://niphr.github.io/csdocs/reference/dot-read_exported_names.md)),
  or `NULL` if unknown. Drives `is_private` (see
  [`.compute_is_private()`](https://niphr.github.io/csdocs/reference/dot-compute_is_private.md));
  has no other effect.

## Value

A list with fields `name`, `package`, `aliases`, `is_private`, `title`,
`description`, `usage`, `arguments`, `details`, `sections`, `format`,
`value`, `examples`, `seealso`, `note`, `source`, `references`,
`author`.
