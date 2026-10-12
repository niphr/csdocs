# Parse `export(...)` directives out of a `NAMESPACE` file

Parse `export(...)` directives out of a `NAMESPACE` file

## Usage

``` r
.parse_namespace_exports(ns_file)
```

## Arguments

- ns_file:

  Path to a `NAMESPACE` file.

## Value

Character vector of exported names (possibly empty), with surrounding
quotes/backticks stripped (`export("[<-.foo")`, `` export(`%>%`) ``).
