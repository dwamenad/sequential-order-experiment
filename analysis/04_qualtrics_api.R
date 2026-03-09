#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(jsonlite)
})

args <- commandArgs(trailingOnly = TRUE)

usage <- function() {
  cat(
    "Usage:\n",
    "  Rscript analysis/04_qualtrics_api.R whoami\n",
    "  Rscript analysis/04_qualtrics_api.R export-responses <survey_id> [out_csv]\n\n",
    "Required env vars:\n",
    "  QUALTRICS_API_TOKEN    API token from Qualtrics account settings\n",
    "  QUALTRICS_DATACENTER   Datacenter id (e.g., ca1, yul1, iad1) or full URL\n",
    sep = ""
  )
}

if (length(args) < 1) {
  usage()
  quit(status = 1)
}

cmd <- args[[1]]
api_token <- Sys.getenv("QUALTRICS_API_TOKEN", unset = "")
datacenter <- Sys.getenv("QUALTRICS_DATACENTER", unset = "")

if (api_token == "" || datacenter == "") {
  cat("Missing env var(s). Set QUALTRICS_API_TOKEN and QUALTRICS_DATACENTER.\n")
  quit(status = 1)
}

if (grepl("^https?://", datacenter, ignore.case = TRUE)) {
  base_url <- sub("/$", "", datacenter)
} else {
  base_url <- paste0("https://", datacenter, ".qualtrics.com")
}

run_curl <- function(curl_args) {
  out <- system2("curl", args = curl_args, stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop(sprintf("curl failed (%s): %s", status, paste(out, collapse = "\n")))
  }
  out
}

api_json <- function(method, path, body = NULL, context = "API request") {
  url <- paste0(base_url, path)
  curl_args <- c(
    "-sS",
    "-X", method,
    "-H", paste0("X-API-TOKEN:", api_token),
    "-H", "Content-Type:application/json"
  )

  if (!is.null(body)) {
    curl_args <- c(curl_args, "--data-binary", toJSON(body, auto_unbox = TRUE))
  }

  curl_args <- c(curl_args, "-w", "HTTPSTATUS:%{http_code}", url)
  out <- run_curl(curl_args)

  if (length(out) < 1) stop(sprintf("%s failed: empty response.", context))

  resp_all <- paste(out, collapse = "\n")
  status_code <- suppressWarnings(as.integer(sub(".*HTTPSTATUS:([0-9]{3})\\s*$", "\\1", resp_all)))
  resp_body <- sub("HTTPSTATUS:[0-9]{3}\\s*$", "", resp_all)

  if (is.na(status_code)) {
    stop(sprintf("%s failed: could not parse HTTP status. Raw: %s", context, resp_all))
  }

  if (status_code >= 400) {
    stop(sprintf("%s failed (%s): %s", context, status_code, resp_body))
  }

  if (nchar(trimws(resp_body)) == 0) return(list())
  fromJSON(resp_body, simplifyVector = FALSE)
}

api_download <- function(path, dest_file, context = "download") {
  url <- paste0(base_url, path)
  dir.create(dirname(dest_file), recursive = TRUE, showWarnings = FALSE)

  out <- run_curl(c(
    "-sS",
    "-L",
    "-H", paste0("X-API-TOKEN:", api_token),
    "-o", dest_file,
    "-w", "HTTPSTATUS:%{http_code}",
    url
  ))

  out_all <- paste(out, collapse = "\n")
  status_code <- suppressWarnings(as.integer(sub(".*HTTPSTATUS:([0-9]{3})\\s*$", "\\1", out_all)))
  if (is.na(status_code) || status_code >= 400) {
    stop(sprintf("%s failed (%s)", context, ifelse(is.na(status_code), "unknown", status_code)))
  }
}

run_whoami <- function() {
  data <- api_json("GET", "/API/v3/whoami", context = "whoami")
  cat("Connected to Qualtrics API.\n")
  if (!is.null(data$result$userName)) cat("User: ", data$result$userName, "\n", sep = "")
  if (!is.null(data$result$accountId)) cat("Account ID: ", data$result$accountId, "\n", sep = "")
  if (!is.null(data$result$datacenterId)) cat("Datacenter: ", data$result$datacenterId, "\n", sep = "")
}

poll_export <- function(survey_id, progress_id, poll_seconds = 2, max_polls = 120) {
  for (i in seq_len(max_polls)) {
    body <- api_json(
      "GET",
      sprintf("/API/v3/surveys/%s/export-responses/%s", survey_id, progress_id),
      context = "poll export"
    )

    status <- body$result$status

    if (status == "complete") {
      return(body$result$fileId)
    }
    if (status %in% c("failed", "cancelled")) {
      stop(sprintf("Export failed with status: %s", status))
    }

    cat(sprintf("Export status: %s (poll %d/%d)\n", status, i, max_polls))
    Sys.sleep(poll_seconds)
  }

  stop("Timed out waiting for export to complete.")
}

run_export <- function(survey_id, out_csv) {
  dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)

  start_body <- api_json(
    "POST",
    sprintf("/API/v3/surveys/%s/export-responses", survey_id),
    body = list(format = "csv", useLabels = TRUE),
    context = "start export"
  )

  progress_id <- start_body$result$progressId
  if (is.null(progress_id) || progress_id == "") {
    stop("No progressId returned by Qualtrics export endpoint.")
  }

  cat("Started export. Progress ID: ", progress_id, "\n", sep = "")
  file_id <- poll_export(survey_id, progress_id)
  cat("Export complete. File ID: ", file_id, "\n", sep = "")

  tmp_zip <- tempfile(fileext = ".zip")
  api_download(
    sprintf("/API/v3/surveys/%s/export-responses/%s/file", survey_id, file_id),
    dest_file = tmp_zip,
    context = "download export file"
  )

  unzip_dir <- tempfile(pattern = "qualtrics_export_")
  dir.create(unzip_dir, recursive = TRUE, showWarnings = FALSE)
  unzip(tmp_zip, exdir = unzip_dir)

  csv_files <- list.files(unzip_dir, pattern = "\\.csv$", full.names = TRUE)
  if (length(csv_files) < 1) {
    stop("No CSV found inside downloaded export ZIP.")
  }

  file.copy(csv_files[[1]], out_csv, overwrite = TRUE)
  cat("Saved CSV to: ", out_csv, "\n", sep = "")

  # quick read check
  test <- tryCatch(utils::read.csv(out_csv, nrows = 5), error = function(e) NULL)
  if (!is.null(test)) {
    cat("Read check passed.\n")
  }
}

if (cmd == "whoami") {
  run_whoami()
} else if (cmd == "export-responses") {
  if (length(args) < 2) {
    cat("Missing survey_id.\n")
    usage()
    quit(status = 1)
  }
  survey_id <- args[[2]]
  out_csv <- ifelse(length(args) >= 3, args[[3]], "data/raw/qualtrics_export.csv")
  run_export(survey_id, out_csv)
} else {
  cat("Unknown command: ", cmd, "\n", sep = "")
  usage()
  quit(status = 1)
}
