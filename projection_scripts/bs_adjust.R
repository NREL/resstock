# update bs csvs in ways that was not possible when modifying the tsv housing characteristics files

rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
setwd("~/Yale Courses/Research/Final Paper/resstock_scenarios/projection_scripts")
# library(readr)
# setwd("C:/Users/pb637/Documents/Yale Courses/Research/Final Paper/StockModelCode/")
# rs2<-read_csv("../bscsvs/Scenarios/bs2030hiDR15k.csv") # trying out with the 2030 hi DR scenario
# rm_dot<-function(df) {
#   cn<-names(df)
#   cn<-str_replace_all(cn,"Dependency.", "Dependency=")
#   cn<-str_replace_all(cn,"Option..1940", "Option=<1940")
#   cn<-str_replace_all(cn,"Option.", "Option=")
#   cn<-str_replace_all(cn,"\\.", " ")
#   cn<-str_replace_all(cn,"Single.","Single-")
#   names(df)<-cn
#   df
# }

rm_dot2<-function(df) {
  cn<-names(df)
  cn<-gsub("Dependency.", "Dependency=",cn)
  cn<-gsub("Option..1940", "Option=<1940",cn)
  cn<-gsub("Option.", "Option=",cn)
  cn<-gsub("\\.", " ",cn)
  cn<-gsub("Single.","Single-",cn)
  names(df)<-cn
  df
}

scenarios<-c("base","baseDE","baseRFA","baseDERFA",
             "hiDR","hiDRDE","hiDRRFA","hiDRDERFA",
             "hiMF","hiMFDE","hiMFRFA","hiMFDERFA")
states<-c("TX","FL","NY","NE","DE","MD") # states which have faster adoption of IECC codes than their ResStock custom regionss

