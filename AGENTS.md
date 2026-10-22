# csdocs: agent notes

csdocs is a fork of [pkgmd](https://github.com/peterczerner/pkgmd) at commit `61e52b1`. The git remote `upstream` is pkgmd. The git remote `origin` is `niphr/csdocs`.

## Where the code lives

- `R/build_reference.R`: the two exported functions, `build_reference()` and `get_documentation()`, and the functions that write the output files.
- `R/build_site.R`: the exported `build_site()`, which builds a whole site: reference pages and rendered vignettes.
- `R/links.R`: resolves Rd links to Markdown hrefs, and finds dead links in a built site.
- `R/pkgdown_sections.R`: reads the reference sections from `_pkgdown.yml` and groups the index by them.
- `R/parse_rd.R`: reads the Rd database of an installed package or a source package, and parses each topic.
- `R/render_md.R`: renders one parsed topic, and the index, as Markdown.
- `R/render_rd_block.R`: renders block-level Rd, for example lists, subsections, tables and code blocks.
- `R/utils.R`: inline Rd text extraction and small helpers.
- `tests/testthat/`: one test file for each file in `R/`, except `pkgdown_sections.R`, which `test-index.R` covers, plus `test-r6.R`.

## Checks

Run both scripts from the package root before you commit.

- `Rscript dev/check.R` runs the tests and prints `TESTS <n> FAILED <n> SKIPPED <n>`. To run one test file, give a filter as the first argument, for example `Rscript dev/check.R render_md`.
- `Rscript dev/static.R` runs the `static-checks` job of `niphr/cstemplate/.github/workflows/r-package.yml` on this machine: the limit of 1000 code lines for each file, and lintr 3.4.0. It prints `LINTS <n>` and exits 1 when a check fails.

The lint allowlist is empty. Fix a lint. Do not add it to the allowlist. The `return_linter` needs an explicit `return()` at the end of every function body in braces.

`dev/static.R` installs org, lintr and cyclocomp into its own library, under `tools::R_user_dir("csdocs", "cache")`. It does not change the user library.

CI is `.github/workflows/check.yml`. It calls the shared workflow, which runs `R CMD check --as-cran` and fails on a NOTE.
