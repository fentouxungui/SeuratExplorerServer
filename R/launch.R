# launch.R
# used to launch the shiny app in a web browser.


#' Launch shiny app
#'
#' @param Encrypted 是否加密App
#' @param credentials 密码文件
#' @param paramterfile 参数文件
#' @param TechnicianEmail 技术人员邮箱
#' @param TechnicianName 技术人员姓名
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
  requireNamespace("shinydashboard")
  requireNamespace("shinymanager")
  app = shinyApp(
    ui = ui(Encrypted.app = Encrypted, TechnicianEmail = TechnicianEmail, TechnicianName = TechnicianName),
    server = server, onStart = onStart(Encrypted, credentials, paramterfile)
    )
  runApp(app, launch.browser = TRUE)
}

