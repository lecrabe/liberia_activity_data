####################################################################################################
####################################################################################################
## CLEAN REFERENCE DATA AND PREPARE FOR ANALYSIS 
## Contact yelena.finegold@fao.org
## 2018/11/07
## r1_combine_and_format.R
####################################################################################################
####################################################################################################

## make sure you run the r0_download_data.R script to download the data before running this script. 
## You only need to run the r0_download_data.R script once

## read data
source('~/liberia_activity_data/scripts/s0_parameters.R')
originalsampledata <- paste0(samp_dir,'all_sample_points.csv')
priorityareasfile <- paste0(pl_dir,'priority_areas_20181014.tif')
### READ RECHECKED DATA ## AMENDED 07/11/2018
recheckedfile <-  paste0(ref_dir,'group_rechecked_duplicates_20181107.csv')

## read data collected by operators from Collect Earth
point_file <- list.files(coll_dir, glob2rx("*.csv"), full.names = T)
myfiles <- lapply(point_file, read.csv)
rd <- do.call(rbind, myfiles)
rechecked <- read.csv(recheckedfile)
rd <- rbind(rd,rechecked)

## read the sample data without iterpretations
sample_data <- read.csv(originalsampledata)
sample_data1 <- sample_data[c(1,12:14)]

## reclassify agricultural commidities to nonforest
rd$map_class[rd$map_class %in% 11] <- 1
## create a map column with matching labels with reference classes
rd$map_class_label[rd$map_class %in% 1] <- 'NFNF'
rd$map_class_label[rd$map_class %in% 2] <- 'FF'
rd$map_class_label[rd$map_class %in% 3] <- 'FNF'
rd$map_class_label[rd$map_class %in% 4] <- 'Fd'
## check the table
table(rd$map_class_label,rd$change)

#####################################
## seperate out duplicates
## merge data from orginal sample data and collected database to get information about duplicated plots
df <- merge(rd,sample_data1, by='id', all.x=T)
## create a nonunique ID to find duplicated samples
df$id_nonunique <- str_replace_all(df$id_unique,"dup","")
nonunique <- df[df$db_double %in% 'TRUE',]
rechecked <- df[df$plot_file %in% "recheck_QA_samples.csv",]



## write duplicates to a CSV
write.csv(nonunique,paste0(ref_dir,'duplicate_samples_liberia.csv'),row.names = FALSE)
## look at agreement and disagreement between duplicate samples
dup <- dcast(nonunique[,c('id_nonunique','change')], id_nonunique  ~ change)
dup.match <- dup %>% 
  filter(Fd == 2 | FF == 2 | FNF == 2 | NFNF == 2)
dup.nonmatch <- dup %>% 
  filter(Fd == 1 | FF == 1 | FNF == 1 | NFNF == 1)
df.nonmatch <- df[df$id_nonunique %in% dup.nonmatch$id_nonunique,]
df.nonmatch.nodup <- df.nonmatch[!duplicated(df.nonmatch$id_nonunique),]
## visualize the disagreements in tables
## make sure each nonunique ID is repeated. it should have a value of 2 or greater 
head(table(df.nonmatch$id_nonunique))
## check the low/high confidence classifications of nonmatching duplicates
table(df.nonmatch$conf_change)
## eliminate duplicate plots, these are not yet filtered to find the majority classification
allref <- df[!duplicated(df$id_nonunique),]
allref <- allref[!allref$id %in% df.nonmatch$id,]
allref <- rbind(allref,rechecked)

table(df$id[df$plot_file %in% 'recheck_QA_samples.csv'])
table(df.nonmatch$id)
## assess which operators have checked which nonmatching duplicates
## this can be used to reassign the samples to another operator
operator <- dcast(df.nonmatch[,c('id_nonunique','operator')], id_nonunique  ~ operator  ,value.var = 'operator',fill=0)
# this is the full database of all the matching duplicated samples
df.match <- df[df$id_nonunique %in% dup.match$id_nonunique,]
## further exploring the data, show the classification of the land use at time 1 for forest and time 2 for nonforest by activity data classification
table.df.nonmatch <- dcast(df.nonmatch[,c('id_nonunique','lu_t2_nf','lu_t1_f','change')], id_nonunique  ~ lu_t1_f + lu_t2_nf ,value.var = 'change',fill=0)
table.df.nonmatch
## write the operator of nonmatching duplicates to CSV file
write.csv(operator,paste0(ref_dir,'operator_nonmatch.csv'),row.names = F)

###########################
## CREATE INPUT FOR COLLECT EARTH
## THIS IS THE FILE TO RECHECK OF UNMATCHING DUPLICATES
samp_recheck <- sample_data[sample_data$id %in% df.nonmatch.nodup$id,]
## the file name is "~/liberia_activity_data_2018/data/reference_data/recheck_QA_samples.csv"
write.csv(samp_recheck,paste0(ref_dir,'recheck_QA_samples.csv'),row.names = FALSE)

