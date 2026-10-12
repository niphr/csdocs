test_that("%||% falls back only for NULL", {
  expect_equal(NULL %||% "fallback", "fallback")
  expect_equal("value" %||% "fallback", "value")
  expect_equal(0 %||% "fallback", 0)
  expect_equal(FALSE %||% "fallback", FALSE)
})

test_that(".collapse_whitespace collapses newlines and internal whitespace to single spaces", {
  expect_equal(.collapse_whitespace("a\nb"), "a b")
  expect_equal(.collapse_whitespace("a   \n  b\n\nc"), "a b c")
  expect_equal(.collapse_whitespace("  padded  "), "padded")
  expect_equal(.collapse_whitespace("one line"), "one line")
})

test_that(".get_rd_tag filters direct children by Rd_tag", {
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{A test function}
\\description{Does something test-worthy.}
"
  rd <- tools::parse_Rd(textConnection(rd_text))

  titles <- .get_rd_tag(rd, "\\title")
  expect_length(titles, 1)

  missing <- .get_rd_tag(rd, "\\value")
  expect_length(missing, 0)
})

test_that(".rd_to_text flattens nested Rd fragments, rendering inline tags as Markdown", {
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{A test function}
\\description{Returns \\code{x + y}, see \\link{other_fun}.}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  description <- .get_rd_tag(rd, "\\description")

  expect_equal(.rd_to_text(description), "Returns `x + y`, see `other_fun`.")
})

.rd_description_text <- function(rd_body) {
  rd_text <- paste0(
    "\\name{my_fun}\n\\alias{my_fun}\n\\title{T}\n\\description{", rd_body, "}\n"
  )
  rd <- tools::parse_Rd(textConnection(rd_text))
  .rd_to_text(.get_rd_tag(rd, "\\description"))
}

test_that(".rd_to_text doesn't double-wrap \\code{\\link{}} in backticks", {
  # Real dplyr regression: \code{\link{arrange}()} in \seealso{} rendered
  # as "``arrange`()`" (backtick-in-backtick) because \code and \link each
  # independently wrapped their content.
  md <- .rd_description_text("\\code{\\link{arrange}}()")
  expect_equal(md, "`arrange`()")
})

