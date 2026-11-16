# ui.R
# shiny UI

#' UI for shiny App interface
#'
#' @param Encrypted.app whether to encrypt app
#' @param TechnicianEmail Email of the technician
#' @param TechnicianName Name of the technician
#' @rawNamespace import(shiny, except=c(dataTableOutput, renderDataTable))
#' @import SeuratExplorer
#' @import shinydashboard shinyWidgets shinymanager
#' @importFrom shinydashboard menuItem menuSubItem sidebarMenu tabItem box
#' @importFrom shinycssloaders withSpinner
#' @importFrom DT DTOutput
#' @importFrom shinyjs useShinyjs
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

  # Reusable styled section box (colored border + icon header + body), to avoid
  # duplicating the same markup for every page section.
  section_box <- function(title, icon_name = NULL, color = "#3b82f6", ...) {
    # Keep the accent border, but use an AA-contrast text tone on white.
    text_color <- switch(
      tolower(color),
      "#3b82f6" = "#1D4ED8",
      "#10b981" = "#047857",
      "#f59e0b" = "#B45309",
      "#8b5cf6" = "#6D28D9",
      "#ec4899" = "#BE185D",
      "#06b6d4" = "#0E7490",
      color
    )
    if (is.null(icon_name)) {
      title_tag <- h4(style = sprintf("margin: 0; color: %s; font-weight: 600;", text_color), title)
    } else {
      title_tag <- div(
        style = "display: flex; align-items: center; gap: 10px;",
        icon(icon_name, style = sprintf("color: %s; font-size: 18px;", color)),
        h4(style = sprintf("margin: 0; color: %s; font-weight: 600;", text_color), title)
      )
    }
    div(
      class = "col-xs-12",
      style = "margin-bottom: 20px;",
      div(
        class = "box",
        style = sprintf("background: white; border: 2px solid %s; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08);", color),
        div(
          class = "box-header",
          style = sprintf("padding: 15px 20px; border-bottom: 2px solid %s;", color),
          title_tag
        ),
        div(
          class = "box-body",
          style = "padding: 20px;",
          ...
        )
      )
    )
  }

  # Header ----
  header = shinydashboard::dashboardHeader(
    title = p(strong(em("SeuratExplorer Server")), style = "margin: 0;"),
    # Compact dataset status (mirrors the header of SeuratExplorer)
    tags$li(class = "dropdown", uiOutput("header_status")),
    # Dropdown menu for R package on github page
    shinydashboard::dropdownMenu(type = "notifications", icon = icon("github"), headerText = "R packages on Github:",
                 notificationItemWithAttr(icon = icon("github"), status = "info", text = "SeuratExplorer", href = "https://github.com/fentouxungui/SeuratExplorer", target = "_blank"),
                 notificationItemWithAttr(icon = icon("github"), status = "info", text = "SeuratExplorerServer", href = "https://github.com/fentouxungui/SeuratExplorerServer", target = "_blank")))

  # Sidebar ----
  # Keep each sidebarMenu as a direct child of dashboardSidebar, matching
  # SeuratExplorer. Nesting explorer_sidebar_ui() (which already contains its
  # own sidebarMenu) inside another sidebarMenu adds wrapper bullets/margins
  # and makes every Explorer submenu row taller.
  sidebar = shinydashboard::dashboardSidebar(
    sidebarMenu(
      menuItem("Dataset", tabName = "dataset", icon = icon("database")),
      menuItem("Reports", tabName = "reports", icon = icon("file")),
      menuItem("Comments", tabName = "comments", icon = icon("comments"))
    ),
    SeuratExplorer::explorer_sidebar_ui(),
    conditionalPanel(
      condition = "output.file_loaded",
      sidebarMenu(menuItem("Settings", tabName = "settings", icon = icon("gear")))
    )
  )

  # BODY ----
  tab_list = list()

  tab_list[["dataset"]] = tabItem(tabName = "dataset",
                               fluidRow(id = "dataset-main-row",
                                 # Select Data (顶部，全宽)
                                 section_box(title = "Select Data", icon_name = "upload", color = "#10b981",
                                   withSpinner(uiOutput("SelectData.UI")),
                                   div(style = "text-align: center; margin-top: 20px;",
                                     actionButton(inputId = "submitdata",
                                                 label = "Load Data",
                                                 icon = icon("upload"),
                                                 class = "btn-primary btn-lg",
                                                 style = "padding: 12px 35px; border-radius: 8px; font-weight: 600; background: linear-gradient(135deg, #047857 0%, #065F46 100%); border: none; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);")
                                   ),
                                   # current data info
                                   uiOutput("CurrentDataOverview")
                                 ),

                                 # Metadata of Dataset (中部，全宽)
                                 section_box(title = "Metadata of Dataset", icon_name = "table", color = "#3b82f6",
                                   DTOutput("DataList")
                                 ),

                                 # Session Info (底部，全宽)
                                 section_box(title = "Session Info", icon_name = "info-circle", color = "#8b5cf6",
                                   withSpinner(verbatimTextOutput("sessioninfo"))
                                 )
                               )
  )

  tab_list[["reports"]] = tabItem(tabName = "reports",
                               fluidRow(id = "reports-main-row",
                                 section_box(title = "View and Download Analysis Reports", icon_name = "file", color = "#f59e0b",
                                   verbatimTextOutput(outputId = "DirectoryTree"),
                                   div(style = "text-align: center; margin-top: 20px;",
                                     actionButton(inputId = "generatereports",
                                                 label = "Generate/Update Reports",
                                                 icon = icon("refresh"),
                                                 class = "btn-primary btn-lg",
                                                 style = "padding: 12px 35px; border-radius: 8px; font-weight: 600; background: linear-gradient(135deg, #B45309 0%, #92400E 100%); border: none; box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);")
                                   ),
                                   div(style = "margin-top: 20px;",
                                     uiOutput("ViewReports.UI")
                                   )
                                 )
                               )
  )

  tab_list[["comments"]] = tabItem(tabName = "comments",
                                fluidRow(id = "comments-main-row",
                                  section_box(title = "Comments / 留言", icon_name = "comments", color = "#06b6d4",
                                    # Comment guidelines
                                    div(
                                      style = "background: #eff6ff; border: 1px solid #3b82f6; border-left: 4px solid #3b82f6; padding: 12px 16px; border-radius: 6px; margin-bottom: 15px;",
                                      div(
                                        style = "display: flex; align-items: flex-start; gap: 10px;",
                                        icon("info-circle", style = "color: #1D4ED8; margin-top: 2px;"),
                                        div(
                                          style = "color: #1e40af;",
                                          strong("Comment guidelines: "),
                                          "Please be respectful and use appropriate language. For bug reports or technical issues, please do not post here — contact the technician directly (",
                                          TechnicianName, ", ", TechnicianEmail, ")."
                                        )
                                      )
                                    ),
                                    # Board full warning
                                    conditionalPanel(
                                      condition = "output.comments_full",
                                      div(
                                        style = "background: #fef3c7; border: 1px solid #f59e0b; border-left: 4px solid #f59e0b; padding: 12px 16px; border-radius: 6px; margin-bottom: 15px;",
                                        div(
                                          style = "display: flex; align-items: center; gap: 10px;",
                                          icon("exclamation-triangle", style = "color: #B45309;"),
                                          span(style = "color: #92400e;", "The comment board has reached its size limit, so new comments are disabled. Please contact the technician (", TechnicianName, ").")
                                        )
                                      )
                                    ),
                                    # Sample filter
                                    uiOutput("comment_filter_ui"),
                                    # Comment list (card layout)
                                    uiOutput("comments_list"),
                                    uiOutput("comment_reply_indicator"),
                                    hr(),
                                    # New comment form (hidden when the board is full)
                                    conditionalPanel(
                                      condition = "!output.comments_full",
                                      h4(icon("pen"), "Add a Comment", style = "color: #0E7490; font-weight: 600; margin-bottom: 10px;"),
                                      div(
                                        style = "background: #f0fdfa; border: 1px solid #06b6d4; border-left: 4px solid #06b6d4; padding: 15px; border-radius: 6px;",
                                        div(
                                          style = "display: flex; gap: 15px; flex-wrap: wrap; margin-bottom: 10px;",
                                          div(
                                            style = "flex: 1; min-width: 180px;",
                                            div(style = "color: #5C636A; font-size: 12px; margin-bottom: 4px;", "Login name (read-only)"),
                                            textOutput("comment_current_user", inline = TRUE)
                                          ),
                                          div(
                                            style = "flex: 1; min-width: 180px;",
                                            textInput("comment_realname", "Your real name (optional):", value = "", width = "100%")
                                          ),
                                          div(
                                            style = "flex: 1; min-width: 180px;",
                                            uiOutput("comment_sample_ui")
                                          )
                                        ),
                                        textAreaInput("comment_content", "Comment:", value = "", width = "100%", height = "120px", resize = "vertical"),
                                        div(style = "color: #5C636A; font-size: 12px; margin-top: 4px;", paste0("Max ", getOption("SeuratExplorerServerMaxCommentLength", 2000), " characters.")),
                                        div(
                                          style = "text-align: right; margin-top: 10px;",
                                          actionButton("submit_comment", "Post Comment", icon = icon("paper-plane"),
                                                       class = "btn-primary",
                                                       style = "padding: 10px 28px; border-radius: 6px; font-weight: 600; background: linear-gradient(135deg, #0E7490 0%, #155E75 100%); border: none; box-shadow: 0 4px 12px rgba(6, 182, 212, 0.3);")
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
                                       icon("exclamation-triangle", style = "color: #B45309; font-size: 20px;"),
                                       div(style = "flex: 1;", textOutput("settings_warning"))
                                     )
                                   )
                                 ),

                                 # Set Default Initialization Parameter (底部，全宽)
                                 section_box(title = "Set Default Initialization Parameters", icon_name = "gear", color = "#3b82f6",
                                   div(
                                     style = "background: #eff6ff; border: 1px solid #3b82f6; border-left: 4px solid #3b82f6; padding: 15px; border-radius: 6px; margin-bottom: 20px;",
                                     h5(icon("info-circle"), "Current Data Information", style = "color: #1D4ED8; margin-bottom: 10px; display: flex; align-items: center; gap: 8px;"),
                                     verbatimTextOutput(outputId = "InfoForDataOpened")
                                   ),
                                   div(
                                     style = "background: #f0fdf4; border: 1px solid #10b981; border-left: 4px solid #10b981; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                                     h4(icon("sliders-h"), "Parameter Settings", style = "color: #047857; margin-bottom: 15px; font-weight: 600; display: flex; align-items: center; gap: 8px;"),
                                     withSpinner(
                                       div(
                                         uiOutput("SetSampleName.UI"),
                                         uiOutput("SetSpecies.UI"),
                                         uiOutput("SetDescription.UI"),
                                         uiOutput("SetDefaultReduction.UI"),
                                         uiOutput("SetDefaultCluster.UI"),
                                         uiOutput("SetDefaultAssay.UI"),
                                         uiOutput("SetDefaultSplitMaxLevels.UI")
                                       ),
                                       proxy.height = "10px"
                                     )
                                   ),
                                   div(style = "text-align: center;",
                                     actionButton(inputId = "submitsettings",
                                                 label = "Save Settings",
                                                 icon = icon("save"),
                                                 class = "btn-primary btn-lg",
                                                 style = "padding: 12px 35px; border-radius: 8px; font-weight: 600; background: linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%); border: none; box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);")
                                   )
                                 )
                               )
  )

  body = dashboardBody(
    shinyjs::useShinyjs(),
    tags$head(
      tags$style(HTML("
        /* Global font optimization */
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        }

        /* Header title: fit the full app name without clipping */
        .main-header .logo {
          font-size: 16px;
          white-space: nowrap;
        }

        /* Sidebar menu: compact spacing */
        .sidebar-menu .treeview-menu li a {
          white-space: nowrap;
          padding: 4px 5px 4px 12px !important;
        }

        /* Optimize box style - keep default background */
        .box {
          border-radius: 6px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          transition: box-shadow 0.2s ease;
        }

        .box:hover {
          box-shadow: 0 2px 6px rgba(0,0,0,0.15);
        }

        .box.box-solid .box-title {
          font-weight: 600;
        }

        /* Information boxes: tighten the gap to the content below.
           Mirrors the rule in SeuratExplorer: AdminLTE gives .box a 20px
           bottom margin which left a visibly large gap under the hints. */
        #degs-info-box,
        #topgenes-info-box,
        #featuresummary-info-box,
        #featurecorrelation-info-box,
        #clustercolors-info-box,
        #exportdata-info-box {
          margin-bottom: 8px !important;
        }

        #degs-info-box > .box,
        #topgenes-info-box > .box,
        #featuresummary-info-box > .box,
        #featurecorrelation-info-box > .box,
        #clustercolors-info-box > .box,
        #exportdata-info-box > .box {
          margin-bottom: 0 !important;
        }

        /* Optimize button style */
        .btn {
          border-radius: 6px;
          font-weight: 500;
          transition: all 0.2s ease;
        }

        .btn:hover {
          box-shadow: 0 2px 6px rgba(0,0,0,0.15);
        }

        /* Modal Dialog Styles */
        .modal-content {
          border-radius: 8px;
          box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }

        .modal-header {
          border-radius: 8px 8px 0 0;
          padding: 16px 20px;
        }

        .modal-body {
          padding: 20px;
        }

        .modal-footer {
          border-top: 1px solid #dee2e6;
          padding: 16px 20px;
        }

        .modal-footer .btn {
          border-radius: 6px;
          padding: 8px 16px;
          font-weight: 500;
        }

        /* Collapsible parameter group styles (inherited from SeuratExplorer) */
        summary::-webkit-details-marker,
        summary::marker {
          display: none;
        }

        .param-group-chevron {
          transition: transform 0.3s ease;
          display: inline-block;
        }

        details:not([open]) .param-group-chevron {
          transform: rotate(-90deg);
        }

        /* Accessibility: AA text tokens and fixed shinydashboard surfaces */
        :root {
          --se-primary: #2563EB;
          --se-primary-text: #1D4ED8;
          --se-muted-text: #5C636A;
        }

        .skin-blue .main-header .navbar,
        .skin-blue .main-header .logo,
        .skin-blue .main-header .logo:hover {
          background-color: #256b8e !important;
        }

        .sidebar-menu .treeview-menu > li > a {
          color: #c4d1d8 !important;
        }

        .box.box-solid.box-primary > .box-header {
          background-color: #256b8e !important;
        }

        .label-info,
        .badge-info,
        .label-primary {
          background-color: #0e7490 !important;
          color: #fff !important;
        }

        .label-success {
          background-color: #047857 !important;
          color: #fff !important;
        }

        .sidebar-menu .label-info {
          font-size: 10px !important;
          padding: 2px 4px !important;
        }

        .btn-primary,
        .btn-primary:visited {
          background-color: #256b8e !important;
          border-color: #256b8e !important;
          color: #fff !important;
        }

        /* actionButton wraps its label in .action-label. Do not paint that
           inner span: it must stay transparent over the button surface. */
        .btn-primary .action-label,
        .btn-primary a {
          background-color: transparent !important;
          color: #fff !important;
        }

        .btn-info {
          background-color: #0e7490 !important;
          border-color: #0e7490 !important;
          color: #fff !important;
        }

        .btn-info .action-label {
          background-color: transparent !important;
          color: #fff !important;
        }

        .bttn-primary {
          background-color: #256b8e !important;
          border-color: #256b8e !important;
          color: #fff !important;
        }

        .bttn-primary a {
          color: #fff !important;
        }

        .btn-warning,
        .btn-warning:visited {
          background-color: #B45309 !important;
          border-color: #B45309 !important;
          color: #fff !important;
        }

        .btn-warning .action-label,
        .btn-warning a {
          background-color: transparent !important;
          color: #fff !important;
        }

        .content-wrapper a {
          color: var(--se-primary-text);
        }

        #ClusterColorClearSaved {
          color: #B42318 !important;
          min-height: 24px;
          line-height: 24px;
          padding: 4px 0;
        }

        .bootstrap-select .filter-option-inner-inner,
        .bootstrap-select .bs-placeholder,
        .selectize-control .bs-placeholder,
        .selectize-control .filter-option-inner-inner,
        .selectize-control .selectized {
          color: var(--se-muted-text) !important;
        }

        input[id$='-selectized'] {
          min-width: 24px !important;
          min-height: 24px !important;
        }

        .box-tools .btn-box-tool {
          min-width: 28px;
          min-height: 28px;
          padding: 3px 4px;
        }

        .btn-xs {
          min-height: 24px;
          padding-top: 3px;
          padding-bottom: 3px;
        }

        .box-body details > summary {
          min-height: 32px;
          padding: 4px 0;
        }

        .param-group-summary:focus-visible {
          outline: 2px solid #1D4ED8;
          outline-offset: 2px;
          border-radius: 4px;
        }

        .selectize-control .selectize-input {
          min-height: 32px;
        }

        .form-control,
        .form-control:disabled,
        .form-control[readonly] {
          color: #495057;
        }

        .form-control::placeholder {
          color: var(--se-muted-text) !important;
          opacity: 1;
        }

        /* Inherited SeuratExplorer body UI may carry older inline accents.
           Map those text colours to AA tones without changing borders. */
        [style*='color: #10b981'] { color: #047857 !important; }
        [style*='color: #3b82f6'] { color: #1D4ED8 !important; }
        [style*='color: #f59e0b'] { color: #B45309 !important; }
        [style*='color: #ec4899'] { color: #BE185D !important; }
        [style*='color: #8b5cf6'] { color: #6D28D9 !important; }
        [style*='color: #6c757d'] { color: #5C636A !important; }
        [style*='color: #06b6d4'] { color: #0E7490 !important; }

        /* Keep native checkbox/radio sizing: Bootstrap positions the input
           with a negative margin, so enlarging it overlaps the label text. */
        .checkbox,
        .radio {
          min-height: 24px;
        }

        .checkbox label,
        .radio label {
          min-height: 24px;
          line-height: 24px;
        }

        /* Responsive optimization */
        @media (max-width: 768px) {
          .content-wrapper {
            padding: 10px;
          }

          .box {
            margin-bottom: 10px;
          }
        }
      "))
    ),
    div(class= "tab-content", tab_list),
    # to hide how many notifications in shinydashboard::dropdownMenu(), refer to:https://stackoverflow.com/questions/65915414/alter-dropdown-menu-in-shiny
    tags$script(HTML("document.querySelector('body > div.wrapper > header > nav > div > ul > li > a > span').style.visibility = 'hidden';")),
    tags$script(HTML("
      (function() {
        document.documentElement.lang = 'en';

        function fixA11y() {
          document.querySelectorAll('.sidebar-menu a[aria-selected]').forEach(function(a) {
            a.removeAttribute('aria-selected');
          });

          document.querySelectorAll('i[aria-label]').forEach(function(i) {
            var label = i.getAttribute('aria-label');
            var control = i.closest('button,a');
            if (control && !control.getAttribute('aria-label') &&
                !control.textContent.trim()) {
              control.setAttribute('aria-label',
                                   control.getAttribute('title') ||
                                   label.replace(/ icon$/, ''));
            }
            i.removeAttribute('aria-label');
            i.setAttribute('aria-hidden', 'true');
          });

          document.querySelectorAll('input[id^=\"clustercolor_\"]').forEach(function(input) {
            if (input.getAttribute('aria-label')) return;
            var row = input.closest('.row');
            var label = row ? row.querySelector('.col-sm-5') : null;
            var text = label ? label.textContent.trim() : '';
            input.setAttribute('aria-label', text ? 'Color for ' + text : 'Cluster color');
          });

          document.querySelectorAll('.main-header .dropdown-toggle').forEach(function(a) {
            if (!a.getAttribute('aria-label') && a.querySelector('.fa-github')) {
              a.setAttribute('aria-label', 'GitHub repositories');
            }
          });

          // Legacy shinyWidgets::downloadBttn wraps an empty Shiny download
          // link in a button. Keep the link out of the tab order.
          document.querySelectorAll('.bttn .shiny-download-link').forEach(function(a) {
            a.style.display = 'none';
            a.setAttribute('aria-hidden', 'true');
            a.setAttribute('tabindex', '-1');
            a.setAttribute('aria-live', 'off');
          });
        }

        fixA11y();
        new MutationObserver(fixA11y).observe(document.body, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ['aria-label', 'role']
        });
      })();
    ")))

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


