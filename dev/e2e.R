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
# It exits 0 always. The caller reads the counts.

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
