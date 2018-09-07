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

#################### CREATE GFC TREE COVER MAP IN 2004 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_2004_gt",gfc_threshold,".tif"),
               paste0("(A>",gfc_threshold,")*((B==0)+(B>3))")
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

#################### COMBINATION INTO DD MAP
system(sprintf("gdal_calc.py -A %s -B %s -C %s -D %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2004_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0414_gt",gfc_threshold,"_inf.tif"),
               paste0(gadm_dir,"gadm_",countrycode,"_l1.tif"),
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,".tif"),
               paste0("(D>0)*((A==0)*1+(A>0)*((B==0)*(C==0)*2+(B>0)*3+(C>0)*4))")
))

#################### CREATE A COLOR TABLE FOR THE OUTPUT MAP
my_classes <- c(0,1,2,3,4)
my_colors  <- col2rgb(c("black","grey","darkgreen","red","orange"))

pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]))

write.table(pct,paste0(dd_dir,"color_table.txt"),row.names = F,col.names = F,quote = F)




################################################################################
#################### Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(dd_dir,"color_table.txt"),
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,"pct.tif")
))


################################################################################
#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_0414_gt",gfc_threshold,"pct.tif"),
               paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_option1.tif")
))

#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(dd_dir,"tmp*.tif")
))

(time_decision_tree <- Sys.time() - time_start)







#################### CREATE GFC TREE COVER MAP in 2000 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               gfc_tc,
               paste0("(A>",gfc_threshold,")*A")
))

#################### CREATE GFC TREE COVER LOSS MAP AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               gfc_ly,
               paste0("(A>",gfc_threshold,")*B")
))

#################### CREATE GFC FOREST MASK IN 2000 AT THRESHOLD (0 no forest, 1 forest)
system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               gfc_tc,
               gfc_00,
               "A>0"
))

#################### CREATE GFC FOREST MASK IN 2016 AT THRESHOLD (0 no forest, 1 forest)
system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               gfc_tc,
               gfc_ly,
               gfc_gn,
               gfc_16,
               "(C==1)*1+(C==0)*((B==0)*(A>0)*1+(B==0)*(A==0)*0+(B>0)*0)"
))

#################### CREATE MAP 2000-2014 AT THRESHOLD (0 no data, 1 forest, 2 non-forest, 3 loss, 4 gain)
system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               gfc_tc,
               gfc_ly,
               gfc_gn,
               gfc_mp,
               "(C==1)*4+(C==0)*((B==0)*(A>0)*1+(B==0)*(A==0)*2+(B>0)*(B<15)*3+(B>=15)*1)"
))

#############################################################
### CROP TO COUNTRY BOUNDARIES
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
               gfc_mp,
               gfc_mp_crop,
               "OBJECTID"
))

#############################################################
### CROP TO ONE STATE BOUNDARIES
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(gadm_dir,"work_aoi_sub.shp"),
               gfc_mp_crop,
               gfc_mp_sub,
               "OBJECTID"
))

####################################################################################
####### CLIP ESA MAP TO COUNTRY BOUNDING BOX
####################################################################################
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
               floor(bb@xmin),
               ceiling(bb@ymax),
               ceiling(bb@xmax),
               floor(bb@ymin),
               paste0(esastore_dir,"ESACCI-LC-L4-LC10-Map-20m-P1Y-2016-v1.0.tif"),
               paste0(esa_dir,"esa.tif")
))


#############################################################
### CROP TO COUNTRY BOUNDARIES
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
               paste0(esa_dir,"esa.tif"),
               paste0(esa_dir,"esa_crop.tif"),
               "OBJECTID"
))

#############################################################
### CROP TO ONE STATE BOUNDARIES
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(gadm_dir,"work_aoi_sub.shp"),
               paste0(esa_dir,"esa_crop.tif"),
               paste0(esa_dir,"esa_sub_crop.tif"),
               "OBJECTID"
))

#############################################################
### CREATE A FOREST MASK FOR MSPA ANALYSIS
system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(esa_dir,"esa_crop.tif"),
               paste0(esa_dir,"esa_mspa.tif"),
               paste0("(A==1)*2+((A==0)+(A==200))*0+((A>1)*(A<200))*1")
))


time_products_global <- Sys.time() - time_start


