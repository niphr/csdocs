# Extract all child tags of a given type from an Rd object

[`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html) (and
[`tools::parse_Rd()`](https://rdrr.io/r/tools/parse_Rd.html)) return
objects of class `Rd` whose elements carry a `Rd_tag` attribute (e.g.
`"\\arguments"`, `"\\description"`). This helper will filter an Rd
object (or a list of Rd fragments) down to the direct children matching
a given tag.

## Usage

``` r
.get_rd_tag(rd, tag)
```

## Arguments

- rd:

  An `Rd` object or a list of Rd fragments.

- tag:

  Tag name including the leading backslash, e.g. `"\\item"`.

## Value

List of matching Rd fragments (possibly empty).
