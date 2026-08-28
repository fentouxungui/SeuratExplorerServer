# comments.R
# A simple comment board: read/write comments to a CSV file with a file lock.

# Column names of the comments table
.comments_columns <- function() {
  c("id", "user_id", "user_id_optional", "sample_id", "content",
    "created_at", "reply_to", "is_resolved", "deleted")
}

# Read comments from a CSV file. Returns an empty data.frame with the correct
# columns when the file does not exist yet.
load_comments <- function(comments_file) {
  cols <- .comments_columns()
  if (!file.exists(comments_file)) {
    return(data.frame(
      id = integer(),
      user_id = character(),
      user_id_optional = character(),
      sample_id = character(),
      content = character(),
      created_at = character(),
      reply_to = character(),
      is_resolved = logical(),
      deleted = logical(),
      stringsAsFactors = FALSE
    ))
  }
  df <- utils::read.csv(comments_file, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  # read.csv may drop all-empty columns; restore the full schema
  for (col in setdiff(cols, names(df))) {
    df[[col]] <- NA
  }
  df <- df[cols]
  df$id <- suppressWarnings(as.integer(df$id))
  df$is_resolved <- as.logical(df$is_resolved)
  df$deleted <- as.logical(df$deleted)
  df
}

# Write comments atomically (temp file + rename) so concurrent readers never
# observe a partially-written file.
.save_comments <- function(comments_file, df) {
  tmp <- paste0(comments_file, ".tmp")
  utils::write.csv(df, tmp, row.names = FALSE, fileEncoding = "UTF-8")
  if (!file.rename(tmp, comments_file)) {
    file.copy(tmp, comments_file, overwrite = TRUE)
    file.remove(tmp)
  }
  invisible(comments_file)
}

# Append a new comment under a file lock.
add_comment <- function(comments_file, user_id, user_id_optional, sample_id,
                        content, reply_to = "") {
  lck <- filelock::lock(paste0(comments_file, ".lock"), timeout = 10000)
  on.exit(filelock::unlock(lck), add = TRUE)
  df <- load_comments(comments_file)
  new_id <- if (nrow(df) == 0) 1L else max(df$id, na.rm = TRUE) + 1L
  new_row <- data.frame(
    id = new_id,
    user_id = as.character(user_id),
    user_id_optional = as.character(user_id_optional),
    sample_id = as.character(sample_id),
    content = as.character(content),
    created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    reply_to = as.character(reply_to),
    is_resolved = FALSE,
    deleted = FALSE,
    stringsAsFactors = FALSE
  )
  df <- rbind(df, new_row)
  .save_comments(comments_file, df)
  invisible(new_id)
}

# Update the `is_resolved` / `deleted` flags of a comment under a file lock.
update_comment <- function(comments_file, id, is_resolved = NULL, deleted = NULL) {
  lck <- filelock::lock(paste0(comments_file, ".lock"), timeout = 10000)
  on.exit(filelock::unlock(lck), add = TRUE)
  df <- load_comments(comments_file)
  idx <- which(df$id == id)
  if (length(idx) == 0) {
    return(invisible(FALSE))
  }
  if (!is.null(is_resolved)) {
    df$is_resolved[idx] <- isTRUE(is_resolved)
  }
  if (!is.null(deleted)) {
    df$deleted[idx] <- isTRUE(deleted)
  }
  .save_comments(comments_file, df)
  invisible(TRUE)
}
