# RS results interpretation 
# This script reads in the results csv and uses it to calculate energy consumption by fuel and end use
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console

# Last Update Peter Berrill May 2 2022

# Purpose: Calculate % reductions in final energy consumption from different renovation families in each renovation scenario, for SI Tables S6 and S7. Calculate number of renovations by type in each ren scenario

# Inputs: - Intermediate_results/RenStandard_EG.RData
#         - Intermediate_results/RenAdvanced_EG.RData
#         - Intermediate_results/RenExtElec_EG.RData

# Outputs: 
#         - SI_Tables/heat_age_reg_rr.csv, ... , etc for cool, dhw, env and rr, ar, er
#         - SI_Tables/heat_typ_age_rr.csv, ... , etc for cool, dhw, env and rr, ar, er

library(dplyr)
library(reshape2)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/")

# regular renovations ###########
load("Intermediate_results/RenStandard_EG.RData")
# stockwide avg effects of individual retrofits
tapply(rs_RRn$redn_cren,rs_RRn$change_cren_only,mean) # 0.14%
tapply(rs_RRn$redn_iren,rs_RRn$change_iren_only,mean) # 13.9%
tapply(rs_RRn$redn_wren,rs_RRn$change_wren_only,mean) # 3.25#
tapply(rs_RRn$redn_hren,rs_RRn$change_hren_only,mean) # 6.5%

# avg effects by building type
tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in SFD and MH, negative in MF
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in MF2-4 & SFD (both 15%)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in SFA (4.8%), lowest in MH
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in SFD (7.5%) & MH (7.2%)

# avg effects by vintage
tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Vintage), mean) # negative in older homes (<1970)
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Vintage), mean) # highest in older homes (~20%)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Vintage), mean) # reasonably steady across vintages, slightly higher in older homes
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Vintage), mean) # highest in older homes (>8%)

# advanced renovations ############
load("Intermediate_results/RenAdvanced_EG.RData")
# stockwide avg effects of individual retrofits
tapply(rs_ARn$redn_cren,rs_ARn$change_cren_only,mean) # 0.24%
tapply(rs_ARn$redn_iren,rs_ARn$change_iren_only,mean) # 11.9%
tapply(rs_ARn$redn_wren,rs_ARn$change_wren_only,mean) # 5.0#
tapply(rs_ARn$redn_hren,rs_ARn$change_hren_only,mean) # 10.2%

# avg effects by building type
tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # highest in SFD and MH, negative in MF
tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # highest in MF2-4 & SFD (14% and 12.7%)
tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # highest in SFA (6%) and MF5+ (6.5%)
tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # highest in SFD (11%) & MH (10.6%)

# avg effects by vintage
tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Vintage), mean) # negative in older homes (<1950)
tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Vintage), mean) # highest in older homes (17-18%)
tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Vintage), mean) # reasonably steady across vintages
tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Vintage), mean) # highest in older homes (12-13%)

# extensive renovations ##########
load("Intermediate_results/RenExtElec_EG.RData")
# stockwide avg effects of individual retrofits
tapply(rs_ERn$redn_cren,rs_ERn$change_cren_only,mean) # 0.21%
tapply(rs_ERn$redn_iren,rs_ERn$change_iren_only,mean) # 9.8%
tapply(rs_ERn$redn_wren,rs_ERn$change_wren_only,mean) # 7.2#
tapply(rs_ERn$redn_hren,rs_ERn$change_hren_only,mean) # 15.1%

# avg effects by building type
tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # highest in SFD and MH, negative in MF
tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # highest in MF2-4 (12.5%) & SFD (10.3%)
tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # highest in SFA (9.5%) and SFA (8.3%)
tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # 16-17% in SFD, MH, and MF2-4

# avg effects by vintage
tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Vintage), mean) # negative in older homes (<1970)
tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Vintage), mean) # highest in older homes (14-15%)
tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Vintage), mean) # steady across vintages
tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Vintage), mean) # highest in older homes (~20%)

