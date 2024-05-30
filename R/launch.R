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
                                        paramterfile = system.file("extdata/demo/others", "sample-paramters.rds", package = "SeuratExplorerServer"),
                                        TechnicianEmail = "zhangyongchao@nibs.ac.cn",
                                        TechnicianName = "ZhangYongchao"
                                       ){
  require(shinydashboard)
  require(shinymanager)
  # define global variables for server function
  # refer to: https://stackoverflow.com/questions/31118236/how-to-set-global-variable-values-in-the-onstart-parameter-of-shiny-application
  onStart <- function(){
    Encrypted.app <<- Encrypted
    credentials.server <<- credentials
    # 读入数据配置文件，并作检查
    paramterfile.app <<- paramterfile
    data_meta <<- check_metedata(readRDS(paramterfile))
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
  app = shinyApp(ui = ui(Encrypted.app = Encrypted, TechnicianEmail = TechnicianEmail, TechnicianName = TechnicianName), server = server, onStart = onStart)
  runApp(app, launch.browser = TRUE)
}

