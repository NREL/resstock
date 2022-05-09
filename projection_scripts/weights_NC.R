# calculate base weights by house type3, cohort, and state for use with future built houses 
library(ggplot2)
library(dplyr)
library(reshape2)
library(stringr)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts")
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console

# Last Update Peter Berrill April 30 2022

# Purpose: Calculate base weights by house type3, cohort, and state for use with future built houses. This rectifies the differences between actual and sampled number of housing units by type and state for new housing, due to the the smaller sample sizes of new housing

# Inputs: - rs_base_EG.RData
#         - rs_hiDR_EG.RData
#         - rs_hiMF_EG.RData
#         - ctycode.RData
#         - HSM_github/HSM_results/County_Scenario_SM_Results.RData


# Outputs: 
#         - Intermediate_results/base_weights_NC.RData


# Revision March 2022, recalc the NewConEstimates at the county-cohort-type level
load("../Intermediate_results/rs_base_EG.RData")
load("../Intermediate_results/rs_hiDR_EG.RData")
load("../Intermediate_results/rs_hiMF_EG.RData")
load("../ExtData/ctycode.RData")
load("~/Yale Courses/Research/Final Paper/HSM_github/HSM_results/County_Scenario_SM_Results.RData") # load in stock model results, from https://github.com/peterberr/US_county_HSM

# start a dataframe in which to extract the unit totals 
smop_base_HUTC<-smop_base[,1:2]

smop_base_HUTC[,paste(rep(names(smop_base[[3]][[1]])[c(116:119,136:139,156:159)],each=2),rep(seq(2025,2060,5),2),sep="_")]<-0

# start a dataframe in which to extract the totals by type in future decades
smop_base_HUTY<-smop_base[,1:2]
smop_base_HUTY[,paste(rep(names(smop_base[[3]][[1]])[15:17],each=4),seq(2030,2060,10),sep="_")]<-0
names(smop_base_HUTY)<-gsub('Occ_HU_','',names(smop_base_HUTY))
for (r in 1:3142) {
  
  smop_base_HUTC[r,c(3:4)]<-smop_base[[3]][[r]]$Tot_HU_SF_Occ_2020_29[c(6,11)]
  smop_base_HUTC[r,c(5:6)]<-smop_base[[3]][[r]]$Tot_HU_SF_Occ_2030_39[c(16,21)]
  smop_base_HUTC[r,c(7:8)]<-smop_base[[3]][[r]]$Tot_HU_SF_Occ_2040_49[c(26,31)]
  smop_base_HUTC[r,c(9:10)]<-smop_base[[3]][[r]]$Tot_HU_SF_Occ_2050_60[c(36,41)]
  
  smop_base_HUTC[r,c(11:12)]<-smop_base[[3]][[r]]$Tot_HU_MF_Occ_2020_29[c(6,11)]
  smop_base_HUTC[r,c(13:14)]<-smop_base[[3]][[r]]$Tot_HU_MF_Occ_2030_39[c(16,21)]
  smop_base_HUTC[r,c(15:16)]<-smop_base[[3]][[r]]$Tot_HU_MF_Occ_2040_49[c(26,31)]
  smop_base_HUTC[r,c(17:18)]<-smop_base[[3]][[r]]$Tot_HU_MF_Occ_2050_60[c(36,41)]
  
  smop_base_HUTC[r,c(19:20)]<-smop_base[[3]][[r]]$Tot_HU_MH_Occ_2020_29[c(6,11)]
  smop_base_HUTC[r,c(21:22)]<-smop_base[[3]][[r]]$Tot_HU_MH_Occ_2030_39[c(16,21)]
  smop_base_HUTC[r,c(23:24)]<-smop_base[[3]][[r]]$Tot_HU_MH_Occ_2040_49[c(26,31)]
  smop_base_HUTC[r,c(25:26)]<-smop_base[[3]][[r]]$Tot_HU_MH_Occ_2050_60[c(36,41)]
  
  smop_base_HUTY[r,3:6]<-round(smop_base[[3]][[r]]$Occ_HU_SF[c(11,21,31,41)])
  smop_base_HUTY[r,7:10]<-round(smop_base[[3]][[r]]$Occ_HU_MF[c(11,21,31,41)])
  smop_base_HUTY[r,11:14]<-round(smop_base[[3]][[r]]$Occ_HU_MH[c(11,21,31,41)])
  
}

