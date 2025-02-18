
<!-- README.md is generated from README.Rmd. Please edit that file -->

# SeuratExplorerServer

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> Q: 为什么搞这个R包<br/> A:
> `SeuratExplorer`相当于一个桌面版软件，允许在本地电脑上查看和分析`Seurat`分析结果，即使把`SeuratExplorer`安装到服务器上，那也只能通过上传数据方式来浏览客户端电脑上的单细胞数据。而`SeuratExplorerServer`可作为**Shiny
> app**部署到服务器上，用户可通过网页来访问位于服务器上的单细胞数据，该R包不仅具有`SeuratExplorer`R
> 包的所有功能外，还可以查看中间分析结果，并且支持多数据切换、密码保护功能和自定义部分初始化参数。

> Q: 为啥要多数据切换<br/> A:有时在做完分析后，会需要提取某些cell
> type的细胞，然后再重新分析，得到新的`Seurat`对象，这样同一个project下就会有多个`Seurat`对象。

> Q: 为什么需要密码保护<br/>
> A:对于未公开的数据，一般会仅仅允许数据相关的人员可以获取和查看数据。对于已发表的数据，可以选择不设置密码。

> Q: `SeuratExplorer`与`SeuratExplorerServer`的关系<br/>
> A:`SeuratExplorerServer`依赖于`SeuratExplorer`，并且具备所有`SeuratExplorer`里的数据分析功能。

> Q: `SeuratExplorerServer`支持的分析报告类型<br/> A: pdf, html, tiff,
> csv, jpg, jpeg, png, bmp,
> svg等，也可以通过修改`functions.R`里的`prepare_reports`function，来指定其它类型的文件。

## 1. Installation

You can install the development version of `SeuratExplorer` and
`SeuratExplorerServer`like so:

``` r
# install dependency
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("ComplexHeatmap")

if(!require(devtools)){install.packages("devtools")}
install_github("fentouxungui/SeuratExplorer")

# install SeuratExplorerServer
options(timeout = max(300, getOption("timeout")))
install_github("fentouxungui/SeuratExplorerServer")
```

## 2. Run a demo

``` r
library(SeuratExplorerServer)
launchSeuratExplorerServer()
```

`launchSeuratExplorerServer` Parameters:

- `Encrypted`: whether to encrypt the App

- `credentials`: You must specify this parameter when `Encrypted` is set
  to `TRUE`

- `paramterfile`: see bellow for detailed information

## 3. Workflow introduction

- 首先在App所在目录（比如：***Fly-Gut-EEs-scRNAseq***）的上层目录创建同名的并以`_reports`为后缀的目录（***Fly-Gut-EEs-scRNAseq_reports***），sample
  meta中`Reports.main`列和`Reports.second`列对应目录中里的特定类型的文件，会以快捷连接方式被放到***reports***目录中。这会导致App加载延迟。

- 登录：输入账户和密码。

- `sample meta`信息展示及下载。

- 选择或切换数据。

- 浏览分析报告。

- `SeuratExplorer`里的功能。

- 修改样本元信息的默认参数，重启后生效。

- 关闭时会删除`_reports`目录（***Fly-Gut-EEs-scRNAseq_reports***）

## 4. Examples deployed on Shinyserver

