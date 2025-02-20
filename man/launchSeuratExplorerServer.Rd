% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/launch.R
\name{launchSeuratExplorerServer}
\alias{launchSeuratExplorerServer}
\title{Launch shiny app}
\usage{
launchSeuratExplorerServer(
  Encrypted = TRUE,
  credentials = data.frame(user = "shiny", password = "12345", stringsAsFactors = FALSE),
  paramterfile = SeuratExplorerServer:::revise_path(),
  TechnicianEmail = "zhangyongchao@nibs.ac.cn",
  TechnicianName = "ZhangYongchao"
)
}
\arguments{
\item{Encrypted}{是否加密App}

\item{credentials}{密码文件}

\item{paramterfile}{参数文件}

\item{TechnicianEmail}{技术人员邮箱}

\item{TechnicianName}{技术人员姓名}
}
\value{
In-browser Shiny Application launch
}
\description{
Launch shiny app
}
\examples{
# launchSeuratExplorerServer()
}