names(smop_base_HUTC)<-gsub('Tot_HU_','',names(smop_base_HUTC))
smop_base_HUTC<-merge(smop_base_HUTC,ctycode)

smop_base_m<-melt(smop_base_HUTC)
smop_base_m<-smop_base_m[,-2]
smop_base_m$Type<-substr(smop_base_m$variable,1,2)
smop_base_m$Vintage<-paste(substr(smop_base_m$variable,8,11),'s',sep="")
smop_base_m$Year<-substr(smop_base_m$variable,16,19)
smop_base_m$State<-substr(smop_base_m$RS_ID,1,2)

sum_stcy<-as.data.frame(tapply(smop_base_m$value,list(smop_base_m$Type,smop_base_m$Vintage,smop_base_m$Year,smop_base_m$State),sum))
sum_stcy$Type<-rownames(sum_stcy)
sum_stcy<-melt(sum_stcy)
sum_stcy$Year<-substr(sum_stcy$variable,7,10)
sum_stcy$Vintage<-substr(sum_stcy$variable,1,5)
sum_stcy$State<-substr(sum_stcy$variable,12,13)
sum_stcy<-sum_stcy[complete.cases(sum_stcy),]

yrs<-seq(2030,2060,10)
# subtract the 5 year total from the decade total to calculate what is built in the second half
for (y in yrs) {
  sum_stcy[sum_stcy$Year==y,]$value<-sum_stcy[sum_stcy$Year==y,]$value-sum_stcy[sum_stcy$Year==y-5,]$value
}
names(sum_stcy)[3]<-'UnitCount'

rs_base$Type3<-str_sub(rs_base$ctyTC,-10,-9)
rs_base$St_TC_Year<-paste(rs_base$State,rs_base$Type3,rs_base$Vintage.ACS,sep="_")
stcy<-as.data.frame(table(rs_base$St_TC,rs_base$Year))
stcy$Type<-substr(stcy$Var1,4,5)
stcy$State<-substr(stcy$Var1,1,2)
stcy$Vintage<-substr(stcy$Var1,7,11)
names(stcy)[2]<-'Year'
names(stcy)[3]<-'SampleCount'
stcy<-stcy[,-1]

stcy_comp<-merge(sum_stcy,stcy,by=c('Year','Vintage','State','Type'),all.x = TRUE)
stcy_comp<-stcy_comp[!stcy_comp$State %in% c('AK','HI'), ]
stcy_comp[is.na(stcy_comp$SampleCount),]$SampleCount<-0
stcy_comp$wf<-stcy_comp$UnitCount/stcy_comp$SampleCount
# stcy_comp$isNA<-is.na(stcy_comp$wf)
# round(tapply(stcy_comp$isNA,stcy_comp$State,sum)/tapply(stcy_comp$isNA,stcy_comp$State,length),3) # only a few states with few MH that have NAs
stcy_comp[is.infinite(stcy_comp$wf),]$wf<-median(stcy_comp$wf)
# see how it compares by type
tapply(stcy_comp$wf,stcy_comp$Type,mean)
tapply(stcy_comp$wf,stcy_comp$Type,median)

round(tapply(stcy_comp$wf,list(stcy_comp$Type,stcy_comp$State),mean))
stcy_comp_base<-stcy_comp

# see if it is possible to sum at county level
sum_ccty<-as.data.frame(tapply(smop_base_m$value,list(smop_base_m$Type,smop_base_m$Vintage,smop_base_m$Year,smop_base_m$RS_ID),sum))
sum_ccty$Type<-rownames(sum_ccty)
sum_ccty<-melt(sum_ccty)
sum_ccty$Year<-substr(sum_ccty$variable,7,10)
sum_ccty$Vintage<-substr(sum_ccty$variable,1,5)
sum_ccty$County<-str_sub(sum_ccty$variable,12)
sum_ccty<-sum_ccty[complete.cases(sum_ccty),]

yrs<-seq(2030,2060,10)
# subtract the 5 year total from the decade total to calculate what is built in the second half
for (y in yrs) {
  sum_ccty[sum_ccty$Year==y,]$value<-sum_ccty[sum_ccty$Year==y,]$value-sum_ccty[sum_ccty$Year==y-5,]$value
}
names(sum_ccty)[3]<-'UnitCount'


