.linkpkg_path <- function() {
  return(testthat::test_path("fixtures", "linkpkg"))
}

.build_linkpkg <- function() {
  out <- withr::local_tempdir(.local_envir = parent.frame())
  suppressMessages(build_reference(.linkpkg_path(), output_dir = out))
  return(out)
}

.read_md <- function(path) {
  return(paste(readLines(path, encoding = "UTF-8"), collapse = "\n"))
}

test_that("a link to a topic of the same package renders as a relative Markdown link", {
  out <- .build_linkpkg()
  md <- .read_md(file.path(out, "main_topic.md"))

  expect_match(md, "](other_topic.md)", fixed = TRUE)
  expect_match(md, "[`other_topic`](other_topic.md)", fixed = TRUE)
  expect_match(md, "[`the other topic`](other_topic.md)", fixed = TRUE)
})

test_that("a linkS4class link renders as a link to the class topic", {
  out <- .build_linkpkg()
  md <- .read_md(file.path(out, "main_topic.md"))

  expect_match(md, "[`Thing`](Thing-class.md)", fixed = TRUE)
})

test_that("a link inside code renders as a code span inside the link", {
  out <- .build_linkpkg()
  md <- .read_md(file.path(out, "main_topic.md"))

  expect_match(md, "[`helper_fun()`](helper_fun.md)", fixed = TRUE)
})

test_that("a link to another package or to an unknown alias renders as a code span", {
  out <- .build_linkpkg()
  md <- .read_md(file.path(out, "main_topic.md"))

  expect_match(md, "Cross-package link: `median`.", fixed = TRUE)
  expect_match(md, "Unknown alias: `no_such_alias`.", fixed = TRUE)
  expect_no_match(md, "median.md", fixed = TRUE)
  expect_no_match(md, "no_such_alias.md", fixed = TRUE)
})

test_that("a roxygen family block in seealso links each member to its topic file", {
  out <- .build_linkpkg()
  md <- .read_md(file.path(out, "main_topic.md"))

  expect_match(
    md,
    "## See Also\n\nOther fam: [`fam_a()`](fam_a.md), [`fam_b()`](fam-topics.md)\n",
    fixed = TRUE
  )
})

test_that("seealso keeps its list structure", {
  rd <- tools::parse_Rd(textConnection(c(
    "\\name{f}",
    "\\alias{f}",
    "\\title{F}",
    "\\seealso{",
    "\\itemize{",
    "\\item \\code{a}",
    "\\item \\code{b}",
    "}",
    "}"
  )))
  topic <- .parse_rd_topic(rd, "f.Rd", "testpkg")

  expect_equal(topic$seealso, "- `a`\n- `b`")
})

test_that("_full_reference.md and get_documentation() have no relative file links", {
  out <- .build_linkpkg()
  full <- .read_md(file.path(out, "_full_reference.md"))
  docs <- get_documentation(.linkpkg_path())

  for (md in list(full, docs)) {
    expect_no_match(md, "\\]\\([^)]*\\.md", perl = TRUE)
    expect_match(md, "Plain link: `other_topic`.", fixed = TRUE)
    expect_match(md, "Roxygen function link: `helper_fun()`.", fixed = TRUE)
  }
})

test_that("the per-topic output of the fixture has no dead links", {
  out <- .build_linkpkg()

  expect_equal(nrow(.find_dead_links(out)), 0)
  expect_gt(nrow(.md_relative_links(out)), 0)
})

.write_link_folder <- function(files) {
  dir <- withr::local_tempdir(.local_envir = parent.frame())
  for (name in names(files)) {
    writeLines(files[[name]], file.path(dir, name))
  }
  return(dir)
}

.target_md <- c(
  "# Target page",
  "",
  "## A heading",
  "",
  "## A heading",
  "",
  "<a id=\"method-TaskJob-new\"></a>"
)

test_that(".find_dead_links reports a dead file, a dead fragment and a case-only fragment mismatch", {
  dir <- .write_link_folder(list(
    "a.md" = c(
      "[x](missing.md)",
      "[y](b.md#nope)",
      "[z](b.md#method-TaskJob-new)",
      "[live](b.md#method-taskjob-new)"
    ),
    "b.md" = .target_md
  ))
  dead <- .find_dead_links(dir)

  expect_equal(nrow(dead), 3)
  expect_equal(dead$file, c("a.md", "a.md", "a.md"))
  expect_equal(
    dead$link,
    c("missing.md", "b.md#nope", "b.md#method-TaskJob-new")
  )
  expect_equal(dead$kind, c("file", "fragment", "fragment"))
})

test_that(".find_dead_links reads destinations with parentheses and angle brackets", {
  dir <- .write_link_folder(list(
    "a.md" = c(
      "[p](a(b).md) [q](<a b.md>) [r](<a b.md#target-page>)",
      "[s](a(b).md \"title\") [t](a(c).md) [u](<a c.md>)",
      "[v](a(b).md#nope) [w](<a b.md#nope>)"
    ),
    "a(b).md" = .target_md,
    "a b.md" = .target_md
  ))
  dead <- .find_dead_links(dir)

  expect_equal(
    .md_relative_links(dir)$link,
    c(
      "a(b).md",
      "a b.md",
      "a b.md#target-page",
      "a(b).md",
      "a(c).md",
      "a c.md",
      "a(b).md#nope",
      "a b.md#nope"
    )
  )
  expect_equal(dead$link, c("a(c).md", "a c.md", "a(b).md#nope", "a b.md#nope"))
  expect_equal(dead$kind, c("file", "file", "fragment", "fragment"))
})

test_that(".find_dead_links reports a fragment on a file that is not Markdown", {
  dir <- .write_link_folder(list(
    "a.md" = c("[x](data.txt) [y](data.txt#part)"),
    "data.txt" = c("<a id=\"part\"></a>")
  ))
  dead <- .find_dead_links(dir)

  expect_equal(dead$link, "data.txt#part")
  expect_equal(dead$kind, "fragment")
})

test_that(".find_dead_links reports nothing for a folder with no dead links", {
  dir <- .write_link_folder(list(
    "a.md" = c(
      "# Local",
      "[a](b.md) [b](b.md#target-page) [c](b.md#a-heading)",
      "[d](b.md#a-heading-1) [e](b.md#method-taskjob-new) [f](#local)"
    ),
    "b.md" = .target_md
  ))

  expect_equal(nrow(.find_dead_links(dir)), 0)
  expect_equal(nrow(.md_relative_links(dir)), 6)
})

test_that(".find_dead_links ignores external links and links in code", {
  dir <- .write_link_folder(list(
    "a.md" = c(
      "[a](https://example.com/x.md) [b](http://example.com) [c](mailto:x@y.z)",
      "`[d](gone.md)` and ``[e](gone.md#x)``",
      "```",
      "[f](gone.md)",
      "```",
      "[g](#in-code)",
      "`<a id=\"in-code\"></a>`"
    )
  ))
  dead <- .find_dead_links(dir)

  expect_equal(dead$link, "#in-code")
  expect_equal(dead$kind, "fragment")
})