## LOW CONFINDENCE CHANGE CLASS
table(df$conf_change)
df.low.confid <- df[df$conf_change %in% 'low',] 
df.low.confid <- df.low.confid[!df.low.confid$id %in% df.nonmatch.nodup$id,]
samp_recheck.low.confid <- sample_data[sample_data$id %in% df.low.confid$id,]
write.csv(samp_recheck.low.confid,paste0(ref_dir,'recheck_QA_samples_low_confidence.csv'),row.names = FALSE)

## check the data
head(dup)
nrow(dup[dup$Fd %in%1,])
table(dup$Fd)
table(dup$FF)
table(dup$FNF)
table(dup$NFNF)

# Start writing to an output file
sink(paste0(ana_dir,'analysis-output.txt'))
## some information that could be useful for reporting
cat(paste0('To check interpreter error ', nrow(dup), ' samples, ', 
           sprintf("%.0f%%", 100 * nrow(dup)/nrow(df[!duplicated(df$id_nonunique),])),
           ' of the total samples were duplicated. \n'))
cat(paste0('The activity data had a consistent classification for ',nrow(dup.match), 
           ' of the ', nrow(dup), ' (',sprintf("%.0f%%", 100 * nrow(dup.match)/nrow(dup)),') duplicated samples. \n'))
cat(paste0('The activity data had an inconsistent classification for ',nrow(dup.nonmatch), 
           ' of the ', nrow(dup), ' (',sprintf("%.0f%%", 100 * nrow(dup.nonmatch)/nrow(dup)),') duplicated samples.\n'))
cat(paste0('From the nonmatching duplicated samples, ',nrow(dup[dup$Fd %in% c(1,2),]), 
           ' samples were classified as degradation by at least one interpreter. ', 
           nrow(dup[dup$Fd %in% c(1),]), ' were nonmatching and ', nrow(dup[dup$Fd %in% c(2),]),
           ' were matching.\n'))
cat(paste0('From the nonmatching duplicated samples, ',nrow(dup[dup$FF %in% c(1,2),]), 
           ' samples were classified as stable forest by at least one interpreter. ', 
           nrow(dup[dup$FF %in% c(1),]), ' were nonmatching and ', nrow(dup[dup$FF %in% c(2),]),
           ' were matching.\n'))
cat(paste0('From the nonmatching duplicated samples, ',nrow(dup[dup$NFNF %in% c(1,2),]), 
           ' samples were classified as stable non-forest by at least one interpreter. ', 
           nrow(dup[dup$NFNF %in% c(1),]), ' were nonmatching and ', nrow(dup[dup$NFNF %in% c(2),]),
           ' were matching.\n'))
cat(paste0('From the nonmatching duplicated samples, ',nrow(dup[dup$FNF %in% c(1,2),]), 
           ' samples were classified as deforestation by at least one interpreter. ', 
           nrow(dup[dup$FNF %in% c(1),]), ' were nonmatching and ', nrow(dup[dup$FNF %in% c(2),]),
           ' were matching.\n'))

# Stop writing to the file
sink()


## read priority area raster file
pa <- raster(priorityareasfile)
# pa.shp <- readOGR(paste0(pl_dir,"priority_areas_20181014.shp"))
## convert dataframe into spatial points data frame 
coord <- coordinates(allref[,c('location_x','location_y')])
coord.sp <- SpatialPoints(coord)
coord.df <- as.data.frame(coord)
coord.spdf <- SpatialPointsDataFrame(coord.sp, coord.df,proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
proj4string(coord.spdf) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
##match the coordinate systems for the sample points and the boundaries
coord.spdf.UTM <- spTransform(coord.spdf, crs(pa))
allref$priorityarea <- raster::extract(pa, coord.spdf.UTM)
# pa.shp.coord <- over(coord.spdf.UTM, pa.shp)
# allref$priorityarea <- pa.shp.coord[,3]
# allref$priorityarea[is.na(allref$priorityarea)] <- 0
table(allref$priorityarea,allref$samp)
## format dataframe to not have NA values
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
write.csv(all_strata_areas,paste0(samp_dir,'all_strata_areas.csv'),row.names = F)

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

##############################################################
## FINAL COMBINED DATABASES OF ASSESSED REFERENCE DATA
## THESE ARE INPUT INTO THE SAEA APPLICATION (STRATIFIED AREA ESTIMATOR ANALYSIS)
# write the dataframes to a CSV
write.csv(allref,paste0(ref_dir,'all_reference_data.csv'),row.names = FALSE)
write.csv(npl,paste0(ref_dir,'npl_reference_data.csv'),row.names = FALSE)
write.csv(pl1,paste0(ref_dir,'pl1_reference_data.csv'),row.names = FALSE)
write.csv(pl2,paste0(ref_dir,'pl2_reference_data.csv'),row.names = FALSE)

