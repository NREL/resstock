# script to calculate floor area and GHG of envelope renovations every 5 years 2025 - 2060
library(ggplot2)
library(dplyr)
library(reshape2)
library(stringr)

# Last Update Peter Berrill May 2 2022

# Purpose: Calculate floor area and GHG of envelope renovations for each five years 2020-2060, by county and house type (3), and national totals

# Inputs: - ExtData/Arch_intensities.RData, material and GHG intensities (in kg material/m2, kgCO2e/ m2 respectively) of 270 housing archetypes, defined in https://github.com/peterberr/US_county_HSM
#         - scen_bscsv/bs2020_180k.csv, initial 2020 stock
#         - RenStandard_EG.RData
#         - RenAdvancedEG.RData
#         - RenExtElec_EG.RData

# Outputs: 
#         - Final_results/renGHG.RData
#         - Final_results/renGHG_cty_type.RData


rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/")
load("ExtData/Arch_intensities.RData")
bs2020<-read.csv('scen_bscsv/bs2020_180k.csv')
bs2020<-bs2020[,c("Building","Geometry.Building.Number.Units.HL","Geometry.Floor.Area.Bin")] # just get the columns excluded from the rs_ dataframes

# reg renovation ############
load("Intermediate_results/RenStandard_EG.RData")
rs_RR_ren<-rs_RRn[,c("Year","Building","Year_Building","Census.Division", "Geometry.Floor.Area","floor_area_lighting_ft_2","Geometry.Building.Type.RECS",
                     "Geometry.Foundation.Type","Geometry.Stories","Geometry.Garage", "insulation_slab","insulation_crawlspace","insulation_finished_basement",
                    "insulation_unfinished_attic", "insulation_unfinished_basement","insulation_wall", "County",  "ctyTC","base_weight","change_iren",
                     "wbase_2020","wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060",
                     "whiDR_2020","whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060",
                     "whiMF_2020","whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")]
weights<-c("wbase_2020","wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060",
            "whiDR_2020","whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060",
             "whiMF_2020","whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")
rs_RR_ren<-merge(rs_RR_ren,bs2020,by='Building')

# make sure renovations are counted only once, this means that e.g. a 2027 renovation will only be counted in 2030, not in 2035 or after. 
# this would not be the case if e.g. a house with an insulation renovation in 2027 then got a heating renovation in 2031 and a cooling renovation in 2038, which would mean they would be included in the ren df also in 2035 and 2040
# but we are concerned only with envelope/insulation renovations.
# there are some counties in which no home ever undergoes an insulation renovation, thus, this operation also removes those (36) counties completely

rs_RR_ren<-rs_RR_ren[(rs_RR_ren$Year-rs_RR_ren$change_iren)<5,]
# if year is 2025, only the decay factors for 2025 should be non-zero
for (yr in seq(2025,2060,5)) {
  we<-weights[-c(ends_with(as.character(yr),vars = weights))]
  rs_RR_ren[rs_RR_ren$Year==yr ,we]<-0
}


# tot housing units, base stock evolution
rs_RR_ren[,c("base HU 2020","base HU 2025","base HU 2030","base HU 2035","base HU 2040","base HU 2045","base HU 2050","base HU 2055","base HU 2060")]<-
  rs_RR_ren$base_weight*rs_RR_ren[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

# tot housing units, hiDR stock evolution
rs_RR_ren[,c("hiDR HU 2020","hiDR HU 2025","hiDR HU 2030","hiDR HU 2035","hiDR HU 2040","hiDR HU 2045","hiDR HU 2050","hiDR HU 2055","hiDR HU 2060")]<-
  rs_RR_ren$base_weight*rs_RR_ren[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]

# tot housing units, hiMF stock evolution
rs_RR_ren[,c("hiMF HU 2020","hiMF HU 2025","hiMF HU 2030","hiMF HU 2035","hiMF HU 2040","hiMF HU 2045","hiMF HU 2050","hiMF HU 2055","hiMF HU 2060")]<-
  rs_RR_ren$base_weight*rs_RR_ren[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

# calc per unit FA 
rs_RR_ren$Type3<-"MF"
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_RR_ren$Geometry.Building.Type.RECS=="Single-Family Detached",]$Type3<-"SF"
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS=="Mobile Home",]$Type3<-"MH"