# load("buildstock100.RData") # just demonstrating with the 100,000 bs.csv 
for (yr in seq(2025,2060,5)) { print(yr)
# for (yr in 2025) {
  
  for (scen in 1:12) { print(scenarios[scen])
    fn<-paste("../scen_bscsv/bs",yr,scenarios[scen],"_25.csv",sep="")# update filename ending as appropriate
    rs<-read.csv(fn)
  

# rs<-read.csv("../bscsvs/Scenarios/bs2030hiDR15k.csv") # trying out with the 2030 hi DR scenario
# View(names(rs))
tryCatch({
# windows ############ same process for all years 
# windows, update TX, FL, NY, NE, DE and MD windows to `Option=Low-E, Double, Low-Gain` for all vintages 2020 onwards
# all of the states are predominantly (exception of upper NY state) in regions with low-gain windows specified
rs[rs$State %in% states,]$Windows<-"Low-E, Double, Low-Gain" # already exists in options lookup
# ducts do not vary by geography in the base tsv, so are not further changed here. I.e. the changes in newCohorts apply to assumed average improvements for all regions

# Infiltration ############ # same process for all years
# in FL, bring anything over ACH5 down to ACH5. this may actually make no change, as they could be down there already
if (length(rs[rs$State=="FL"&rs$Infiltration %in% c("6 ACH50","7 ACH50","8 ACH50","10 ACH50","15 ACH50","20 ACH50","25 ACH50","30 ACH50","40 ACH50","50 ACH50"),]$Infiltration)>0) {
rs[rs$State=="FL"&rs$Infiltration %in% c("6 ACH50","7 ACH50","8 ACH50","10 ACH50","15 ACH50","20 ACH50","25 ACH50","30 ACH50","40 ACH50","50 ACH50"),]$Infiltration<-"5 ACH50"}
# In all other rogue states, bring anything above ACH3 down to ACH3.
rs[rs$State %in% c("TX","NY","NE","DE","MD")  &rs$Infiltration %in% c("4 ACH50","5 ACH50", "6 ACH50","7 ACH50","8 ACH50","10 ACH50","15 ACH50","20 ACH50","25 ACH50","30 ACH50","40 ACH50","50 ACH50"),]$Infiltration<-"3 ACH50"

# Insulation crawlspace ########### # no diff b/w IECC 2015 and 2021, therefore can apply the same change to all future years
# no rqm for TX or FL (climate zones 3, 2, 1)
# NY, DE, and MD in CZ 4 go to R10/R13. NE in CZ5 goes to R15/R19
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Crawlspace %in% c("Uninsulated, Vented"),]$Insulation.Crawlspace<-"Ceiling R-13, Vented"
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Crawlspace %in% c("Wall R-5, Unvented") ,]$Insulation.Crawlspace<-"Wall R-10, Unvented"
rs[rs$State =="NE" & rs$Insulation.Crawlspace %in% c("Uninsulated, Vented","Ceiling R-13, Vented"),]$Insulation.Crawlspace<-"Ceiling R-19, Vented"
rs[rs$State =="NE" & rs$Insulation.Crawlspace  %in% c("Wall R-5, Unvented","Wall R-10, Unvented") ,]$Insulation.Crawlspace<-"Wall R-15, Unvented" # this is a new option, add to options lookup

# Insulation Finished Basement ########### # no diff b/w IECC 2018 and 2021, therefore can apply the same change to all future years
# no rqm for TX or FL (climate zones 3, 2, 1)
# NY, DE, and MD in CZ 4 go to R10. NE in CZ5 goes to R15
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Finished.Basement %in% c("Uninsulated","Wall R-5"),]$Insulation.Finished.Basement<-"Wall R-10"
rs[rs$State =="NE" & rs$Insulation.Finished.Basement %in% c("Uninsulated","Wall R-5","Wall R-10"),]$Insulation.Finished.Basement<-"Wall R-15"

# Insulation IZ Floor and PB and Fin Roof unchanged

# Insulation Slab ######
# no rqm for TX or FL (climate zones 3, 2, 1). Actually in 2021 there is a rqm for slab insulation in CZ3, but most of texas's population is in CZ 2
# In 2020s NY, DE, and MD in CZ 4 and NE in CZ5 go to R10 2ft. From 2030s onwards (i.e. sim year = 2035 or later),all of these states go to go to R10 4ft, 
if (yr<2035) {
rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Slab %in% c("2ft R5 Perimeter, R5 Gap"),]$Insulation.Slab<-"2ft R10 Perimeter, R10 Gap"
rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Slab %in% c("Uninsulated", "2ft R5 Exterior"),]$Insulation.Slab<-"2ft R10 Exterior"
}
if (yr>2034) {
  rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Slab %in% c("2ft R5 Perimeter, R5 Gap","2ft R10 Perimeter, R10 Gap"),]$Insulation.Slab<-"4ft R10 Perimeter, R10 Gap" # new option
  rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Slab %in% c("Uninsulated", "2ft R5 Exterior","2ft R10 Exterior"),]$Insulation.Slab<-"4ft R10 Exterior"

}
# Insulation Unfinished Attic ########
# in 2020s TX and FL go to R-38 min. CZ4 and CZ5 go to R-49 min. 
if (yr<2035) {
rs[rs$State %in% c("TX","FL") & rs$Insulation.Unfinished.Attic %in% c("Uninsulated, Vented","Ceiling R-7, Vented","Ceiling R-13, Vented","Ceiling R-19, Vented","Ceiling R-30, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-38, Vented"
rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Unfinished.Attic %in% c("Uninsulated, Vented","Ceiling R-7, Vented","Ceiling R-13, Vented","Ceiling R-19, Vented","Ceiling R-30, Vented",
                                                                                "Ceiling R-38, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-49, Vented"
}
# from 2030s onwards TX FL now go to R-49, and CZ 4 and 5 go to R-60
if (yr>2034) {
rs[rs$State %in% c("TX","FL") & rs$Insulation.Unfinished.Attic %in% c("Uninsulated, Vented","Ceiling R-7, Vented","Ceiling R-13, Vented","Ceiling R-19, Vented","Ceiling R-30, Vented",
                                                                      "Ceiling R-38, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-49, Vented"

rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Unfinished.Attic %in% c("Uninsulated, Vented","Ceiling R-7, Vented","Ceiling R-13, Vented","Ceiling R-19, Vented","Ceiling R-30, Vented",
                                                                                "Ceiling R-38, Vented","Ceiling R-49, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-60, Vented"
}
# Insulation Unfinished Basement ########### # no diff b/w IECC 2015 and 2021, same adjustment for all years 
# no restriction in TX/FL
# CZ4 goes to R-13 and CZ5 goes to R-19
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Unfinished.Basement == "Uninsulated",]$Insulation.Unfinished.Basement<-"Ceiling R-13" 
rs[rs$State %in% c("NE") & rs$Insulation.Unfinished.Basement %in% c("Uninsulated","Ceiling R-13") ,]$Insulation.Unfinished.Basement<-"Ceiling R-19" 

# Insulation Wall ############## # no diff b/w IECC 2015 and 2021
# In TX, FL, minimum R-15 wood, masonry at least R-7
# In all other states, minimum R-19 wood. In CZ4, masonry at least R-11, in CZ5, masonry at least R-15
rs[rs$State %in% c("TX","FL") & rs$Insulation.Wall %in% c("Wood Stud, Uninsulated"),]$Insulation.Wall<-"Wood Stud, R-7"
rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Wall %in% c("Wood Stud, Uninsulated","Wood Stud, R-7","Wood Stud, R-11","Wood Stud, R-15"),]$Insulation.Wall<-"Wood Stud, R-19"

rs[rs$State %in% c("TX","FL") & rs$Insulation.Wall %in% c("CMU, 6-in Hollow, Uninsulated","Brick, 12-in, 3-wythe, Uninsulated"),]$Insulation.Wall<-"CMU, 6-in Hollow, R-7"
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Wall %in% c("CMU, 6-in Hollow, Uninsulated","CMU, 6-in Hollow, R-7","Brick, 12-in, 3-wythe, Uninsulated"),]$Insulation.Wall<-"CMU, 6-in Hollow, R-11"
rs[rs$State %in% c("NE") & rs$Insulation.Wall %in% c("CMU, 6-in Hollow, Uninsulated","CMU, 6-in Hollow, R-7","CMU, 6-in Hollow, R-11","Brick, 12-in, 3-wythe, Uninsulated"),]$Insulation.Wall<-"CMU, 6-in Hollow, R-15"
}, error = function(err) {print(err)})
# higher adoptions of efficient AC in southern states #################
SoSt<-c("DC","DE", "KY","MD","TN","VA") # southern states not included in southern Location Regions (LR)
SoLR<-c("CR09","CR10","CR11") # southern Location Regions (ResStock Custom Regions)
rs$SoCool<-0 # is it a southern cooling state, with regard to efficiency standards? see note on AC here https://www.ecfr.gov/cgi-bin/text-idx?rgn=div8&node=10:3.0.1.4.18.3.9.2
rs[rs$Location.Region %in% SoLR | rs$State %in% SoSt,]$SoCool<-1 # if a member of SoSt or SoLR it is a southern states as far as cooling equipment efficiency standards are concerned

# define probability matrix for hvac cooling efficiency
# ceff_types<-rownames(table(rs$HVAC.Cooling.Efficiency))
# seeing as there are no SEER 8/10 central AC, or no EER 8.5 room AC in new housing, the types should be as follows:
# AC SEER 13,15,18, HP, None, Room AC 9.8, 10.7, 12.0, Shared Cooling
# ceff_types<-c(ceff_types[c(1:5,8,6:7,9)] )
ceff_types<-c("AC, SEER 13","AC, SEER 15","AC, SEER 18","Heat Pump","None","Room AC, EER 9.8","Room AC, EER 10.7","Room AC, EER 12.0","Shared Cooling")
ce<-matrix(0,length(ceff_types),length(ceff_types))
colnames(ce)<-rownames(ce)<-ceff_types
# seer 13 to 13:15:18
ce[1:3,1]<-c(0.9,0.05,0.05)
# seer 15 to 15:18
ce[2:3,2]<-c(0.9,0.1)
# seer 18, HP, and none stay same
ce[3:5,3:5]<-diag(3)
# appliance efficiency regs don't differ for room AC by region, but assume a higher adoption of room AC in South
# eer 9.8 to 9.8, 10.7, 12
ce[6:8,6]<-c(0.8,0.15,0.05)
# eer 10.7 to 10.7: 12
ce[7:8,7]<-c(0.9,0.1)
# seer 12 and shared cooling
ce[8,8]<-ce[9,9]<-1

for (i in 1:nrow(rs)) { # this will only work with the new construction cohorts, as the current rs file has options that are out of bounds, e.g. AC, SEER 10
  if (rs$SoCool[i]==1) {
    rs$HVAC.Cooling.Efficiency[i]<-sample(ceff_types,1,p=ce[,rs$HVAC.Cooling.Efficiency[i]]) 
  }
}
rssave<-rm_dot2(rs[,1:113])
# all.equal(names(rs2),names(rssave)) # to check if the colnames are the same
fnsave<-paste("../scen_bscsv_adj/bs",yr,scenarios[scen],"_25.csv",sep="")# update filename ending as appropriate
write.csv(rssave,file=fnsave, row.names = FALSE)
  }
}


