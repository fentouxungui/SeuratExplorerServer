library(SeuratExplorerServer)
credentials <- readRDS(system.file("extdata/shinyserver_demo/index-page", "credentials.rds", package ="SeuratExplorerServer"))

launchSeuratExplorerServer(Encrypted = TRUE,
                           credentials = credentials,
                           paramterfile = revise_demo_path(system.file("extdata/shinyserver_demo/data-page/demo_2", 'data_meta.rds', package ="SeuratExplorerServer")),
                           TechnicianEmail = "zhangyongchao@nibs.ac.cn",
                           TechnicianName = "ZhangYongchao",
                           verbose = FALSE)

# data_meta <- readRDS("inst/extdata/shinyserver_demo/data-page/demo_2/data_meta.rds")
# data_meta$Reports.main <- c("mouse", "mouse/Subset/subset-goblet")
# saveRDS(data_meta,file = "inst/extdata/shinyserver_demo/data-page/demo_2/data_meta.rds")


