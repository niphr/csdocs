.skip_if_cannot_render <- function() {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
}

# Builds the site of the sitepkg fixture. The fixture holds notes.qmd, so
# every build warns about it. Only that warning is muffled here.
.build_fixture_site <- function(out_dir, ...) {
  withCallingHandlers(
    suppressMessages(
      build_site(test_path("fixtures", "sitepkg"), output_dir = out_dir, ...)
    ),
    warning = function(w) {
      if (grepl("Quarto", conditionMessage(w), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

test_that("build_site() front page links the vignette title to articles/intro.md", {
  .skip_if_cannot_render()
  out_dir <- withr::local_tempdir()
  .build_fixture_site(out_dir)

  front <- readLines(fs::path(out_dir, "README.md"))
  expect_equal(front[1], "# sitepkg 0.0.1")
  expect_true("## Articles" %in% front)
  expect_true("- [Introduction to sitepkg](articles/intro.md)" %in% front)
  expect_true("- [Every function and object](reference/README.md)" %in% front)
})

test_that("build_site() renders articles/intro.md with chunk output and a figure", {
  .skip_if_cannot_render()
  out_dir <- withr::local_tempdir()
  .build_fixture_site(out_dir)

  article <- fs::path(out_dir, "articles", "intro.md")
  expect_true(fs::file_exists(article))
  lines <- readLines(article)
  expect_true(any(grepl("^\\s*## \\[1\\] 2$", lines)))
  figures <- fs::dir_ls(
    fs::path(out_dir, "articles"),
    recurse = TRUE,
    glob = "*.png"
  )
  expect_length(figures, 1)
  figure <- fs::path_rel(figures, fs::path(out_dir, "articles"))
  expect_true(any(grepl(figure, lines, fixed = TRUE)))
})

test_that("build_site() writes the reference and leaves no dead links", {
  .skip_if_cannot_render()
  out_dir <- withr::local_tempdir()
  .build_fixture_site(out_dir)

  expect_true(fs::file_exists(fs::path(out_dir, "reference", "README.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "reference", "greet.md")))
  expect_equal(nrow(.find_dead_links(out_dir)), 0)
})

test_that("build_site() deletes the copied .Rmd sources and keeps .qmd files", {
  .skip_if_cannot_render()
  out_dir <- withr::local_tempdir()
  .build_fixture_site(out_dir)

  articles <- list.files(fs::path(out_dir, "articles"), recursive = TRUE)
  expect_false(any(grepl("\\.Rmd(\\.orig)?$", articles)))
  expect_true("notes.qmd" %in% articles)
})

test_that("build_site() warns about each .qmd vignette by name", {
  .skip_if_cannot_render()
  out_dir <- withr::local_tempdir()
  expect_warning(
    suppressMessages(
      build_site(test_path("fixtures", "sitepkg"), output_dir = out_dir)
    ),
    "notes.qmd"
  )
})

test_that("build_site() rejects an installed package name", {
  out_dir <- withr::local_tempdir()
  expect_error(
    suppressMessages(build_site("stats", output_dir = out_dir)),
    "source directory"
  )
})

test_that("build_site() shows 7 characters of GITHUB_SHA", {
  .skip_if_cannot_render()
  withr::local_envvar(GITHUB_SHA = "0123456789abcdef0123456789abcdef01234567")
  out_dir <- withr::local_tempdir()
  .build_fixture_site(out_dir)

  front <- readLines(fs::path(out_dir, "README.md"))
  expect_true("Built from commit `0123456`." %in% front)
})

test_that("build_site() with overwrite = FALSE aborts on a non-empty output_dir", {
  out_dir <- withr::local_tempdir()
  writeLines("x", fs::path(out_dir, "keep.txt"))
  expect_error(
    build_site(
      test_path("fixtures", "sitepkg"),
      output_dir = out_dir,
      overwrite = FALSE
    ),
    "not empty"
  )
  expect_equal(readLines(fs::path(out_dir, "keep.txt")), "x")
})

test_that("build_site() with overwrite = TRUE clears the previous articles", {
  .skip_if_cannot_render()
  out_dir <- withr::local_tempdir()
  fs::dir_create(fs::path(out_dir, "articles"))
  writeLines("# Old", fs::path(out_dir, "articles", "stale.md"))
  .build_fixture_site(out_dir)

  expect_false(fs::file_exists(fs::path(out_dir, "articles", "stale.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "articles", "intro.md")))
})

test_that("build_site() without vignettes writes a front page with no Articles", {
  pkg_dir <- withr::local_tempdir()
  fs::file_copy(
    fs::path(test_path("fixtures", "sitepkg"), c("DESCRIPTION", "NAMESPACE")),
    pkg_dir
  )
  fs::dir_copy(
    fs::path(test_path("fixtures", "sitepkg"), "man"),
    fs::path(pkg_dir, "man")
  )
  out_dir <- withr::local_tempdir()
  suppressMessages(build_site(pkg_dir, output_dir = out_dir))

  front <- readLines(fs::path(out_dir, "README.md"))
  expect_false("## Articles" %in% front)
  expect_false(fs::dir_exists(fs::path(out_dir, "articles")))
  expect_equal(nrow(.find_dead_links(out_dir)), 0)
})
