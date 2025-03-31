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
#' @param verbose for debug use
#' @rawNamespace import(shiny, except=c(dataTableOutput, renderDataTable))
#' @import SeuratExplorer SeuratExplorerServer shinydashboard
#' @import shinymanager SeuratExplorerServer
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
                                        verbose = FALSE
                                       ){
  options("SeuratExplorerServerVerbose" = verbose)
  options("SeuratExplorerServerEncrypted" = Encrypted)
  options("SeuratExplorerServerCredentials" = credentials)
  options("SeuratExplorerServerParamterfile" = paramterfile)
  shinyApp(
    ui = ui(Encrypted.app = Encrypted, TechnicianEmail = TechnicianEmail, TechnicianName = TechnicianName),
    server = server)
}

