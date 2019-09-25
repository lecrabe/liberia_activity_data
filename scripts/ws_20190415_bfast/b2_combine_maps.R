##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org  or yelena.finegold@fao.org
# Last update: 2019-08-10
##########################################################################################
## USER DEFINED PARAMETERS

mmu <- 11
source('~/liberia_activity_data/scripts/s0_parameters.R')
#################
## RUN THE SCRIPT
library(gdalUtils)
time_start  <- Sys.time()

if(!(file.exists(paste0(lc_dir,"LCF2015_Liberia_32629_10m.tif")))){
  system(sprintf("wget -O %s %s",
                 paste0(lc_dir,"LCF2015_Liberia_32629_10m.tif"),
                 "https://www.dropbox.com/s/7f4hjbn40oktprv/LCF2015_Liberia_32629_10m.tif?dl=0"))}


lcc_map <- paste0(bfst_dir,list.files(bfst_dir,pattern = glob2rx("*.tif"))[1])
  
####################################################################################
####### PREPARE COMMODITY MAP (RASTERIZE AND CLIP TO EXTENT)
####################################################################################
shp <- readOGR(paste0(ag_dir,"all_farms_merged.shp"))
dbf <- shp@data
dbf$unique_id <- row(dbf)[,1]
shp@data <- dbf

shp <- spTransform(shp,CRS('+init=epsg:4326'))

writeOGR(shp,paste0(ag_dir,"commodities.shp"),paste0(ag_dir,"commodities"),"ESRI Shapefile",overwrite_layer = T)

head(shp)
system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(ag_dir,"commodities.shp"),
               lcc_map,
               paste0(ag_dir,"commodities.tif"),
               "unique_id"
))

#################### ALIGN PRODUCTS ON MASK: BFAST RESULTS
mask   <- lcc_map
proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]


#################### INPUT : GEOVILLE MAP 2015
input  <- paste0(lc_dir,"LCF2015_Liberia_32629_10m.tif")
ouput  <- paste0(lc_dir,"lc_2015.tif")

system(sprintf("gdalwarp -co COMPRESS=LZW -t_srs \"%s\" -te %s %s %s %s -tr %s %s %s %s -overwrite",
               proj4string(raster(mask)),
               extent(raster(mask))@xmin,
               extent(raster(mask))@ymin,
               extent(raster(mask))@xmax,
               extent(raster(mask))@ymax,
               res(raster(mask))[1],
               res(raster(mask))[2],
               input,
               ouput
))

####################################################################################
####### COMBINE LAYERS
####################################################################################


############################ CREATE THE LOSS LAYER
system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"lc_2015.tif"),
               lcc_map,
               paste0(ag_dir,"commodities.tif"),
               paste0(lc_dir,"tmp_loss.tif"),
               paste0("((B==4)+(B==5))*(A>=1)*(A<=4)*(C==0)")
))

############################ CREATE THE GAIN LAYER
system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"lc_2015.tif"),
               lcc_map,
               paste0(ag_dir,"commodities.tif"),
               paste0(lc_dir,"tmp_gain.tif"),
               paste0("((B==8)+(B==9))+((A==14)*(A==16)*2)*(C==0)")
))
# paste0("((B==8)+(B==9))*((A==14)+(A==16))*(C==0)")

gdalinfo(paste0(lc_dir,"tmp_gain.tif"),mm=T)
plot(raster(paste0(lc_dir,"tmp_gain.tif")))
plot(raster(lcc_map))

############################ CREATE THE FOREST NON FOREST MASK
system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"lc_2015.tif"),
               paste0(lc_dir,"tmp_fnf_2015.tif"),
               paste0("(A>=1)*(A<=4)*1+(A>4)*(A<14)*2+(A==14)*3+(A>14)*2")
))

system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"tmp_fnf_2015.tif"),
               paste0(lc_dir,"tmp_loss.tif"),
               paste0(lc_dir,"tmp_gain.tif"),
               paste0(lc_dir,"tmp_fnf_2018.tif"),
               paste0("(B==0)*(C==0)*A+(B==1)*2+(C==1)*1")
))



#################### CREATE A COLOR TABLE FOR THE OUTPUT MAP
my_classes <- c(0,1,2,3)
my_colors  <- col2rgb(c("black","darkgreen","grey","blue"))

pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]))

write.table(pct,paste0(dd_dir,"color_table.txt"),row.names = F,col.names = F,quote = F)




################################################################################
#################### Add pseudo color table to result
################################################################################
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(dd_dir,"color_table.txt"),
               paste0(lc_dir,"tmp_fnf_2018.tif"),
               paste0(lc_dir,"tmp_fnf_pct_2018.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(lc_dir,"tmp_fnf_pct_2018.tif"),
               paste0(lc_dir,"fnf_2018.tif")
 ))


################## PREPARE OUTPUT FOR MSPA

system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"fnf_2018.tif"),
               paste0(lc_dir,"mspa_2018.tif"),
               paste0("(A==1)*2+(A>1)*1")
))