# 2D tables ###########
heat_typ_reg_rr<-tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 
cool_typ_reg_rr<-tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 
dhw_typ_reg_rr<-tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 
ins_typ_reg_rr<-tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 

heat_age_reg_rr<-tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 
cool_age_reg_rr<-tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 
dhw_age_reg_rr<-tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 
ins_age_reg_rr<-tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 

heat_typ_age_rr<-tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 
cool_typ_age_rr<-tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 
dhw_typ_age_rr<-tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 
ins_typ_age_rr<-tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 

heat_typ_reg_ar<-tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 
cool_typ_reg_ar<-tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 
dhw_typ_reg_ar<-tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 
ins_typ_reg_ar<-tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 

heat_age_reg_ar<-tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 
cool_age_reg_ar<-tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 
dhw_age_reg_ar<-tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 
ins_age_reg_ar<-tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 

heat_typ_age_ar<-tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 
cool_typ_age_ar<-tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 
dhw_typ_age_ar<-tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 
ins_typ_age_ar<-tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 

heat_typ_reg_er<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
cool_typ_reg_er<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
dhw_typ_reg_er<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
ins_typ_reg_er<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 

heat_age_reg_er<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
cool_age_reg_er<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
dhw_age_reg_er<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
ins_age_reg_er<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 

heat_typ_age_er<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
cool_typ_age_er<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
dhw_typ_age_er<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
ins_typ_age_er<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 


# write tables ######
# by age and region
write.csv(round(100*heat_age_reg_rr,2),file="SI_Tables/heat_age_reg_rr.csv")
write.csv(round(100*heat_age_reg_ar,2),file="SI_Tables/heat_age_reg_ar.csv")
write.csv(round(100*heat_age_reg_er,2),file="SI_Tables/heat_age_reg_er.csv")

write.csv(round(100*cool_age_reg_rr,2),file="SI_Tables/cool_age_reg_rr.csv")
write.csv(round(100*cool_age_reg_ar,2),file="SI_Tables/cool_age_reg_ar.csv")
write.csv(round(100*cool_age_reg_er,2),file="SI_Tables/cool_age_reg_er.csv")

write.csv(round(100*dhw_age_reg_rr,2),file="SI_Tables/dhw_age_reg_rr.csv")
write.csv(round(100*dhw_age_reg_ar,2),file="SI_Tables/dhw_age_reg_ar.csv")
write.csv(round(100*dhw_age_reg_er,2),file="SI_Tables/dhw_age_reg_er.csv")

write.csv(round(100*ins_age_reg_rr,2),file="SI_Tables/env_age_reg_rr.csv")
write.csv(round(100*ins_age_reg_ar,2),file="SI_Tables/env_age_reg_ar.csv")
write.csv(round(100*ins_age_reg_er,2),file="SI_Tables/env_age_reg_er.csv")

# by type and age
write.csv(round(100*heat_typ_age_rr,2),file="SI_Tables/heat_typ_age_rr.csv")
write.csv(round(100*heat_typ_age_ar,2),file="SI_Tables/heat_typ_age_ar.csv")
write.csv(round(100*heat_typ_age_er,2),file="SI_Tables/heat_typ_age_er.csv")

write.csv(round(100*cool_typ_age_rr,2),file="SI_Tables/cool_typ_age_rr.csv")
write.csv(round(100*cool_typ_age_ar,2),file="SI_Tables/cool_typ_age_ar.csv")
write.csv(round(100*cool_typ_age_er,2),file="SI_Tables/cool_typ_age_er.csv")

write.csv(round(100*dhw_typ_age_rr,2),file="SI_Tables/dhw_typ_age_rr.csv")
write.csv(round(100*dhw_typ_age_ar,2),file="SI_Tables/dhw_typ_age_ar.csv")
write.csv(round(100*dhw_typ_age_er,2),file="SI_Tables/dhw_typ_age_er.csv")

write.csv(round(100*ins_typ_age_rr,2),file="SI_Tables/env_typ_age_rr.csv")
write.csv(round(100*ins_typ_age_ar,2),file="SI_Tables/env_typ_age_ar.csv")
write.csv(round(100*ins_typ_age_er,2),file="SI_Tables/env_typ_age_er.csv")

