library(SeuratExplorerServer)
credentials <- readRDS(system.file("extdata/shinyserver_demo/index-page", "credentials.rds", package ="SeuratExplorerServer"))

# to load the demo data
if (!file.exists("data_meta.rds")){
  data_meta_source_path <- revise_demo_path(system.file("extdata/shinyserver_demo/data-page/demo_1", 'data_meta.rds', package ="SeuratExplorerServer"))
  file.copy(data_meta_source_path, "data_meta.rds")
}

launchSeuratExplorerServer(Encrypted = TRUE,
                           credentials = credentials,
                           paramterfile = "data_meta.rds",
                           TechnicianEmail = "zhangyongchao@nibs.ac.cn",
                           TechnicianName = "ZhangYongchao",
                           verbose = FALSE)

# data_meta <- readRDS("inst/extdata/shinyserver_demo/data-page/demo_1/data_meta.rds")
# data_meta$Reports.main <- c("fly")
# saveRDS(data_meta,file = "inst/extdata/shinyserver_demo/data-page/demo_1/data_meta.rds")
