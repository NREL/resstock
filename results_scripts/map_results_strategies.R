rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")

# Last Update Peter Berrill May 8 2022

# Purpose: Map results of mitigation strategies and electricity scenario by county and state, for different scenarios

# Inputs: - Final_results/GHG_scen_comp_StateCty.RData, calculations of GHG emissions reductions by county and state
#         - ExtData/GHGI_maps.RData, concordance of different geographical units; county, fips codes, electrical grid regions (small and large)
#         - ExtData/GHGI_LowRECost.RData, Projections of GHG intensity of electricity, NREL Low RE Cost scenario
#         - ExtData/GHGI_MidCase.RData, Projections of GHG intensity of electricity, NREL Mid Case scenario
#         - ExtData/ctycode.RData, county names and FIPS codes
#         - Final_results/StockCountComp.RData, counts of housing stock projections by county/state from scenarios and weighted samples

# Outputs: 
#         - Spatial figures for the main text (Fig 4) and supporting information, and associated csv files

library(dplyr)
library(ggplot2)
library(reshape2)
library(urbnmapr)
library(ggplot2)
library(RColorBrewer)
library(urbnthemes)
library(ggrepel)
library(stringr)
library(sf)
library(gridExtra)
set_urbn_defaults(style = "map")
'%!in%' <- function(x,y)!('%in%'(x,y))
# load in results
load('../Final_results/GHG_scen_comp_StateCty.RData')
load('../ExtData/GHGI_maps.RData')
load('../ExtData/GHGI_LowRECost.RData')
load('../ExtData/GHGI_MidCase.RData')
# add FIPS codes
load("../ExtData/ctycode.RData")
names(ctycode)[2]<-'County'
cty_assess<-merge(cty_assess,ctycode)

# loading mapping files
counties_sf<-get_urbn_map(map = "counties", sf = TRUE)
counties_sf<-counties_sf[!counties_sf$state_abbv %in% c('AK','HI'),]

states_sf <- get_urbn_map(map = "states", sf = TRUE)
states_sf <- states_sf[!states_sf$state_abbv  %in% c('AK','HI'),]

# first show what is the best strategy by county. 
# remove counties where hiDR or hiMF is identified but there are big differences in stock estimate accuracies
check_hiDR<-cty_assess[cty_assess$best %in% c('hiDR'),]
check_hiDR<-check_hiDR[abs(check_hiDR$EstRatio_base-check_hiDR$EstRatio_hiDR)<0.015,] # all counties which pass this test will be checked further

check_hiMF<-cty_assess[cty_assess$best %in% c('hiMF'),]
check_hiMF<-check_hiMF[abs(check_hiMF$EstRatio_base-check_hiMF$EstRatio_hiMF)<0.015 & check_hiMF$pop_growth_pc>0.05,] # all counties which pass this test will be checked further
check_hiMF$County

# don't include these counties
filter<-cty_assess[cty_assess$best %in% c('hiDR','hiMF') & !(cty_assess$County %in% check_hiMF$County | cty_assess$County %in% check_hiDR$County),]


cty_assess$priority3<-cty_assess$best3<-NA
str_group<-str_sub(c('abs_redn_ER','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA'),10)
for (k in 1:nrow(cty_assess)) {
  cty_assess$priority3[k]<-paste(c(str_group[order(cty_assess[k,c('abs_redn_ER','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA')],decreasing=TRUE)]),collapse = ">")
  cty_assess$best3[k]<-str_group[order(cty_assess[k,c('abs_redn_ER','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA')],decreasing=TRUE)][1]
}

check_hiDR3<-cty_assess[cty_assess$best3 %in% c('hiDR'),]
check_hiDR3<-check_hiDR3[abs(check_hiDR3$EstRatio_base-check_hiDR3$EstRatio_hiDR)<0.015,] # all counties which pass this test will be checked further

check_hiMF3<-cty_assess[cty_assess$best3 %in% c('hiMF'),]
check_hiMF3<-check_hiMF3[abs(check_hiMF3$EstRatio_base-check_hiMF3$EstRatio_hiMF)<0.015 & check_hiMF3$pop_growth_pc>0.05,] # all counties which pass this test will be checked further

