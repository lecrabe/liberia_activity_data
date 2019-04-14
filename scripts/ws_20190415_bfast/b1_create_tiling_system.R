####################################################################################################
####################################################################################################
## Tiling of an AOI (shapefile defined)
## Contact remi.dannunzio@fao.org 
## 2019/03/11
####################################################################################################
####################################################################################################

### Select a vector from location of another vector
aoi   <- getData('GADM',
                 path=gadm_dir, 
                 country= countrycode, 
                 level=0)

(bb    <- extent(aoi))

### What grid size do we need ? 
grid_size <- 20000          ## in meters

### GENERATE A GRID
sqr_df <- generate_grid(aoi,grid_size/111320)

nrow(sqr_df)

### Select a vector from location of another vector
sqr_df_selected <- sqr_df[aoi,]
nrow(sqr_df_selected)

### Give the output a decent name, with unique ID
names(sqr_df_selected@data) <- "tileID" 
sqr_df_selected@data$tileID <- row(sqr_df_selected@data)[,1]

### Reproject in LAT LON
tiles   <- spTransform(sqr_df_selected,CRS("+init=epsg:4326"))
aoi_geo <- spTransform(aoi,CRS("+init=epsg:4326"))


### Plot the results
plot(tiles)
plot(aoi_geo,add=T,border="blue")


### Call the pilot sites file
df <- read.csv(paste0(data_dir,"Liberia_Bfast_sample_locations.csv"))
spdf <- SpatialPointsDataFrame(df[,c("plot_location_x","plot_location_y")],
                               data = df,
                               proj4string = CRS('+init=epsg:32629')
                                )

pts <- spTransform(spdf,CRS('+init=epsg:4326'))
plot(pts,add=T)

### Export pilot tiles as KML
x <- "pilot"
ex_tile <- tiles[pts,]
plot(ex_tile,add=T,col="red")

export_name <- paste0("ex_",x,"_tiles")
writeOGR(obj=   ex_tile,
         dsn=   paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)

### Select and Export one Tile as KML 
one_tile <- tiles[tiles$tileID == 205,]
plot(one_tile,add=T,col="green")

export_name <- paste0("one_tile")
writeOGR(obj=   one_tile,
         dsn=   paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)

##############################################################################
### CONVERT TO A FUSION TABLE
### For example:    
##############################################################################

### Export ALL TILES as KML
export_name <- paste0("tiling_system_all")

writeOGR(obj=sqr_df_selected,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)


##############################################################################
### CONVERT TO A FUSION TABLE
### For example:    
##############################################################################
