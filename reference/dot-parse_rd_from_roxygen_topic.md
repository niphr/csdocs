# Parse one in-memory roxygen2 `RdFile` topic into an `Rd` object

`format(topic)` renders the `RdFile` back to `.Rd` source text, which
[`tools::parse_Rd()`](https://rdrr.io/r/tools/parse_Rd.html) only
accepts from a connection, not a plain string - hence the
[`textConnection()`](https://rdrr.io/r/base/textconnections.html)
round-trip. The connection is explicitly closed afterwards; left open,
each call leaks one and eventually surfaces as an R "closing unused
connection" warning once the finalizer runs.

## Usage

``` r
.parse_rd_from_roxygen_topic(topic)
```

## Arguments

- topic:

  A single roxygen2 `RdFile` object.

## Value

An `Rd` object, as
[`tools::parse_Rd()`](https://rdrr.io/r/tools/parse_Rd.html) would
return for a file on disk.