### now combine into less files and remove redundant rows ###########

rm(list=ls()) # clear workspace i.e. remove saved variables
bsall<- list.files(path = "../scen_bscsv_adj/")
for (k in 1:length(bsall)) {
  fn<-bsall[k]
  rs<-read.csv(paste("../scen_bscsv_adj/",fn,sep = ""))
  rs$sim_year<-as.numeric(substr(fn,3,6))
  rs$scen<-substr(fn,7,nchar(fn)-7)
  assign(gsub('*.csv','',fn),rs)
}
# base2055_60<-base2045_50<-base2035_40<-base2025_30<-rep(0,nrow(rs))
# for (i in 1:nrow(rs)) {
#   if(all(bs2025base_25[i,2:113]==bs2030base_25[i,2:113])) {
#   base2025_30[i]<-i
#   }
#   if(all(bs2035base_25[i,2:113]==bs2040base_25[i,2:113])) {
#     base2035_40[i]<-i
#   }
#   if(all(bs2045base_25[i,2:113]==bs2050base_25[i,2:113])) {
#     base2045_50[i]<-i
#   }
#   if(all(bs2055base_25[i,2:113]==bs2060base_25[i,2:113])) {
#     base2055_60[i]<-i
#   }
# }
# base2025_30<-base2025_30[base2025_30>0]
# base2035_40<-base2035_40[base2035_40>0]
# base2045_50<-base2045_50[base2045_50>0]
# base2055_60<-base2055_60[base2055_60>0]
# 
# # hiDR
# hiDR2055_60<-hiDR2045_50<-hiDR2035_40<-hiDR2025_30<-rep(0,nrow(rs))
# for (i in 1:nrow(rs)) {
#   if(all(bs2025hiDR_25[i,2:113]==bs2030hiDR_25[i,2:113])) {
#     hiDR2025_30[i]<-i
#   }
#   if(all(bs2035hiDR_25[i,2:113]==bs2040hiDR_25[i,2:113])) {
#     hiDR2035_40[i]<-i
#   }
#   if(all(bs2045hiDR_25[i,2:113]==bs2050hiDR_25[i,2:113])) {
#     hiDR2045_50[i]<-i
#   }
#   if(all(bs2055hiDR_25[i,2:113]==bs2060hiDR_25[i,2:113])) {
#     hiDR2055_60[i]<-i
#   }
# }
# hiDR2025_30<-hiDR2025_30[hiDR2025_30>0]
# hiDR2035_40<-hiDR2035_40[hiDR2035_40>0]
# hiDR2045_50<-hiDR2045_50[hiDR2045_50>0]
# hiDR2055_60<-hiDR2055_60[hiDR2055_60>0]
# 
# # hiMF
# hiMF2055_60<-hiMF2045_50<-hiMF2035_40<-hiMF2025_30<-rep(0,nrow(rs))
# for (i in 1:nrow(rs)) {
#   if(all(bs2025hiMF_25[i,2:113]==bs2030hiMF_25[i,2:113])) {
#     hiMF2025_30[i]<-i
#   }
#   if(all(bs2035hiMF_25[i,2:113]==bs2040hiMF_25[i,2:113])) {
#     hiMF2035_40[i]<-i
#   }
#   if(all(bs2045hiMF_25[i,2:113]==bs2050hiMF_25[i,2:113])) {
#     hiMF2045_50[i]<-i
#   }
#   if(all(bs2055hiMF_25[i,2:113]==bs2060hiMF_25[i,2:113])) {
#     hiMF2055_60[i]<-i
#   }
# }
# hiMF2025_30<-hiMF2025_30[hiMF2025_30>0]
# hiMF2035_40<-hiMF2035_40[hiMF2035_40>0]
# hiMF2045_50<-hiMF2045_50[hiMF2045_50>0]
# hiMF2055_60<-hiMF2055_60[hiMF2055_60>0]
# identify and remove base duplicates ########
bs_base<-rbind(bs2025base_25, bs2030base_25, bs2035base_25, bs2040base_25, bs2045base_25, bs2050base_25, bs2055base_25, bs2060base_25)
bs_base$Building_id<-bs_base$Building # preserve original building id
bs_base$Building<-1:nrow(bs_base)
dupe_base<-which(duplicated(bs_base[,2:113]))
bs_base<-bs_base[!duplicated(bs_base[,2:113]),]

