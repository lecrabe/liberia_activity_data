####################################################################################################
####################################################################################################
## Set environment variables
## Contact remi.dannunzio@fao.org 
## updated by: yelena.finegold@fao.org
## 2018/09/07
## updated: 2019/10/17
####################################################################################################
####################################################################################################

####################################################################################################

### Read all external files with TEXT as TEXT
options(stringsAsFactors = FALSE)

### Create a function that checks if a package is installed and installs it otherwise
packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}

### Install (if necessary) two missing packages in your local SEPAL environment
packages(Hmisc)
packages(RCurl)
packages(hexbin)
packages(gfcanalysis)

### Load necessary packages
packages(raster)
packages(rgeos)
packages(ggplot2)
packages(rgdal)
packages(plyr)
packages(dplyr)
packages(foreign)
packages(reshape2)
packages(survey)
packages(stringr)
packages(tidyr)
packages(devtools)

## Set the working directory
rootdir       <- "~/liberia_activity_data/"

## Set two downloads directories
gfcstore_dir  <- paste0('/',paste0(strsplit(getwd(),'/')[[1]][2:3],collapse = '/'),"/downloads/gfc/",countrycode,'/')
#esastore_dir  <- "~/downloads/ESA_2016/"

## Set the country code
countrycode <- "LBR"

## years to assess
startyear <- 2017
endyear <- 2018
## Go to the root directory
setwd(rootdir)
rootdir <- paste0(getwd(),"/")

scriptdir<- paste0(rootdir,"scripts/")
data_dir <- paste0(rootdir,"data/")
gadm_dir <- paste0(rootdir,"data/gadm/")
gfc_dir  <- paste0(rootdir,"data/gfc/")
dd_dir   <- paste0(rootdir,"data/dd_map/")
lc_dir   <- paste0(rootdir,"data/forest_mask/")
ag_dir   <- paste0(rootdir,"data/farms/")
pl_dir   <- paste0(rootdir,"data/priority_landscapes/")
ref_dir  <- paste0(rootdir,"data/reference_data/")
samp_dir <- paste0(rootdir,"data/samples/")
coll_dir <- paste0(ref_dir,'collected_samples/')
ana_dir  <- paste0(ref_dir,'analysis/')
plot_dir <- paste0(ana_dir,'plots/')
rdsdir   <- paste0(rootdir,"data/roads/")

tile_dir <- paste0(rootdir,"data/tiling/")
#tab_dir  <- paste0(rootdir,"data/tables/")
# esa_dir  <- paste0(rootdir,"data/esa/")
# lsat_dir <- paste0(rootdir,"data/mosaic_lsat/")
# seg_dir  <- paste0(rootdir,"data/segments/")

dir.create(data_dir,showWarnings = F)
dir.create(gadm_dir,showWarnings = F)
dir.create(gfcstore_dir,showWarnings = F)
dir.create(gfc_dir,showWarnings = F)
dir.create(dd_dir,showWarnings = F)
dir.create(lc_dir,showWarnings = F)
dir.create(ag_dir,showWarnings = F)
dir.create(pl_dir,showWarnings = F)
dir.create(ref_dir,showWarnings = F)
dir.create(samp_dir,showWarnings = F)
dir.create(ana_dir,showWarnings = F)
dir.create(plot_dir,showWarnings = F)
dir.create(rdsdir,showWarnings = F)

# dir.create(esastore_dir,showWarnings = F)
# dir.create(esa_dir,showWarnings = F)
# dir.create(lsat_dir,showWarnings = F)
# dir.create(seg_dir,showWarnings = F)
dir.create(tile_dir,showWarnings = F)

#################### FOREST DEFINITION
gfc_threshold <- 30 # in % Tree cover
mmu <- 12           # in pixels 

#################### PRODUCTS AT THE THRESHOLD
gfc_tc       <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_tc.tif")
gfc_ly       <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_ly.tif")
gfc_gn       <- paste0(gfc_dir,"gfc_gain.tif")
gfc_end      <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_F_",endyear,".tif")
gfc_start    <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_F_",startyear,".tif")
gfc_mp       <- paste0(gfc_dir,"gfc_map_",startyear,"_",endyear,"_th",gfc_threshold,".tif")
gfc_mp_crop  <- paste0(gfc_dir,"gfc_map_",startyear,"_",endyear,"_th",gfc_threshold,"_crop.tif")
gfc_mp_sub   <- paste0(gfc_dir,"gfc_map_",startyear,"_",endyear,"_th",gfc_threshold,"_sub_crop.tif")

############ CREATE A FUNCTION TO GENERATE REGULAR GRIDS
generate_grid <- function(aoi,size){
  ### Create a set of regular SpatialPoints on the extent of the created polygons  
  sqr <- SpatialPoints(makegrid(aoi,offset=c(-0.5,-0.5),cellsize = size))
  
  ### Convert points to a square grid
  grid <- points2grid(sqr)
  
  ### Convert the grid to SpatialPolygonDataFrame
  SpP_grd <- as.SpatialPolygons.GridTopology(grid)
  
  sqr_df <- SpatialPolygonsDataFrame(Sr=SpP_grd,
                                     data=data.frame(rep(1,length(SpP_grd))),
                                     match.ID=F)
  ### Assign the right projection
  proj4string(sqr_df) <- proj4string(aoi)
  sqr_df
}
