####################################################################################################
####################################################################################################
## DRIVERS OF DEFORESTATION ANALYSIS
## Contact yelena.finegold@fao.org
## 2018/10/29
## r3_drivers_analysis.R
####################################################################################################
####################################################################################################

## read data
source('~/liberia_activity_data_2018/scripts/s0_parameters.R')
allref <- read.csv(paste0(ref_dir,'all_reference_data.csv'))

# quick stats on degraded forest
# original land use of degraded forest...
tab_degraded <- table(allref$change[allref$change %in% 'Fd'],allref$lu_t1_f[allref$change %in% 'Fd'])
colnames(tab_degraded) <- c('intact forest', 'planted forest', 'secondary forest' )
paste('Forest degraded between 2007 and 2016 orginally was',sprintf("%.0f%%", 100 * prop.table(tab_degraded)),colnames(tab_degraded), sep = ' ')
lbls <- paste(colnames(tab_degraded), "\n", sprintf("%.0f%%", 100 * prop.table(tab_degraded)), sep="")
# first display the chart in Rstudio
pie(tab_degraded, labels = lbls, 
    main=paste0("Original forest types of degraded forest", "\n", 'Sample size: ',sum(tab_degraded) ))
# then save as a PNG
png(paste0(plot_dir,'pie_degraded_t1.png'))
pie(tab_degraded, labels = lbls, 
    main=paste0("Original forest types of degraded forest", "\n", 'Sample size: ',sum(tab_degraded) ))
dev.off()
dev.off()

# disturbances of degraded forest...
tab_degraded_disturb <- table(allref$change[allref$change %in% 'Fd'],allref$disturbance_type.1.[allref$change %in% 'Fd'])
colnames(tab_degraded_disturb) <- c('commodity agriculture', 'logging', 'other human impact','roads', 'shifting cultivation')
paste('The main disturbance of forest degraded between 2007 and 2016 was',sprintf("%.0f%%", 100 * prop.table(tab_degraded_disturb)),colnames(tab_degraded_disturb), sep = ' ')
lbls <- paste(colnames(tab_degraded_disturb), "\n", sprintf("%.0f%%", 100 * prop.table(tab_degraded_disturb)), sep="")
# first display the chart in Rstudio
pie(tab_degraded_disturb, labels = lbls, 
    main=paste0("Primary disturbances of degraded forest", "\n", 'Sample size: ',sum(tab_degraded_disturb) ))
# then save as a PNG
png(paste0(plot_dir,'pie_degraded_t2.png'))
pie(tab_degraded_disturb, labels = lbls, 
    main=paste0("Primary disturbances of degraded forest", "\n", 'Sample size: ',sum(tab_degraded_disturb) ))
dev.off()
dev.off()

# table of drivers of degradation by forest type
deg <- table(allref$lu_t1_f[allref$change %in% 'Fd'],allref$disturbance_type.1.[allref$change %in% 'Fd'])
colnames(deg) <- c('commodity agriculture', 'logging', 'other human impact','roads', 'shifting cultivation')
rownames(deg) <- c('intact forest', 'planted forest', 'secondary forest' )
melted_deg <- melt(deg)
head(melted_deg)
# first display the chart in Rstudio
ggplot(data = melted_deg, aes(x=Var1, y=Var2)) +
  theme(plot.title = element_text(hjust = 0.5))+
  geom_tile(aes(fill=value)) + 
  geom_text(aes(label = value)) +
  scale_fill_gradient(low = "white", high = "red")+
  ggtitle("Drivers of degradation \n in Liberia by forest type") +
  xlab("Forest type") + ylab("Driver of degradation") +
  labs(fill = "# of samples")
# then save as a PNG
png(paste0(plot_dir,'heatmap_degraded_drivers.png'))
ggplot(data = melted_deg, aes(x=Var1, y=Var2)) +
  theme(plot.title = element_text(hjust = 0.5))+
  geom_tile(aes(fill=value)) + 
  geom_text(aes(label = value)) +
  scale_fill_gradient(low = "white", high = "red")+
  ggtitle("Drivers of degradation \n in Liberia by forest type") +
  xlab("Forest type") + ylab("Driver of degradation") +
  labs(fill = "# of samples")
dev.off()
dev.off()

