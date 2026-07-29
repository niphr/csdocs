.write_fixture_package <- function(pkg_dir, name = "fixturepkg", version = "0.1.0") {
  writeLines(
    c(
      glue::glue("Package: {name}"),
      "Title: Fixture Package",
      glue::glue("Version: {version}"),
      "License: MIT"
    ),
    fs::path(pkg_dir, "DESCRIPTION")
  )
  writeLines(c("export(foo)", "export(bar)"), fs::path(pkg_dir, "NAMESPACE"))
  fs::dir_create(fs::path(pkg_dir, "man"))
  writeLines(
    "\\name{foo}\n\\alias{foo}\n\\title{Foo}\n\\description{Does foo.}\n\\usage{foo(x)}\n",
    fs::path(pkg_dir, "man", "foo.Rd")
  )
  writeLines(
    "\\name{bar}\n\\alias{bar}\n\\title{Bar}\n\\description{Does bar.}\n\\usage{bar(x)}\n",
    fs::path(pkg_dir, "man", "bar.Rd")
  )
}

.write_fixture_package_with_private <- function(pkg_dir, name = "fixturepkg", version = "0.1.0") {
  .write_fixture_package(pkg_dir, name = name, version = version)
  # bar is documented but never exported - a private helper.
  writeLines("export(foo)", fs::path(pkg_dir, "NAMESPACE"))
}

test_that(".read_package_metadata reads name/version from DESCRIPTION for source packages", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir, name = "fixturepkg", version = "1.2.3")

  meta <- .read_package_metadata(pkg_dir)

  expect_equal(meta$name, "fixturepkg")
  expect_equal(meta$version, "1.2.3")
})

test_that(".read_package_metadata reads name/version for installed packages", {
  meta <- .read_package_metadata("methods")

  expect_equal(meta$name, "methods")
  expect_true(nzchar(meta$version))
})

test_that(".build_topics drops unnamed topics and sorts by name", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  db <- .read_rd_db_source(pkg_dir)

  topics <- .build_topics(db, "fixturepkg")

  expect_equal(unname(purrr::map_chr(topics, "name")), c("bar", "foo"))
  expect_true(all(purrr::map_chr(topics, "package") == "fixturepkg"))
})

test_that("build_reference() writes one file per topic plus README and _full_reference", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir)

  expect_true(fs::file_exists(fs::path(out_dir, "foo.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "bar.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "README.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "_full_reference.md")))

  readme <- readLines(fs::path(out_dir, "README.md"))
  expect_true(any(grepl("foo.md", readme, fixed = TRUE)))
  expect_true(any(grepl("bar.md", readme, fixed = TRUE)))

  full_ref <- readLines(fs::path(out_dir, "_full_reference.md"))
  expect_true(any(grepl("# `foo\\(\\)`", full_ref)))
  expect_true(any(grepl("# `bar\\(\\)`", full_ref)))
})

test_that("build_reference() with overwrite = FALSE aborts if .md files already exist", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir)

  expect_error(
    build_reference(pkg_dir, output_dir = out_dir, overwrite = FALSE),
    class = "rlang_error"
  )
})

test_that("build_reference() with overwrite = TRUE (default) re-renders without error", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir)
  expect_no_error(build_reference(pkg_dir, output_dir = out_dir))
})

test_that("build_reference() overwrite = TRUE removes stale .md files from a previous build", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir)
  # Simulate a topic that existed in a previous build but was since renamed
  # or removed from the package - this must not survive a re-build.
  writeLines("stale content", fs::path(out_dir, "stale_topic.md"))

  build_reference(pkg_dir, output_dir = out_dir)

  expect_false(fs::file_exists(fs::path(out_dir, "stale_topic.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "foo.md")))
})

test_that("build_reference() include_private = TRUE (default) includes and flags private topics", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package_with_private(pkg_dir)
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir)

  expect_true(fs::file_exists(fs::path(out_dir, "bar.md")))
  bar_md <- readLines(fs::path(out_dir, "bar.md"))
  expect_true(any(grepl("_(private)_", bar_md, fixed = TRUE)))

  foo_md <- readLines(fs::path(out_dir, "foo.md"))
  expect_false(any(grepl("_(private)_", foo_md, fixed = TRUE)))

  readme <- readLines(fs::path(out_dir, "README.md"))
  expect_true(any(grepl("bar.md) _(private)_", readme, fixed = TRUE)))
})

