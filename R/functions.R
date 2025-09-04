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
  requireNamespace("utils")
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
        stop("Please contact data curator to report this error! this error is related to the second_dirs column in data meta!")
      }
    }

    # check sample name
    postfix_pattern_to_be_removed <- paste0("(.", paste0(supported_file_types, collapse = "$)|("), "$)")
    if (is.null(parameters$Sample.name)) {
      parameters$Sample.name <- gsub(postfix_pattern_to_be_removed, basename(parameters$Rds.path),fixed = TRUE, ignore.case = TRUE)
    }else if(any(is.na(parameters$Sample.name))) {
      parameters$Sample.name[is.na(parameters$Sample.name)] <- gsub(postfix_pattern_to_be_removed, basename(parameters$Rds.path[is.na(parameters$Sample.name)]),fixed = TRUE, ignore.case = TRUE)
    }
    # arrange by main directory
    parameters <- parameters[order(parameters$Reports.main),]
    return(parameters)
  }
}

prepare_reports <- function(reports_dir, data_meta, file_types_included = c("pdf", "tiff", "tif", "jpeg", 'gif',"jpg", "png", "bmp", "svg","html",'mp4','avi')){
  file.types.pttern = paste0("(\\.", paste0(file_types_included, collapse = "$)|(\\."), "$)")
  # generate from + to data.frame for main directory
  links.db.list <- list()
  for (i in 1:nrow(data_meta)) {
    links.from <- list.files(data_meta$Reports.main[i], recursive = TRUE, pattern = file.types.pttern, full.names = TRUE)
    links.to <- paste0(reports_dir, "/", data_meta$Sample.name[i], "/", list.files(data_meta$Reports.main[i], recursive = TRUE, pattern = file.types.pttern, full.names = FALSE))
    if (length(links.from) != 0) {
      links.db.list[[data_meta$Sample.name[i]]] <- data.frame(from = links.from, to = links.to)
    }
  }
  # secondary analysis directory, under others directory, possible problem: link will be rewrite by files with same name.
  second_dirs <- unique(as.vector(na.omit(data_meta$Reports.second)))
  if (length(second_dirs) > 0) {
    links.from <- c()
    links.to <- c()
    for (i in second_dirs) {
      links.from <- append(links.from, list.files(i, recursive = TRUE, pattern = file.types.pttern, full.names = TRUE))
      links.to <- append(links.to, paste0(reports_dir, "/others/", list.files(i, recursive = TRUE, pattern = file.types.pttern, full.names = FALSE)))
    }
    if (length(links.from) != 0) {
      links.db.list[["others"]] <- data.frame(from = links.from, to = links.to)
    }
  }
  if (length(links.db.list) != 0) { # if does has reports files
    links.db <- Reduce(rbind, links.db.list)
    links.db <- links.db[!duplicated(links.db),] # remove duplicated links
    # create links
    if (nrow(links.db) > 0) {
      for (i in 1:nrow(links.db)) {
        suppressWarnings(R.utils::createLink(link = links.db$to[i], target = links.db$from[i], skip = TRUE))
      }
    }
  }
  if(getOption("SeuratExplorerServerVerbose")){message("reports prepared successfully!")}
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
    invisible(check_metadata(parameters = data_meta))
    return(data_meta)
  }else{
    stop("Check the parameters length.")
  }
}

#' Revise demo data path
#'
#' @param paramterfile the path to metadata file
#'
#' @return path to parameter file
#' @export
#'
#' @examples
#' revise_demo_path()
revise_demo_path <- function(paramterfile = system.file("extdata", "data_meta.rds", package ="SeuratExplorerServer")){
  data_meta <- readRDS(paramterfile)
  if(all(!dir.exists(data_meta$Reports.main))){ # run demo mode, try change the path in installation, only work for the first time run.
    data_meta$Reports.main <- paste(system.file("extdata", "source-data", package ="SeuratExplorerServer"), data_meta$Reports.main,sep = "/")
    if(any(!dir.exists(data_meta$Reports.main))){ # if still can found the files after modification
      stop('Error, can not found the Reports.main directory in demo data.')
    }
    saveRDS(data_meta, file = paramterfile)
  }
  return(paramterfile)
}
