# ui.R
# shiny UI

#' UI for shiny App interface
#'
#' @param Encrypted.app weather to encrypt app
#' @param TechnicianEmail Email of the technician
#' @param TechnicianName Name of the technician
#' @rawNamespace import(shiny, except=c(dataTableOutput, renderDataTable))
#' @import SeuratExplorer
#' @import shinydashboard shinyWidgets shinymanager
#' @importFrom shinydashboard menuItem menuSubItem sidebarMenu tabItem box
#' @importFrom shinycssloaders withSpinner
#' @importFrom DT DTOutput
#' @export
#' @return shiny UI
#'
ui <-  function(Encrypted.app, TechnicianEmail = "zhangyongchao@nibs.ac.cn", TechnicianName = "Zhang Yongchao"){
  # shinydashboard::notificationItem: the default function can not open link
  # to make a new function: refer to: https://forum.posit.co/t/shinydashboard-notification-item-with-link-in-new-tab/37580/2
  notificationItemWithAttr <- function(text, icon = shiny::icon("warning"), status = "success", href = NULL, ...) {
    if (is.null(href)){href <- "#"}
    icon <- tagAppendAttributes(icon, class = paste0("text-", status))
    tags$li(a(href = href, icon, text, ...))
  }

  # Header ----
  header = shinydashboard::dashboardHeader(
    title = p(em("SeuratExplorer Server")),
    # Dropdown menu for R package on github page
    shinydashboard::dropdownMenu(type = "notifications", icon = icon("github"), headerText = "R packages on Github:",
                 notificationItemWithAttr(icon = icon("github"), status = "info", text = "SeuratExplorer", href = "https://github.com/fentouxungui/SeuratExplorer", target = "_blank"),
                 notificationItemWithAttr(icon = icon("github"), status = "info", text = "SeuratExplorerServer", href = "https://github.com/fentouxungui/SeuratExplorerServer", target = "_blank")))

  # Sidebar ----
  sidebar = shinydashboard::dashboardSidebar(
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
                               fluidRow(id = "dataset-main-row",
                                 # Select Data (顶部，全宽)
                                 div(
                                   class = "col-xs-12",
                                   style = "margin-bottom: 20px;",
                                   div(
                                     class = "box",
                                     style = "background: white; border: 2px solid #10b981; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08);",
                                     div(
                                       class = "box-header",
                                       style = "padding: 15px 20px; border-bottom: 2px solid #10b981;",
                                       div(
                                         style = "display: flex; align-items: center; gap: 10px;",
                                         icon("upload", style = "color: #10b981; font-size: 18px;"),
                                         h4(style = "margin: 0; color: #10b981; font-weight: 600;", "Select Data")
                                       )
                                     ),
                                     div(
                                       class = "box-body",
                                       style = "padding: 20px;",
                                       withSpinner(uiOutput("SelectData.UI")),
                                       div(style = "text-align: center; margin-top: 20px;",
                                         actionButton(inputId = "submitdata",
                                                     label = "Load Data",
                                                     icon = icon("upload"),
                                                     class = "btn-primary btn-lg",
                                                     style = "padding: 12px 35px; border-radius: 8px; font-weight: 600; background: linear-gradient(135deg, #10b981 0%, #059669 100%); border: none; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);")
                                       )
                                     )
                                   )
                                 ),

                                 # Metadata of Dataset (中部，全宽)
                                 div(
                                   class = "col-xs-12",
                                   style = "margin-bottom: 20px;",
                                   div(
                                     class = "box",
                                     style = "background: white; border: 2px solid #3b82f6; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08);",
                                     div(
                                       class = "box-header",
                                       style = "padding: 15px 20px; border-bottom: 2px solid #3b82f6;",
                                       div(
                                         style = "display: flex; align-items: center; gap: 10px;",
                                         icon("table", style = "color: #3b82f6; font-size: 18px;"),
                                         h4(style = "margin: 0; color: #3b82f6; font-weight: 600;", "Metadata of Dataset")
                                       )
                                     ),
                                     div(
                                       class = "box-body",
                                       style = "padding: 20px;",
                                       DTOutput("DataList")
                                     )
                                   )
                                 ),

                                 # Session Info (底部，全宽)
                                 div(
                                   class = "col-xs-12",
                                   div(
                                     class = "box",
                                     style = "background: white; border: 2px solid #8b5cf6; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08);",
                                     div(
                                       class = "box-header",
                                       style = "padding: 15px 20px; border-bottom: 2px solid #8b5cf6;",
                                       div(
                                         style = "display: flex; align-items: center; gap: 10px;",
                                         icon("info-circle", style = "color: #8b5cf6; font-size: 18px;"),
                                         h4(style = "margin: 0; color: #8b5cf6; font-weight: 600;", "Session Info")
                                       )
                                     ),
                                     div(
                                       class = "box-body",
                                       style = "padding: 20px;",
                                       withSpinner(verbatimTextOutput("sessioninfo"))
                                     )
                                   )
                                 )
                               )
  )

  tab_list[["reports"]] = tabItem(tabName = "reports",
                               fluidRow(id = "reports-main-row",
                                 div(
                                   class = "col-xs-12",
                                   div(
                                     class = "box",
                                     style = "background: white; border: 2px solid #f59e0b; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08);",
                                     div(
                                       class = "box-header",
                                       style = "padding: 15px 20px; border-bottom: 2px solid #f59e0b;",
                                       div(
                                         style = "display: flex; align-items: center; gap: 10px;",
                                         icon("file", style = "color: #f59e0b; font-size: 18px;"),
                                         h4(style = "margin: 0; color: #f59e0b; font-weight: 600;", "View and Download Analysis Reports")
                                       )
                                     ),
                                     div(
                                       class = "box-body",
                                       style = "padding: 20px;",
                                       verbatimTextOutput(outputId = "DirectoryTree"),
                                       div(style = "text-align: center; margin-top: 20px;",
                                         actionButton(inputId = "generatereports",
                                                     label = "Generate/Update Reports",
                                                     icon = icon("refresh"),
                                                     class = "btn-primary btn-lg",
                                                     style = "padding: 12px 35px; border-radius: 8px; font-weight: 600; background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); border: none; box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);")
                                       ),
                                       div(style = "margin-top: 20px;",
                                         uiOutput("ViewReports.UI")
                                       )
                                     )
                                   )
                                 )
                               )
  )

  # body part for Seurat Explorer functions
  tab_list <- SeuratExplorer::explorer_body_ui(tab_list = tab_list)

  # body part for set default parameters
  tab_list[["settings"]] = tabItem(tabName = "settings",
                               fluidRow(id = "settings-main-row",
                                 # Warning message (顶部，全宽)
                                 div(
                                   class = "col-xs-12",
                                   style = "margin-bottom: 20px;",
                                   div(
                                     style = "background: #fef3c7; border: 2px solid #f59e0b; border-left: 4px solid #f59e0b; padding: 15px 20px; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08);",
                                     div(
                                       style = "display: flex; align-items: center; gap: 10px;",
                                       icon("exclamation-triangle", style = "color: #f59e0b; font-size: 20px;"),
                                       div(style = "flex: 1;", textOutput("settings_warning"))
                                     )
                                   )
                                 ),

                                 # Set Default Initialization Parameter (底部，全宽)
                                 div(
                                   class = "col-xs-12",
                                   div(
                                     class = "box",
                                     style = "background: white; border: 2px solid #3b82f6; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08);",
                                     div(
                                       class = "box-header",
                                       style = "padding: 15px 20px; border-bottom: 2px solid #3b82f6;",
                                       div(
                                         style = "display: flex; align-items: center; gap: 10px;",
                                         icon("gear", style = "color: #3b82f6; font-size: 18px;"),
                                         h4(style = "margin: 0; color: #3b82f6; font-weight: 600;", "Set Default Initialization Parameters")
                                       )
                                     ),
                                     div(
                                       class = "box-body",
                                       style = "padding: 20px;",
                                       div(
                                         style = "background: #eff6ff; border: 1px solid #3b82f6; border-left: 4px solid #3b82f6; padding: 15px; border-radius: 6px; margin-bottom: 20px;",
                                         h5(icon("info-circle"), "Current Data Information", style = "color: #3b82f6; margin-bottom: 10px; display: flex; align-items: center; gap: 8px;"),
                                         verbatimTextOutput(outputId = "InfoForDataOpened")
                                       ),
                                       div(
                                         style = "background: #f0fdf4; border: 1px solid #10b981; border-left: 4px solid #10b981; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                                         h4(icon("sliders-h"), "Parameter Settings", style = "color: #10b981; margin-bottom: 15px; font-weight: 600; display: flex; align-items: center; gap: 8px;"),
                                         withSpinner(uiOutput("SetSampleName.UI")),
                                         withSpinner(uiOutput("SetSpecies.UI")),
                                         withSpinner(uiOutput("SetDescription.UI")),
                                         withSpinner(uiOutput("SetDefaultReduction.UI")),
                                         withSpinner(uiOutput("SetDefaultCluster.UI")),
                                         withSpinner(uiOutput("SetDefaultAssay.UI")),
                                         withSpinner(uiOutput("SetDefaultSplitMaxLevels.UI"))
                                       ),
                                       div(style = "text-align: center;",
                                         actionButton(inputId = "submitsettings",
                                                     label = "Save Settings",
                                                     icon = icon("save"),
                                                     class = "btn-primary btn-lg",
                                                     style = "padding: 12px 35px; border-radius: 8px; font-weight: 600; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); border: none; box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);")
                                       )
                                     )
                                   )
                                 )
                               )
  )

  body = dashboardBody(
    div(class= "tab-content", tab_list),
    # to hide how many notifications in shinydashboard::dropdownMenu(), refer to:https://stackoverflow.com/questions/65915414/alter-dropdown-menu-in-shiny
    tags$script(HTML("document.querySelector('body > div.wrapper > header > nav > div > ul > li > a > span').style.visibility = 'hidden';")))

  # combine
  ui_out <- dashboardPage(header, sidebar, body, title = "SeuratExplorer Server")
  # encrypt
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


