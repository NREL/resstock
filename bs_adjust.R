# update bs csvs in ways that was not possible when modifying the tsv housing characteristics files
# Peter Berrill, Jan 12 2021
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
# setwd("C:/Users/pb637/Documents/Yale Courses/Research/Final Paper/StockModelCode/")

load("buildstock100.RData") # just demonstrating with the 100,000 bs.csv 
# View(names(rs))
# windows, update TX, FL, NY, NE, DE and MD windows to `Option=Low-E, Double, Low-Gain` for all vintages 2020 onwards
# rs[rs$State=="TX"| rs$State=="FL" | rs$State=="NY" | rs$State== "NE" | rs$State=="DE" | rs$State == "MD",]$Windows<-"Low-E, Double, Low-Gain"

states<-c("TX","FL","NY","NE","DE","MD") # states which have faster adoption of IECC codes than their ResStock custom regionss
# windows ############ same process for all years 
# all of the states are predominantly (exception of upper NY state) in regions with low-gain windows specified
rs[rs$State %in% states,]$Windows<-"Low-E, Double, Low-Gain"
# ducts do not vary by geography

# Infiltration ############ # same process for all years
# in FL, bring anything over ACH5 down to ACH5. 
rs[rs$State=="FL"&rs$Infiltration %in% c("6 ACH50","7 ACH50","8 ACH50","10 ACH50","15 ACH50","20 ACH50","25 ACH50","30 ACH50","40 ACH50","50 ACH50"),]$Infiltration<-"5 ACH50"
# In all other rogue states, bring anything above ACH3 down to ACH3.
rs[rs$State %in% c("TX","NY","NE","DE","MD")  &rs$Infiltration %in% c("4 ACH50","5 ACH50", "6 ACH50","7 ACH50","8 ACH50","10 ACH50","15 ACH50","20 ACH50","25 ACH50","30 ACH50","40 ACH50","50 ACH50"),]$Infiltration<-"3 ACH50"

# Insulation crawlspace ########### # no diff b/w IECC 2015 and 2021
# no rqm for TX or FL (climate zones 3, 2, 1)
# NY, DE, and MD in CZ 4 go to R10/R13. NE in CZ5 goes to R15/R19
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Crawlspace %in% c("Uninsulated, Vented"),]$Insulation.Crawlspace<-"Ceiling R-13, Vented"
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Crawlspace %in% c("Wall R-5, Unvented") ,]$Insulation.Crawlspace<-"Wall R-10, Unvented"
rs[rs$State =="NE" & rs$Insulation.Crawlspace %in% c("Uninsulated, Vented","Ceiling R-13, Vented"),]$Insulation.Crawlspace<-"Ceiling R-19, Vented"
rs[rs$State =="NE" & rs$Insulation.Crawlspace  %in% c("Wall R-5, Unvented","Wall R-10, Unvented") ,]$Insulation.Crawlspace<-"Wall R-15, Unvented" # this is a new option

# Insulation Finished Basement ###########
# no rqm for TX or FL (climate zones 3, 2, 1)
# NY, DE, and MD in CZ 4 go to R10. NE in CZ5 goes to R15
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Finished.Basement %in% c("Uninsulated","Wall R-5"),]$Insulation.Finished.Basement<-"Wall R-10"
rs[rs$State =="NE" & rs$Insulation.Finished.Basement %in% c("Uninsulated","Wall R-5","Wall R-10"),]$Insulation.Finished.Basement<-"Wall R-15"

# Insulation IZ Floor and PB and Fin Roof unchanged

# Insulation Slab ######
# no rqm for TX or FL (climate zones 3, 2, 1)
# NY, DE, and MD in CZ 4 go to R10 3ft. NE in CZ5 goes to R10 4ft
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Slab %in% c("2ft R5 Perimeter, R5 Gap"),]$Insulation.Slab<-"2ft R10 Perimeter, R10 Gap"
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Slab %in% c("Uninsulated", "2ft R5 Exterior"),]$Insulation.Slab<-"2ft R10 Exterior"

rs[rs$State %in% c("NE") & rs$Insulation.Slab %in% c("2ft R5 Perimeter, R5 Gap","2ft R10 Perimeter, R10 Gap"),]$Insulation.Slab<-"4ft R10 Perimeter, R10 Gap" # new option
rs[rs$State %in% c("NE") & rs$Insulation.Slab %in% c("Uninsulated", "2ft R5 Exterior","2ft R10 Exterior"),]$Insulation.Slab<-"4ft R10 Exterior"

# second round, for IECC 2021, applied from 2030s onwards. zone 4 now also goes to 4ft R10. Zone 3 now has a stipulation in IECC 2021, but TX is mostly Zone 2 so leave unchanged
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Slab %in% c("2ft R5 Perimeter, R5 Gap","2ft R10 Perimeter, R10 Gap"),]$Insulation.Slab<-"4ft R10 Perimeter, R10 Gap" # new option
rs[rs$State %in% c("NY","DE","MD") & rs$Insulation.Slab %in% c("Uninsulated", "2ft R5 Exterior","2ft R10 Exterior"),]$Insulation.Slab<-"4ft R10 Exterior"

# Insulation Unfinished Attic ########
# TX and FL go to R-38 min. CZ4 and CZ5 go to R-49 min. 
rs[rs$State %in% c("TX","FL") & rs$Insulation.Unfinished.Attic %in% c("Uninsulated, Vented","Ceiling R-7, Vented","Ceiling R-13, Vented","Ceiling R-19, Vented","Ceiling R-30, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-38, Vented"
rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Unfinished.Attic %in% c("Uninsulated, Vented","Ceiling R-7, Vented","Ceiling R-13, Vented","Ceiling R-19, Vented","Ceiling R-30, Vented",
                                                                                "Ceiling R-38, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-49, Vented"
# second round, for IECC 2021, from 2030s. TX FL now go to R-49, and CZ 4 and 5 go to R-60
rs[rs$State %in% c("TX","FL") & rs$Insulation.Unfinished.Attic %in% c("Ceiling R-38, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-49, Vented"
rs[rs$State %in% c("NY","DE","MD","NE") & rs$Insulation.Unfinished.Attic %in% c("Ceiling R-49, Vented"),]$Insulation.Unfinished.Attic<-"Ceiling R-60, Vented"

# Insulation Unfinished Basement ########### # no diff b/w IECC 2015 and 2021
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



# higher adoptions of efficient AC in southern states #################
SoSt8<-c("DC","DE", "KY","MD","TN","VA","WV")
SoLR<-c("CR09","CR10","CR11")
rs$SoCool<-0 # is it a souther cooling state, with regard to efficiency standards?
rs[rs$Location.Region %in% SoLR | rs$State %in% SoSt8,]$SoCool<-1

# define probability matrix for hvac cooling efficiency
ceff_types<-rownames(table(rs$HVAC.Cooling.Efficiency))
ceff_types<-c(ceff_types[c(2:3)], "AC, SEER 18",ceff_types[c(5:6,10,7:8,11)])
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
