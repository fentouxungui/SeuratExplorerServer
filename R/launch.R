# launch.R
# Run shiny app in a web browser.


#' Launch shiny app
#'
#' @param Encrypted whether to encrypt app
#' @param credentials a data frame with the credentials
#' @param parameterfile path to the parameter file(rds), a data frame with columns:Reports.main, Rds.path, Reports.second, Sample.name
#' SplitOptions.MaxLevel, Default.DimensionReduction, Default.ClusterResolution, Species, and Description
#' @param TechnicianEmail Email of the technician
#' @param TechnicianName Name of the technician
#' @param ReportsFileTypes File types to be included in reports
#' @param DefaultSplitMaxLevel the max factor level of the column from metadata to be included in split option
#' @param SupportedFileTypes supported file types
#' @param verbose default FALSE, messages for debug use
#' @param ReductionKeyWords keywords to extract reductions for the reduction options
#' @param CommentsFile path to the CSV file that stores the comment board.
#'   Defaults to a `comments.csv` file next to `parameterfile`.
#' @param TechnicianUser character vector of login usernames with technician
#'   privileges (allowed to delete comments / mark them resolved). Ignored when
#'   `Encrypted = FALSE` (everyone is treated as technician).
#' @param MaxReportFileSize maximum size (in bytes) of a report file that will
#'   be copied into the reports directory when a hard link is not possible
#'   (i.e. the source is on a different filesystem). Larger files are skipped.
#'   Use `Inf` for no limit. Defaults to 100 MB.
#'
#' @rawNamespace import(shiny, except=c(dataTableOutput, renderDataTable))
#' @return In-browser Shiny Application launch
#' @examples
#' if(interactive()){launchSeuratExplorerServer()}
#' @export
#'
#'
launchSeuratExplorerServer <- function( Encrypted = TRUE,
                                        credentials = data.frame(user = "shiny", password = "12345", stringsAsFactors = FALSE),
                                        parameterfile = revise_demo_path(),
                                        TechnicianEmail = "zhangyongchao@nibs.ac.cn",
                                        TechnicianName = "ZhangYongchao",
                                        ReductionKeyWords = c("umap","tsne","pca"),
                                        ReportsFileTypes = c("pdf", "tiff", "tif", "jpeg", 'gif',"jpg", "png", "bmp", "svg","html",'mp4','avi','Rmd','R','ipynb','sh','Sh','txt','csv','xlsx','xls','xml','md','py'),
                                        DefaultSplitMaxLevel = 6,
                                        SupportedFileTypes = c("rds", "qs2"),
                                        CommentsFile = NULL,
                                        TechnicianUser = "admin",
                                        MaxReportFileSize = 100 * 1024^2,
                                        verbose = FALSE
                                       ){
  if (is.null(CommentsFile)) {
    CommentsFile <- file.path(dirname(parameterfile), "comments.csv")
  }
  options(
    SeuratExplorerVerbose = verbose,
    SeuratExplorerServerVerbose = verbose,
    SeuratExplorerServerEncrypted = Encrypted,
    SeuratExplorerServerCredentials = credentials,
    SeuratExplorerServerParameterfile = parameterfile,
    SeuratExplorerServerReportsFileTypes = ReportsFileTypes,
    SeuratExplorerServerDefaultSplitLevel =  DefaultSplitMaxLevel,
    SeuratExplorerServerSupportedFiles =  SupportedFileTypes,
    SeuratExplorerServerReductionKeyWords=  ReductionKeyWords,
    SeuratExplorerServerCommentsFile = CommentsFile,
    SeuratExplorerServerTechnicianUser = TechnicianUser,
    SeuratExplorerServerMaxReportFileSize = MaxReportFileSize,
    # Suppress the `as.list.reactivevalues()` deprecation warning emitted by
    # shinydashboard 0.7.3 (and other older deps) on newer Shiny versions.
    shiny.deprecation.messages = FALSE
  )

  shinyApp(
    ui = ui(Encrypted.app = Encrypted, TechnicianEmail = TechnicianEmail, TechnicianName = TechnicianName),
    server = server)
}