bs_baseDE<-rbind(bs2025baseDE_25, bs2030baseDE_25, bs2035baseDE_25, bs2040baseDE_25, bs2045baseDE_25, bs2050baseDE_25, bs2055baseDE_25, bs2060baseDE_25)
bs_baseDE$Building_id<-bs_baseDE$Building # preserve original building id
bs_baseDE$Building<-1:nrow(bs_baseDE)
dupe_baseDE<-which(duplicated(bs_baseDE[,2:113]))
bs_baseDE<-bs_baseDE[!duplicated(bs_baseDE[,2:113]),]

bs_baseRFA<-rbind(bs2025baseRFA_25, bs2030baseRFA_25, bs2035baseRFA_25, bs2040baseRFA_25, bs2045baseRFA_25, bs2050baseRFA_25, bs2055baseRFA_25, bs2060baseRFA_25)
bs_baseRFA$Building_id<-bs_baseRFA$Building # preserve original building id
bs_baseRFA$Building<-1:nrow(bs_baseRFA)
dupe_baseRFA<-which(duplicated(bs_baseRFA[,2:113]))
bs_baseRFA<-bs_baseRFA[!duplicated(bs_baseRFA[,2:113]),]

bs_baseDERFA<-rbind(bs2025baseDERFA_25, bs2030baseDERFA_25, bs2035baseDERFA_25, bs2040baseDERFA_25, bs2045baseDERFA_25, bs2050baseDERFA_25, bs2055baseDERFA_25, bs2060baseDERFA_25)
bs_baseDERFA$Building_id<-bs_baseDERFA$Building # preserve original building id
bs_baseDERFA$Building<-1:nrow(bs_baseDERFA)
dupe_baseDERFA<-which(duplicated(bs_baseDERFA[,2:113]))
bs_baseDERFA<-bs_baseDERFA[!duplicated(bs_baseDERFA[,2:113]),]

