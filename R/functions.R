#' Check and arrange the data in the metadata
#'
#' @param parameters a dataframe of the sample metadata info
#' @param supported_file_types file types to included in reports
#'
#' @return dataframe: a check passed metadata
#' @export
#'
#' @examples
#' library(SeuratExplorerServer)
#' data_meta <- initialize_metadata(Reports.main = c(
#' system.file("extdata/source-data", "fly", package ="SeuratExplorerServer"),
#' system.file("extdata/source-data", "mouse", package ="SeuratExplorerServer")),
#' Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"),
#' Reports.second = c(NA, NA), Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT",
#' "Mouse-Intestine-scRNAseq-Haber"))
#' invisible(check_metadata(parameters = data_meta))
check_metadata <- function(parameters, supported_file_types =  c("rds", "qs2")){
  # check the path of rds or qs2 file
  parameters$Rds.full.path <- paste(parameters$Reports.main, parameters$Rds.path,sep = "/")
   if (!all(file.exists(parameters$Rds.full.path))) {
    stop("Please contact data curator to report this error, this error is related to the Reports.main and Rds.path columns in data meta!")
  }else{
    format.object_size <- getFromNamespace('format.object_size', 'utils')
    parameters$Rds.File.size <- sapply(file.size(parameters$Rds.full.path), function(x)format.object_size(x, "auto"))
    # check Reports.second directory exits
    second_dirs <- as.vector(na.omit(parameters$Reports.second))
    if (length(second_dirs) > 0) {
      if (!all(dir.exists(second_dirs))) {
        # plan: change stop() to showModal(), do not end the session!
        stop("Please contact data curator to report this error! this error is related to the second_dirs column in data meta!")
      }
    }

    # check sample name
    postfix_pattern_to_be_removed <- paste0("(.", paste0(supported_file_types, collapse = "$)|("), "$)")
    # if all Sample.name not exist, use filename without postfix
    if (any(is.na(parameters$Sample.name))) {
      parameters$Sample.name[is.na(parameters$Sample.name)] <- gsub(postfix_pattern_to_be_removed, basename(parameters$Rds.path[is.na(parameters$Sample.name)]), ignore.case = TRUE)
    }
    # arrange by main directory
    parameters <- parameters[order(parameters$Reports.main),]
    return(parameters)
  }
}

