##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-10-14
##########################################################################################

time_start  <- Sys.time()

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
               paste0(bfst_dir,"lcc_map.tif"),
               paste0(ag_dir,"commodities.tif"),
               "unique_id"
))

#################### ALIGN PRODUCTS ON MASK: BFAST RESULTS
mask   <- paste0(bfst_dir,"lcc_map.tif")
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

system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"lc_2015.tif"),
               paste0(bfst_dir,"lcc_map.tif"),
               paste0(ag_dir,"commodities.tif"),
               paste0(lc_dir,"tmp_loss.tif"),
               paste0("((B==4)+(B==5))*(A>=1)*(A<=4)*(C==0)")
))

system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"lc_2015.tif"),
               paste0(bfst_dir,"lcc_map.tif"),
               paste0(ag_dir,"commodities.tif"),
               paste0(lc_dir,"tmp_gain.tif"),
               paste0("((B==8)+(B==9))*((A==14)+(A==16))*(C==0)")
))

system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"lc_2015.tif"),
               paste0(lc_dir,"tmp_fnf_2015.tif"),
               paste0("(A>=1)*(A<=4)*1+(A>4)*2")
))

system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(lc_dir,"tmp_fnf_2015.tif"),
               paste0(lc_dir,"tmp_loss.tif"),
               paste0(lc_dir,"tmp_gain.tif"),
               paste0(lc_dir,"tmp_fnf_2018.tif"),
               paste0("(B==0)*(C==0)*A+(B==1)*2+(C==1)*1")
))


# #################### CREATE A COLOR TABLE FOR THE OUTPUT MAP
# my_classes <- c(0,1,2,3,4,11)
# my_colors  <- col2rgb(c("black","grey","darkgreen","red","orange","purple"))
# 
# pct <- data.frame(cbind(my_classes,
#                         my_colors[1,],
#                         my_colors[2,],
#                         my_colors[3,]))
# 
# write.table(pct,paste0(dd_dir,"color_table.txt"),row.names = F,col.names = F,quote = F)
# 
# 
# 
# 
# ################################################################################
# #################### Add pseudo color table to result
# ################################################################################
# system(sprintf("(echo %s) | oft-addpct.py %s %s",
#                paste0(dd_dir,"color_table.txt"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_country.tif"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"pct.tif")
# ))
# 
# ################################################################################
# #################### COMPRESS
# ################################################################################
# system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"pct.tif"),
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif")
# ))
# 
# 
# 
# #############################################################
# ### ADAPT PRIORITY LANDSCAPE MAPS FOR CROPPING
# #############################################################
# pls <- readOGR(paste0(pl_dir,"priority_areas_20181014.shp"))
# proj4string(pls)
# head(pls)
# 
# #################### RASTERIZE THE PRIORITY LANDSCAPE
# system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
#                scriptdir,
#                paste0(pl_dir,"priority_areas_20181014.shp"),
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
#                paste0(pl_dir,"priority_areas_20181014.tif"),
#                "id"
# ))
# 
# #################### MASK MAP FOR PRIORITY LANDSCAPE 1
# system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
#                paste0(pl_dir,"priority_areas_20181014.tif"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1.tif"),
#                paste0("(B==1)*A")
# ))
# 
# #################### MASK MAP FOR PRIORITY LANDSCAPE 2
# system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
#                paste0(pl_dir,"priority_areas_20181014.tif"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2.tif"),
#                paste0("(B==2)*A")
# ))
# 
# #################### MASK MAP FOR NON PRIORITY LANDSCAPE
# system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_20181014.tif"),
#                paste0(pl_dir,"priority_areas_20181014.tif"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl.tif"),
#                paste0("(B==0)*A")
# ))
# 
# 
# ################################################################################
# #################### Add pseudo color table to result
# ################################################################################
# system(sprintf("(echo %s) | oft-addpct.py %s %s",
#                paste0(dd_dir,"color_table.txt"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1.tif"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1_pct.tif")
# ))
# 
# ################################################################################
# #################### COMPRESS
# ################################################################################
# system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl1_pct.tif"),
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_pl1_20181014.tif")
# ))
# 
# ################################################################################
# #################### Add pseudo color table to result
# ################################################################################
# system(sprintf("(echo %s) | oft-addpct.py %s %s",
#                paste0(dd_dir,"color_table.txt"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2.tif"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2_pct.tif")
# ))
# 
# ################################################################################
# #################### COMPRESS
# ################################################################################
# system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_pl2_pct.tif"),
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_pl2_20181014.tif")
# ))
# 
# ################################################################################
# #################### Add pseudo color table to result
# ################################################################################
# system(sprintf("(echo %s) | oft-addpct.py %s %s",
#                paste0(dd_dir,"color_table.txt"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl.tif"),
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl_pct.tif")
# ))
# 
# ################################################################################
# #################### COMPRESS
# ################################################################################
# system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
#                paste0(dd_dir,"tmp_dd_map_0716_gt",gfc_threshold,"_utm_npl_pct.tif"),
#                paste0(dd_dir,"dd_map_0716_gt",gfc_threshold,"_utm_npl_20181014.tif")
# ))
# 
# ################################################################################
# ####################  CLEAN
# ################################################################################
# system(sprintf("rm %s",
#                paste0(dd_dir,"tmp*.tif")
# ))

(time_decision_tree <- Sys.time() - time_start)