# identify and remove hiDR duplicates ##########
bs_hiDR<-rbind(bs2025hiDR_25, bs2030hiDR_25, bs2035hiDR_25, bs2040hiDR_25, bs2045hiDR_25, bs2050hiDR_25, bs2055hiDR_25, bs2060hiDR_25)
bs_hiDR$Building_id<-bs_hiDR$Building # preserve original building id
bs_hiDR$Building<-1:nrow(bs_hiDR)
dupe_hiDR<-which(duplicated(bs_hiDR[,2:113]))
bs_hiDR<-bs_hiDR[!duplicated(bs_hiDR[,2:113]),]

bs_hiDRDE<-rbind(bs2025hiDRDE_25, bs2030hiDRDE_25, bs2035hiDRDE_25, bs2040hiDRDE_25, bs2045hiDRDE_25, bs2050hiDRDE_25, bs2055hiDRDE_25, bs2060hiDRDE_25)
bs_hiDRDE$Building_id<-bs_hiDRDE$Building # preserve original building id
bs_hiDRDE$Building<-1:nrow(bs_hiDRDE)
dupe_hiDRDE<-which(duplicated(bs_hiDRDE[,2:113]))
bs_hiDRDE<-bs_hiDRDE[!duplicated(bs_hiDRDE[,2:113]),]

