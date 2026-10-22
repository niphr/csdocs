.block_md <- function(details_body) {
  rd_text <- paste0(
    "\\name{my_fun}\n\\alias{my_fun}\n\\title{T}\n\\description{D}\n",
    "\\details{\n",
    details_body,
    "\n}\n"
  )
  rd <- tools::parse_Rd(textConnection(rd_text))
  .rd_to_block_md(.first_rd_tag_children(rd, "\\details"))
}

test_that(".rd_to_block_md returns an empty string for NULL/empty input", {
  expect_equal(.rd_to_block_md(NULL), "")
  expect_equal(.rd_to_block_md(list()), "")
})

test_that(".rd_to_block_md joins a hard-wrapped paragraph into flowing text", {
  md <- .block_md(
    "This is a long sentence that was\nhard-wrapped in the Rd source\nfor readability."
  )
  expect_equal(
    md,
    "This is a long sentence that was hard-wrapped in the Rd source for readability."
  )
})

test_that(".rd_to_block_md preserves a real paragraph break as a blank line", {
  md <- .block_md("First paragraph.\n\nSecond paragraph.")
  expect_equal(md, "First paragraph.\n\nSecond paragraph.")
})

test_that(".rd_to_block_md renders \\itemize{} as a Markdown bullet list", {
  md <- .block_md(
    "\\itemize{\n\\item First item.\n\\item Second item with \\code{code}.\n}"
  )
  expect_equal(md, "- First item.\n- Second item with `code`.")
})

test_that(".rd_to_block_md renders \\enumerate{} as a Markdown numbered list", {
  md <- .block_md(
    "\\enumerate{\n\\item First.\n\\item Second.\n\\item Third.\n}"
  )
  expect_equal(md, "1. First.\n2. Second.\n3. Third.")
})

test_that(".rd_to_block_md collapses a hard-wrapped \\itemize{} item onto one line", {
  # Real dplyr regression: bullet items that wrap across multiple physical
  # lines in the Rd source (extremely common - Rd is hard-wrapped for
  # readability) rendered with a literal embedded newline, which isn't
  # reliably safe as "the same bullet" across Markdown renderers (a
  # continuation line can be misread as a new block, e.g. one starting
  # with "<table>" gets parsed as literal HTML). Every bullet must be a
  # single Markdown line for GitHub/Gitea compatibility.
  md <- .block_md(paste0(
    "\\itemize{\n",
    "\\item First item that\nwas wrapped across\nmultiple lines.\n",
    "\\item Second item.\n",
    "}"
  ))

  expect_equal(
    md,
    "- First item that was wrapped across multiple lines.\n- Second item."
  )
  expect_length(strsplit(md, "\n")[[1]], 2)
})

test_that(".rd_to_block_md collapses a hard-wrapped \\subsection{} title onto one line", {
  md <- .block_md("\\subsection{A title that\nwraps across lines}{\nbody\n}")

  expect_match(md, "^### A title that wraps across lines\n\n", perl = TRUE)
})

test_that(".rd_to_block_md renders \\subsection{}{} as a heading plus recursive body", {
  md <- .block_md(
    "\\subsection{A Title}{\nBody text.\n\n\\itemize{\n\\item nested item\n}\n}"
  )

  expect_match(md, "^### A Title\n\n", perl = TRUE)
  expect_match(md, "Body text.", fixed = TRUE)
  expect_match(md, "- nested item", fixed = TRUE)
})

test_that(".rd_to_block_md nested \\subsection{}{} increases heading depth", {
  md <- .block_md("\\subsection{Outer}{\n\\subsection{Inner}{\nbody\n}\n}")

  expect_match(md, "### Outer", fixed = TRUE)
  expect_match(md, "#### Inner", fixed = TRUE)
})

test_that(".rd_to_block_md renders \\preformatted{} as a fenced code block preserving indentation", {
  md <- .block_md("\\preformatted{\nraw <- code\n  keeps(indentation)\n}")

  expect_equal(md, "```\nraw <- code\n  keeps(indentation)\n```")
})

test_that(".rd_to_block_md separates paragraphs and block elements with blank lines", {
  md <- .block_md("Intro.\n\n\\itemize{\n\\item one\n\\item two\n}\n\nOutro.")

  expect_equal(md, "Intro.\n\n- one\n- two\n\nOutro.")
})