prepare_reports <- function(reports_dir,
                           data_meta,
                           file_types_included = c("pdf", "tiff", "tif", "jpeg", "gif",
                                                   "jpg", "png", "bmp", "svg", "html", "mp4", "avi"),
                           overwrite = FALSE,
                           create_dirs = TRUE,
                           use_relative_links = FALSE,
                           conflict_resolution = c("rename", "error", "skip", "prefix_sample")) {

  # Match argument
  conflict_resolution <- match.arg(conflict_resolution)

  # Input validation
  if (!dir.exists(reports_dir)) {
    stop("'reports_dir' does not exist: ", reports_dir)
  }

  if (!is.data.frame(data_meta) ||
      !all(c("Reports.main", "Sample.name") %in% names(data_meta))) {
    stop("'data_meta' must be a data.frame with 'Reports.main' and 'Sample.name' columns")
  }

  # Check if Reports.second column exists
  has_second <- "Reports.second" %in% names(data_meta)

  # Validate file types
  file_types_included <- tolower(file_types_included)
  file.types.pattern <- paste0("(\\.", paste0(file_types_included, collapse = "$)|(\\."), "$)")

  # Helper function to sanitize filenames
  sanitize_filename <- function(name) {
    # Replace invalid characters with underscore
    # Note: Using rawToChar and chartr to avoid null character in source code
    invalid_chars <- '[<>:"/\\\\|?*]'
    gsub(invalid_chars, '_', name, perl = TRUE)
  }

  # Helper function to create directory if needed
  ensure_dir_exists <- function(path) {
    if (!dir.exists(path)) {
      if (create_dirs) {
        dir.create(path, recursive = TRUE, showWarnings = FALSE)
        if (!dir.exists(path)) {
          warning("Failed to create directory: ", path)
          return(FALSE)
        }
      } else {
        warning("Directory does not exist and create_dirs=FALSE: ", path)
        return(FALSE)
      }
    }
    return(TRUE)
  }

  # Helper function to check if file is already a symlink
  is_symlink <- function(path) {
    tryCatch({
      file.exists(path) && file.info(path)$islnk
    }, error = function(e) FALSE)
  }

  # Helper function to resolve filename conflicts
  resolve_conflict <- function(target_path, conflict_resolution, sample_name = "") {
    if (!file.exists(target_path)) {
      return(target_path)
    }

    switch(conflict_resolution,
      "error" = {
        stop("File already exists: ", target_path, ". Use overwrite=TRUE or change conflict_resolution")
      },
      "skip" = {
        warning("Skipping existing file: ", target_path)
        return(NA)
      },
      "rename" = {
        # Add numeric suffix
        counter <- 1
        dir_path <- dirname(target_path)
        base_name <- basename(target_path)
        while (file.exists(target_path)) {
          new_name <- sub("(\\.[^.]+)$", paste0("_", counter, "\\1"), base_name)
          target_path <- file.path(dir_path, new_name)
          counter <- counter + 1
        }
        return(target_path)
      },
      "prefix_sample" = {
        # Add sample name prefix
        dir_path <- dirname(target_path)
        base_name <- basename(target_path)
        new_name <- paste0(sample_name, "_", base_name)
        return(file.path(dir_path, new_name))
      }
    )
  }

  # Track statistics
  # stats <- list(
  #   total_files = 0,
  #   successful_links = 0,
  #   skipped_files = 0,
  #   failed_links = 0,
  #   conflicts = 0
  # )

  stats <- new.env(parent = emptyenv())
  stats$total_files <- 0L
  stats$successful_links <- 0L
  stats$skipped_files <- 0L
  stats$failed_links <- 0L
  stats$conflicts <- 0L

  links.db.list <- list()

  # Process main directories (sample-specific)
  message("Processing sample-specific reports...")
  for (i in 1:nrow(data_meta)) {
    sample_name <- sanitize_filename(data_meta$Sample.name[i])
    main_dir <- data_meta$Reports.main[i]

    # Check if source directory exists
    if (!dir.exists(main_dir)) {
      warning("Source directory does not exist: ", main_dir, ". Skipping sample: ", sample_name)
      next
    }

    # Create target directory
    sample_dir <- file.path(reports_dir, sample_name)
    if (!ensure_dir_exists(sample_dir)) {
      warning("Failed to create sample directory: ", sample_dir)
      next
    }

    # Find matching files
    links.from <- list.files(main_dir, recursive = TRUE, pattern = file.types.pattern,
                           full.names = TRUE, ignore.case = TRUE)

    if (length(links.from) == 0) {
      message("  No files found for sample: ", sample_name)
      next
    }

    # Generate target paths
    file.rel.paths <- list.files(main_dir, recursive = TRUE, pattern = file.types.pattern,
                                full.names = FALSE, ignore.case = TRUE)
    links.to <- file.path(sample_dir, file.rel.paths)

    # Create subdirectories if needed
    for (to_dir in unique(dirname(links.to))) {
      ensure_dir_exists(to_dir)
    }

    # Create links
    for (j in seq_along(links.from)) {
      from <- links.from[j]
      to <- links.to[j]
      stats$total_files <- stats$total_files + 1

      # Skip if source is a symlink
      if (is_symlink(from)) {
        warning("Source is already a symlink, skipping: ", from)
        stats$skipped_files <- stats$skipped_files + 1
        next
      }

      # Handle conflicts
      if (file.exists(to)) {
        stats$conflicts <- stats$conflicts + 1

        if (overwrite) {
          tryCatch({
            file.remove(to)
          }, error = function(e) {
            warning("Failed to remove existing file: ", to)
          })
        } else {
          to <- resolve_conflict(to, conflict_resolution, sample_name)
          if (is.na(to)) {
            stats$skipped_files <- stats$skipped_files + 1
            next
          }
        }
      }

      # Ensure parent directory exists
      to_dir <- dirname(to)
      ensure_dir_exists(to_dir)

      # Create symbolic link
      tryCatch({
        file.symlink(from, to)
        stats$successful_links <- stats$successful_links + 1

      }, error = function(e) {
        # Fallback to R.utils::createLink if file.symlink fails
        tryCatch({
          suppressWarnings(R.utils::createLink(link = to, target = from, skip = !overwrite))
          stats$successful_links <- stats$successful_links + 1
        }, error = function(e2) {
          warning("Failed to create link for ", from, " -> ", to, ": ", conditionMessage(e2))
          stats$failed_links <- stats$failed_links + 1
        })
      })
    }

    # Store link info
    if (length(links.from) > 0) {
      links.db.list[[sample_name]] <- data.frame(
        from = links.from,
        to = links.to,
        sample = sample_name,
        type = "main",
        stringsAsFactors = FALSE
      )
    }
  }

  # Process secondary directories (shared in "others")
  if (has_second) {
    second_dirs <- unique(as.vector(na.omit(data_meta$Reports.second)))

    if (length(second_dirs) > 0) {
      message("Processing shared reports (others)...")

      others_dir <- file.path(reports_dir, "others")
      if (!ensure_dir_exists(others_dir)) {
        warning("Failed to create others directory: ", others_dir)
      } else {
        for (second_dir in second_dirs) {
          if (!dir.exists(second_dir)) {
            warning("Secondary directory does not exist: ", second_dir)
            next
          }

          links.from <- list.files(second_dir, recursive = TRUE, pattern = file.types.pattern,
                                 full.names = TRUE, ignore.case = TRUE)

          if (length(links.from) == 0) {
            message("  No files found in: ", second_dir)
            next
          }

          file.rel.paths <- list.files(second_dir, recursive = TRUE, pattern = file.types.pattern,
                                      full.names = FALSE, ignore.case = TRUE)

          # Add source directory prefix to avoid conflicts
          source_prefix <- sanitize_filename(basename(second_dir))
          links.to <- file.path(others_dir, source_prefix, file.rel.paths)

          # Create subdirectories
          for (to_dir in unique(dirname(links.to))) {
            ensure_dir_exists(to_dir)
          }

          # Create links
          for (j in seq_along(links.from)) {
            from <- links.from[j]
            to <- links.to[j]
            stats$total_files <- stats$total_files + 1

            if (is_symlink(from)) {
              stats$skipped_files <- stats$skipped_files + 1
              next
            }

            if (file.exists(to) && !overwrite) {
              stats$conflicts <- stats$conflicts + 1
              to <- resolve_conflict(to, conflict_resolution, source_prefix)
              if (is.na(to)) {
                stats$skipped_files <- stats$skipped_files + 1
                next
              }
            }

            tryCatch({
              file.symlink(from, to)
              stats$successful_links <- stats$successful_links + 1
            }, error = function(e) {
              tryCatch({
                suppressWarnings(R.utils::createLink(link = to, target = from, skip = !overwrite))
                stats$successful_links <- stats$successful_links + 1
              }, error = function(e2) {
                warning("Failed to create link: ", conditionMessage(e2))
                stats$failed_links <- stats$failed_links + 1
              })
            })
          }

          # Store link info
          if (length(links.from) > 0) {
            links.db.list[[paste0("others_", source_prefix)]] <- data.frame(
              from = links.from,
              to = links.to,
              sample = "others",
              type = "second",
              stringsAsFactors = FALSE
            )
          }
        }
      }
    }
  }

  # Print summary
  message("\n=== Report Preparation Summary ===")
  message("Total files processed: ", stats$total_files)
  message("Successful links: ", stats$successful_links)
  message("Skipped files: ", stats$skipped_files)
  message("Failed links: ", stats$failed_links)
  message("Conflicts resolved: ", stats$conflicts)
  message("===================================\n")

  if(getOption("SeuratExplorerServerVerbose")) {
    message("Reports prepared successfully!")
  }

  invisible(stats)
}

