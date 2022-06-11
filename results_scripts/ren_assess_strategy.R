rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")
library(ggplot2)
library(dplyr)
library(reshape2)
library(stringr)

# Last Update Peter Berrill June 10 2022

# Purpose: Test the benefits of individual renovation strategies in different scenarios. Make environmental-economic cost-benefit analysis of renovation strategies

# Inputs: - Intermediate_results/RenStandard_EG.RData
#         - Intermediate_results/RenAdvanced_EG.RData
#         - Intermediate_results/RenExtElec_EG.RData
#         - ExtData/CBA_prices/MT.csv
#         - ExtData/CBA_prices/ESC.csv
#         - etc., fuel prices by division
#         - ExtData/CapExHeat.csv
#         - ExtData/CapExDHW.csv
#         - ExtData/CapExIns.csv

# Outputs: 
#         - 
         # - Final_results/ren_strat_comp.RData
         # - Final_results/ren_strat_comp.xlsx
         # - Final_results/ren_strat_summ.RData
         # - Final_results/ren_NPV.RData
         # - Final_results/ren_div_sum.csv

load("../Intermediate_results/RenStandard_EG.RData")

# tot GHG reductions per renovation, base, in kg
rs_RRn[,c("redGHGren_base_2025","redGHGren_base_2030","redGHGren_base_2035","redGHGren_base_2040","redGHGren_base_2045","redGHGren_base_2050","redGHGren_base_2055","redGHGren_base_2060")]<-1000*
  (rs_RRn$base_weight*rs_RRn[,c("wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*rs_RRn$redn_GHG_abs

rs_RRn[,c("redGHGren_base_2025_LRE","redGHGren_base_2030_LRE","redGHGren_base_2035_LRE","redGHGren_base_2040_LRE","redGHGren_base_2045_LRE","redGHGren_base_2050_LRE","redGHGren_base_2055_LRE","redGHGren_base_2060_LRE")]<-1000*
  (rs_RRn$base_weight*rs_RRn[,c("wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*rs_RRn$redn_GHG_LRE_abs

# make Water Heater Fuel and Water Heater Efficiency consisent
rs_RRn[rs_RRn$Water.Heater.Efficiency %in% c('Electric Heat Pump, 80 gal'),]$Water.Heater.Fuel<-'Electricity HP'
rs_RRn[rs_RRn$Water.Heater.Efficiency %in% c('Electric Premium','Electric Standard','Electric Tankless'),]$Water.Heater.Fuel<-'Electricity'
rs_RRn[rs_RRn$Water.Heater.Efficiency %in% c('Natural Gas Premium','Natural Gas Standard','Natural Gas Tankless'),]$Water.Heater.Fuel<-'Natural Gas'
rs_RRn[rs_RRn$Water.Heater.Efficiency %in% c('Propane Premium','Propane Standard','Propane Tankless'),]$Water.Heater.Fuel<-'Propane'
rs_RRn[rs_RRn$Water.Heater.Efficiency %in% c('FIXME Fuel Oil Indirect','Fuel Oil Standard','Fuel Oil Premium'),]$Water.Heater.Fuel<-'Fuel Oil'

# extract descriptions of heating systems in the houses with heating renovations only
heatren_RR=cbind(as.data.frame(rs_RRn[which(rs_RRn$change_hren_only_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_RRn[which(rs_RRn$change_hren_only),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(heatren_RR)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
heatren_RR[substring(heatren_RR$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
heatren_RR[substring(heatren_RR$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

heatren_RR$Eff_pre<-paste(heatren_RR$Fuel_pre,heatren_RR$Efficiency_pre,sep="_")
heatren_RR$Eff_post<-paste(heatren_RR$Fuel_post,heatren_RR$Efficiency_post,sep="_")
heatren_RR$pre_post<-paste(heatren_RR$Eff_pre,heatren_RR$Eff_post,sep="->")
heatren_RR$Fuel_pre_post<-paste(heatren_RR$Fuel_pre,heatren_RR$Fuel_post,sep="->")
heatren_RR<-heatren_RR[,c('Year_Building','pre_post','Fuel_pre_post')]

# extract descriptions of water heating systems in the houses with heating renovations only
dhwren_RR=cbind(as.data.frame(rs_RRn[which(rs_RRn$change_wren_only_prev),c('Water.Heater.Fuel','Water.Heater.Efficiency')]),as.data.frame(rs_RRn[which(rs_RRn$change_wren_only),c('Year_Building','Year','Building','Water.Heater.Fuel','Water.Heater.Efficiency')]))

names(dhwren_RR)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')

dhwren_RR$Eff_pre<-paste(dhwren_RR$Fuel_pre,dhwren_RR$Efficiency_pre,sep="_")
dhwren_RR$Eff_post<-paste(dhwren_RR$Fuel_post,dhwren_RR$Efficiency_post,sep="_")
dhwren_RR$pre_post<-paste(dhwren_RR$Eff_pre,dhwren_RR$Eff_post,sep="->")
dhwren_RR$Fuel_pre_post<-paste(dhwren_RR$Fuel_pre,dhwren_RR$Fuel_post,sep="->")
dhwren_RR<-dhwren_RR[,c('Year_Building','pre_post','Fuel_pre_post')]

# now envelope renovations
envren_RR=cbind(as.data.frame(rs_RRn[which(rs_RRn$change_iren_only_prev),c('Geometry.Wall.Type','insulation_crawlspace','insulation_unfinished_attic','insulation_unfinished_basement','insulation_wall')]),
             as.data.frame(rs_RRn[which(rs_RRn$change_iren_only),c('Year_Building','Year','Building','Geometry.Wall.Type','insulation_crawlspace','insulation_unfinished_attic','insulation_unfinished_basement','insulation_wall')]))
names(envren_RR)[2:5]<-paste(names(envren_RR)[2:5],'pre',sep="_")
names(envren_RR)[10:13]<-paste(names(envren_RR)[10:13],'post',sep="_")

envren_RR$Eff_pre<-'unallocated'
envren_RR[envren_RR$Geometry.Wall.Type=='Masonry' & envren_RR$insulation_wall_pre %in% c('Brick, 12-in, 3-wythe, Uninsulated','CMU, 6-in Hollow, Uninsulated'),]$Eff_pre<-'None'
envren_RR[envren_RR$Geometry.Wall.Type=='WoodStud' & envren_RR$insulation_wall_pre == 'Wood Stud, Uninsulated',]$Eff_pre<-'None'

envren_RR[envren_RR$Geometry.Wall.Type=='Masonry' & envren_RR$insulation_wall_pre %in% c('CMU, 6-in Hollow, R-7','CMU, 6-in Hollow, R-11'),]$Eff_pre<-'Moderate'
envren_RR[envren_RR$Geometry.Wall.Type=='WoodStud' & envren_RR$insulation_wall_pre %in% c('Wood Stud, R-7','Wood Stud, R-11'),]$Eff_pre<-'Moderate'

envren_RR[envren_RR$Geometry.Wall.Type=='Masonry' & envren_RR$insulation_wall_pre %in% c('CMU, 6-in Hollow, R-15','CMU, 6-in Hollow, R-19'),]$Eff_pre<-'High'
envren_RR[envren_RR$Geometry.Wall.Type=='WoodStud' & envren_RR$insulation_wall_pre %in% c('Wood Stud, R-15','Wood Stud, R-19','Wood Stud, R-19, R-5 Sheathing'),]$Eff_pre<-'High'

envren_RR$Eff_post<-'unallocated'
envren_RR[envren_RR$Geometry.Wall.Type=='Masonry' & envren_RR$insulation_wall_post %in% c('Brick, 12-in, 3-wythe, Uninsulated','CMU, 6-in Hollow, Uninsulated'),]$Eff_post<-'None'
envren_RR[envren_RR$Geometry.Wall.Type=='WoodStud' & envren_RR$insulation_wall_post == 'Wood Stud, Uninsulated',]$Eff_post<-'None'

envren_RR[envren_RR$Geometry.Wall.Type=='Masonry' & envren_RR$insulation_wall_post %in% c('CMU, 6-in Hollow, R-7','CMU, 6-in Hollow, R-11'),]$Eff_post<-'Moderate'
envren_RR[envren_RR$Geometry.Wall.Type=='WoodStud' & envren_RR$insulation_wall_post %in% c('Wood Stud, R-7','Wood Stud, R-11'),]$Eff_post<-'Moderate'

envren_RR[envren_RR$Geometry.Wall.Type=='Masonry' & envren_RR$insulation_wall_post %in% c('CMU, 6-in Hollow, R-15','CMU, 6-in Hollow, R-19'),]$Eff_post<-'High'
envren_RR[envren_RR$Geometry.Wall.Type=='WoodStud' & envren_RR$insulation_wall_post %in% c('Wood Stud, R-15','Wood Stud, R-19','Wood Stud, R-19, R-5 Sheathing'),]$Eff_post<-'High'

table(envren_RR$insulation_wall_post)
table(envren_RR$insulation_wall_post,envren_RR$insulation_wall_pre)
table(envren_RR$insulation_wall_post,envren_RR$Eff_post)

envren_RR$pre_post<-paste(envren_RR$Eff_pre,envren_RR$Eff_post,sep="->")
# envren_RR$Fuel_pre_post<-'NoChange'
envren_RR$Fuel_pre_post<-paste(envren_RR$insulation_wall_pre,envren_RR$insulation_wall_post,sep="->")
envren_RR<-envren_RR[,c('Year_Building','pre_post','Fuel_pre_post')]

# extract descriptions of heating systems in the houses with heating renovations and envelope renovations
heatenvren_RR=cbind(as.data.frame(rs_RRn[which(rs_RRn$change_hren_iren_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_RRn[which(rs_RRn$change_hren_iren),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(heatenvren_RR)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
heatenvren_RR[substring(heatenvren_RR$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
heatenvren_RR[substring(heatenvren_RR$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

heatenvren_RR$Eff_pre<-paste(heatenvren_RR$Fuel_pre,heatenvren_RR$Efficiency_pre,sep="_")
heatenvren_RR$Eff_post<-paste(heatenvren_RR$Fuel_post,heatenvren_RR$Efficiency_post,sep="_")
heatenvren_RR$pre_post<-paste(heatenvren_RR$Eff_pre,heatenvren_RR$Eff_post,sep="->")
heatenvren_RR$Fuel_pre_post<-paste(heatenvren_RR$Fuel_pre,'->',heatenvren_RR$Fuel_post,'_Envelope',sep="")
heatenvren_RR<-heatenvren_RR[,c('Year_Building','pre_post','Fuel_pre_post')]

# function to get summary data of buildings having renovations
# get the full details for buildings that had only a heat ren
ren_extract<-function(rs,dfren,rentype) {

rs_RRn2<-merge(rs,dfren,by='Year_Building',all.x = TRUE)
rs_RRn2<-rs_RRn2[with(rs_RRn2, order(Building,Year)),]

rs_RRn2<-rs_RRn2[,c('Year_Building','Year','Building','County','State','Census.Division','Census.Region','ASHRAE.IECC.Climate.Zone.2004','Building.America.Climate.Zone','ISO.RTO.Region','base_weight','wbase_2020','wbase_2025','wbase_2030','wbase_2035',
                    'Geometry.Building.Type.ACS','Geometry.Building.Type.RECS','Vintage','Vintage.ACS','Heating.Fuel','Geometry.Floor.Area','HVAC.Heating.Type.And.Fuel','Geometry.Stories',
                    'floor_area_attic_ft_2','floor_area_lighting_ft_2','floor_area_conditioned_ft_2','wall_area_above_grade_exterior_ft_2','wall_area_below_grade_ft_2',
                    'HVAC.Heating.Efficiency','HVAC.Cooling.Type','HVAC.Cooling.Efficiency','Water.Heater.Fuel','Water.Heater.Efficiency','Infiltration',
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'insulation'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'electricity'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'natural_gas'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'propane'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'fuel_oil'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'size'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'total'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Elec'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Gas'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Oil'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Prop'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Tot'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'EnGHG'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'redn'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'change'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'GHG_p'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'redG'))],'pre_post','Fuel_pre_post',
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'hren'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'iren'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'wren'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'cren'))])]
if (rentype != 'hren_iren') {rs_RRn2[,paste(rentype,'_assess',sep="")]<-rs_RRn2[,paste('change',rentype,'only',sep="_")] | rs_RRn2[,paste('change',rentype,'only','prev',sep="_")]}
if (rentype == 'hren_iren') {rs_RRn2$hren_iren_assess<-rs_RRn2$change_hren_iren | rs_RRn2$change_hren_iren_prev}

# extract only the rows we are comparing, that is buildings that either had a heat ren, or those buildings immediately pre-heat ren
rs_ret<-rs_RRn2[rs_RRn2[,paste(rentype,'_assess',sep='')]==TRUE,]

rs_ret$RenState<-'post'
rs_ret[is.na(rs_ret$pre_post),]$RenState<-'pre'

rs_ret
}

rs_RRh<-ren_extract(rs_RRn,heatren_RR,'hren')
rs_RRw<-ren_extract(rs_RRn,dhwren_RR,'wren')
rs_RRi<-ren_extract(rs_RRn,envren_RR,'iren')
rs_RRhi<-ren_extract(rs_RRn,heatenvren_RR,'hren_iren')

# define function to compare how reductions play out over geography
df=rs_RRh
var='Census.Division'
rentype='hren'
years<-seq(2020,2060,5)
sum_redn<-function(df,var,rentype) { # need to extend this to include LRE 
  if (rentype == 'iren') {df$Fuel_pre_post<-df$pre_post}
  v<-data.frame(round(tapply(df[df$RenState=='post',]$redn_GHG_abs,
                             list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),mean),2))
  v$FuelSwitch<-rownames(v)
  v<-melt(v)
  v[,var]<-substring(v$variable,7)
  v$Year<-as.numeric(substring(v$variable,2,5))
  v<-v[,c('Year',var,'FuelSwitch','value')]
  names(v)[4]<-'GHG_Redn_avg_t_yr'
  # also for LRE
  v2<-data.frame(round(tapply(df[df$RenState=='post',]$redn_GHG_LRE_abs,
                             list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),mean),2))
  v2$FuelSwitch<-rownames(v2)
  v2<-melt(v2)
  v2[,var]<-substring(v2$variable,7)
  v2$Year<-as.numeric(substring(v2$variable,2,5))
  v2<-v2[,c('Year',var,'FuelSwitch','value')]
  names(v2)[4]<-'GHG_Redn_LRE_avg_t_yr'
  
  v<-merge(v,v2)
  
  # second, we calculate stock-wide reductions in GHG, per year
  hr_det_v0<-data.frame(tapply(df[df$RenState=='post' & df$Year==years[2],which(startsWith(names(df),'redGHGren_base'))[1]],list(df[df$RenState=='post'& df$Year==years[2],]$Fuel_pre_post,df[df$RenState=='post'& df$Year==years[2],var]),sum)*1e-6)
  hr_det_v0$FuelSwitch<-rownames(hr_det_v0)
  hr_det_v0<-melt(hr_det_v0)
  hr_det_v0$Year<-years[2]
  
  hr_det_v1<-data.frame(tapply(df[df$RenState=='post' & df$Year==years[2],which(startsWith(names(df),'redGHGren_base'))[9]],list(df[df$RenState=='post'& df$Year==years[2],]$Fuel_pre_post,df[df$RenState=='post'& df$Year==years[2],var]),sum)*1e-6)
  hr_det_v1$FuelSwitch<-rownames(hr_det_v1)
  hr_det_v1<-melt(hr_det_v1)
  hr_det_v1$Year<-years[2]
  
  for (y in 2:8) {
    hr_det_v<-data.frame(tapply(df[df$RenState=='post'& df$Year==years[y+1],which(startsWith(names(df),'redGHGren_base'))[y]],list(df[df$RenState=='post'& df$Year==years[y+1],]$Fuel_pre_post,df[df$RenState=='post'& df$Year==years[y+1],var]),sum)*1e-6)
    hr_det_v$FuelSwitch<-rownames(hr_det_v)
    hr_det_v<-melt(hr_det_v)
    hr_det_v$Year<-years[y+1]
    
    hr_det_v0<-rbind(hr_det_v0,hr_det_v)
    
    hr_det_v<-data.frame(tapply(df[df$RenState=='post'& df$Year==years[y+1],which(startsWith(names(df),'redGHGren_base'))[y+8]],list(df[df$RenState=='post'& df$Year==years[y+1],]$Fuel_pre_post,df[df$RenState=='post'& df$Year==years[y+1],var]),sum)*1e-6)
    hr_det_v$FuelSwitch<-rownames(hr_det_v)
    hr_det_v<-melt(hr_det_v)
    hr_det_v$Year<-years[y+1]
    
    hr_det_v1<-rbind(hr_det_v1,hr_det_v)
  }
  if (var %in% c('Vintage.ACS','Vintage','Geometry.Floor.Area')) {hr_det_v0$variable<-gsub("X","",hr_det_v0$variable); hr_det_v1$variable<-gsub("X","",hr_det_v1$variable)}
  names(hr_det_v0)[2]<-var
  
  hr_det_v0<-hr_det_v0[,c('Year',var,'FuelSwitch','value')]
  names(hr_det_v0)[4]<-'GHG_Redn_StockTot_kt_yr'
  hr_det_v0$GHG_Redn_StockTot_kt_yr<-round(hr_det_v0$GHG_Redn_StockTot_kt_yr,1)
  
  names(hr_det_v1)[2]<-var
  hr_det_v1<-hr_det_v1[,c('Year',var,'FuelSwitch','value')]
  names(hr_det_v1)[4]<-'GHG_Redn_LRE_StockTot_kt_yr'
  hr_det_v1$GHG_Redn_LRE_StockTot_kt_yr<-round(hr_det_v1$GHG_Redn_LRE_StockTot_kt_yr,1)
  
  v<-merge(v,hr_det_v0)
  v<-merge(v,hr_det_v1)
  
  # now add some cumulative impact measures
  # first average cumulative impact
  vc<-data.frame(round(tapply(df[df$RenState=='post',paste(rentype,'_redn_cum_tCO2',sep="")],
                              list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),mean),2))
  vc$FuelSwitch<-rownames(vc)
  vc<-melt(vc)
  vc[,var]<-substring(vc$variable,7)
  vc$Year<-as.numeric(substring(vc$variable,2,5))
  vc<-vc[,c('Year',var,'FuelSwitch','value')]
  names(vc)[4]<-'GHG_Redn_Cum_avg_t'
  # LRE too
  vc2<-data.frame(round(tapply(df[df$RenState=='post',paste(rentype,'_redn_cum_LRE_tCO2',sep="")],
                              list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),mean),2))
  vc2$FuelSwitch<-rownames(vc2)
  vc2<-melt(vc2)
  vc2[,var]<-substring(vc2$variable,7)
  vc2$Year<-as.numeric(substring(vc2$variable,2,5))
  vc2<-vc2[,c('Year',var,'FuelSwitch','value')]
  names(vc2)[4]<-'GHG_Redn_LRE_Cum_avg_t'
  
  # then stock-wide sum cumulative impacts
  vcs<-data.frame(round(tapply(df[df$RenState=='post',paste(rentype,'_sredn_cum_tCO2',sep="")],
                               list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),sum),2))*1e-6
  vcs$FuelSwitch<-rownames(vcs)
  vcs<-melt(vcs)
  vcs[,var]<-substring(vcs$variable,7)
  vcs$Year<-as.numeric(substring(vcs$variable,2,5))
  vcs<-vcs[,c('Year',var,'FuelSwitch','value')]
  names(vcs)[4]<-'GHG_Redn_Cum_StockTot_Mt'
  # LRE too
  vcs2<-data.frame(round(tapply(df[df$RenState=='post',paste(rentype,'_sredn_cum_LRE_tCO2',sep="")],
                               list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),sum),2))*1e-6
  vcs2$FuelSwitch<-rownames(vcs2)
  vcs2<-melt(vcs2)
  vcs2[,var]<-substring(vcs2$variable,7)
  vcs2$Year<-as.numeric(substring(vcs2$variable,2,5))
  vcs2<-vcs2[,c('Year',var,'FuelSwitch','value')]
  names(vcs2)[4]<-'GHG_Redn_LRE_Cum_StockTot_Mt'
  
  v<-merge(v,vc)
  v<-merge(v,vc2)
  
  v<-merge(v,vcs)
  v<-merge(v,vcs2)
  
  count<-melt(tapply(df$Building,list(df$Year,df[,var],df$Fuel_pre_post),length))
  names(count)<-c('Year',var,'FuelSwitch','Count')
  count[,var]<-gsub('<','.',count[,var])
  count[,var]<-gsub('-','.',count[,var])
  count[,var]<-gsub(' ','.',count[,var])
  
  count25<-melt(round(tapply(df$base_weight*df$wbase_2025,list(df$Year,df[,var],df$Fuel_pre_post),sum)))
  names(count25)<-c('Year',var,'FuelSwitch','Stock_2025')
  count25[,var]<-gsub('<','.',count25[,var])
  count25[,var]<-gsub('-','.',count25[,var])
  count25[,var]<-gsub(' ','.',count25[,var])
  
  count30<-melt(round(tapply(df$base_weight*df$wbase_2030,list(df$Year,df[,var],df$Fuel_pre_post),sum)))
  names(count30)<-c('Year',var,'FuelSwitch','Stock_2030')
  count30[,var]<-gsub('<','.',count30[,var])
  count30[,var]<-gsub('-','.',count30[,var])
  count30[,var]<-gsub(' ','.',count30[,var])
  
  count35<-melt(round(tapply(df$base_weight*df$wbase_2035,list(df$Year,df[,var],df$Fuel_pre_post),sum)))
  names(count35)<-c('Year',var,'FuelSwitch','Stock_2035')
  count35[,var]<-gsub('<','.',count35[,var])
  count35[,var]<-gsub('-','.',count35[,var])
  count35[,var]<-gsub(' ','.',count35[,var])
  
  v<-merge(v,count)
  v<-merge(v,count25)
  v<-merge(v,count30)
  v<-merge(v,count35)
  v[v$Year %in% c(2030,2035),]$Stock_2025<-0
  v[v$Year %in% c(2025,2035),]$Stock_2030<-0
  v[v$Year %in% c(2025,2030),]$Stock_2035<-0
  v$Stock<-v$Stock_2025+v$Stock_2030+v$Stock_2035
  v<-v[,-c(which(names(v) %in% c('Stock_2025','Stock_2030','Stock_2035')))]
  
  if (rentype == 'iren') {names(v)[3]<-'EnvelopeUpgrade'}
  
  if (rentype %in% c('hren','wren')) {
  
  vl<-v[v$FuelSwitch %in% c('Electricity->Electricity HP','Electricity->Natural Gas','Electricity->Electricity',
                            'Electricity HP->Electricity HP',
                            'Fuel Oil->Electricity','Fuel Oil->Electricity HP','Fuel Oil->Fuel Oil','Fuel Oil->Natural Gas',
                            'Natural Gas->Electricity','Natural Gas->Electricity HP','Natural Gas->Natural Gas',
                            'Propane->Electricity','Propane->Electricity HP','Propane->Propane','Propane->Natural Gas'),]
  } else  if (rentype == 'hren_iren') {
    vl<-v[v$FuelSwitch %in% c('Electricity->Electricity HP_Envelope','Electricity->Natural Gas_Envelope','Electricity->Electricity_Envelope',
                              'Electricity HP->Electricity HP_Envelope',
                              'Fuel Oil->Electricity_Envelope','Fuel Oil->Electricity HP_Envelope','Fuel Oil->Fuel Oil_Envelope','Fuel Oil->Natural Gas_Envelope',
                              'Natural Gas->Electricity_Envelope','Natural Gas->Electricity HP_Envelope','Natural Gas->Natural Gas_Envelope',
                              'Propane->Electricity_Envelope','Propane->Electricity HP_Envelope','Propane->Propane_Envelope','Propane->Natural Gas_Envelope'),]
    
  } else  {vl<-v}
  
  vl<-vl[complete.cases(vl),]
  vl<-vl[vl$Count>9,]
  # pick out some highlights with high potential impact
  # ... measured as high cumulative potential in an individual buildings or stock wide
  vl_highlight<-vl[vl$GHG_Redn_Cum_StockTot_Mt>1.5 | vl$GHG_Redn_Cum_avg_t>30 ,]
  
  return (list(v, vl,vl_highlight))
}

# shr<-sum_redn(rs_RRh,'Vintage.ACS','hren')
# vint_heat<-shr[[1]]
# vint_heat_sum<-shr[[2]]
# vint_heat_highlight<-shr[[3]]
# 
# 
# swr<-sum_redn(rs_RRw,'Vintage.ACS','wren')
# vint_dhw<-swr[[1]]
# vint_dhw_sum<-swr[[2]]
# vint_dhw_highlight<-swr[[3]]

# apply sum_redn function for different renovation families, by census division
shr<-sum_redn(rs_RRh,'Census.Division','hren')
div_rr_heat<-shr[[1]]
div_rr_heat_sum<-shr[[2]]
div_rr_heat_highlight<-shr[[3]]

swr<-sum_redn(rs_RRw,'Census.Division','wren')
div_rr_dwh<-swr[[1]]
div_rr_dwh_sum<-swr[[2]]
div_rr_dwh_highlight<-swr[[3]]

sir<-sum_redn(rs_RRi,'Census.Division','iren')
div_rr_env<-sir[[1]]
div_rr_env_sum<-sir[[2]]
div_rr_env_highlight<-sir[[3]]

shir<-sum_redn(rs_RRhi,'Census.Division','hren_iren')
div_rr_heat_env<-shir[[1]]
div_rr_heat_env_sum<-shir[[2]]
div_rr_heat_env_highlight<-shir[[3]]


# calculate NPV of renovations ############
# load in proejction fuel prices by census division, from EIA AEO, https://www.eia.gov/outlooks/aeo/data/browser/#/?id=3-AEO2022&cases=ref2022&sourcekey=0
mt_fc<-read.csv('../ExtData/CBA_prices/MT.csv')
mt_fc$Census.Division<-'Mountain'
esc_fc<-read.csv('../ExtData/CBA_prices/ESC.csv')
esc_fc$Census.Division<-'East South Central'
ma_fc<-read.csv('../ExtData/CBA_prices/MA.csv')
ma_fc$Census.Division<-'Middle Atlantic'
ne_fc<-read.csv('../ExtData/CBA_prices/NE.csv')
ne_fc$Census.Division<-'New England'
pa_fc<-read.csv('../ExtData/CBA_prices/PA.csv')
pa_fc$Census.Division<-'Pacific'
sa_fc<-read.csv('../ExtData/CBA_prices/SA.csv')
sa_fc$Census.Division<-'South Atlantic'
wnc_fc<-read.csv('../ExtData/CBA_prices/WNC.csv')
wnc_fc$Census.Division<-'West North Central'
wsc_fc<-read.csv('../ExtData/CBA_prices/WSC.csv')
wsc_fc$Census.Division<-'West South Central'
enc_fc<-read.csv('../ExtData/CBA_prices/ENC.csv')
enc_fc$Census.Division<-'East North Central'

fc<-bind_rows(mt_fc,esc_fc,ma_fc,ne_fc,pa_fc,sa_fc,wnc_fc,wsc_fc,enc_fc)
names(fc)[2:5]<-c('Prop','Oil','Gas','Elec')
fc[,2:5]<-fc[,2:5]/1.055

fc[,c('Prop_dis','Oil_dis','Gas_dis','Elec_dis')]<-0

# here we define interest rates using a discount factor of 0.03
int<-data.frame(t=1:25)
int$d<-1.03^int$t

fc[fc$Year %in% c(2026:2050),c('Prop_dis','Oil_dis','Gas_dis','Elec_dis')]<-fc[fc$Year %in% c(2026:2050),c('Prop','Oil','Gas','Elec')]/int$d

# capital expenses for renovations, from NREL REMDB https://remdb.nrel.gov/about.php
heatCX<-read.csv('../ExtData/CapExHeat.csv')
dhwCX<-read.csv('../ExtData/CapExDHW.csv')
envCX<-read.csv('../ExtData/CapExIns.csv')

df<-rs_RRh
rentype='hren'
npv<-function(df,rentype,CX,CX2) {
  df0<-df[df[,paste('change',rentype,sep="_")]<2026 & df$Year<2030,c('Year_Building','Year','Building','Census.Division','Heating.Fuel','HVAC.Heating.Efficiency','Water.Heater.Fuel','Water.Heater.Efficiency',
                                                                     'insulation_crawlspace','insulation_unfinished_attic','insulation_unfinished_basement','insulation_wall','Geometry.Stories',
                                                                     'floor_area_attic_ft_2','floor_area_lighting_ft_2','floor_area_conditioned_ft_2','wall_area_above_grade_exterior_ft_2','wall_area_below_grade_ft_2',
                                                                     'hren_redn_cum_tCO2','hren_redn_cum_LRE_tCO2','iren_redn_cum_tCO2','iren_redn_cum_LRE_tCO2','wren_redn_cum_tCO2','wren_redn_cum_LRE_tCO2','hren_iren_redn_cum_tCO2','hren_iren_redn_cum_LRE_tCO2',
                                                                     'Fuel_pre_post','pre_post','Elec_GJ','Gas_GJ','Oil_GJ','Prop_GJ','GHG_post','GHG_pre','redn_GHG_abs','change_hren','change_hren_only')] # might not need these: 'change_hren','change_hren_only'
  if (rentype %in% c('hren','hren_iren')) {df0$Heat_Fuel_Efficiency<-paste(df0$Heating.Fuel,df0$HVAC.Heating.Efficiency,sep="_")}
  if (rentype=='wren') {df0$Heat_Fuel_Efficiency<-paste(df0$Water.Heater.Fuel,df0$Water.Heater.Efficiency,sep="_")}
  if (rentype %in% c('iren','hren_iren')) {CXc<-CX[CX$Element=='Crawlspace',c(1,3)] ; CXua<-CX[CX$Element=='Unfinished Attic',c(1,3)] ;  CXub<-CX[CX$Element=='Unfinished Basement',c(1,3)] ;  CXw<-CX[CX$Element %in% c('Masonry.Wall','WoodFrame.Wall'),c(1,3)] ;
                        names(CXc)[2]<-'Cost_Crawl'; names(CXua)[2]<-'Cost_UnfAtt'; names(CXub)[2]<-'Cost_UnfBase';names(CXw)[2]<-'Cost_Wall';
                        names(CXc)[1]<-'insulation_crawlspace'; names(CXua)[1]<-'insulation_unfinished_attic'; names(CXub)[1]<-'insulation_unfinished_basement';names(CXw)[1]<-'insulation_wall'}
  

  tb<-as.data.frame(table(df0$Building))
  tb<-tb[tb$Freq>1,] # identify which buildings actually had a renovated
  df0<-df0[df0$Building %in% tb$Var1,] # and then select only these ones
  df0$CapEx<-0
  df0$OpEx<-0
  df0$NPV<-0
  df0$NPVc<-0
  df0$GHG_abate_cost<-0
  df0$GHG_abate_cost_LREC<-0
  if (rentype %in% c('hren','wren')) {
  for (b in tb$Var1) { # this can be very slow
    df1<-df0[df0$Building==b,]
    fcd<-fc[fc$Census.Division==df1$Census.Division[1],]
    df1$OpEx[2]<-sum(df1$Elec_GJ[1]*fcd$Elec_dis)-sum(df1$Elec_GJ[2]*fcd$Elec_dis) + 
      sum(df1$Gas_GJ[1]*fcd$Gas_dis)-sum(df1$Gas_GJ[2]*fcd$Gas_dis)  +
      sum(df1$Oil_GJ[1]*fcd$Oil_dis)-sum(df1$Oil_GJ[2]*fcd$Oil_dis)  +
      sum(df1$Prop_GJ[1]*fcd$Prop_dis)-sum(df1$Prop_GJ[2]*fcd$Prop_dis)  
    # add together all 
    CE<-merge(df1,CX) %>% arrange(Year) %>% select(Cost)
    df1$CapEx<-as.numeric(unlist(CE))*-1 
    df1$NPV[2]<-df1$CapEx[2] + df1$OpEx[2]
    df1$NPVc[2]<-df1$CapEx[2] - df1$CapEx[1] + df1$OpEx[2]
  
    df1$GHG_abate_cost[2]<-df1$NPVc[2]*-1/df1[2,paste(rentype,'_redn_cum_tCO2',sep="")]
    df1$GHG_abate_cost_LREC[2]<-df1$NPVc[2]*-1/df1[2,paste(rentype,'_redn_cum_LRE_tCO2',sep="")]
    df0[df0$Building==b,c('CapEx','OpEx','NPV','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC')]<-df1[,c('CapEx','OpEx','NPV','NPVc',paste(rentype,'_redn_cum_tCO2',sep=""),paste(rentype,'_redn_cum_LRE_tCO2',sep=""),'GHG_abate_cost','GHG_abate_cost_LREC')]
  }
  }
  if (rentype=='iren') {
    for (b in tb$Var1) { # this can be very slow
      df1<-df0[df0$Building==b,]
      fcd<-fc[fc$Census.Division==df1$Census.Division[1],]
      df1$OpEx[2]<-sum(df1$Elec_GJ[1]*fcd$Elec_dis)-sum(df1$Elec_GJ[2]*fcd$Elec_dis) +
        sum(df1$Gas_GJ[1]*fcd$Gas_dis)-sum(df1$Gas_GJ[2]*fcd$Gas_dis)  +
        sum(df1$Oil_GJ[1]*fcd$Oil_dis)-sum(df1$Oil_GJ[2]*fcd$Oil_dis)  +
        sum(df1$Prop_GJ[1]*fcd$Prop_dis)-sum(df1$Prop_GJ[2]*fcd$Prop_dis)
      # add together all capital expenses, important assumption for iren is that the only cost is the differences in cost between two levels of insulation

      CEC<-0
      if (str_sub(df1$insulation_crawlspace[2],-8) ==', Vented') {CEC<-merge(df1,CXc) %>% arrange(Year) %>% select(Cost_Crawl)*df1$wall_area_below_grade_ft_2}
      if (str_sub(df1$insulation_crawlspace[2],-8) =='Unvented') {CEC<-merge(df1,CXc) %>% arrange(Year) %>% select(Cost_Crawl)*df1$floor_area_conditioned_ft_2/df1$Geometry.Stories}

      CEUA<-merge(df1,CXua) %>% arrange(Year) %>% select(Cost_UnfAtt)*df1$floor_area_attic_ft_2
      CEUB<-merge(df1,CXub) %>% arrange(Year) %>% select(Cost_UnfBase)*df1$floor_area_conditioned_ft_2/df1$Geometry.Stories
      CEW<-merge(df1,CXw) %>% arrange(Year) %>% select(Cost_Wall)*df1$wall_area_above_grade_exterior_ft_2
      
      CE<-CEC+CEUA+CEUB+CEW

      df1$CapEx<-as.numeric(unlist(CE))*-1
      df1$NPV[2]<-df1$CapEx[2] + df1$OpEx[2]
      df1$NPVc[2]<-df1$CapEx[2] - df1$CapEx[1] + df1$OpEx[2]
      df1$GHG_abate_cost[2]<-df1$NPVc[2]*-1/df1$iren_redn_cum_tCO2[2]
      df1$GHG_abate_cost_LREC[2]<-df1$NPVc[2]*-1/df1$iren_redn_cum_LRE_tCO2[2]
      df0[df0$Building==b,c('CapEx','OpEx','NPV','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC')]<-df1[,c('CapEx','OpEx','NPV','NPVc','iren_redn_cum_tCO2','iren_redn_cum_LRE_tCO2','GHG_abate_cost','GHG_abate_cost_LREC')]
    }
  }
    if (rentype=='hren_iren') {
      for (b in tb$Var1) { 
        df1<-df0[df0$Building==b,]
        fcd<-fc[fc$Census.Division==df1$Census.Division[1],]
        df1$OpEx[2]<-sum(df1$Elec_GJ[1]*fcd$Elec_dis)-sum(df1$Elec_GJ[2]*fcd$Elec_dis) +
          sum(df1$Gas_GJ[1]*fcd$Gas_dis)-sum(df1$Gas_GJ[2]*fcd$Gas_dis)  +
          sum(df1$Oil_GJ[1]*fcd$Oil_dis)-sum(df1$Oil_GJ[2]*fcd$Oil_dis)  +
          sum(df1$Prop_GJ[1]*fcd$Prop_dis)-sum(df1$Prop_GJ[2]*fcd$Prop_dis)
        # add together all capital expenses, important assumption for iren is that the only cost is the differences in cost between two levels of insulation
        
        CEC<-0
        if (str_sub(df1$insulation_crawlspace[2],-8) ==', Vented') {CEC<-merge(df1,CXc) %>% arrange(Year) %>% select(Cost_Crawl)*df1$wall_area_below_grade_ft_2}
        if (str_sub(df1$insulation_crawlspace[2],-8) =='Unvented') {CEC<-merge(df1,CXc) %>% arrange(Year) %>% select(Cost_Crawl)*df1$floor_area_conditioned_ft_2/df1$Geometry.Stories}
        
        CEUA<-merge(df1,CXua) %>% arrange(Year) %>% select(Cost_UnfAtt)*df1$floor_area_attic_ft_2
        CEUB<-merge(df1,CXub) %>% arrange(Year) %>% select(Cost_UnfBase)*df1$floor_area_conditioned_ft_2/df1$Geometry.Stories
        CEW<-merge(df1,CXw) %>% arrange(Year) %>% select(Cost_Wall)*df1$wall_area_above_grade_exterior_ft_2
        CEH<-merge(df1,CX2) %>% arrange(Year) %>% select(Cost)
        
        CE<-CEC+CEUA+CEUB+CEW+CEH
        
        df1$CapEx<-as.numeric(unlist(CE))*-1
        df1$NPV[2]<-df1$CapEx[2] + df1$OpEx[2]
        df1$NPVc[2]<-df1$CapEx[2] - df1$CapEx[1] + df1$OpEx[2]
        df1$GHG_abate_cost[2]<-df1$NPVc[2]*-1/df1$hren_iren_redn_cum_tCO2[2]
        df1$GHG_abate_cost_LREC[2]<-df1$NPVc[2]*-1/df1$hren_iren_redn_cum_LRE_tCO2[2]
        df0[df0$Building==b,c('CapEx','OpEx','NPV','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC')]<-df1[,c('CapEx','OpEx','NPV','NPVc','hren_iren_redn_cum_tCO2','hren_iren_redn_cum_LRE_tCO2','GHG_abate_cost','GHG_abate_cost_LREC')]
      }
  }
  
  df0$pos_GHG_redn<-df0$GHG_redn_cum>0
  df0$pos_GHG_redn_LRE<-df0$GHG_redn_cum_LRE>0
  df0$pos_NPV<-df0$NPVc>0
  
  df0$pos_NPV_GHGredn<- df0$pos_GHG_redn & df0$pos_NPV
  df0$pos_NPV_negGHGredn<- !df0$pos_GHG_redn & df0$pos_NPV
  df0$neg_NPV_posGHGredn<- df0$pos_GHG_redn & !df0$pos_NPV
  df0$neg_NPV_negGHGredn<- !df0$pos_GHG_redn & !df0$pos_NPV
  
  
  df0$pos_NPV_GHGredn_LRE<- df0$pos_GHG_redn_LRE & df0$pos_NPV
  df0$pos_NPV_negGHGredn_LRE<- !df0$pos_GHG_redn_LRE & df0$pos_NPV
  df0$neg_NPV_posGHGredn_LRE<- df0$pos_GHG_redn_LRE & !df0$pos_NPV
  df0$neg_NPV_negGHGredn_LRE<- !df0$pos_GHG_redn_LRE & !df0$pos_NPV
  
  df0
}


npv_heat_RR<-npv(rs_RRh,'hren',heatCX)
npv_heat_RRr<-npv_heat_RR[npv_heat_RR$change_hren_only==TRUE,]

npv_dhw_RR<-npv(rs_RRw,'wren',dhwCX)
npv_dhw_RRr<-npv_dhw_RR[!is.na(npv_dhw_RR$pre_post),]

npv_env_RR<-npv(rs_RRi,'iren',envCX)
npv_env_RRr<-npv_env_RR[!is.na(npv_env_RR$pre_post),]

npv_heat_env_RR<-npv(rs_RRhi,'hren_iren',envCX,heatCX)
npv_heat_env_RRr<-npv_heat_env_RR[!is.na(npv_heat_env_RR$pre_post),]


# write a function to make a summary table, showing: 
# 1) percentage of renovations that are NPV+/- and GHG+/-, 4 columns, by renovation family, strategy, Division, grid scenario, and ren scenario
# 2) total costs of renovation, and reduced GHG emissions, and implied abatement cost,by renovation family, Division, grid scenario, and ren scenario
# 3) comparison of individual heating strategies by census division: identification of best, and worst (done above, not here)
# the function will work given an input npv data frame for a renovation family and ren scenario
str_ren<-npv_env_RRr
add<-div_rr_env

strat_comp<-function(str_ren,add) {
  if(str_ren$Fuel_pre_post[1]=='NoChange') {str_ren$Fuel_pre_post<-str_ren$pre_post;names(add)[3]<-'FuelSwitch'} # for the envelope only renovations
  dfsc<-data.frame(melt(tapply(str_ren$pos_GHG_redn,list(str_ren$Census.Division,str_ren$Fuel_pre_post),length)))
  names(dfsc)<-c('Division','Strategy','Length')
  dfsc$GHGredn_pc<-round(melt(tapply(str_ren$pos_GHG_redn,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc$Length,2)
  dfsc$NPV_pos_pc<-round(melt(tapply(str_ren$pos_NPV,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc$Length,2)
  
  dfsc$GHGredn_NPV_pos_pc<-round(melt(tapply(str_ren$pos_NPV_GHGredn,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc$Length,2)
  dfsc$GHGredn_NPV_neg_pc<-round(melt(tapply(str_ren$neg_NPV_posGHGredn,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc$Length,2)
  dfsc$GHGinc_NPV_pos_pc<-round(melt(tapply(str_ren$pos_NPV_negGHGredn,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc$Length,2)
  dfsc$GHGinc_NPV_neg_pc<-round(melt(tapply(str_ren$neg_NPV_negGHGredn,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc$Length,2)
  
  dfsc$avg_NPV<-round(melt(tapply(str_ren$NPVc,list(str_ren$Census.Division,str_ren$Fuel_pre_post),mean))$value)
  dfsc$tot_NPV<-round(melt(tapply(str_ren$NPVc,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value)
  dfsc$avg_GHG_redn<-round(melt(tapply(str_ren$GHG_redn_cum,list(str_ren$Census.Division,str_ren$Fuel_pre_post),mean))$value,1)
  dfsc$tot_GHG_redn<-round(melt(tapply(str_ren$GHG_redn_cum,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value,1)
  dfsc$abate_cost<-round((-1)*dfsc$tot_NPV/dfsc$tot_GHG_redn,1)
  
  add0<-add[add$Year==2025,c('Census.Division','FuelSwitch','GHG_Redn_Cum_StockTot_Mt','Stock')]
  names(add0)[1:2]<-c('Division','Strategy')
  add0$Division<-gsub('\\.',' ',add0$Division)
  add0[,3]<-round(add0[,3],3)
  
  dfsc<-merge(dfsc,add0)
  
  dfsc<-dfsc[order(dfsc$Strategy),]
  
  dfsc$Grid_Scen<-'MC'
  
  dfsc2<-dfsc[,1:14]
  
  dfsc2$GHGredn_NPV_pos_pc<-round(melt(tapply(str_ren$pos_NPV_GHGredn_LRE,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc2$Length,2)
  dfsc2$GHGredn_NPV_neg_pc<-round(melt(tapply(str_ren$neg_NPV_posGHGredn_LRE,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc2$Length,2)
  dfsc2$GHGinc_NPV_pos_pc<-round(melt(tapply(str_ren$pos_NPV_negGHGredn_LRE,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc2$Length,2)
  dfsc2$GHGinc_NPV_neg_pc<-round(melt(tapply(str_ren$neg_NPV_negGHGredn_LRE,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value/dfsc2$Length,2)
  
  dfsc2$avg_GHG_redn<-round(melt(tapply(str_ren$GHG_redn_cum_LRE,list(str_ren$Census.Division,str_ren$Fuel_pre_post),mean))$value,1)
  dfsc2$tot_GHG_redn<-round(melt(tapply(str_ren$GHG_redn_cum_LRE,list(str_ren$Census.Division,str_ren$Fuel_pre_post),sum))$value,1)
  dfsc2$abate_cost<-round((-1)*dfsc2$tot_NPV/dfsc2$tot_GHG_redn,1)
  
  add0<-add[add$Year==2025,c('Census.Division','FuelSwitch','GHG_Redn_LRE_Cum_StockTot_Mt','Stock')]
  names(add0)[1:3]<-c('Division','Strategy','GHG_Redn_Cum_StockTot_Mt')
  add0$Division<-gsub('\\.',' ',add0$Division)
  add0[,3]<-round(add0[,3],3)
  
  dfsc2<-merge(dfsc2,add0)
  dfsc2<-dfsc2[order(dfsc2$Strategy),]
  
  
  dfsc2$Grid_Scen<-'LREC' 
  
  if (all(names(dfsc)==names(dfsc2))) {dfsc3<-rbind(dfsc,dfsc2)}
  
  # in the end filter to remove NAs and combos with small N
  dfsc3<-dfsc3[dfsc3$Length>4,]
  dfsc3<-dfsc3[complete.cases(dfsc3),]
  
  dfsc3
}

heat_comp_RR<-strat_comp(npv_heat_RRr,div_rr_heat)
dhw_comp_RR<-strat_comp(npv_dhw_RRr,div_rr_dwh)
env_comp_RR<-strat_comp(npv_env_RRr,div_rr_env)
heat_env_comp_RR<-strat_comp(npv_heat_env_RRr,div_rr_heat_env)

# now repeat from beginning for AR ########

load("../Intermediate_results/RenAdvanced_EG.RData")

# # tot GHG reductions per renovation, base, in kg
rs_ARn[,c("redGHGren_base_2025","redGHGren_base_2030","redGHGren_base_2035","redGHGren_base_2040","redGHGren_base_2045","redGHGren_base_2050","redGHGren_base_2055","redGHGren_base_2060")]<-1000*
  (rs_ARn$base_weight*rs_ARn[,c("wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*rs_ARn$redn_GHG_abs

rs_ARn[,c("redGHGren_base_2025_LRE","redGHGren_base_2030_LRE","redGHGren_base_2035_LRE","redGHGren_base_2040_LRE","redGHGren_base_2045_LRE","redGHGren_base_2050_LRE","redGHGren_base_2055_LRE","redGHGren_base_2060_LRE")]<-1000*
  (rs_ARn$base_weight*rs_ARn[,c("wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*rs_ARn$redn_GHG_LRE_abs

# make Water Heater Fuel and Water Heater Efficiency consisent
rs_ARn[rs_ARn$Water.Heater.Efficiency %in% c('Electric Heat Pump, 80 gal'),]$Water.Heater.Fuel<-'Electricity HP'
rs_ARn[rs_ARn$Water.Heater.Efficiency %in% c('Electric Premium','Electric Standard','Electric Tankless'),]$Water.Heater.Fuel<-'Electricity'
rs_ARn[rs_ARn$Water.Heater.Efficiency %in% c('Natural Gas Premium','Natural Gas Standard','Natural Gas Tankless'),]$Water.Heater.Fuel<-'Natural Gas'
rs_ARn[rs_ARn$Water.Heater.Efficiency %in% c('Propane Premium','Propane Standard','Propane Tankless'),]$Water.Heater.Fuel<-'Propane'
rs_ARn[rs_ARn$Water.Heater.Efficiency %in% c('FIXME Fuel Oil Indirect','Fuel Oil Standard','Fuel Oil Premium'),]$Water.Heater.Fuel<-'Fuel Oil'

# extract descriptions of heating systems in the houses with heating renovations only
heatren_AR=cbind(as.data.frame(rs_ARn[which(rs_ARn$change_hren_only_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_ARn[which(rs_ARn$change_hren_only),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(heatren_AR)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
heatren_AR[substring(heatren_AR$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
heatren_AR[substring(heatren_AR$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

heatren_AR$Eff_pre<-paste(heatren_AR$Fuel_pre,heatren_AR$Efficiency_pre,sep="_")
heatren_AR$Eff_post<-paste(heatren_AR$Fuel_post,heatren_AR$Efficiency_post,sep="_")
heatren_AR$pre_post<-paste(heatren_AR$Eff_pre,heatren_AR$Eff_post,sep="->")
heatren_AR$Fuel_pre_post<-paste(heatren_AR$Fuel_pre,heatren_AR$Fuel_post,sep="->")
heatren_AR<-heatren_AR[,c('Year_Building','pre_post','Fuel_pre_post')]

# extract descriptions of water heating systems in the houses with heating renovations only
dhwren_AR=cbind(as.data.frame(rs_ARn[which(rs_ARn$change_wren_only_prev),c('Water.Heater.Fuel','Water.Heater.Efficiency')]),as.data.frame(rs_ARn[which(rs_ARn$change_wren_only),c('Year_Building','Year','Building','Water.Heater.Fuel','Water.Heater.Efficiency')]))

names(dhwren_AR)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')

dhwren_AR$Eff_pre<-paste(dhwren_AR$Fuel_pre,dhwren_AR$Efficiency_pre,sep="_")
dhwren_AR$Eff_post<-paste(dhwren_AR$Fuel_post,dhwren_AR$Efficiency_post,sep="_")
dhwren_AR$pre_post<-paste(dhwren_AR$Eff_pre,dhwren_AR$Eff_post,sep="->")
dhwren_AR$Fuel_pre_post<-paste(dhwren_AR$Fuel_pre,dhwren_AR$Fuel_post,sep="->")
dhwren_AR<-dhwren_AR[,c('Year_Building','pre_post','Fuel_pre_post')]

# now envelope renovations
envren_AR=cbind(as.data.frame(rs_ARn[which(rs_ARn$change_iren_only_prev),c('Geometry.Wall.Type','insulation_crawlspace','insulation_unfinished_attic','insulation_unfinished_basement','insulation_wall')]),
                as.data.frame(rs_ARn[which(rs_ARn$change_iren_only),c('Year_Building','Year','Building','Geometry.Wall.Type','insulation_crawlspace','insulation_unfinished_attic','insulation_unfinished_basement','insulation_wall')]))
names(envren_AR)[2:5]<-paste(names(envren_AR)[2:5],'pre',sep="_")
names(envren_AR)[10:13]<-paste(names(envren_AR)[10:13],'post',sep="_")


envren_AR$Eff_pre<-'unallocated'
envren_AR[envren_AR$Geometry.Wall.Type=='Masonry' & envren_AR$insulation_wall_pre %in% c('Brick, 12-in, 3-wythe, Uninsulated','CMU, 6-in Hollow, Uninsulated'),]$Eff_pre<-'None'
envren_AR[envren_AR$Geometry.Wall.Type=='WoodStud' & envren_AR$insulation_wall_pre == 'Wood Stud, Uninsulated',]$Eff_pre<-'None'

envren_AR[envren_AR$Geometry.Wall.Type=='Masonry' & envren_AR$insulation_wall_pre %in% c('CMU, 6-in Hollow, R-7','CMU, 6-in Hollow, R-11'),]$Eff_pre<-'Moderate'
envren_AR[envren_AR$Geometry.Wall.Type=='WoodStud' & envren_AR$insulation_wall_pre %in% c('Wood Stud, R-7','Wood Stud, R-11'),]$Eff_pre<-'Moderate'

envren_AR[envren_AR$Geometry.Wall.Type=='Masonry' & envren_AR$insulation_wall_pre %in% c('CMU, 6-in Hollow, R-15','CMU, 6-in Hollow, R-19'),]$Eff_pre<-'High'
envren_AR[envren_AR$Geometry.Wall.Type=='WoodStud' & envren_AR$insulation_wall_pre %in% c('Wood Stud, R-15','Wood Stud, R-19','Wood Stud, R-19, R-5 Sheathing'),]$Eff_pre<-'High'

envren_AR$Eff_post<-'unallocated'
envren_AR[envren_AR$Geometry.Wall.Type=='Masonry' & envren_AR$insulation_wall_post %in% c('Brick, 12-in, 3-wythe, Uninsulated','CMU, 6-in Hollow, Uninsulated'),]$Eff_post<-'None'
envren_AR[envren_AR$Geometry.Wall.Type=='WoodStud' & envren_AR$insulation_wall_post == 'Wood Stud, Uninsulated',]$Eff_post<-'None'

envren_AR[envren_AR$Geometry.Wall.Type=='Masonry' & envren_AR$insulation_wall_post %in% c('CMU, 6-in Hollow, R-7','CMU, 6-in Hollow, R-11'),]$Eff_post<-'Moderate'
envren_AR[envren_AR$Geometry.Wall.Type=='WoodStud' & envren_AR$insulation_wall_post %in% c('Wood Stud, R-7','Wood Stud, R-11'),]$Eff_post<-'Moderate'

envren_AR[envren_AR$Geometry.Wall.Type=='Masonry' & envren_AR$insulation_wall_post %in% c('CMU, 6-in Hollow, R-15','CMU, 6-in Hollow, R-19'),]$Eff_post<-'High'
envren_AR[envren_AR$Geometry.Wall.Type=='WoodStud' & envren_AR$insulation_wall_post %in% c('Wood Stud, R-15','Wood Stud, R-19','Wood Stud, R-19, R-5 Sheathing'),]$Eff_post<-'High'

# remove any potential problematic unallocated observations
w<-envren_AR[envren_AR$Eff_pre=='unallocated',]$Building
envren_AR<-envren_AR[envren_AR$Building!=w,]

envren_AR$pre_post<-paste(envren_AR$Eff_pre,envren_AR$Eff_post,sep="->")
envren_AR$Fuel_pre_post<-'NoChange'
envren_AR<-envren_AR[,c('Year_Building','pre_post','Fuel_pre_post')]

# extract descriptions of heating systems in the houses with heating renovations and envelope renovations
heatenvren_AR=cbind(as.data.frame(rs_ARn[which(rs_ARn$change_hren_iren_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_ARn[which(rs_ARn$change_hren_iren),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(heatenvren_AR)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
heatenvren_AR[substring(heatenvren_AR$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
heatenvren_AR[substring(heatenvren_AR$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

heatenvren_AR$Eff_pre<-paste(heatenvren_AR$Fuel_pre,heatenvren_AR$Efficiency_pre,sep="_")
heatenvren_AR$Eff_post<-paste(heatenvren_AR$Fuel_post,heatenvren_AR$Efficiency_post,sep="_")
heatenvren_AR$pre_post<-paste(heatenvren_AR$Eff_pre,heatenvren_AR$Eff_post,sep="->")
heatenvren_AR$Fuel_pre_post<-paste(heatenvren_AR$Fuel_pre,'->',heatenvren_AR$Fuel_post,'_Envelope',sep="")
heatenvren_AR<-heatenvren_AR[,c('Year_Building','pre_post','Fuel_pre_post')]

rs_ARh<-ren_extract(rs_ARn,heatren_AR,'hren')
rs_ARw<-ren_extract(rs_ARn,dhwren_AR,'wren')
rs_ARi<-ren_extract(rs_ARn,envren_AR,'iren')
rs_ARhi<-ren_extract(rs_ARn,heatenvren_AR,'hren_iren')

# summary of reductions by strategy type and census division, renovations starting up to 2035
shr<-sum_redn(rs_ARh,'Census.Division','hren')
div_ar_heat<-shr[[1]]
div_ar_heat_sum<-shr[[2]]
div_ar_heat_highlight<-shr[[3]]

swr<-sum_redn(rs_ARw,'Census.Division','wren')
div_ar_dwh<-swr[[1]]
div_ar_dwh_sum<-swr[[2]]
div_ar_dwh_highlight<-swr[[3]]

sir<-sum_redn(rs_ARi,'Census.Division','iren')
div_ar_env<-sir[[1]]
div_ar_env_sum<-sir[[2]]
div_ar_env_highlight<-sir[[3]]

shir<-sum_redn(rs_ARhi,'Census.Division','hren_iren')
div_ar_heat_env<-shir[[1]]
div_ar_heat_env_sum<-shir[[2]]
div_ar_heat_env_highlight<-shir[[3]]

# NPV calculations
npv_heat_AR<-npv(rs_ARh,'hren',heatCX)
npv_heat_ARr<-npv_heat_AR[npv_heat_AR$change_hren_only==TRUE,]

npv_dhw_AR<-npv(rs_ARw,'wren',dhwCX)
npv_dhw_ARr<-npv_dhw_AR[!is.na(npv_dhw_AR$pre_post),]

npv_env_AR<-npv(rs_ARi,'iren',envCX)
npv_env_ARr<-npv_env_AR[!is.na(npv_env_AR$pre_post),]

npv_heat_env_AR<-npv(rs_ARhi,'hren_iren',envCX,heatCX)
npv_heat_env_ARr<-npv_heat_env_AR[!is.na(npv_heat_env_AR$pre_post),]

heat_comp_AR<-strat_comp(npv_heat_ARr,div_ar_heat)
dhw_comp_AR<-strat_comp(npv_dhw_ARr,div_ar_dwh)
env_comp_AR<-strat_comp(npv_env_ARr,div_ar_env)
heat_env_comp_AR<-strat_comp(npv_heat_env_ARr,div_ar_heat_env)

# rm(check,check2,df,df0,df1,dfsc,dfsc2,dfsc3,str_ren,unall)
# now repeat for ER ########
load("../Intermediate_results/RenExtElec_EG.RData")

# # tot GHG reductions per renovation, base, in kg
rs_ERn[,c("redGHGren_base_2025","redGHGren_base_2030","redGHGren_base_2035","redGHGren_base_2040","redGHGren_base_2045","redGHGren_base_2050","redGHGren_base_2055","redGHGren_base_2060")]<-1000*
  (rs_ERn$base_weight*rs_ERn[,c("wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*rs_ERn$redn_GHG_abs

rs_ERn[,c("redGHGren_base_2025_LRE","redGHGren_base_2030_LRE","redGHGren_base_2035_LRE","redGHGren_base_2040_LRE","redGHGren_base_2045_LRE","redGHGren_base_2050_LRE","redGHGren_base_2055_LRE","redGHGren_base_2060_LRE")]<-1000*
  (rs_ERn$base_weight*rs_ERn[,c("wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*rs_ERn$redn_GHG_LRE_abs

# make Water Heater Fuel and Water Heater Efficiency consisent
rs_ERn[rs_ERn$Water.Heater.Efficiency %in% c('Electric Heat Pump, 80 gal'),]$Water.Heater.Fuel<-'Electricity HP'
rs_ERn[rs_ERn$Water.Heater.Efficiency %in% c('Electric Premium','Electric Standard','Electric Tankless'),]$Water.Heater.Fuel<-'Electricity'
rs_ERn[rs_ERn$Water.Heater.Efficiency %in% c('Natural Gas Premium','Natural Gas Standard','Natural Gas Tankless'),]$Water.Heater.Fuel<-'Natural Gas'
rs_ERn[rs_ERn$Water.Heater.Efficiency %in% c('Propane Premium','Propane Standard','Propane Tankless'),]$Water.Heater.Fuel<-'Propane'
rs_ERn[rs_ERn$Water.Heater.Efficiency %in% c('FIXME Fuel Oil Indirect','Fuel Oil Standard','Fuel Oil Premium'),]$Water.Heater.Fuel<-'Fuel Oil'

# extract descriptions of heating systems in the houses with heating renovations only
heatren_ER=cbind(as.data.frame(rs_ERn[which(rs_ERn$change_hren_only_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_ERn[which(rs_ERn$change_hren_only),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(heatren_ER)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
heatren_ER[substring(heatren_ER$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
heatren_ER[substring(heatren_ER$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

heatren_ER$Eff_pre<-paste(heatren_ER$Fuel_pre,heatren_ER$Efficiency_pre,sep="_")
heatren_ER$Eff_post<-paste(heatren_ER$Fuel_post,heatren_ER$Efficiency_post,sep="_")
heatren_ER$pre_post<-paste(heatren_ER$Eff_pre,heatren_ER$Eff_post,sep="->")
heatren_ER$Fuel_pre_post<-paste(heatren_ER$Fuel_pre,heatren_ER$Fuel_post,sep="->")
heatren_ER<-heatren_ER[,c('Year_Building','pre_post','Fuel_pre_post')]

# extract descriptions of water heating systems in the houses with heating renovations only
dhwren_ER=cbind(as.data.frame(rs_ERn[which(rs_ERn$change_wren_only_prev),c('Water.Heater.Fuel','Water.Heater.Efficiency')]),as.data.frame(rs_ERn[which(rs_ERn$change_wren_only),c('Year_Building','Year','Building','Water.Heater.Fuel','Water.Heater.Efficiency')]))

names(dhwren_ER)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')

dhwren_ER$Eff_pre<-paste(dhwren_ER$Fuel_pre,dhwren_ER$Efficiency_pre,sep="_")
dhwren_ER$Eff_post<-paste(dhwren_ER$Fuel_post,dhwren_ER$Efficiency_post,sep="_")
dhwren_ER$pre_post<-paste(dhwren_ER$Eff_pre,dhwren_ER$Eff_post,sep="->")
dhwren_ER$Fuel_pre_post<-paste(dhwren_ER$Fuel_pre,dhwren_ER$Fuel_post,sep="->")
dhwren_ER<-dhwren_ER[,c('Year_Building','pre_post','Fuel_pre_post')]

# now envelope renovations
envren_ER=cbind(as.data.frame(rs_ERn[which(rs_ERn$change_iren_only_prev),c('Geometry.Wall.Type','insulation_crawlspace','insulation_unfinished_attic','insulation_unfinished_basement','insulation_wall')]),
                as.data.frame(rs_ERn[which(rs_ERn$change_iren_only),c('Year_Building','Year','Building','Geometry.Wall.Type','insulation_crawlspace','insulation_unfinished_attic','insulation_unfinished_basement','insulation_wall')]))
names(envren_ER)[2:5]<-paste(names(envren_ER)[2:5],'pre',sep="_")
names(envren_ER)[10:13]<-paste(names(envren_ER)[10:13],'post',sep="_")


envren_ER$Eff_pre<-'unallocated'
envren_ER[envren_ER$Geometry.Wall.Type=='Masonry' & envren_ER$insulation_wall_pre %in% c('Brick, 12-in, 3-wythe, Uninsulated','CMU, 6-in Hollow, Uninsulated'),]$Eff_pre<-'None'
envren_ER[envren_ER$Geometry.Wall.Type=='WoodStud' & envren_ER$insulation_wall_pre == 'Wood Stud, Uninsulated',]$Eff_pre<-'None'

envren_ER[envren_ER$Geometry.Wall.Type=='Masonry' & envren_ER$insulation_wall_pre %in% c('CMU, 6-in Hollow, R-7','CMU, 6-in Hollow, R-11'),]$Eff_pre<-'Moderate'
envren_ER[envren_ER$Geometry.Wall.Type=='WoodStud' & envren_ER$insulation_wall_pre %in% c('Wood Stud, R-7','Wood Stud, R-11'),]$Eff_pre<-'Moderate'

envren_ER[envren_ER$Geometry.Wall.Type=='Masonry' & envren_ER$insulation_wall_pre %in% c('CMU, 6-in Hollow, R-15','CMU, 6-in Hollow, R-19'),]$Eff_pre<-'High'
envren_ER[envren_ER$Geometry.Wall.Type=='WoodStud' & envren_ER$insulation_wall_pre %in% c('Wood Stud, R-15','Wood Stud, R-19','Wood Stud, R-19, R-5 Sheathing'),]$Eff_pre<-'High'

envren_ER$Eff_post<-'unallocated'
envren_ER[envren_ER$Geometry.Wall.Type=='Masonry' & envren_ER$insulation_wall_post %in% c('Brick, 12-in, 3-wythe, Uninsulated','CMU, 6-in Hollow, Uninsulated'),]$Eff_post<-'None'
envren_ER[envren_ER$Geometry.Wall.Type=='WoodStud' & envren_ER$insulation_wall_post == 'Wood Stud, Uninsulated',]$Eff_post<-'None'

envren_ER[envren_ER$Geometry.Wall.Type=='Masonry' & envren_ER$insulation_wall_post %in% c('CMU, 6-in Hollow, R-7','CMU, 6-in Hollow, R-11'),]$Eff_post<-'Moderate'
envren_ER[envren_ER$Geometry.Wall.Type=='WoodStud' & envren_ER$insulation_wall_post %in% c('Wood Stud, R-7','Wood Stud, R-11'),]$Eff_post<-'Moderate'

envren_ER[envren_ER$Geometry.Wall.Type=='Masonry' & envren_ER$insulation_wall_post %in% c('CMU, 6-in Hollow, R-15','CMU, 6-in Hollow, R-19'),]$Eff_post<-'High'
envren_ER[envren_ER$Geometry.Wall.Type=='WoodStud' & envren_ER$insulation_wall_post %in% c('Wood Stud, R-15','Wood Stud, R-19','Wood Stud, R-19, R-5 Sheathing'),]$Eff_post<-'High'

# remove any potential problematic unallocated observations
w<-envren_ER[envren_ER$Eff_pre=='unallocated',]$Building
envren_ER<-envren_ER[envren_ER$Building!=w,]

envren_ER$pre_post<-paste(envren_ER$Eff_pre,envren_ER$Eff_post,sep="->")
envren_ER$Fuel_pre_post<-'NoChange'
envren_ER<-envren_ER[,c('Year_Building','pre_post','Fuel_pre_post')]

# extract descriptions of heating systems in the houses with heating renovations and envelope renovations
heatenvren_ER=cbind(as.data.frame(rs_ERn[which(rs_ERn$change_hren_iren_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_ERn[which(rs_ERn$change_hren_iren),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(heatenvren_ER)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
heatenvren_ER[substring(heatenvren_ER$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
heatenvren_ER[substring(heatenvren_ER$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

heatenvren_ER$Eff_pre<-paste(heatenvren_ER$Fuel_pre,heatenvren_ER$Efficiency_pre,sep="_")
heatenvren_ER$Eff_post<-paste(heatenvren_ER$Fuel_post,heatenvren_ER$Efficiency_post,sep="_")
heatenvren_ER$pre_post<-paste(heatenvren_ER$Eff_pre,heatenvren_ER$Eff_post,sep="->")
heatenvren_ER$Fuel_pre_post<-paste(heatenvren_ER$Fuel_pre,'->',heatenvren_ER$Fuel_post,'_Envelope',sep="")
heatenvren_ER<-heatenvren_ER[,c('Year_Building','pre_post','Fuel_pre_post')]

rs_ERh<-ren_extract(rs_ERn,heatren_ER,'hren')
rs_ERw<-ren_extract(rs_ERn,dhwren_ER,'wren')
rs_ERi<-ren_extract(rs_ERn,envren_ER,'iren')
rs_ERhi<-ren_extract(rs_ERn,heatenvren_ER,'hren_iren')

# summary of reductions by strategy type and census division, renovations starting up to 2035
shr<-sum_redn(rs_ERh,'Census.Division','hren')
div_er_heat<-shr[[1]]
div_er_heat_sum<-shr[[2]]
div_er_heat_highlight<-shr[[3]]

swr<-sum_redn(rs_ERw,'Census.Division','wren')
div_er_dwh<-swr[[1]]
div_er_dwh_sum<-swr[[2]]
div_er_dwh_highlight<-swr[[3]]

sir<-sum_redn(rs_ERi,'Census.Division','iren')
div_er_env<-sir[[1]]
div_er_env_sum<-sir[[2]]
div_er_env_highlight<-sir[[3]]

shir<-sum_redn(rs_ERhi,'Census.Division','hren_iren')
div_er_heat_env<-shir[[1]]
div_er_heat_env_sum<-shir[[2]]
div_er_heat_env_highlight<-shir[[3]]

# NPV calculations
npv_heat_ER<-npv(rs_ERh,'hren',heatCX)
npv_heat_ERr<-npv_heat_ER[npv_heat_ER$change_hren_only==TRUE,]

npv_dhw_ER<-npv(rs_ERw,'wren',dhwCX)
npv_dhw_ERr<-npv_dhw_ER[!is.na(npv_dhw_ER$pre_post),]

npv_env_ER<-npv(rs_ERi,'iren',envCX)
npv_env_ERr<-npv_env_ER[!is.na(npv_env_ER$pre_post),]

npv_heat_env_ER<-npv(rs_ERhi,'hren_iren',envCX,heatCX)
npv_heat_env_ERr<-npv_heat_env_ER[!is.na(npv_heat_env_ER$pre_post),]

heat_comp_ER<-strat_comp(npv_heat_ERr,div_er_heat)
dhw_comp_ER<-strat_comp(npv_dhw_ERr,div_er_dwh)
env_comp_ER<-strat_comp(npv_env_ERr,div_er_env)
heat_env_comp_ER<-strat_comp(npv_heat_env_ERr,div_er_heat_env)

save(heat_comp_RR,dhw_comp_RR,env_comp_RR,heat_env_comp_RR,
     heat_comp_AR,dhw_comp_AR,env_comp_AR,heat_env_comp_AR,
     heat_comp_ER,dhw_comp_ER,env_comp_ER,heat_env_comp_ER,
     file='../Final_results/ren_strat_comp.RData')

# also save as multiple tabs in an excel file
library(writexl)

write_xlsx(list(heat_comp_RR = heat_comp_RR, dhw_comp_RR = dhw_comp_RR, env_comp_RR = env_comp_RR,heat_env_comp_RR = heat_env_comp_RR,
                heat_comp_AR = heat_comp_AR, dhw_comp_AR = dhw_comp_AR, env_comp_AR = env_comp_AR,heat_env_comp_AR = heat_env_comp_AR,
                heat_comp_ER = heat_comp_ER, dhw_comp_ER = dhw_comp_ER, env_comp_ER = env_comp_ER,heat_env_comp_ER = heat_env_comp_ER),
           "../Final_results/ren_strat_comp.xlsx",format_headers = FALSE)


# also save the summary files
save(div_rr_heat_sum,div_rr_dwh_sum,div_rr_env_sum,div_rr_heat_env_sum,
     div_ar_heat_sum,div_ar_dwh_sum,div_ar_env_sum,div_ar_heat_env_sum,
     div_er_heat_sum,div_er_dwh_sum,div_er_env_sum,div_er_heat_env_sum,
     file='../Final_results/ren_strat_summ.RData')

# and finally the npv files
save(npv_heat_RRr,npv_dhw_RRr,npv_env_RRr,npv_heat_env_RRr,
     npv_heat_ARr,npv_dhw_ARr,npv_env_ARr,npv_heat_env_ARr,
     npv_heat_ERr,npv_dhw_ERr,npv_env_ERr,npv_heat_env_ERr,
     file='../Final_results/ren_NPV.RData')


# additional results aggregating and processing #######
load('../Final_results/ren_NPV.RData')
npv_heat_RRr$Ren<-'RR'
npv_heat_ARr$Ren<-'AR'
npv_heat_ERr$Ren<-'ER'

npv_dhw_RRr$Ren<-'RR'
npv_dhw_ARr$Ren<-'AR'
npv_dhw_ERr$Ren<-'ER'

npv_env_RRr$Ren<-'RR'
npv_env_ARr$Ren<-'AR'
npv_env_ERr$Ren<-'ER'

npv_heat_env_RRr$Ren<-'RR'
npv_heat_env_ARr$Ren<-'AR'
npv_heat_env_ERr$Ren<-'ER'

heat_all<-rbind(npv_heat_RRr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
                npv_heat_ARr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
                npv_heat_ERr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')])

dhw_all<-rbind(npv_dhw_RRr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
                npv_dhw_ARr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
                npv_dhw_ERr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')])

env_all<-rbind(npv_env_RRr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
               npv_env_ARr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
               npv_env_ERr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')])

heat_env_all<-rbind(npv_heat_env_RRr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
                npv_heat_env_ARr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')],
                npv_heat_env_ERr[,c('Year_Building','Year','Building','Census.Division','Fuel_pre_post','pre_post','NPVc','GHG_redn_cum','GHG_redn_cum_LRE','GHG_abate_cost','GHG_abate_cost_LREC','Ren')])


heat_all$Type<-'heat'
dhw_all$Type<-'dhw'
env_all$Type<-'env'
heat_env_all$Type<-'heat_env'

heat_all$Strategy<-heat_all$Fuel_pre_post
dhw_all$Strategy<-dhw_all$Fuel_pre_post
env_all$Strategy<-env_all$pre_post
heat_env_all$Strategy<-heat_env_all$Fuel_pre_post

summary_all<-rbind(heat_all,dhw_all,env_all,heat_env_all)

summary_all$Type_Strategy<-paste(summary_all$Type,summary_all$Strategy,sep="_")

# what percentage of renovations do we remove by the filter, currentky 0.06%
100*sum(abs(summary_all$GHG_redn_cum_LRE)<0.001)/nrow(summary_all)

summary_all<-summary_all[abs(summary_all$GHG_redn_cum_LRE)>0.001,]

tdg<-round(as.data.frame(tapply(summary_all$GHG_redn_cum_LRE,list(summary_all$Type,summary_all$Census.Division),median)),1)
tdg$Type<-rownames(tdg)
tdgm<-melt(tdg)
names(tdgm)[3]<-'GHG_redn_t'

tdgr<-round(as.data.frame(tapply(summary_all$GHG_redn_cum_LRE,list(summary_all$Type,summary_all$Census.Division,summary_all$Ren),median)),1)
tdgr$Type<-rownames(tdgr)
tdgrm<-melt(tdgr)
tdgrm$Ren<-str_sub(tdgrm$variable,-2)
tdgrm$variable<-str_sub(tdgrm$variable,1,-4)
names(tdgrm)[3]<-'GHG_redn_t'

tdn<-round(as.data.frame(tapply(summary_all$NPVc,list(summary_all$Type,summary_all$Census.Division),median)),1)
tdn$Type<-rownames(tdn)
tdnm<-melt(tdn)
names(tdnm)[3]<-'NPV_USD'

tda<-round(as.data.frame(tapply(summary_all$GHG_abate_cost_LREC,list(summary_all$Type,summary_all$Census.Division),median)),1)
tda$Type<-rownames(tda)
tdam<-melt(tda)
names(tdam)[3]<-'AbateCost_USD_t'

td<-merge(merge(tdgm,tdnm),tdam)
write.csv(td,'../Final_results/ren_div_sum.csv')

hsd<-round(as.data.frame(tapply(heat_all$GHG_redn_cum_LRE,list(heat_all$Fuel_pre_post,heat_all$Census.Division),mean)),1)
hsd$FuelSwitch<-rownames(hsd)

hsdl<-as.data.frame(tapply(heat_all$GHG_redn_cum_LRE,list(heat_all$Fuel_pre_post,heat_all$Census.Division),length))
which(rowSums(hsdl,na.rm = TRUE)>200)

hsd<-hsd[as.numeric(which(rowSums(hsdl,na.rm = TRUE)>190)),]

heat_strategies<-names(which(rowSums(hsdl,na.rm = TRUE)>190))

wsd<-round(as.data.frame(tapply(dhw_all$GHG_redn_cum_LRE,list(dhw_all$Fuel_pre_post,dhw_all$Census.Division),mean)),1)
wsd$FuelSwitch<-rownames(wsd)

wsdl<-as.data.frame(tapply(dhw_all$GHG_redn_cum_LRE,list(dhw_all$Fuel_pre_post,dhw_all$Census.Division),length))
which(rowSums(wsdl,na.rm = TRUE)>200)

wsd<-wsd[as.numeric(which(rowSums(wsdl,na.rm = TRUE)>190)),]

dhw_strategies<-c(names(which(rowSums(wsdl,na.rm = TRUE)>190)),'Fuel Oil->Natural Gas','Propane->Electricity HP')

hesd<-round(as.data.frame(tapply(heat_env_all$GHG_redn_cum_LRE,list(heat_env_all$Fuel_pre_post,heat_env_all$Census.Division),mean)),1)
hesd$FuelSwitch<-rownames(hesd)

hesdl<-as.data.frame(tapply(heat_env_all$GHG_redn_cum_LRE,list(heat_env_all$Fuel_pre_post,heat_env_all$Census.Division),length))
which(rowSums(hesdl,na.rm = TRUE)>100)

hesd<-hesd[as.numeric(which(rowSums(hesdl,na.rm = TRUE)>100)),]

heat_env_strategies<-names(which(rowSums(hesdl,na.rm = TRUE)>100))

divs<-data.frame(Census.Division=c('East North Central','East South Central','Middle Atlantic','Mountain','New England','Pacific','South Atlantic','West North Central','West South Central'),
                 CD_Abbr=c('ENC','ESC','MA','MT','NE','PAC','SA','WNC','WSC'))

heat_all_plot<-merge(heat_all,divs)
dhw_all_plot<-merge(dhw_all,divs)
env_all_plot<-merge(env_all,divs)
heat_env_all_plot<-merge(heat_env_all,divs)


for (h in heat_strategies) {
  df<-heat_all_plot[heat_all_plot$Strategy==h,]
  l<-quantile(df$GHG_redn_cum_LRE, c(0.01, 0.99))
  df[df$GHG_redn_cum_LRE<l[1],]$GHG_redn_cum_LRE<-l[1]
  df[df$GHG_redn_cum_LRE>l[2],]$GHG_redn_cum_LRE<-l[2]

  l2<-quantile(df$NPVc, c(0.01, 0.99))
  df[df$NPVc<l2[1],]$NPVc<-l2[1]
  df[df$NPVc>l2[2],]$NPVc<-l2[2]
  
  l3<-quantile(df$GHG_abate_cost_LREC, c(0.05, 0.95))
  df[df$GHG_abate_cost_LREC<l3[1],]$GHG_abate_cost_LREC<-l3[1]
  df[df$GHG_abate_cost_LREC>l3[2],]$GHG_abate_cost_LREC<-l3[2]
  
  heat_all_plot[heat_all_plot$Strategy==h,]<-df
}

windows()
ggplot(heat_all_plot[heat_all_plot$Strategy %in% heat_strategies,],aes(x=CD_Abbr,y=GHG_redn_cum_LRE)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol = 3) + 
  geom_hline(yintercept=0,color='red') + labs(title = "a) Cumulative 25-year household GHG emission reductions of Heating Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='tCO2e') +
  theme(axis.text=element_text(size=8))+ theme_bw()

# windows()
ggplot(heat_all_plot[heat_all_plot$Strategy %in% heat_strategies,],aes(x=CD_Abbr,y=0.001*NPVc)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "b) NPV of Heating Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='NPV (1,000 2021$)') + theme(axis.text=element_text(size=8)) + theme_bw() 

# windows()
ggplot(heat_all_plot[heat_all_plot$Strategy %in% heat_strategies,],aes(x=CD_Abbr,y=GHG_abate_cost_LREC)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "c) GHG abatement cost of Heating Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='2021$/tCO2e') + theme(axis.text=element_text(size=8)) + theme_bw() 

# hot water

for (h in dhw_strategies) {
  df<-dhw_all_plot[dhw_all_plot$Strategy==h,]
  l<-quantile(df$GHG_redn_cum_LRE, c(0.02, 0.98))
  df[df$GHG_redn_cum_LRE<l[1],]$GHG_redn_cum_LRE<-l[1]
  df[df$GHG_redn_cum_LRE>l[2],]$GHG_redn_cum_LRE<-l[2]
  # dhw_all_plot[dhw_all_plot$Strategy==h,]<-df
  
  l2<-quantile(df$NPVc, c(0.01, 0.99))
  df[df$NPVc<l2[1],]$NPVc<-l2[1]
  df[df$NPVc>l2[2],]$NPVc<-l2[2]
  
  l3<-quantile(df$GHG_abate_cost_LREC, c(0.05, 0.95))
  df[df$GHG_abate_cost_LREC<l3[1],]$GHG_abate_cost_LREC<-l3[1]
  df[df$GHG_abate_cost_LREC>l3[2],]$GHG_abate_cost_LREC<-l3[2]
  
  dhw_all_plot[dhw_all_plot$Strategy==h,]<-df
}
# if we were to include FO-HP, in MA and NE the median is >10
# negative emission reductions in Electric->Electric DHW replacements almost exclusively come from swapping to electric tankless water heaters
# windows()
ggplot(dhw_all_plot[dhw_all_plot$Strategy %in% dhw_strategies,],aes(x=CD_Abbr,y=GHG_redn_cum_LRE)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol = 3) + 
  geom_hline(yintercept=0,color='red') + labs(title = "a) Cumulative 25-year household GHG emission reductions of Hot Water Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='tCO2e') +
  theme(axis.text=element_text(size=8))+ theme_bw()

#  if we were to include FO-HP, in MA positive median NPV, around 0.25k, in NE negative NPV, around -1.25k
# windows()
ggplot(dhw_all_plot[dhw_all_plot$Strategy %in% dhw_strategies,],aes(x=CD_Abbr,y=0.001*NPVc)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "b) NPV of Hot Water Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='NPV (1,000 2021$)') + theme(axis.text=element_text(size=8)) + theme_bw() 

# windows()
ggplot(dhw_all_plot[dhw_all_plot$Strategy %in% dhw_strategies,],aes(x=CD_Abbr,y=GHG_abate_cost_LREC)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "c) GHG abatement cost of Hot Water Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='2021$/tCO2e') + theme(axis.text=element_text(size=8)) + theme_bw() 

# envelope
for (h in unique(env_all_plot$Strategy)) {
  df<-env_all_plot[env_all_plot$Strategy==h,]
  
  l<-quantile(df$GHG_redn_cum_LRE, c(0.01, 0.99))
  df[df$GHG_redn_cum_LRE<l[1],]$GHG_redn_cum_LRE<-l[1]
  df[df$GHG_redn_cum_LRE>l[2],]$GHG_redn_cum_LRE<-l[2]
  
  l2<-quantile(df$NPVc, c(0.01, 0.99))
  df[df$NPVc<l2[1],]$NPVc<-l2[1]
  df[df$NPVc>l2[2],]$NPVc<-l2[2]
  

  l3<-quantile(df$GHG_abate_cost_LREC, c(0.05, 0.95))
  df[df$GHG_abate_cost_LREC<l3[1],]$GHG_abate_cost_LREC<-l3[1]
  df[df$GHG_abate_cost_LREC>l3[2],]$GHG_abate_cost_LREC<-l3[2]
  
  env_all_plot[env_all_plot$Strategy==h,]<-df
}

windows()
ggplot(env_all_plot,aes(x=CD_Abbr,y=GHG_redn_cum_LRE)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol = 3) + 
  geom_hline(yintercept=0,color='red') + labs(title = "a) Cumulative 25-year household GHG emission reductions of Envelope Renovations by Wall Insulation Level and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='tCO2e') +
  theme(axis.text=element_text(size=8))+ theme_bw()

ggplot(env_all_plot,aes(x=CD_Abbr,y=0.001*NPVc)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "b) NPV of Envelope Renovations by Wall Insulation Level and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='NPV (1,000 2021$)') + theme(axis.text=element_text(size=8)) + theme_bw() 

ggplot(env_all_plot,aes(x=CD_Abbr,y=GHG_abate_cost_LREC)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "c) GHG abatement cost of Envelope Renovations by Wall Insulation Level and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='2021$/tCO2e') + theme(axis.text=element_text(size=8)) + theme_bw() 

env_ac_med<-tapply(env_all_plot$GHG_abate_cost_LREC,list(env_all_plot$CD_Abbr,env_all_plot$Strategy),median)

# heat and envelope

for (h in heat_env_strategies) {
  df<-heat_env_all_plot[heat_env_all_plot$Strategy==h,]
  l<-quantile(df$GHG_redn_cum_LRE, c(0.02, 0.98))
  df[df$GHG_redn_cum_LRE<l[1],]$GHG_redn_cum_LRE<-l[1]
  df[df$GHG_redn_cum_LRE>l[2],]$GHG_redn_cum_LRE<-l[2]
  
  l2<-quantile(df$NPVc, c(0.01, 0.99))
  df[df$NPVc<l2[1],]$NPVc<-l2[1]
  df[df$NPVc>l2[2],]$NPVc<-l2[2]
  
  l3<-quantile(df$GHG_abate_cost_LREC, c(0.05, 0.95))
  df[df$GHG_abate_cost_LREC<l3[1],]$GHG_abate_cost_LREC<-l3[1]
  df[df$GHG_abate_cost_LREC>l3[2],]$GHG_abate_cost_LREC<-l3[2]
  
  heat_env_all_plot[heat_env_all_plot$Strategy==h,]<-df
}

windows()
ggplot(heat_env_all_plot[heat_env_all_plot$Strategy %in% heat_env_strategies,],aes(x=CD_Abbr,y=GHG_redn_cum_LRE)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol = 3) + 
  geom_hline(yintercept=0,color='red') + labs(title = "a) Cumulative 25-year household GHG emission reductions of Heating & Envelope Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='tCO2e') +
  theme(axis.text=element_text(size=8))+ theme_bw()

heatenv_ghg_med<-tapply(heat_env_all_plot$GHG_redn_cum_LRE,list(heat_env_all_plot$CD_Abbr,heat_env_all_plot$Strategy),median)
#windows()
ggplot(heat_env_all_plot[heat_env_all_plot$Strategy %in% heat_env_strategies,],aes(x=CD_Abbr,y=0.001*NPVc)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "b) NPV of Heating & Envelope Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='NPV (1,000 2021$)') + theme(axis.text=element_text(size=8)) + theme_bw() 


#windows()
ggplot(heat_env_all_plot[heat_env_all_plot$Strategy %in% heat_env_strategies,],aes(x=CD_Abbr,y=GHG_abate_cost_LREC)) +  geom_boxplot(outlier.color='grey',outlier.size = 1) + facet_wrap(~Strategy,scale='free',ncol=3) + scale_y_continuous(labels=scales::comma_format()) + 
  geom_hline(yintercept=0,color='red') +labs(title = "c) GHG abatement cost of Heating & Envelope Renovations by Fuel-Switch and Division",subtitle = 'For renovations occuring between 2021-2025',x='Census Division',y='2021$/tCO2e') + theme(axis.text=element_text(size=8)) + theme_bw() 

heatenv_ac_med<-tapply(heat_env_all_plot$GHG_abate_cost_LREC,list(heat_env_all_plot$CD_Abbr,heat_env_all_plot$Strategy),median)
q75<-function(x) {q=quantile(x,0.75); q}
tapply(heat_env_all_plot$GHG_abate_cost_LREC,list(heat_env_all_plot$CD_Abbr,heat_env_all_plot$Strategy),q75)