################################################################################
#################### CREATE UPDATED LAND COVER MAP
################################################################################
## CLASSES FROM THE GEOVILLE LAND COVER MAP
# - 001 Natural and Semi-natural forest 80% - 100%
# - 002 Natural and Semi-natural forest 60% - 80%
# - 003 Natural and Semi-natural forest 30% - 60%
# - 004 Mangrove forest
# - 005 Tree cover 0 - 30%
# - 006 Shrubs
# - 007 Rubber tree plantations (Smallholder)
# - 008 Rubber tree plantations (Industrial)
# - 009 Oil palm plantations (Smallholder)
# - 010 Oil palm plantations (Industrial)
# - 011 Other Plantations (Smallholder)
# - 012 Other Plantations (Industrial)
# - 013 Swamps
# - 014 Surface water bodies
# - 015 Bare Soil
# - 016 Ecosystem complex (rocks and sand)
# - 017 Settlements
# - 018 Grassland
##


#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -8 -st %s %s %s ",
               mmu,
               paste0(lc_dir,"tmp_loss.tif"),
               paste0(lc_dir,'tmp_loss_sieve.tif')
               
))

#################### SIEVE OUT INDIVIDUAL PIXELS
system(sprintf("gdal_sieve.py -st 1 %s %s ",
               paste0(lc_dir,"tmp_loss.tif"),
               paste0(lc_dir,'tmp_loss_sieve1.tif')
               
))
#################### SIEVE OUT INDIVIDUAL PIXELS
system(sprintf("gdal_sieve.py -st 1 %s %s ",
               paste0(lc_dir,"tmp_gain.tif"),
               paste0(lc_dir,'tmp_gain_sieve1.tif')
               
))

## Compress sieved
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(lc_dir,'tmp_loss_sieve1.tif'),
               paste0(lc_dir,  'loss_sieve1.tif' )
               
))

## Compress sieved
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(lc_dir,'tmp_gain_sieve1.tif'),
               paste0(lc_dir,  'gain_sieve1.tif' )
               
))
## Compress sieved
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(lc_dir,'tmp_loss_sieve.tif'),
               paste0(lc_dir,  'loss_sieve.tif' )
               
))


#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"tmp_loss.tif"),
               paste0(lc_dir,  'loss_sieve.tif' ),
               paste0(lc_dir,  'loss_sieve_inf.tif' ),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))

############################ CREATE THE UPDATED LAND COVER MAP FOR 2018
system(sprintf("gdal_calc.py -A %s -B %s -C %s -D %s -E %s -F %s -G %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"lc_2015.tif"),           # A - geoville map
               lcc_map,                                # B - bfast thresholds
               paste0(ag_dir,"commodities.tif"),       # C - commodities
               paste0(lc_dir,  'loss_sieve1.tif' ),    # D - bfast loss all
               paste0(lc_dir,  'loss_sieve.tif' ),     # E - bfast loss >1ha
               paste0(lc_dir,  'loss_sieve_inf.tif' ), # F - bfast loss <1ha
               paste0(lc_dir,  'gain_sieve1.tif' ),    # G - bfast gain
               
               paste0(lc_dir,  'lc_2018.tif' ),
               
               paste0( "(A==1)*(E==1)*5 + ",
               "(A==1)*(F==1)*2 +",
               "(A==1)*(G==1)*1 +",
               "(A==2)*(E==1)*5 +",
               "(A==2)*(F==1)*3 +",
               "(A==2)*(G==1)*1 +",
               "(A==3)*(E==1)*5 +",
               "(A==3)*(F==1)*5 +",
               "(A==3)*(G==1)*2 +",
               "(A==4)*(D==1)*13 +",
               "(A==4)*(G==1)*4 +",
               "(A==5)*(D==1)*11 +",
               "(A==5)*(G==1)*3 +",
               "(A==18)*(D==1)*11 +",
               "(A==18)*(G==1)*19 + ",# gain in grassland savannah - potential classes - 5,9,11
               "(A==6)*(D==1)*11 +",
               "(A==6)*(G==1)*20 + ",# gain in shrubs - potential classes - 9,11
               "(A==7)*(D==1)*21 + ",# loss in rubber smallholder - potential classes - 9,11
               "(A==7)*(G==1)*7 +",
               "(A==8)*(D==1)*8 +",
               "(A==8)*(G==1)*8 +",
               "(A==9)*(D==1)*22 + ",# loss in oil palm smallholder - potential classes - 7,11
               "(A==9)*(G==1)*3 +",
               "(A==10)*(D==1)*10 +",
               "(A==10)*(G==1)*10 +",
               "(A==11)*(D==1)*11 +",
               "(A==11)*(G==1)*3 +",
               "(A==12)*(D==1)*12 +",
               "(A==12)*(G==1)*12 +",
               "(A==13)*(D==1)*23 + ",# loss in swamps - potential classes - 7,11
               "(A==13)*(G==1)*4 +",
               "(A==16)*(D==1)*15 +",
               "(A==16)*(G==1)*16 + ",
               "(A==14)*(D==1)*14 +",
               "(A==14)*(G==1)*24 + ",# gain in surface water - potential classes - 4,13
               "(A==15)*(D==1)*15 +",
               "(A==15)*(G==1)*18 +",
               "(A==17)*(D==1)*17 +",
               "(A==17)*(G==1)*18 +",
               "(D==0)*(G==0)*A+",
               "(C==0)*0"
                ,collapse = "")
  
))

gdalinfo( paste0(lc_dir,  'lc_2018.tif' ),mm=T)



# #################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
# system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(thres_dir,"/","tmp_hi_mag_gain.tif"),
#                paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve.tif'),
#                paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve_inf.tif'),
#                paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
# ))


################################################################################
####################  CLEAN
################################################################################
system(sprintf("rm %s",
               paste0(lc_dir,"tmp*.tif")
))

(time_decision_tree <- Sys.time() - time_start)

