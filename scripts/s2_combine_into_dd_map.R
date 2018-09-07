##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-08-24
##########################################################################################

time_start  <- Sys.time()

####################################################################################
####### GET COUNTRY BOUNDARIES
####################################################################################
aoi <- getData('GADM',path=gadm_dir, country= countrycode, level=1)
bb <- extent(aoi)

writeOGR(aoi,
         paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
         paste0("gadm_",countrycode,"_l1"),
         "ESRI Shapefile",
         overwrite_layer = T)

head(read.dbf(paste0(gadm_dir,"gadm_",countrycode,"_l1.dbf")))

#################### Create a country boundary mask at the GFC resolution (TO BE REPLACED BY NATIONAL DATA IF AVAILABLE) 
system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gadm_dir,"gadm_",countrycode,"_l1.tif"),
               "ID_1"
))
proj4string(shp)

####################################################################################
####### PREPARE COMMODITY MAP
####################################################################################
shp <- readOGR(paste0(ag_dir,"all_farms_merged.shp"))
dbf <- shp@data
dbf$unique_id <- row(dbf)[,1]
shp@data <- dbf
shp <- spTransform(shp,CRS('+init=epsg:4326'))
writeOGR(shp,paste0(ag_dir,"commodities.shp"),paste0(ag_dir,"commodities"),"ESRI Shapefile",overwrite_layer = T)
head(dbf)

system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(ag_dir,"commodities.shp"),
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(ag_dir,"commodities.tif"),
               "unique_id"
))

####################################################################################
####### COMBINE GFC LAYERS
####################################################################################

#################### CREATE GFC TREE COVER MAP IN 2004 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_2004_gt",gfc_threshold,".tif"),
               paste0("(A>",gfc_threshold,")*((B==0)+(B>3))*A")
))

#################### CREATE GFC LOSS MAP AT THRESHOLD between 2004 and 2014
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,".tif"),
               paste0("(A>",gfc_threshold,")*(B>3)*(B<15)")
))

#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st 12 %s %s ",
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,"_sieve.tif")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,"_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))

#################### COMBINATION INTO DD MAP (1==NF, 2==F, 3==Df, 4==Dg, 11==agriculture, 12==HCS_f, 13==HSC_df, 14==HSC_dg)
system(sprintf("gdal_calc.py -A %s -B %s -C %s -D %s -E %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2004_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,"_inf.tif"),
               paste0(gadm_dir,"gadm_",countrycode,"_l1.tif"),
               paste0(ag_dir,"commodities.tif"),
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,".tif"),
               paste0("(D>0)*((A==0)*1+(A>0)*(E==0)*((B==0)*(C==0)*2+(B>0)*3+(C>0)*4)+(A>60)*(E>0)*((B==0)*(C==0)*12+(B>0)*13+(C>0)*14)+(E>0)*(A<60)*11)")
))

#################### CREATE A COLOR TABLE FOR THE OUTPUT MAP
my_classes <- c(0,1,2,3,4,11,12,13,14)
my_colors  <- col2rgb(c("black","grey","darkgreen","red","orange","purple","lightgreen","pink","yellow"))

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
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,"pct.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,"pct.tif"),
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_geo.tif")
))

################################################################################
#################### PROJECT IN UTM 29
################################################################################
system(sprintf("gdalwarp -t_srs \"%s\" -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:32629",
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_geo.tif"),
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_utm.tif")
))

################################################################################
####################  CLEAN
################################################################################
system(sprintf("rm %s",
               paste0(dd_dir,"tmp*.tif")
))


#############################################################
### ADAPT PRIORITY LANDSCAPE MAPS FOR CROPPING
#############################################################
pls <- readOGR(paste0(pl_dir,"Priority_areas.shp"))
proj4string(pls)

head(pls)
pl1 <- pls[pls@data$Id == 1,]
pl2 <- pls[pls@data$Id == 2,]

writeOGR(pl1,paste0(pl_dir,"pl1.shp"),paste0(pl_dir,"pl1"),"ESRI Shapefile",overwrite_layer = T)
writeOGR(pl2,paste0(pl_dir,"pl2.shp"),paste0(pl_dir,"pl2"),"ESRI Shapefile",overwrite_layer = T)

#############################################################
### CROP TO Priority Landscape 1
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(pl_dir,"pl1.shp"),
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_utm.tif"),
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_utm_pl1.tif"),
               "Id"
))

#############################################################
### CROP TO Priority Landscape 2
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(pl_dir,"pl2.shp"),
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_utm.tif"),
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_utm_pl2.tif"),
               "Id"
))


(time_decision_tree <- Sys.time() - time_start)