# don't include these counties
filter3<-cty_assess[cty_assess$best3 %in% c('hiDR','hiMF') & !(cty_assess$County %in% check_hiMF3$County | cty_assess$County %in% check_hiDR3$County),]

vars3<-cty_assess[!cty_assess$County %in% filter3$County ,c('County','abs_redn_ER','best3','GeoID')]
vars3$best4<-NA
vars3[vars3$best3=='hiDR',]$best4<-'High-TO'
vars3[vars3$best3=='ER',]$best4<-'Ext. Ren.'
vars3[vars3$best3=='hiMF',]$best4<-'High-MF'
vars3[vars3$best3=='DERFA',]$best4<-'IE & RFA'

vars<-cty_assess[!cty_assess$County %in% filter$County ,c('County','abs_redn_ER','best','GeoID')]

vars$best2<-NA
vars[vars$best=='LRE',]$best2<-'LREC'
vars[vars$best=='ER',]$best2<-'Ext. Ren.'
vars[vars$best=='hiMF',]$best2<-'High-MF'
vars[vars$best=='DERFA',]$best2<-'IE & RFA'
table(vars$best)
map_data<-right_join(counties_sf,vars,by = c("county_fips" ="GeoID"))

# Fig S34a, ED Figure 6a
windows(8.8, 5.4)
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = best2)) + coord_sf(datum = NA) + scale_fill_manual(values = c("#009E73","#CC79A7","#D55E00", "#E69F00")) +  #scale_fill_manual(values = c("blue", "magenta",  "#fdc086", "green")) +
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "Strategy") + 
  ggtitle("a) Best Mitigation Strategy by County") +
  theme(legend.title = element_text(size = 13,face='bold'),legend.text = element_text(size = 11),legend.key.size = unit(1.4,"line"),plot.title = element_text(hjust = 0.5,vjust=0,size=15),
        legend.box.margin=margin(-20,-20,-20,-20))

# now without LRE

map_data<-right_join(counties_sf,vars3,by = c("county_fips" ="GeoID"))
# Fig S34b, ED Figure 6b
windows(8.8, 5.4)
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = best4)) + coord_sf(datum = NA) + scale_fill_manual(values = c("#009E73","#CC79A7",'blue',"#D55E00")) +  #scale_fill_manual(values = c("blue", "magenta",  "#fdc086", "green")) +
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "Strategy") + 
  ggtitle("b) Best Mitigation Strategy by County, Excluding Electricity Supply Strategies") +
  theme(legend.title = element_text(size = 13,face='bold'),legend.text = element_text(size = 11),legend.key.size = unit(1.4,"line"),plot.title = element_text(hjust = 0.5,vjust=0,size=15),
        legend.box.margin=margin(-20,-20,-20,-20))


# show pc reductions by county
vars<-cty_assess[,c('County','pc_redn_ER','abs_redn_ER','pc_redn_LRE','abs_redn_LRE','pc_redn_ER_LRE','abs_redn_ER_LRE','GeoID')]
vars[vars$pc_redn_ER<0,]$pc_redn_ER<-0
vars[vars$pc_redn_ER>0.42,]$pc_redn_ER<-0.42
vars[vars$pc_redn_LRE>0.5,]$pc_redn_LRE<-0.5
vars[vars$pc_redn_ER_LRE<0,]$pc_redn_ER_LRE<-0
vars[vars$pc_redn_ER_LRE>0.65,]$pc_redn_ER_LRE<-0.65
map_data<-right_join(counties_sf,vars,by = c("county_fips" ="GeoID"))
# ER
windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_ER)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "%      ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("a) Percent reduction, Cumulative Residential GHG 2020-2060, ER") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

# LRE
windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_LRE)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "%      ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("b) Percent reduction, Cumulative Residential GHG 2020-2060, LRE") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

# ER_LRE
windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_ER_LRE)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "%      ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("c) Percent reduction, Cumulative Residential GHG 2020-2060, ER & LRE") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 


