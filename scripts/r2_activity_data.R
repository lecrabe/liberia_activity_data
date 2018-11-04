####################################################################################################
####################################################################################################
## ACTIVITY DATA CALCULATION
## Contact yelena.finegold@fao.org
## 2018/10/29
## r2_activity_data.R
####################################################################################################
####################################################################################################
# make sure you run r1_combine_and_format.R before running this script

## read data
source('~/liberia_activity_data_2018/scripts/s0_parameters.R')
allref <- read.csv(paste0(ref_dir,'all_reference_data.csv'))
all_strata_areas <- read.csv(paste0(samp_dir,'all_strata_areas.csv'))
national_strata_areas <- read.csv(paste0(samp_dir,'national_strata_change_areas.csv'))


### need a column with strata areas for each priority area...
### also can have national level 
?merge
allref1 <- base::merge(allref,all_strata_areas, by='strata_pl')
table(allref1$strata_pl)
table(allref1$map_area)

head(allref1)

?svyby
# simple (systematic) random survey
totalarea <- sum(all_strata_areas$map_area)
srs_design <- svydesign(ids=~1, probs=NULL, strata=NULL,
                        variables=NULL, fpc=NULL, weights=NULL, data=allref1)
svymean(~change ,srs_design)

svytotal(~change ,srs_design)

# stratified random survey
strat_srs_design <- svydesign(ids=~1,  strata=~strata_pl,
                              fpc=~map_area, weights=~map_weights, data=allref1)
svyby(~change, ~strata_pl_label, strat_srs_design, svymean,keep.var = T, vartype = 'ci')
table(allref1$strata_pl_label,allref1$lu_t1_f)
allref1.sub <- allref1[allref1$change %in% 'FNF',]
table(allref1$change_label)
nrow(allref1.sub)
table(allref1.sub$strata_pl_label,allref1.sub$lu_t1_f)
head(allref1)
table(allref1$lu_t1_f)
allref1.nona <- allref1[!allref1$lu_t1_f %in% "",]
nrow(allref1.nona)
strat_srs_design.1 <- svydesign(ids=~1,  strata=~strata_pl,
                              fpc=~map_area, weights=~map_weights, data=allref1.nona)
svyby(~change, ~strata_pl_label, strat_srs_design.1, svymean,keep.var = T, vartype = 'ci')

svymean(~change ,strat_srs_design)

svytotal(~change_pl ,strat_srs_design)

# calculate area and CI per class (for random systematic sampling design)
df.results.strat_srs_design <- as.data.frame(svymean(~change_pl,strat_srs_design))
df.results.strat_srs_design$mean_m <-df.results.strat_srs_design$mean * totalarea 
df.results.strat_srs_design$CI <-df.results.strat_srs_design$SE * 1.96 
df.results.strat_srs_design$CI_m <-df.results.strat_srs_design$SE * 1.96  * totalarea
df.results.strat_srs_design$CI_percent <- df.results.strat_srs_design$CI_m/df.results.strat_srs_design$mean_m
df.results.strat_srs_design


# calculate area and CI per class (for random systematic sampling design)
df.results <- as.data.frame(svymean(~change,srs_design))
df.results$class <- substring(row.names(df.results),7 )

df.results$CI <-df.results$SE * 1.96
df.results$CI_percent <- df.results$CI/df.results$mean

df.results$area_m <-df.results$mean * totalarea
df.results$CI_m <-df.results$SE * 1.96  * totalarea
df.results


# write.csv(df.results,'oromia_area_CI.csv',row.names = F)
# ######################## plotting the data



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