bs_hiDRRFA<-rbind(bs2025hiDRRFA_25, bs2030hiDRRFA_25, bs2035hiDRRFA_25, bs2040hiDRRFA_25, bs2045hiDRRFA_25, bs2050hiDRRFA_25, bs2055hiDRRFA_25, bs2060hiDRRFA_25)
bs_hiDRRFA$Building_id<-bs_hiDRRFA$Building # preserve original building id
bs_hiDRRFA$Building<-1:nrow(bs_hiDRRFA)
dupe_hiDRRFA<-which(duplicated(bs_hiDRRFA[,2:113]))
bs_hiDRRFA<-bs_hiDRRFA[!duplicated(bs_hiDRRFA[,2:113]),]

bs_hiDRDERFA<-rbind(bs2025hiDRDERFA_25, bs2030hiDRDERFA_25, bs2035hiDRDERFA_25, bs2040hiDRDERFA_25, bs2045hiDRDERFA_25, bs2050hiDRDERFA_25, bs2055hiDRDERFA_25, bs2060hiDRDERFA_25)
bs_hiDRDERFA$Building_id<-bs_hiDRDERFA$Building # preserve original building id
bs_hiDRDERFA$Building<-1:nrow(bs_hiDRDERFA)
dupe_hiDRDERFA<-which(duplicated(bs_hiDRDERFA[,2:113]))
bs_hiDRDERFA<-bs_hiDRDERFA[!duplicated(bs_hiDRDERFA[,2:113]),]

# identify and remove hiMF duplicates ##########
bs_hiMF<-rbind(bs2025hiMF_25, bs2030hiMF_25, bs2035hiMF_25, bs2040hiMF_25, bs2045hiMF_25, bs2050hiMF_25, bs2055hiMF_25, bs2060hiMF_25)
bs_hiMF$Building_id<-bs_hiMF$Building # preserve original building id
bs_hiMF$Building<-1:nrow(bs_hiMF)
dupe_hiMF<-which(duplicated(bs_hiMF[,2:113]))
bs_hiMF<-bs_hiMF[!duplicated(bs_hiMF[,2:113]),]

bs_hiMFDE<-rbind(bs2025hiMFDE_25, bs2030hiMFDE_25, bs2035hiMFDE_25, bs2040hiMFDE_25, bs2045hiMFDE_25, bs2050hiMFDE_25, bs2055hiMFDE_25, bs2060hiMFDE_25)
bs_hiMFDE$Building_id<-bs_hiMFDE$Building # preserve original building id
bs_hiMFDE$Building<-1:nrow(bs_hiMFDE)
dupe_hiMFDE<-which(duplicated(bs_hiMFDE[,2:113]))
bs_hiMFDE<-bs_hiMFDE[!duplicated(bs_hiMFDE[,2:113]),]

