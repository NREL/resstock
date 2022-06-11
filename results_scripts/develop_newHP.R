rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
library(reshape2)
library(ggplot2)
library(gridExtra)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")

# Last Update Peter Berrill June 10 2022

# Purpose: Calculate demand for new heat pumps in different scenarios

# Inputs: - Intermediate_results/rs_base_EG.RData
#         - Intermediate_results/rs_baseDE_EG.RData
#         - Intermediate_results/RenStandard_EG.RData
#         - Intermediate_results/RenExtElec_EG.RData

# Outputs: 
#         - none, just create some figures


load("../Intermediate_results/rs_base_EG.RData")

# growth of new housing stock
colSums((rs_base$base_weight*rs_base[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]))
colSums((rs_base$base_weight_STCY*rs_base[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]))

# stock of new housing by year
nhs<-data.frame(Year=seq(2025,2060,5),Units=0,HP_Units=0)

for (y in seq(2025,2060,5)) {
  df<-rs_base[rs_base$Year==y,]
  nhs[nhs$Year==y,]$Units<-sum(df$base_weight_STCY*df[,paste('wbase',y,sep="_")])/5
  dfhp<-rs_base[rs_base$Year==y  & substr(rs_base$HVAC.Heating.Efficiency,1,4) %in% c('ASHP','MSHP'),]
  nhs[nhs$Year==y,]$HP_Units<-sum(dfhp$base_weight_STCY*dfhp[,paste('wbase',y,sep="_")])/5
  
}

# calculate total demand for heat pumps including replacement, assuming a 25 yr lifetime and no decay of new housing built over next 40 years
nhs$HP_Rep<-0
nhs$HP_Rep[6:8]<-nhs$HP_Units[1:3]
nhs$HP_NC_Tot<-nhs$HP_Units+nhs$HP_Rep

load("../Intermediate_results/rs_baseDE_EG.RData")

# stock of new housing by year
nhs_de<-data.frame(Year=seq(2025,2060,5),Units=0,HP_Units=0)

for (y in seq(2025,2060,5)) {
  df<-rs_baseDE[rs_baseDE$Year==y,]
  nhs_de[nhs_de$Year==y,]$Units<-sum(df$base_weight_STCY*df[,paste('wbase',y,sep="_")])/5
  dfhp<-rs_baseDE[rs_baseDE$Year==y  & substr(rs_baseDE$HVAC.Heating.Efficiency,1,4) %in% c('ASHP','MSHP'),]
  nhs_de[nhs_de$Year==y,]$HP_Units<-sum(dfhp$base_weight_STCY*dfhp[,paste('wbase',y,sep="_")])/5
  
}
# calculate total demand for heat pumps including replacement, assuming a 20 yr lifetime and no decay of new housing built over next 40 years
nhs_de$HP_Rep<-0
nhs_de$HP_Rep[6:8]<-nhs_de$HP_Units[1:3]
nhs_de$HP_NC_Tot<-nhs_de$HP_Units+nhs_de$HP_Rep

# now calculate how many HP to be installed in renovations, in both RR and ER scenarios
load('../Intermediate_results/RenStandard_EG.RData')

nhp_rr<-data.frame(Year=seq(2025,2060,5),RenUnits=0,HP_RenUnits=0)

for (y in seq(2025,2060,5)) {
  df<-rs_RRn[rs_RRn$Year==y & rs_RRn$change_hren<y,]
  nhp_rr[nhp_rr$Year==y,]$RenUnits<-sum(df$base_weight*df[,paste('wbase',y,sep="_")])/5
  dfhp<-rs_RRn[rs_RRn$Year==y & rs_RRn$change_hren<y & substr(rs_RRn$HVAC.Heating.Efficiency,1,4) %in% c('ASHP','MSHP'),]
  nhp_rr[nhp_rr$Year==y,]$HP_RenUnits<-sum(dfhp$base_weight*dfhp[,paste('wbase',y,sep="_")])/5
  
}

# and now for the ER scenario
load('../Intermediate_results/RenExtElec_EG.RData')


nhp_er<-data.frame(Year=seq(2025,2060,5),RenUnits=0,HP_RenUnits=0)

for (y in seq(2025,2060,5)) {
  df<-rs_ERn[rs_ERn$Year==y & rs_ERn$change_hren<y,]
  nhp_er[nhp_er$Year==y,]$RenUnits<-sum(df$base_weight*df[,paste('wbase',y,sep="_")])/5
  dfhp<-rs_ERn[rs_ERn$Year==y & rs_ERn$change_hren<y & substr(rs_ERn$HVAC.Heating.Efficiency,1,4) %in% c('ASHP','MSHP'),]
  nhp_er[nhp_er$Year==y,]$HP_RenUnits<-sum(dfhp$base_weight*dfhp[,paste('wbase',y,sep="_")])/5
  
}

hp_base_rr<-merge(nhs,nhp_rr)

names(hp_base_rr)[c(3,4,7)]<-c('NewCon','NewCon_Rep','Renovation')
hp_base_rrm<-melt(hp_base_rr[,c('Year','NewCon','NewCon_Rep','Renovation')],id.vars = 'Year')
names(hp_base_rrm)<-c('Year','Source','Demand')
hp_base_rrm$Scenario<-'Base NHC & Reg. Ren.'

hp_DE_er<-merge(nhs_de,nhp_er)

names(hp_DE_er)[c(3,4,7)]<-c('NewCon','NewCon_Rep','Renovation')
hp_DE_erm<-melt(hp_DE_er[,c('Year','NewCon','NewCon_Rep','Renovation')],id.vars = 'Year')
names(hp_DE_erm)<-c('Year','Source','Demand')
hp_DE_erm$Scenario<-'Inc. Elec. NHC & Ext. Ren.'

windows(width = 6.8,height = 5.4)
a<-ggplot(hp_base_rrm,aes(Year,1E-6*Demand,fill=Source)) + geom_area(alpha=0.75)  + scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10,2)) +
  labs(title ="a) Heat Pump Demand for Construction & Renovation",subtitle = 'Base NHC and Reg. Ren. Scenario',y="Million Heat Pump Units") + theme_bw() + 
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

windows(width = 6.8,height = 5.4)
b<-ggplot(hp_DE_erm,aes(Year,1E-6*Demand,fill=Source)) + geom_area(alpha=0.75)  + scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10,2)) +
  labs(title ="b) Heat Pump Demand for Construction & Renovation",subtitle = 'Inc. Elec. NHC and Ext. Ren. Scenario',y="Million Heat Pump Units") + theme_bw() + 
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

windows(width = 6.8,height = 10.5)
grid.arrange(a,b,nrow=2)