# show absolute and pc reductions by state, these are used in the main text Fig. 4, and SI Fig S32 and S33 ###########
# first ER
vars<-st_assess[,c('State','abs_redn_ER','pc_redn_ER')]
map_data<-right_join(states_sf,vars,by = c("state_abbv" ="State"))

windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_ER)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size = 4,color='black') +
  labs(fill = "%      ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("a) Reduction of 2020-60 Cumulative GHG, ER (Renovate)") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=18)) 

# Fig S33a
windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = abs_redn_ER)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size = 4,color='gray') +
  labs(fill = "Mt") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("a) Absolute reduction, Cumulative Residential GHG 2020-2060, ER") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

ER_eg<-cty_assess[cty_assess$pc_redn_ER>0.3 & cty_assess$abs_redn_ER>5,]
write.csv(vars,'../Figures/Spatial/ER.csv',row.names = FALSE)

# LRE
vars<-st_assess[,c('State','abs_redn_LRE','pc_redn_LRE')]
map_data<-right_join(states_sf,vars,by = c("state_abbv" ="State"))

windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_LRE)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size =4,color='black') +
  labs(fill = "%       ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("b) Reduction of Cumulative GHG 2020-2060, LREC (Grid)") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=18)) 
# Fig S33b
windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = abs_redn_LRE)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size = 3,color='gray') +
  labs(fill = "Mt") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("b) Absolute reduction of Cumulative Residential GHG 2020-2060, LREC") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16))  
LRE_eg<-cty_assess[cty_assess$pc_redn_LRE>0.3 & cty_assess$abs_redn_LRE>5,]
write.csv(vars,'../Figures/Spatial/LRE.csv',row.names = FALSE)

# hiDR
vars<-st_assess[,c('State','abs_redn_hiDR','pc_redn_hiDR')]
vars2<-st_type_assess[,c('State','Type3','abs_redn_hiDR','pc_redn_hiDR')]
map_data<-right_join(states_sf,vars,by = c("state_abbv" ="State"))

windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_hiDR)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size =4,color='black') +
  labs(fill = "%       ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("a) Percent reduction of Cumulative Residential GHG 2020-2060, hiTO") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 
# Fig S33e
windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = abs_redn_hiDR)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size =4,color='black') +
  labs(fill = "Mt") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("e) Absolute reduction of Cumulative Residential GHG 2020-2060, hiTO") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16))  

write.csv(vars,'../Figures/Spatial/hiDR.csv',row.names = FALSE)
write.csv(vars2,'../Figures/Spatial/hiDR2.csv',row.names = FALSE)

# hiMF
vars<-st_assess[,c('State','abs_redn_hiMF','pc_redn_hiMF')]
map_data<-right_join(states_sf,vars,by = c("state_abbv" ="State"))

windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_hiMF)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size = 4,color='black') +
  labs(fill = "%"       ) + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("d) Reduction of Cumulative GHG 2020-60, hiMF (Stock)") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=18)) 
# Fig S33d
windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = abs_redn_hiMF)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size = 4,color='gray') +
  labs(fill = "Mt") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("d) Absolute reduction of Cumulative Residential GHG 2020-2060, hiMF") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16))  

write.csv(vars,'../Figures/Spatial/hiMF.csv',row.names = FALSE)

# hiMF by county
vars<-cty_assess[!cty_assess$County %in% filter$County ,c('County','abs_redn_hiMF','pc_redn_hiMF','best','GeoID')]
map_data<-right_join(counties_sf,vars,by = c("county_fips" ="GeoID"))

windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_hiMF)) + coord_sf(datum = NA) +  
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "%") +  scale_fill_viridis_c(option = "viridis") + 
  ggtitle("Percent reduction of Cumulative Residential GHG 2020-2060, hiMF") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = abs_redn_hiMF)) + coord_sf(datum = NA) +  
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "Mt") +  scale_fill_viridis_c(option = "viridis") + 
  ggtitle("Absolute reduction of Cumulative Residential GHG 2020-2060, hiMF") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

