# ui.R
# R shiny UI for SeuratExplorer

#' UI for shiny App interface
#'
#' @param Encrypted.app 是否要加密App
#' @param TechnicianEmail 技术人员的联系邮箱
#' @param TechnicianName 技术人员的名字
#'
#' @import shiny SeuratExplorer
#' @import shinydashboard shinyWidgets shinymanager
#' @export
ui <-  function(Encrypted.app, TechnicianEmail = "zhangyongchao@nibs.ac.cn", TechnicianName = "ZhangYongchao"){
  requireNamespace("shinydashboard")
  requireNamespace("shinyWidgets")
  requireNamespace("SeuratExplorer")
  requireNamespace("shinymanager")

  # notificationItem 默认函数无法在新页面打开链接; refer to: https://forum.posit.co/t/shinydashboard-notification-item-with-link-in-new-tab/37580/2
  notificationItemWithAttr <- function(text, icon = shiny::icon("warning"), status = "success", href = NULL, ...) {
    if (is.null(href))
      href <- "#"
    icon <- tagAppendAttributes(icon, class = paste0("text-",
                                                     status))
    tags$li(a(href = href, icon, text, ...))
  }

  # Header ----
  header = dashboardHeader(
    title = "SeuratExplorer Server",
    # Dropdown menu for github
    dropdownMenu(type = "notifications", icon = icon("github"), headerText = "R packages on Github:",
                 notificationItemWithAttr(icon = icon("github"), status = "info", text = "SeuratExplorer", href = "https://github.com/fentouxungui/SeuratExplorer", target = "_blank"),
                 notificationItemWithAttr(icon = icon("github"), status = "info", text = "SeuratExplorerServer", href = "https://github.com/fentouxungui/SeuratExplorerServer", target = "_blank")))

  # Sidebar ----
  sidebar = dashboardSidebar(
    sidebarMenu(
      menuItem("Dataset", tabName = "dataset", icon = icon("database")),
      sidebarMenu(menuItem("Reports", tabName = "reports", icon = icon("file"))),
      SeuratExplorer::explorer_sidebar_ui(),
      conditionalPanel(
        condition = "output.file_loaded",
        sidebarMenu(menuItem("Settings", tabName = "settings", icon = icon("gear"))))
     )
  )

  # BODY ----
  tab_list = list()

  tab_list[["dataset"]] = tabItem(tabName = "dataset",
                                  fluidRow(
                                    # 选择数据
                                    box(status = "primary", title = "Select Data", width = 12, collapsible = TRUE, solidHeader = TRUE,
                                        shinycssloaders::withSpinner(uiOutput("SelectData.UI")),
                                        actionButton(inputId = "submitdata",label = "Load data", icon = icon("upload"), class = "btn-primary")
                                    ),
                                    box(title = "Metadata of Dataset", width = 12, collapsible = TRUE, solidHeader = TRUE,
                                        DT::dataTableOutput("DataList")),
                                    conditionalPanel(
                                      condition = "output.file_loaded",
                                      box(title = "Metadata of Cells", width = 12, collapsible = TRUE, solidHeader = TRUE,
                                          shinycssloaders::withSpinner(DT::dataTableOutput('dataset_meta')))
                                    ))

  )

  tab_list[["reports"]] = tabItem(tabName = "reports",
                                  fluidRow(
                                    box(status = "primary", width = 12, title = "View Analysis Reports", collapsible = TRUE, solidHeader = TRUE,
                                        verbatimTextOutput(outputId = "DirectoryTree"),
                                        actionButton(inputId = "generatereports",label = "Generate/Update Reports", icon = icon("refresh"), class = "btn-primary"),
                                        # br(),
                                        uiOutput("ViewReports.UI")
                                        # conditionalPanel(
                                        #   condition = "reports.generated",
                                        #   box(title = "Metadata of Cells", width = 12, collapsible = TRUE, solidHeader = TRUE,
                                        #       shinycssloaders::withSpinner(DT::dataTableOutput('dataset_meta')))
                                        # shinycssloaders::withSpinner(uiOutput("ReportURL.UI"))
                                        ))
 )

  # body part for Seurat Explorer functions
  tab_list <- SeuratExplorer::explorer_body_ui(tab_list = tab_list)

  # body part for set default parameters
  tab_list[["settings"]] = tabItem(tabName = "settings",
                                   fluidRow(
                                     box(textOutput("settings_warning"), title = "WARNING：", background = "orange", width = 12),
                                     box(status = "primary", width = 12, title = "Set Default Initialization Parameter", collapsible = TRUE, solidHeader = TRUE,
                                         verbatimTextOutput(outputId = "InfoForDataOpened"),
                                         shinycssloaders::withSpinner(uiOutput("SetSampleName.UI")),
                                         shinycssloaders::withSpinner(uiOutput("SetSpecies.UI")),
                                         shinycssloaders::withSpinner(uiOutput("SetDescription.UI")),
                                         shinycssloaders::withSpinner(uiOutput("SetDefaultReduction.UI")),
                                         shinycssloaders::withSpinner(uiOutput("SetDefaultCluster.UI")),
                                         shinycssloaders::withSpinner(uiOutput("SetDefaultSplitMaxLevels.UI")),
                                         actionButton(inputId = "submitsettings",label = "Save", icon = icon("save"), class = "btn-primary")
                                     ))
 )

  body = dashboardBody(
    div(class= "tab-content", tab_list),
    tags$script(HTML(
      "document.querySelector('body > div.wrapper > header > nav > div > ul > li > a > span').style.visibility = 'hidden';"
    )) # 不显示dropdownMenu中notification的数目， refer to:https://stackoverflow.com/questions/65915414/alter-dropdown-menu-in-shiny
  )



  # 整合到一起
  ui_out <- dashboardPage(header, sidebar, body)
  # 加密UI
  if (Encrypted.app) {
    ui_out <- shinymanager::secure_app(ui = ui_out,
                                       tags_bottom = tags$div(tags$p("For any question, please  contact ",
                                                                     tags$a(href = paste0("mailto:", TechnicianEmail,"?Subject=Report%20A%20ShinyApp%20Issue"),
                                                                            target="_top", TechnicianName))),
                                       background  = "linear-gradient(rgba(0, 0, 255, 0.5), rgba(255, 255, 0, 0.5))",
                                       language = "en")
  }
  return(ui_out)
}