ccty<-as.data.frame(table(rs_base$ctyTC,rs_base$Year))
ccty$Type<-str_sub(ccty$Var1,-10,-9)
ccty$County<-str_sub(ccty$Var1,1,-11)
ccty$Vintage<-paste(str_sub(ccty$Var1,-7,-4),'s',sep="")
names(ccty)[2]<-'Year'
names(ccty)[3]<-'SampleCount'
ccty<-ccty[,-1]

ccty_comp<-merge(sum_ccty,ccty,by=c('Year','Vintage','County','Type'),all.x = TRUE)
ccty_comp$State<-substr(ccty_comp$County,1,2)
ccty_comp<-ccty_comp[!ccty_comp$State %in% c('AK','HI'), ]
#ccty_comp[is.na(ccty_comp$SampleCount),]$SampleCount<-0
ccty_comp$wf<-ccty_comp$UnitCount/ccty_comp$SampleCount
ccty_comp$isNA<-is.na(ccty_comp$wf)
round(tapply(ccty_comp$isNA,ccty_comp$State,sum)/tapply(ccty_comp$isNA,ccty_comp$State,length),3)
# there are far too many NAs, not feasible to proceed

ccty_comp[is.infinite(ccty_comp$wf),]$wf<-median(ccty_comp$wf,na.rm = TRUE)

stock_tcy<-melt(smop_base_HUTY)
stock_tcy<-merge(stock_tcy,ctycode)
stock_tcy$State<-substr(stock_tcy$RS_ID,1,2)
stock_tcy$Type<-substr(stock_tcy$variable,1,2)
stock_tcy$Year<-substr(stock_tcy$variable,4,7)
stock_tcy<-stock_tcy[,c(5:8,4)]
names(stock_tcy)[c(1,3,5)]<-c('County','Type3','UnitCount')
stock_tsy<-stock_tcy[,2:5]%>%group_by(Year,State,Type3)%>%summarise_all(funs(sum))

stock_tcy_base<-stock_tcy
stock_tsy_base<-stock_tsy
# repeat for hiDR ########

# start a dataframe in which to extract the unit totals 
smop_hiDR_HUTC<-smop_hiDR[,1:2]

smop_hiDR_HUTC[,paste(rep(names(smop_hiDR[[3]][[1]])[c(116:119,136:139,156:159)],each=2),rep(seq(2025,2060,5),2),sep="_")]<-0

# start a dataframe in which to extract the totals by type in future decades
smop_hiDR_HUTY<-smop_hiDR[,1:2]
smop_hiDR_HUTY[,paste(rep(names(smop_hiDR[[3]][[1]])[15:17],each=4),seq(2030,2060,10),sep="_")]<-0
names(smop_hiDR_HUTY)<-gsub('Occ_HU_','',names(smop_hiDR_HUTY))
for (r in 1:3142) {
  
  smop_hiDR_HUTC[r,c(3:4)]<-smop_hiDR[[3]][[r]]$Tot_HU_SF_Occ_2020_29[c(6,11)]
  smop_hiDR_HUTC[r,c(5:6)]<-smop_hiDR[[3]][[r]]$Tot_HU_SF_Occ_2030_39[c(16,21)]
  smop_hiDR_HUTC[r,c(7:8)]<-smop_hiDR[[3]][[r]]$Tot_HU_SF_Occ_2040_49[c(26,31)]
  smop_hiDR_HUTC[r,c(9:10)]<-smop_hiDR[[3]][[r]]$Tot_HU_SF_Occ_2050_60[c(36,41)]
  
  smop_hiDR_HUTC[r,c(11:12)]<-smop_hiDR[[3]][[r]]$Tot_HU_MF_Occ_2020_29[c(6,11)]
  smop_hiDR_HUTC[r,c(13:14)]<-smop_hiDR[[3]][[r]]$Tot_HU_MF_Occ_2030_39[c(16,21)]
  smop_hiDR_HUTC[r,c(15:16)]<-smop_hiDR[[3]][[r]]$Tot_HU_MF_Occ_2040_49[c(26,31)]
  smop_hiDR_HUTC[r,c(17:18)]<-smop_hiDR[[3]][[r]]$Tot_HU_MF_Occ_2050_60[c(36,41)]
  
  smop_hiDR_HUTC[r,c(19:20)]<-smop_hiDR[[3]][[r]]$Tot_HU_MH_Occ_2020_29[c(6,11)]
  smop_hiDR_HUTC[r,c(21:22)]<-smop_hiDR[[3]][[r]]$Tot_HU_MH_Occ_2030_39[c(16,21)]
  smop_hiDR_HUTC[r,c(23:24)]<-smop_hiDR[[3]][[r]]$Tot_HU_MH_Occ_2040_49[c(26,31)]
  smop_hiDR_HUTC[r,c(25:26)]<-smop_hiDR[[3]][[r]]$Tot_HU_MH_Occ_2050_60[c(36,41)]
  
  smop_hiDR_HUTY[r,3:6]<-round(smop_hiDR[[3]][[r]]$Occ_HU_SF[c(11,21,31,41)])
  smop_hiDR_HUTY[r,7:10]<-round(smop_hiDR[[3]][[r]]$Occ_HU_MF[c(11,21,31,41)])
  smop_hiDR_HUTY[r,11:14]<-round(smop_hiDR[[3]][[r]]$Occ_HU_MH[c(11,21,31,41)])
  
}