hiMF_eg<-vars[vars$abs_redn_hiMF>1 & vars$pc_redn_hiMF>0.09,]

# DERFA
vars<-st_assess[,c('State','abs_redn_DERFA','pc_redn_DERFA')]
map_data<-right_join(states_sf,vars,by = c("state_abbv" ="State"))

windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_DERFA)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size = 4,color='black') +
  labs(fill = "%       ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("c) Reduction of Cumulative GHG 2020-60, IE-RFA (New Homes)") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=18)) 
# Fig S33c
windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = abs_redn_DERFA)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.25) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size = 4,color='gray') +
  labs(fill = "Mt") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("c) Absolute reduction of Cumulative Residential GHG 2020-2060, DERFA") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16))  

write.csv(vars,'../Figures/Spatial/DERFA.csv',row.names = FALSE)

# DERFA by county
vars<-cty_assess[!cty_assess$County %in% filter$County ,c('County','abs_redn_DERFA','pc_redn_DERFA','best','GeoID')]
map_data<-right_join(counties_sf,vars,by = c("county_fips" ="GeoID"))

windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_DERFA)) + coord_sf(datum = NA) +  
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "%") +  scale_fill_viridis_c(option = "viridis") + 
  ggtitle("Percent reduction of Cumulative Residential GHG 2020-2060, DERFA") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'white', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = abs_redn_DERFA)) + coord_sf(datum = NA) +  
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "Mt") +  scale_fill_viridis_c(option = "viridis") + 
  ggtitle("Absolute reduction of Cumulative Residential GHG 2020-2060, DERFA") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

DERFA_eg<-vars[vars$abs_redn_DERFA>1.5 & vars$pc_redn_DERFA>0.129,]
# and last LRE-ER
vars<-st_assess[,c('State','abs_redn_ER_LRE','pc_redn_ER_LRE')]
map_data<-right_join(states_sf,vars,by = c("state_abbv" ="State"))
windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = 100*pc_redn_ER_LRE)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.1) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size =4,color='black') +
  labs(fill = "%       ") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("b) Percent reduction, Cumulative Residential GHG 2020-2060, ER & LREC") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 
# Fig S33f
windows()
ggplot() +
  geom_sf(map_data,mapping = aes(fill = abs_redn_ER_LRE)) + coord_sf(datum = NA) +
  geom_sf(data = states_sf, fill = NA, color = "gray", size = 0.25) +
  geom_sf_text(data = get_urbn_labels(map = "states", sf = TRUE)[-c(2,12),],aes(label = state_abbv),size =4,color='black') +
  labs(fill = "Mt") + scale_fill_viridis_c(option = "viridis") + 
  ggtitle("f) Absolute reduction, Cumulative Residential GHG 2020-2060, ER & LREC") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16))  

write.csv(vars,'../Figures/Spatial/ER_LRE.csv',row.names = FALSE)


# now map the balancing areas by county
map[map$geoid10=='46113',c('geoid10','county','RS_ID')]<-c('46102','Oglala Lakota','SD, Oglala Lakota County')
map$geoid<-map$geoid10
map[nchar(map$geoid10)==4,]$geoid<-paste('0',map[nchar(map$geoid10)==4,]$geoid10,sep="")
map$rto2<-str_sub(map$rto,4)
vars<-map
map_data<-right_join(counties_sf,vars,by = c("county_fips" ="geoid"))

windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'red', color = "#ffffff", size = 0.25) +
  geom_sf(md,mapping = aes(fill = rto2)) + coord_sf(datum = NA)  + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(18))  + #scale_fill_manual(values = c("blue", "magenta",  "#fdc086", "green")) +   # scale_fill_discrete() +   # scale_fill_brewer(palette = "Set3") +
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "RTO") + 
  ggtitle("RTO") +
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

