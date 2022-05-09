# revised script to assess comparison of scenarios for particular stock segments
# March 6 2022
# base on RS_results_all_rev

# for now I exclude the hiMF stock scenarios from this analysis


library(ggplot2)
library(dplyr)
library(reshape2)
library(RColorBrewer)
library(openxlsx)
library(stringr)
library(sjPlot)
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")


# Last Update Peter Berrill May 6 2022

# Purpose: Assess GHG reductions from scenarios, for particular combinations, geographical and housing stock based. Make some linear models to help assess the main influences on emission reductions in different scenarios

# Inputs: - ExtData/US_FA_GHG_summaries.RData, floor area and GHG summaries from housing stock model (HSM)
#         - Yale Courses/Research/Final Paper/HSM_github/HSM_results/County_Scenario_SM_Results_Summary.RData, greater details from HSM
#         - ExtData/ctycode.RData, county names and fips codes
#         - Yale Courses/Research/Final Paper/HSM_github/HSM_results/County_FloorArea_Mat.RData, more details from HSM
#         - Final_results/renGHG_cty_type.RData, embodied emissions from renovations
#         - Final_results/res_base_RR.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_base_AR.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_base_ER.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_hiDR_RR.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_hiDR_AR.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_hiDR_ER.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_hiMF_RR.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_hiMF_AR.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/res_hiMF_ER.RData, energy and emissions for specific stock and renovation scenario combination, produced by RS_results_proj_new_rev_fn
#         - Final_results/StockCountComp.RData, comparison stock counts by state and house type housing stock projections

# Outputs: 
#         - Final_results/GHG_scen_comp_StateCty.RData


# not in function
'%!in%' <- function(x,y)!('%in%'(x,y))
# load in results
# first of all embodied/new construction emissions for 6 housing stock scenarios
# these need to be by county and house type
load("../ExtData/US_FA_GHG_summaries.RData")
# get summary about population growth
load("~/Yale Courses/Research/Final Paper/HSM_github/HSM_results/County_Scenario_SM_Results_Summary.RData") # large file, based on the analysis here https://github.com/peterberr/US_county_HSM
load("../ExtData/ctycode.RData")

smop_base_small$pop_2020<-0
smop_base_small$pop_2060<-0

smop_base_small$pop_growth_abs<-0
smop_base_small$pop_growth_pc<-0

for (k in 1:3142) {
  smop_base_small$pop_2020[k]<-smop_base_small[[3]][[k]]$Population[1]
  smop_base_small$pop_2060[k]<-smop_base_small[[3]][[k]]$Population[41]
  
  
  smop_base_small$pop_growth_abs[k]<-smop_base_small[[3]][[k]]$Population[41]-smop_base_small[[3]][[k]]$Population[1]
  smop_base_small$pop_growth_pc[k]<-smop_base_small[[3]][[k]]$Population[41]/smop_base_small[[3]][[k]]$Population[1]-1
}
smop_base_small<-merge(smop_base_small,ctycode)
pop_summ<-smop_base_small[,c('RS_ID','pop_2020','pop_growth_abs','pop_growth_pc')]
names(pop_summ)[1]<-'County'

smop_base_small$State<-substr(smop_base_small$RS_ID,1,2)
pop_sum_state<-data.frame(pop2020=tapply(smop_base_small$pop_2020,smop_base_small$State,sum),
                          pop2060=tapply(smop_base_small$pop_2060,smop_base_small$State,sum))
pop_sum_state$State<-rownames(pop_sum_state)
pop_sum_state<-pop_sum_state[pop_sum_state$State %!in% c('AK','HI'),]
pop_sum_state$pop_growth_abs<-pop_sum_state$pop2060-pop_sum_state$pop2020
pop_sum_state$pop_growth_pc<-pop_sum_state$pop2060/pop_sum_state$pop2020-1

pop_sum_state<-pop_sum_state[,c('State','pop_growth_abs','pop_growth_pc')]

load("~/Yale Courses/Research/Final Paper/HSM_github/HSM_results/County_FloorArea_Mat.RData") # large file, based on the analysis here https://github.com/peterberr/US_county_HSM
cty_GHG<-smop_base_FA[,c('GeoID','RS_ID')]
cty_GHG[,c('GHG_SF_base','GHG_MF_base','GHG_MH_base','GHG_Tot_base',
           'GHG_SF_hiDR','GHG_MF_hiDR','GHG_MH_hiDR','GHG_Tot_hiDR',
           'GHG_SF_hiMF','GHG_MF_hiMF','GHG_MH_hiMF','GHG_Tot_hiMF',
           'GHG_SF_base_RFA','GHG_MF_base_RFA','GHG_MH_base_RFA','GHG_Tot_base_RFA',
           'GHG_SF_hiDR_RFA','GHG_MF_hiDR_RFA','GHG_MH_hiDR_RFA','GHG_Tot_hiDR_RFA',
           'GHG_SF_hiMF_RFA','GHG_MF_hiMF_RFA','GHG_MH_hiMF_RFA','GHG_Tot_hiMF_RFA')]<-0
for (k in 1:3108) {
  cty_GHG[k,c('GHG_SF_base','GHG_MF_base','GHG_MH_base','GHG_Tot_base')]<-
    1e-9*c(sum(smop_base_FA[[3]][[k]][,'GHG_NC_SF']),sum(smop_base_FA[[3]][[k]][,'GHG_NC_MF']),sum(smop_base_FA[[3]][[k]][,'GHG_NC_MH']),sum(smop_base_FA[[3]][[k]][,'GHG_NC']))
  
  cty_GHG[k,c('GHG_SF_hiDR','GHG_MF_hiDR','GHG_MH_hiDR','GHG_Tot_hiDR')]<-
    1e-9*c(sum(smop_hiDR_FA[[3]][[k]][,'GHG_NC_SF']),sum(smop_hiDR_FA[[3]][[k]][,'GHG_NC_MF']),sum(smop_hiDR_FA[[3]][[k]][,'GHG_NC_MH']),sum(smop_hiDR_FA[[3]][[k]][,'GHG_NC']))
  
  cty_GHG[k,c('GHG_SF_hiMF','GHG_MF_hiMF','GHG_MH_hiMF','GHG_Tot_hiMF')]<-
    1e-9*c(sum(smop_hiMF_FA[[3]][[k]][,'GHG_NC_SF']),sum(smop_hiMF_FA[[3]][[k]][,'GHG_NC_MF']),sum(smop_hiMF_FA[[3]][[k]][,'GHG_NC_MH']),sum(smop_hiMF_FA[[3]][[k]][,'GHG_NC']))
  
  cty_GHG[k,c('GHG_SF_base_RFA','GHG_MF_base_RFA','GHG_MH_base_RFA','GHG_Tot_base_RFA')]<-
    1e-9*c(sum(smop_RFA_FA[[3]][[k]][,'GHG_NC_SF']),sum(smop_RFA_FA[[3]][[k]][,'GHG_NC_MF']),sum(smop_RFA_FA[[3]][[k]][,'GHG_NC_MH']),sum(smop_RFA_FA[[3]][[k]][,'GHG_NC']))
  
  
  cty_GHG[k,c('GHG_SF_hiDR_RFA','GHG_MF_hiDR_RFA','GHG_MH_hiDR_RFA','GHG_Tot_hiDR_RFA')]<-
    1e-9*c(sum(smop_hiDR_RFA_FA[[3]][[k]][,'GHG_NC_SF']),sum(smop_hiDR_RFA_FA[[3]][[k]][,'GHG_NC_MF']),sum(smop_hiDR_RFA_FA[[3]][[k]][,'GHG_NC_MH']),sum(smop_hiDR_RFA_FA[[3]][[k]][,'GHG_NC']))
  
  cty_GHG[k,c('GHG_SF_hiMF_RFA','GHG_MF_hiMF_RFA','GHG_MH_hiMF_RFA','GHG_Tot_hiMF_RFA')]<-
    1e-9*c(sum(smop_hiMF_RFA_FA[[3]][[k]][,'GHG_NC_SF']),sum(smop_hiMF_RFA_FA[[3]][[k]][,'GHG_NC_MF']),sum(smop_hiMF_RFA_FA[[3]][[k]][,'GHG_NC_MH']),sum(smop_hiMF_RFA_FA[[3]][[k]][,'GHG_NC']))
  
}
rm(list=ls(pattern = "smop")) # remove to save space
# then embodied emissions from renovations
load("../Final_results/renGHG_cty_type.RData")