#' initialize sample metadata
#' @description
#' When building a new app, it is used to initialise the metadata, which records the primary and secondary analysis
#' directories for the data, the path of the rds/qs2 file under the primary analysis directory and the name of each sample;
#' the primary analysis directory should contain the Rds/qs2 file.
#'
#' @param Reports.main primary analysis directory, Rds should be included, and all files located in this directory will be included in reports
#' @param Rds.path relative path of rds/qs2 file under the primary analysis directory
#' @param Sample.name Sample name
#' @param Reports.second secondary analysis directory, and all files located in this directory will also be included in reports, such 'cellranger' outputs will be linked to Others directory
#'
#' @return A data.frame
#' @export
#' @examples
#' data_meta <- initialize_metadata(Reports.main = c(
#' system.file("extdata/source-data", "fly", package ="SeuratExplorerServer"),
#' system.file("extdata/source-data", "mouse", package ="SeuratExplorerServer")),
#' Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"),
#' Reports.second = c(NA, NA), Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT",
#' "Mouse-Intestine-scRNAseq-Haber"))
#' data_meta
#' # saveRDS(data_meta,file = system.file("extdata", "data_meta.rds",
#' # package ="SeuratExplorerServer"))
#'
initialize_metadata <- function(Reports.main, Rds.path, Reports.second, Sample.name){
  if (all(sapply(list(Reports.main, Rds.path, Reports.second, Sample.name), function(x) length(x) == length(Sample.name)))) {
    if (anyDuplicated(Sample.name) | anyDuplicated(Reports.main)) {
      stop("Duplicated values found!")
    }
    data_meta <- data.frame(Reports.main = Reports.main,
                      Rds.path = Rds.path,
                      Reports.second = Reports.second, # such as cellranger outputs
                      Sample.name = Sample.name, stringsAsFactors = FALSE)
    data_meta$Species <- NA
    data_meta$Description <- NA
    data_meta$Default.DimensionReduction <- NA
    data_meta$Default.ClusterResolution <- NA
    data_meta$SplitOptions.MaxLevel <- NA
    data_meta$Default.Assay <- 'RNA'
    invisible(check_metadata(parameters = data_meta))
    return(data_meta)
  }else{
    stop("Check the parameters length.")
  }
}