# now make the figure of GHG intensity in 2020 and in 2050 with LREC, for Fig S24 and ED Fig4
ghgi_gea20<-gicty_gea_LREC[gicty_gea_LREC$Year==2020,]
ghgi_gea20[ghgi_gea20$geoid10==46113,]$geoid10<-46102 # fix Oglala Lakota
ghgi_gea50<-gicty_gea_LREC[gicty_gea_LREC$Year==2050,]
ghgi_gea50[ghgi_gea50$geoid10==46113,]$geoid10<-46102 # fix Oglala Lakota
vars<-merge(map,ghgi_gea20[,c('geoid10','GHG_int')],by='geoid10')
names(vars)[11]<-'GHG_int_20'
vars<-merge(vars,ghgi_gea50[,c('geoid10','GHG_int')],by='geoid10')
names(vars)[12]<-'GHG_int_50'
md<-unique(right_join(counties_sf,vars,by = c("county_fips" ="geoid")))

gea_list<-unique(md$gea)

gea_ghg=data.frame(gea=rep('gea',length(gea_list)),ghg20=rep(0,length(gea_list)),ghg50=rep(0,length(gea_list)),geometry=rep(md$geometry[1],length(gea_list)))

for (k in 1:length(gea_list)) {
  g<-gea_list[k]
  gea_ghg$gea[k]<-g
  gea_ghg$geometry[k]<-st_union(md[md$gea==g,'geometry'])
  gea_ghg$ghg20[k]<-mean(md[md$gea==g,]$GHG_int_20)
  gea_ghg$ghg50[k]<-mean(md[md$gea==g,]$GHG_int_50)
  
}

# 
windows()
ggplot() + 
  geom_sf(data=gea_ghg$geometry,mapping = aes(fill=gea_ghg$ghg20),color='white',size=0.2) + 
  geom_sf(data = states_sf, fill = NA, color = 'grey' ,size = 0.05) + 
  labs(fill = "gCO2/kWh") + scale_fill_viridis_c(option = "plasma") +
  ggtitle("a) 2020 GHG intensity by GEA region") + 
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16))

windows()
ggplot() + 
  geom_sf(data=gea_ghg$geometry,mapping = aes(fill=gea_ghg$ghg50),color='white',size=0.2) + 
  geom_sf(data = states_sf, fill = NA, color = 'grey' ,size = 0.05) + 
  labs(fill = "gCO2/kWh") + scale_fill_viridis_c(option = "plasma") +
  ggtitle("b) 2050 GHG intensity by GEA region, LREC electricity scenario") + 
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16))

# plot evolution of grid intensities by grid region. need to do this before/without loading the urbanthemes, urbnmapr
gea_LREC<-unique(merge(gicty_gea_LREC,vars[,c('geoid10','gea')],by='geoid10')[,2:4])
gea_MC<-unique(merge(gicty_gea,vars[,c('geoid10','gea')],by='geoid10')[,2:4])

write.csv(gea_LREC,'../Figures/Grid/gea_LREC.csv',row.names = FALSE)
write.csv(gea_MC,'../Figures/Grid/gea_MC.csv',row.names = FALSE)

geas<-sort(unique(gea_LREC$gea))

windows(width = 6.5, height = 5.8)
a<-ggplot(gea_MC[gea_MC$gea %in% geas[1:10],],aes(Year,GHG_int,group=gea)) + geom_line(aes(color=gea),size=1) + theme_bw() + 
  scale_color_brewer(palette="Paired") + scale_y_continuous(limits = c(0,650)) + 
  labs(title = "a) Reduction of GHG intensity, 2020-2050, MC", subtitle = "GEA Regions Group 1",  y = "kgCO2/kWh") +
  theme(axis.text=element_text(size=10),axis.title=element_text(size=11,face = "bold"),plot.title = element_text(size = 12), plot.subtitle = element_text(size=11),legend.position = 'bottom',legend.margin=margin(t = 0, unit='cm'), legend.spacing.x = unit(0.1,'cm'),legend.title=element_blank(),legend.text = element_text(size=8))
a

