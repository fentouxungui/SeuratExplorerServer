# launch.R
# used to launch the shiny app in a web browser.


#' Launch shiny app
#'
#' @import shiny SeuratExplorer
#' @return In-browser Shiny Application launch
#' @examples
#' # launchSeuratExplorerServer()
#' @export
#'
#'
launchSeuratExplorerServer <- function( Encrypted = TRUE,
                                        credentials = data.frame(user = "shiny", password = "12345", stringsAsFactors = FALSE),
                                        paramterfile = revise_path(),
                                        TechnicianEmail = "zhangyongchao@nibs.ac.cn",
                                        TechnicianName = "ZhangYongchao"
                                       ){
  require(shinydashboard)
  require(shinymanager)
  app = shinyApp(
    ui = ui(Encrypted.app = Encrypted, TechnicianEmail = TechnicianEmail, TechnicianName = TechnicianName),
    server = server, onStart = onStart(Encrypted, credentials, paramterfile)
    )
  runApp(app, launch.browser = TRUE)
}

