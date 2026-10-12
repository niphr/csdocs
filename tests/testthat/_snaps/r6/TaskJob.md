# `TaskJob` — TaskJob R6 Class

**Package:** testpkg · **Version:** 0.0.0

Run a cs9 task in a background R process with live output streaming back to the current R console via `later::later()` polling. Equivalent in spirit to `run_task_sequentially_as_rstudio_job_using_load_all()` but does not depend on RStudio's job API (which Positron does not implement).

Methods:

- $start() spawns the background process and starts to poll its output.
- $wait(t) blocks this session until the task finishes. It drains the event loop while it waits.
- $is_alive() returns TRUE while the background process runs.
- $status() prints a brief status summary.
- $tail(n) prints the last n lines of the log file (a snapshot, not live).
- $kill() terminates the background process.

## Public fields

- **`task_name`**: Character string. Name of the task being run.
- **`ss_prefix`**: Character string. R expression used to access the surveillance system in the child process.
- **`script_path`**: Character string. Path to the temporary R script that is sourced in the background process.
- **`log_path`**: Character string. Path to the log file where background process output is written.
- **`started_at`**: POSIXct. Time at which `$start()` was called.
- **`finished_at`**: POSIXct. Time at which the background process exited.

## Methods

### Public methods

- [`TaskJob$new()`](#method-taskjob-initialize)
- [`TaskJob$start()`](#method-taskjob-start)
- [`TaskJob$is_alive()`](#method-taskjob-is_alive)
- [`TaskJob$status()`](#method-taskjob-status)
- [`TaskJob$wait()`](#method-taskjob-wait)
- [`TaskJob$kill()`](#method-taskjob-kill)
- [`TaskJob$tail()`](#method-taskjob-tail)
- [`TaskJob$clone()`](#method-taskjob-clone)

<a id="method-taskjob-initialize"></a>

### `TaskJob$new()`

Create a new TaskJob.

#### Usage

```
TaskJob$new(
  task_name,
  ss_prefix = "global$ss",
  log_dir = tempdir(check = TRUE)
)
```

#### Arguments

- **`task_name`**: Character string. Name of the task to run, as registered in the surveillance system (e.g. `ss$tasks[["my_task"]]`).
- **`ss_prefix`**: Character string. R expression that evaluates to the surveillance system object in the child process. Defaults to `"global$ss"`.
- **`log_dir`**: Character string. Directory where the temporary script and log file are written. Defaults to `tempdir()`.

#### Returns

A new `TaskJob` object. Call `$start()` to launch the background process.

<a id="method-taskjob-start"></a>

### `TaskJob$start()`

Spawn the background process and start to poll its output.

#### Usage

```
TaskJob$start()
```

#### Returns

Invisibly returns the `TaskJob` object.

<a id="method-taskjob-is_alive"></a>

### `TaskJob$is_alive()`

Check whether the background process is still running.

#### Usage

```
TaskJob$is_alive()
```

#### Returns

Logical. `TRUE` while the background process is alive.

<a id="method-taskjob-status"></a>

### `TaskJob$status()`

Print a brief status summary (task name, start time, alive status, log path).

#### Usage

```
TaskJob$status()
```

#### Returns

Invisibly returns the `TaskJob` object.

<a id="method-taskjob-wait"></a>

### `TaskJob$wait()`

Block the current session until the background task finishes or the timeout expires. This method drains the later event loop while it waits.

#### Usage

```
TaskJob$wait(timeout_s = 600)
```

#### Arguments

- **`timeout_s`**: Numeric. Maximum number of seconds to wait. Defaults to `600` (10 minutes).

#### Returns

Invisibly returns the `TaskJob` object.

<a id="method-taskjob-kill"></a>

### `TaskJob$kill()`

Terminate the background process.

#### Usage

```
TaskJob$kill()
```

#### Returns

Invisibly returns the `TaskJob` object.

<a id="method-taskjob-tail"></a>

### `TaskJob$tail()`

Print the last `n` lines of the task log file (snapshot, not live).

#### Usage

```
TaskJob$tail(n = 20)
```

#### Arguments

- **`n`**: Integer. Number of trailing lines to show. Defaults to `20`.

#### Returns

Invisibly returns the `TaskJob` object.

<a id="method-taskjob-clone"></a>

### `TaskJob$clone()`

The objects of this class are cloneable with this method.

#### Usage

```
TaskJob$clone(deep = FALSE)
```

#### Arguments

- **`deep`**: Whether to make a deep clone.

## Examples

<details>
<summary>Show examples</summary>

```r
job <- TaskJob$new("my_task")
job$start()
job$status()
job$wait(timeout_s = 120)
job$tail(n = 30)
```

</details>


