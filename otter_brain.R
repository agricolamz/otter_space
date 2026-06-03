suppressPackageStartupMessages(library(tidyverse))
library(logger)
library(otteRagent)

args <- commandArgs(trailingOnly=TRUE)

if(length(args) == 0) {
  loglevel <- "INFO"
} else {
  loglevel <- args[[1]]
}

as.loglevel(loglevel) |>
  log_threshold()

appender_tee(file = getOption("otteRagent_path_to_logs"),
             max_lines = 1000L,
             max_files = 10L) |>
  log_appender()

log_info("📋  Начало сессии. Читаю список задач")

path_to_tasks <- getOption("otteRagent_path_to_tasks")

path_to_tasks |>
  read_csv(show_col_types = FALSE,
           progress = FALSE,
           col_types = list(
             id = "d",
             task = "c",
             skill = "c",
             schedule = "c",
             ignore = "c",
             params = "c")) |>
  filter(is.na(ignore)) |>
  mutate(schedule = if_else(is.na(schedule), "", schedule)) ->
  tasks

if(sum(duplicated(tasks$id)) > 0) {
  log_info("🧮  Обнаружены повторяющиеся индексы, переиндексирую список задач")

  path_to_tasks |>
    read_csv(show_col_types = FALSE,
             progress = FALSE) |>
    mutate(id = 1:n()) |>
    write_csv(file = path_to_tasks, na = "")

  path_to_tasks |>
    read_csv(show_col_types = FALSE,
             progress = FALSE) |>
    filter(is.na(ignore)) ->
    tasks
}

n_tasks <- nrow(tasks)

log_info("🦦  Количество задач в файле: {n_tasks}")

seq_along(tasks$id) |>
  walk(function(task_id){

    run_task(task = tasks$task[task_id],
             skill = tasks$skill[task_id],
             schedule = tasks$schedule[task_id],
             params = tasks$params[task_id],
             task_id = task_id,
             path_to_tasks = path_to_tasks)
  })

log_info("🧮  Задачи выполнены, переиндексирую список задач")

path_to_tasks |>
  read_csv(show_col_types = FALSE,
           progress = FALSE,
           col_types = list(
             id = "d",
             task = "c",
             skill = "c",
             schedule = "c",
             ignore = "c",
             params = "c")) |>
  nrow() ->
  n_tasks

if(n_tasks > 0) {
  path_to_tasks |>
    read_csv(show_col_types = FALSE,
             progress = FALSE,
             col_types = list(
               id = "d",
               task = "c",
               skill = "c",
               schedule = "c",
               ignore = "c",
               params = "c")) |>
    mutate(id = 1:n()) |>
    write_csv(file = path_to_tasks, na = "")
}

log_info("🏁  Конец сессии.")