test_that("build_reference() include_private = FALSE excludes private topics entirely", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package_with_private(pkg_dir)
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir, include_private = FALSE)

  expect_false(fs::file_exists(fs::path(out_dir, "bar.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "foo.md")))

  readme <- readLines(fs::path(out_dir, "README.md"))
  expect_false(any(grepl("bar", readme, fixed = TRUE)))
})

test_that("build_reference() treats every topic as public when NAMESPACE is unknown", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  fs::file_delete(fs::path(pkg_dir, "NAMESPACE"))
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir, include_private = FALSE)

  expect_true(fs::file_exists(fs::path(out_dir, "foo.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "bar.md")))
})

test_that(".check_topic_name_collisions aborts when a topic name collides with a generated meta file", {
  topics <- list(list(name = "README", aliases = character(0)))
  expect_error(.check_topic_name_collisions(topics), class = "rlang_error")

  topics2 <- list(list(name = "_full_reference", aliases = character(0)))
  expect_error(.check_topic_name_collisions(topics2), class = "rlang_error")
})

test_that(".check_topic_name_collisions aborts on case-insensitive filename duplicates", {
  topics <- list(
    list(name = "Foo", aliases = character(0)),
    list(name = "foo", aliases = character(0))
  )
  expect_error(.check_topic_name_collisions(topics), class = "rlang_error")
})

test_that(".check_topic_name_collisions passes through distinct topic names", {
  topics <- list(
    list(name = "foo", aliases = character(0)),
    list(name = "bar", aliases = character(0))
  )
  expect_no_error(.check_topic_name_collisions(topics))
})

test_that("build_reference() works against an installed package", {
  out_dir <- withr::local_tempdir()

  build_reference("methods", output_dir = out_dir)

  expect_true(fs::file_exists(fs::path(out_dir, "as.md")))
  expect_true(fs::file_exists(fs::path(out_dir, "README.md")))
})

test_that("build_reference() defaults package to \".\" and output_dir to \"md-docs\"", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  withr::local_dir(pkg_dir)

  build_reference()

  expect_true(fs::file_exists(fs::path(pkg_dir, "md-docs", "foo.md")))
  expect_true(fs::file_exists(fs::path(pkg_dir, "md-docs", "README.md")))
})

test_that("build_reference() output_dir default applies only to source packages", {
  expect_error(
    build_reference("methods"),
    class = "rlang_error"
  )
})

test_that(".resolve_output_dir passes an explicit output_dir through unchanged", {
  expect_equal(.resolve_output_dir("methods", "custom-dir"), "custom-dir")
})

test_that(".resolve_output_dir defaults to \"md-docs\" for a source package", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)

  expect_equal(.resolve_output_dir(pkg_dir, NULL), "md-docs")
})

test_that(".resolve_output_dir aborts with a clear message for an installed package", {
  expect_error(.resolve_output_dir("methods", NULL), class = "rlang_error")
})

test_that("get_documentation() returns the same content as _full_reference.md, without writing files", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  out_dir <- withr::local_tempdir()

  build_reference(pkg_dir, output_dir = out_dir, include_private = FALSE)
  full_ref <- paste(readLines(fs::path(out_dir, "_full_reference.md")), collapse = "\n")

  fresh_dir <- withr::local_tempdir()
  expect_equal(list.files(fresh_dir), character(0))
  withr::local_dir(fresh_dir)

  docs <- get_documentation(pkg_dir)

  expect_equal(docs, full_ref)
  expect_equal(list.files(fresh_dir), character(0))
})

test_that("get_documentation() defaults include_private to FALSE, excluding private topics", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package_with_private(pkg_dir)

  docs <- get_documentation(pkg_dir)

  expect_true(grepl("# `foo\\(\\)`", docs))
  expect_false(grepl("# `bar\\(\\)`", docs))
})

test_that("get_documentation() include_private = TRUE includes private topics", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package_with_private(pkg_dir)

  docs <- get_documentation(pkg_dir, include_private = TRUE)

  expect_true(grepl("# `foo\\(\\)`", docs))
  expect_true(grepl("# `bar\\(\\)`", docs))
})

test_that("get_documentation() works against an installed package", {
  docs <- get_documentation("methods")

  expect_true(grepl("methods — Full Reference", docs, fixed = TRUE))
  expect_true(nchar(docs) > 0)
})

test_that("get_documentation() defaults package to \".\"", {
  pkg_dir <- withr::local_tempdir()
  .write_fixture_package(pkg_dir)
  withr::local_dir(pkg_dir)

  docs <- get_documentation()

  expect_true(grepl("fixturepkg — Full Reference", docs, fixed = TRUE))
})
