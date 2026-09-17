[
  # Dialyzer infers `Algoliax.Resources.Task.task/1`'s success type never
  # returns a list, so the `{:ok, responses} when is_list(responses)` clause
  # in `do_wait_task/2` is unreachable as written. Whether this is dead code
  # or masks a real bug in the batch/multi-task polling path needs domain
  # investigation, not a mechanical fix bundled into a CI-tooling change.
  {"lib/algoliax.ex", :guard_fail, 135}
]
