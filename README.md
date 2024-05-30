
<!-- README.md is generated from README.Rmd. Please edit that file -->

# SeuratExplorerServer

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> Q: 为什么搞这个R包<br/> A:
> `SeuratExplorer`相当于一个桌面版软件，可以在本地电脑上查看和分析`Seurat`对象，即使把`SeuratExplorer`安装到服务器上，那也只能通过上传数据来浏览客户端电脑上的`Seurat`对象，无法查看位于服务器上的数据。`SeuratExplorerServer`的开发目的是，允许用户利用服务器硬件资源，通过网页浏览器来查看位于服务器上的`Seurat`对象数据，该R包不仅具有`SeuratExplorer`R
> 包的所有功能外，还可以查看中间分析结果，并且支持多数据切换和密码保护功能。

> Q: 为啥要多数据切换<br/> A:有时在做完分析后，会需要提取某些cell
> type的细胞，然后再重新分析，得到新的`Seurat`对象，这样同一个project下就会有多个`Seurat`对象。

> Q: 为什么需要密码保护<br/>
> A:对于未公开的数据，一般会仅仅允许数据相关的人员可以获取和查看数据。对于已发表的数据，可以选择不设置密码。

> Q: `SeuratExplorer`与`SeuratExplorerServer`的关系<br/>
> A:`SeuratExplorerServer`依赖于`SeuratExplorer`

> Q: `SeuratExplorerServer`支持的分析报告类型<br/> A: pdf, html, tiff,
> csv, jpg, jpeg, png, bmp,
> svg等，也可以通过修改`functions.R`里的`prepare_reports`function，来指定其它类型的文件。

## Installation

You can install the development version of `SeuratExplorer` and
`SeuratExplorerServer`like so:

``` r
if(!require(devtools)){install.packages("devtools")}
install_github("fentouxungui/SeuratExplorer")
install_github("fentouxungui/SeuratExplorerServer")
```

## Run a demo

``` r
library(SeuratExplorerServer)
launchSeuratExplorerServer()
```

`launchSeuratExplorerServer` Parameters:

- `Encrypted`: whether to encrypt the App

- `credentials`: You must specify this parameter when `Encrypted` is set
  to `TRUE`

- `paramterfile`: see bellow for detailed information

## Usage

### Generate credentials

