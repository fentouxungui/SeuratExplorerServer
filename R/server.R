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
  prepare_cluster_options <- getFromNamespace('prepare_cluster_options', 'SeuratExplorer')
  prepare_qc_options <- getFromNamespace('prepare_qc_options', 'SeuratExplorer')
  prepare_reduction_options <- getFromNamespace('prepare_reduction_options', 'SeuratExplorer')
  prepare_seurat_object <- getFromNamespace('prepare_seurat_object', 'SeuratExplorer')
  prepare_split_options <- getFromNamespace('prepare_split_options', 'SeuratExplorer')
  readSeurat <- getFromNamespace('readSeurat', 'SeuratExplorer')
  prepare_assays_options <- getFromNamespace('prepare_assays_options', 'SeuratExplorer')
  prepare_gene_annotations <- getFromNamespace('prepare_gene_annotations', 'SeuratExplorer')

  # encrypt
  if (getOption("SeuratExplorerServerEncrypted")){
    res_auth <- shinymanager::secure_server(check_credentials = shinymanager::check_credentials(db = getOption("SeuratExplorerServerCredentials")))
  }


  # Data set Page
  data_meta <- check_metadata(parameters = readRDS(getOption("SeuratExplorerServerParamterfile")), getOption("SeuratExplorerServerSupportedFiles"))

  ## to cache data
  cache.rds.list <- list()
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
  data = reactiveValues(obj = NULL, loaded = FALSE, Name = NULL, Path = NULL,
                        Species = NULL, Description = NULL,
                        reduction_options = NULL, reduction_default = NULL,
                        assays_options = NULL, assay_default = 'RNA',
                        cluster_options = NULL, cluster_default = NULL,
                        split_maxlevel = 6, split_options = NULL, gene_annotions_list = NULL,
                        extra_qc_options = NULL)


  ## read in data after data selection
  ## possible problem: when switch data, data$obj will change firstly, while the default reduction and other options is still the previous configuration,
  ## background will throw an error: Warning: Error in [.data.frame: Undefined columns are selected, but the UI will not show the error.
  observeEvent(input$submitdata,{
    shiny::req(input$Choosendata)
    showModal(modalDialog(title = "Loading data...", "Please wait until data loaded! large file usually takes longer.", footer= NULL, size = "l"))
    which_data <- match(input$Choosendata, data_meta$Rds.full.path)
    if (is.null(names(cache.rds.list)) | !(data_meta$Sample.name[which_data] %in% names(cache.rds.list))) { # first time load
      data$obj <- prepare_seurat_object(obj = readSeurat(path = input$Choosendata), verbose = getOption('SeuratExplorerServerVerbose'))
      data$Name <- data_meta$Sample.name[which_data]
      data$Path <- input$Choosendata
      data$Species <- if(is.na(data_meta$Species[which_data])){NULL}else{data_meta$Species[which_data]} # if NA value, return NULL
      data$Description <- if(is.na(data_meta$Description[which_data])){NULL}else{data_meta$Description[which_data]} # if NA value, return NULL
      data$reduction_options <- prepare_reduction_options(obj = data$obj, keywords = getOption("SeuratExplorerServerReductionKeyWords"))
      data$reduction_default <- if(is.na(data_meta$Default.DimensionReduction[which_data])){NULL}else{data_meta$Default.DimensionReduction[which_data]} # if NA value, return NULL
      data$assays_options <- prepare_assays_options(obj = data$obj, verbose = getOption('SeuratExplorerServerVerbose')) # update assay options
      if (!'Default.Assay' %in% colnames(data_meta)) { # for old version data_meta.rds, there is no Default.Assay column
        data$assay_default <- ifelse(data$assay_default %in% data$assays_options,data$assay_default, data$assays_options[1]) # update the default assay
      }else{
        data$assay_default <- ifelse(data_meta$Default.Assay[which_data] %in% data$assays_options, data_meta$Default.Assay[which_data], data$assays_options[1]) # update the default assay
      }
      data$cluster_options <- prepare_cluster_options(df = data$obj@meta.data)
      data$cluster_default <- if(is.na(data_meta$Default.ClusterResolution[which_data])){NULL}else{data_meta$Default.ClusterResolution[which_data]} # if NA value, return NULL
      data$split_maxlevel <- if(is.na(data_meta$SplitOptions.MaxLevel[which_data])){getOption("SeuratExplorerServerDefaultSplitLevel")}else{data_meta$SplitOptions.MaxLevel[which_data]} # if NA value, use split options level cutoff
      data$split_options <- prepare_split_options(df = data$obj@meta.data, max.level = data$split_maxlevel)
      data$extra_qc_options <- prepare_qc_options(df = data$obj@meta.data, types = c("double","integer","numeric"))
      data$gene_annotions_list <- prepare_gene_annotations(obj = data$obj, verbose = getOption('SeuratExplorerServerVerbose'))
      cache.rds.list[[data_meta$Sample.name[which_data]]] <<- reactiveValuesToList(data)
      # message('Newly loaded data has been cached!')
      # print(names(cache.rds.list))
    }else{ # for data loaded before
      # message('Loadded from Cached data!')
      data$obj <- cache.rds.list[[data_meta$Sample.name[which_data]]]$obj
      data$Name <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Name
      data$Path <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Path
      data$Species <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Species
      data$Description <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Description
      data$reduction_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$reduction_options
      data$reduction_default <- cache.rds.list[[data_meta$Sample.name[which_data]]]$reduction_default
      data$assays_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$assays_options
      data$assay_default <- cache.rds.list[[data_meta$Sample.name[which_data]]]$assay_default
      data$cluster_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$cluster_options
      data$cluster_default <- cache.rds.list[[data_meta$Sample.name[which_data]]]$cluster_default
      data$split_maxlevel <- cache.rds.list[[data_meta$Sample.name[which_data]]]$split_maxlevel
      data$split_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$split_options
      data$extra_qc_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$extra_qc_options
      data$gene_annotions_list <- cache.rds.list[[data_meta$Sample.name[which_data]]]$gene_annotions_list
    }
    if(getOption("SeuratExplorerServerVerbose")){message("data loaded successfully!")}
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
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing DirectoryTree...")}
    print(mytree, "SampleName")
  }, width = 300) # max 300 characters allowed for each line

  reports_dir <- paste0("../", basename(getwd()), "_reports")

  ## to show data web address
  output$reports_not_work <- renderText({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing reports_not_work...")}
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
      showModal(modalDialog(title = "Generating reports...", "Please wait...", footer= NULL, size = "l"))
    }else{ # update reports directory
      showModal(modalDialog(title = "Updating reports...", "Please wait...", footer= NULL, size = "l"))
      unlink(reports_dir, recursive = TRUE)
    }
    dir.create(reports_dir)
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing the reports direcotry, Please wait a moment...")}
    prepare_reports(reports_dir = reports_dir, data_meta = data_meta, file_types_included = getOption("SeuratExplorerServerReportsFileTypes"))
    removeModal()
    output$ViewReports.UI <- renderUI({ # generate view reports UI
      if(getOption("SeuratExplorerServerVerbose")){message("Preparing ReportURL.UI...")}
      if (session$clientData$url_pathname == "/") {
        verbatimTextOutput(outputId = "reports_not_work")
      }else{
        full_URL = paste0(session$clientData$url_protocol, "//",session$clientData$url_hostname,":",session$clientData$url_port,session$clientData$url_pathname)
        reports_URL = paste0(dirname(full_URL), "/", basename(reports_dir),"/")
        # https://stackoverflow.com/questions/37795760/r-shiny-add-weblink-to-actionbutton
        if(getOption("SeuratExplorerServerVerbose")){message(paste0("Reports url: ", reports_URL))}
        actionButton(inputId='openreportswebpage',
                     label="View/Download Reports",
                     onclick = paste0("window.open('", reports_URL, "','_blank')"),
                     icon = icon("file"),
                     class = "btn-primary")
      }
    })
  })



  # Seurat explorer functions
  SeuratExplorer::explorer_server(input = input, output = output, session = session, data = data, verbose = getOption("SeuratExplorerServerVerbose"))

  # settings
  ## Warning
  output$settings_warning = renderText({
    paste0('Note: modifications take effect next time you open this app. Only one sample can be modified at each time.')
  })

  output$InfoForDataOpened <- renderText({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing InfoForDataOpened...")}
    which_data <- match(data$Path, data_meta$Rds.full.path)
    paste(sep = "",
          "Data Opened: ",               data_meta$Sample.name[which_data],     "\n",
          "\n",
          "Parameters bellow can not be modified, Contact technician if you want to make a change:\n",
          "\n",
          "Main Reports Directory: ",    data_meta$Reports.main[which_data],    "\n",
          "Data Relative Path: ",        data_meta$Rds.path[which_data],        "\n",
          "SecondaryReports Directory:", data_meta$Reports.second[which_data],  "\n"
    )
  })

  output$SetSampleName.UI <- renderUI({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing SetSampleName.UI...")}
    textInput(inputId = "NewName", label = "Sample Name:", value = data$Name, placeholder = "Suggest only use letters, numbers, undersocres, and not too long.")
  })

  output$SetSpecies.UI <- renderUI({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing SetSpecies.UI...")}
    selectInput(inputId = "NewSpecies", label = "Choose the Species:", choices = c(Human = "Human", Mouse = "Mouse", Fly = "Fly", Others = "Others"), selected = data$Species)
  })

  output$SetDescription.UI <- renderUI({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing SetDescription.UI...")}
    textAreaInput(inputId = "NewDescription", label = "Sample Description:", value = data$Description, placeholder = "Do not use special characters")
  })

  output$SetDefaultReduction.UI <- renderUI({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing SetDefaultReduction.UI...")}
    selectInput("NewDefaultReduction", "Dimension Reduction:", choices = data$reduction_options, selected = data$reduction_default)
  })

  output$SetDefaultCluster.UI <- renderUI({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing SetDefaultCluster.UI...")}
    selectInput("NewDefaultCluster","Cluster Resolution:", choices = data$cluster_options, selected = data$cluster_default)
  })

  output$SetDefaultAssay.UI <- renderUI({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing SetDefaultAssay.UI...")}
    selectInput("NewDefaultAssay","Default Assay:", choices = data$assays_options, selected = data$assay_default)
  })

  output$SetDefaultSplitMaxLevels.UI <- renderUI({
    if(getOption("SeuratExplorerServerVerbose")){message("Preparing SetDefaultSplitMaxLevels.UI...")}
    sliderInput("NewSplitMaxLevel", label = "Max Split Level:", min = 1, max = 50, value = data$split_maxlevel)
  })

  observeEvent(input$submitsettings,{
    # 1. check Name
    if(trimws(input$NewName) == ""){
      showModal(modalDialog(title = "Error:","Sample name can not be empty.",easyClose = TRUE,footer = NULL))
    }else{
      which_data <- match(data$Path, data_meta$Rds.full.path)
      if( !'Default.Assay' %in% colnames(data_meta)){ # for old version data.meta file, there is no Default.Assay column
        data_meta$Defaul.Assay <- 'RNA'
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
      saveRDS(data_meta_new, file = getOption("SeuratExplorerServerParamterfile"))
      # R Shiny app shows old data
      # https://stackoverflow.com/questions/37408072/r-shiny-app-shows-old-data
      p <- paste0(getwd(), "/app.R")
      if(file.exists(p)){
        print("update app.R file, in case of Shiny not refresh when restart.")
        R.utils::touchFile(p)}
      showModal(modalDialog(title = "Success:","New settings has beed saved successfully. restart App to use the latest settings.",easyClose = TRUE,footer = NULL))
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
}
