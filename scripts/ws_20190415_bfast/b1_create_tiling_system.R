####################################################################################################
####################################################################################################
## Tiling of an AOI (shapefile defined)
## Contact remi.dannunzio@fao.org 
## 2019/03/11
####################################################################################################
####################################################################################################

### GET COUNTRY BOUNDARIES FROM THE WWW.GADM.ORG DATASET
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
df <- read.csv(paste0(tile_dir,"Liberia_Bfast_sample_locations.csv"))
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

##########################################
################## PILOT SITES (2tiles per person)

### Call the extra sites
extra_tiles <- readOGR(paste0(tile_dir,"extra_tiles.kml"))

### Append the final list of tiles
list_tiles  <- c(extra_tiles@data[,"tileID"],ex_tile@data[,"tileID"])

### Read the list of usernames
users     <- read.csv(paste0(data_dir,"workshop_list_20190415.csv"))

### Assign each tile with a username
df        <- data.frame(cbind(list_tiles,users$username))
names(df) <- c("tileID","username")
df$tileID <- as.numeric(df$tileID)

### Create a final subset corresponding to your username
my_tiles <- tiles[tiles$tileID %in% df[df$username == username,"tileID"],]
plot(my_tiles,add=T,col="yellow")

### Export the final subset
export_name <- paste0("tiles_",username)

writeOGR(obj=my_tiles,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)



##########################################
################## ALL TILES IN COUNTRY

### Assign each tile with a username
df        <- data.frame(cbind(tiles@data[,"tileID"],users$username))
names(df) <- c("tileID","username")
df$tileID <- as.numeric(df$tileID)

### Create a final subset corresponding to your username
my_tiles <- tiles[tiles$tileID %in% df[df$username == username,"tileID"],]
plot(my_tiles,add=T,col="black")
length(my_tiles)

### Export the final subset
export_name <- paste0("national_scale_",length(my_tiles),"_tiles_",username)

writeOGR(obj=my_tiles,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)
