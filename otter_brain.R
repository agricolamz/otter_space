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

appender_tee(file = paste0(getOption("otteRagent_directory"), "logs/logs.txt"),
             max_lines = 1000L,
             max_files = 10L) |>
  log_appender()

check_tasklist()

# test me