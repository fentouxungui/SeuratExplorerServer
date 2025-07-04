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
                                  fluidRow(
                                    # choose a data
                                    box(status = "primary", title = "Select Data", width = 12, collapsible = TRUE, solidHeader = TRUE,
                                        withSpinner(uiOutput("SelectData.UI")),
                                        actionButton(inputId = "submitdata",label = "Load data", icon = icon("upload"), class = "btn-primary")),
                                    box(title = "Metadata of Dataset", width = 12, collapsible = TRUE, solidHeader = TRUE,status = "primary", align = "center",
                                        DTOutput("DataList")),
                                    conditionalPanel(
                                      condition = "output.file_loaded",
                                      box(title = "Metadata of Cells", width = 12, collapsible = TRUE, solidHeader = TRUE,status = "primary", align = "center",
                                          withSpinner(DTOutput('dataset_meta'))),
                                      box(title = "Structure of Seurat Object", collapsible = TRUE, collapsed = FALSE, width = 12,solidHeader = TRUE, status = "primary",
                                          withSpinner(verbatimTextOutput("object_structure"))))
                                    ))

  tab_list[["reports"]] = tabItem(tabName = "reports",
                                  fluidRow(
                                    box(status = "primary", width = 12, title = "View and Download Analysis Reports", collapsible = TRUE, solidHeader = TRUE,
                                        verbatimTextOutput(outputId = "DirectoryTree"),
                                        actionButton(inputId = "generatereports",label = "Generate/Update Reports", icon = icon("refresh"), class = "btn-primary"),
                                        # https://stackoverflow.com/questions/65767801/adjust-spacing-between-r-shinys-rendertext-elements
                                        div(style = "margin-top: 10px;"), # adjust the space with the last UI, without this code, it will be too close to the last UI.
                                        uiOutput("ViewReports.UI"))
                                    ))

  # body part for Seurat Explorer functions
  tab_list <- SeuratExplorer::explorer_body_ui(tab_list = tab_list)

  # body part for set default parameters
  tab_list[["settings"]] = tabItem(tabName = "settings",
                                   fluidRow(
                                     box(textOutput("settings_warning"), background = "orange", width = 12),
                                     box(status = "primary", width = 12, title = "Set Default Initialization Parameter", collapsible = TRUE, solidHeader = TRUE,
                                         verbatimTextOutput(outputId = "InfoForDataOpened"),
                                         withSpinner(uiOutput("SetSampleName.UI")),
                                         withSpinner(uiOutput("SetSpecies.UI")),
                                         withSpinner(uiOutput("SetDescription.UI")),
                                         withSpinner(uiOutput("SetDefaultReduction.UI")),
                                         withSpinner(uiOutput("SetDefaultCluster.UI")),
                                         withSpinner(uiOutput("SetDefaultSplitMaxLevels.UI")),
                                         actionButton(inputId = "submitsettings",label = "Save", icon = icon("save"), class = "btn-primary"))
                                     ))

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


