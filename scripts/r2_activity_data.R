####################################################################################################
####################################################################################################
## ACTIVITY DATA CALCULATION
## Contact yelena.finegold@fao.org
## 2018/11/07
## r2_activity_data.R
####################################################################################################
####################################################################################################
# make sure you run r1_combine_and_format.R before running this script

## read data
source('~/liberia_activity_data_2018/scripts/s0_parameters.R')
allref <- read.csv(paste0(ref_dir,'all_reference_data.csv'))
all_strata_areas <- read.csv(paste0(samp_dir,'all_strata_areas.csv'))
national_strata_areas <- read.csv(paste0(samp_dir,'national_strata_change_areas.csv'))

## combine reference data with strata area information
allref1 <- base::merge(allref,all_strata_areas, by='strata_pl')
## visual check of data
table(allref1$strata_pl_label)
head(allref1)
###########################################################
## AREA STATS
## 
## simple (systematic) random survey
totalarea <- sum(all_strata_areas$map_area)
srs_design <- svydesign(ids=~1, probs=NULL, strata=NULL,
                        variables=NULL, fpc=NULL, weights=NULL, data=allref1)
svymean(~change ,srs_design)
svytotal(~change ,srs_design)

# stratified random survey
strat_srs_design <- svydesign(ids=~1,  strata=~strata_pl,
                              fpc=~map_area, weights=~map_weights, data=allref1)
svyby(~change, ~strata_pl_label, strat_srs_design, svymean,keep.var = T, vartype = 'ci')

svymean(~change ,strat_srs_design)
svytotal(~change_pl ,strat_srs_design)
table(allref1$change_pl)
# calculate area and CI per class (for STRATIFIED random sampling design)
df.results.strat_srs_design <- as.data.frame(svymean(~change_pl,strat_srs_design))
df.results.strat_srs_design$class <- substring(row.names(df.results.strat_srs_design),10 )
df.results.strat_srs_design$area_m <-round(df.results.strat_srs_design$mean * totalarea)
df.results.strat_srs_design$CI_95 <- df.results.strat_srs_design$SE * 1.96
df.results.strat_srs_design$CI_m <-round(df.results.strat_srs_design$SE * 1.96  * totalarea)
df.results.strat_srs_design$CI_percent <- round(df.results.strat_srs_design$CI_m/df.results.strat_srs_design$area_m,digits = 3)
df.results.strat_srs_design$prioritylandscape <- str_sub(df.results.strat_srs_design$class,-1,-1 )
df.results.strat_srs_design$change <- str_sub(df.results.strat_srs_design$class,1,-2 )
as.data.frame(svytotal(~change_pl,strat_srs_design))
samplesize <- table(allref1$change_pl)
melted_samplesize <- melt(samplesize)
names(melted_samplesize) <- c('class','samplesize')
df.results.strat_srs_design <- merge(df.results.strat_srs_design,melted_samplesize,by='class')
df.results.strat_srs_design


# calculate area and CI per class (for SIMPLE random sampling design)
df.results <- as.data.frame(svymean(~change,srs_design))
df.results$class <- substring(row.names(df.results),7 )

df.results$CI <-df.results$SE * 1.96
df.results$CI_percent <- df.results$CI/df.results$mean

df.results$area_m <-df.results$mean * totalarea
df.results$CI_m <-df.results$SE * 1.96  * totalarea
df.results

write.csv(df.results.strat_srs_design,paste0(ana_dir,'activity_data_by_priorityarea.csv'),row.names = F)
# write.csv(df.results,'oromia_area_CI.csv',row.names = F)
# ######################## plotting the data
##################################################################################################
################ Create gg_plot
##################################################################################################
avg.plot <- 
  ggplot(data = df.results.strat_srs_design,
         aes(
           x = change,
           y = area_m,
           fill = factor(prioritylandscape)
         ))

##################################################################################################
################ Display plots with parameters
##################################################################################################
limits_strat <-
  aes(
    ymax = df.results.strat_srs_design$area_m + df.results.strat_srs_design$CI_m,
    ymin = df.results.strat_srs_design$area_m - df.results.strat_srs_design$CI_m
  )
avg.plot +
  geom_bar(stat = "identity",
           position = position_dodge(0.9)) +
  geom_errorbar(limits_strat,
                position = position_dodge(0.9),
                width = 0.25) +
  labs(x = "Class", y = "Area estimate") +
  ggtitle("Area estimates from stratified random sampling design in priority \n and nonpriority areas") +
  scale_fill_manual(name = "Priority landscape",
                    values = c("#BBBBBB", "#333333", "#999999")) +
  theme_bw()