windows(width = 6.5, height = 5.8)
b<-ggplot(gea_MC[gea_MC$gea %in% geas[11:20],],aes(Year,GHG_int,group=gea)) + geom_line(aes(color=gea),size=1) + theme_bw() + 
  scale_color_brewer(palette="Paired") + scale_y_continuous(limits = c(0,650)) + 
  labs(title = "c) Reduction of GHG intensity, 2020-2050, MC", subtitle = "GEA Regions Group 2",  y = "kgCO2/kWh") +
  theme(axis.text=element_text(size=10),axis.title=element_text(size=11,face = "bold"),plot.title = element_text(size = 12), plot.subtitle = element_text(size=11),legend.position = 'bottom',legend.margin=margin(t = 0, unit='cm'), legend.spacing.x = unit(0.1,'cm'),legend.title=element_blank(),legend.text = element_text(size=8))
b

windows(width = 6.5, height = 5.8)
c<-ggplot(gea_LREC[gea_LREC$gea %in% geas[1:10],],aes(Year,GHG_int,group=gea)) + geom_line(aes(color=gea),size=1) + theme_bw() + 
  scale_color_brewer(palette="Paired") + scale_y_continuous(limits = c(0,650)) + 
  labs(title = "b) Reduction of GHG intensity, 2020-2050, LREC", subtitle = "GEA Regions Group 1",  y = "kgCO2/kWh") +
  theme(axis.text=element_text(size=10),axis.title=element_text(size=11,face = "bold"),plot.title = element_text(size = 12), plot.subtitle = element_text(size=11), legend.position = 'bottom',legend.margin=margin(t = 0, unit='cm'), legend.spacing.x = unit(0.1,'cm'),legend.title=element_blank(),legend.text = element_text(size=8), axis.title.y=element_blank())
c
windows(width = 6.5, height = 5.8)
d<-ggplot(gea_LREC[gea_LREC$gea %in% geas[11:20],],aes(Year,GHG_int,group=gea)) + geom_line(aes(color=gea),size=1) + theme_bw() + 
  scale_color_brewer(palette="Paired") + scale_y_continuous(limits = c(0,650)) + 
  labs(title = "d) Reduction of GHG intensity, 2020-2050, LREC", subtitle = "GEA Regions Group 2",  y = "kgCO2/kWh") +
  theme(axis.text=element_text(size=10),axis.title=element_text(size=11,face = "bold"),plot.title = element_text(size = 12), plot.subtitle = element_text(size=11),legend.position = 'bottom',legend.margin=margin(t = 0, unit='cm'), legend.spacing.x = unit(0.1,'cm'), legend.title=element_blank(),legend.text = element_text(size=8), axis.title.y=element_blank())
d

grid.arrange(a, c,b,d,nrow = 2)

# see how much GHG intensity reduced by GEA region
ghgi_gea20_50<-ghgi_gea50[,1:2]
ghgi_gea20_50$pc_redn_LREC<-100*(ghgi_gea20$GHG_int-ghgi_gea50$GHG_int)/ghgi_gea20$GHG_int


vars<-merge(map,ghgi_gea20_50[,c('geoid10','pc_redn_LREC')],by='geoid10')
map_data<-right_join(counties_sf,vars,by = c("county_fips" ="geoid"))

windows()
ggplot() +
  geom_sf(data = counties_sf, fill = 'red', color = "#ffffff", size = 0.25) +
  geom_sf(map_data,mapping = aes(fill = pc_redn_LREC)) + coord_sf(datum = NA)  + 
  geom_sf(data = states_sf, fill = NA, color = "#ffffff", size = 0.25) +
  labs(fill = "%") + scale_fill_viridis_c(option = "plasma") +
  ggtitle("2020-2050 reduction in GHG intensity, LREC") + 
  theme(legend.title = element_text(size = 12),legend.text = element_text(size = 12),legend.key.size = unit(2,"line"),plot.title = element_text(hjust = 0.5,size=16)) 

vars<-merge(vars,ghgi_gea20[,c('geoid10','GHG_int')])
names(vars)[12]<-'GHG_int_2020'
vars<-merge(vars,ghgi_gea50[,c('geoid10','GHG_int')])
names(vars)[13]<-'GHG_int_2050'

write.csv(vars,'../Figures/Grid/LRE_redn.csv',row.names = FALSE)