#' Revise demo data path
#'
#' Checks whether the \code{Reports.main} paths in the metadata file are valid.
#' If not, attempts to prepend the package installation path to fix them.
#'
#' @section Side Effects:
#' When path correction is triggered (i.e., all original \code{Reports.main}
#' paths are invalid), this function **overwrites** the \code{parameterfile}
#' on disk via \code{saveRDS()}. This typically only happens on the first
#' run after package installation. Subsequent calls will find valid paths
#' and skip the modification.
#'
#' @param parameterfile the path to metadata file (.rds).
#'   Defaults to the built-in demo metadata file.
#'
#' @return The file path to the (possibly modified) parameter file (character).
#' @export
#'
#' @examples
#' revise_demo_path()
revise_demo_path <- function(parameterfile = system.file("extdata", "data_meta.rds", package ="SeuratExplorerServer")){
  data_meta <- readRDS(parameterfile)
  if(all(!dir.exists(data_meta$Reports.main))){ # run demo mode, try change the path in installation, only work for the first time run.
    data_meta$Reports.main <- paste(system.file("extdata", "source-data", package ="SeuratExplorerServer"), data_meta$Reports.main,sep = "/")
    if(any(!dir.exists(data_meta$Reports.main))){ # if still can found the files after modification
      stop('Error, can not found the Reports.main directory in demo data.')
    }
    saveRDS(data_meta, file = parameterfile)
  }
  return(parameterfile)
}


.log_verbose <- function(...) {
  if (isTRUE(getOption("SeuratExplorerServerVerbose"))) {
    message(...)
  }
}

na_to_null <- function(x) if (is.na(x)) NULL else x

.import_from_explorer <- function(func_names) {
  fns <- lapply(func_names, getFromNamespace, ns = "SeuratExplorer")
  names(fns) <- func_names
  fns
}
