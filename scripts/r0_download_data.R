####################################################################################################
####################################################################################################
## DOWNLOAD DATA
## Contact yelena.finegold@fao.org
## 2018/10/29
## r0_download_data.R
####################################################################################################
####################################################################################################

## user parameters to get directory names
source('~/liberia_activity_data_2018/scripts/s0_parameters.R')
## download data 
## download the reference data that was collected by the 5 operators 
system(sprintf("wget -O %s  https://www.dropbox.com/s/iud6iatbhdcn457/all_sample_points.csv", paste0(samp_dir,'all_sample_points.csv')))
system(sprintf("wget -O %s  https://www.dropbox.com/s/f9m4ugfskhobc74/collected_samples.zip", paste0(ref_dir,'collected_samples.zip')))
system(sprintf("unzip -o %s  -d %s ",paste0(ref_dir,'collected_samples.zip'),paste0(ref_dir,'collected_samples/')))
system(sprintf("rm %s",paste0(ref_dir,'collected_samples.zip')))

## download the strata areas by priority landscape
system(sprintf("wget -O %s  https://www.dropbox.com/s/mh9i8jyp76nteru/all_strata_areas.csv", paste0(samp_dir,'all_strata_areas.csv')))