test_that(".split_rd_items ignores content before the first \\item marker", {
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{T}
\\description{D}
\\details{
\\itemize{
  leading whitespace, no item yet
  \\item real item
}
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  details <- .first_rd_tag_children(rd, "\\details")
  itemize <- Filter(
    function(x) identical(attr(x, "Rd_tag"), "\\itemize"),
    details
  )[[1]]

  items <- .split_rd_items(itemize)
  expect_length(items, 1)
})

test_that("real-world regression: dplyr_by-style description with itemize+subsection renders structurally", {
  # Reproduces (in miniature) the dplyr::dplyr_by page reported as
  # "totally wrong formatted: no bullets, no sections, no code chunks" -
  # everything used to collapse into one flat paragraph.
  rd_text <- "
\\name{dplyr_by}
\\alias{dplyr_by}
\\title{Per-operation grouping}
\\description{
There are two ways to group in dplyr:
\\itemize{
\\item Persistent grouping with \\code{group_by()}
\\item Per-operation grouping with \\code{.by}/\\code{by}
}

\\subsection{Supported verbs}{
\\itemize{
\\item \\code{mutate(.by = )}
\\item \\code{summarise(.by = )}
}
}
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  topic <- .parse_rd_topic(rd, "dplyr_by.Rd", "dplyr")

  expect_match(
    topic$description,
    "^There are two ways to group in dplyr:",
    perl = TRUE
  )
  expect_match(topic$description, "- Persistent grouping with `group_by\\(\\)`")
  expect_match(topic$description, "### Supported verbs")
  expect_match(topic$description, "- `mutate\\(.by = \\)`")
})

test_that("real-world regression: lifecycle badge (\\ifelse+\\figure) renders as plain-text fallback", {
  # Reproduces dplyr::mutate()'s .by argument: a lifecycle badge expands to
  # \ifelse{html}{\figure{...}}{\strong{[Experimental]}}. Since our output
  # targets text/Markdown, we should prefer the non-html ("no") branch.
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{T}
\\arguments{
\\item{x}{\\ifelse{html}{\\href{https://example.com}{\\figure{badge.svg}{options: alt='[Experimental]'}}}{\\strong{[Experimental]}} A value.}
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  topic <- .parse_rd_topic(rd, "my_fun.Rd", "testpkg")

  expect_equal(topic$arguments[[1]]$description, "**[Experimental]** A value.")
})

test_that("real-world regression: a bare \\figure{} with alt text falls back to that text", {
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{T}
\\description{See \\figure{diagram.svg}{options: alt='a diagram'} for details.}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  topic <- .parse_rd_topic(rd, "my_fun.Rd", "testpkg")

  expect_equal(topic$description, "See a diagram for details.")
})

test_that("real-world regression: \\if{html}{\\out{<div class=\"sourceCode r\">...}} renders as a fenced code block", {
  # Reproduces dplyr::dplyr_by()'s code examples, authored via roxygen2's
  # Markdown fenced-code support, which compiles to raw HTML passthrough.
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{T}
\\description{
Example:

\\if{html}{\\out{<div class=\"sourceCode r\">}}\\preformatted{x <- 1
x #> [1] 1}\\if{html}{\\out{</div>}}
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  topic <- .parse_rd_topic(rd, "my_fun.Rd", "testpkg")

  expect_no_match(topic$description, "<div", fixed = TRUE)
  expect_no_match(topic$description, "\\\\if", fixed = TRUE)
  expect_match(topic$description, "```")
})

test_that(".if_out_html_block drops \\out{} HTML that is not an R6 anchor or method list", {
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{T}
\\description{
\\if{html}{\\out{<div class=\"sourceCode r\">
mutate(x) #&amp;gt; result
</div>}}
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  desc <- .first_rd_tag_children(rd, "\\description")
  if_node <- Filter(function(x) identical(attr(x, "Rd_tag"), "\\if"), desc)[[1]]

  expect_null(.if_out_html_block(if_node))
  topic <- .parse_rd_topic(rd, "my_fun.Rd", "testpkg")
  expect_equal(topic$description, "")
})

test_that("real-world regression: an opening/closing-only \\out{} div wrapper contributes nothing", {
  # roxygen2's Markdown fenced-code support compiles one fenced block into
  # THREE top-level nodes: an opening \if{html}{\out{<div ...>}}, the real
  # code as a plain \preformatted{}, and a closing \if{html}{\out{</div>}}.
  # The wrapper nodes have no content once tags are stripped and used to
  # render as spurious empty ```r``` fences around the real code block.
  rd_text <- "
\\name{my_fun}
\\alias{my_fun}
\\title{T}
\\description{
Example:

\\if{html}{\\out{<div class=\"sourceCode r\">}}\\preformatted{x <- 1}\\if{html}{\\out{</div>}}
}
"
  rd <- tools::parse_Rd(textConnection(rd_text))
  topic <- .parse_rd_topic(rd, "my_fun.Rd", "testpkg")

  expect_equal(topic$description, "Example:\n\n```\nx <- 1\n```")
})

test_that(".strip_html_tags removes tags without touching surrounding text", {
  expect_equal(.strip_html_tags("<div class=\"x\">hello</div>"), "hello")
  expect_equal(.strip_html_tags("no tags here"), "no tags here")
})

test_that(".decode_html_entities decodes common entities, &amp; last", {
  expect_equal(.decode_html_entities("a &gt; b &lt; c"), "a > b < c")
  expect_equal(.decode_html_entities("&amp;lt;"), "&lt;")
  expect_equal(.decode_html_entities("&quot;q&quot; &#39;s&#39;"), "\"q\" 's'")
})

.tabular_md <- function(spec, body_rd) {
  rd_text <- paste0(
    "\\name{my_fun}\n\\alias{my_fun}\n\\title{T}\n\\description{D}\n",
    "\\details{\n\\tabular{",
    spec,
    "}{\n",
    body_rd,
    "\n}\n}\n"
  )
  rd <- tools::parse_Rd(textConnection(rd_text))
  .rd_to_block_md(.first_rd_tag_children(rd, "\\details"))
}

test_that(".render_rd_tabular renders a \\tabular{} node as a Markdown table", {
  md <- .tabular_md("ll", "A \\tab B \\cr\nC \\tab D\n")

  expect_equal(md, "| A | B |\n| --- | --- |\n| C | D |")
})

test_that(".render_rd_tabular maps alignment characters to Markdown markers", {
  md <- .tabular_md("lcr", "A \\tab B \\tab C \\cr\nX \\tab Y \\tab Z\n")

  lines <- strsplit(md, "\n")[[1]]
  expect_equal(lines[2], "| --- | :---: | ---: |")
})

test_that("real-world regression: \\tabular{} comparison table renders as a Markdown table", {
  # Reproduces dplyr::dplyr_by()'s ".by vs group_by()" comparison table,
  # previously rendered as one garbled run-on line starting with the raw
  # alignment spec ("ll`.by` `group_by()` ...").
  md <- .tabular_md(
    "ll",
    "\\code{.by} \\tab \\code{group_by()} \\cr\nSingle verb \\tab Persistent\n"
  )

  expect_no_match(md, "^ll", perl = TRUE)
  expect_match(md, "^\\| `\\.by` \\| `group_by\\(\\)` \\|", perl = TRUE)
  expect_match(md, "Single verb")
})

test_that(".render_rd_tabular escapes a literal pipe in cell content", {
  md <- .tabular_md("ll", "A \\tab x | y \\cr\nC \\tab D\n")

  lines <- strsplit(md, "\n")[[1]]
  expect_equal(lines[1], "| A | x \\| y |")
  # the escaped pipe must not be mistaken for a real column separator
  expect_length(strsplit(lines[1], "(?<!\\\\)\\|", perl = TRUE)[[1]], 3)
})

test_that(".render_rd_tabular ignores whitespace/newlines in the alignment spec", {
  md <- .tabular_md("l\nc r", "A \\tab B \\tab C \\cr\nX \\tab Y \\tab Z\n")

  lines <- strsplit(md, "\n")[[1]]
  expect_equal(lines[2], "| --- | :---: | ---: |")
})

.describe_md <- function(body_rd) {
  rd_text <- paste0(
    "\\name{my_fun}\n\\alias{my_fun}\n\\title{T}\n\\description{D}\n",
    "\\details{\n\\describe{\n",
    body_rd,
    "\n}\n}\n"
  )
  rd <- tools::parse_Rd(textConnection(rd_text))
  .rd_to_block_md(.first_rd_tag_children(rd, "\\details"))
}

test_that(".rd_to_block_md renders \\describe{} as a bullet list of term/description pairs", {
  md <- .describe_md("\\item{x}{The x variable.}\n\\item{y}{The y variable.}\n")

  expect_equal(md, "- **x**: The x variable.\n- **y**: The y variable.")
})

test_that(".rd_to_block_md's \\describe{} does not concatenate term and description", {
  # Before \\describe{} support existed, it fell through to the
  # transparent-container path and ran term straight into description with
  # no separator or list markup at all.
  md <- .describe_md("\\item{alpha}{First entry.}")

  expect_no_match(md, "alphaFirst", fixed = TRUE)
  expect_match(md, "\\*\\*alpha\\*\\*: First entry\\.")
})

.value_md <- function(name) {
  rd <- tools::parse_Rd(test_path("fixtures", "value", paste0(name, ".Rd")))
  return(.parse_rd_topic(rd, paste0(name, ".Rd"), "testpkg")$value)
}

test_that("\\value{} renders \\item{name}{desc} entries as a Markdown list", {
  expect_equal(
    .value_md("value_items"),
    paste0(
      "A list with two elements:\n\n",
      "- **`status`**: A string, one of `\"ok\"` or `\"error\"`.\n",
      "- **`issues`**: A character vector of problems."
    )
  )
})

test_that("\\value{} renders an \\itemize{} with bare \\item as a Markdown list", {
  lines <- strsplit(.value_md("check_environment_setup"), "\n")[[1]]
  expect_equal(
    lines,
    c(
      "A list containing environment setup status and recommendations:",
      "",
      "- status: \"ok\", \"warning\", or \"error\".",
      "- issues: Character vector of identified problems.",
      "- recommendations: Character vector of suggested fixes."
    )
  )
})