names(smop_hiDR_HUTC)<-gsub('Tot_HU_','',names(smop_hiDR_HUTC))
smop_hiDR_HUTC<-merge(smop_hiDR_HUTC,ctycode)

smop_hiDR_m<-melt(smop_hiDR_HUTC)
smop_hiDR_m<-smop_hiDR_m[,-2]
smop_hiDR_m$Type<-substr(smop_hiDR_m$variable,1,2)
smop_hiDR_m$Vintage<-paste(substr(smop_hiDR_m$variable,8,11),'s',sep="")
smop_hiDR_m$Year<-substr(smop_hiDR_m$variable,16,19)
smop_hiDR_m$State<-substr(smop_hiDR_m$RS_ID,1,2)

sum_stcy<-as.data.frame(tapply(smop_hiDR_m$value,list(smop_hiDR_m$Type,smop_hiDR_m$Vintage,smop_hiDR_m$Year,smop_hiDR_m$State),sum))
sum_stcy$Type<-rownames(sum_stcy)
sum_stcy<-melt(sum_stcy)
sum_stcy$Year<-substr(sum_stcy$variable,7,10)
sum_stcy$Vintage<-substr(sum_stcy$variable,1,5)
sum_stcy$State<-substr(sum_stcy$variable,12,13)
sum_stcy<-sum_stcy[complete.cases(sum_stcy),]

yrs<-seq(2030,2060,10)
# subtract the 5 year total from the decade total to calculate what is built in the second half
for (y in yrs) {
  sum_stcy[sum_stcy$Year==y,]$value<-sum_stcy[sum_stcy$Year==y,]$value-sum_stcy[sum_stcy$Year==y-5,]$value
}
names(sum_stcy)[3]<-'UnitCount'

rs_hiDR$Type3<-str_sub(rs_hiDR$ctyTC,-10,-9)
rs_hiDR$St_TC_Year<-paste(rs_hiDR$State,rs_hiDR$Type3,rs_hiDR$Vintage.ACS,sep="_")
stcy<-as.data.frame(table(rs_hiDR$St_TC,rs_hiDR$Year))
stcy$Type<-substr(stcy$Var1,4,5)
stcy$State<-substr(stcy$Var1,1,2)
stcy$Vintage<-substr(stcy$Var1,7,11)
names(stcy)[2]<-'Year'
names(stcy)[3]<-'SampleCount'
stcy<-stcy[,-1]

stcy_comp<-merge(sum_stcy,stcy,by=c('Year','Vintage','State','Type'),all.x = TRUE)
stcy_comp<-stcy_comp[!stcy_comp$State %in% c('AK','HI'), ]
stcy_comp[is.na(stcy_comp$SampleCount),]$SampleCount<-0
stcy_comp$wf<-stcy_comp$UnitCount/stcy_comp$SampleCount
stcy_comp[is.infinite(stcy_comp$wf),]$wf<-median(stcy_comp$wf)
# see how it compares by type
tapply(stcy_comp$wf,stcy_comp$Type,mean)
tapply(stcy_comp$wf,stcy_comp$Type,median)

