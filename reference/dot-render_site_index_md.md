# Render the front page of a site

Render the front page of a site

## Usage

``` r
.render_site_index_md(package, version, commit, titles)
```

## Arguments

- package:

  Package name.

- version:

  Package version.

- commit:

  Full commit hash, or `NULL`.

- titles:

  Article titles, named by the relative path of each `.md` file, as from
  [`.render_articles()`](https://niphr.github.io/csdocs/reference/dot-render_articles.md).

## Value

A character vector of Markdown lines.