########################################################
# quick stats on deforestation
# original land use of deforested land...
tab_deforest_t1 <- table(allref$change[allref$change %in% 'FNF'],allref$lu_t1_f[allref$change %in% 'FNF'])
paste('Deforestation between 2007 and 2016 orginally was',sprintf("%.0f%%", 100 * prop.table(tab_deforest_t1)),colnames(tab_deforest_t1), sep = ' ')
colnames(tab_deforest_t1) <- c('intact forest', 'mangroves' ,'planted forest', 'secondary forest' )
lbls <- paste(colnames(tab_deforest_t1), "\n", sprintf("%.0f%%", 100 * prop.table(tab_deforest_t1)), sep="")
pie(tab_deforest_t1, labels = lbls, 
    main=paste0("Deforested areas were converted \n from the following forest types", "\n", 'Sample size: ',sum(tab_deforest_t1) ))
# then save as a PNG
png(paste0(plot_dir,'pie_deforest_t1.png'))
pie(tab_deforest_t1, labels = lbls, 
    main=paste0("Drivers of deforestation in Liberia", "\n", 'Sample size: ',sum(tab_deforest_t1) ))
dev.off()
dev.off()

# drivers of deforestation
tab_deforest_t2 <- table(allref$change[allref$change %in% 'FNF'],allref$lu_t2[allref$change %in% 'FNF'])
paste('Forest deforested between 2007 and 2016 was converted into',sprintf("%.0f%%", 100 * prop.table(tab_deforest_t2)),colnames(tab_deforest_t2), sep = ' ')
lbls <- paste(colnames(tab_deforest_t2), "\n", sprintf("%.0f%%", 100 * prop.table(tab_deforest_t2)), sep="")
pie(tab_deforest_t2, labels = lbls, 
    main=paste0("Drivers of deforestation in Liberia", "\n", 'Sample size: ',sum(tab_deforest_t2) ))
# then save as a PNG
png(paste0(plot_dir,'pie_deforest_t2.png'))
pie(tab_deforest_t2, labels = lbls, 
    main=paste0("Drivers of deforestation in Liberia", "\n", 'Sample size: ',sum(tab_deforest_t2) ))
dev.off()

# table of drivers of deforestation by forest type
def <- table(allref$lu_t1_f[allref$change %in% 'FNF'],allref$lu_t2[allref$change %in% 'FNF'])
rownames(def) <- c('intact forest', 'mangroves' ,'planted forest', 'secondary forest' )
melted_def <- melt(def)
head(melted_def)
ggplot(data = melted_def, aes(x=Var1, y=Var2)) +
  theme(plot.title = element_text(hjust = 0.5))+
  geom_tile(aes(fill=value)) + 
  geom_text(aes(label = value)) +
  scale_fill_gradient(low = "white", high = "red")+
  ggtitle("Drivers of deforestation \n in Liberia by forest type") +
  xlab("Forest type") + ylab("Driver of deforestation") +
  labs(fill = "# of samples")
# then save as a PNG
png(paste0(plot_dir,'heatmap_deforest_drivers.png'))
ggplot(data = melted_def, aes(x=Var1, y=Var2)) +
  theme(plot.title = element_text(hjust = 0.5))+
  geom_tile(aes(fill=value)) + 
  geom_text(aes(label = value)) +
  scale_fill_gradient(low = "white", high = "red")+
  ggtitle("Drivers of deforestation \n in Liberia by forest type") +
  xlab("Forest type") + ylab("Driver of deforestation") +
  labs(fill = "# of samples")
dev.off()


## append text outputs to analysis text file
sink(paste0(ana_dir,'analysis-output.txt'), append=TRUE)
cat(' \n ____________________________________________________________________________ \n \n')
cat(' \n DRIVERS OF FOREST DEGRADATION AND DEFORESTATION \n ')
cat(paste('Forest degraded between 2007 and 2016 orginally was',sprintf("%.0f%%", 100 * prop.table(tab_degraded)),colnames(tab_degraded),'\n', sep = ' '))
cat(paste('The main disturbance of forest degraded between 2007 and 2016 was',sprintf("%.0f%%", 100 * prop.table(tab_degraded_disturb)),colnames(tab_degraded_disturb),'\n', sep = ' '))
cat(paste('Deforestation between 2007 and 2016 orginally was',sprintf("%.0f%%", 100 * prop.table(tab_deforest_t1)),colnames(tab_deforest_t1),'\n', sep = ' '))
cat(paste('Deforestation between 2007 and 2016 was forest converted into',sprintf("%.0f%%", 100 * prop.table(tab_deforest_t2)),colnames(tab_deforest_t2), '\n',sep = ' '))
# Stop writing to the file
sink()

