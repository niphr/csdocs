# Write text to a file as UTF-8, regardless of the platform's locale

Plain `writeLines(x, path, useBytes = TRUE)` relies on every string in
`x` already carrying a UTF-8 marking that R's `useBytes` path preserves
as-is - true on macOS/Linux where the native encoding already is UTF-8,
but fragile on Windows locales where a non-UTF-8 native encoding can
cause silent mis-encoding. Opening the connection in raw binary mode
(`"wb"`) and explicitly marking the text as UTF-8 first
([`enc2utf8()`](https://rdrr.io/r/base/Encoding.html)) writes the
intended bytes unconditionally, independent of the platform's native
encoding, and also sidesteps any newline translation `"w"` mode would
otherwise apply.

## Usage

``` r
.write_utf8_lines(text, path)
```

## Arguments

- text:

  Character vector to write, one file line per element.

- path:

  Destination file path.

## Value

`path`, invisibly.