# renovation counts ###################
rs_RRn$change_hren_true<-rs_RRn$change_hren>0
rs_RRn$change_iren_true<-rs_RRn$change_iren>0
rs_RRn$change_wren_true<-rs_RRn$change_wren>0

rs_ARn$change_hren_true<-rs_ARn$change_hren>0
rs_ARn$change_iren_true<-rs_ARn$change_iren>0
rs_ARn$change_wren_true<-rs_ARn$change_wren>0

rs_ERn$change_hren_true<-rs_ERn$change_hren>0
rs_ERn$change_iren_true<-rs_ERn$change_iren>0
rs_ERn$change_wren_true<-rs_ERn$change_wren>0

# heating
rencount<-data.frame(Year=rep(seq(2025,2060,5),each=9),Scen=rep(rep(c("RR","AR","ER"),each=3),8),Ren=rep(c("heat","env","water"),24),count=0)

rencount[rencount$Year==2025&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2025*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2030*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2035*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2045*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2045*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2050*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2055*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="RR"&rencount$Ren=="heat",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2060*rs_RRn$change_hren_true,rs_RRn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2025*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2030*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2035*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2045*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2045*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2050*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2055*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="AR"&rencount$Ren=="heat",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2060*rs_ARn$change_hren_true,rs_ARn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2025*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2030*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2035*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2045*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2045*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2050*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2055*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="ER"&rencount$Ren=="heat",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2060*rs_ERn$change_hren_true,rs_ERn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2025*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2030*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2035*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2045*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2045*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2050*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2055*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="RR"&rencount$Ren=="env",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2060*rs_RRn$change_iren_true,rs_RRn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2025*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2030*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2035*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2045*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2045*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2050*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2055*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="AR"&rencount$Ren=="env",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2060*rs_ARn$change_iren_true,rs_ARn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2025*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2030*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2035*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2045*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2045*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2050*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2055*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="ER"&rencount$Ren=="env",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2060*rs_ERn$change_iren_true,rs_ERn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2025*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2030*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2035*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2045*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2045*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2050*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2055*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="RR"&rencount$Ren=="water",]$count<-tapply(rs_RRn$base_weight*rs_RRn$wbase_2060*rs_RRn$change_wren_true,rs_RRn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2025*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2030*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2035*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2045*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2045*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2050*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2055*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="AR"&rencount$Ren=="water",]$count<-tapply(rs_ARn$base_weight*rs_ARn$wbase_2060*rs_ARn$change_wren_true,rs_ARn$Year,sum)["2060"]/5e6

rencount[rencount$Year==2025&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2025*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2025"]/5e6
rencount[rencount$Year==2030&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2030*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2030"]/5e6
rencount[rencount$Year==2035&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2035*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2035"]/5e6
rencount[rencount$Year==2040&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2045*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2045&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2045*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2045"]/5e6
rencount[rencount$Year==2050&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2050*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2050"]/5e6
rencount[rencount$Year==2055&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2055*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2055"]/5e6
rencount[rencount$Year==2060&rencount$Scen=="ER"&rencount$Ren=="water",]$count<-tapply(rs_ERn$base_weight*rs_ERn$wbase_2060*rs_ERn$change_wren_true,rs_ERn$Year,sum)["2060"]/5e6

tapply(rencount$count,list(rencount$Scen,rencount$Ren),mean)
tapply(rencount$count,list(rencount$Scen,rencount$Ren),median)

rencount2<-rencount
names(rencount2)<-c("Year","RenScen","RenType","count")

# make ggplot 
library(ggplot2)
windows()
ggplot(rencount2,aes(Year,count)) + geom_point(aes(shape=RenType,colour=RenScen)) + theme_bw() + ylim(0,8.5) + geom_line(aes(linetype=RenType,color=RenScen)) + 
  labs(title="Renovations per year, by scenario and type",y = "Mill Housing Units") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))