rs_RR_ren$Floor.Area.m2<-0
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="0-499"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(328/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="0-499"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(317/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="0-499"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(333/10.765,1)

rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="500-749"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(633/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="500-749"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(617/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="500-749"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(617/10.765,1)

rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="750-999"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(885/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="750-999"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(866/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="750-999"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(853/10.765,1)

rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="1000-1499"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(1220/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="1000-1499"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(1202/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="1000-1499"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(1138/10.765,1)

rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="1500-1999"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(1690/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="1500-1999"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(1675/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="1500-1999"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(1623/10.765,1)

rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="2000-2499"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(2176/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="2000-2499"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(2152/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="2000-2499"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(2115/10.765,1)

rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="2500-2999"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(2663/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="2500-2999"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(2631/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="2500-2999"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(2590/10.765,1)

rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="3000-3999"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(3301/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="3000-3999"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(3241/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="3000-3999"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(3138/10.765,1)
# 4000+. Using my own estimates here, consistent with my changes to options_lookup, but creating different value for MH
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="4000+"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached"),]$Floor.Area.m2<-round(7500/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="4000+"&rs_RR_ren$Geometry.Building.Type.RECS %in% c("Mobile Home"),]$Floor.Area.m2<-round(4200/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="4000+"&rs_RR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(7000/10.765,1)
rs_RR_ren[rs_RR_ren$Geometry.Floor.Area=="4000+"&rs_RR_ren$Type3=="MF",]$Floor.Area.m2<-round(7000/10.765,1)

# tot floor area, measure 2
rs_RR_ren[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")]<-
  rs_RR_ren$Floor.Area.m2*rs_RR_ren[,c("base HU 2020",  "base HU 2025", "base HU 2030", "base HU 2035", "base HU 2040", "base HU 2045", "base HU 2050", "base HU 2055", "base HU 2060")]
colSums(as.numeric(rs_RR_ren$change_iren>0)*rs_RR_ren[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")])

rs_RR_ren[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")]<-
  rs_RR_ren$Floor.Area.m2*rs_RR_ren[,c("hiDR HU 2020",  "hiDR HU 2025", "hiDR HU 2030", "hiDR HU 2035", "hiDR HU 2040", "hiDR HU 2045", "hiDR HU 2050", "hiDR HU 2055", "hiDR HU 2060")]
colSums(as.numeric(rs_RR_ren$change_iren>0)*rs_RR_ren[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")])

rs_RR_ren[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")]<-
  rs_RR_ren$Floor.Area.m2*rs_RR_ren[,c("hiMF HU 2020",  "hiMF HU 2025", "hiMF HU 2030", "hiMF HU 2035", "hiMF HU 2040", "hiMF HU 2045", "hiMF HU 2050", "hiMF HU 2055", "hiMF HU 2060")]
colSums(as.numeric(rs_RR_ren$change_iren>0)*rs_RR_ren[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")])

# advanced renovation ########
load("Intermediate_results/RenAdvanced_EG.RData")
rs_AR_ren<-rs_ARn[,c("Year","Building","Year_Building","Census.Division", "Geometry.Floor.Area","floor_area_lighting_ft_2","Geometry.Building.Type.RECS",
                     "Geometry.Foundation.Type","Geometry.Stories","Geometry.Garage", "insulation_slab","insulation_crawlspace","insulation_finished_basement",
                     "insulation_unfinished_attic", "insulation_unfinished_basement","insulation_wall", "County",  "ctyTC","base_weight","change_iren",
                     "wbase_2020","wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060",
                     "whiDR_2020","whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060",
                     "whiMF_2020","whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")]
rs_AR_ren<-merge(rs_AR_ren,bs2020,by='Building')
# make sure renovations are counted only once. in this case, only 5 counties which never undergo insulation renovations are removed
rs_AR_ren<-rs_AR_ren[(rs_AR_ren$Year-rs_AR_ren$change_iren)<5,]
# if year is 2025, only the decay factors for 2025 should be non-zero
for (yr in seq(2025,2060,5)) {
  we<-weights[-c(ends_with(as.character(yr),vars = weights))]
  rs_AR_ren[rs_AR_ren$Year==yr ,we]<-0
}

# tot housing units, base stock evolution
rs_AR_ren[,c("base HU 2020","base HU 2025","base HU 2030","base HU 2035","base HU 2040","base HU 2045","base HU 2050","base HU 2055","base HU 2060")]<-
  rs_AR_ren$base_weight*rs_AR_ren[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

# tot housing units, hiDR stock evolution
rs_AR_ren[,c("hiDR HU 2020","hiDR HU 2025","hiDR HU 2030","hiDR HU 2035","hiDR HU 2040","hiDR HU 2045","hiDR HU 2050","hiDR HU 2055","hiDR HU 2060")]<-
  rs_AR_ren$base_weight*rs_AR_ren[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]

# tot housing units, hiMF stock evolution
rs_AR_ren[,c("hiMF HU 2020","hiMF HU 2025","hiMF HU 2030","hiMF HU 2035","hiMF HU 2040","hiMF HU 2045","hiMF HU 2050","hiMF HU 2055","hiMF HU 2060")]<-
  rs_AR_ren$base_weight*rs_AR_ren[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

# calc pre unit FA the original way
rs_AR_ren$Type3<-"MF"
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_AR_ren$Geometry.Building.Type.RECS=="Single-Family Detached",]$Type3<-"SF"
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS=="Mobile Home",]$Type3<-"MH"

rs_AR_ren$Floor.Area.m2<-0
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="0-499"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(328/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="0-499"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(317/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="0-499"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(333/10.765,1)

rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="500-749"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(633/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="500-749"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(617/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="500-749"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(617/10.765,1)

rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="750-999"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(885/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="750-999"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(866/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="750-999"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(853/10.765,1)

rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="1000-1499"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(1220/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="1000-1499"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(1202/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="1000-1499"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(1138/10.765,1)

rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="1500-1999"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(1690/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="1500-1999"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(1675/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="1500-1999"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(1623/10.765,1)

rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="2000-2499"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(2176/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="2000-2499"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(2152/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="2000-2499"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(2115/10.765,1)

rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="2500-2999"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(2663/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="2500-2999"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(2631/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="2500-2999"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(2590/10.765,1)

rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="3000-3999"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(3301/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="3000-3999"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(3241/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="3000-3999"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(3138/10.765,1)
# 4000+. Using my own estimates here, consistent with my changes to options_lookup, but creating different value for MH
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="4000+"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached"),]$Floor.Area.m2<-round(7500/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="4000+"&rs_AR_ren$Geometry.Building.Type.RECS %in% c("Mobile Home"),]$Floor.Area.m2<-round(4200/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="4000+"&rs_AR_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(7000/10.765,1)
rs_AR_ren[rs_AR_ren$Geometry.Floor.Area=="4000+"&rs_AR_ren$Type3=="MF",]$Floor.Area.m2<-round(7000/10.765,1)

# tot floor area, measure 2
rs_AR_ren[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")]<-
  rs_AR_ren$Floor.Area.m2*rs_AR_ren[,c("base HU 2020",  "base HU 2025", "base HU 2030", "base HU 2035", "base HU 2040", "base HU 2045", "base HU 2050", "base HU 2055", "base HU 2060")]

colSums(as.numeric(rs_AR_ren$change_iren>0)*rs_AR_ren[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")])

rs_AR_ren[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")]<-
  rs_AR_ren$Floor.Area.m2*rs_AR_ren[,c("hiDR HU 2020",  "hiDR HU 2025", "hiDR HU 2030", "hiDR HU 2035", "hiDR HU 2040", "hiDR HU 2045", "hiDR HU 2050", "hiDR HU 2055", "hiDR HU 2060")]
colSums(as.numeric(rs_AR_ren$change_iren>0)*rs_AR_ren[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")])

rs_AR_ren[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")]<-
  rs_AR_ren$Floor.Area.m2*rs_AR_ren[,c("hiMF HU 2020",  "hiMF HU 2025", "hiMF HU 2030", "hiMF HU 2035", "hiMF HU 2040", "hiMF HU 2045", "hiMF HU 2050", "hiMF HU 2055", "hiMF HU 2060")]
colSums(as.numeric(rs_AR_ren$change_iren>0)*rs_AR_ren[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")])

# Extensive renovation ########
load("Intermediate_results/RenExtElec_EG.RData")
rs_ER_ren<-rs_ERn[,c("Year","Building","Year_Building","Census.Division", "Geometry.Floor.Area","floor_area_lighting_ft_2","Geometry.Building.Type.RECS",
                     "Geometry.Foundation.Type","Geometry.Stories","Geometry.Garage", "insulation_slab","insulation_crawlspace","insulation_finished_basement",
                     "insulation_unfinished_attic", "insulation_unfinished_basement","insulation_wall", "County", "ctyTC","base_weight","change_iren",
                     "wbase_2020","wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060",
                     "whiDR_2020","whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060",
                     "whiMF_2020","whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")]

rs_ER_ren<-merge(rs_ER_ren,bs2020,by='Building')
# make sure renovations are counted only once. this time, 7 counties are removed which never undergo insulation renovations
rs_ER_ren<-rs_ER_ren[(rs_ER_ren$Year-rs_ER_ren$change_iren)<5,]
# if year is 2025, only the decay factors for 2025 should be non-zero
for (yr in seq(2025,2060,5)) {
  we<-weights[-c(ends_with(as.character(yr),vars = weights))]
  rs_ER_ren[rs_ER_ren$Year==yr ,we]<-0
}

# tot housing units, base stock evolution
rs_ER_ren[,c("base HU 2020","base HU 2025","base HU 2030","base HU 2035","base HU 2040","base HU 2045","base HU 2050","base HU 2055","base HU 2060")]<-
  rs_ER_ren$base_weight*rs_ER_ren[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

# tot housing units, hiDR stock evolution
rs_ER_ren[,c("hiDR HU 2020","hiDR HU 2025","hiDR HU 2030","hiDR HU 2035","hiDR HU 2040","hiDR HU 2045","hiDR HU 2050","hiDR HU 2055","hiDR HU 2060")]<-
  rs_ER_ren$base_weight*rs_ER_ren[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]

# tot housing units, hiMF stock evolution
rs_ER_ren[,c("hiMF HU 2020","hiMF HU 2025","hiMF HU 2030","hiMF HU 2035","hiMF HU 2040","hiMF HU 2045","hiMF HU 2050","hiMF HU 2055","hiMF HU 2060")]<-
  rs_ER_ren$base_weight*rs_ER_ren[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

# calc pre unit FA the original way
rs_ER_ren$Type3<-"MF"
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_ER_ren$Geometry.Building.Type.RECS=="Single-Family Detached",]$Type3<-"SF"
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS=="Mobile Home",]$Type3<-"MH"

rs_ER_ren$Floor.Area.m2<-0
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="0-499"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(328/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="0-499"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(317/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="0-499"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(333/10.765,1)

rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="500-749"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(633/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="500-749"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(617/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="500-749"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(617/10.765,1)

rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="750-999"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(885/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="750-999"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(866/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="750-999"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(853/10.765,1)

rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="1000-1499"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(1220/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="1000-1499"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(1202/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="1000-1499"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(1138/10.765,1)

rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="1500-1999"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(1690/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="1500-1999"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(1675/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="1500-1999"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(1623/10.765,1)

rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="2000-2499"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(2176/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="2000-2499"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(2152/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="2000-2499"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(2115/10.765,1)

rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="2500-2999"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(2663/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="2500-2999"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(2631/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="2500-2999"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(2590/10.765,1)

rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="3000-3999"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Mobile Home"),]$Floor.Area.m2<-round(3301/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="3000-3999"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(3241/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="3000-3999"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(3138/10.765,1)
# 4000+. Using my own estimates here, consistent with my changes to options_lookup, but creating different value for MH
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="4000+"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached"),]$Floor.Area.m2<-round(7500/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="4000+"&rs_ER_ren$Geometry.Building.Type.RECS %in% c("Mobile Home"),]$Floor.Area.m2<-round(4200/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="4000+"&rs_ER_ren$Geometry.Building.Type.RECS == "Single-Family Attached",]$Floor.Area.m2<-round(7000/10.765,1)
rs_ER_ren[rs_ER_ren$Geometry.Floor.Area=="4000+"&rs_ER_ren$Type3=="MF",]$Floor.Area.m2<-round(7000/10.765,1)

# tot floor area, measure 2
rs_ER_ren[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")]<-
  rs_ER_ren$Floor.Area.m2*rs_ER_ren[,c("base HU 2020",  "base HU 2025", "base HU 2030", "base HU 2035", "base HU 2040", "base HU 2045", "base HU 2050", "base HU 2055", "base HU 2060")]
colSums(as.numeric(rs_ER_ren$change_iren>0)*rs_ER_ren[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")])

rs_ER_ren[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")]<-
  rs_ER_ren$Floor.Area.m2*rs_ER_ren[,c("hiDR HU 2020",  "hiDR HU 2025", "hiDR HU 2030", "hiDR HU 2035", "hiDR HU 2040", "hiDR HU 2045", "hiDR HU 2050", "hiDR HU 2055", "hiDR HU 2060")]
colSums(as.numeric(rs_ER_ren$change_iren>0)*rs_ER_ren[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")])

rs_ER_ren[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")]<-
  rs_ER_ren$Floor.Area.m2*rs_ER_ren[,c("hiMF HU 2020",  "hiMF HU 2025", "hiMF HU 2030", "hiMF HU 2035", "hiMF HU 2040", "hiMF HU 2045", "hiMF HU 2050", "hiMF HU 2055", "hiMF HU 2060")]
colSums(as.numeric(rs_ER_ren$change_iren>0)*rs_ER_ren[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")])

# now get the GHG intensities per m2 to calculate the renovation GHGs #############
mgi_ren<-mgi_all[,c(1:6,19,22:25,29:30,31,34:37,41:43)] # only get material GHG intensities for cement, glass, insulation, wood, gypsum and transport (don't use transport)
# the following materials assume 10% ghgi intensity for renovations
mgi_ren[,c("gi20_Cement","gi20_Glass","gi20_Gypsum","gi20_Wood","gi60_Cement","gi60_Glass","gi60_Gypsum","gi60_Wood")]<-
  0.1*mgi_ren[,c("gi20_Cement","gi20_Glass","gi20_Gypsum","gi20_Wood","gi60_Cement","gi60_Glass","gi60_Gypsum","gi60_Wood")]
# for insulation materials assume 70%
mgi_ren[,c("gi20_Insulation","gi60_Insulation")]<-
  0.7*mgi_ren[,c("gi20_Insulation","gi60_Insulation")]
# assume for now 0 transport and site energy emissions
mgi_ren[,c("gi20_Transport/Construction","gi60_Transport/Construction")]<-0
mgi_ren$gi20_Tot<-rowSums(mgi_ren[,c("gi20_Cement","gi20_Glass","gi20_Gypsum","gi20_Wood","gi20_Insulation","gi20_Transport/Construction")])
mgi_ren$gi60_Tot<-rowSums(mgi_ren[,c("gi60_Cement","gi60_Glass","gi60_Gypsum","gi60_Wood","gi60_Insulation","gi60_Transport/Construction")])

# finalize emission calculations, RR #############
# define all archetype groups
rs_RR_ren$arch<-0
# slab SF
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories==1 &
          !rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-1

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-2

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories==1 &
          !rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-3

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-4

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories>1 &
          !rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-5

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-6

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-7
# this one needs redefined, represent with arch 7 for now, small SF with multiple stories and garage
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Slab" & rs_RR_ren$Geometry.Stories>1 &
          !rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-7
# Basement SF
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories==1 &
          !rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-8

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-9

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories==1 &
          !rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-10

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-11

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories>1 &
          !rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-12

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-13

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-14
# this one needs redefined, represent with arch 14 for now, small SF with multiple stories and garage
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_RR_ren$Geometry.Stories>1 &
          !rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-14
# MF Mid-Rise
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & !rs_RR_ren$Geometry.Floor.Area.Bin == "0-1499" & 
          !rs_RR_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-15 # Large MF Mid-rise
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & rs_RR_ren$Geometry.Floor.Area.Bin == "0-1499" & 
          !rs_RR_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-16 # Small MF Mid-rise

# Crawlspace SF
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories==1 &
          !rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-17

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-18

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories==1 &
          !rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-19

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-20

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories>1 &
          !rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-21

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-22

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-23
# this one needs redefined, represent with arch 23 for now, small SF with multiple stories and garage
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Crawl" & rs_RR_ren$Geometry.Stories>1 &
          !rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-23

# Pier and Beam SF
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-24

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_RR_ren$Geometry.Stories==1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-25

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & !rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-26

rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_RR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_RR_ren$Geometry.Stories>1 &
          rs_RR_ren$Geometry.Garage=="None" & rs_RR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-27

# MH 
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Mobile Home") & !rs_RR_ren$Geometry.Floor.Area.Bin == "0-1499", ]$arch<-28
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Mobile Home") & rs_RR_ren$Geometry.Floor.Area.Bin == "0-1499", ]$arch<-29

# MF high-rise
rs_RR_ren[rs_RR_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & rs_RR_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-30

mgi_ren$Division<-"New England"
mgi_ren[mgi_ren$Div=="MA",]$Division<-"Middle Atlantic"
mgi_ren[mgi_ren$Div=="ENC",]$Division<-"East North Central"
mgi_ren[mgi_ren$Div=="WNC",]$Division<-"West North Central"
mgi_ren[mgi_ren$Div=="SA",]$Division<-"South Atlantic"
mgi_ren[mgi_ren$Div=="ESC",]$Division<-"East South Central"
mgi_ren[mgi_ren$Div=="WSC",]$Division<-"West South Central"
mgi_ren[mgi_ren$Div=="MT",]$Division<-"Mountain"
mgi_ren[mgi_ren$Div=="PAC",]$Division<-"Pacific"

mgi_ren$arch_div<-paste(mgi_ren$arch,mgi_ren$Division,sep="_")

rs_RR_ren$arch_div<-paste(rs_RR_ren$arch,rs_RR_ren$Census.Division,sep="_")

mgi_ren_comb<-mgi_ren[,c(23,13,20)]
mgi_ren_comb[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]<-0
for (k in 1:270) {
mgi_ren_comb[k,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]<-as.numeric(unlist(approx(c(2020,2060),c(mgi_ren_comb$gi20_Tot[k],mgi_ren_comb$gi60_Tot[k]),n=41)[2]))[seq(1,41,5)]
}
mgi_ren_comb<-mgi_ren_comb[,-c(2,3)]
rs_RR_ren0<-merge(rs_RR_ren,mgi_ren_comb,by="arch_div")
# now calculate GHG emissions for the 3 stock evolution scenarios
rs_RR_ren0[,c("base_GHG_2020","base_GHG_2025","base_GHG_2030","base_GHG_2035","base_GHG_2040","base_GHG_2045","base_GHG_2050","base_GHG_2055","base_GHG_2060")]<-
  rs_RR_ren0[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")]*
  rs_RR_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

rs_RR_ren0[,c("hiDR_GHG_2020","hiDR_GHG_2025","hiDR_GHG_2030","hiDR_GHG_2035","hiDR_GHG_2040","hiDR_GHG_2045","hiDR_GHG_2050","hiDR_GHG_2055","hiDR_GHG_2060")]<-
  rs_RR_ren0[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")]*
  rs_RR_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

rs_RR_ren0[,c("hiMF_GHG_2020","hiMF_GHG_2025","hiMF_GHG_2030","hiMF_GHG_2035","hiMF_GHG_2040","hiMF_GHG_2045","hiMF_GHG_2050","hiMF_GHG_2055","hiMF_GHG_2060")]<-
  rs_RR_ren0[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")]*
  rs_RR_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

# calculate sum by year at national aggregate level
renGHG<-data.frame(Year=2020:2060,Source="Renovation",Stock="Base",Renovation="Reg",MtCO2e=c(0,tapply(rs_RR_ren0$base_GHG_2025,rs_RR_ren0$change_iren,sum)*1e-9))
renGHG$MtCO2e<-renGHG$MtCO2e+c(0,tapply(rs_RR_ren0$base_GHG_2030,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG$MtCO2e<-renGHG$MtCO2e+c(0,tapply(rs_RR_ren0$base_GHG_2035,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG$MtCO2e<-renGHG$MtCO2e+c(0,tapply(rs_RR_ren0$base_GHG_2040,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG$MtCO2e<-renGHG$MtCO2e+c(0,tapply(rs_RR_ren0$base_GHG_2045,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG$MtCO2e<-renGHG$MtCO2e+c(0,tapply(rs_RR_ren0$base_GHG_2050,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG$MtCO2e<-renGHG$MtCO2e+c(0,tapply(rs_RR_ren0$base_GHG_2055,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG$MtCO2e<-renGHG$MtCO2e+c(0,tapply(rs_RR_ren0$base_GHG_2060,rs_RR_ren0$change_iren,sum)*1e-9)

renGHG2<-data.frame(Year=2020:2060,Source="Renovation",Stock="hiTO",Renovation="Reg",MtCO2e=c(0,tapply(rs_RR_ren0$hiDR_GHG_2025,rs_RR_ren0$change_iren,sum)*1e-9))
renGHG2$MtCO2e<-renGHG2$MtCO2e+c(0,tapply(rs_RR_ren0$hiDR_GHG_2030,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG2$MtCO2e<-renGHG2$MtCO2e+c(0,tapply(rs_RR_ren0$hiDR_GHG_2035,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG2$MtCO2e<-renGHG2$MtCO2e+c(0,tapply(rs_RR_ren0$hiDR_GHG_2040,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG2$MtCO2e<-renGHG2$MtCO2e+c(0,tapply(rs_RR_ren0$hiDR_GHG_2045,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG2$MtCO2e<-renGHG2$MtCO2e+c(0,tapply(rs_RR_ren0$hiDR_GHG_2050,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG2$MtCO2e<-renGHG2$MtCO2e+c(0,tapply(rs_RR_ren0$hiDR_GHG_2055,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG2$MtCO2e<-renGHG2$MtCO2e+c(0,tapply(rs_RR_ren0$hiDR_GHG_2060,rs_RR_ren0$change_iren,sum)*1e-9)

renGHG3<-data.frame(Year=2020:2060,Source="Renovation",Stock="hiMF",Renovation="Reg",MtCO2e=c(0,tapply(rs_RR_ren0$hiMF_GHG_2025,rs_RR_ren0$change_iren,sum)*1e-9))
renGHG3$MtCO2e<-renGHG3$MtCO2e+c(0,tapply(rs_RR_ren0$hiMF_GHG_2030,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG3$MtCO2e<-renGHG3$MtCO2e+c(0,tapply(rs_RR_ren0$hiMF_GHG_2035,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG3$MtCO2e<-renGHG3$MtCO2e+c(0,tapply(rs_RR_ren0$hiMF_GHG_2040,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG3$MtCO2e<-renGHG3$MtCO2e+c(0,tapply(rs_RR_ren0$hiMF_GHG_2045,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG3$MtCO2e<-renGHG3$MtCO2e+c(0,tapply(rs_RR_ren0$hiMF_GHG_2050,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG3$MtCO2e<-renGHG3$MtCO2e+c(0,tapply(rs_RR_ren0$hiMF_GHG_2055,rs_RR_ren0$change_iren,sum)*1e-9)
renGHG3$MtCO2e<-renGHG3$MtCO2e+c(0,tapply(rs_RR_ren0$hiMF_GHG_2060,rs_RR_ren0$change_iren,sum)*1e-9)

# calculate sum by county and type, base stock
cty_type_base_RR<-as.data.frame(tapply(rs_RR_ren0$base_GHG_2025,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$base_GHG_2030,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) + 
  as.data.frame(tapply(rs_RR_ren0$base_GHG_2035,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$base_GHG_2040,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$base_GHG_2045,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$base_GHG_2050,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$base_GHG_2055,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$base_GHG_2060,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9)

cty_type_base_RR$Year<-rownames(cty_type_base_RR)
cty_type_base_RR<-melt(cty_type_base_RR)
cty_type_base_RR$Type<-str_sub(cty_type_base_RR$variable,-2)
cty_type_base_RR$County<-str_sub(cty_type_base_RR$variable,1,-4)

cty_type_base_RR[is.na(cty_type_base_RR)]<-0
cty_type_base_RR_cum<-as.data.frame(tapply(cty_type_base_RR$value,list(cty_type_base_RR$County,cty_type_base_RR$Type),sum))

cty_type_base_RR_cum$County<-rownames(cty_type_base_RR_cum)
cty_type_base_RR_cum<-melt(cty_type_base_RR_cum)
names(cty_type_base_RR_cum)[2:3]<-c('Type','renGHG_base_RR_Mt')
# now hiDR
cty_type_hiDR_RR<-as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2025,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2030,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) + 
  as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2035,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2040,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2045,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2050,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2055,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_RR_ren0$hiDR_GHG_2060,list(rs_RR_ren0$change_iren,rs_RR_ren0$County,rs_RR_ren0$Type3),sum)*1e-9)

cty_type_hiDR_RR$Year<-rownames(cty_type_hiDR_RR)
cty_type_hiDR_RR<-melt(cty_type_hiDR_RR)
cty_type_hiDR_RR$Type<-str_sub(cty_type_hiDR_RR$variable,-2)
cty_type_hiDR_RR$County<-str_sub(cty_type_hiDR_RR$variable,1,-4)

cty_type_hiDR_RR[is.na(cty_type_hiDR_RR)]<-0
cty_type_hiDR_RR_cum<-as.data.frame(tapply(cty_type_hiDR_RR$value,list(cty_type_hiDR_RR$County,cty_type_hiDR_RR$Type),sum))

cty_type_hiDR_RR_cum$County<-rownames(cty_type_hiDR_RR_cum)
cty_type_hiDR_RR_cum<-melt(cty_type_hiDR_RR_cum)
names(cty_type_hiDR_RR_cum)[2:3]<-c('Type','renGHG_hiDR_RR_Mt')

cty_type_RR_cum<-merge(cty_type_base_RR_cum,cty_type_hiDR_RR_cum)

# finalize emission calculations, AR #############
# define all archetype groups
rs_AR_ren$arch<-0
# slab SF
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories==1 &
            !rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-1

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-2

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories==1 &
            !rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-3

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-4

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories>1 &
            !rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-5

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-6

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-7
# this one needs redefined, represent with arch 7 for now, small SF with multiple stories and garage
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Slab" & rs_AR_ren$Geometry.Stories>1 &
            !rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-7
# Basement SF
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories==1 &
            !rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-8

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-9

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories==1 &
            !rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-10

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-11

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories>1 &
            !rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-12

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-13

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-14
# this one needs redefined, represent with arch 14 for now, small SF with multiple stories and garage
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_AR_ren$Geometry.Stories>1 &
            !rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-14
# MF Mid-Rise
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & !rs_AR_ren$Geometry.Floor.Area.Bin == "0-1499" & 
            !rs_AR_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-15 # Large MF Mid-rise
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & rs_AR_ren$Geometry.Floor.Area.Bin == "0-1499" & 
            !rs_AR_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-16 # Small MF Mid-rise

# Crawlspace SF
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories==1 &
            !rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-17

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-18

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories==1 &
            !rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-19

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-20

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories>1 &
            !rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-21

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-22

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-23
# this one needs redefined, represent with arch 23 for now, small SF with multiple stories and garage
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Crawl" & rs_AR_ren$Geometry.Stories>1 &
            !rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-23

# Pier and Beam SF
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-24

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_AR_ren$Geometry.Stories==1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-25

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & !rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-26

rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_AR_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_AR_ren$Geometry.Stories>1 &
            rs_AR_ren$Geometry.Garage=="None" & rs_AR_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-27

# MH 
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Mobile Home") & !rs_AR_ren$Geometry.Floor.Area.Bin == "0-1499", ]$arch<-28
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Mobile Home") & rs_AR_ren$Geometry.Floor.Area.Bin == "0-1499", ]$arch<-29

# MF high-rise
rs_AR_ren[rs_AR_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & rs_AR_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-30

rs_AR_ren$arch_div<-paste(rs_AR_ren$arch,rs_AR_ren$Census.Division,sep="_")

rs_AR_ren0<-merge(rs_AR_ren,mgi_ren_comb,by="arch_div")
# now calculate GHG emissions for the 3 stock evolution scenarios
rs_AR_ren0[,c("base_GHG_2020","base_GHG_2025","base_GHG_2030","base_GHG_2035","base_GHG_2040","base_GHG_2045","base_GHG_2050","base_GHG_2055","base_GHG_2060")]<-
  rs_AR_ren0[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")]*
  rs_AR_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

rs_AR_ren0[,c("hiDR_GHG_2020","hiDR_GHG_2025","hiDR_GHG_2030","hiDR_GHG_2035","hiDR_GHG_2040","hiDR_GHG_2045","hiDR_GHG_2050","hiDR_GHG_2055","hiDR_GHG_2060")]<-
  rs_AR_ren0[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")]*
  rs_AR_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

rs_AR_ren0[,c("hiMF_GHG_2020","hiMF_GHG_2025","hiMF_GHG_2030","hiMF_GHG_2035","hiMF_GHG_2040","hiMF_GHG_2045","hiMF_GHG_2050","hiMF_GHG_2055","hiMF_GHG_2060")]<-
  rs_AR_ren0[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")]*
  rs_AR_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

renGHG4<-data.frame(Year=2020:2060,Source="Renovation",Stock="Base",Renovation="Adv",MtCO2e=c(0,tapply(rs_AR_ren0$base_GHG_2025,rs_AR_ren0$change_iren,sum)*1e-9))
renGHG4$MtCO2e<-renGHG4$MtCO2e+c(0,tapply(rs_AR_ren0$base_GHG_2030,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG4$MtCO2e<-renGHG4$MtCO2e+c(0,tapply(rs_AR_ren0$base_GHG_2035,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG4$MtCO2e<-renGHG4$MtCO2e+c(0,tapply(rs_AR_ren0$base_GHG_2040,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG4$MtCO2e<-renGHG4$MtCO2e+c(0,tapply(rs_AR_ren0$base_GHG_2045,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG4$MtCO2e<-renGHG4$MtCO2e+c(0,tapply(rs_AR_ren0$base_GHG_2050,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG4$MtCO2e<-renGHG4$MtCO2e+c(0,tapply(rs_AR_ren0$base_GHG_2055,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG4$MtCO2e<-renGHG4$MtCO2e+c(0,tapply(rs_AR_ren0$base_GHG_2060,rs_AR_ren0$change_iren,sum)*1e-9)

renGHG5<-data.frame(Year=2020:2060,Source="Renovation",Stock="hiTO",Renovation="Adv",MtCO2e=c(0,tapply(rs_AR_ren0$hiDR_GHG_2025,rs_AR_ren0$change_iren,sum)*1e-9))
renGHG5$MtCO2e<-renGHG5$MtCO2e+c(0,tapply(rs_AR_ren0$hiDR_GHG_2030,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG5$MtCO2e<-renGHG5$MtCO2e+c(0,tapply(rs_AR_ren0$hiDR_GHG_2035,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG5$MtCO2e<-renGHG5$MtCO2e+c(0,tapply(rs_AR_ren0$hiDR_GHG_2040,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG5$MtCO2e<-renGHG5$MtCO2e+c(0,tapply(rs_AR_ren0$hiDR_GHG_2045,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG5$MtCO2e<-renGHG5$MtCO2e+c(0,tapply(rs_AR_ren0$hiDR_GHG_2050,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG5$MtCO2e<-renGHG5$MtCO2e+c(0,tapply(rs_AR_ren0$hiDR_GHG_2055,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG5$MtCO2e<-renGHG5$MtCO2e+c(0,tapply(rs_AR_ren0$hiDR_GHG_2060,rs_AR_ren0$change_iren,sum)*1e-9)

renGHG6<-data.frame(Year=2020:2060,Source="Renovation",Stock="hiMF",Renovation="Adv",MtCO2e=c(0,tapply(rs_AR_ren0$hiMF_GHG_2025,rs_AR_ren0$change_iren,sum)*1e-9))
renGHG6$MtCO2e<-renGHG6$MtCO2e+c(0,tapply(rs_AR_ren0$hiMF_GHG_2030,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG6$MtCO2e<-renGHG6$MtCO2e+c(0,tapply(rs_AR_ren0$hiMF_GHG_2035,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG6$MtCO2e<-renGHG6$MtCO2e+c(0,tapply(rs_AR_ren0$hiMF_GHG_2040,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG6$MtCO2e<-renGHG6$MtCO2e+c(0,tapply(rs_AR_ren0$hiMF_GHG_2045,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG6$MtCO2e<-renGHG6$MtCO2e+c(0,tapply(rs_AR_ren0$hiMF_GHG_2050,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG6$MtCO2e<-renGHG6$MtCO2e+c(0,tapply(rs_AR_ren0$hiMF_GHG_2055,rs_AR_ren0$change_iren,sum)*1e-9)
renGHG6$MtCO2e<-renGHG6$MtCO2e+c(0,tapply(rs_AR_ren0$hiMF_GHG_2060,rs_AR_ren0$change_iren,sum)*1e-9)

# calculate sum by county and type, AR, first base stock
cty_type_base_AR<-as.data.frame(tapply(rs_AR_ren0$base_GHG_2025,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$base_GHG_2030,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) + 
  as.data.frame(tapply(rs_AR_ren0$base_GHG_2035,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$base_GHG_2040,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$base_GHG_2045,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$base_GHG_2050,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$base_GHG_2055,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$base_GHG_2060,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9)

cty_type_base_AR$Year<-rownames(cty_type_base_AR)
cty_type_base_AR<-melt(cty_type_base_AR)
cty_type_base_AR$Type<-str_sub(cty_type_base_AR$variable,-2)
cty_type_base_AR$County<-str_sub(cty_type_base_AR$variable,1,-4)

cty_type_base_AR[is.na(cty_type_base_AR)]<-0
cty_type_base_AR_cum<-as.data.frame(tapply(cty_type_base_AR$value,list(cty_type_base_AR$County,cty_type_base_AR$Type),sum))

cty_type_base_AR_cum$County<-rownames(cty_type_base_AR_cum)
cty_type_base_AR_cum<-melt(cty_type_base_AR_cum)
names(cty_type_base_AR_cum)[2:3]<-c('Type','renGHG_base_AR_Mt')
# now hiDR
cty_type_hiDR_AR<-as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2025,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2030,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) + 
  as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2035,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2040,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2045,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2050,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2055,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_AR_ren0$hiDR_GHG_2060,list(rs_AR_ren0$change_iren,rs_AR_ren0$County,rs_AR_ren0$Type3),sum)*1e-9)

cty_type_hiDR_AR$Year<-rownames(cty_type_hiDR_AR)
cty_type_hiDR_AR<-melt(cty_type_hiDR_AR)
cty_type_hiDR_AR$Type<-str_sub(cty_type_hiDR_AR$variable,-2)
cty_type_hiDR_AR$County<-str_sub(cty_type_hiDR_AR$variable,1,-4)

cty_type_hiDR_AR[is.na(cty_type_hiDR_AR)]<-0
cty_type_hiDR_AR_cum<-as.data.frame(tapply(cty_type_hiDR_AR$value,list(cty_type_hiDR_AR$County,cty_type_hiDR_AR$Type),sum))

cty_type_hiDR_AR_cum$County<-rownames(cty_type_hiDR_AR_cum)
cty_type_hiDR_AR_cum<-melt(cty_type_hiDR_AR_cum)
names(cty_type_hiDR_AR_cum)[2:3]<-c('Type','renGHG_hiDR_AR_Mt')

cty_type_AR_cum<-merge(cty_type_base_AR_cum,cty_type_hiDR_AR_cum)

# finalize emission calculations, ER #############
# define all archetype groups
rs_ER_ren$arch<-0
# slab SF
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories==1 &
            !rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-1

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-2

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories==1 &
            !rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-3

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-4

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories>1 &
            !rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-5

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-6

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-7
# this one needs redefined, represent with arch 7 for now, small SF with multiple stories and garage
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Slab" & rs_ER_ren$Geometry.Stories>1 &
            !rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-7
# Basement SF
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories==1 &
            !rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-8

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-9

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories==1 &
            !rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-10

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-11

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories>1 &
            !rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-12

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-13

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-14
# this one needs redefined, represent with arch 14 for now, small SF with multiple stories and garage
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type %in% c("Heated Basement","Unheated Basement") & rs_ER_ren$Geometry.Stories>1 &
            !rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-14
# MF Mid-Rise
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & !rs_ER_ren$Geometry.Floor.Area.Bin == "0-1499" & 
            !rs_ER_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-15 # Large MF Mid-rise
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & rs_ER_ren$Geometry.Floor.Area.Bin == "0-1499" & 
            !rs_ER_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-16 # Small MF Mid-rise

# Crawlspace SF
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories==1 &
            !rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-17

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-18

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories==1 &
            !rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-19

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-20

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories>1 &
            !rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-21

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-22

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-23
# this one needs redefined, represent with arch 23 for now, small SF with multiple stories and garage
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Crawl" & rs_ER_ren$Geometry.Stories>1 &
            !rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-23

# Pier and Beam SF
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-24

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_ER_ren$Geometry.Stories==1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-25

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & !rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-26

rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached") & rs_ER_ren$Geometry.Foundation.Type=="Pier and Beam" & rs_ER_ren$Geometry.Stories>1 &
            rs_ER_ren$Geometry.Garage=="None" & rs_ER_ren$Geometry.Floor.Area %in% c("0-499","500-749","750-999","1000-1499","1500-1999"), ]$arch<-27

# MH 
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Mobile Home") & !rs_ER_ren$Geometry.Floor.Area.Bin == "0-1499", ]$arch<-28
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Mobile Home") & rs_ER_ren$Geometry.Floor.Area.Bin == "0-1499", ]$arch<-29

# MF high-rise
rs_ER_ren[rs_ER_ren$Geometry.Building.Type.RECS %in% c("Multi-Family with 2 - 4 Units","Multi-Family with 5+ Units") & rs_ER_ren$Geometry.Building.Number.Units.HL=="50 or more Units high", ]$arch<-30

rs_ER_ren$arch_div<-paste(rs_ER_ren$arch,rs_ER_ren$Census.Division,sep="_")

rs_ER_ren0<-merge(rs_ER_ren,mgi_ren_comb,by="arch_div")
# now calculate GHG emissions for the 3 stock evolution scenarios
rs_ER_ren0[,c("base_GHG_2020","base_GHG_2025","base_GHG_2030","base_GHG_2035","base_GHG_2040","base_GHG_2045","base_GHG_2050","base_GHG_2055","base_GHG_2060")]<-
  rs_ER_ren0[,c("base FA 2020","base FA 2025","base FA 2030","base FA 2035","base FA 2040","base FA 2045","base FA 2050","base FA 2055","base FA 2060")]*
  rs_ER_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

rs_ER_ren0[,c("hiDR_GHG_2020","hiDR_GHG_2025","hiDR_GHG_2030","hiDR_GHG_2035","hiDR_GHG_2040","hiDR_GHG_2045","hiDR_GHG_2050","hiDR_GHG_2055","hiDR_GHG_2060")]<-
  rs_ER_ren0[,c("hiDR FA 2020","hiDR FA 2025","hiDR FA 2030","hiDR FA 2035","hiDR FA 2040","hiDR FA 2045","hiDR FA 2050","hiDR FA 2055","hiDR FA 2060")]*
  rs_ER_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

rs_ER_ren0[,c("hiMF_GHG_2020","hiMF_GHG_2025","hiMF_GHG_2030","hiMF_GHG_2035","hiMF_GHG_2040","hiMF_GHG_2045","hiMF_GHG_2050","hiMF_GHG_2055","hiMF_GHG_2060")]<-
  rs_ER_ren0[,c("hiMF FA 2020","hiMF FA 2025","hiMF FA 2030","hiMF FA 2035","hiMF FA 2040","hiMF FA 2045","hiMF FA 2050","hiMF FA 2055","hiMF FA 2060")]*
  rs_ER_ren0[,c("gi2020","gi2025","gi2030","gi2035","gi2040","gi2045","gi2050","gi2055","gi2060")]

renGHG7<-data.frame(Year=2020:2060,Source="Renovation",Stock="Base",Renovation="Ext",MtCO2e=c(0,tapply(rs_ER_ren0$base_GHG_2025,rs_ER_ren0$change_iren,sum)*1e-9))
renGHG7$MtCO2e<-renGHG7$MtCO2e+c(0,tapply(rs_ER_ren0$base_GHG_2030,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG7$MtCO2e<-renGHG7$MtCO2e+c(0,tapply(rs_ER_ren0$base_GHG_2035,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG7$MtCO2e<-renGHG7$MtCO2e+c(0,tapply(rs_ER_ren0$base_GHG_2040,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG7$MtCO2e<-renGHG7$MtCO2e+c(0,tapply(rs_ER_ren0$base_GHG_2045,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG7$MtCO2e<-renGHG7$MtCO2e+c(0,tapply(rs_ER_ren0$base_GHG_2050,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG7$MtCO2e<-renGHG7$MtCO2e+c(0,tapply(rs_ER_ren0$base_GHG_2055,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG7$MtCO2e<-renGHG7$MtCO2e+c(0,tapply(rs_ER_ren0$base_GHG_2060,rs_ER_ren0$change_iren,sum)*1e-9)

renGHG8<-data.frame(Year=2020:2060,Source="Renovation",Stock="hiTO",Renovation="Ext",MtCO2e=c(0,tapply(rs_ER_ren0$hiDR_GHG_2025,rs_ER_ren0$change_iren,sum)*1e-9))
renGHG8$MtCO2e<-renGHG8$MtCO2e+c(0,tapply(rs_ER_ren0$hiDR_GHG_2030,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG8$MtCO2e<-renGHG8$MtCO2e+c(0,tapply(rs_ER_ren0$hiDR_GHG_2035,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG8$MtCO2e<-renGHG8$MtCO2e+c(0,tapply(rs_ER_ren0$hiDR_GHG_2040,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG8$MtCO2e<-renGHG8$MtCO2e+c(0,tapply(rs_ER_ren0$hiDR_GHG_2045,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG8$MtCO2e<-renGHG8$MtCO2e+c(0,tapply(rs_ER_ren0$hiDR_GHG_2050,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG8$MtCO2e<-renGHG8$MtCO2e+c(0,tapply(rs_ER_ren0$hiDR_GHG_2055,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG8$MtCO2e<-renGHG8$MtCO2e+c(0,tapply(rs_ER_ren0$hiDR_GHG_2060,rs_ER_ren0$change_iren,sum)*1e-9)

renGHG9<-data.frame(Year=2020:2060,Source="Renovation",Stock="hiMF",Renovation="Ext",MtCO2e=c(0,tapply(rs_ER_ren0$hiMF_GHG_2025,rs_ER_ren0$change_iren,sum)*1e-9))
renGHG9$MtCO2e<-renGHG9$MtCO2e+c(0,tapply(rs_ER_ren0$hiMF_GHG_2030,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG9$MtCO2e<-renGHG9$MtCO2e+c(0,tapply(rs_ER_ren0$hiMF_GHG_2035,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG9$MtCO2e<-renGHG9$MtCO2e+c(0,tapply(rs_ER_ren0$hiMF_GHG_2040,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG9$MtCO2e<-renGHG9$MtCO2e+c(0,tapply(rs_ER_ren0$hiMF_GHG_2045,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG9$MtCO2e<-renGHG9$MtCO2e+c(0,tapply(rs_ER_ren0$hiMF_GHG_2050,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG9$MtCO2e<-renGHG9$MtCO2e+c(0,tapply(rs_ER_ren0$hiMF_GHG_2055,rs_ER_ren0$change_iren,sum)*1e-9)
renGHG9$MtCO2e<-renGHG9$MtCO2e+c(0,tapply(rs_ER_ren0$hiMF_GHG_2060,rs_ER_ren0$change_iren,sum)*1e-9)

renGHGall<-rbind(renGHG,renGHG2,renGHG3,renGHG4,renGHG5,renGHG6,renGHG7,renGHG8,renGHG9)
renGHGall$Scen<-paste(renGHGall$Stock,renGHGall$Renovation,sep="_")
rownames(renGHGall)<-1:nrow(renGHGall)
save(renGHGall,file="Final_results/renGHG.RData")

# calculate sum by county and type, ER, first base stock
cty_type_base_ER<-as.data.frame(tapply(rs_ER_ren0$base_GHG_2025,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$base_GHG_2030,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) + 
  as.data.frame(tapply(rs_ER_ren0$base_GHG_2035,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$base_GHG_2040,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$base_GHG_2045,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$base_GHG_2050,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$base_GHG_2055,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$base_GHG_2060,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9)

cty_type_base_ER$Year<-rownames(cty_type_base_ER)
cty_type_base_ER<-melt(cty_type_base_ER)
cty_type_base_ER$Type<-str_sub(cty_type_base_ER$variable,-2)
cty_type_base_ER$County<-str_sub(cty_type_base_ER$variable,1,-4)

cty_type_base_ER[is.na(cty_type_base_ER)]<-0
cty_type_base_ER_cum<-as.data.frame(tapply(cty_type_base_ER$value,list(cty_type_base_ER$County,cty_type_base_ER$Type),sum))

cty_type_base_ER_cum$County<-rownames(cty_type_base_ER_cum)
cty_type_base_ER_cum<-melt(cty_type_base_ER_cum)
names(cty_type_base_ER_cum)[2:3]<-c('Type','renGHG_base_ER_Mt')
# now hiDR
cty_type_hiDR_ER<-as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2025,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2030,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) + 
  as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2035,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2040,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2045,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2050,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2055,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9) +
  as.data.frame(tapply(rs_ER_ren0$hiDR_GHG_2060,list(rs_ER_ren0$change_iren,rs_ER_ren0$County,rs_ER_ren0$Type3),sum)*1e-9)

cty_type_hiDR_ER$Year<-rownames(cty_type_hiDR_ER)
cty_type_hiDR_ER<-melt(cty_type_hiDR_ER)
cty_type_hiDR_ER$Type<-str_sub(cty_type_hiDR_ER$variable,-2)
cty_type_hiDR_ER$County<-str_sub(cty_type_hiDR_ER$variable,1,-4)

cty_type_hiDR_ER[is.na(cty_type_hiDR_ER)]<-0
cty_type_hiDR_ER_cum<-as.data.frame(tapply(cty_type_hiDR_ER$value,list(cty_type_hiDR_ER$County,cty_type_hiDR_ER$Type),sum))

cty_type_hiDR_ER_cum$County<-rownames(cty_type_hiDR_ER_cum)
cty_type_hiDR_ER_cum<-melt(cty_type_hiDR_ER_cum)
names(cty_type_hiDR_ER_cum)[2:3]<-c('Type','renGHG_hiDR_ER_Mt')

cty_type_ER_cum<-merge(cty_type_base_ER_cum,cty_type_hiDR_ER_cum)

cty_type_cum<-merge(cty_type_RR_cum,cty_type_AR_cum,by=c('County','Type'),all = TRUE)
cty_type_cum<-merge(cty_type_cum,cty_type_ER_cum,all=TRUE)

save(cty_type_cum,file="resstock_projections/Final_results/renGHG_cty_type.RData")

windows()
ggplot(renGHGall,aes(x=Year,y=MtCO2e,color=Scen)) + geom_line()
windows()
ggplot(renGHGall,aes(x=Year,y=MtCO2e,color=Stock)) + geom_line(size=1,aes(linetype=Renovation)) + theme_bw()