test_that(".rd_to_text renders \\method{generic}{class} as generic.class", {
  rd_text <- "
\\name{mutate}
\\alias{mutate}
\\title{T}
\\usage{
\\method{mutate}{data.frame}(.data, ...)
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  usage <- .get_rd_tag(rd, "\\usage")

  expect_match(.rd_to_text(usage), "^mutate\\.data\\.frame\\(", perl = TRUE)
})

test_that(".rd_to_raw_text renders \\method{generic}{class} as generic.class", {
  rd_text <- "
\\name{mutate}
\\alias{mutate}
\\title{T}
\\usage{
\\method{mutate}{data.frame}(.data, ...)
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  usage <- .get_rd_tag(rd, "\\usage")

  expect_match(trimws(.rd_to_raw_text(usage)), "^mutate\\.data\\.frame\\(", perl = TRUE)
})

test_that(".rd_to_text normalizes whitespace and handles NULL", {
  expect_equal(.rd_to_text(NULL), "")

  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{A test function}
\\description{Has    extra   spaces.}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  description <- .get_rd_tag(rd, "\\description")

  expect_equal(.rd_to_text(description), "Has extra spaces.")
})

test_that(".rd_to_text renders \\emph{} and \\strong{}/\\bold{} as Markdown emphasis", {
  expect_equal(.rd_description_text("\\emph{word}"), "_word_")
  expect_equal(.rd_description_text("\\strong{word}"), "**word**")
  expect_equal(.rd_description_text("\\bold{word}"), "**word**")
})

test_that(".rd_to_text renders \\href{}{} as a Markdown link and \\url{} in angle brackets", {
  expect_equal(
    .rd_description_text("\\href{https://example.com}{link text}"),
    "[link text](https://example.com)"
  )
  expect_equal(.rd_description_text("\\url{https://example.com}"), "<https://example.com>")
})

test_that(".rd_to_text renders \\dQuote{}/\\sQuote{} as quoted text", {
  expect_equal(.rd_description_text("\\dQuote{word}"), "“word”")
  expect_equal(.rd_description_text("\\sQuote{word}"), "‘word’")
})

test_that(".rd_to_raw_text preserves internal whitespace and indentation verbatim", {
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{T}
\\usage{
my_fun(x,
  y = 1)
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  usage <- .get_rd_tag(rd, "\\usage")

  expect_equal(trimws(.rd_to_raw_text(usage)), "my_fun(x,\n  y = 1)")
})

test_that(".rd_to_text handles USERMACRO nodes (e.g. \\I{}) without duplicating text", {
  rd_text <- "
\\name{foo}
\\alias{foo}
\\title{Foo}
\\description{Foo.}
\\seealso{See \\I{bar} for details.}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  seealso <- .get_rd_tag(rd, "\\seealso")

  # tools::parse_Rd() already duplicates the macro's substituted text
  # ("bar") into the following sibling TEXT node as a fallback for
  # consumers that don't understand USERMACRO tags (verified against
  # tools::Rd2txt()'s own rendering of this input) — so .leaf_rd_text()
  # must skip USERMACRO nodes to avoid rendering "bar" twice.
  expect_equal(.rd_to_text(seealso), "See bar for details.")
})

test_that(".leaf_rd_text skips USERMACRO nodes and passes through plain text", {
  x <- c("#1", "bar")
  attr(x, "Rd_tag") <- "USERMACRO"
  expect_equal(.leaf_rd_text(x), "")

  expect_equal(.leaf_rd_text("plain text"), "plain text")
})

test_that(".callable_candidates finds a name that appears as a call in usage", {
  expect_equal(.callable_candidates("mutate", "mutate", "mutate(.data, ...)"), "mutate")
})

test_that(".callable_candidates returns nothing for a bare-name usage (dataset)", {
  expect_equal(.callable_candidates("starwars", "starwars", "starwars"), character(0))
})

test_that(".callable_candidates returns nothing when usage is empty", {
  expect_equal(.callable_candidates("some_topic", character(0), ""), character(0))
})

test_that(".callable_candidates finds every callable when a topic documents more than one", {
  result <- .callable_candidates("lead-lag", c("lead-lag", "lag", "lead"), "lag(x)\n\nlead(x)")
  expect_equal(result, c("lag", "lead"))
})

test_that(".callable_candidates recognizes an infix operator despite no call syntax", {
  # Real csdocs regression: %||%'s own \usage{} is "x %||% y" - never
  # "%||%(" - so the plain name-followed-by-"(" check alone missed it,
  # which meant %||% was silently never eligible to be flagged private.
  expect_equal(.callable_candidates("%||%", "%||%", "x %||% y"), "%||%")
})

test_that(".callable_candidates does not mistake an ordinary name for an operator", {
  expect_equal(.callable_candidates("percent", "percent", "some %||% other text"), character(0))
})

test_that(".escape_table_pipe escapes a literal pipe", {
  expect_equal(.escape_table_pipe("TRUE|FALSE"), "TRUE\\|FALSE")
  expect_equal(.escape_table_pipe("no pipes here"), "no pipes here")
})

test_that(".code_fence uses 3 backticks when content has none", {
  expect_equal(.code_fence("plain code"), "```")
})

test_that(".code_fence widens past an embedded backtick run", {
  expect_equal(.code_fence("code with ``` inside"), "````")
  expect_equal(.code_fence("code with ```` inside"), "`````")
})

test_that(".inline_code_span wraps ordinary text in a single backtick pair", {
  expect_equal(.inline_code_span("mutate"), "`mutate`")
})

test_that(".inline_code_span widens and pads when content itself is a backtick", {
  # Real base::Quotes regression: one of its aliases IS the backtick
  # character. A naive `` `x` `` wrap around a bare backtick produces an
  # unbroken run of 3 backticks, which reads as a fence, not a code span.
  span <- .inline_code_span("`")

  expect_equal(span, "`` ` ``")
  expect_no_match(span, "`{3,}", perl = TRUE)
})

test_that(".inline_code_span widens delimiters around embedded backtick runs", {
  span <- .inline_code_span("a``b")
  expect_equal(span, "```a``b```")
})

test_that(".write_utf8_lines writes UTF-8 text that reads back unchanged", {
  path <- withr::local_tempfile()
  text <- c("# Title with émoji 🎉", "Second line with ümlaut")

  .write_utf8_lines(text, path)
  result <- readLines(path, encoding = "UTF-8")

  expect_equal(result, text)
})

test_that(".safe_filename leaves plain names untouched", {
  expect_equal(.safe_filename("mutate"), "mutate")
  expect_equal(.safe_filename("my_fun.default"), "my_fun.default")
  expect_equal(.safe_filename("my-fun"), "my-fun")
})

test_that(".safe_filename URL-encodes special characters", {
  encoded <- .safe_filename("%>%")
  expect_false(encoded == "%>%")
  expect_match(encoded, "%")

  encoded_assign <- .safe_filename("<-")
  expect_false(grepl("/", encoded_assign, fixed = TRUE))
})

test_that(".safe_filename replaces a leading dot so the file isn't hidden", {
  # Real regression: a private/internal topic like .escape_table_pipe
  # produced a literal dotfile, invisible to list.files() (default
  # all.files = FALSE), Finder, and plain ls - the file existed but
  # looked undocumented. Mirrors roxygen2::document()'s own man/dot-*.Rd
  # convention for exactly this problem.
  expect_equal(.safe_filename(".escape_table_pipe"), "dot-escape_table_pipe")
  expect_false(startsWith(.safe_filename(".rd_to_text"), "."))
})

test_that(".is_source_path detects a directory with a DESCRIPTION file", {
  pkg_dir <- withr::local_tempdir()
  writeLines("Package: fixturepkg", fs::path(pkg_dir, "DESCRIPTION"))

  expect_true(.is_source_path(pkg_dir))
})

test_that(".is_source_path is FALSE for a directory without DESCRIPTION", {
  empty_dir <- withr::local_tempdir()
  expect_false(.is_source_path(empty_dir))
})

test_that(".is_source_path is FALSE for an installed-package-style name", {
  expect_false(.is_source_path("dplyr"))
  expect_false(.is_source_path("a-name-that-is-definitely-not-a-directory"))
})
