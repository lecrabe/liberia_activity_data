##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-10-14
##########################################################################################

time_start  <- Sys.time()

####################################################################################
####### PREPARE COMMODITY MAP
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
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(ag_dir,"commodities.tif"),
               "unique_id"
))

####################################################################################
####### COMBINE GFC LAYERS
####################################################################################

#################### CREATE GFC TREE COVER MAP IN 2007 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_2007_gt",gfc_threshold,".tif"),
               paste0("(A>",gfc_threshold,")*((B==0)+(B>6))*A")
))

#################### CREATE GFC LOSS MAP AT THRESHOLD between 2007 and 2016
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,".tif"),
               paste0("(A>",gfc_threshold,")*(B>6)*(B<16)")
))

#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,"_sieve.tif")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,"_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))


#################### CREATE GFC TREE COVER MASK IN 2016 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2007_gt",gfc_threshold,".tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,".tif"),
               paste0("(A>0)*((B>=16)+(B==0))")
))


#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_sieve.tif")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))

#################### COMBINATION INTO DD MAP (1==NF, 2==F, 3==Df, 4==Dg, 11==agriculture)
system(sprintf("gdal_calc.py -A %s -B %s -C %s -D %s -E %s -F %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2007_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0716_gt",gfc_threshold,"_inf.tif"),
               paste0(ag_dir,"commodities.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_inf.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,".tif"),
               paste0("(A==0)*1+(A>0)*(D==0)*((B==0)*(C==0)*((E>0)*2+(F>0)*1)+(B>0)*3+(C>0)*4)+(A>0)*(D>0)*11")
))

################################################################################
#################### PROJECT IN UTM 29
################################################################################
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:32629",
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm.tif")
))

#################### Create a country boundary mask at the GFC resolution (TO BE REPLACED BY NATIONAL DATA IF AVAILABLE) 
system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(gadm_dir,"Liberia_dd_utm.shp"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm.tif"),
               paste0(gadm_dir,"Liberia_dd_utm.tif"),
               "ID"
))

#################### CLIP TO COUNTRY BOUNDARIES
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm.tif"),
               paste0(gadm_dir,"Liberia_dd_utm.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_country.tif"),
               paste0("(B>0)*A")
))

#################### CREATE A COLOR TABLE FOR THE OUTPUT MAP
my_classes <- c(0,1,2,3,4,11)
my_colors  <- col2rgb(c("black","grey","darkgreen","red","orange","purple"))

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
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_country.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"pct.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"pct.tif"),
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif")
))



#############################################################
### ADAPT PRIORITY LANDSCAPE MAPS FOR CROPPING
#############################################################
pls <- readOGR(paste0(pl_dir,"priority_areas_20190925.shp"))
proj4string(pls)
head(pls)
pls@data$Id <- 1:2
names(pls@data)[1] <- "id"
writeOGR(pls,paste0(pl_dir,"priority_areas_20190925.shp"),"priority_areas_20190925","ESRI Shapefile",overwrite_layer = T)

#################### RASTERIZE THE PRIORITY LANDSCAPE
system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(pl_dir,"priority_areas_20190925.shp"),
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
               paste0(pl_dir,"priority_areas_20190925.tif"),
               "id"
))

#################### MASK MAP FOR PRIORITY LANDSCAPE 1
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
               paste0(pl_dir,"priority_areas_20190925.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1.tif"),
               paste0("(B==1)*A")
))

#################### MASK MAP FOR PRIORITY LANDSCAPE 2
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
               paste0(pl_dir,"priority_areas_20190925.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2.tif"),
               paste0("(B==2)*A")
))

#################### MASK MAP FOR NON PRIORITY LANDSCAPE
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
               paste0(pl_dir,"priority_areas_20190925.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl.tif"),
               paste0("(B==0)*A")
))


################################################################################
#################### Add pseudo color table to result
################################################################################
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(dd_dir,"color_table.txt"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1_pct.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1_pct.tif"),
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_pl1_20190925.tif")
))

################################################################################
#################### Add pseudo color table to result
################################################################################
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(dd_dir,"color_table.txt"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2_pct.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2_pct.tif"),
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_pl2_20190925.tif")
))

################################################################################
#################### Add pseudo color table to result
################################################################################
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(dd_dir,"color_table.txt"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl.tif"),
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl_pct.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl_pct.tif"),
               paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_npl_20190925.tif")
))

################################################################################
####################  CLEAN
################################################################################
system(sprintf("rm %s",
               paste0(dd_dir,"tmp*.tif")
))

(time_decision_tree <- Sys.time() - time_start)

