# server.R
## shiny server

#' Shiny Server
#' @rawNamespace import(shiny, except=c(dataTableOutput, renderDataTable))
#' @import ggplot2 utils shinydashboard shinyWidgets shinymanager
#' @import Seurat SeuratObject SeuratExplorer data.tree
#' @importFrom plyr rbind.fill
#' @importFrom DT renderDT datatable
#' @importFrom utils getFromNamespace sessionInfo
#' @importFrom stats na.omit
#' @param input Input from the UI
#' @param output Output to send back to UI
#' @param session shiny session
#' @export
#' @return shiny server functions
#'
server <- function(input, output, session) {
  # define some basic functions, ::: is not allowed in R package
  # Using an un-exported function from another R package:
  # https://stackoverflow.com/questions/32535773/using-un-exported-function-from-another-r-package

  explorer_fns <- .import_from_explorer(c(
    "prepare_cluster_options",
    "prepare_qc_options",
    "prepare_reduction_options",
    "prepare_seurat_object",
    "prepare_split_options",
    "readSeurat",
    "updateSeurat",
    "prepare_assays_slots",
    "prepare_assays_options",
    "prepare_gene_annotations"
  ))

  # Assign imported functions to current environment
  list2env(explorer_fns, envir = environment())

  # encrypt
  if (getOption("SeuratExplorerServerEncrypted")){
    res_auth <- shinymanager::secure_server(check_credentials = shinymanager::check_credentials(db = getOption("SeuratExplorerServerCredentials")))
  } else {
    res_auth <- NULL
  }


  # Data set Page
  data_meta <- check_metadata(parameters = readRDS(getOption("SeuratExplorerServerParameterfile")), getOption("SeuratExplorerServerSupportedFiles"))

  # Create an env to store package-specific variables
  .pkg.env <- new.env(parent = emptyenv())
  .pkg.env$cache.rds.list <- list() ## to cache data
  .pkg.env$current_data_name <- NULL ## to record current data name

  # to be deleted
  # ## to cache data
  # cache.rds.list <- list()
  #
  # ## to record current data name
  # current_data_name <- NULL

  ## data information UI
  output$DataList <- renderDT(datatable(data_meta,
                                        class = 'cell-border stripe',
                                        caption = htmltools::tags$caption(
                                          style = 'caption-side: bottom; text-align: center;',
                                          'Table 1: ', htmltools::em('Sample metadata of Data')),
                                        options = list(searching = FALSE, scrollX = T)))


  ## data selection UI
  output$SelectData.UI <- renderUI({
    choices <- data_meta$Rds.full.path
    names(choices)  <- paste0(data_meta$Sample.name, " [",data_meta$Rds.File.size, "]")
    radioButtons(inputId = "Choosendata",
                 label = NULL,
                 choices = choices,
                 selected = unname(choices[1]))
  })

  ## create data
  ## reactiveValues: Create an object for storing reactive values,similar to a list,
  data = reactiveValues(obj = NULL,
                        loaded = FALSE,
                        Name = NULL,
                        Path = NULL,
                        Species = NULL,
                        Description = NULL,
                        reduction_options = NULL,
                        reduction_default = NULL,
                        assays_options = NULL,
                        assay_default = 'RNA',
                        cluster_options = NULL,
                        assay_slots = c('counts', 'data', 'scale.data'),
                        cluster_default = NULL,
                        split_maxlevel = 6,
                        split_options = NULL,
                        gene_annotations_list = NULL,
                        extra_qc_options = NULL)

  ## read in data after data selection
  ## possible problem: when switch data, data$obj will change firstly, while the default reduction and other options is still the previous configuration,
  ## background will throw an error: Warning: Error in [.data.frame: Undefined columns are selected, but the UI will not show the error.
  observeEvent(input$submitdata,{
    shiny::req(input$Choosendata)
    showModal(modalDialog(
      # title = tagList(
      #   icon("spinner", class = "fa-spin"),
      #   " Loading Data..."
      # ),
      div(
        style = "text-align: center; padding: 20px;",
        icon("circle-notch", class = "fa-spin fa-3x", style = "color: #3b82f6; margin-bottom: 15px;"),
        p("Please wait until data is loaded. Large files usually take longer.", style = "color: #6c757d; font-size: 14px;")
      ),
      footer = NULL,
      size = "l"
    ))
    which_data <- match(input$Choosendata, data_meta$Rds.full.path)
    .pkg.env$current_data_name <- data_meta$Sample.name[which_data]
    if (is.null(names(.pkg.env$cache.rds.list)) | !(.pkg.env$current_data_name %in% names(.pkg.env$cache.rds.list))) { # first time load
      data$obj <- prepare_seurat_object(obj = updateSeurat(obj = readSeurat(path = input$Choosendata, verbose = getOption('SeuratExplorerServerVerbose')),
                                                           verbose = getOption('SeuratExplorerServerVerbose')),
                                        verbose = getOption('SeuratExplorerServerVerbose'))
      data$Name <- .pkg.env$current_data_name
      data$Path <- input$Choosendata
      data$Species <- na_to_null(data_meta$Species[which_data]) # if NA value, return NULL
      data$Description <- na_to_null(data_meta$Description[which_data]) # if NA value, return NULL
      data$reduction_options <- prepare_reduction_options(obj = data$obj, keywords = getOption("SeuratExplorerServerReductionKeyWords"))
      data$reduction_default <- na_to_null(data_meta$Default.DimensionReduction[which_data]) # if NA value, return NULL
      data$assays_slots_options <- prepare_assays_slots(ob = data$obj, data_slot = data$assay_slots, verbose = getOption('SeuratExplorerServerVerbose'))
      data$assays_options <- prepare_assays_options(Alist = data$assays_slots_options, verbose = getOption('SeuratExplorerServerVerbose'))
      if (!'Default.Assay' %in% colnames(data_meta)) { # for old version data_meta.rds, there is no Default.Assay column
        data$assay_default <- ifelse(data$assay_default %in% data$assays_options,data$assay_default, data$assays_options[1]) # update the default assay
      }else{
        data$assay_default <- ifelse(data_meta$Default.Assay[which_data] %in% data$assays_options, data_meta$Default.Assay[which_data], data$assays_options[1]) # update the default assay
      }
      data$cluster_options <- prepare_cluster_options(df = data$obj@meta.data)
      data$cluster_default <- na_to_null(data_meta$Default.ClusterResolution[which_data]) # if NA value, return NULL
      data$split_maxlevel <- if(is.na(data_meta$SplitOptions.MaxLevel[which_data])){getOption("SeuratExplorerServerDefaultSplitLevel")}else{data_meta$SplitOptions.MaxLevel[which_data]} # if NA value, use split options level cutoff
      data$split_options <- prepare_split_options(df = data$obj@meta.data, max.level = data$split_maxlevel)
      data$extra_qc_options <- prepare_qc_options(df = data$obj@meta.data, types = c("double","integer","numeric"))
      data$gene_annotations_list <- prepare_gene_annotations(obj = data$obj, verbose = getOption('SeuratExplorerServerVerbose'))
      data$version <- 0
      .pkg.env$cache.rds.list[[.pkg.env$current_data_name]] <- reactiveValuesToList(data)
      # message('Newly loaded data has been cached!')
      # print(names(.pkg.env$cache.rds.list))
    }else{ # for data loaded before
      # message('Loading from cached data!')
      cached <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]
      for (field in names(cached)) {
        data[[field]] <- cached[[field]]
      }
      # to be deleted below
      # data$obj <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$obj
      # data$Name <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$Name
      # data$Path <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$Path
      # data$Species <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$Species
      # data$Description <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$Description
      # data$reduction_options <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$reduction_options
      # data$reduction_default <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$reduction_default
      # data$assays_slots_options <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$assays_slots_options
      # data$assays_options <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$assays_options
      # data$assay_default <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$assay_default
      # data$cluster_options <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$cluster_options
      # data$cluster_default <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$cluster_default
      # data$split_maxlevel <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$split_maxlevel
      # data$split_options <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$split_options
      # data$extra_qc_options <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$extra_qc_options
      # data$gene_annotations_list <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$gene_annotations_list
      # data$version <- .pkg.env$cache.rds.list[[.pkg.env$current_data_name]]$version
    }
    .log_verbose("data loaded successfully!")
    removeModal()
  })

  ## when data loaded successfully, set loaded to TRUE
  observe({
    req(data$obj)
    data$loaded = !is.null(data$obj)
  })

  ## Conditional panel control based on loaded obj
  output$file_loaded = reactive({
    return(data$loaded)
  })

  ############################### Render Session Info
  output$sessioninfo <- renderPrint({
    sessionInfo()
  })

  ## Disable suspend for output$file_loaded
  ## When TRUE (the default), the output object will be suspended (not execute) when it is hidden on the web page.
  ## When FALSE, the output object will not suspend when hidden, and if it was already hidden and suspended, then it will resume immediately.
  outputOptions(output, 'file_loaded', suspendWhenHidden=FALSE)

  # Reports page
  output$DirectoryTree <- renderPrint({
    path <- gsub("//+","/",data_meta$Reports.main)
    # https://stackoverflow.com/questions/36094183/how-to-build-a-dendrogram-from-a-directory-tree
    x <- lapply(strsplit(path, "/"), function(z) as.data.frame(t(z)))
    x <- rbind.fill(x)
    equal.index <- apply(x, 2, function(x)length(unique(x)) == 1)
    if (all(equal.index)) {
      x <- x[,(ncol(x) - 1):ncol(x)]
    }else{
      x <- x[,(min(which(!equal.index)) - 1) : ncol(x)]
    }
    x$pathString <- apply(x, 1, function(x) paste(trimws(na.omit(x)), collapse="/"))
    x$SampleName <- data_meta$Sample.name
    mytree <- data.tree::as.Node(x)
    .log_verbose("Preparing DirectoryTree...")
    # print(mytree, "SampleName")
  }, width = 300) # max 300 characters allowed for each line

  reports_dir <- paste0("../", basename(getwd()), "_reports")

  ## to show data web address
  output$reports_not_work <- renderText({
    .log_verbose("Preparing reports_not_work...")
    full_URL = paste0(session$clientData$url_protocol, "//",session$clientData$url_hostname,":",session$clientData$url_port,session$clientData$url_pathname)
    reports_URL = paste0(dirname(full_URL), "/", basename(reports_dir),"/")
    paste(sep = "",
          "protocol: ", session$clientData$url_protocol, "\n",
          "hostname: ", session$clientData$url_hostname, "\n",
          "pathname: ", session$clientData$url_pathname, "\n",
          "port: ",     session$clientData$url_port,     "\n",
          "search: ",   session$clientData$url_search,   "\n",
          "full url: ",      full_URL,     "\n",
          "reports url: ",      reports_URL,     "\n",
          "\n",
          "Attention: Reports function not work by using this kind of url [only IP + port], pathname should be included."
    )
  })

  # click generate reports button to update or generate reports web page, and add a view reports button to link the analysis results
  observeEvent(input$generatereports,{
    if (!dir.exists(reports_dir)) { # generate reports directory
      showModal(modalDialog(
        title = tagList(
          icon("spinner", class = "fa-spin"),
          " Generating Reports..."
        ),
        div(
          style = "text-align: center; padding: 20px;",
          icon("circle-notch", class = "fa-spin fa-3x", style = "color: #f59e0b; margin-bottom: 15px;"),
          p("Please wait while reports are being generated...", style = "color: #6c757d; font-size: 14px;")
        ),
        footer = NULL,
        size = "l"
      ))
    }else{ # update reports directory
      showModal(modalDialog(
        title = tagList(
          icon("spinner", class = "fa-spin"),
          " Updating Reports..."
        ),
        div(
          style = "text-align: center; padding: 20px;",
          icon("circle-notch", class = "fa-spin fa-3x", style = "color: #10b981; margin-bottom: 15px;"),
          p("Please wait while reports are being updated...", style = "color: #6c757d; font-size: 14px;")
        ),
        footer = NULL,
        size = "l"
      ))
      unlink(reports_dir, recursive = TRUE)
    }
    dir.create(reports_dir)
    .log_verbose("Preparing the reports direcotry, Please wait a moment...")
    prepare_reports(reports_dir = reports_dir, data_meta = data_meta, file_types_included = getOption("SeuratExplorerServerReportsFileTypes"))
    removeModal()
    output$ViewReports.UI <- renderUI({ # generate view reports UI
      .log_verbose("Preparing ReportURL.UI...")
      if (session$clientData$url_pathname == "/") {
        verbatimTextOutput(outputId = "reports_not_work")
      }else{
        full_URL = paste0(session$clientData$url_protocol, "//",session$clientData$url_hostname,":",session$clientData$url_port,session$clientData$url_pathname)
        reports_URL = paste0(dirname(full_URL), "/", basename(reports_dir),"/")
        # https://stackoverflow.com/questions/37795760/r-shiny-add-weblink-to-actionbutton
        .log_verbose(paste0("Reports url: ", reports_URL))
        div(style = "text-align: center;",
          actionButton(inputId='openreportswebpage',
                       label="View/Download Reports",
                       onclick = paste0("window.open('", reports_URL, "','_blank')"),
                       icon = icon("file-alt"),
                       class = "btn-primary btn-lg",
                       style = "padding: 12px 35px; border-radius: 8px; font-weight: 600; background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); border: none; box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);")
        )
      }
    })
  })

  # Seurat explorer functions
  SeuratExplorer::explorer_server(input = input, output = output, session = session, data = data, verbose = getOption("SeuratExplorerServerVerbose"))

  # update the cache.rds.list when Rename Clusters - submit button clicked
  observeEvent(data$version, {
    req(data$obj)
    if (.pkg.env$current_data_name == data$Name & data$version != 0) {
      .pkg.env$cache.rds.list[[data$Name]] <- reactiveValuesToList(data)
      .log_verbose("Cache data updated!")
    }
  })

  # settings
  ## Warning
  output$settings_warning = renderText({
    paste0('Note: modifications take effect next time you open this app. Only one sample can be modified at each time.')
  })

  output$InfoForDataOpened <- renderText({
    .log_verbose("Preparing InfoForDataOpened...")
    which_data <- match(data$Path, data_meta$Rds.full.path)
    paste(sep = "",
          "Data Opened: ",               .pkg.env$current_data_name,     "\n",
          "\n",
          "Parameters bellow can not be modified, Contact technician if you want to make a change:\n",
          "\n",
          "Main Reports Directory: ",    data_meta$Reports.main[which_data],    "\n",
          "Data Relative Path: ",        data_meta$Rds.path[which_data],        "\n",
          "SecondaryReports Directory:", data_meta$Reports.second[which_data],  "\n"
    )
  })

  output$SetSampleName.UI <- renderUI({
    .log_verbose("Preparing SetSampleName.UI...")
    textInput(inputId = "NewName", label = "Sample Name:", value = data$Name, placeholder = "Suggest only use letters, numbers, undersocres, and not too long.")
  })

  output$SetSpecies.UI <- renderUI({
    .log_verbose("Preparing SetSpecies.UI...")
    selectInput(inputId = "NewSpecies", label = "Choose the Species:", choices = c(Human = "Human", Mouse = "Mouse", Fly = "Fly", Others = "Others"), selected = data$Species)
  })

  output$SetDescription.UI <- renderUI({
    .log_verbose("Preparing SetDescription.UI...")
    textAreaInput(inputId = "NewDescription", label = "Sample Description:", value = data$Description, placeholder = "Do not use special characters")
  })

  output$SetDefaultReduction.UI <- renderUI({
    .log_verbose("Preparing SetDefaultReduction.UI...")
    selectInput("NewDefaultReduction", "Dimension Reduction:", choices = data$reduction_options, selected = data$reduction_default)
  })

  output$SetDefaultCluster.UI <- renderUI({
    .log_verbose("Preparing SetDefaultCluster.UI...")
    selectInput("NewDefaultCluster","Cluster Resolution:", choices = data$cluster_options, selected = data$cluster_default)
  })

  output$SetDefaultAssay.UI <- renderUI({
    .log_verbose("Preparing SetDefaultAssay.UI...")
    selectInput("NewDefaultAssay","Default Assay:", choices = data$assays_options, selected = data$assay_default)
  })

  output$SetDefaultSplitMaxLevels.UI <- renderUI({
    .log_verbose("Preparing SetDefaultSplitMaxLevels.UI...")
    sliderInput("NewSplitMaxLevel", label = "Max Split Level:", min = 1, max = 50, value = data$split_maxlevel)
  })

  observeEvent(input$submitsettings,{
    # 1. check Name
    if(trimws(input$NewName) == ""){
      showModal(modalDialog(
        title = tagList(
          icon("exclamation-triangle", style = "color: #ef4444;"),
          " Error"
        ),
        div(
          style = "text-align: center; padding: 20px;",
          icon("times-circle", class = "fa-3x", style = "color: #ef4444; margin-bottom: 15px;"),
          p("Sample name cannot be empty. Please enter a valid name.", style = "color: #6c757d; font-size: 14px;")
        ),
        easyClose = TRUE,
        footer = NULL
      ))
    }else{
      which_data <- match(data$Path, data_meta$Rds.full.path)
      if( !'Default.Assay' %in% colnames(data_meta)){ # for old version data.meta file, there is no Default.Assay column
        data_meta$Default.Assay <- 'RNA'
      }
      data_meta_new <- data_meta
      data_meta_new$Sample.name[which_data] <- input$NewName
      data_meta_new$Species[which_data] <- input$NewSpecies
      data_meta_new$Description[which_data] <- ifelse(trimws(input$NewDescription) == "", NA, input$NewDescription)
      data_meta_new$Default.DimensionReduction[which_data] <- input$NewDefaultReduction
      data_meta_new$Default.ClusterResolution[which_data] <- input$NewDefaultCluster
      data_meta_new$Default.Assay[which_data] <- input$NewDefaultAssay
      data_meta_new$SplitOptions.MaxLevel[which_data] <- input$NewSplitMaxLevel
      data_meta_new$Rds.full.path <- NULL
      data_meta_new$Rds.File.size <- NULL
      saveRDS(data_meta_new, file = getOption("SeuratExplorerServerParameterfile"))
      # R Shiny app shows old data
      # https://stackoverflow.com/questions/37408072/r-shiny-app-shows-old-data
      p <- paste0(getwd(), "/app.R")
      if(file.exists(p)){
        print("update app.R file, in case of Shiny not refresh when restart.")
        R.utils::touchFile(p)}
      showModal(modalDialog(
        title = tagList(
          icon("check-circle", style = "color: #10b981;"),
          " Success"
        ),
        div(
          style = "text-align: center; padding: 20px;",
          icon("check-circle", class = "fa-3x", style = "color: #10b981; margin-bottom: 15px;"),
          p("New settings have been saved successfully.", style = "color: #6c757d; font-size: 14px; margin-bottom: 10px;"),
          p(strong("Please restart the App to use the latest settings."), style = "color: #f59e0b; font-size: 13px;")
        ),
        easyClose = TRUE,
        footer = NULL
      ))
      removeUI(selector = "div:has(> #NewName)")
      removeUI(selector = "div:has(> #NewSpecies)")
      removeUI(selector = "div:has(> #NewDescription)")
      removeUI(selector = "div:has(> #NewDefaultReduction)")
      removeUI(selector = "div:has(> #NewDefaultCluster)")
      removeUI(selector = "div:has(> #NewDefaultAssay)")
      removeUI(selector = "div:has(> #NewSplitMaxLevel)")
      removeUI(selector = "div:has(> #submitsettings)")
    }
  })


  ############################### Comments (message board)
  comments_file <- getOption("SeuratExplorerServerCommentsFile")

  comments <- reactiveVal(load_comments(comments_file))

  # Refresh the comment board (called after local writes, and periodically to
  # pick up comments posted by other users). Only re-assign when the content
  # actually changed, to avoid needless re-renders every polling interval.
  reload_comments <- function() {
    new <- load_comments(comments_file)
    if (!identical(comments(), new)) comments(new)
  }
  observe({
    invalidateLater(30000)
    reload_comments()
  })

  current_user <- reactive({
    if (!is.null(res_auth) && !is.null(res_auth$user)) as.character(res_auth$user) else ""
  })

  is_technician <- reactive({
    if (!getOption("SeuratExplorerServerEncrypted")) return(TRUE)
    u <- current_user()
    nzchar(u) && u %in% getOption("SeuratExplorerServerTechnicianUser")
  })

  # stable id (Rds.path) -> sample name lookup
  sample_choices <- reactive({
    stats::setNames(data_meta$Rds.path, data_meta$Sample.name)
  })

  sample_name_of <- function(sample_id) {
    m <- match(sample_id, data_meta$Rds.path)
    ifelse(is.na(m), sample_id, data_meta$Sample.name[m])
  }

  comment_display_name <- function(user_id, user_id_optional) {
    nm <- if (!is.na(user_id_optional) && nzchar(user_id_optional)) user_id_optional else user_id
    if (is.na(nm) || !nzchar(nm)) "(anonymous)" else nm
  }

  comment_snippet <- function(x, n = 40) {
    if (is.na(x) || !nzchar(x)) return("")
    x <- gsub("\\s+", " ", trimws(x))
    if (nchar(x) > n) paste0(substr(x, 1, n), "...") else x
  }

  reply_parent <- function(all_df, reply_to) {
    if (is.na(reply_to) || !nzchar(reply_to)) return(NULL)
    parent_id <- suppressWarnings(as.integer(reply_to))
    if (is.na(parent_id)) return(NULL)
    row <- all_df[all_df$id %in% parent_id, , drop = FALSE]
    if (nrow(row) == 0) {
      return(list(name = "(deleted)", snippet = "", deleted = TRUE))
    }
    if (row$deleted[1] %in% TRUE) {
      return(list(name = comment_display_name(row$user_id[1], row$user_id_optional[1]), snippet = "", deleted = TRUE))
    }
    list(
      name = comment_display_name(row$user_id[1], row$user_id_optional[1]),
      snippet = comment_snippet(row$content[1]),
      deleted = FALSE
    )
  }

  output$comment_current_user <- renderText({
    u <- current_user()
    if (nzchar(u)) u else "(anonymous)"
  })

  output$comment_filter_ui <- renderUI({
    choices <- c("All samples" = "All", sample_choices())
    selectInput("comment_filter", "Filter by sample:", choices = choices, selected = "All", width = "100%")
  })

  output$comment_sample_ui <- renderUI({
    choices <- sample_choices()
    sel <- NULL
    cur <- data$Name
    if (!is.null(cur) && cur %in% names(choices)) {
      sel <- unname(choices[cur])
    }
    selectInput("comment_sample", "Data:", choices = choices, selected = sel, width = "100%")
  })

  filtered_comments <- reactive({
    df <- comments()
    if (is.null(df) || nrow(df) == 0) return(df)
    df <- df[!(df$deleted %in% TRUE), , drop = FALSE]
    f <- input$comment_filter
    if (!is.null(f) && nzchar(f) && f != "All") {
      df <- df[df$sample_id %in% f, , drop = FALSE]
    }
    df
  })

  avatar_color <- function(name) {
    palette <- c("#3b82f6", "#10b981", "#8b5cf6", "#f59e0b", "#06b6d4", "#ef4444", "#6366f1", "#14b8a6")
    s <- sum(utf8ToInt(name))
    palette[(s %% length(palette)) + 1]
  }

  comment_action_button <- function(id, type, label, icon_name, extra_class = "btn-default") {
    tags$button(
      id = paste0("comment_", type, "_", id),
      type = "button",
      class = paste("btn btn-xs", extra_class),
      onclick = sprintf("Shiny.setInputValue('comment_action', {type:'%s', id:%d}, {priority:'event'});", type, as.integer(id)),
      icon(icon_name), label
    )
  }

  thread_rows <- function(df) {
    if (is.null(df) || nrow(df) == 0) return(df)
    pid <- vapply(seq_len(nrow(df)), function(i) {
      x <- df$reply_to[i]
      if (is.na(x) || !nzchar(x)) NA_integer_ else suppressWarnings(as.integer(x))
    }, integer(1))
    valid_ids <- df$id
    is_top <- is.na(pid) | !(pid %in% valid_ids)
    out <- integer()
    indent <- integer()
    walk <- function(id, lvl) {
      if (lvl > 12) return()
      out <<- c(out, id)
      indent <<- c(indent, lvl)
      kids <- sort(valid_ids[which(pid == id)])
      for (k in kids) walk(k, lvl + 1L)
    }
    for (t in sort(valid_ids[is_top])) walk(t, 0L)
    df2 <- df[match(out, valid_ids), , drop = FALSE]
    df2$indent <- indent
    df2
  }

  comment_card <- function(row, is_tech, all_df) {
    name <- comment_display_name(row$user_id, row$user_id_optional)
    sname <- sample_name_of(row$sample_id)
    resolved <- row$is_resolved %in% TRUE
    reply_ctx <- reply_parent(all_df, row$reply_to)
    indent <- row$indent
    if (is.null(indent) || is.na(indent)) indent <- 0L
    initial <- toupper(substr(name, 1, 1))
    if (!nzchar(initial)) initial <- "?"
    card_border <- if (indent > 0) "#cbd5e1" else "#06b6d4"
    card <- div(
      style = sprintf("background: white; border: 1px solid #e5e7eb; border-left: 4px solid %s; border-radius: 8px; padding: 14px 16px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.06);", card_border),
      div(
        style = "display: flex; align-items: flex-start; gap: 12px;",
        div(
          style = sprintf("flex-shrink: 0; width: 36px; height: 36px; border-radius: 50%%; background: %s; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 15px;", avatar_color(name)),
          initial
        ),
        div(
          style = "flex: 1; min-width: 0;",
          div(
            style = "display: flex; align-items: center; gap: 8px; flex-wrap: wrap;",
            strong(name, style = "font-size: 14px; color: #1f2937;"),
            tags$span(class = "label label-primary", style = "font-size: 11px; padding: 2px 6px;", sname),
            if (resolved) tags$span(class = "label label-success", style = "font-size: 11px; padding: 2px 6px;", "Resolved"),
            tags$span(row$created_at, style = "margin-left: auto; color: #9ca3af; font-size: 12px;")
          ),
          div(
            style = "margin-top: 6px; color: #374151; line-height: 1.6; white-space: pre-wrap; word-break: break-word;",
            row$content
          ),
          div(
            style = "margin-top: 8px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap;",
            if (!is.null(reply_ctx)) tags$span(
              style = "color: #6b7280; font-size: 12px; background: #f3f4f6; padding: 2px 8px; border-radius: 10px; max-width: 100%;",
              icon("reply"), " Reply to ", strong(reply_ctx$name),
              if (reply_ctx$deleted) " (deleted)" else if (nzchar(reply_ctx$snippet)) paste0(": \"", reply_ctx$snippet, "\"") else ""
            ),
            comment_action_button(row$id, "reply", "Reply", "reply"),
            if (is_tech && !resolved) comment_action_button(row$id, "resolve", "Resolve", "check-circle", "btn-success"),
            if (is_tech) comment_action_button(row$id, "delete", "Delete", "trash", "btn-danger")
          )
        )
      )
    )
    if (indent > 0) {
      div(
        style = sprintf("margin-left: %dpx; border-left: 2px solid #e0e7ef; padding-left: 12px;", min(as.integer(indent) * 24L, 96L)),
        card
      )
    } else {
      card
    }
  }

  output$comments_list <- renderUI({
    df <- filtered_comments()
    if (is.null(df) || nrow(df) == 0) {
      return(div(
        style = "text-align: center; padding: 30px 10px; color: #9ca3af;",
        icon("comment-dots", class = "fa-2x"),
        p("No comments yet. Post the first one below!", style = "margin-top: 10px;")
      ))
    }
    tech <- is_technician()
    df <- thread_rows(df)
    all_df <- comments()
    do.call(tagList, lapply(seq_len(nrow(df)), function(i) comment_card(df[i, , drop = FALSE], tech, all_df)))
  })

  reply_target <- reactiveVal(NULL)

  observeEvent(input$cancel_reply, {
    reply_target(NULL)
  })

  output$comment_reply_indicator <- renderUI({
    id <- reply_target()
    if (is.null(id)) return(NULL)
    df <- comments()
    row <- df[df$id %in% id, , drop = FALSE]
    if (nrow(row) == 0) {
      reply_target(NULL)
      return(NULL)
    }
    snip <- comment_snippet(row$content)
    div(
      style = "margin-top: 10px; padding: 8px 12px; background: #e0f2fe; border-left: 3px solid #06b6d4; border-radius: 4px; display: flex; align-items: center; gap: 10px;",
      span(
        style = "color: #0c4a6e;",
        "Replying to ", strong(comment_display_name(row$user_id, row$user_id_optional)),
        if (nzchar(snip)) paste0(": \"", snip, "\"") else ""
      ),
      actionLink("cancel_reply", "Cancel")
    )
  })

  observeEvent(input$submit_comment, {
    content <- input$comment_content
    content <- if (is.null(content)) "" else trimws(content)
    if (!nzchar(content)) {
      showNotification("Comment cannot be empty.", type = "error")
      return(NULL)
    }
    sample_id <- input$comment_sample
    if (is.null(sample_id) || !nzchar(sample_id)) {
      showNotification("Please select a dataset.", type = "error")
      return(NULL)
    }
    realname <- input$comment_realname
    realname <- if (is.null(realname)) "" else trimws(realname)
    rt <- reply_target()
    ok <- tryCatch({
      add_comment(comments_file,
                  user_id = current_user(),
                  user_id_optional = realname,
                  sample_id = sample_id,
                  content = content,
                  reply_to = if (is.null(rt)) "" else as.character(rt))
      TRUE
    }, error = function(e) {
      showNotification(paste("Could not post comment:", conditionMessage(e)), type = "error")
      FALSE
    })
    if (ok) {
      reply_target(NULL)
      updateTextAreaInput(session, "comment_content", value = "")
      reload_comments()
      showNotification("Comment posted.", type = "message")
    }
  })

  observeEvent(input$comment_action, {
    a <- input$comment_action
    if (is.null(a) || is.null(a$type) || is.null(a$id)) return(NULL)
    type <- a$type
    id <- as.integer(a$id)
    if (type == "reply") {
      reply_target(id)
    } else if (type == "resolve" && is_technician()) {
      ok <- tryCatch({
        update_comment(comments_file, id, is_resolved = TRUE)
        TRUE
      }, error = function(e) {
        showNotification(paste("Could not update comment:", conditionMessage(e)), type = "error")
        FALSE
      })
      if (ok) reload_comments()
    } else if (type == "delete" && is_technician()) {
      ok <- tryCatch({
        update_comment(comments_file, id, deleted = TRUE)
        TRUE
      }, error = function(e) {
        showNotification(paste("Could not delete comment:", conditionMessage(e)), type = "error")
        FALSE
      })
      if (ok) reload_comments()
    }
  })

  # do something when session ended
  session$onSessionEnded(function() {
    reports_dir <- paste0("../", basename(getwd()), "_reports")
    if (!getOption("SeuratExplorerServerEncrypted")){
      if(dir.exists(reports_dir)){unlink(reports_dir, recursive = TRUE)}
      print('Hello, the session finally ended!')
    }else if(!is.null(isolate({res_auth$user}))){ # attention: shinymanager load can also cause session ended
      if(dir.exists(reports_dir)){unlink(reports_dir, recursive = TRUE)}
      print('Hello, the session finally ended!')
    }
  })

  # Current Data Overview
  output$CurrentDataOverview <- renderUI({
    req(data$obj)

    obj <- data$obj

    # Calculate stats
    total_cells <- ncol(obj)
    total_genes <- nrow(obj)
    n_clusters <- length(unique(Seurat::Idents(obj)))
    n_assays <- length(Seurat::Assays(obj))

    # Stat card helper: color-coded card with an icon and label/value
    stat_card <- function(icon_name, label, value, color) {
      div(
        style = sprintf("background: white; padding: 15px; border-radius: 6px; border-left: 4px solid %s; box-shadow: 0 1px 3px rgba(0,0,0,0.05);", color),
        div(
          style = "color: #6c757d; font-size: 12px; margin-bottom: 5px; display: flex; align-items: center; gap: 6px;",
          icon(icon_name, style = sprintf("color: %s;", color)),
          label
        ),
        div(style = sprintf("color: %s; font-size: 18px; font-weight: 600;", color), value)
      )
    }

    div(
      style = "padding: 20px; background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border: 2px solid #e9ecef; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 8px rgba(0,0,0,0.08);",
      h4(
        style = "color: #495057; margin-bottom: 20px; display: flex; align-items: center; gap: 10px;",
        icon("chart-bar", style = "color: #495057;"),
        "Current Data Overview"
      ),
      div(
        style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px;",
        stat_card("folder-open", "Current Data", format(data$Name, big.mark = ","), "#f59e0b"),
        stat_card("microscope", "Total Cells", format(total_cells, big.mark = ","), "#3b82f6"),
        stat_card("dna", "Total Genes", format(total_genes, big.mark = ","), "#10b981"),
        stat_card("chart-pie", "Clusters", n_clusters, "#8b5cf6"),
        stat_card("flask", "Assays", n_assays, "#06b6d4")
      )
    )
  })
}