# then full energy results for housing stock and characteristics scenarios, each with 2 electricity grid variations, all produced by RS_results_proj.R script
# first base scripts #########
rm(list=ls(pattern = "rs_")) # remove to save space
load("../Final_results/res_base_RR.RData")
load("../Final_results/res_base_AR.RData")
load("../Final_results/res_base_ER.RData")
load("../Final_results/res_hiDR_RR.RData")
load("../Final_results/res_hiDR_AR.RData")
load("../Final_results/res_hiDR_ER.RData")
load("../Final_results/res_hiMF_RR.RData")
load("../Final_results/res_hiMF_AR.RData")
load("../Final_results/res_hiMF_ER.RData")

# add in Type3 as a building type identifier, applying this function is a bit slow
add_Type3<-function(df) {
  df$Type3<-'MF'
  df[df$Geometry.Building.Type.RECS ==  'Mobile Home',]$Type3<-'MH' 
  df[df$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF' 
  df
}
rs_base_all_RR<-add_Type3(rs_base_all_RR)
rs_base_all_AR<-add_Type3(rs_base_all_AR)
rs_base_all_ER<-add_Type3(rs_base_all_ER)
rs_hiDR_all_RR<-add_Type3(rs_hiDR_all_RR)
rs_hiDR_all_AR<-add_Type3(rs_hiDR_all_AR)
rs_hiDR_all_ER<-add_Type3(rs_hiDR_all_ER)
rs_hiMF_all_RR<-add_Type3(rs_hiMF_all_RR)
rs_hiMF_all_AR<-add_Type3(rs_hiMF_all_AR)
rs_hiMF_all_ER<-add_Type3(rs_hiMF_all_ER)
# to check on changes in distribution of housing numbers, types and cohorts between counties
basectyTC<-table(rs_base_all_RR$ctyTC)
hiDRctyTC<-table(rs_hiDR_all_RR$ctyTC)

G<-rs_base_all_RR[,c('Year_Building','Vintage','County','State','GHG_int_2020')]
G4<-unique(rs_base_all_RR[,c('County','GHG_int_2020')])
G5<-unique(rs_base_all_AR[,c('County','GHG_int_2020')])

GHGelec2020<-unique(rs_base_all_RR[,c('County','State','GHG_int_2020')])
GHGelec2020$GHG_int_2020<-3.6*GHGelec2020$GHG_int_2020 # convert to kgco2/kWh

GHGelec2020_st<-as.data.frame(tapply(rs_base_all_RR$GHG_int_2020*rs_base_all_RR$Elec_GJ,rs_base_all_RR$State,sum)/tapply(rs_base_all_RR$Elec_GJ,rs_base_all_RR$State,sum))
GHGelec2020_st$State<-rownames(GHGelec2020_st)
names(GHGelec2020_st)[1]<-'GHG_int_2020'
GHGelec2020_st$GHG_int_2020<-3.6*GHGelec2020_st$GHG_int_2020
GHGelec2020_st<-GHGelec2020_st[,c(2,1)]

# extract geographic relations, county and census division, climate zone, grid region
bs2020<-read.csv('../scen_bscsv/bs2020_180k.csv')
geos<-unique(bs2020[,c('County','State','Census.Division','ASHRAE.IECC.Climate.Zone.2004','Building.America.Climate.Zone','ISO.RTO.Region')])
# make summary of initial characteristics by county:
# - Share of homes with electric heating 
# - Share of homes built before 1960
# - etc.
hf<-as.data.frame(tapply(bs2020$Building,list(bs2020$Heating.Fuel,bs2020$County),length))
hf[is.na(hf)]<-0
# electricity share of heating fuel
es<-melt(hf['Electricity',]/colSums(hf))
names(es)<-c('County','ElecHeatShare')

ac<-as.data.frame(tapply(bs2020$Building,list(bs2020$Vintage.ACS,bs2020$County),length))
ac[is.na(ac)]<-0
# 'old' (<1960) share of housing stock
os<-melt(colSums(ac[1:2,])/colSums(ac))
os$County<-rownames(os)
os<-os[,c(2,1)]
names(os)[2]<-c('OldShare')

type<-as.data.frame(tapply(bs2020$Building,list(bs2020$Geometry.Building.Type.RECS,bs2020$County),length))
type[is.na(type)]<-0
sfs<-melt(colSums(type[4:5,])/colSums(type))
sfs$County<-rownames(sfs)
sfs<-sfs[,c(2,1)]
names(sfs)[2]<-c('SFShare')

size0<-as.data.frame(tapply(bs2020$Building,list(bs2020$Geometry.Floor.Area,bs2020$County),length))
size0[is.na(size0)]<-0
bs0<-melt(colSums(size0[c('3000-3999','4000+'),])/colSums(size0))
bs0$County<-rownames(bs0)
names(bs0)[1]<-'LargeShareAll'

size<-as.data.frame(tapply(bs2020[bs2020$Vintage %in% c('1990s','2000s','2010s'),]$Building,list(bs2020[bs2020$Vintage %in% c('1990s','2000s','2010s'),]$Geometry.Floor.Area,bs2020[bs2020$Vintage %in% c('1990s','2000s','2010s'),]$County),length))
size[is.na(size)]<-0
bs<-melt(colSums(size[c('3000-3999','4000+'),])/colSums(size))
bs$County<-rownames(bs)
bs<-bs[,c(2,1)]
names(bs)[2]<-c('LargeShare')

bs<-merge(bs,bs0,all = TRUE)
bs[is.na(bs$LargeShare),]$LargeShare<-bs[is.na(bs$LargeShare),]$LargeShareAll
bs<-bs[,1:2]

# merge the geographies with the descriptive stats
geos<-merge(geos,es)
geos<-merge(geos,os)
geos<-merge(geos,sfs)
geos<-merge(geos,bs)

# load in the stock evaluations to attach some info about how good the stock sample estimates are between stock scenarios
load('../Final_results/StockCountComp.RData')
cty50sum<-cty50[,c('County','UnitCount','UnitCount_STCY')] %>% group_by(County) %>% summarise_all(list(~ sum(., na.rm = TRUE)))
cty50sum$EstRatio_base<-round(cty50sum$UnitCount_STCY/cty50sum$UnitCount,3)
names(cty50sum)[2]<-'UnitCountBase'

cty50sum_hm<-cty50hm[,c('County','UnitCount','UnitCount_STCY')] %>% group_by(County) %>% summarise_all(list(~ sum(., na.rm = TRUE)))
cty50sum_hm$EstRatio_hiMF<-round(cty50sum_hm$UnitCount_STCY/cty50sum_hm$UnitCount,3)
cty50sum_hm$base_comp<-cty50sum_hm$EstRatio_hiMF/cty50sum$EstRatio_base
names(cty50sum_hm)[2]<-'UnitCounthiMF'

cty50sum_hd<-cty50hd[,c('County','UnitCount','UnitCount_STCY')] %>% group_by(County) %>% summarise_all(list(~ sum(., na.rm = TRUE)))
cty50sum_hd$EstRatio_hiDR<-round(cty50sum_hd$UnitCount_STCY/cty50sum_hd$UnitCount,3)
cty50sum_hd$base_comp<-cty50sum_hd$EstRatio_hiDR/cty50sum$EstRatio_base
names(cty50sum_hd)[2]<-'UnitCounthiDR'

cty50comp<-merge(cty50sum[,c('County','UnitCountBase','EstRatio_base')],cty50sum_hd[,c('County','EstRatio_hiDR')])
cty50comp<-merge(cty50comp,cty50sum_hm[,c('County','UnitCounthiMF','EstRatio_hiMF')])

st50sum<-st50[,c('State','UnitCount','UnitCount_STCY')] %>% group_by(State) %>% summarise_all(list(~ sum(., na.rm = TRUE)))
st50sum$EstRatio_base<-round(st50sum$UnitCount_STCY/st50sum$UnitCount,3)
names(st50sum)[2]<-'UnitCountBase'

st50sum_hm<-st50hm[,c('State','UnitCount','UnitCount_STCY')] %>% group_by(State) %>% summarise_all(list(~ sum(., na.rm = TRUE)))
st50sum_hm$EstRatio_hiMF<-round(st50sum_hm$UnitCount_STCY/st50sum_hm$UnitCount,3)
st50sum_hm$base_comp<-st50sum_hm$EstRatio_hiMF/st50sum$EstRatio_base
names(st50sum_hm)[2]<-'UnitCounthiMF'

# merge the stock estimates data into the geos file by county/ the state sums are good enough that there is no need to compare
geos<-merge(geos,cty50comp)

# do the same for the state level, to get around the problem of small samples
hfs<-as.data.frame(tapply(bs2020$Building,list(bs2020$Heating.Fuel,bs2020$State),length))
hfs[is.na(hfs)]<-0
# electricity share of heating fuel
ess<-melt(hfs['Electricity',]/colSums(hfs))
names(ess)<-c('State','ElecHeatShare_State')

acs<-as.data.frame(tapply(bs2020$Building,list(bs2020$Vintage.ACS,bs2020$State),length))
acs[is.na(acs)]<-0
# 'old' (<1960) share of housing stock
oss<-melt(colSums(acs[1:2,])/colSums(acs))
oss$State<-rownames(oss)
oss<-oss[,c(2,1)]
names(oss)[2]<-c('OldShare_State')

types<-as.data.frame(tapply(bs2020$Building,list(bs2020$Geometry.Building.Type.RECS,bs2020$State),length))
types[is.na(types)]<-0
sfss<-melt(colSums(types[4:5,])/colSums(types))
sfss$State<-rownames(sfss)
sfss<-sfss[,c(2,1)]
names(sfss)[2]<-c('SFShare_State')

sizes<-as.data.frame(tapply(bs2020[bs2020$Vintage %in% c('1990s','2000s','2010s'),]$Building,
                            list(bs2020[bs2020$Vintage %in% c('1990s','2000s','2010s'),]$Geometry.Floor.Area,bs2020[bs2020$Vintage %in% c('1990s','2000s','2010s'),]$State),length))
sizes[is.na(sizes)]<-0
bss<-melt(colSums(sizes[c('3000-3999','4000+'),])/colSums(sizes))
bss$State<-rownames(bss)
bss<-bss[,c(2,1)]
names(bss)[2]<-c('LargeShare_State')

# merge the geographies with the descriptive stats
geos<-merge(geos,ess,by='State')
geos<-merge(geos,oss,by='State')
geos<-merge(geos,sfss,by='State')
geos<-merge(geos,bss,by='State')

geos<-merge(geos,pop_summ)
geos<-merge(geos,GHGelec2020)

# round to make easier to read
geos[,c('ElecHeatShare','OldShare','SFShare','LargeShare','ElecHeatShare_State','OldShare_State','SFShare_State','LargeShare_State','pop_growth_pc','GHG_int_2020')]<-
  round(geos[,c('ElecHeatShare','OldShare','SFShare','LargeShare','ElecHeatShare_State','OldShare_State','SFShare_State','LargeShare_State','pop_growth_pc','GHG_int_2020')],3)
geos[,c('pop_2020','pop_growth_abs')]<-round(geos[,c('pop_2020','pop_growth_abs')])
geos$GHGint<-'4_HighGHG'
geos[geos$GHG_int_2020<0.5 & geos$GHG_int_2020>=0.35,]$GHGint<-'3_MedHighGHG'
geos[geos$GHG_int_2020<0.35 & geos$GHG_int_2020>=0.2,]$GHGint<-'2_MedLowGHG'
geos[geos$GHG_int_2020<0.2,]$GHGint<-'1_LowGHG'

geos$PopGrowth<-'4_HighPG'
geos[geos$pop_growth_pc<0.1 & geos$pop_growth_pc>=0,]$PopGrowth<-'3_ModPosPG'
geos[geos$pop_growth_pc<0 & geos$pop_growth_pc>=(-0.1),]$PopGrowth<-'2_ModNegPG'
geos[geos$pop_growth_pc<(-0.1),]$PopGrowth<-'1_StrongNegPG'

geos$ElecShare<-'4_HighES'
geos[geos$ElecHeatShare<0.667 & geos$ElecHeatShare>=0.429,]$ElecShare<-'3_MedHighES'
geos[geos$ElecHeatShare<0.429 & geos$ElecHeatShare>=0.196,]$ElecShare<-'2_MedLowES'
geos[geos$ElecHeatShare<0.196,]$ElecShare<-'1_LowES'

geos$OldShareCat<-'4_HighOS'
geos[geos$OldShare<0.375 & geos$OldShare>=0.222,]$OldShareCat<-'3_MedHighOS'
geos[geos$OldShare<0.222 & geos$OldShare>=0.111,]$OldShareCat<-'2_MedLowOS'
geos[geos$OldShare<0.111,]$OldShareCat<-'1_LowOS'

# finally, simplify the climate zones
geos$BACZ_agg<-'Cold'
geos[geos$Building.America.Climate.Zone %in% c('Hot-Humid','Hot-Dry'),]$BACZ_agg<-'Hot'
geos[geos$Building.America.Climate.Zone %in% c('Mixed-Humid','Mixed-Dry'),]$BACZ_agg<-'Mixed'
geos[geos$Building.America.Climate.Zone %in% c('Marine'),]$BACZ_agg<-'Marine'

geos<-geos %>% rename(ClimateZone = ASHRAE.IECC.Climate.Zone.2004,BAClimateZone=Building.America.Climate.Zone)

geos_st<-unique(geos[,c('State','Census.Division','ElecHeatShare_State','OldShare_State','SFShare_State','LargeShare_State')])
geos_st<-merge(geos_st,pop_sum_state)
geos_st<-merge(geos_st,GHGelec2020_st)
# round
geos_st[,c('pop_growth_pc','GHG_int_2020')]<-round(geos_st[,c('pop_growth_pc','GHG_int_2020')],3)
geos_st$pop_growth_abs<-round(geos_st$pop_growth_abs)

geos_st$GHGint<-'4_HighGHG'
geos_st[geos_st$GHG_int_2020<0.5 & geos_st$GHG_int_2020>=0.35,]$GHGint<-'3_MedHighGHG'
geos_st[geos_st$GHG_int_2020<0.35 & geos_st$GHG_int_2020>=0.2,]$GHGint<-'2_MedLowGHG'
geos_st[geos_st$GHG_int_2020<0.2,]$GHGint<-'1_LowGHG'

geos_st$PopGrowth<-'4_HighPG'
geos_st[geos_st$pop_growth_pc<0.15 & geos_st$pop_growth_pc>=0,]$PopGrowth<-'3_ModPosPG'
geos_st[geos_st$pop_growth_pc<0 & geos_st$pop_growth_pc>=(-0.12),]$PopGrowth<-'2_ModNegPG'
geos_st[geos_st$pop_growth_pc<(-0.12),]$PopGrowth<-'1_StrongNegPG'

geos_st$ElecShare<-'4_HighES'
geos_st[geos_st$ElecHeatShare_State<0.667 & geos_st$ElecHeatShare_State>=0.429,]$ElecShare<-'3_MedHighES'
geos_st[geos_st$ElecHeatShare_State<0.429 & geos_st$ElecHeatShare_State>=0.196,]$ElecShare<-'2_MedLowES'
geos_st[geos_st$ElecHeatShare_State<0.196,]$ElecShare<-'1_LowES'

geos_st$OldShareCat<-'4_HighOS'
geos_st[geos_st$OldShare_State<0.375 & geos_st$OldShare_State>=0.222,]$OldShareCat<-'3_MedHighOS'
geos_st[geos_st$OldShare_State<0.222 & geos_st$OldShare_State>=0.111,]$OldShareCat<-'2_MedLowOS'
geos_st[geos_st$OldShare_State<0.111,]$OldShareCat<-'1_LowOS'

rm(bs2020,es,os,sfs,ess,oss,sfss,hf,ac,type,hfs,acs,types)

# add in GHG emissions for CFE
# first define intensities for fuel combustion
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

# make a function to calculate total energy-based emissions for a given stock, NHC, ren scenario #########

# to explain the difference b/w all counties in the energy emissions file rs_base_all_RR (3084) and the embodied emissions file cty_GHG (3108):
# this is due to some counties not being included in the original sample of the housing stock in 2020.
# there are 24 such counties, all with tiny population:
cdiff<-unique(cty_GHG$RS_ID)[unique(cty_GHG$RS_ID) %!in% unique(rs_base_all_RR$County)]

# make the df of embodied emissions from new construction and renovation long and more amenable to subsetting matching/merging
cty_GHG$State<-substr(cty_GHG$RS_ID,1,2)
cty_type_cum$State<-substr(cty_type_cum$County,1,2)

cty_GHGm<-melt(cty_GHG)
# remove the totals 
cty_GHGm$variable<-as.character(cty_GHGm$variable)
cty_GHGm<-cty_GHGm[-c(which(startsWith(cty_GHGm$variable,'GHG_Tot'))),]
cty_GHGm$Stock<-str_sub(cty_GHGm$variable,8)
cty_GHGm$Type3<-str_sub(cty_GHGm$variable,5,6)
cty_GHGm<-subset(cty_GHGm,select=-c(variable))
names(cty_GHGm)[4]<-'embGHG_NC_Mt'
names(cty_GHGm)[2]<-'County'


ren_cum<-melt(cty_type_cum)
ren_cum$Stock<-str_sub(ren_cum$variable,-10,-7)
ren_cum$Ren<-str_sub(ren_cum$variable,-5,-4)
ren_cum<-subset(ren_cum,select=-c(variable))
names(ren_cum)[c(2,4)]<-c('Type3','embGHG_ren_Mt')
ren_cum[is.na(ren_cum)]<-0

# example function arguments that can be used for testing
# df<-rs_base_all_RR
# chars<-c('State')
# chars<-c('State','Type3')
# stock<-'base'
# ren<-'RR'
stock_sum<-function(df,chars,stock,ren) {
  
sum_emissions<-paste('EnGHGkg',substr(stock,1,4),seq(2020,2060,5),sep="_")
enGHG_MC<-melt(df[,c('Year_Building',chars,sum_emissions)])
enGHG_MC$Year<-str_sub(enGHG_MC$variable,-4)

if (length(chars)==1) {tl<-list(enGHG_MC$Year, enGHG_MC[,chars])}
if (length(chars)==2) {tl<-list(enGHG_MC$Year, enGHG_MC[,chars[1]],enGHG_MC[,chars[2]])}
if (length(chars)==3) {tl<-list(enGHG_MC$Year, enGHG_MC[,chars[1]],enGHG_MC[,chars[2]],enGHG_MC[,chars[3]])}
if (length(chars)==4) {tl<-list(enGHG_MC$Year, enGHG_MC[,chars[1]],enGHG_MC[,chars[2]],enGHG_MC[,chars[3]],enGHG_MC[,chars[4]])}

comb_enGHG_MC<-melt(tapply(enGHG_MC$value,tl,sum))

names(comb_enGHG_MC)[1]<-'Year'
names(comb_enGHG_MC)[length(comb_enGHG_MC)]<-'EnGHG_MC'
names(comb_enGHG_MC)[2:(length(comb_enGHG_MC)-1)]<-chars

# comb_enGHG_MC$Grid<-'MC'
comb_enGHG_MC$Ren<-ren
comb_enGHG_MC$Stock<-stock

sum_emissions<-paste('EnGHGkg',substr(stock,1,4),seq(2020,2060,5),'LRE',sep="_")
enGHG_LRE<-melt(df[,c('Year_Building',chars,sum_emissions)])
enGHG_LRE$Year<-str_sub(enGHG_LRE$variable,-4)

comb_enGHG_LRE<-melt(tapply(enGHG_LRE$value,tl,sum))

names(comb_enGHG_LRE)[1]<-'Year'
names(comb_enGHG_LRE)[length(comb_enGHG_LRE)]<-'EnGHG_LRE'
names(comb_enGHG_LRE)[2:(length(comb_enGHG_LRE)-1)]<-chars

# comb_enGHG_LRE$Grid<-'LRE'
comb_enGHG_LRE$Ren<-ren
comb_enGHG_LRE$Stock<-stock

comb_enGHG<-merge(comb_enGHG_MC,comb_enGHG_LRE)

if (length(chars)==1) {comb_enGHG$unq_chars<-paste(comb_enGHG[,2],sep="_")}
if (length(chars)==2) {comb_enGHG$unq_chars<-paste(comb_enGHG[,2],comb_enGHG[,3],sep="_")}
if (length(chars)==3) {comb_enGHG$unq_chars<-paste(comb_enGHG[,2],comb_enGHG[,3],comb_enGHG[,4],sep="_")}
if (length(chars)==4) {comb_enGHG$unq_chars<-paste(comb_enGHG[,2],comb_enGHG[,3],comb_enGHG[,4],comb_enGHG[,5],sep="_")}

ucs<-unique(comb_enGHG$unq_chars)

comb_summ<-unique(comb_enGHG[,c(chars,'unq_chars')])
comb_summ[,c('TotGHG_MC','TotGHG_LRE')]<-0

for (u in 1:length(ucs)) {
  cumu<-comb_enGHG[comb_enGHG$unq_chars==ucs[u],] # avoid breakdown due to the specific combination not existing
  if (any(!is.na(cumu$EnGHG_MC))) {
    comb_summ[comb_summ$unq_chars==ucs[u],'TotGHG_MC']<-sum(spline(cumu$Year,cumu$EnGHG_MC,xout = 2020:2060)$y)*1e-9 +  # energy emissions in Mt
      sum(cty_GHGm[cty_GHGm[,chars[1]]==cumu[,chars[1]][1] & cty_GHGm$Type3==cumu$Type3[1] & cty_GHGm$Stock==stock,]$embGHG_NC_Mt) + # embodied emissions from NC in Mt, only for county-resolution
      sum(ren_cum[ren_cum[,chars[1]]==cumu[,chars[1]][1] & ren_cum$Type3==cumu$Type3[1] & ren_cum$Stock==stock & ren_cum$Ren==ren,]$embGHG_ren_Mt) # embodied emissions from renovation in Mt
    
    comb_summ[comb_summ$unq_chars==ucs[u],'TotGHG_LRE']<-sum(spline(cumu$Year,cumu$EnGHG_LRE,xout = 2020:2060)$y)*1e-9 +  # energy emissions in Mt
      sum(cty_GHGm[cty_GHGm[,chars[1]]==cumu[,chars[1]][1] & cty_GHGm$Type3==cumu$Type3[1] & cty_GHGm$Stock==stock,]$embGHG_NC_Mt) + # embodied emissions from NC in Mt
      sum(ren_cum[ren_cum[,chars[1]]==cumu[,chars[1]][1] & ren_cum$Type3==cumu$Type3[1] & ren_cum$Stock==stock & ren_cum$Ren==ren,]$embGHG_ren_Mt) # embodied emissions from renovation in Mt
      }
}

comb_summ$Stock<-stock
comb_summ$Ren<-ren

comb_summ
}
# use function to extract summary emissions by state and Type for stock and ren scenarios
base_RR_State_Type<-stock_sum(rs_base_all_RR,c('State','Type3'),'base','RR')
base_AR_State_Type<-stock_sum(rs_base_all_AR,c('State','Type3'),'base','AR')
base_ER_State_Type<-stock_sum(rs_base_all_ER,c('State','Type3'),'base','ER')

hiDR_RR_State_Type<-stock_sum(rs_hiDR_all_RR,c('State','Type3'),'hiDR','RR')
hiDR_AR_State_Type<-stock_sum(rs_hiDR_all_AR,c('State','Type3'),'hiDR','AR')
hiDR_ER_State_Type<-stock_sum(rs_hiDR_all_ER,c('State','Type3'),'hiDR','ER')

hiMF_RR_State_Type<-stock_sum(rs_hiMF_all_RR,c('State','Type3'),'hiMF','RR')
hiMF_AR_State_Type<-stock_sum(rs_hiMF_all_AR,c('State','Type3'),'hiMF','AR')
hiMF_ER_State_Type<-stock_sum(rs_hiMF_all_ER,c('State','Type3'),'hiMF','ER')

# aggregate results by house type.
agg_ST<-function(df) { # aggregate state-type results to state results
  dfMC<-df[,c('State','TotGHG_MC')]%>%group_by(State)%>%summarise_all(funs(sum))
  dfLRE<-df[,c('State','TotGHG_LRE')]%>%group_by(State)%>%summarise_all(funs(sum))
  df<-merge(dfMC,dfLRE)
  df
}

base_RR_State<-agg_ST(base_RR_State_Type)
base_AR_State<-agg_ST(base_AR_State_Type)
base_ER_State<-agg_ST(base_ER_State_Type)

hiDR_RR_State<-agg_ST(hiDR_RR_State_Type)
hiDR_AR_State<-agg_ST(hiDR_AR_State_Type)
hiDR_ER_State<-agg_ST(hiDR_ER_State_Type)

hiMF_RR_State<-agg_ST(hiMF_RR_State_Type)
hiMF_AR_State<-agg_ST(hiMF_AR_State_Type)
hiMF_ER_State<-agg_ST(hiMF_ER_State_Type)

# use function to extract summary emissions by county and Type for stock and ren scenarios
base_RR_Cty_Type<-stock_sum(rs_base_all_RR,c('County','Type3'),'base','RR')
base_AR_Cty_Type<-stock_sum(rs_base_all_AR,c('County','Type3'),'base','AR')
base_ER_Cty_Type<-stock_sum(rs_base_all_ER,c('County','Type3'),'base','ER')

hiDR_RR_Cty_Type<-stock_sum(rs_hiDR_all_RR,c('County','Type3'),'hiDR','RR')
hiDR_AR_Cty_Type<-stock_sum(rs_hiDR_all_AR,c('County','Type3'),'hiDR','AR')
hiDR_ER_Cty_Type<-stock_sum(rs_hiDR_all_ER,c('County','Type3'),'hiDR','ER')

hiMF_RR_Cty_Type<-stock_sum(rs_hiMF_all_RR,c('County','Type3'),'hiMF','RR')
hiMF_AR_Cty_Type<-stock_sum(rs_hiMF_all_AR,c('County','Type3'),'hiMF','AR')
hiMF_ER_Cty_Type<-stock_sum(rs_hiMF_all_ER,c('County','Type3'),'hiMF','ER')

# agg cty-type to cty
agg_CT<-function(df) {
  dfMC<-df[,c('County','TotGHG_MC')]%>%group_by(County)%>%summarise_all(funs(sum))
  dfLRE<-df[,c('County','TotGHG_LRE')]%>%group_by(County)%>%summarise_all(funs(sum))
  df<-merge(dfMC,dfLRE)
  df
}

base_RR_Cty<-agg_CT(base_RR_Cty_Type)
base_AR_Cty<-agg_CT(base_AR_Cty_Type)
base_ER_Cty<-agg_CT(base_ER_Cty_Type)

hiDR_RR_Cty<-agg_CT(hiDR_RR_Cty_Type)
hiDR_AR_Cty<-agg_CT(hiDR_AR_Cty_Type)
hiDR_ER_Cty<-agg_CT(hiDR_ER_Cty_Type)

hiMF_RR_Cty<-agg_CT(hiMF_RR_Cty_Type)
hiMF_AR_Cty<-agg_CT(hiMF_AR_Cty_Type)
hiMF_ER_Cty<-agg_CT(hiMF_ER_Cty_Type)

rm(list=ls(pattern = "rs_"))

# repeat with DERFA scripts ################
load("../Final_results/res_baseDERFA_RR.RData")
load("../Final_results/res_baseDERFA_AR.RData")
load("../Final_results/res_baseDERFA_ER.RData")
load("../Final_results/res_hiDRDERFA_RR.RData")
load("../Final_results/res_hiDRDERFA_AR.RData")
load("../Final_results/res_hiDRDERFA_ER.RData")
load("../Final_results/res_hiMFDERFA_RR.RData")
load("../Final_results/res_hiMFDERFA_AR.RData")
load("../Final_results/res_hiMFDERFA_ER.RData")

# add the Type3 variable
rs_baseDERFA_all_RR<-add_Type3(rs_baseDERFA_all_RR)
rs_baseDERFA_all_AR<-add_Type3(rs_baseDERFA_all_AR)
rs_baseDERFA_all_ER<-add_Type3(rs_baseDERFA_all_ER)
rs_hiDRDERFA_all_RR<-add_Type3(rs_hiDRDERFA_all_RR)
rs_hiDRDERFA_all_AR<-add_Type3(rs_hiDRDERFA_all_AR)
rs_hiDRDERFA_all_ER<-add_Type3(rs_hiDRDERFA_all_ER)
rs_hiMFDERFA_all_RR<-add_Type3(rs_hiMFDERFA_all_RR)
rs_hiMFDERFA_all_AR<-add_Type3(rs_hiMFDERFA_all_AR)
rs_hiMFDERFA_all_ER<-add_Type3(rs_hiMFDERFA_all_ER)


# use function to extract summary emissions by state and Type for DERFA base and hiDR stock scenarios, with all ren scenarios
baseDERFA_RR_State_Type<-stock_sum(rs_baseDERFA_all_RR,c('State','Type3'),'base_RFA','RR')
baseDERFA_AR_State_Type<-stock_sum(rs_baseDERFA_all_AR,c('State','Type3'),'base_RFA','AR')
baseDERFA_ER_State_Type<-stock_sum(rs_baseDERFA_all_ER,c('State','Type3'),'base_RFA','ER')

hiDRDERFA_RR_State_Type<-stock_sum(rs_hiDRDERFA_all_RR,c('State','Type3'),'hiDR_RFA','RR')
hiDRDERFA_AR_State_Type<-stock_sum(rs_hiDRDERFA_all_AR,c('State','Type3'),'hiDR_RFA','AR')
hiDRDERFA_ER_State_Type<-stock_sum(rs_hiDRDERFA_all_ER,c('State','Type3'),'hiDR_RFA','ER')
# only done for hiMF and ER, but can be extended to the other ren scens 
hiMFDERFA_ER_State_Type<-stock_sum(rs_hiMFDERFA_all_ER,c('State','Type3'),'hiMF_RFA','ER')

baseDERFA_RR_State<-agg_ST(baseDERFA_RR_State_Type)
baseDERFA_AR_State<-agg_ST(baseDERFA_AR_State_Type)
baseDERFA_ER_State<-agg_ST(baseDERFA_ER_State_Type)

hiDRDERFA_RR_State<-agg_ST(hiDRDERFA_RR_State_Type)
hiDRDERFA_AR_State<-agg_ST(hiDRDERFA_AR_State_Type)
hiDRDERFA_ER_State<-agg_ST(hiDRDERFA_ER_State_Type)

# hiMFDERFA_RR_State<-agg_ST(hiMFDERFA_RR_State_Type)
# hiMFDERFA_AR_State<-agg_ST(hiMFDERFA_AR_State_Type)
hiMFDERFA_ER_State<-agg_ST(hiMFDERFA_ER_State_Type)

baseDERFA_RR_Cty_Type<-stock_sum(rs_baseDERFA_all_RR,c('County','Type3'),'base_RFA','RR')
baseDERFA_AR_Cty_Type<-stock_sum(rs_baseDERFA_all_AR,c('County','Type3'),'base_RFA','AR')
baseDERFA_ER_Cty_Type<-stock_sum(rs_baseDERFA_all_ER,c('County','Type3'),'base_RFA','ER')

hiDRDERFA_RR_Cty_Type<-stock_sum(rs_hiDRDERFA_all_RR,c('County','Type3'),'hiDR_RFA','RR')
hiDRDERFA_AR_Cty_Type<-stock_sum(rs_hiDRDERFA_all_AR,c('County','Type3'),'hiDR_RFA','AR')
hiDRDERFA_ER_Cty_Type<-stock_sum(rs_hiDRDERFA_all_ER,c('County','Type3'),'hiDR_RFA','ER')

# hiMFDERFA_RR_Cty_Type<-stock_sum(rs_hiMFDERFA_all_RR,c('County','Type3'),'hiMF_RFA','RR')
# hiMFDERFA_AR_Cty_Type<-stock_sum(rs_hiMFDERFA_all_AR,c('County','Type3'),'hiMF_RFA','AR')
hiMFDERFA_ER_Cty_Type<-stock_sum(rs_hiMFDERFA_all_ER,c('County','Type3'),'hiMF_RFA','ER')

baseDERFA_RR_Cty<-agg_CT(baseDERFA_RR_Cty_Type)
baseDERFA_AR_Cty<-agg_CT(baseDERFA_AR_Cty_Type)
baseDERFA_ER_Cty<-agg_CT(baseDERFA_ER_Cty_Type)

hiDRDERFA_RR_Cty<-agg_CT(hiDRDERFA_RR_Cty_Type)
hiDRDERFA_AR_Cty<-agg_CT(hiDRDERFA_AR_Cty_Type)
hiDRDERFA_ER_Cty<-agg_CT(hiDRDERFA_ER_Cty_Type)

# hiMFDERFA_RR_Cty<-agg_CT(hiMFDERFA_RR_Cty_Type)
# hiMFDERFA_AR_Cty<-agg_CT(hiMFDERFA_AR_Cty_Type)
hiMFDERFA_ER_Cty<-agg_CT(hiMFDERFA_ER_Cty_Type)


# example parameters for the `ass` function
# assess=cty_type_assess
# base_RR=base_RR_Cty_Type
# base_AR=base_AR_Cty_Type
# base_ER=base_ER_Cty_Type
# baseDERFA_RR=baseDERFA_RR_Cty_Type
# baseDERFA_AR=baseDERFA_AR_Cty_Type
# baseDERFA_ER=baseDERFA_ER_Cty_Type
# hiDR_RR=hiDR_RR_Cty_Type
# hiDR_AR=hiDR_AR_Cty_Type
# hiDR_ER=hiDR_ER_Cty_Type
# hiDRDERFA_RR=hiDRDERFA_RR_Cty_Type
# hiDRDERFA_AR=hiDRDERFA_AR_Cty_Type
# hiDRDERFA_ER=hiDRDERFA_ER_Cty_Type
# hiMF_RR=hiMF_RR_Cty_Type
# hiMF_ER=hiMF_ER_Cty_Type
# hiMFDERFA_RR=hiMFDERFA_RR_Cty_Type
# hiMFDERFA_ER=hiMFDERFA_ER_Cty_Type

ass<-function(base_RR,base_AR,base_ER,baseDERFA_RR,baseDERFA_AR,baseDERFA_ER,
              hiDR_RR,hiDR_AR,hiDR_ER,hiDRDERFA_RR,hiDRDERFA_AR,hiDRDERFA_ER,
              hiMF_RR,hiMF_ER,geos,geog) { #,hiMFDERFA_RR,hiMFDERFA_ER) {
  
  if (any(names(base_RR)=='Type3')) {
    assess<-base_RR[,c(geog,'Type3','TotGHG_MC','TotGHG_LRE')]
    assess[,3:4]<-round(assess[,3:4],4)
    names(assess)[3:4]<-paste(names(assess)[3:4],'_base_RR',sep="")
  } else {
    assess<-base_RR
    assess[,2:3]<-round(assess[,2:3],4)
    names(assess)[2:3]<-paste(names(assess)[2:3],'_base_RR',sep="")
}

# calculate abs. and pc reductions of individual strategies
assess$abs_redn_AR<-base_RR$TotGHG_MC-base_AR$TotGHG_MC
assess$abs_redn_ER<-base_RR$TotGHG_MC-base_ER$TotGHG_MC
assess$abs_redn_LRE<-base_RR$TotGHG_MC-base_RR$TotGHG_LR
# NB!!! For estimating the abs and pc reductions in hiDR and base, because different samples were drawn to represent future housing in these scenarios, 
# there is sometimes the case that for individual small counties a certain house type got sampled less. this occasionally leads to large (up to 100%!) reductions 
# in particulary county-type combos. these are not to be taken literally.
assess$abs_redn_hiDR<-base_RR$TotGHG_MC-hiDR_RR$TotGHG_MC
assess$abs_redn_hiMF<-base_RR$TotGHG_MC-hiMF_RR$TotGHG_MC # makes no sense to check the influence of hiMF by type, need to aggregate by type first
assess$abs_redn_DERFA<-base_RR$TotGHG_MC-baseDERFA_RR$TotGHG_MC

# see which strategy group is the best
assess$priority<-NA
str_group<-str_sub(c('abs_redn_ER','abs_redn_LRE','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA'),10)
for (k in 1:nrow(assess)) {
  assess$priority[k]<-paste(c(str_group[order(assess[k,c('abs_redn_ER','abs_redn_LRE','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA')],decreasing=TRUE)]),collapse = ">")
  assess$best[k]<-str_group[order(assess[k,c('abs_redn_ER','abs_redn_LRE','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA')],decreasing=TRUE)][1]
}

# calculate abs. and pc reductions of combined strategies
assess$abs_redn_AR_LRE<-base_RR$TotGHG_MC-base_AR$TotGHG_LRE
assess$abs_redn_ER_LRE<-base_RR$TotGHG_MC-base_ER$TotGHG_LRE

assess$abs_redn_hiDR_DERFA<-base_RR$TotGHG_MC-hiDRDERFA_RR$TotGHG_MC
assess$abs_redn_DERFA_LRE<-base_RR$TotGHG_MC-baseDERFA_RR$TotGHG_LRE
assess$abs_redn_DERFA_AR_LRE<-base_RR$TotGHG_MC-baseDERFA_AR$TotGHG_LRE
assess$abs_redn_DERFA_ER_LRE<-base_RR$TotGHG_MC-baseDERFA_ER$TotGHG_LRE
assess$abs_redn_hiDR_DERFA_ER_LRE<-base_RR$TotGHG_MC-hiDRDERFA_ER$TotGHG_LRE

# finally calculate some percentage reductions
assess$pc_redn_AR<-round(assess$abs_redn_AR/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_ER<-round(assess$abs_redn_ER/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_LRE<-round(assess$abs_redn_LRE/assess$TotGHG_MC_base_RR,4)
# don't rank emissions by pc redn in hiDR, for the reasons mentioned above. better to sort by abs reduction with hiDR and then see the distn in percentages for the highest hitters.
assess$pc_redn_hiDR<-round(assess$abs_redn_hiDR/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_hiMF<-round(assess$abs_redn_hiMF/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_DERFA<-round(assess$abs_redn_DERFA/assess$TotGHG_MC_base_RR,4)

assess$pc_redn_ER_LRE<-round(assess$abs_redn_ER_LRE/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_hiDR_DERFA<-round(assess$abs_redn_hiDR_DERFA/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_DERFA_LRE<-round(assess$abs_redn_DERFA_LRE/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_DERFA_AR_LRE<-round(assess$abs_redn_DERFA_AR_LRE/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_DERFA_ER_LRE<-round(assess$abs_redn_DERFA_ER_LRE/assess$TotGHG_MC_base_RR,4)
assess$pc_redn_hiDR_DERFA_ER_LRE<-round(assess$abs_redn_hiDR_DERFA_ER_LRE/assess$TotGHG_MC_base_RR,4)

assess<-merge(assess,geos,by=geog)

assess

} # end of assess function


cty_type_assess<-ass(base_RR_Cty_Type,base_AR_Cty_Type,base_ER_Cty_Type,baseDERFA_RR_Cty_Type,baseDERFA_AR_Cty_Type,baseDERFA_ER_Cty_Type,
                      hiDR_RR_Cty_Type,hiDR_AR_Cty_Type,hiDR_ER_Cty_Type,hiDRDERFA_RR_Cty_Type,hiDRDERFA_AR_Cty_Type,hiDRDERFA_ER_Cty_Type,
                      hiMF_RR_Cty_Type,hiMF_ER_Cty_Type,geos,'County')
cty_type_assess$cty_type<-paste(cty_type_assess$County,cty_type_assess$Type3,sep="_")

st_type_assess<-ass(base_RR_State_Type,base_AR_State_Type,base_ER_State_Type,baseDERFA_RR_State_Type,baseDERFA_AR_State_Type,baseDERFA_ER_State_Type,
                     hiDR_RR_State_Type,hiDR_AR_State_Type,hiDR_ER_State_Type,hiDRDERFA_RR_State_Type,hiDRDERFA_AR_State_Type,hiDRDERFA_ER_State_Type,
                     hiMF_RR_State_Type,hiMF_ER_State_Type,geos_st,'State')
st_type_assess$st_type<-paste(st_type_assess$State,st_type_assess$Type3,sep="_")

cty_assess<-ass(base_RR_Cty,base_AR_Cty,base_ER_Cty,baseDERFA_RR_Cty,baseDERFA_AR_Cty,baseDERFA_ER_Cty,
                     hiDR_RR_Cty,hiDR_AR_Cty,hiDR_ER_Cty,hiDRDERFA_RR_Cty,hiDRDERFA_AR_Cty,hiDRDERFA_ER_Cty,
                     hiMF_RR_Cty,hiMF_ER_Cty,geos,'County')
cty_assess$County<-cty_assess$County

st_assess<-ass(base_RR_State,base_AR_State,base_ER_State,baseDERFA_RR_State,baseDERFA_AR_State,baseDERFA_ER_State,
                    hiDR_RR_State,hiDR_AR_State,hiDR_ER_State,hiDRDERFA_RR_State,hiDRDERFA_AR_State,hiDRDERFA_ER_State,
                    hiMF_RR_State,hiMF_ER_State,geos_st,'State')

# save variables 
save(cty_type_assess,st_type_assess,cty_assess,st_assess,file = '../Final_results/GHG_scen_comp_StateCty.RData')

# some simple linear models to estimate influence of different variables
# try filtering on the difference between estimates of the total stock and actual values to remove results that differ due to different stock estimates from different samples drawn
cty_assess_fil<-cty_assess[abs(cty_assess$EstRatio_base-1)<0.06 & abs(cty_assess$EstRatio_hiDR-1)<0.06 & abs(cty_assess$EstRatio_hiDR-1)<0.06,]

# make some linear models
cty_AR_lm<-lm(pc_redn_AR~ BAClimateZone+GHG_int_2020+pop_growth_pc +ElecHeatShare+OldShare+SFShare,data=cty_assess_fil)
summary(cty_AR_lm)

cty_ER_lm<-lm(pc_redn_ER~ BAClimateZone+GHG_int_2020+pop_growth_pc +ElecHeatShare+OldShare+SFShare,data=cty_assess_fil)
summary(cty_ER_lm)
# categorical variable version
cty_ER_lm2<-lm(pc_redn_ER~ BAClimateZone+ GHGint + PopGrowth + ElecShare + OldShareCat +SFShare,data=cty_assess_fil)
summary(cty_ER_lm2)
# With aggregate climate zones 
cty_ER_lm3<-lm(pc_redn_ER~ BACZ_agg+ GHGint + PopGrowth + ElecShare + OldShareCat +SFShare,data=cty_assess_fil)
summary(cty_ER_lm3)

tab_model(cty_ER_lm3,show.ci = FALSE,show.se = TRUE)

# climate and GHGint appear to be the most important variables here (Although building age and old share are also important) let's confirm their role with some tables,summary stats
round(tapply(cty_assess_fil$pc_redn_ER, list(cty_assess_fil$BACZ_agg,cty_assess_fil$GHGint), mean),3)
# this is a very telling table, summing up the comparison between LRE and ER strategies by climate and GHG intensity.
table(cty_assess_fil$best,cty_assess_fil$BACZ_agg,cty_assess_fil$GHGint)

cty_LRE_lm<-lm(pc_redn_LRE~ Building.America.Climate.Zone+GHG_int_2020+pop_growth_pc +ElecHeatShare+OldShare+SFShare,data=cty_assess_fil)
summary(cty_LRE_lm)
# categorical variable version
cty_LRE_lm2<-lm(pc_redn_LRE~ Building.America.Climate.Zone+ GHGint + PopGrowth + ElecShare + OldShareCat +SFShare,data=cty_assess_fil)
summary(cty_LRE_lm2)

cty_LRE_lm3<-lm(pc_redn_LRE~ BACZ_agg+ GHGint + PopGrowth + ElecShare + OldShareCat +SFShare,data=cty_assess_fil)
summary(cty_LRE_lm3)

tab_model(cty_LRE_lm3,show.ci = FALSE,show.se = TRUE)

# for LRE, initial GHGint and share of electrified homes are the defining variables
round(tapply(cty_assess_fil$pc_redn_LRE, list(cty_assess_fil$GHGint,cty_assess_fil$ElecShare), mean),3)
table(cty_assess_fil$best,cty_assess_fil$GHGint,cty_assess_fil$ElecShare)
# now hiDR
cty_hiDR_lm<-lm(pc_redn_hiDR~ Building.America.Climate.Zone+GHG_int_2020+pop_growth_pc +ElecHeatShare+OldShare+SFShare,data=cty_assess_fil)
summary(cty_hiDR_lm)

cty_hiDR_lm3<-lm(pc_redn_hiDR~ BACZ_agg+ GHGint + PopGrowth + ElecShare + OldShareCat +SFShare,data=cty_assess_fil)
summary(cty_hiDR_lm3)

tab_model(cty_hiDR_lm3,show.ci = FALSE,show.se = TRUE)

# try running a model on a filtered version of cty_type_assess
cty_type_assess_fil<-cty_type_assess[abs(cty_type_assess$EstRatio_base-1)<0.06 & abs(cty_type_assess$EstRatio_hiDR-1)<0.06 & abs(cty_type_assess$EstRatio_hiDR-1)<0.06,]
cty_type_hiDR_lm<-lm(pc_redn_hiDR~ BACZ_agg + GHGint + PopGrowth + ElecShare + OldShareCat +Type3,data=cty_type_assess_fil)
summary(cty_type_hiDR_lm)
tab_model(cty_type_hiDR_lm,show.ci = FALSE,show.se = TRUE)


# for hiDR, having a high share of old homes and a low population growth appear to be most relevant. Model also has very low R2 however
round(tapply(cty_assess_fil$pc_redn_hiDR, list(cty_assess_fil$OldShareCat,cty_assess_fil$PopGrowth), median),3)
round(tapply(cty_assess_fil$pc_redn_hiDR, list(cty_assess_fil$GHGin,cty_assess_fil$BACZ_agg), median),3)
# there is also weak evidence (here and in the table) than being in a cold climate with MedHigh GHG gives a lower reduction from hiDR
round(tapply(cty_assess_fil$pc_redn_hiDR, list(cty_assess_fil$GHGin,cty_assess_fil$BACZ_agg), mean),3)

# hiMF
cty_hiMF_lm<-lm(pc_redn_hiMF~ Building.America.Climate.Zone+GHG_int_2020+pop_growth_pc +ElecHeatShare+OldShare+SFShare,data=cty_assess_fil)
summary(cty_hiMF_lm)

cty_hiMF_lm3<-lm(pc_redn_hiMF~ BACZ_agg+ GHGint + PopGrowth + ElecShare + OldShareCat +SFShare,data=cty_assess_fil)
summary(cty_hiMF_lm3)
tab_model(cty_hiMF_lm3,show.ci = FALSE,show.se = TRUE)

# make a summary table of all models
tab_model(cty_ER_lm3,cty_LRE_lm3,cty_hiDR_lm3,cty_hiMF_lm3,show.ci = FALSE,show.se = TRUE,
          title = 'Linear Models of percent reduction in GHG emissions in US counties from alternative strategies',
          dv.labels = c('Ext. Ren.','LREC Elec.','Hi Turnover','Hi MultiFam.'))

# for hiMF, having a high population growth rate and a cold/Marine climate appear to be the main factors
round(tapply(cty_assess_fil$pc_redn_hiMF, list(cty_assess_fil$PopGrowth,cty_assess_fil$BACZ_agg), mean),3)

cty_DERFA_lm<-lm(pc_redn_DERFA~ Building.America.Climate.Zone+GHG_int_2020+pop_growth_pc +ElecHeatShare+OldShare+SFShare,data=cty_assess_fil)
summary(cty_DERFA_lm)

cty_DERFA_lm3<-lm(pc_redn_DERFA~ BACZ_agg+ GHGint + PopGrowth + ElecShare + OldShareCat +SFShare ,data=cty_assess_fil)
summary(cty_DERFA_lm3)
tab_model(cty_DERFA_lm3,show.ci = FALSE,show.se = TRUE)

tab_model(cty_ER_lm3,cty_LRE_lm3,cty_hiDR_lm3,cty_hiMF_lm3,cty_DERFA_lm3,show.ci = FALSE,show.se = TRUE,
          title = 'Linear Models of percent reduction in GHG emissions in US counties from alternative strategies',
          dv.labels = c('Ext. Ren.','LREC Elec.','Hi Turnover','Hi MultiFam.','Deep Elec. Red. FA New Homes'))

# for DERFA, Climate (Marine), GHGintensity, Population growth, all seem to be important.
round(tapply(cty_assess_fil$pc_redn_DERFA, list(cty_assess_fil$PopGrowth,cty_assess_fil$BACZ_agg), mean),3)
round(tapply(cty_assess_fil$pc_redn_DERFA, list(cty_assess_fil$PopGrowth,cty_assess_fil$BACZ_agg,cty_assess_fil$GHGint), mean),3)
round(tapply(cty_assess_fil$pc_redn_DERFA, list(cty_assess_fil$PopGrowth,cty_assess_fil$GHGint), mean),3)

st_type_assess_fil<-st_type_assess[-c(5:18)]

# tables comparing best solution by housing stock characteristics
st_assess_fil<-st_assess
table(st_assess_fil$best,st_assess_fil$GHGint)
table(st_assess_fil$best,st_assess_fil$OldShareCat)
table(st_assess_fil$best,st_assess_fil$ElecShare)
table(st_assess_fil$best,st_assess_fil$PopGrowth)

# single characteristics
# cty_assess_fil<-cty_assess[cty_assess$TotGHG_MC_base_RR>cty_thresh & cty_assess$pop_2020>2500,-c(4:17)]
# cty_assess_fil<cty_assess
table(cty_assess_fil$best,cty_assess_fil$GHGint)
table(cty_assess_fil$best,cty_assess_fil$OldShareCat)
table(cty_assess_fil$best,cty_assess_fil$ElecShare)
table(cty_assess_fil$best,cty_assess_fil$PopGrowth)
# multiple characteristics
table(cty_assess_fil$best,cty_assess_fil$OldShareCat,cty_assess_fil$BAClimateZone)
# it's a bit long, but this table does a job in showing the importance of old-share, climate-zone, and GHG intensity in determining which is the best renovation strategy.
# basically in regions with low/ GHG int, ER is usually the best, especially if there is a high share of old homes
# then for MdLow/MedHigh GHGint, it depends a bit on the climate zone, with colder climates preferring ER and mixed/hotter climates preferring LRE especially with MedHigh GHGint.
# then for High GHGint, LRE is the best strategy in almost every case.
table(cty_assess_fil$best,cty_assess_fil$OldShareCat,cty_assess_fil$BAClimateZone,cty_assess_fil$GHGint)

# tapply of numeric renovation GHG reductions by stock/region characteristics
# hiDR better with negative pop growth and high share of old buildings
round(tapply(cty_type_assess_fil$pc_redn_hiDR, list(cty_type_assess_fil$OldShareCat,cty_type_assess_fil$PopGrowth), mean),3)
round(tapply(cty_type_assess_fil$pc_redn_hiDR, list(cty_type_assess_fil$OldShareCat,cty_type_assess_fil$PopGrowth), median),3)

# ER better with low GHGint and high share of old buildings
round(tapply(cty_type_assess_fil$pc_redn_ER, list(cty_type_assess_fil$OldShareCat,cty_type_assess_fil$GHGint), mean),3)
# taking a step further, ER has higher impact in regions with low Elec Share of heat
round(tapply(cty_type_assess_fil$pc_redn_ER, list(cty_type_assess_fil$OldShareCat,cty_type_assess_fil$GHGint,cty_type_assess_fil$ElecShare), mean),3)

# extract some tables to compare ###########
ER_table<-cty_assess_fil[c(head(order(cty_assess_fil$abs_redn_ER,decreasing = TRUE),150),tail(order(cty_assess_fil$abs_redn_ER,decreasing = TRUE),50)),
                         c('County','TotGHG_MC_base_RR','priority','best',
                           'abs_redn_ER','abs_redn_LRE','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA','abs_redn_ER_LRE','abs_redn_DERFA_LRE','abs_redn_DERFA_ER_LRE',
                           'pc_redn_ER','pc_redn_LRE','pc_redn_hiDR','pc_redn_hiMF','pc_redn_DERFA','pc_redn_ER_LRE','pc_redn_DERFA_LRE','pc_redn_DERFA_ER_LRE',
                           'Building.America.Climate.Zone','BACZ_agg', 'ElecHeatShare','OldShare','SFShare','pop_2020','pop_growth_pc','GHG_int_2020',
                           'GHGint','PopGrowth','ElecShare','OldShareCat')]
ER_table<-ER_table[ER_table$pop_2020>9999,]
rownames(ER_table)<-1:nrow(ER_table)

LRE_table<-cty_assess_fil[c(head(order(cty_assess_fil$abs_redn_LRE,decreasing = TRUE),150),tail(order(cty_assess_fil$abs_redn_LRE,decreasing = TRUE),50)),
                         c('County','TotGHG_MC_base_RR','priority','best',
                           'abs_redn_LRE','abs_redn_ER','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA','abs_redn_ER_LRE','abs_redn_DERFA_LRE','abs_redn_DERFA_ER_LRE',
                           'pc_redn_LRE','pc_redn_ER','pc_redn_hiDR','pc_redn_hiMF','pc_redn_DERFA','pc_redn_ER_LRE','pc_redn_DERFA_LRE','pc_redn_DERFA_ER_LRE',
                           'Building.America.Climate.Zone','BACZ_agg', 'ElecHeatShare','OldShare','SFShare','pop_2020','pop_growth_pc','GHG_int_2020',
                           'GHGint','PopGrowth','ElecShare','OldShareCat')]
LRE_table<-LRE_table[LRE_table$pop_2020>9999,]
rownames(LRE_table)<-1:nrow(LRE_table)

hiDR_table<-cty_assess_fil[c(head(order(cty_assess_fil$abs_redn_hiDR,decreasing = TRUE),150),tail(order(cty_assess_fil$abs_redn_hiDR,decreasing = TRUE),50)),
                          c('County','TotGHG_MC_base_RR','priority','best',
                            'abs_redn_hiDR','abs_redn_LRE','abs_redn_ER','abs_redn_hiMF','abs_redn_DERFA','abs_redn_ER_LRE','abs_redn_DERFA_LRE','abs_redn_DERFA_ER_LRE',
                            'pc_redn_hiDR','pc_redn_LRE','pc_redn_ER','pc_redn_hiMF','pc_redn_DERFA','pc_redn_ER_LRE','pc_redn_DERFA_LRE','pc_redn_DERFA_ER_LRE',
                            'Building.America.Climate.Zone','BACZ_agg', 'ElecHeatShare','OldShare','SFShare','pop_2020','pop_growth_pc','GHG_int_2020',
                            'GHGint','PopGrowth','ElecShare','OldShareCat')]
hiDR_table<-hiDR_table[hiDR_table$pop_2020>9999,]
rownames(hiDR_table)<-1:nrow(hiDR_table)

hiDR_table_type<-cty_type_assess_fil[cty_type_assess_fil$County %in% hiDR_table$County,]

base_hf<-as.data.frame(table(rs_base_all_RR$County,rs_base_all_RR$HVAC.Heating.Type.And.Fuel))
base_hf<-base_hf[base_hf$Freq>0,]

hiDR_hf<-as.data.frame(table(rs_hiDR_all_RR$County,rs_hiDR_all_RR$HVAC.Heating.Type.And.Fuel))
hiDR_hf<-hiDR_hf[hiDR_hf$Freq>0,]

hiMF_table<-cty_assess_fil[c(head(order(cty_assess_fil$abs_redn_hiMF,decreasing = TRUE),150),tail(order(cty_assess_fil$abs_redn_hiMF,decreasing = TRUE),50)),
                           c('County','TotGHG_MC_base_RR','priority','best',
                             'abs_redn_hiMF','abs_redn_hiDR','abs_redn_LRE','abs_redn_ER','abs_redn_hiMF','abs_redn_DERFA','abs_redn_ER_LRE','abs_redn_DERFA_LRE','abs_redn_DERFA_ER_LRE',
                             'pc_redn_hiMF','pc_redn_hiDR','pc_redn_LRE','pc_redn_ER','pc_redn_DERFA','pc_redn_ER_LRE','pc_redn_DERFA_LRE','pc_redn_DERFA_ER_LRE',
                             'Building.America.Climate.Zone','BACZ_agg', 'ElecHeatShare','OldShare','SFShare','pop_2020','pop_growth_pc','GHG_int_2020',
                             'GHGint','PopGrowth','ElecShare','OldShareCat')]
hiMF_table<-hiMF_table[hiMF_table$pop_2020>9999,]
rownames(hiMF_table)<-1:nrow(hiMF_table)


# general table of top 500
str_table<-cty_assess_fil[c(head(order(cty_assess_fil$TotGHG_MC_base_RR,decreasing = TRUE),500),tail(order(cty_assess_fil$TotGHG_MC_base_RR,decreasing = TRUE),0)),
                      c('County','TotGHG_MC_base_RR','priority','best',
                        'abs_redn_ER','abs_redn_LRE','abs_redn_hiDR','abs_redn_hiMF','abs_redn_DERFA','abs_redn_ER_LRE','abs_redn_DERFA_LRE','abs_redn_DERFA_ER_LRE',
                        'pc_redn_ER','pc_redn_LRE','pc_redn_hiDR','pc_redn_hiMF','pc_redn_DERFA','pc_redn_ER_LRE','pc_redn_DERFA_LRE','pc_redn_DERFA_ER_LRE',
                        'UnitCountBase','EstRatio_base','EstRatio_hiDR','UnitCounthiMF','EstRatio_hiMF',
                        'BAClimateZone','BACZ_agg', 'ElecHeatShare','OldShare','SFShare','LargeShare','pop_2020','pop_growth_pc','GHG_int_2020',
                        'GHGint','PopGrowth','ElecShare','OldShareCat')]