round(tapply(stcy_comp$wf,list(stcy_comp$Type,stcy_comp$State),mean))
stcy_comp_hiDR<-stcy_comp

stock_tcy<-melt(smop_hiDR_HUTY)
stock_tcy<-merge(stock_tcy,ctycode)
stock_tcy$State<-substr(stock_tcy$RS_ID,1,2)
stock_tcy$Type<-substr(stock_tcy$variable,1,2)
stock_tcy$Year<-substr(stock_tcy$variable,4,7)
stock_tcy<-stock_tcy[,c(5:8,4)]
names(stock_tcy)[c(1,3,5)]<-c('County','Type3','UnitCount')
stock_tsy<-stock_tcy[,2:5]%>%group_by(Year,State,Type3)%>%summarise_all(funs(sum))

stock_tcy_hiDR<-stock_tcy
stock_tsy_hiDR<-stock_tsy

# repeat for hiMF ########

# start a dataframe in which to extract the unit totals 
smop_hiMF_HUTC<-smop_hiMF[,1:2]

smop_hiMF_HUTC[,paste(rep(names(smop_hiMF[[3]][[1]])[c(116:119,136:139,156:159)],each=2),rep(seq(2025,2060,5),2),sep="_")]<-0

# start a dataframe in which to extract the totals by type in future decades
smop_hiMF_HUTY<-smop_hiMF[,1:2]
smop_hiMF_HUTY[,paste(rep(names(smop_hiMF[[3]][[1]])[15:17],each=4),seq(2030,2060,10),sep="_")]<-0
names(smop_hiMF_HUTY)<-gsub('Occ_HU_','',names(smop_hiMF_HUTY))
for (r in 1:3142) {
  
  smop_hiMF_HUTC[r,c(3:4)]<-smop_hiMF[[3]][[r]]$Tot_HU_SF_Occ_2020_29[c(6,11)]
  smop_hiMF_HUTC[r,c(5:6)]<-smop_hiMF[[3]][[r]]$Tot_HU_SF_Occ_2030_39[c(16,21)]
  smop_hiMF_HUTC[r,c(7:8)]<-smop_hiMF[[3]][[r]]$Tot_HU_SF_Occ_2040_49[c(26,31)]
  smop_hiMF_HUTC[r,c(9:10)]<-smop_hiMF[[3]][[r]]$Tot_HU_SF_Occ_2050_60[c(36,41)]
  
  smop_hiMF_HUTC[r,c(11:12)]<-smop_hiMF[[3]][[r]]$Tot_HU_MF_Occ_2020_29[c(6,11)]
  smop_hiMF_HUTC[r,c(13:14)]<-smop_hiMF[[3]][[r]]$Tot_HU_MF_Occ_2030_39[c(16,21)]
  smop_hiMF_HUTC[r,c(15:16)]<-smop_hiMF[[3]][[r]]$Tot_HU_MF_Occ_2040_49[c(26,31)]
  smop_hiMF_HUTC[r,c(17:18)]<-smop_hiMF[[3]][[r]]$Tot_HU_MF_Occ_2050_60[c(36,41)]
  
  smop_hiMF_HUTC[r,c(19:20)]<-smop_hiMF[[3]][[r]]$Tot_HU_MH_Occ_2020_29[c(6,11)]
  smop_hiMF_HUTC[r,c(21:22)]<-smop_hiMF[[3]][[r]]$Tot_HU_MH_Occ_2030_39[c(16,21)]
  smop_hiMF_HUTC[r,c(23:24)]<-smop_hiMF[[3]][[r]]$Tot_HU_MH_Occ_2040_49[c(26,31)]
  smop_hiMF_HUTC[r,c(25:26)]<-smop_hiMF[[3]][[r]]$Tot_HU_MH_Occ_2050_60[c(36,41)]
  
  smop_hiMF_HUTY[r,3:6]<-round(smop_hiMF[[3]][[r]]$Occ_HU_SF[c(11,21,31,41)])
  smop_hiMF_HUTY[r,7:10]<-round(smop_hiMF[[3]][[r]]$Occ_HU_MF[c(11,21,31,41)])
  smop_hiMF_HUTY[r,11:14]<-round(smop_hiMF[[3]][[r]]$Occ_HU_MH[c(11,21,31,41)])
  
}

