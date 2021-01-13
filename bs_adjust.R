# update bs csvs in ways that was not possible when modifying the tsv housing characteristics files
# Peter Berrill, Jan 12 2021
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
load("buildstock100.RData") # just demonstrating with the 100,000 bs.csv 
# View(names(rs))
# windows, update TX, FL, NY, NE, DE and MD windows to `Option=Low-E, Double, Low-Gain` for all vintages 2020 onwards
# rs[rs$State=="TX"| rs$State=="FL" | rs$State=="NY" | rs$State== "NE" | rs$State=="DE" | rs$State == "MD",]$Windows<-"Low-E, Double, Low-Gain"

states<-c("TX","FL","NY","NE","DE","MD") # states which have faster adoption of IECC codes than their ResStock custom regionss

rs[rs$State %in% states,]$Windows<-"Low-E, Double, Low-Gain"

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
