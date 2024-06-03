check_metedata <- function(parameters){
  requireNamespace("shinydashboard")
  # 1. 检查路径是否正确
  parameters$Rds.full.path <- paste(parameters$Reports.main, parameters$Rds.path,sep = "/")
   if (!all(file.exists(parameters$Rds.full.path))) {
    stop("Please contact data curator to report this error, this error is related to the Reports.main and Rds.path columns in data meta!")
  }else{
    # 2. 检查Reports.second路径是否都存在
    second_dirs <- as.vector(na.omit(parameters$Reports.second))
    if (length(second_dirs) > 0) {
      if (!all(dir.exists(second_dirs))) {
        stop("Please contact data curator to report this error! this error is related to the second_dirs column in data meta!")
      }
    }
    # 2. 检查sample name
    if (is.null(parameters$Sample.name)) {
      parameters$Sample.name <- gsub(".rds", basename(parameters$Rds.path),fixed = TRUE)
    }else if (any(is.na(parameters$Sample.name))) {
      parameters$Sample.name[is.na(parameters$Sample.name)] <- gsub(".rds", basename(parameters$Rds.path[is.na(parameters$Sample.name)]),fixed = TRUE)
    }
    return(parameters)
  }
}

prepare_reports <- function(reports_dir, data_meta){
  file.types = "(\\.html$)|(\\.tiff$)|(\\.csv$)|(\\.pdf$)|(\\.jpg$)|(\\.jpeg$)|(\\.png$)|(\\.bmp$)|(\\.svg$)"
  # 生成from+to data.frame for 主分析目录
  links.db.list <- list()
  for (i in 1:nrow(data_meta)) {
    links.from <- list.files(data_meta$Reports.main[i], recursive = TRUE, pattern = file.types, full.names = TRUE)
    links.to <- paste0(reports_dir, "/", data_meta$Sample.name[i], "/", list.files(data_meta$Reports.main[i], recursive = TRUE, pattern = file.types, full.names = FALSE))
    if (length(links.from) != 0) {
      links.db.list[[data_meta$Sample.name[i]]] <- data.frame(from = links.from, to = links.to)
    }
  }
  # 次要分析目录（新建连接到others文件目录下） 可能的问题，如果两个目录有相同的文件，会被覆盖！
  second_dirs <- unique(as.vector(na.omit(data_meta$Reports.second)))
  if (length(second_dirs) > 0) {
    links.from <- c()
    links.to <- c()
    for (i in second_dirs) {
      links.from <- append(links.from, list.files(i, recursive = TRUE, pattern = file.types, full.names = TRUE))
      links.to <- append(links.to, paste0(reports_dir, "/others/", list.files(i, recursive = TRUE, pattern = file.types, full.names = FALSE)))
    }
    if (length(links.from) != 0) {
      links.db.list[["others"]] <- data.frame(from = links.from, to = links.to)
    }
  }
  if (length(links.db.list) != 0) { # 如果确实存在中间分析文件
    links.db <- Reduce(rbind, links.db.list)
    # 创建链接
    if (nrow(links.db) > 0) {
      for (i in 1:nrow(links.db)) {
        suppressWarnings(R.utils::createLink(link = links.db$to[i], target = links.db$from[i], skip = TRUE))
      }
    }
  }

}

#' 初始化样本的元数据信息
#' @description
#' 搭建新的app时，用于初始化元数据，记录了数据的分析主要和次要分析目录、Rds文件的在主分析目录中的路径和各样本的名字，主要分析目录会包含Rds文件。
#'
#' @param Reports.main 主分析目录, Rds文件位于此目录中，并且所有位于该目录下的指定文件也会被收录到reports中，以sample name进行命名和区分。
#' @param Rds.path Rds文件在主分析目录中的相对目录
#' @param Sample.name Sample name
#' @param Reports.second 次要分析目录，此目录中的分析报告也会被加载到reports临时目录中，比如cellranger的结果。放到Others子目录下。
#'
#' @return A data.frame
#' @export
#' @examples
#' # initialize_metadata(Reports.main = c("inst/extdata/demo/fly-gut-EEs-scRNA", "inst/extdata/demo/mouse-gut-haber"),
#' # Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"),
#' # Reports.second = c(NA, NA),
#' # Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT", "Mouse-Intestine-scRNAseq-Haber"))
#' # saveRDS(data_meta,file = "./inst/extdata/demo/others/sample-paramters.rds")
initialize_metadata <- function(Reports.main, Rds.path, Reports.second, Sample.name){
  if (all(sapply(list(Reports.main, Rds.path, Reports.second, Sample.name), function(x) length(x) == length(Sample.name)))) {
    if (anyDuplicated(Sample.name) | anyDuplicated(Reports.main)) {
      stop("Duplicated values found!")
    }
    data_meta <- data.frame(Reports.main = Reports.main,
                      Rds.path = Rds.path,
                      Reports.second = Reports.second, # 比如cellranger outputs
                      Sample.name = Sample.name, stringsAsFactors = FALSE)
    data_meta$Species <- NA
    data_meta$Description <- NA
    data_meta$Default.DimensionReduction <- NA
    data_meta$Default.ClusterResolution <- NA
    data_meta$SplitOptions.MaxLevel <- NA
    invisible(check_metedata(parameters = data_meta))
    return(data_meta)
  }else{
    stop("Check the parameters length.")
  }
}

revise_path <- function(paramterfile = system.file("extdata/demo/others", "sample-paramters.rds", package ="SeuratExplorerServer")){
  data_meta <- readRDS(paramterfile)
  if(all(!dir.exists(data_meta$Reports.main))){ # run demo mode, try change the path in installation, only work for the first time run.
    data_meta$Reports.main <- paste(system.file(package ="SeuratExplorerServer"),data_meta$Reports.main,sep = "/")
    saveRDS(data_meta,file = paramterfile)
  }
  return(paramterfile)
}

# define global variables for server function
# refer to: https://stackoverflow.com/questions/31118236/how-to-set-global-variable-values-in-the-onstart-parameter-of-shiny-application
onStart <- function(Encrypted, credentials, paramterfile){
  Encrypted.server <<- Encrypted # 经测试，必须要在这里重新复制定义Encrypted.server
  credentials.server <<- credentials
  # 读入数据配置文件，并作检查
  paramterfile.server <<- paramterfile
  data_meta <<- check_metedata(parameters = readRDS(paramterfile))
  # 准备reports目录
  reports_dir <<- paste0("../", basename(getwd()), "_reports") # 创建一个临时目录，用于存储reports文件的快捷方式
  if(!dir.exists(reports_dir)){
    dir.create(reports_dir)
  }else{
    unlink(reports_dir, recursive = TRUE)
    dir.create(reports_dir)
  }
  # 准备reports文件
  message("Preparing the reports direcotry, Please wait a moment...")
  prepare_reports(reports_dir = reports_dir, data_meta = data_meta)
  # clean up jobs
  onStop(function(){
    if(dir.exists(reports_dir)){unlink(reports_dir, recursive = TRUE)}
    cat("Session stopped\n")
  })
}
