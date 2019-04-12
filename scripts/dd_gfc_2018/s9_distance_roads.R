####################################################################################################
## Analyze relate DD maps to distance to roads
## remi.dannunzio@fao.org 
## 2018/11/14
## LIBERIA
####################################################################################################
####################################################################################################

##################### Roads downloaded from https://geonode.wfp.org/layers/ogcserver.gis.wfp.org%3Ageonode%3Albr_trs_roads_osm
download.file("http://ogcserver.gis.wfp.org/geoserver/ows?format_options=charset:UTF-8&typename=geonode:lbr_trs_roads_osm&outputFormat=SHAPE-ZIP&version=1.0.0&service=WFS&request=GetFeature",
              destfile = paste0(rdsdir,"roads.zip"))

##################### Unzip archive
system(sprintf("unzip -o %s  -d %s ",
               paste0(rdsdir,"roads.zip"),
               rdsdir
               ))

##################### Reproject in UTM
system(sprintf("ogr2ogr -t_srs \"%s\" %s %s",
               "EPSG:32629",
               paste0(rdsdir,"lbr_trs_roads_osm_utm.shp"),
               paste0(rdsdir,"lbr_trs_roads_osm.shp")
))

##################### Rasterize at dd_map resolution
system(sprintf("python %s  -v %s -i %s -o %s -a %s",
               paste0(scriptdir,"oft-rasterize_attr.py"),
               paste0(rdsdir,"lbr_trs_roads_osm_utm.shp"),
               paste0(dd_dir,"dd_map_0716_gt30_utm_20181014.tif"),
               paste0(rdsdir,"lbr_trs_roads_osm_30m.tif"),
               "fclass"
))

##################### Calculate distance to road
system(sprintf("gdal_proximity.py -co COMPRESS=LZW  -distunits GEO -ot Int16 %s %s",
               paste0(rdsdir,"lbr_trs_roads_osm_30m.tif"),
               paste0(rdsdir,"dist_roads.tif")
))


#################### Discretize distance to main roads
system(sprintf("gdal_calc.py -A %s --type=Byte  --overwrite --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(rdsdir,"dist_roads.tif"),
               paste0(rdsdir,"dist_roads_km.tif"),
               "A/1000"
))

##################### Clip dd maps to real extent
system(sprintf("gdal_translate -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
               212781.792683,
               951995.137653,
               470570.837593,
               709301.847625,
               paste0(dd_dir,"dd_map_0716_gt30_utm_pl1_20181014.tif"),
               paste0(dd_dir,"dd_pl1.tif")
               ))

system(sprintf("gdal_translate -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
               435734.480173,
               730203.662077,
               690039.889342,
               507250.974587,
               paste0(dd_dir,"dd_map_0716_gt30_utm_pl2_20181014.tif"),
               paste0(dd_dir,"dd_pl2.tif")
))

system(sprintf("gdal_translate -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
               273164.812212,
               879999.998984,
               700490.796568,
               470092.193338,
               paste0(dd_dir,"dd_map_0716_gt30_utm_npl_20181014.tif"),
               paste0(dd_dir,"dd_npl.tif")
))


#################### ALIGN PRODUCTS PL1
input  <- paste0(rdsdir,"dist_roads_km.tif")

mask   <- paste0(dd_dir,"dd_pl1.tif")
proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]
ouput  <- paste0(rdsdir,"dist_roads_pl1.tif")

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

#################### ALIGN PRODUCTS  PL2
mask   <- paste0(dd_dir,"dd_pl2.tif")
proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]
ouput  <- paste0(rdsdir,"dist_roads_pl2.tif")

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

#################### ALIGN PRODUCTS  NPL
mask   <- paste0(dd_dir,"dd_npl.tif")
proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]
ouput  <- paste0(rdsdir,"dist_roads_npl.tif")

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

#################### Make distance map for illustration
system(sprintf("gdal_calc.py -A %s -B %s --type=Byte  --overwrite --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(rdsdir,"dist_roads_npl.tif"),
               paste0(dd_dir,"dd_npl.tif"),
               paste0(rdsdir,"map_dist_roads_npl.tif"),
               "(B>0)*A"
))

system(sprintf("gdal_calc.py -A %s -B %s --type=Byte  --overwrite --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(rdsdir,"dist_roads_pl1.tif"),
               paste0(dd_dir,"dd_pl1.tif"),
               paste0(rdsdir,"map_dist_roads_pl1.tif"),
               "(B>0)*A"
))

system(sprintf("gdal_calc.py -A %s -B %s --type=Byte  --overwrite --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(rdsdir,"dist_roads_pl2.tif"),
               paste0(dd_dir,"dd_pl2.tif"),
               paste0(rdsdir,"map_dist_roads_pl2.tif"),
               "(B>0)*A"
))

#################### ZONAL Priority 1
system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
               paste0(dd_dir,"dd_pl1.tif"),
               paste0(dd_dir,"stats_dd_pl1.txt"),
               paste0(rdsdir,"dist_roads_pl1.tif"),
               12
))

#################### ZONAL Priority 2
system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
               paste0(dd_dir,"dd_pl2.tif"),
               paste0(dd_dir,"stats_dd_pl2.txt"),
               paste0(rdsdir,"dist_roads_pl2.tif"),
               12
))

#################### ZONAL Non Priority
system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
               paste0(dd_dir,"dd_npl.tif"),
               paste0(dd_dir,"stats_dd_npl.txt"),
               paste0(rdsdir,"dist_roads_npl.tif"),
               12
))

#df <- read.table(paste0(dd_dir,"stats_dd_pl1.txt"))
#df <- read.table(paste0(dd_dir,"stats_dd_pl2.txt"))
df <- read.table(paste0(dd_dir,"stats_dd_npl.txt"))

df <- df[,colSums(df) !=0]
names(df) <- c("distance_km","total","no_data","non-forest","forest","deforestation","degradation","agriculture","tof")

df$total_data <- df$total-df$no_data

df$cum_def <- cumsum(df$deforestation)
df$cum_deg <- cumsum(df$degradation)

df$pct_def <- df$cum_def/df[nrow(df),]$cum_def
df$pct_deg <- df$cum_deg/df[nrow(df),]$cum_deg

plot(df$distance_km,df$pct_def,xlab="Distance from road (km)",ylab="Deforestation (% of total)")
plot(df$distance_km,df$pct_deg,xlab="Distance from road (km)",ylab="Degradation (% of total)")

#write.csv(df,paste0(rdsdir,"stats_dd_pl1.csv"),row.names = F)
#write.csv(df,paste0(rdsdir,"stats_dd_pl2.csv"),row.names = F)
write.csv(df,paste0(rdsdir,"stats_dd_npl.csv"),row.names = F)
