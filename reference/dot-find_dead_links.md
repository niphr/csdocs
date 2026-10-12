# Find the dead relative links in a folder of Markdown files

Reads every `.md` file under `dir` and checks every relative Markdown
link. A link is dead when its file does not exist, or when its
`#fragment` is not a target in the file it points to. A fragment on a
file that is not Markdown is always dead. A link of the form `#x` points
to the same file. The checker ignores links with a URL scheme, such as
`https:` or `mailto:`. It also ignores links and targets inside fenced
code blocks and inline code spans.

## Usage

``` r
.find_dead_links(dir)
```

## Arguments

- dir:

  Path to a folder.

## Value

A data.frame with the columns `file` (relative to `dir`), `link` and
`kind`, which is `"file"` or `"fragment"`. It has one row per dead link.

## Details

The targets follow GitHub: see
[`.md_fragment_targets()`](https://niphr.github.io/csdocs/reference/dot-md_fragment_targets.md).
The checker compares a fragment with the targets exactly, because GitHub
does too.
