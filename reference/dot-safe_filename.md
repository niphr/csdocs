# Make a function/topic name safe for use as a filename

Replaces characters that are problematic in filenames (e.g. `%`, `<-`,
`/`) with URL encoding. A leading `.` - the standard R convention for
internal helpers (`.get_rd_tag`, `.rd_to_text`, ...), and exactly what
`include_private` surfaces - gets a `dot-` prefix instead (mirroring
`roxygen2::document()`'s own `man/dot-*.Rd` convention): a literal
leading dot makes the file invisible to
[`list.files()`](https://rdrr.io/r/base/list.files.html) (default
`all.files = FALSE`), Finder, and plain `ls`, which would make a
documented-and-correctly-flagged-private topic file *look* undocumented
even though it exists on disk. Otherwise-plain alphanumeric names
(including any remaining internal `.`/`_`) are returned unchanged.

## Usage

``` r
.safe_filename(name)
```

## Arguments

- name:

  Topic or function name.

## Value

Filesystem-safe string without file extension.
