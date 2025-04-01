
<!-- README.md is generated from README.Rmd. Please edit that file -->

# SeuratExplorerServer

<!-- badges: start -->

[![](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![](https://img.shields.io/badge/devel%20version-0.1.1-rossellhayes.svg)](https://github.com/fentouxungui/SeuratExplorerServer)
[![](https://img.shields.io/github/languages/code-size/fentouxungui/SeuratExplorerServer.svg)](https://github.com/fentouxungui/SeuratExplorerServer)
<!-- badges: end -->

> 可用于搭建单细胞数据库，允许用户访问位于服务器上的分析结果。该R包支持
> `App`
> 加密、多数据切换、分析报告浏览及下载、分析结果检索及再分析（基于`SeuratExplorer`）和自定义初始化参数。

## 1. 功能介绍

***数据加密***

对于未公开数据，可对 `App` 设置密码，限制访问。

***多数据切换***

做完某个分析后，可能会提取某种细胞类型，进行再分析，将得到新的 `Seurat`
对象，这样多个 `Seurat` 对象可以放到同一个 `App`
中；或者某篇文章里做了多个单细胞数据分析，所有的分析结果也都可以放到同一个
`App` 中。

***分析报告浏览***

支持浏览、查看和下载分析过程中产生的分析报告文件，包括`pdf, html, tiff, csv, jpg, jpeg, png, bmp, svg`
等格式，也可通过修改参数指定其它类型文件。

***支持自定义数据的初始化参数***

可以设置数据加载后的默认参数，比如`Cluster Resolution、Species、Dimension Reduction`
等。

***可拓展性***

多个由`SeuratExplorerServer` 搭建的
`App`，可组成一个小型单细胞数据库，分别通过对应目录进行访问。将每个
`App` 的访问地址及数据信息汇总到一个 `index`
网页中，这样用户可以查找相关数据，并访问。这部分暂不提供相关 `DEMO`
代码。

***与`SeuratExplorer`的关系与区别***

`SeuratExplorer`相当于一个桌面版软件，允许在本地电脑上查看和分析单个`Seurat`分析结果，即使把`SeuratExplorer`安装到服务器上，那也只能通过上传数据方式来浏览客户端电脑上的单细胞数据。而`SeuratExplorerServer`可作为`Shiny app`部署到服务器上，用户可通过网页来访问位于服务器上的单细胞数据，该R包不仅具有`SeuratExplorer`
包的所有功能外，还可以查看中间分析结果，并且支持多数据切换、密码保护和自定义部分初始化参数等功能。`SeuratExplorerServer`依赖于`SeuratExplorer`，并且具备所有`SeuratExplorer`里的数据分析功能。

## 2. 安装及运行

You can install the development version of `SeuratExplorer` and
`SeuratExplorerServer`like so:

``` r
# install dependency
if(!require(devtools)){install.packages("devtools")}
install_github("fentouxungui/SeuratExplorer")

# install SeuratExplorerServer
options(timeout = max(300, getOption("timeout")))
install_github("fentouxungui/SeuratExplorerServer")
```

Run App:

``` r
library(SeuratExplorerServer)
launchSeuratExplorerServer()
```

## 4. 软件工作流

- 登录：输入账户和密码。

- 数据选择、加载和切换。

- `sample meta`信息展示及下载。

- 浏览分析报告：单击`Generate/Update Reports` 按钮，会在 `App`
  所在目录（如：`Fly-Gut-EEs-scRNAseq`）的上层目录创建同名但以
  `_reports` 为后缀的目录（如：
  `Fly-Gut-EEs-scRNAseq_reports`），`sample meta` 中 `Reports.main` 列和
  `Reports.second`列的对应目录中里的符合类型的文件，会以快捷连接方式放到
  `_reports` 目录中。

- `SeuratExplorer`里的功能。

- 修改样本元信息的默认参数，重启后生效。

- 关闭时会删除`_reports`目录（如：`Fly-Gut-EEs-scRNAseq_reports`）

## 5. Examples deployed on Shinyserver

[**Open**](http://www.nibs.ac.cn:666/Test-SeuratExplorer-Server/) a live
demo .

``` r
# app.R
library(SeuratExplorerServer)
launchSeuratExplorerServer(Encrypted = TRUE,
                           credentials = data.frame(user = "shiny", password = "12345", stringsAsFactors = FALSE),
                           paramterfile = revise_demo_path(),
                           TechnicianEmail = "zhangyongchao@nibs.ac.cn",
                           TechnicianName = "ZhangYongchao",
                           verbose = FALSE)
```

## 6. Tutorials

### 6.1 Generate credentials

Please refer to R package
[shinymanager](https://github.com/datastorm-open/shinymanager) for
details to generate a credentials data.

``` r
# Init DB using credentials data
credentials <- data.frame(
  user = "shiny",
  password = "12345",
  stringsAsFactors = FALSE
)
```

### 6.2 Generate sample metadata parameters

从 `dataframe` 生成 `metadata`。

``` r
data_meta <- data.frame(
  # 必填：主分析目录, Rds文件位于此目录中，并且所有位于该目录下的指定文件也会被收录到reports中，以sample name进行命名和区分。
  Reports.main = c(system.file("extdata/demo", "fly", package ="SeuratExplorerServer"), system.file("extdata/demo", "mouse", package ="SeuratExplorerServer")), 
  # 必填：Rds文件在主分析目录中的相对目录
  Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"),
  # 必填：次要分析目录，此目录中的分析报告也会被加载到reports临时目录中，比如cellranger的结果，会被放到Others子目录下。
  Reports.second = c(NA, NA), 
  # 必填：Sample name
  Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT", "Mouse-Intestine-scRNAseq-Haber"), 
  # 选填： 用于设定split选项的参数,如果是多样本数据合并，一般该值要大于或等于样本数。
  SplitOptions.MaxLevel = c(1, 4), 
  # 选填： dimension reduction的默认值。
  Default.DimensionReduction = c("tsne", "umap"),
  # 选填： cluster的默认值。
  Default.ClusterResolution = c("res.0.4", NA),
  # 选填： Human, Mouse, Fly or Others
  Species = c("Fly", "Mouse"), 
  # 选填：description of the sample or the analysis, or whatever.
  Description = c("blabla","hahaha"), 
  stringsAsFactors = FALSE)

data_meta
#>                                                                              Reports.main
#> 1   C:/Users/Xi_Lab/AppData/Local/R/win-library/4.4/SeuratExplorerServer/extdata/demo/fly
#> 2 C:/Users/Xi_Lab/AppData/Local/R/win-library/4.4/SeuratExplorerServer/extdata/demo/mouse
#>                      Rds.path Reports.second                    Sample.name
#> 1 Rds-file/G101_PC20res04.rds             NA     Fly-Gut-EEs-scRNAseq-GuoXT
#> 2     haber.tsne.embeding.rds             NA Mouse-Intestine-scRNAseq-Haber
#>   SplitOptions.MaxLevel Default.DimensionReduction Default.ClusterResolution
#> 1                     1                       tsne                   res.0.4
#> 2                     4                       umap                      <NA>
#>   Species Description
#> 1     Fly      blabla
#> 2   Mouse      hahaha
```

``` r

# check the meta data
library(SeuratExplorerServer)
invisible(check_metadata(parameters = data_meta))
# if check passed, save the meta data
# saveRDS(data_meta, file = "data_meta.rds")
```

或直接使用 `initialize_metadata` 函数生成 `meta data`:

``` r
library(SeuratExplorerServer)
data_meta <- initialize_metadata(
  Reports.main = c(system.file("extdata/demo", "fly", package ="SeuratExplorerServer"), system.file("extdata/demo", "mouse", package ="SeuratExplorerServer")),
  Rds.path = c("Rds-file/G101_PC20res04.rds", "haber.tsne.embeding.rds"),
  Reports.second = c(NA, NA), Sample.name = c("Fly-Gut-EEs-scRNAseq-GuoXT", "Mouse-Intestine-scRNAseq-Haber"))

data_meta
#>                                                                              Reports.main
#> 1   C:/Users/Xi_Lab/AppData/Local/R/win-library/4.4/SeuratExplorerServer/extdata/demo/fly
#> 2 C:/Users/Xi_Lab/AppData/Local/R/win-library/4.4/SeuratExplorerServer/extdata/demo/mouse
#>                      Rds.path Reports.second                    Sample.name
#> 1 Rds-file/G101_PC20res04.rds             NA     Fly-Gut-EEs-scRNAseq-GuoXT
#> 2     haber.tsne.embeding.rds             NA Mouse-Intestine-scRNAseq-Haber
#>   Species Description Default.DimensionReduction Default.ClusterResolution
#> 1      NA          NA                         NA                        NA
#> 2      NA          NA                         NA                        NA
#>   SplitOptions.MaxLevel
#> 1                    NA
#> 2                    NA
```

``` r

# save metadata
# saveRDS(data_meta, file = "data_meta.rds")
```

必填项目一般是由数据分析员设定的，其他参数可以在 `App`
运行过程中进行修改, 即允许用户自行设定。

### 6.3 Run app

``` r
library(SeuratExplorerServer)
launchSeuratExplorerServer(Encrypted = TRUE, 
                           credentials = credentials,
                           paramterfile = "sample-paramters.rds",
                           TechnicianEmail = "your-email",
                           TechnicianName = "your-name")
```

## 7. Screenshots

<img src="inst/extdata/www/login.png" width="50%" />

<img src="inst/extdata/www/dataset.png" width="80%" /><img src="inst/extdata/www/reports-main.png" width="80%" /><img src="inst/extdata/www/reports-2.png" width="80%" /><img src="inst/extdata/www/reports-3.png" width="80%" /><img src="inst/extdata/www/settings.png" width="80%" />

## 8. Rsession info

    #> R version 4.4.3 (2025-02-28 ucrt)
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
    #> other attached packages:
    #> [1] SeuratExplorerServer_0.1.1 badger_0.2.4              
    #> 
    #> loaded via a namespace (and not attached):
    #>   [1] RColorBrewer_1.1-3     rstudioapi_0.16.0      dlstats_0.1.7         
    #>   [4] jsonlite_1.8.8         billboarder_0.4.1      magrittr_2.0.3        
    #>   [7] spatstat.utils_3.0-5   rmarkdown_2.27         fs_1.6.4              
    #>  [10] vctrs_0.6.5            ROCR_1.0-11            memoise_2.0.1         
    #>  [13] spatstat.explore_3.2-7 askpass_1.2.0          htmltools_0.5.8.1     
    #>  [16] sass_0.4.9             sctransform_0.4.1      parallelly_1.37.1     
    #>  [19] KernSmooth_2.23-26     bslib_0.7.0            htmlwidgets_1.6.4     
    #>  [22] desc_1.4.3             ica_1.0-3              plyr_1.8.9            
    #>  [25] plotly_4.10.4          zoo_1.8-12             cachem_1.1.0          
    #>  [28] igraph_2.0.3           mime_0.12              lifecycle_1.0.4       
    #>  [31] pkgconfig_2.0.3        Matrix_1.7-2           R6_2.5.1              
    #>  [34] fastmap_1.2.0          fitdistrplus_1.1-11    future_1.33.2         
    #>  [37] shiny_1.8.1.1          digest_0.6.36          colorspace_2.1-0      
    #>  [40] shinycssloaders_1.0.0  patchwork_1.2.0        Seurat_5.2.1          
    #>  [43] tensor_1.5             RSpectra_0.16-1        irlba_2.3.5.1         
    #>  [46] RSQLite_2.3.7          progressr_0.14.0       fansi_1.0.6           
    #>  [49] spatstat.sparse_3.1-0  httr_1.4.7             polyclip_1.10-6       
    #>  [52] abind_1.4-5            compiler_4.4.3         bit64_4.0.5           
    #>  [55] DBI_1.2.3              fastDummies_1.7.3      highr_0.11            
    #>  [58] R.utils_2.12.3         MASS_7.3-64            openssl_2.2.0         
    #>  [61] tools_4.4.3            lmtest_0.9-40          httpuv_1.6.15         
    #>  [64] future.apply_1.11.2    goftest_1.2-3          R.oo_1.26.0           
    #>  [67] glue_1.7.0             nlme_3.1-167           promises_1.3.0        
    #>  [70] grid_4.4.3             Rtsne_0.17             cluster_2.1.8         
    #>  [73] reshape2_1.4.4         generics_0.1.3         gtable_0.3.5          
    #>  [76] spatstat.data_3.1-2    R.methodsS3_1.8.2      shinyBS_0.61.1        
    #>  [79] tidyr_1.3.1            data.table_1.15.4      sp_2.1-4              
    #>  [82] utf8_1.2.4             spatstat.geom_3.2-9    RcppAnnoy_0.0.22      
    #>  [85] shinymanager_1.0.410   ggrepel_0.9.5          RANN_2.6.1            
    #>  [88] pillar_1.9.0           stringr_1.5.1          yulab.utils_0.1.4     
    #>  [91] spam_2.10-0            RcppHNSW_0.6.0         later_1.3.2           
    #>  [94] splines_4.4.3          dplyr_1.1.4            lattice_0.22-6        
    #>  [97] bit_4.0.5              survival_3.8-3         deldir_2.0-4          
    #> [100] tidyselect_1.2.1       rvcheck_0.2.1          miniUI_0.1.1.1        
    #> [103] pbapply_1.7-2          knitr_1.47             gridExtra_2.3         
    #> [106] scattermore_1.2        shinydashboard_0.7.2   xfun_0.45             
    #> [109] matrixStats_1.3.0      DT_0.33                stringi_1.8.4         
    #> [112] scrypt_0.1.6           lazyeval_0.2.2         yaml_2.3.8            
    #> [115] shinyWidgets_0.8.6     evaluate_0.24.0        codetools_0.2-20      
    #> [118] data.tree_1.1.0        tibble_3.2.1           BiocManager_1.30.23   
    #> [121] cli_3.6.3              uwot_0.2.2             xtable_1.8-4          
    #> [124] reticulate_1.38.0      munsell_0.5.1          jquerylib_0.1.4       
    #> [127] Rcpp_1.0.12            SeuratExplorer_0.1.1   globals_0.16.3        
    #> [130] spatstat.random_3.2-3  png_0.1-8              parallel_4.4.3        
    #> [133] blob_1.2.4             ggplot2_3.5.1          dotCall64_1.1-1       
    #> [136] listenv_0.9.1          viridisLite_0.4.2      scales_1.3.0          
    #> [139] ggridges_0.5.6         SeuratObject_5.0.2     purrr_1.0.2           
    #> [142] rlang_1.1.4            cowplot_1.1.3