names(smop_hiMF_HUTC)<-gsub('Tot_HU_','',names(smop_hiMF_HUTC))
smop_hiMF_HUTC<-merge(smop_hiMF_HUTC,ctycode)

smop_hiMF_m<-melt(smop_hiMF_HUTC)
smop_hiMF_m<-smop_hiMF_m[,-2]
smop_hiMF_m$Type<-substr(smop_hiMF_m$variable,1,2)
smop_hiMF_m$Vintage<-paste(substr(smop_hiMF_m$variable,8,11),'s',sep="")
smop_hiMF_m$Year<-substr(smop_hiMF_m$variable,16,19)
smop_hiMF_m$State<-substr(smop_hiMF_m$RS_ID,1,2)

sum_stcy<-as.data.frame(tapply(smop_hiMF_m$value,list(smop_hiMF_m$Type,smop_hiMF_m$Vintage,smop_hiMF_m$Year,smop_hiMF_m$State),sum))
sum_stcy$Type<-rownames(sum_stcy)
sum_stcy<-melt(sum_stcy)
sum_stcy$Year<-substr(sum_stcy$variable,7,10)
sum_stcy$Vintage<-substr(sum_stcy$variable,1,5)
sum_stcy$State<-substr(sum_stcy$variable,12,13)
sum_stcy<-sum_stcy[complete.cases(sum_stcy),]

yrs<-seq(2030,2060,10)
# subtract the 5 year total from the decade total to calculate what is built in the second half
for (y in yrs) {
  sum_stcy[sum_stcy$Year==y,]$value<-sum_stcy[sum_stcy$Year==y,]$value-sum_stcy[sum_stcy$Year==y-5,]$value
}
names(sum_stcy)[3]<-'UnitCount'

rs_hiMF$Type3<-str_sub(rs_hiMF$ctyTC,-10,-9)
rs_hiMF$St_TC_Year<-paste(rs_hiMF$State,rs_hiMF$Type3,rs_hiMF$Vintage.ACS,sep="_")
stcy<-as.data.frame(table(rs_hiMF$St_TC,rs_hiMF$Year))
stcy$Type<-substr(stcy$Var1,4,5)
stcy$State<-substr(stcy$Var1,1,2)
stcy$Vintage<-substr(stcy$Var1,7,11)
names(stcy)[2]<-'Year'
names(stcy)[3]<-'SampleCount'
stcy<-stcy[,-1]

stcy_comp<-merge(sum_stcy,stcy,by=c('Year','Vintage','State','Type'),all.x = TRUE)
stcy_comp<-stcy_comp[!stcy_comp$State %in% c('AK','HI'), ]
stcy_comp[is.na(stcy_comp$SampleCount),]$SampleCount<-0
stcy_comp$wf<-stcy_comp$UnitCount/stcy_comp$SampleCount
stcy_comp[is.infinite(stcy_comp$wf),]$wf<-median(stcy_comp$wf)
# see how it compares by type
tapply(stcy_comp$wf,stcy_comp$Type,mean)
tapply(stcy_comp$wf,stcy_comp$Type,median)

round(tapply(stcy_comp$wf,list(stcy_comp$Type,stcy_comp$State),mean))
stcy_comp_hiMF<-stcy_comp

stock_tcy<-melt(smop_hiMF_HUTY)
stock_tcy<-merge(stock_tcy,ctycode)
stock_tcy$State<-substr(stock_tcy$RS_ID,1,2)
stock_tcy$Type<-substr(stock_tcy$variable,1,2)
stock_tcy$Year<-substr(stock_tcy$variable,4,7)
stock_tcy<-stock_tcy[,c(5:8,4)]
names(stock_tcy)[c(1,3,5)]<-c('County','Type3','UnitCount')
stock_tsy<-stock_tcy[,2:5]%>%group_by(Year,State,Type3)%>%summarise_all(funs(sum))

stock_tcy_hiMF<-stock_tcy
stock_tsy_hiMF<-stock_tsy

save(stcy_comp_base,stcy_comp_hiDR,stcy_comp_hiMF,
     stock_tcy_base,stock_tcy_hiDR,stock_tcy_hiMF,
     stock_tsy_base,stock_tsy_hiDR,stock_tsy_hiMF,
     file='../Intermediate_results/base_weights_NC.RData')