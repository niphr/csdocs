# Coerce a single (non-list) Rd node to a scalar string

Almost always `as.character(x)` already returns a length-1 string. The
exception is `"USERMACRO"`-tagged nodes (from Rd macros like `\\I{}`),
whose value is a placeholder token (`"#1"`) followed by the macro's
substituted argument (e.g. `c("#1", "bar")`).
[`tools::parse_Rd()`](https://rdrr.io/r/tools/parse_Rd.html) already
duplicates that substituted text into the *following* sibling `TEXT`
node as a fallback for consumers that don't understand `USERMACRO`
(verified against
[`tools::Rd2txt()`](https://rdrr.io/r/tools/Rd2HTML.html)'s own
output) - so a `USERMACRO` node contributes nothing here to avoid
rendering the text twice. Any other, unanticipated multi-value leaf is
collapsed rather than erroring.

## Usage

``` r
.leaf_rd_text(x)
```

## Arguments

- x:

  A non-list Rd leaf node.

## Value

A single string.
