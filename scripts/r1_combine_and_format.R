####################################################################################################
####################################################################################################
## CLEAN REFERENCE DATA AND PREPARE FOR ANALYSIS 
## Contact yelena.finegold@fao.org
## 2018/10/29
## r1_combine_and_format.R
####################################################################################################
####################################################################################################

## make sure you run the r0_download_data.R script to download the data before running this script. 
## You only need to run the r0_download_data.R script once

## read data
source('~/liberia_activity_data_2018/scripts/s0_parameters.R')
originalsampledata <- paste0(samp_dir,'all_sample_points.csv')
priorityareasfile <- paste0(pl_dir,'priority_areas_20181014.tif')

## read data collected by operators from Collect Earth
point_file <- list.files(coll_dir, glob2rx("*.csv"), full.names = T)
myfiles <- lapply(point_file, read.csv)
rd <- do.call(rbind, myfiles)
## read the sample data without iterpretations
samp <- read.csv(originalsampledata)
samp1 <- samp[c(1,12:14)]

## reclassify agricultural commidities to nonforest
rd$map_class[rd$map_class %in% 11] <- 1
## create a map column with matching labels with reference classes
rd$map_class_label[rd$map_class %in% 1] <- 'NFNF'
rd$map_class_label[rd$map_class %in% 2] <- 'FF'
rd$map_class_label[rd$map_class %in% 3] <- 'FNF'
rd$map_class_label[rd$map_class %in% 4] <- 'Fd'
table(rd$map_class_label,rd$change)

## merge data from orginal sample data and collected database to get information about duplicated plots
mg <- merge(rd,samp1, by='id', all.x=T)
## create a nonunique ID to find duplicated samples
mg$id_nonunique <- str_replace_all(mg$id_unique,"dup","")
nonunique <- mg[mg$db_double %in% 'TRUE',]

## write duplicates to a CSV
write.csv(nonunique,paste0(ref_dir,'duplicate_samples_liberia.csv'),row.names = FALSE)
## look at agreement and disagreement between duplicate samples
dup <- dcast(nonunique[,c('id_nonunique','change')], id_nonunique  ~ change)
dup.match <- dup %>% 
  filter(Fd == 2 | FF == 2 | FNF == 2 | NFNF == 2)
dup.nonmatch <- dup %>% 
  filter(Fd == 1 | FF == 1 | FNF == 1 | NFNF == 1)
mg.nonmatch <- mg[mg$id_nonunique %in% dup.nonmatch$id_nonunique,]
mg.nonmatch.nodup <- mg.nonmatch[!duplicated(mg.nonmatch$id_nonunique),]
samp_recheck <- samp[samp$id %in% mg.nonmatch.nodup$id,]
write.csv(samp_recheck,paste0(ref_dir,'recheck_QA_samples.csv'),row.names = FALSE)

table(mg.nonmatch$id_nonunique)
table(mg.nonmatch$conf_change)
op <- dcast(mg.nonmatch[,c('id_nonunique','operator')], id_nonunique  ~ operator  ,value.var = 'operator',fill=0)
mg.match <- mg[mg$id_nonunique %in% dup.match$id_nonunique,]
test <- dcast(mg.nonmatch[,c('id_nonunique','lu_t2_nf','lu_t1_f','change')], id_nonunique  ~ lu_t1_f + lu_t2_nf ,value.var = 'change',fill=0)

write.csv(op,paste0(ref_dir,'operator_nonmatch.csv'),row.names = F)
## check the data
head(dup)
table(dup$Fd)
table(dup$FF)
table(dup$FNF)
table(dup$NFNF)

# eliminate duplicate plots, these are not yet filtered to find the majority classification
allref <- mg[!duplicated(mg$id_nonunique),]
# read priority area raster file
pa <- raster(priorityareasfile)
# convert dataframe into spatial points data frame 
coord <- coordinates(allref[,c('location_x','location_y')])
coord.sp <- SpatialPoints(coord)
coord.df <- as.data.frame(coord)
coord.spdf <- SpatialPointsDataFrame(coord.sp, coord.df,proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
proj4string(coord.spdf) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
#match the coordinate systems for the sample points and the boundaries
coord.spdf.UTM <- spTransform(coord.spdf, crs(pa))
allref$priorityarea <- raster::extract(pa, coord.spdf)
table(allref$priorityarea,allref$samp)
allref[is.na(allref)] <- ""


########################################################### 
## format the area files

# read area by strata CSV, this includes area by priority/nonpriority areas and change map stratification
all_strata_areas <- read.csv(paste0(samp_dir,'all_strata_areas.csv'))
# create a column with a unique identifier for PL * strata
all_strata_areas$strata_pl <- paste0(all_strata_areas$map_code,all_strata_areas$priority_area)
all_strata_areas$strata_pl_label <- paste(all_strata_areas$map_edited_class,all_strata_areas$priority_area_label,sep = '_')
# calculate strata weights
all_strata_areas$map_weights<-all_strata_areas$map_area/sum(unique(all_strata_areas$map_area))

##############################
# create an strata area dataframe for national level calculations
national_strata_areas <-aggregate(all_strata_areas$map_area, by=list(Category=all_strata_areas$map_edited_class), FUN=sum)
names(national_strata_areas) <- c('map_edited_class','map_area')

# calculate strata weights using only the change map --- at the national scale without priority landscapes... 
national_strata_areas$map_weights<-national_strata_areas$map_area/sum(unique(national_strata_areas$map_area))
write.csv(national_strata_areas,paste0(samp_dir,'national_strata_change_areas.csv'),row.names = F)

allref$strata_pl <- paste0(allref$map_class,allref$priorityarea)

# create a column with complete information for time 1 land use
allref$lu_t1 <- allref$lu_t1_f
# stable land use is assumed to remain the same in t1 and t2
allref$lu_t1[allref$change %in% 'FF'] <- allref$lu_t2_f[allref$change %in% 'FF'] 
allref$lu_t1[allref$change %in% 'NFNF'] <- allref$lu_t2_nf[allref$change %in% 'NFNF'] 
# create a column with complete information for time 2 land use
allref <- unite(allref, "lu_t2", c("lu_t2_f","lu_t2_nf"), sep="", remove = F)
# assume all degraded forest is now secondary
allref$lu_t2[allref$change %in% 'Fd'] <- 'second'

allref$change_pl <- paste0(allref$change,allref$priorityarea)

# create 3 dataframe for the 3 priority/nonpriority areas
npl <- allref[allref$priorityarea %in% 0,]
pl1 <- allref[allref$priorityarea %in% 1,]
pl2 <- allref[allref$priorityarea %in% 2,]

# write the dataframes to a CSV

write.csv(allref,paste0(ref_dir,'all_reference_data.csv'),row.names = FALSE)
write.csv(npl,paste0(ref_dir,'npl_reference_data.csv'),row.names = FALSE)
write.csv(pl1,paste0(ref_dir,'pl1_reference_data.csv'),row.names = FALSE)
write.csv(pl2,paste0(ref_dir,'pl2_reference_data.csv'),row.names = FALSE)