## save chart
png(paste0(plot_dir,'activity_data.png'))
avg.plot +
  geom_bar(stat = "identity",
           position = position_dodge(0.9)) +
  geom_errorbar(limits_strat,
                position = position_dodge(0.9),
                width = 0.25) +
  labs(x = "Class", y = "Area estimate") +
  ggtitle("Area estimates from stratified random sampling design in priority \n and nonpriority areas") +
  scale_fill_manual(name = "Priority landscape",
                    values = c("#BBBBBB", "#333333", "#999999")) +
  theme_bw()
dev.off()


######################################################################################
## CALCULATIONS AT NATIONAL SCALE, USING PRIORITY LANDSCAPES
######################################################################################
allref2 <- base::merge(allref,national_strata_areas,by.x="map_class_label", by.y='map_edited_class')
national_strat_srs_design <- svydesign(ids=~1,  strata=~strata_pl,
                                       fpc=~map_area, weights=~map_weights, data=allref2)

svymean(~change ,national_strat_srs_design)
table(allref2$change)
# calculate area and CI per class (for STRATIFIED random sampling design)
df.results.national_strat_srs_design <- as.data.frame(svymean(~change,national_strat_srs_design))
df.results.national_strat_srs_design$class <- substring(row.names(df.results.national_strat_srs_design),7 )
df.results.national_strat_srs_design$area_m <-round(df.results.national_strat_srs_design$mean * totalarea)
# df.results.national_strat_srs_design$CI_95 <- df.results.national_strat_srs_design$SE * 1.96
df.results.national_strat_srs_design$CI_m <-round(df.results.national_strat_srs_design$SE * 1.96  * totalarea)
df.results.national_strat_srs_design$CI_percent <- round(df.results.national_strat_srs_design$CI_m/df.results.national_strat_srs_design$area_m,digits = 3)
df.results.national_strat_srs_design$strata <- 'none'
df.results.national_strat_srs_design <-df.results.national_strat_srs_design[3:ncol(df.results.national_strat_srs_design)]

nat_ad <-plyr::ddply(df.results.strat_srs_design, .(change), plyr::summarize,
                     area_m=sum(area_m), CI_m=sum(CI_m)
                     # ,
                     # samplesize=sum(samplesize)
)
names(nat_ad)[1] <- 'class'
nat_ad$CI_percent <- round(nat_ad$CI_m/nat_ad$area_m,digits = 3)
nat_ad$strata <- 'PL'
nat_ad_all <- rbind(df.results.national_strat_srs_design,nat_ad)

##################################################################################################
################ Create gg_plot
##################################################################################################
avg.plot <- 
  ggplot(data = nat_ad_all,
         aes(
           x = class,
           y = area_m,
           fill = factor(strata)
         ))

##################################################################################################
################ Display plots with parameters
##################################################################################################
limits_strat <-
  aes(
    ymax = nat_ad_all$area_m + nat_ad_all$CI_m,
    ymin = nat_ad_all$area_m - nat_ad_all$CI_m
  )
avg.plot +
  geom_bar(stat = "identity",
           position = position_dodge(0.9)) +
  geom_errorbar(limits_strat,
                position = position_dodge(0.9),
                width = 0.25) +
  labs(x = "Class", y = "Area estimate") +
  ggtitle("Comparing nationally aggregated activity data") +
  scale_fill_manual(name = "Stratification",
                    values = c("#BBBBBB", "#333333", "#999999")) +
  theme_bw()
## save chart
png(paste0(plot_dir,'compare_national_AD.png'))
avg.plot +
  geom_bar(stat = "identity",
           position = position_dodge(0.9)) +
  geom_errorbar(limits_strat,
                position = position_dodge(0.9),
                width = 0.25) +
  labs(x = "Class", y = "Area estimate") +
  ggtitle("Comparing nationally aggregated activity data") +
  scale_fill_manual(name = "Stratification",
                    values = c("#BBBBBB", "#333333", "#999999")) +
  theme_bw()
dev.off()

#########################################################################
## ideas for further data analysis
table(allref$map_class)
table(allref$change)
table(allref$fire)
table(allref$change,allref$lu_t1_f)
table(allref$change,allref$lu_t2_f)
table(allref$change,allref$lu_t2_nf)
table(allref$change,allref$disturbance_type.1.)
table(allref$change,allref$disturbance_type.2.)
table(allref$change,allref$lu_croptype)
table(allref$change,allref$shifting_yrs1)
table(allref$change,allref$shift_cult_id)
table(allref$change,allref$year_change)
table(allref$change,allref$map_class_label)
table(allref$change,allref$region)
table(allref$change,allref$shifting_yrs)

