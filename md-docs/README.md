# pkgmd — Reference

**Version:** 0.1

Full context for LLMs: [`_full_reference.md`](_full_reference.md)

| Topic | Description | Aliases |
|-------|-------------|---------|
| [`.build_topics()`](dot-build_topics.md) _(private)_ | Parse every entry of an Rd database into topic lists |  |
| [`.callable_candidates()`](dot-callable_candidates.md) _(private)_ | Determine which of a topic's name/aliases actually look callable |  |
| [`.callable_names()`](dot-callable_names.md) _(private)_ | Determine which of a topic's name/aliases are actually callable |  |
| [`.check_existing_output()`](dot-check_existing_output.md) _(private)_ | Abort if `output_dir` already contains `.md` files |  |
| [`.check_topic_name_collisions()`](dot-check_topic_name_collisions.md) _(private)_ | Abort if two topics would collide on the filesystem |  |
| [`.clear_generated_output()`](dot-clear_generated_output.md) _(private)_ | Remove every `.md` file already in `output_dir` |  |
| [`.code_fence()`](dot-code_fence.md) _(private)_ | Pick a backtick fence long enough to safely wrap some code |  |
| [`.collapse_whitespace()`](dot-collapse_whitespace.md) _(private)_ | Collapse a prose string to a single line |  |
| [`.compute_is_private()`](dot-compute_is_private.md) _(private)_ | Decide whether a topic counts as "private" (not part of the public API) |  |
| [`.decode_html_entities()`](dot-decode_html_entities.md) _(private)_ | Decode the handful of HTML entities that show up in Rd \\out{} blocks |  |
| [`.detect_source_code_lang()`](dot-detect_source_code_lang.md) _(private)_ | Detect a `class="sourceCode <lang>"` marker in raw HTML, if present |  |
| [`.escape_table_pipe()`](dot-escape_table_pipe.md) _(private)_ | Escape literal pipe characters for use in a GFM table cell |  |
| [`.first_rd_tag_children()`](dot-first_rd_tag_children.md) _(private)_ | Get the children of the first Rd node matching a tag |  |
| [`.get_rd_tag()`](dot-get_rd_tag.md) _(private)_ | Extract all child tags of a given type from an Rd object |  |
| [`.if_out_html_block()`](dot-if_out_html_block.md) _(private)_ | Detect a block-level \\if{html}{\out{...}} HTML code block, if `x` is one |  |
| [`.inline_code_span()`](dot-inline_code_span.md) _(private)_ | Wrap text in an inline code span, widening delimiters to avoid collision |  |
| [`.is_source_path()`](dot-is_source_path.md) _(private)_ | Detect whether `package` refers to a local package source directory |  |
| [`.leaf_or_list_raw_text()`](dot-leaf_or_list_raw_text.md) _(private)_ | Render one Rd child that may be a bare leaf or a list, as raw text |  |
| [`.leaf_or_list_text()`](dot-leaf_or_list_text.md) _(private)_ | Render one Rd child that may be a bare leaf or a list, as inline text |  |
| [`.leaf_rd_text()`](dot-leaf_rd_text.md) _(private)_ | Coerce a single (non-list) Rd node to a scalar string |  |
| [`.looks_callable()`](dot-looks_callable.md) _(private)_ | Decide whether one name looks callable given a topic's usage text |  |
| [`.normalize_block_whitespace()`](dot-normalize_block_whitespace.md) _(private)_ | Collapse a block of prose to paragraphs, preserving paragraph breaks |  |
| [`.parse_namespace_exports()`](dot-parse_namespace_exports.md) _(private)_ | Parse `export(...)` directives out of a `NAMESPACE` file |  |
| [`.parse_rd_aliases()`](dot-parse_rd_aliases.md) _(private)_ | Extract all \\alias{} entries of an Rd object |  |
| [`.parse_rd_arguments()`](dot-parse_rd_arguments.md) _(private)_ | Extract \\arguments{} as a list of name/description pairs |  |
| [`.parse_rd_examples()`](dot-parse_rd_examples.md) _(private)_ | Extract the \\examples{} block as a code string |  |
| [`.parse_rd_from_roxygen_topic()`](dot-parse_rd_from_roxygen_topic.md) _(private)_ | Parse one in-memory roxygen2 `RdFile` topic into an `Rd` object |  |
| [`.parse_rd_name()`](dot-parse_rd_name.md) _(private)_ | Resolve a topic's name, preferring its \\name{} tag |  |
| [`.parse_rd_sections()`](dot-parse_rd_sections.md) _(private)_ | Extract all \\section{title}{body} blocks of an Rd object |  |
| [`.parse_rd_topic()`](dot-parse_rd_topic.md) _(private)_ | Parse a single Rd object into an internal list |  |
| [`.parse_rd_usage()`](dot-parse_rd_usage.md) _(private)_ | Extract the \\usage{} block as preformatted code |  |
| [`.rd_inline_piece()`](dot-rd_inline_piece.md) _(private)_ | Render one Rd child node as an inline Markdown piece |  |
| [`.rd_raw_piece()`](dot-rd_raw_piece.md) _(private)_ | Render one Rd child node as raw text (no whitespace/inline formatting) |  |
| [`.rd_to_block_md()`](dot-rd_to_block_md.md) _(private)_ | Render a list of Rd block-level children as multi-paragraph Markdown |  |
| [`.rd_to_raw_text()`](dot-rd_to_raw_text.md) _(private)_ | Flatten an Rd fragment to raw, unnormalized text |  |
| [`.rd_to_text()`](dot-rd_to_text.md) _(private)_ | Flatten an Rd text fragment into a single string, with inline Markdown |  |
| [`.read_exported_names()`](dot-read_exported_names.md) _(private)_ | Determine a package's exported names, for flagging private topics |  |
| [`.read_exported_names_installed()`](dot-read_exported_names_installed.md) _(private)_ | Determine an installed package's exported names via its namespace |  |
| [`.read_exported_names_source()`](dot-read_exported_names_source.md) _(private)_ | Determine a source package's exported names from its `NAMESPACE` file |  |
| [`.read_package_metadata()`](dot-read_package_metadata.md) _(private)_ | Resolve package name and version, for either an installed or a source package |  |
| [`.read_rd_db()`](dot-read_rd_db.md) _(private)_ | Read the Rd documentation of a package, installed or in development |  |
| [`.read_rd_db_installed()`](dot-read_rd_db_installed.md) _(private)_ | Read the Rd database of an installed package |  |
| [`.read_rd_db_source()`](dot-read_rd_db_source.md) _(private)_ | Read the Rd documentation of a package straight from its source tree |  |
| [`.render_aliases_line()`](dot-render_aliases_line.md) _(private)_ | Render a compact "Aliases:" line for aliases not already in the heading |  |
| [`.render_arguments_section()`](dot-render_arguments_section.md) _(private)_ | Render the arguments table, if present |  |
| [`.render_author_section()`](dot-render_author_section.md) _(private)_ | Render the author section, if present |  |
| [`.render_description_section()`](dot-render_description_section.md) _(private)_ | Render the description section, if present |  |
| [`.render_details_section()`](dot-render_details_section.md) _(private)_ | Render the details section, if present |  |
| [`.render_examples_section()`](dot-render_examples_section.md) _(private)_ | Render the examples section as a <details> block, if present |  |
| [`.render_format_section()`](dot-render_format_section.md) _(private)_ | Render the format section, if present |  |
| [`.render_full_reference_md()`](dot-render_full_reference_md.md) _(private)_ | Render every topic into a single Markdown string |  |
| [`.render_index_md()`](dot-render_index_md.md) _(private)_ | Render the `README.md` index file for a reference output directory |  |
| [`.render_note_section()`](dot-render_note_section.md) _(private)_ | Render the note section, if present |  |
| [`.render_private_badge()`](dot-render_private_badge.md) _(private)_ | Render a _(private)_ marker for topics outside the public API |  |
| [`.render_rd_describe()`](dot-render_rd_describe.md) _(private)_ | Render a \\describe{} node as a Markdown definition-style bullet list |  |
| [`.render_rd_enumerate()`](dot-render_rd_enumerate.md) _(private)_ | Render an \\enumerate{} node as a Markdown numbered list |  |
| [`.render_rd_figure_alt()`](dot-render_rd_figure_alt.md) _(private)_ | Render one \\figure{file}{options} node as its alt text, if any |  |
| [`.render_rd_itemize()`](dot-render_rd_itemize.md) _(private)_ | Render an \\itemize{} node as a Markdown bullet list |  |
| [`.render_rd_out_as_code()`](dot-render_rd_out_as_code.md) _(private)_ | Render an \\out{} node's raw HTML as a fenced Markdown code block |  |
| [`.render_rd_preformatted()`](dot-render_rd_preformatted.md) _(private)_ | Render a \\preformatted{} node as a fenced Markdown code block |  |
| [`.render_rd_subsection()`](dot-render_rd_subsection.md) _(private)_ | Render a \\subsection{title}{body} node as a Markdown heading + body |  |
| [`.render_rd_tabular()`](dot-render_rd_tabular.md) _(private)_ | Render a \\tabular{spec}{body} node as a Markdown table |  |
| [`.render_references_section()`](dot-render_references_section.md) _(private)_ | Render the references section, if present |  |
| [`.render_sections()`](dot-render_sections.md) _(private)_ | Render every \\section{title}{body} block, if any |  |
| [`.render_seealso_section()`](dot-render_seealso_section.md) _(private)_ | Render the related-functions section, if present |  |
| [`.render_source_section()`](dot-render_source_section.md) _(private)_ | Render the source section, if present |  |
| [`.render_topic_heading()`](dot-render_topic_heading.md) _(private)_ | Render a topic's heading identifier (the part before " - Title") |  |
| [`.render_topic_md()`](dot-render_topic_md.md) _(private)_ | Render a parsed Rd topic as a Markdown string |  |
| [`.render_usage_section()`](dot-render_usage_section.md) _(private)_ | Render the usage section, if present |  |
| [`.render_value_section()`](dot-render_value_section.md) _(private)_ | Render the return-value section, if present |  |
| [`.resolve_output_dir()`](dot-resolve_output_dir.md) _(private)_ | Resolve `output_dir`, applying the source-package-only default |  |
| [`.safe_filename()`](dot-safe_filename.md) _(private)_ | Make a function/topic name safe for use as a filename |  |
| [`.split_rd_items()`](dot-split_rd_items.md) _(private)_ | Split the children of an \\itemize{}/\\enumerate{} node into items |  |
| [`.split_rd_table_cells()`](dot-split_rd_table_cells.md) _(private)_ | Split one table row's children into cells |  |
| [`.split_rd_table_rows()`](dot-split_rd_table_rows.md) _(private)_ | Split the children of a \\tabular{}{} node's body into rows |  |
| [`.strip_html_tags()`](dot-strip_html_tags.md) _(private)_ | Strip HTML tags from a string |  |
| [`.write_full_reference_file()`](dot-write_full_reference_file.md) _(private)_ | Write _full_reference.md (every topic in a single file) |  |
| [`.write_index_file()`](dot-write_index_file.md) _(private)_ | Write the `README.md` index file |  |
| [`.write_topic_file()`](dot-write_topic_file.md) _(private)_ | Write the Markdown file for a single topic |  |
| [`.write_utf8_lines()`](dot-write_utf8_lines.md) _(private)_ | Write text to a file as UTF-8, regardless of the platform's locale |  |
| [`build_reference()`](build_reference.md) | Generate Markdown reference documentation for a package |  |
| [`get_documentation()`](get_documentation.md) | Get a package's full reference documentation as a single string |  |
| [`%||%()`](op-null-default.md) _(private)_ | Default for `NULL` values |  |

