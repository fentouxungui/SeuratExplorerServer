library(shiny)
library(shinydashboard)
library(DT)

# trans characters to links
tans_link <- function(Avector,label = "View Data"){
  res <- c()
  for (i in Avector) {
    if (!i %in% c("","-",NA)) {
      res <- append(res,paste(paste0("<a href='",unlist(strsplit(i,split = ";")),"' target='_blank'>",label,"</a>"),collapse = "<br>"))
    }else{
      res <- append(res,"-")
    }
  }
  return(res)
}

# # create credentials file
# credentials <- data.frame(
#   user = "shiny",
#   password = "12345",
#   stringsAsFactors = FALSE
# )
# saveRDS(credentials, file = "credentials.rds")


ui <- dashboardPage( title = "Demo Data Hub",
                     dashboardHeader( title = strong("Demo Data Hub"), titleWidth = 240),
                     dashboardSidebar(width = 240,
                                      sidebarMenu(menuItem(strong("Data"), tabName = "Data", icon = icon("tachometer-alt")))),
                     dashboardBody(tags$style("@import url(https://use.fontawesome.com/releases/v5.7.2/css/all.css);"),
                                   tabItems(tabItem(tabName = "Data",
                                                    h2(strong("Data")),
                                                    h3("Main Entrance: ", tags$a(href = "http://192.168.13.45/shiny-server/Data/","Link Here!")),
                                                    br(),
                                                    fluidRow(box(title = "Included Data", width = 12, status = "primary",
                                                                 DT::dataTableOutput("DataIndex")))
                                   ))))

server <- function(input, output, session) {
  # Data
  Data <- read.csv(system.file("extdata/shinyserver_demo/index-page", "Entry.csv", package ="SeuratExplorerServer"), stringsAsFactors = FALSE)
  Data$Data.Link <- tans_link(Data$Data.Link)
  Data$Official.Link <- tans_link(Data$Official.Link)
  Data$Paper.Link <- tans_link(Data$Paper.Link, "View Paper")
  output$DataIndex <- DT::renderDataTable(DT::datatable(Data,escape = FALSE))
}


shinyApp(ui, server)