[**A live
demo**](http://www.nibs.ac.cn:666/Test-SeuratExplorer-Server/).

``` r
# app.R
options(timeout = max(300, getOption("timeout")))

if(!require(devtools)){install.packages("devtools")}
if(!require(SeuratExplorer)){install_github("fentouxungui/SeuratExplorer")}
if(!require(SeuratExplorerServer)){install_github("fentouxungui/SeuratExplorerServer")}

Encrypted = TRUE
credentials = data.frame(user = "shiny", password = "12345", stringsAsFactors = FALSE)
paramterfile = SeuratExplorerServer:::revise_path()
TechnicianEmail = "zhangyongchao@nibs.ac.cn"
TechnicianName = "ZhangYongchao"

shinyApp(
  ui = SeuratExplorerServer::ui(Encrypted.app = Encrypted, TechnicianEmail = TechnicianEmail, TechnicianName = TechnicianName),
  server = SeuratExplorerServer::server, onStart = SeuratExplorerServer:::onStart(Encrypted, credentials, paramterfile)
)
```

## 5. Usage

### 5.1 Generate credentials

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

### 5.2 Generate sample metadata parameters

``` r
data_meta <- data.frame(
  Reports.main = c("inst/extdata/demo/fly-gut-EEs-scRNA", "inst/extdata/demo/mouse-gut-haber"), # 主分析目录, Rds文件位于此目录中，并且所有位于该目录下的指定文件也会被收录到reports中，以sample name进行命名和区分。
  Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"), # Rds文件在主分析目录中的相对目录
  Reports.second = c(NA, NA), # 次要分析目录，此目录中的分析报告也会被加载到reports临时目录中，比如cellranger的结果。放到Others子目录下。
  Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT", "Mouse-Intestine-scRNAseq-Haber"), # Sample name
  SplitOptions.MaxLevel = c(1, 4), # 用于设定split选项的参数,如果是多样本数据合并，一般该值要大于或等于样本数。
  Default.DimensionReduction = c("tsne", "umap"), # dimension reduction的默认值。
  Default.ClusterResolution = c("res.0.4", NA),  # cluster的默认值。
  Species = c("Fly", "Mouse"), # Human, Mouse, Fly or Others
  Description = c("blabla","hahaha"), # descript the sample or the analsyis, or whatever.
  stringsAsFactors = FALSE)
knitr::kable(data_meta)
```

| Reports.main | Rds.path | Reports.second | Sample.name | SplitOptions.MaxLevel | Default.DimensionReduction | Default.ClusterResolution | Species | Description |
|:---|:---|:---|:---|---:|:---|:---|:---|:---|
| inst/extdata/demo/fly-gut-EEs-scRNA | Rds-file/G101_PC20res04.rds | NA | Fly-Gut-EEs-scRNAseq-GuoXT | 1 | tsne | res.0.4 | Fly | blabla |
| inst/extdata/demo/mouse-gut-haber | haber.tsne.embeding.rds | NA | Mouse-Intestine-scRNAseq-Haber | 4 | umap | NA | Mouse | hahaha |

``` r
# saveRDS(data_meta, file = "sample-paramters.rds")
```

Or:

``` r
data_meta <- SeuratExplorerServer::initialize_metadata(
  Reports.main = c("inst/extdata/demo/fly", "inst/extdata/demo/mouse"), # 必填项目
  Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"), # 必填项目
  Reports.second = c(NA, NA), # 必填项目
  Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT", "Mouse-Intestine-scRNAseq-Haber")) # 必填项目
#> Warning: replacing previous import 'R.utils::validate' by 'shiny::validate'
#> when loading 'SeuratExplorerServer'
#> Warning: replacing previous import 'R.utils::setProgress' by
#> 'shiny::setProgress' when loading 'SeuratExplorerServer'
#> Warning: replacing previous import 'R.utils::timestamp' by 'utils::timestamp'
#> when loading 'SeuratExplorerServer'
#> data meta file check passed!
#> data meta file initilized successfully!
```

``` r
knitr::kable(data_meta)
```

| Reports.main | Rds.path | Reports.second | Sample.name | Species | Description | Default.DimensionReduction | Default.ClusterResolution | SplitOptions.MaxLevel |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| inst/extdata/demo/fly | Rds-file/G101_PC20res04.rds | NA | Fly-Gut-EEs-scRNAseq-GuoXT | NA | NA | NA | NA | NA |
| inst/extdata/demo/mouse | haber.tsne.embeding.rds | NA | Mouse-Intestine-scRNAseq-Haber | NA | NA | NA | NA | NA |

``` r
# saveRDS(data_meta, file = "sample-paramters.rds")
```

其他参数可以在App运行过程中进行修改。必填项目一般是由数据分析员设定的，其他参数可由用户自行设定。

### 5.3 Explore data

``` r
library(SeuratExplorerServer)
launchSeuratExplorerServer(Encrypted = TRUE, 
                           credentials = credentials,
                           paramterfile = "sample-paramters.rds",
                           TechnicianEmail = "your-email",
                           TechnicianName = "your-name")
```

## 6. Screenshots

<img src="inst/extdata/www/login.png" width="100%" /><img src="inst/extdata/www/dataset.png" width="100%" /><img src="inst/extdata/www/reports-main.png" width="100%" /><img src="inst/extdata/www/reports-2.png" width="100%" /><img src="inst/extdata/www/reports-3.png" width="100%" /><img src="inst/extdata/www/settings.png" width="100%" />

## 7. To Do List

- 支持空间转录组数据，`SeuratExplorer`
  related，比较复杂，以后有精力再做.

## 8. Rsession info

    #> R version 4.4.1 (2024-06-14 ucrt)
    #> Platform: x86_64-w64-mingw32/x64
    #> Running under: Windows 11 x64 (build 22631)
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
    #>   [1] RColorBrewer_1.1-3              rstudioapi_0.16.0              
    #>   [3] jsonlite_1.8.8                  billboarder_0.4.1              
    #>   [5] magrittr_2.0.3                  spatstat.utils_3.0-5           
    #>   [7] rmarkdown_2.27                  vctrs_0.6.5                    
    #>   [9] ROCR_1.0-11                     memoise_2.0.1                  
    #>  [11] spatstat.explore_3.2-7          askpass_1.2.0                  
    #>  [13] htmltools_0.5.8.1               SeuratExplorerServer_0.0.1.0002
    #>  [15] sass_0.4.9                      sctransform_0.4.1              
    #>  [17] parallelly_1.37.1               KernSmooth_2.23-24             
    #>  [19] bslib_0.7.0                     htmlwidgets_1.6.4              
    #>  [21] ica_1.0-3                       plyr_1.8.9                     
    #>  [23] plotly_4.10.4                   zoo_1.8-12                     
    #>  [25] cachem_1.1.0                    igraph_2.0.3                   
    #>  [27] mime_0.12                       lifecycle_1.0.4                
    #>  [29] pkgconfig_2.0.3                 Matrix_1.7-0                   
    #>  [31] R6_2.5.1                        fastmap_1.2.0                  
    #>  [33] fitdistrplus_1.1-11             future_1.33.2                  
    #>  [35] shiny_1.8.1.1                   digest_0.6.36                  
    #>  [37] colorspace_2.1-0                patchwork_1.2.0                
    #>  [39] Seurat_5.2.1                    tensor_1.5                     
    #>  [41] RSpectra_0.16-1                 irlba_2.3.5.1                  
    #>  [43] RSQLite_2.3.7                   progressr_0.14.0               
    #>  [45] fansi_1.0.6                     spatstat.sparse_3.1-0          
    #>  [47] httr_1.4.7                      polyclip_1.10-6                
    #>  [49] abind_1.4-5                     compiler_4.4.1                 
    #>  [51] bit64_4.0.5                     DBI_1.2.3                      
    #>  [53] fastDummies_1.7.3               highr_0.11                     
    #>  [55] R.utils_2.12.3                  MASS_7.3-60.2                  
    #>  [57] openssl_2.2.0                   tools_4.4.1                    
    #>  [59] lmtest_0.9-40                   httpuv_1.6.15                  
    #>  [61] future.apply_1.11.2             goftest_1.2-3                  
    #>  [63] R.oo_1.26.0                     glue_1.7.0                     
    #>  [65] nlme_3.1-164                    promises_1.3.0                 
    #>  [67] grid_4.4.1                      Rtsne_0.17                     
    #>  [69] cluster_2.1.6                   reshape2_1.4.4                 
    #>  [71] generics_0.1.3                  gtable_0.3.5                   
    #>  [73] spatstat.data_3.1-2             R.methodsS3_1.8.2              
    #>  [75] tidyr_1.3.1                     data.table_1.15.4              
    #>  [77] sp_2.1-4                        utf8_1.2.4                     
    #>  [79] spatstat.geom_3.2-9             RcppAnnoy_0.0.22               
    #>  [81] ggrepel_0.9.5                   shinymanager_1.0.410           
    #>  [83] RANN_2.6.1                      pillar_1.9.0                   
    #>  [85] stringr_1.5.1                   spam_2.10-0                    
    #>  [87] RcppHNSW_0.6.0                  later_1.3.2                    
    #>  [89] splines_4.4.1                   dplyr_1.1.4                    
    #>  [91] lattice_0.22-6                  bit_4.0.5                      
    #>  [93] survival_3.6-4                  deldir_2.0-4                   
    #>  [95] tidyselect_1.2.1                miniUI_0.1.1.1                 
    #>  [97] pbapply_1.7-2                   knitr_1.47                     
    #>  [99] gridExtra_2.3                   scattermore_1.2                
    #> [101] xfun_0.45                       shinydashboard_0.7.2           
    #> [103] matrixStats_1.3.0               DT_0.33                        
    #> [105] stringi_1.8.4                   scrypt_0.1.6                   
    #> [107] lazyeval_0.2.2                  yaml_2.3.8                     
    #> [109] shinyWidgets_0.8.6              evaluate_0.24.0                
    #> [111] codetools_0.2-20                tibble_3.2.1                   
    #> [113] cli_3.6.3                       uwot_0.2.2                     
    #> [115] xtable_1.8-4                    reticulate_1.38.0              
    #> [117] munsell_0.5.1                   jquerylib_0.1.4                
    #> [119] Rcpp_1.0.12                     SeuratExplorer_0.0.6.2000      
    #> [121] globals_0.16.3                  spatstat.random_3.2-3          
    #> [123] png_0.1-8                       parallel_4.4.1                 
    #> [125] blob_1.2.4                      ggplot2_3.5.1                  
    #> [127] dotCall64_1.1-1                 listenv_0.9.1                  
    #> [129] viridisLite_0.4.2               scales_1.3.0                   
    #> [131] ggridges_0.5.6                  SeuratObject_5.0.2             
    #> [133] purrr_1.0.2                     rlang_1.1.4                    
    #> [135] cowplot_1.1.3