bs_hiMFRFA<-rbind(bs2025hiMFRFA_25, bs2030hiMFRFA_25, bs2035hiMFRFA_25, bs2040hiMFRFA_25, bs2045hiMFRFA_25, bs2050hiMFRFA_25, bs2055hiMFRFA_25, bs2060hiMFRFA_25)
bs_hiMFRFA$Building_id<-bs_hiMFRFA$Building # preserve original building id
bs_hiMFRFA$Building<-1:nrow(bs_hiMFRFA)
dupe_hiMFRFA<-which(duplicated(bs_hiMFRFA[,2:113]))
bs_hiMFRFA<-bs_hiMFRFA[!duplicated(bs_hiMFRFA[,2:113]),]

bs_hiMFDERFA<-rbind(bs2025hiMFDERFA_25, bs2030hiMFDERFA_25, bs2035hiMFDERFA_25, bs2040hiMFDERFA_25, bs2045hiMFDERFA_25, bs2050hiMFDERFA_25, bs2055hiMFDERFA_25, bs2060hiMFDERFA_25)
bs_hiMFDERFA$Building_id<-bs_hiMFDERFA$Building # preserve original building id
bs_hiMFDERFA$Building<-1:nrow(bs_hiMFDERFA)
dupe_hiMFDERFA<-which(duplicated(bs_hiMFDERFA[,2:113]))
bs_hiMFDERFA<-bs_hiMFDERFA[!duplicated(bs_hiMFDERFA[,2:113]),]

### next stage #######
# combine scenario csvs
bs_base_all<-rbind(bs_base,bs_baseDE,bs_baseRFA,bs_baseDERFA)
bs_base_all$Building<-1:nrow(bs_base_all)
# bs_base_unique<-distinct(bs_base_all[,-c(1,114,115,116)]) # not currently worth the (row-tracking) effort of removing duplicates here, will see later if it will be necessary with a bigger sample

bs_hiDR_all<-rbind(bs_hiDR,bs_hiDRDE,bs_hiDRRFA,bs_hiDRDERFA)
bs_hiDR_all$Building<-1:nrow(bs_hiDR_all)
# bs_hiDR_unique<-distinct(bs_hiDR_all[,-c(1,114,115,116)]) # not currently worth the (row-tracking) effort of removing duplicates here, will see later if it will be necessary with a bigger sample

bs_hiMF_all<-rbind(bs_hiMF,bs_hiMFDE,bs_hiMFRFA,bs_hiMFDERFA)
bs_hiMF_all$Building<-1:nrow(bs_hiMF_all)
# bs_hiMF_unique<-distinct(bs_hiMF_all[,-c(1,114,115,116)]) # not currently worth the (row-tracking) effort of removing duplicates here, will see later if it will be necessary with a bigger sample
rssave<-rm_dot2(rs[,1:113])

# save csvs ready for simulation
bs_base_sim<-rm_dot2(bs_base_all[,1:113])
bs_hiDR_sim<-rm_dot2(bs_hiDR_all[,1:113])
bs_hiMF_sim<-rm_dot2(bs_hiMF_all[,1:113])

write.csv(bs_base_sim,file='../scen_bscsv_sim/bs_base.csv', row.names = FALSE)
write.csv(bs_hiDR_sim,file='../scen_bscsv_sim/bs_hiDR.csv', row.names = FALSE)
write.csv(bs_hiMF_sim,file='../scen_bscsv_sim/bs_hiMF.csv', row.names = FALSE)





