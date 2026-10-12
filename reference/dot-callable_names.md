# Determine which of a topic's name/aliases are actually callable

A topic is "callable" for heading purposes if its own name (or one of
its aliases) literally appears followed by `(` in its `\\usage{}` block

- e.g. `mutate.Rd` has usage `mutate(.data, ...)`, so `"mutate"`
  qualifies. Datasets and concept pages (`\\usage{}` is just a bare
  name, or empty) never qualify. A single Rd topic can document several
  callables at once (e.g. `lead-lag.Rd` documents both `lead()` and
  [`lag()`](https://rdrr.io/r/stats/lag.html), with topic name
  `"lead-lag"` matching neither) - hence this returns a vector, not a
  single yes/no.

## Usage

``` r
.callable_names(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

Character vector of callable names (possibly empty).
