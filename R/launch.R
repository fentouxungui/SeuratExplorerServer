# launch.R
# Run shiny app in a web browser.


#' Launch shiny app
#'
#' @param Encrypted weather to encrypt app
#' @param credentials a data frame with the credentials
#' @param paramterfile path to the parameter file(rds), a data frame with columns:Reports.main, Rds.path, Reports.second, Sample.name
#' SplitOptions.MaxLevel, Default.DimensionReduction, Default.ClusterResolution, Species, and Description
#' @param TechnicianEmail Email of the technician
#' @param TechnicianName Name of the technician
#' @param ReportsFileTypes File types to be included in reports
#' @param DefaultSplitMaxLevel the max factor level of the column from metadata to be included in split option
#' @param SupportedFileTypes supported file types
#' @param verbose default FALSE, messages for debug use
#' @param ReductionKeyWords keywords to extract reductions for the reduction options
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
                                        paramterfile = revise_demo_path(),
                                        TechnicianEmail = "zhangyongchao@nibs.ac.cn",
                                        TechnicianName = "ZhangYongchao",
                                        ReductionKeyWords = c("umap","tsne"),
                                        ReportsFileTypes = c("pdf", "tiff", "tif", "jped", "jpg", "png", "bmp", "svg", "csv"),
                                        DefaultSplitMaxLevel = 6,
                                        SupportedFileTypes = c("rds", "qs2"),
                                        verbose = FALSE
                                       ){
  options("SeuratExplorerServerVerbose" = verbose)
  options("SeuratExplorerServerEncrypted" = Encrypted)
  options("SeuratExplorerServerCredentials" = credentials)
  options("SeuratExplorerServerParamterfile" = paramterfile)
  options("SeuratExplorerServerReportsFileTypes" = ReportsFileTypes)
  options("SeuratExplorerServerDefaultSplitLevel" =  DefaultSplitMaxLevel)
  options("SeuratExplorerServerSupportedFiles" =  SupportedFileTypes)
  options("SeuratExplorerServerReductionKeyWords" =  ReductionKeyWords)

  shinyApp(
    ui = ui(Encrypted.app = Encrypted, TechnicianEmail = TechnicianEmail, TechnicianName = TechnicianName),
    server = server)
}

