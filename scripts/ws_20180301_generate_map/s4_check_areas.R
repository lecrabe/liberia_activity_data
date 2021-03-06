pls <- readOGR(paste0(pl_dir,"priority_areas_20181014.shp"))
tif <- raster(paste0(pl_dir,"priority_areas_20181014.tif"))

pls$areas <- gArea(pls,byid = T)
head(pls)
pls@data$areas/10000
write.csv(pls@data,paste0(pl_dir,"areas_shp.csv"),row.names = F)
system(sprintf("oft-stat %s %s %s",
               paste0(pl_dir,"priority_areas_20181014.tif"),
               paste0(pl_dir,"priority_areas_20181014.tif"),
               paste0(pl_dir,"stat_priority_areas_20181014.txt")
               ))

tab <- read.table(paste0(pl_dir,"stat_priority_areas_20181014.txt"))[,1:2]
names(tab) <- c("priority","pixel")

tab$areas_ras <- tab$pixel * res(tif)[1]* res(tif)[1]
tab$areas_shp <- tapply(pls$areas,pls$id,sum)

tab$diff <- tab$areas_ras - tab$areas_shp
tab
write.csv(tab,paste0(pl_dir,"areas_comparison.csv"),row.names = F)


test <- readOGR(paste0(pl_dir,"test_qgis_areas.shp"))

test$area_r <- gArea(test,byid = T)/10000

test@data
