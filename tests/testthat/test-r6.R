# Render one Rd fixture to <dir>/<name>.md, the way build_reference() renders
# a topic, without the footer. The footer links README.md, which this folder
# does not have.
.render_r6_fixture <- function(name, dir) {
  rd <- tools::parse_Rd(test_path("fixtures", "r6", paste0(name, ".Rd")))
  topic <- .parse_rd_topic(rd, paste0(name, ".Rd"), "testpkg")
  path <- file.path(dir, paste0(name, ".md"))
  .write_utf8_lines(.render_topic_md(topic, "0.0.0", footer = FALSE), path)
  return(path)
}

# The lines of a Markdown file that are inside a fenced code block.
.fenced_lines <- function(lines) {
  return(lines[.md_strip_fences(lines) != lines])
}

test_that("every in-page method link of the TaskJob page resolves to an anchor", {
  dir <- withr::local_tempdir()
  path <- .render_r6_fixture("TaskJob", dir)
  lines <- readLines(path, encoding = "UTF-8")

  expect_equal(sum(grepl("](#method-taskjob-", lines, fixed = TRUE)), 8)
  dead <- .find_dead_links(dir)
  expect_equal(nrow(dead[dead$kind == "fragment", ]), 0)
})

test_that("an R6 method anchor renders as a lowercase <a id> on its own line", {
  dir <- withr::local_tempdir()
  lines <- readLines(.render_r6_fixture("TaskJob", dir), encoding = "UTF-8")

  expect_true("<a id=\"method-taskjob-initialize\"></a>" %in% lines)
  expect_equal(sum(grepl("^<a id=\"method-taskjob-[a-z_]+\"></a>$", lines)), 8)
})

test_that("no fenced code block in the rendered R6 pages holds HTML", {
  dir <- withr::local_tempdir()
  for (name in c("TaskJob", "Inherits")) {
    lines <- readLines(.render_r6_fixture(name, dir), encoding = "UTF-8")
    fenced <- .fenced_lines(lines)
    expect_false(any(grepl("<a id", fenced, fixed = TRUE)), label = name)
    expect_false(any(grepl("<details", fenced, fixed = TRUE)), label = name)
    expect_false(any(grepl("<hr>", lines, fixed = TRUE)), label = name)
    expect_false(any(grepl("<div", lines, fixed = TRUE)), label = name)
  }
})

test_that("the Inherited methods block renders as a list of code spans", {
  dir <- withr::local_tempdir()
  lines <- readLines(.render_r6_fixture("Inherits", dir), encoding = "UTF-8")

  expect_true(all(c("- `Base$goodbye()`", "- `Base$hello()`") %in% lines))
  expect_false(any(grepl("<details|<li>|<ul>", lines)))
  dead <- .find_dead_links(dir)
  expect_equal(nrow(dead), 0)
})

test_that(".render_inherited_methods reads the roxygen2 7 span form", {
  html <- paste0(
    "<details open><summary>Inherited methods</summary><ul>",
    "<li><span class=\"pkg-link\" data-pkg=\"P\" data-topic=\"C\" ",
    "data-id=\"m\"><a href='../../P/html/C.html#method-C-m'>",
    "<code>P::C$m()</code></a></span></li></ul></details>"
  )
  expect_equal(
    .render_inherited_methods(html),
    "Inherited methods:\n\n- `C$m()`"
  )
})

test_that("other \\out{} HTML is dropped", {
  expect_null(.render_inherited_methods("<hr>"))
  rd <- tools::parse_Rd(textConnection(
    "\\name{x}\\alias{x}\\title{T}\\description{\\if{html}{\\out{<hr>}}}"
  ))
  out <- .first_rd_tag_children(rd, "\\description")[[1]][[2]][[1]]
  expect_null(.render_rd_out_as_code(out))
})

test_that("the rendered TaskJob page matches its snapshot", {
  dir <- withr::local_tempdir()
  expect_snapshot_file(.render_r6_fixture("TaskJob", dir), "TaskJob.md")
})
