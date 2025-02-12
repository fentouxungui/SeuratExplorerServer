# server.R
## R shiny server side for SeuratExplorer

#' Server for SeuratExplorer shiny app
#' @import shiny ggplot2 utils
#' @import Seurat SeuratObject SeuratExplorer
#' @param input Input from the UI
#' @param output Output to send back to UI
#' @param session from shiny server function
#' @export
server <- function(input, output, session) {
  requireNamespace("Seurat")
  requireNamespace("ggplot2")
  requireNamespace("shinyWidgets")
  requireNamespace("shinydashboard")
  requireNamespace("SeuratObject")
  requireNamespace("shinymanager")
  requireNamespace("data.tree")
  requireNamespace("plyr")
  requireNamespace("SeuratExplorer")
  requireNamespace("R.utils")
  requireNamespace("utils")

  # 加密
  if (Encrypted.server) {
    res_auth <- shinymanager::secure_server(check_credentials = shinymanager::check_credentials(db = credentials.server))
  }


  ############################################################# Dataset Page
  # 用于缓存数据
  cache.rds.list <- list()
  # 展示元数据
  output$DataList <- DT::renderDataTable(DT::datatable(data_meta,
                                                       class = 'cell-border stripe',
                                                       caption = htmltools::tags$caption(
                                                         style = 'caption-side: bottom; text-align: center;',
                                                         'Table 1: ', htmltools::em('Sample metadata for this App')),
                                                       options = list(searching = FALSE, scrollX = T))
  )


  # 返回数据选择UI
  output$SelectData.UI <- renderUI({
    choices <- data_meta$Rds.full.path
    names(choices)  <- paste0(data_meta$Sample.name, " [",data_meta$Rds.File.size, "]")
    radioButtons(inputId = "Choosendata",
                 label = NULL,
                 choices = choices,
                 selected = unname(choices[1]))
  })

  ## Dataset tab ----
  # reactiveValues: Create an object for storing reactive values,similar to a list,
  data = reactiveValues(obj = NULL, loaded = FALSE, Name = NULL, Path = NULL,
                        Species = NULL, Description = NULL,
                        reduction_options = NULL, reduction_default = NULL,
                        cluster_options = NULL, cluster_default = NULL,
                        split_maxlevel = 6, split_options = NULL,
                        extra_qc_options = NULL)


  # 选择好数据后，读入数据
  # 潜在问题： 在切换数据时，data$obj先发生了变化会引起reactive，此时default reduction等仍为先前数据的配置，后台会抛出一个错误：Warning: Error in [.data.frame: 选择了未定义的列
  # 但并不影响前台显示。
  observeEvent(input$submitdata,{
    shiny::req(input$Choosendata) # req: Check for required values; Choosendata is a data.frame
    showModal(modalDialog(title = "Loading data...", "Please wait until data loaded! large file takes longer.", footer= NULL, size = "l"))
    which_data <- match(input$Choosendata, data_meta$Rds.full.path)
    if (is.null(names(cache.rds.list)) | !data_meta$Sample.name[which_data] %in% names(cache.rds.list)) { # 首次加载
      data$obj <- SeuratExplorer:::prepare_seurat_object(obj = Seurat::UpdateSeuratObject(readRDS(file = input$Choosendata)))
      data$Name <- data_meta$Sample.name[which_data]
      data$Path <- input$Choosendata
      data$Species <- if(is.na(data_meta$Species[which_data])){NULL}else{data_meta$Species[which_data]} # 如果是NA值，输出为NULL
      data$Description <- if(is.na(data_meta$Description[which_data])){NULL}else{data_meta$Description[which_data]} # 如果是NA值，输出为NULL
      data$reduction_options <- SeuratExplorer:::prepare_reduction_options(obj = data$obj, keywords = c("umap","tsne"))
      data$reduction_default <- if(is.na(data_meta$Default.DimensionReduction[which_data])){NULL}else{data_meta$Default.DimensionReduction[which_data]} # 如果是NA值，输出为NULL
      data$cluster_options <- SeuratExplorer:::prepare_cluster_options(df = data$obj@meta.data)
      data$cluster_default <- if(is.na(data_meta$Default.ClusterResolution[which_data])){NULL}else{data_meta$Default.ClusterResolution[which_data]} # 如果是NA值，输出为NULL
      data$split_maxlevel <- if(is.na(data_meta$SplitOptions.MaxLevel[which_data])){6}else{data_meta$SplitOptions.MaxLevel[which_data]} # 如果是NA值，设为6，决定了split选项
      data$split_options <- SeuratExplorer:::prepare_split_options(df = data$obj@meta.data, max.level = data$split_maxlevel)
      data$extra_qc_options <- SeuratExplorer:::prepare_qc_options(df = data$obj@meta.data, types = c("double","integer","numeric"))
      cache.rds.list[[data_meta$Sample.name[which_data]]] <<- reactiveValuesToList(data)
    }else{ # 之前加载过
      data$obj <- cache.rds.list[[data_meta$Sample.name[which_data]]]$obj
      data$Name <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Name
      data$Path <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Path
      data$Species <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Species
      data$Description <- cache.rds.list[[data_meta$Sample.name[which_data]]]$Description
      data$reduction_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$reduction_options
      data$reduction_default <- cache.rds.list[[data_meta$Sample.name[which_data]]]$reduction_default
      data$cluster_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$cluster_options
      data$cluster_default <- cache.rds.list[[data_meta$Sample.name[which_data]]]$cluster_default
      data$split_maxlevel <- cache.rds.list[[data_meta$Sample.name[which_data]]]$split_maxlevel
      data$split_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$split_options
      data$extra_qc_options <- cache.rds.list[[data_meta$Sample.name[which_data]]]$extra_qc_options
    }
    message("data loaded successfully!")
    removeModal()
  })

  # 数据加载成功后，设置loaded为TRUE
  observe({
    req(data$obj)
    data$loaded = !is.null(data$obj)
  })

  # Render metadata table
  # 可以下载全部，参考：https://stackoverflow.com/questions/50039186/add-download-buttons-in-dtrenderdatatable
  output$dataset_meta <- DT::renderDT(server=TRUE,{
    shiny::req(data$obj)
    message("Preparing dataset_meta...")
    # Show data
    DT::datatable(data$obj@meta.data, extensions = 'Buttons',
                  caption = htmltools::tags$caption(
                    style = 'caption-side: bottom; text-align: center;',
                    'Table 2: ', htmltools::em('cell metadata')),
                  options = list(scrollX=TRUE,
                                 # lengthMenu = c(5,10,15),
                             paging = TRUE, searching = TRUE,
                             fixedColumns = TRUE, autoWidth = TRUE,
                             ordering = TRUE, dom = 'Bfrtip',
                             buttons = c('copy', 'csv', 'excel')))
  })

  # Conditional panel control based on loaded obj，条件panel,数据记载成功后，显示：dashboardSidebar -sidebarMenu - menuItem - Explorer和 dashboardBody - dataset - tabItem -  box - Cell Meta Info
  output$file_loaded = reactive({
    return(data$loaded)
  })

  # Disable suspend for output$file_loaded, 当被隐藏时，禁用暂停，conditionalpanel所需要要的参数
  outputOptions(output, 'file_loaded', suspendWhenHidden=FALSE)

  ######################################################### Reports page
  output$DirectoryTree <- renderPrint({
    path <- gsub("//+","/",data_meta$Reports.main)
    # https://stackoverflow.com/questions/36094183/how-to-build-a-dendrogram-from-a-directory-tree
    x <- lapply(strsplit(path, "/"), function(z) as.data.frame(t(z)))
    x <- plyr::rbind.fill(x)
    equal.index <- apply(x, 2, function(x)length(unique(x)) == 1)
    if (all(equal.index)) {
      x <- x[,(ncol(x) - 1):ncol(x)]
    }else{
      x <- x[,(min(which(!equal.index)) - 1) : ncol(x)]
    }
    x$pathString <- apply(x, 1, function(x) paste(trimws(na.omit(x)), collapse="/"))
    x$SampleName <- data_meta$Sample.name
    mytree <- data.tree::as.Node(x)
    message("Preparing DirectoryTree...")
    print(mytree, "SampleName")
  }, width = 300) # 每行300个字符

  # 调试IP地址用的
  output$reports_not_work <- renderText({
    message("Preparing reports_not_work...")
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

  # 点击generate reports按钮，更新或者生成reports目录，然后加入一个view reports按钮，可链接到分析结果目录。
  observeEvent(input$generatereports,{
    reports_dir <- paste0("../", basename(getwd()), "_reports")
    if (!dir.exists(reports_dir)) { # 生成
      showModal(modalDialog(title = "Generating reports...", "Please wait...", footer= NULL, size = "l"))
    }else{ # 更新
      showModal(modalDialog(title = "Updating reports...", "Please wait...", footer= NULL, size = "l"))
      unlink(reports_dir, recursive = TRUE)
    }
    dir.create(reports_dir)
    message("Preparing the reports direcotry, Please wait a moment...")
    prepare_reports(reports_dir = reports_dir, data_meta = data_meta)
    removeModal()
    output$ViewReports.UI <- renderUI({ # 生成view reports UI
      message("Preparing ReportURL.UI...")
      if (session$clientData$url_pathname == "/") {
        verbatimTextOutput(outputId = "reports_not_work")
      }else{
        full_URL = paste0(session$clientData$url_protocol, "//",session$clientData$url_hostname,":",session$clientData$url_port,session$clientData$url_pathname)
        reports_URL = paste0(dirname(full_URL), "/", basename(reports_dir),"/")
        # https://stackoverflow.com/questions/37795760/r-shiny-add-weblink-to-actionbutton
        message(paste0("Reports url: ", reports_URL))
        actionButton(inputId='openreportswebpage',
                     label="View/Download Reports",
                     onclick = paste0("window.open('", reports_URL, "','_blank')"),
                     icon = icon("file"),
                     class = "btn-primary")
      }
    })
  })



  ##################################### Seurat explorer functions
  SeuratExplorer::explorer_server(input = input, output = output, session = session, data = data)

  ##################################### settings
  # Warning
  output$settings_warning = renderText({
    paste0('注意：修改参数后，需要您关闭网页后重新打开，修改才能生效。每次只能修改一个样本的参数。')
  })

  output$InfoForDataOpened <- renderText({
    message("Preparing InfoForDataOpened...")
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
    message("Preparing SetSampleName.UI...")
    textInput(inputId = "NewName", label = "Sample Name:", value = data$Name, placeholder = "Suggest only use letters, numbers, undersocres. And not too long.")
  })

  output$SetSpecies.UI <- renderUI({
    message("Preparing SetSpecies.UI...")
    selectInput(inputId = "NewSpecies", label = "Choose the Species:", choices = c(Human = "Human", Mouse = "Mouse", Fly = "Fly", Others = "Others"), selected = data$Species)
  })

  output$SetDescription.UI <- renderUI({
    message("Preparing SetDescription.UI...")
    textAreaInput(inputId = "NewDescription", label = "Sample Description:", value = data$Description, placeholder = "Do not use special characters")
  })

  output$SetDefaultReduction.UI <- renderUI({
    message("Preparing SetDefaultReduction.UI...")
    selectInput("NewDefaultReduction", "Dimension Reduction:", choices = data$reduction_options, selected = data$reduction_default)
  })

  output$SetDefaultCluster.UI <- renderUI({
    message("Preparing SetDefaultCluster.UI...")
    selectInput("NewDefaultCluster","Cluster Resolution:", choices = data$cluster_options, selected = data$cluster_default)
  })

  output$SetDefaultSplitMaxLevels.UI <- renderUI({
    message("Preparing SetDefaultSplitMaxLevels.UI...")
    sliderInput("NewSplitMaxLevel", label = "Max Split Level:", min = 1, max = 20, value = data$split_maxlevel)
  })

  observeEvent(input$submitsettings,{
    # 1. check Name
    if(trimws(input$NewName) == ""){
      showModal(modalDialog(title = "Error:","Sample name can not be empty.",easyClose = TRUE,footer = NULL))
    }else{
      which_data <- match(data$Path, data_meta$Rds.full.path)
      data_meta_new <- data_meta
      data_meta_new$Sample.name[which_data] <- input$NewName
      data_meta_new$Species[which_data] <- input$NewSpecies
      data_meta_new$Description[which_data] <- ifelse(trimws(input$NewDescription) == "", NA, input$NewDescription)
      data_meta_new$Default.DimensionReduction[which_data] <- input$NewDefaultReduction
      data_meta_new$Default.ClusterResolution[which_data] <- input$NewDefaultCluster
      data_meta_new$SplitOptions.MaxLevel[which_data] <- input$NewSplitMaxLevel
      data_meta_new$Rds.full.path <- NULL
      data_meta_new$Rds.File.size <- NULL
      saveRDS(data_meta_new, file = paramterfile.server)
      # R Shiny app shows old data
      # https://stackoverflow.com/questions/37408072/r-shiny-app-shows-old-data
      p <- paste0(getwd(), "/app.R")
      if(file.exists(p)){
        print("update app.R file, in case of Shiny use cached data when restart.")
        R.utils::touchFile(p)}
      showModal(modalDialog(title = "Success:","New settings has beed saved successfully. restart App to use the latest settings.",easyClose = TRUE,footer = NULL))
      removeUI(selector = "div:has(> #NewName)")
      removeUI(selector = "div:has(> #NewSpecies)")
      removeUI(selector = "div:has(> #NewDescription)")
      removeUI(selector = "div:has(> #NewDefaultReduction)")
      removeUI(selector = "div:has(> #NewDefaultCluster)")
      removeUI(selector = "div:has(> #NewSplitMaxLevel)")
      removeUI(selector = "div:has(> #submitsettings)")
    }
  })

  # do something when session ended
  session$onSessionEnded(function() {
    reports_dir <- paste0("../", basename(getwd()), "_reports")
    if (!Encrypted.server) {
      if(dir.exists(reports_dir)){unlink(reports_dir, recursive = TRUE)}
      print('Hello, the session finally ended!')
    }else if(!is.null(isolate({res_auth$user}))){ # 注意，shinymanager登陆成功后也会触发session ended
      if(dir.exists(reports_dir)){unlink(reports_dir, recursive = TRUE)}
      print('Hello, the session finally ended!')
    }
  })

}
