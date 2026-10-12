# Build the reference of two real packages and check the links in it.
#
# Usage, from the package root:
#   Rscript dev/e2e.R
#
# The script reads the source directories of cs9 and norsyss.cs9 and does
# not change them. It writes the output to $TEMP/csdocs-e2e/<pkg>. For each
# package it prints three counts, then every dead link:
#   DEADFILES <pkg> <n>      links whose file does not exist
#   DEADFRAGMENTS <pkg> <n>  links whose #fragment is not a target
#   LINKS <pkg> <n>          relative links to a .md file
# It then runs build_site() on the sitepkg fixture into
# $TEMP/csdocs-e2e/sitepkg-site and prints DEADFILES and DEADFRAGMENTS for
# it, plus ARTICLES sitepkg-site <n>, the number of articles/*.md files.
# It exits 0 always. The caller reads the counts.

# pandoc is not on PATH here. This is the copy that dev/check.R uses.
Sys.setenv(
  RSTUDIO_PANDOC = "C:/Users/RIWH/AppData/Local/Programs/Positron/resources/app/quarto/bin/tools"
)
pkgload::load_all(".", quiet = TRUE)

packages <- c(
  cs9 = "C:/Users/RIWH/GitHub/cs9",
  norsyss.cs9 = "C:/Users/RIWH/GitHub/norsyss.cs9"
)
root <- file.path(Sys.getenv("TEMP"), "csdocs-e2e")

for (pkg in names(packages)) {
  out <- file.path(root, pkg)
  suppressMessages(build_reference(packages[[pkg]], output_dir = out))
  links <- .md_relative_links(out)
  path <- sub("[?#].*$", "", links$link)
  dead <- .find_dead_links(out)
  cat(sprintf("DEADFILES %s %d\n", pkg, sum(dead$kind == "file")))
  cat(sprintf("DEADFRAGMENTS %s %d\n", pkg, sum(dead$kind == "fragment")))
  cat(sprintf("LINKS %s %d\n", pkg, sum(grepl("\\.md$", path))))
  for (i in seq_len(nrow(dead))) {
    cat(sprintf("  %s %s %s\n", dead$kind[i], dead$file[i], dead$link[i]))
  }
}

site <- file.path(root, "sitepkg-site")
suppressMessages(build_site(
  "tests/testthat/fixtures/sitepkg",
  output_dir = site
))
dead <- .find_dead_links(site)
cat(sprintf("DEADFILES sitepkg-site %d\n", sum(dead$kind == "file")))
cat(sprintf("DEADFRAGMENTS sitepkg-site %d\n", sum(dead$kind == "fragment")))
cat(sprintf(
  "ARTICLES sitepkg-site %d\n",
  length(list.files(file.path(site, "articles"), pattern = "\\.md$"))
))
for (i in seq_len(nrow(dead))) {
  cat(sprintf("  %s %s %s\n", dead$kind[i], dead$file[i], dead$link[i]))
}