Please refer to R package
[shinymanager](https://github.com/datastorm-open/shinymanager) for
detailed tutorial to generate a credentials data in `data.frame`.

``` r
# Init DB using credentials data
credentials <- data.frame(
  user = "shiny",
  password = "12345",
  stringsAsFactors = FALSE
)
```

### Generate sample metadata parameters

``` r
data_meta <- data.frame(
  reports.main = c("inst/extdata/demo/fly-gut-EEs-scRNA", "inst/extdata/demo/mouse-gut-haber"), # 主分析目录, Rds文件位于此目录中，并且所有位于该目录下的指定文件也会被收录到reports中，以sample name进行命名和区分。
  Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"), # Rds文件在主分析目录中的相对目录
  reports.second = c(NA, NA), # 次要分析目录，此目录中的分析报告也会被加载到reports临时目录中，比如cellranger的结果。放到Others子目录下。
  Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT", "Mouse-Intestine-scRNAseq-Haber"), # Sample name
  SplitOptions.MaxLevel = c(1, 4), # 用于设定split选项的参数,如果是多样本数据合并，一般该值要大于或等于样本数。
  Default.DimensionReduction = c("tsne", "umap"), # dimension reduction的默认值。
  Default.ClusterResolution = c("res.0.4", NA),  # cluster的默认值。
  Species = c("Fly", "Mouse"), # Human, Mouse, Fly or Others
  Description = c("blabla","hahaha"), # descript the sample or the analsyis, or whatever.
  stringsAsFactors = FALSE)
knitr::kable(data_meta)
```

| reports.main                        | Rds.path                    | reports.second | Sample.name                    | SplitOptions.MaxLevel | Default.DimensionReduction | Default.ClusterResolution | Species | Description |
|:------------------------------------|:----------------------------|:---------------|:-------------------------------|----------------------:|:---------------------------|:--------------------------|:--------|:------------|
| inst/extdata/demo/fly-gut-EEs-scRNA | Rds-file/G101_PC20res04.rds | NA             | Fly-Gut-EEs-scRNAseq-GuoXT     |                     1 | tsne                       | res.0.4                   | Fly     | blabla      |
| inst/extdata/demo/mouse-gut-haber   | haber.tsne.embeding.rds     | NA             | Mouse-Intestine-scRNAseq-Haber |                     4 | umap                       | NA                        | Mouse   | hahaha      |

``` r
# saveRDS(data_meta, file = "inst/extdata/demo/others/sample-paramters.rds")
```

Or:

``` r
data_meta <- SeuratExplorerServer::initialize_metadata(
  reports.main = c("inst/extdata/demo/fly-gut-EEs-scRNA", "inst/extdata/demo/mouse-gut-haber"), # 必填项目
  Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"), # 必填项目
  reports.second = c(NA, NA), # 必填项目
  Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT", "Mouse-Intestine-scRNAseq-Haber")) # 必填项目
#> The legacy packages maptools, rgdal, and rgeos, underpinning the sp package,
#> which was just loaded, will retire in October 2023.
#> Please refer to R-spatial evolution reports for details, especially
#> https://r-spatial.org/r/2023/05/15/evolution4.html.
#> It may be desirable to make the sf package available;
#> package maintainers should consider adding sf to Suggests:.
#> The sp package is now running under evolution status 2
#>      (status 2 uses the sf package in place of rgdal)
knitr::kable(data_meta)
```

| reports.main                        | Rds.path                    | reports.second | Sample.name                    | Species | Description | Default.DimensionReduction | Default.ClusterResolution | SplitOptions.MaxLevel |
|:------------------------------------|:----------------------------|:---------------|:-------------------------------|:--------|:------------|:---------------------------|:--------------------------|:----------------------|
| inst/extdata/demo/fly-gut-EEs-scRNA | Rds-file/G101_PC20res04.rds | NA             | Fly-Gut-EEs-scRNAseq-GuoXT     | NA      | NA          | NA                         | NA                        | NA                    |
| inst/extdata/demo/mouse-gut-haber   | haber.tsne.embeding.rds     | NA             | Mouse-Intestine-scRNAseq-Haber | NA      | NA          | NA                         | NA                        | NA                    |

``` r
# saveRDS(data_meta, file = "./inst/extdata/demo/others/sample-paramters.rds")
```

其他参数可以在App运行过程中进行修改。必填项目一般是否数据分析员所设定的，其他参数可由用户自行设定。

### Explorer data

``` r
library(SeuratExplorerServer)
launchSeuratExplorerServer(Encrypted = TRUE,
                           credentials_file = credentials,
                           Paramters = "inst/extdata/demo/others/sample-paramters.rds")
```

## 软件工作流程介绍

- 首先在App所在目录（比如：***Fly-Gut-EEs-scRNAseq***）的上层目录创建同名的并以`_reports`目录（***Fly-Gut-EEs-scRNAseq_reports***），sample
  meta中`reports.main`列和`reports.second`列对应目录中里的特定类型的文件，会以快捷连接方式被放到***reports***目录中。这会导致App加载延迟。

- 登录：输入账户和密码。

- sample meta 信息展示。

- 选择数据。

- 浏览分析报告。

- SeuratExplorer里的功能。

- 修改样本元信息的默认参数。

## Example: Deploy on Shinyserver

## Online Demo

shinyapps.io

## Rsession info

    #> R version 4.3.0 (2023-04-21 ucrt)
    #> Platform: x86_64-w64-mingw32/x64 (64-bit)
    #> Running under: Windows 10 x64 (build 19045)
    #> 
    #> Matrix products: default
    #> 
    #> 
    #> locale:
    #> [1] LC_COLLATE=Chinese (Simplified)_China.utf8 
    #> [2] LC_CTYPE=Chinese (Simplified)_China.utf8   
    #> [3] LC_MONETARY=Chinese (Simplified)_China.utf8
    #> [4] LC_NUMERIC=C                               
    #> [5] LC_TIME=Chinese (Simplified)_China.utf8    
    #> 
    #> time zone: Asia/Shanghai
    #> tzcode source: internal
    #> 
    #> attached base packages:
    #> [1] stats     graphics  grDevices utils     datasets  methods   base     
    #> 
    #> loaded via a namespace (and not attached):
    #>   [1] deldir_1.0-9                    pbapply_1.7-2                  
    #>   [3] gridExtra_2.3                   rlang_1.1.3                    
    #>   [5] magrittr_2.0.3                  shinydashboard_0.7.2           
    #>   [7] RcppAnnoy_0.0.21                spatstat.geom_3.2-4            
    #>   [9] matrixStats_1.0.0               ggridges_0.5.4                 
    #>  [11] compiler_4.3.0                  png_0.1-8                      
    #>  [13] vctrs_0.6.2                     reshape2_1.4.4                 
    #>  [15] stringr_1.5.0                   pkgconfig_2.0.3                
    #>  [17] fastmap_1.1.1                   utf8_1.2.3                     
    #>  [19] promises_1.2.0.1                rmarkdown_2.22                 
    #>  [21] purrr_1.0.1                     xfun_0.39                      
    #>  [23] cachem_1.0.8                    SeuratExplorer_0.0.5.9000      
    #>  [25] jsonlite_1.8.5                  goftest_1.2-3                  
    #>  [27] later_1.3.1                     spatstat.utils_3.0-3           
    #>  [29] irlba_2.3.5.1                   parallel_4.3.0                 
    #>  [31] cluster_2.1.4                   R6_2.5.1                       
    #>  [33] ica_1.0-3                       bslib_0.5.0                    
    #>  [35] stringi_1.7.12                  RColorBrewer_1.1-3             
    #>  [37] spatstat.data_3.0-1             SeuratExplorerServer_0.0.0.9000
    #>  [39] reticulate_1.30                 parallelly_1.36.0              
    #>  [41] jquerylib_0.1.4                 lmtest_0.9-40                  
    #>  [43] scattermore_1.2                 Rcpp_1.0.10                    
    #>  [45] knitr_1.43                      tensor_1.5                     
    #>  [47] future.apply_1.11.0             zoo_1.8-12                     
    #>  [49] sctransform_0.4.1               httpuv_1.6.11                  
    #>  [51] Matrix_1.6-4                    splines_4.3.0                  
    #>  [53] igraph_1.4.3                    tidyselect_1.2.0               
    #>  [55] abind_1.4-5                     rstudioapi_0.14                
    #>  [57] yaml_2.3.7                      spatstat.random_3.1-5          
    #>  [59] codetools_0.2-19                miniUI_0.1.1.1                 
    #>  [61] spatstat.explore_3.2-1          listenv_0.9.0                  
    #>  [63] lattice_0.21-8                  tibble_3.2.1                   
    #>  [65] plyr_1.8.8                      shiny_1.8.1.1                  
    #>  [67] ROCR_1.0-11                     evaluate_0.21                  
    #>  [69] Rtsne_0.16                      future_1.33.0                  
    #>  [71] fastDummies_1.7.3               survival_3.5-5                 
    #>  [73] polyclip_1.10-4                 fitdistrplus_1.1-11            
    #>  [75] pillar_1.9.0                    Seurat_5.1.0                   
    #>  [77] KernSmooth_2.23-20              plotly_4.10.2                  
    #>  [79] generics_0.1.3                  RcppHNSW_0.6.0                 
    #>  [81] sp_2.0-0                        ggplot2_3.5.1                  
    #>  [83] munsell_0.5.0                   scales_1.3.0                   
    #>  [85] globals_0.16.2                  xtable_1.8-4                   
    #>  [87] glue_1.6.2                      lazyeval_0.2.2                 
    #>  [89] tools_4.3.0                     data.table_1.14.8              
    #>  [91] RSpectra_0.16-1                 RANN_2.6.1                     
    #>  [93] leiden_0.4.3                    dotCall64_1.1-1                
    #>  [95] cowplot_1.1.1                   grid_4.3.0                     
    #>  [97] tidyr_1.3.0                     colorspace_2.1-0               
    #>  [99] nlme_3.1-162                    patchwork_1.2.0                
    #> [101] cli_3.6.1                       spatstat.sparse_3.0-2          
    #> [103] spam_2.10-0                     fansi_1.0.4                    
    #> [105] viridisLite_0.4.2               dplyr_1.1.2                    
    #> [107] uwot_0.1.16                     gtable_0.3.3                   
    #> [109] sass_0.4.6                      digest_0.6.31                  
    #> [111] progressr_0.14.0                ggrepel_0.9.3                  
    #> [113] htmlwidgets_1.6.2               SeuratObject_5.0.2             
    #> [115] htmltools_0.5.5                 lifecycle_1.0.3                
    #> [117] shinyWidgets_0.8.6              httr_1.4.6                     
    #> [119] mime_0.12                       MASS_7.3-58.4