# bs_baseDE<-rbind(bs2025baseDE_25, bs2030baseDE_25, bs2035baseDE_25, bs2040baseDE_25, bs2045baseDE_25, bs2050baseDE_25, bs2055baseDE_25, bs2060baseDE_25)
# bs_baseRFA<-rbind(bs2025baseRFA_25, bs2030baseRFA_25, bs2035baseRFA_25, bs2040baseRFA_25, bs2045baseRFA_25, bs2050baseRFA_25, bs2055baseRFA_25, bs2060baseRFA_25)
# bs_baseDERFA<-rbind(bs2025baseDERFA_25, bs2030baseDERFA_25, bs2035baseDERFA_25, bs2040baseDERFA_25, bs2045baseDERFA_25, bs2050baseDERFA_25, bs2055baseDERFA_25, bs2060baseDERFA_25)
# bs_base_all<-rbind(bs_base,bs_baseDE,bs_baseRFA,bs_baseDERFA)
# bs_base_unique<-distinct(bs_base_all[,-c(1,114,115,116)])
# 
# base_dupe<-matrix(0,nrow(bs_base_all),nrow(bs_base_all))
# # this seems a very slow inefficienct way to find which rows are duplicates of which other rows. Would be far too slow for the big samples
# for (r in 1:nrow(bs_base_all)) {
#   for (c in 1:nrow(bs_base_all)) {
#     base_dupe[r,c]<-as.numeric(all(bs_base_all[r,2:113]==bs_base_all[c,2:113]))
#   }
# }

# RFA_DERFA<-DE_DERFA<-DE_RFA<-baseRFA<-baseDERFA<-baseDE<-matrix(0,200,1)
# for (l in 1:200) {
#   # baseDE[l]<-as.numeric(all(bs_base[l,2:113]==bs_baseDE[l,2:113]))
#   # baseRFA[l]<-as.numeric(all(bs_base[l,2:113]==bs_baseRFA[l,2:113]))
#   # baseDERFA[l]<-as.numeric(all(bs_base[l,2:113]==bs_baseDERFA[l,2:113]))
#   
#   DE_RFA[l]<-as.numeric(all(bs_baseDE[l,2:113]==bs_baseRFA[l,2:113]))
#   DE_DERFA[l]<-as.numeric(all(bs_baseDE[l,2:113]==bs_baseDERFA[l,2:113]))
#   
#   RFA_DERFA[l]<-as.numeric(all(bs_baseRFA[l,2:113]==bs_baseDERFA[l,2:113]))
# }
# dupes<-which(duplicated(bs_base_all[,2:113]))
# dupmat<-matrix(0,nrow(bs_base_all),length(dupes))
# for (r in 1:nrow(bs_base_all)) {
#   for (c in 1:length(dupes)) {
#     dupmat[r,c]<-as.numeric(all(bs_base_all[r,2:113]==bs_base_all[dupes[c],2:113]))
#   }
# }
# colnames(dupmat)<-dupes
# chk<-rep(0,800)
# for (i in 1:800) {
#   chk[i]<-all(bs_base_all[i,2:113]==bs_base_all[76,2:113])
# }
# which(chk>0)
# dms<-matrix(0,25,25)
# for (r in 1:25) {
#   for (c in 1:25) {
    # dms[r,c]<-as.numeric(all(bs2025base_25[r,1:113]==bs2030base_25[c,1:113]))
    # dms[r,c]<-as.numeric(all(bs2035base_25[r,1:113]==bs2040base_25[c,1:113])) # this is the only one that gives duplicates. I don't know why.
    # dms[r,c]<-as.numeric(all(bs2045base_25[r,1:113]==bs2050base_25[c,1:113]))
    # dms[r,c]<-as.numeric(all(bs2055base_25[r,1:113]==bs2060base_25[c,1:113]))
    
    
#   }
# }
#########
# rs1<-read.csv("../scen_bscsv/bs2035base_25.csv")
# rs2<-read.csv("../scen_bscsv/bs2040base_25.csv")
# 
# rs3<-read.csv("../resources/bs2035base_25.csv")
# rs4<-read.csv("../resources/bs2040base_25.csv")
