## modelling of efficiency and technology upgrade scenarios to existing pre-2020 units
# Peter Berrill Jan 18 2020
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(readr)
library(reshape2)
setwd("~/Yale Courses/Research/Final Paper/resstock_scenarios/projection_scripts")
# load("bs2020GHG2.RData") # bs2020_150k including regression energy estimates and GHG calculations.
load("~/Yale Courses/Research/US Housing/AHS/RenovationStats_new.RData") # produced by script AHS_new_ren2.R
load('../../StockModelCode/rencombs.RData') # produced by older version of this script. Combinations of heat fuel/efficiencies, water heat fuel/efficiencies, cooling efficiencies, insulation types
rs<-read.csv("../scen_bscsv/bs2020_25.csv") # load in most recent sample of 2020 housing stock
# rs<-bs2020GHG
nms<-names(rs) # see which columns can be removed, none until after the RS simulations have been done
# base_weight is already included in the rs file, not sure about this with the new rs directly from the bs.csv

# create columns for indicating the year of the most recent renovation
rs$last_ctren_none<-rs$last_ctren_room<-rs$last_hren<-rs$last_cren<-rs$last_wren<-rs$last_iren<-0
# create columns for indicating the probability of getting renovated
rs$pi<-rs$pw<-rs$pc<-rs$ph<-rs$pctnone<-rs$pctroom<-0  # probability of renovating insulation (pi), water heater (pw), cooling equipment (pc), heating equipment (ph), changing cooling type (pctnone, pctroom)
# create columns to make note of renovations which actually make no change (e.g. because max eff level has already been reached). 
# These will be turned to zero if a renovation actually involves no change
rs$change_hren<-rs$change_wren<-rs$change_iren<-rs$change_cren<-0 # note here if a renovation makes any change
rscn<-names(rs)

# define heating fuel and efficiency combos
rs$Heating.Fuel_Efficiency<-paste(rs$Heating.Fuel,rs$HVAC.Heating.Efficiency,sep = "_")
# hfeff types pre-loaded in rencombs
phfe<-matrix(0,length(hfeff_types),length(hfeff_types)) # probability of increasing heating fuel efficiency. Define the actual values later. changes to HP will need to be also reflected in the HVAC Heating Type column
colnames(phfe)<-rownames(phfe)<-hfeff_types

htf<-as.data.frame(read_tsv('../project_national_2025_base/housing_characteristics/HVAC Heating Type and Fuel.tsv',col_names = TRUE))
htft<-t(htf)
# adjust the fuel switching probability matrix pfuel_all to slightly reduce chance of switching elec-> oil in NE
pfuel_all[,"Electricity","NE"]<-c(0.67,0.01,0.24,0.045,0,0.035)

# define the matrix for wall insulation switching. 
#wins_types pre-loaded in rencombs
pwins<-matrix(0,length(wins_types),length(wins_types))
colnames(pwins)<-rownames(pwins)<-wins_types
# probability matrices are organised by post renovation level (rows) and pre renovation level (cols)
# For now I basically define that insulation switches 50:50 to levels 1:2 levels higher, unless on the second-to-top or top level, in which they can only go 1 or 0 levels higher
# brick and concrete walls
pwins[3:4,1:2]<-0.5
pwins[4:5,3]<-0.5
pwins[5:6,4]<-0.5
pwins[6,5:6]<-1
# wood stud walls
pwins[8:9,7]<-0.5
pwins[9:10,8]<-0.5
pwins[10:11,9]<-0.5
pwins[11:12,10]<-0.5
pwins[12,11:12]<-1

# define that when a wall insulation happens, a basement insulation also happens, if the basement is a crawlspace or an unfinished basement, and an attic insulation also happens
# crins types pre-loaded in rencombs
pcrins<-matrix(0,length(crins_types),length(crins_types))
colnames(pcrins)<-rownames(pcrins)<-crins_types
# again define swithcing 50:50 up 1/2 levels where possible
pcrins[2:3,1]<-0.5
pcrins[3,2:3]<-1
pcrins[4,4]<-1 # None remains None
pcrins[6:7,5]<-0.5
pcrins[7,6:7]<-1

# replicate for unfinished basements
# ubins_types pre-loaded in rencombs
pubins<-matrix(0,length(ubins_types),length(ubins_types))
colnames(pubins)<-rownames(pubins)<-ubins_types
# again define switching 50:50 up 1/2 levels where possible
pubins[2:3,1]<-0.5
pubins[3,2:3]<-1
pubins[4,4]<-1 # None remains None

# replicate for unfinished attics
# uains types pre-loaded in rencombs. needs redefined as it omits R-60
uains_types<-c("Uninsulated, Vented", "Ceiling R-7, Vented","Ceiling R-13, Vented", "Ceiling R-19, Vented", "Ceiling R-30, Vented", "Ceiling R-38, Vented", "Ceiling R-49, Vented",
               "Ceiling R-60, Vented", "None")
puains<-matrix(0,length(uains_types),length(uains_types))
colnames(puains)<-rownames(puains)<-uains_types
# R-19 is now the minimum level for new construction, so leapfrog from uninsulated to at least R-19
puains[4:5,1:2]<-c(0.75,0.25)
puains[4:6,3]<-c(0.25,0.65,0.1) # higher levels if starting from R-13
puains[5:6,4]<-c(0.5,0.5)
puains[6:7,5]<-c(0.5,0.5)
puains[7:8,6]<-c(0.5,0.5)
puains[8,7:8]<-1
puains[9,9]<-1 # None remains None

# infiltration, which will also reduce with insulation retrofits
inf<-as.data.frame(read_tsv('../project_national_2025_base/housing_characteristics/Infiltration.tsv',col_names = TRUE))
inf_types<-gsub("Option=","", names(inf)[4:18])

pinf<-matrix(0,length(inf_types),length(inf_types))
colnames(pinf)<-rownames(pinf)<-inf_types
pinf[1:3,1:3]<-diag(3) # no improvement in infiltration if already ACH3 or lower
pinf[3:14,4:15]<-diag(12) # for all other initial levels, renovation reduced infiltration by one degree

# now define probability matrices for switching water heater,  table(rs$Water.Heater). mainly some fuel switching, plus some upgrades to 'premium' efficiency and 'tankless' as well as heat pumps
# wheff_types pre-loaded in rencombs
whfe<-matrix(0,length(wheff_types),length(wheff_types))
colnames(whfe)<-rownames(whfe)<-wheff_types # values will be defined within the loop, depending on region

# now define probability matrices for switching AC. Four types (central, room, HP, none), dependent on heating type (ducted/non-ducted)
# 11 efficiency levels: four for central, one for HP, one for none, four for room, one for shared.

# two probabilities apply for cooling, probability of switching system, defined within the loop by pctype_all, 
# and probability of an efficiency upgrades within types for central and room, which can be pre-defined
# first, remove the possibility of switching from room AC to no AC
pctype_all["None","Room",]<-0
# then define the probability of remainin Room as 1 - the probability of switching from room to central
pctype_all["Room","Room",]<-1-pctype_all["Central","Room",]
ACtypes<-colnames(pctype_all)<-rownames(pctype_all)<-c("Central AC","None","Room AC")
# now define probability matrix for efficiency and types
# ceff types pre-loaded in rencombs
ce<-matrix(0,length(ceff_types),length(ceff_types))
colnames(ce)<-rownames(ce)<-ceff_types
# for any central AC < SEER 13, move to 13. Below 13 not sold anymore (https://www.eia.gov/analysis/studies/residential/pdf/res_ee_fuel_switch.pdf)
ce[3,1:2]<-1
# for central AC SEER == 13, replace with 13:15:18 in ratio 10:80:10
ce[3:5,3]<-c(0.1,0.8,0.1)
# for central AC SEER ==15, repace with 15:18 in ratio 25:75
ce[4:5,4]<-c(0.25,0.75)
# central SEER 18, HP, and None all remain the same
ce[5:7,5:7]<-diag(3)
# for 8.5 and 9.8 EER room AC, move up two levels in 50:50 ratio
ce[9:10,8]<-ce[10:11,9]<-0.5
# for 10.7 EER, replace with 10.7 12.0 in 25:75 ratio
ce[10:11,10]<-c(0.25,0.75)
# replace highest effient room AC (12), and shared cooling with itself
ce[11,11]<-ce[12,12]<-1

rs_2020<-rs
# define regions and types
Regions<-c("Northeast","Midwest","South","West")
RGs<-c("NE","MW","S","W")
# Types<-c("SF","MF","MH")
# define yr, this will later be in a loop
for (yr in 2021:2060) {
  print(yr)
# yr<-2021
for (r in 1:4) {# four regions 
print(RGs[r])
RG<-rs[rs$Census.Region==Regions[r],]
# pick out SF units
SF<-RG[substr(RG$Geometry.Building.Type.RECS,1,6)=="Single",]
SF$pi<-SF$ph<-SF$pw<-SF$pc<-SF$pctnone<-SF$pctroom<-0
hren<-pren[RGs[r],"SF","Heat"] # the renovation rate for a given region, type, system combination
hLT<-round(1/hren) # average lifetime of equipment, or period for replacements
hIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(hLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-hLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
hIC[which(hIC$Year>(full-1)&hIC$Year<(half+1)),]$Rate<-rev(seq(0,hren,length.out = hLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
hIC[hIC$Year<full,]$Rate<-hren
SF[SF$Vintage.ACS=="<1940",]$ph<-hren
SF[SF$Vintage.ACS=="1940-59",]$ph<-mean(hIC[which(hIC$Year>1939&hIC$Year<1960),]$Rate)
SF[SF$Vintage.ACS=="1960-79",]$ph<-mean(hIC[which(hIC$Year>1959&hIC$Year<1980),]$Rate)
SF[SF$Vintage.ACS=="1980-99",]$ph<-mean(hIC[which(hIC$Year>1979&hIC$Year<2000),]$Rate)
SF[SF$Vintage.ACS=="2000-09",]$ph<-mean(hIC[which(hIC$Year>1999&hIC$Year<2010),]$Rate)
SF[SF$Vintage.ACS=="2010s",]$ph<-mean(hIC[which(hIC$Year>2009),]$Rate)

numren<-round(nrow(SF)*hren) # Number of units renovated, this approach avoids the downward bias from setting ph<hren for recently built units, since hren was calculated as the stock average rate, including recent units 
if (any(SF$last_hren>full+4)) {SF[SF$last_hren>full+4,]$ph<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(SF),numren,prob=SF$ph) # which rows are the renovated ones
SFhrensam<-SF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
SFhrensam$last_hren<-yr

# define heating renovation probability matrix phfe #############
# Renovations of electric HP heating systems
# assign ASHPs to the equivalent 1 and 2 levels higher, in 50:50 ratio
for (rc in 1:4) { # for row/column 1:4
  phfe[rc+1:2,rc]<-pfuel_all["Electricity HP","Electricity HP",RGs[r]]*0.5 # multiply the chance of reamining with a heat pump by 0.5 as we split this into two efficiency levels
}
# assign the two most efficienct ASHPs to the most efficient ASHP
phfe[6,5:6]<-pfuel_all["Electricity HP","Electricity HP",RGs[r]]

# assign MSHP to the higher version of themselves, apart from the highest efficiency, which is assigned to itself
phfe[13,13]<-phfe[13,12]<-phfe[12,11]<-pfuel_all["Electricity HP","Electricity HP",RGs[r]]

# switching from el HP to el res.: assign ducted AHSP to electric furnace
phfe[9,1:6]<-pfuel_all["Electricity","Electricity HP",RGs[r]]
# assign non-ducted MSHP to electric baseboard
phfe[7,11:13]<-pfuel_all["Electricity","Electricity HP",RGs[r]]

# switching from el HP to fuel (only gas applies), assign ducted ASHP to two most efficient furnaces in 50:50 ratio
phfe[c("Natural Gas_Fuel Furnace, 80% AFUE","Natural Gas_Fuel Furnace, 92.5% AFUE"),c(1:6)]<-0.5*pfuel_all["Gas","Electricity HP",RGs[r]]
# assign non-ducted MSHP, assume 35:35:10:20 split between the two most efficient boilers and the most efficient floor/wall furnace ,"Natural Gas_Fuel Boiler, 96% AFUE"
phfe[c("Natural Gas_Fuel Boiler, 80% AFUE","Natural Gas_Fuel Boiler, 90% AFUE"),c(11:13)]<-0.35*pfuel_all["Gas","Electricity HP",RGs[r]]
phfe[c("Natural Gas_Fuel Boiler, 96% AFUE"),c(11:13)]<-0.1*pfuel_all["Gas","Electricity HP",RGs[r]]
phfe[c("Natural Gas_Fuel Wall/Floor Furnace, 68% AFUE"),c(11:13)]<-0.2*pfuel_all["Gas","Electricity HP",RGs[r]]

# Renovations of electric resistance heating systems
# assign all resistance electricity to themselves
phfe[7:10,7:10]<-pfuel_all["Electricity","Electricity",RGs[r]]*diag(4)
# assign non-ducted resistance electricity to non-ducted MSHP, two least efficient in 50:50 ratio
phfe[11:12,c(7,8,10)]<-pfuel_all["Electricity HP","Electricity",RGs[r]]*0.5
# assign ducted electricity furnaces to two standard efficiency ASHP in 50:50 ratio
phfe[2:3,9]<-pfuel_all["Electricity HP","Electricity",RGs[r]]*0.5

# switching from el resistance ducted to fuel ducted, assume a 50:50 split between the two most efficient types, this is a much more efficient mix than the current mix of fuel furnaces
phfe[c("Natural Gas_Fuel Furnace, 80% AFUE","Natural Gas_Fuel Furnace, 92.5% AFUE"),c(9)]<-0.5*pfuel_all["Gas","Electricity",RGs[r]]
phfe[c("Fuel Oil_Fuel Furnace, 80% AFUE","Fuel Oil_Fuel Furnace, 92.5% AFUE"),c(9)]<-0.5*pfuel_all["Oil","Electricity",RGs[r]]
phfe[c("Propane_Fuel Furnace, 80% AFUE","Propane_Fuel Furnace, 92.5% AFUE"),c(9)]<-0.5*pfuel_all["Propane","Electricity",RGs[r]]
# switching from el res non-ducted to gas non-ducted, assume 35:35:10:20 split between the three most efficent boilers and  most efficient floor/wall furnace
phfe[c("Natural Gas_Fuel Boiler, 80% AFUE","Natural Gas_Fuel Boiler, 90% AFUE"),c(7,8,10)]<-0.35*pfuel_all["Gas","Electricity",RGs[r]]
phfe[c("Natural Gas_Fuel Boiler, 96% AFUE"),c(7,8,10)]<-0.1*pfuel_all["Gas","Electricity",RGs[r]]
phfe[c("Natural Gas_Fuel Wall/Floor Furnace, 68% AFUE"),c(7,8,10)]<-0.2*pfuel_all["Gas","Electricity",RGs[r]]
# switching from el res non-ducted to non-gas fuel non-ducted, assume 40:40:20 split between the three most efficent boilers and  most efficient floor/wall furnace
phfe[c("Fuel Oil_Fuel Boiler, 80% AFUE","Fuel Oil_Fuel Boiler, 90% AFUE"),c(7,8,10)]<-0.4*pfuel_all["Oil","Electricity",RGs[r]]
phfe[c("Fuel Oil_Fuel Wall/Floor Furnace, 68% AFUE"),c(7,8,10)]<-0.2*pfuel_all["Oil","Electricity",RGs[r]]
phfe[c("Propane_Fuel Boiler, 80% AFUE","Propane_Fuel Boiler, 90% AFUE"),c(7,8,10)]<-0.4*pfuel_all["Propane","Electricity",RGs[r]]
phfe[c("Propane_Fuel Wall/Floor Furnace, 68% AFUE"),c(7,8,10)]<-0.2*pfuel_all["Propane","Electricity",RGs[r]]

# Renovations of oil heating systems
# Oil->Oil
# oil boilers go up (or most efficient stay the same)
phfe[16:17,15]<-pfuel_all["Oil","Oil",RGs[r]]*0.5
phfe[17,16:17]<-pfuel_all["Oil","Oil",RGs[r]]
# oil ducted furnaces go up (or most efficient stay the same)
phfe[19:20,18]<-pfuel_all["Oil","Oil",RGs[r]]*0.5
phfe[20,19:20]<-pfuel_all["Oil","Oil",RGs[r]]
# oil floor/wall furnaces go up (or most efficient stay the same)
phfe[22,21:22]<-pfuel_all["Oil","Oil",RGs[r]]
# Oil->Elec HP
# Non-ducted oil heaters go to  MSHP, with a  50:50 split of the two most efficient
phfe[c(11:12),c(15:17,21:22)]<-pfuel_all["Electricity HP","Oil",RGs[r]]*0.5
# ducted oil furnaces go to low-mid efficiency ASHP, with a 50:50 split
phfe[c(2:3),18:20]<-pfuel_all["Electricity HP","Oil",RGs[r]]*0.5
# Oil->Elec Res
# Non-ducted oil heaters go to electric ductless resistance (allocate all to baseboard)
phfe[c(7),c(15:17,21:22)]<-pfuel_all["Electricity","Oil",RGs[r]]
# ducted oil furnaces go to electric ducted furnaces 
phfe[c(9),18:20]<-pfuel_all["Electricity","Oil",RGs[r]]
# Oil->Gas
# furnaces go to furnaces (two most efficient) with 50:50 split
phfe[30:31,18:20]<-pfuel_all["Gas","Oil",RGs[r]]*0.5
# non-ducted go to non-ducted of the same type, but up an efficiency level
phfe[33,21:22]<-phfe[26,16:17]<-phfe[25,15]<-pfuel_all["Gas","Oil",RGs[r]]
# Oil->Propane
# furnaces go to furnaces (two most efficient) with 50:50 split
phfe[43:44,18:20]<-pfuel_all["Propane","Oil",RGs[r]]*0.5
# non-ducted go to non-ducted of the same type, but up an efficiency level
phfe[46,21:22]<-phfe[40,16:17]<-phfe[39,15]<-pfuel_all["Propane","Oil",RGs[r]]

# Renovations of gas heating systems
# Gas->Gas
# gas boilers go up (or most efficient stay the same)
phfe[25:26,24]<-pfuel_all["Gas","Gas",RGs[r]]*0.5
phfe[26:27,25]<-pfuel_all["Gas","Gas",RGs[r]]*c(0.8,0.2) # make it less likely to change up to a 96% than 90% efficient, from 80%
phfe[27,26:27]<-pfuel_all["Gas","Gas",RGs[r]]
# gas ducted furnaces go up (or most efficient stay the same) (for some reason there exist 60% AFUE gas furnaces but not oil furnaces)
phfe[30:31,29]<-phfe[29:30,28]<-pfuel_all["Gas","Gas",RGs[r]]*0.5
phfe[31,30:31]<-pfuel_all["Gas","Gas",RGs[r]]
# gas floor/wall furnaces go up (or most efficient stay the same)
phfe[33,32:33]<-pfuel_all["Gas","Gas",RGs[r]]
# Gas->Elec HP
# Non-ducted gas heaters go to MSHP, with a  50:50 split to the low:mid efficiency options
phfe[c(11:12),c(24:27,32:33)]<-pfuel_all["Electricity HP","Gas",RGs[r]]*0.5
# ducted gas furnaces go to low-mid efficiency ASHP, with a 50:50 split
phfe[c(2:3),28:31]<-pfuel_all["Electricity HP","Gas",RGs[r]]*0.5
# Gas -> Elec Res
# Non-ducted gas heaters go to electric ductless resistance (allocate all to baseboard)
phfe[c(7),c(24:27,32:33)]<-pfuel_all["Electricity","Gas",RGs[r]]
# ducted gas furnaces go to electric ducted furnaces
phfe[c(9),28:31]<-pfuel_all["Electricity","Gas",RGs[r]]
# Gas->Oil
# furnaces go to furnaces (two most efficient) with 50:50 split
phfe[19:20,28:31]<-pfuel_all["Oil","Gas",RGs[r]]*0.5
# non-ducted go to non-ducted of the same type, but up an efficiency level where possible
phfe[22,32:33]<-phfe[17,25:27]<-phfe[16,24]<-pfuel_all["Oil","Gas",RGs[r]]
# Gas->Propane
# furnaces go to furnaces (two most efficient) with 50:50 split
phfe[43:44,28:31]<-pfuel_all["Propane","Gas",RGs[r]]*0.5
# non-ducted go to non-ducted of the same type, but up an efficiency level
phfe[46,32:33]<-phfe[44,25:27]<-phfe[43,24]<-pfuel_all["Propane","Gas",RGs[r]]

# Renovations of propane heating systems
# Propane->Propane
# propane boilers go up (or most efficient stay the same)
phfe[39:40,38]<-pfuel_all["Propane","Propane",RGs[r]]*0.5
phfe[40,39:40]<-pfuel_all["Propane","Propane",RGs[r]]
# propane ducted furnaces go up (or most efficient stay the same) (for some reason there exist 60% AFUE propane furnaces but not oil furnaces)
phfe[43:44,42]<-phfe[42:43,41]<-pfuel_all["Propane","Propane",RGs[r]]*0.5
phfe[44,43:44]<-pfuel_all["Propane","Propane",RGs[r]]
# propane floor/wall furnaces go up (or most efficient stay the same)
phfe[46,45:46]<-pfuel_all["Propane","Propane",RGs[r]]
# Propane->Elec HP
# Non-ducted prop heaters go to  MSHP, with a  50:50 split
phfe[c(11:12),c(38:40,45:46)]<-pfuel_all["Electricity HP","Propane",RGs[r]]*0.5
# ducted prop furnaces go to electric ducted furnaces or low-mid efficiency ASHP, with a 50:50 split
phfe[c(2:3),41:44]<-pfuel_all["Electricity HP","Propane",RGs[r]]*0.5

# Non-ducted prop heaters go to electric ductless resistance (allocate all to baseboard)
phfe[c(7),c(38:40,45:46)]<-pfuel_all["Electricity","Propane",RGs[r]]
# ducted prop furnaces go to electric ducted furnaces 
phfe[c(9),41:44]<-pfuel_all["Electricity","Propane",RGs[r]]
# Propane->Oil
# furnaces go to furnaces (two most efficient) with 50:50 split
phfe[19:20,41:44]<-pfuel_all["Oil","Propane",RGs[r]]*0.5
# non-ducted go to non-ducted of the same type, but up an efficiency level
phfe[22,45:46]<-phfe[17,39:40]<-phfe[16,38]<-pfuel_all["Oil","Propane",RGs[r]]
# Propane->Gas
# furnaces go to furnaces (two most efficient) with 50:50 split
phfe[30:31,41:44]<-pfuel_all["Gas","Propane",RGs[r]]*0.5
# non-ducted go to non-ducted of the same type, but up an efficiency level
phfe[33,45:46]<-phfe[27,40]<-phfe[26,39]<-phfe[25,38]<-pfuel_all["Gas","Propane",RGs[r]]

# make sure that other/none/void/shared heating remain unchanged
for (h in which(sub(".*_","",colnames(phfe))=="Void"|sub(".*_","",colnames(phfe))=="None"|sub(".*_","",colnames(phfe))=="Other"|sub(".*_","",colnames(phfe))=="Shared Heating")) {
  phfe[h,h]<-1
}
# check colsums ==1
min(colSums(phfe))
max(colSums(phfe))
# demonstrate probs for electricity and gas systems
# pp<-phfe[,c(1,7:9)]
# ppp<-round(pp[which(rowSums(pp)>0),],4)
# pp<-phfe[,c(25:33)]
# ppp<-round(pp[which(rowSums(pp)>0),],3)

# continue on, characteristics before #############
table(SF$Heating.Fuel)
table(SF$HVAC.Heating.Efficiency)
table(SFhrensam$Heating.Fuel)
table(SFhrensam$HVAC.Heating.Efficiency)
SFhrensam$Heating.Fuel_Efficiency_new<-"NA"
for (i in 1:nrow(SFhrensam)) {
  SFhrensam$Heating.Fuel_Efficiency_new[i]<-sample(hfeff_types,1,p=phfe[,SFhrensam$Heating.Fuel_Efficiency[i]])
  SFhrensam$HVAC.Heating.Type.And.Fuel[i]<-sample(gsub("Option=","",rownames(htft))[3:27],1,p=htft[3:27,which(htft[1,]==sub("_.*","",SFhrensam$Heating.Fuel_Efficiency_new[i])&htft[2,]== sub(".*_","",SFhrensam$Heating.Fuel_Efficiency_new[i]))])
  if (!SFhrensam$Heating.Fuel_Efficiency_new[i]==SFhrensam$Heating.Fuel_Efficiency[i]) {SFhrensam$change_hren[i]<-yr} # if a renovation actually makes a change, make note of that here
}

SFhrensam$Heating.Fuel<-sub("_.*","",SFhrensam$Heating.Fuel_Efficiency_new)
SFhrensam$HVAC.Heating.Efficiency<-sub(".*_","",SFhrensam$Heating.Fuel_Efficiency_new)
table(SFhrensam$Heating.Fuel)
table(SFhrensam$HVAC.Heating.Efficiency)
SFhrensam$Heating.Fuel_Efficiency<-SFhrensam$Heating.Fuel_Efficiency_new
SFhrensam<-SFhrensam[,!(names(SFhrensam) %in% c("Heating.Fuel_Efficiency_new"))]
SF[ren_rows,]<-SFhrensam
# after
# table(SF$Heating.Fuel)
# table(SF$HVAC.Heating.Efficiency)

# same for water heating fuel and efficiency
wren<-pren[RGs[r],"SF","Water"] # the renovation rate for a given region, type, system combination
wLT<-round(1/wren) # average lifetime of equipment, or period for replacements
wIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(wLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-wLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
wIC[which(wIC$Year>(full-1)&wIC$Year<(half+1)),]$Rate<-rev(seq(0,wren,length.out = wLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
wIC[wIC$Year<full,]$Rate<-wren
SF[SF$Vintage.ACS=="<1940",]$pw<-wren
SF[SF$Vintage.ACS=="1940-59",]$pw<-mean(wIC[which(wIC$Year>1939&wIC$Year<1960),]$Rate)
SF[SF$Vintage.ACS=="1960-79",]$pw<-mean(wIC[which(wIC$Year>1959&wIC$Year<1980),]$Rate)
SF[SF$Vintage.ACS=="1980-99",]$pw<-mean(wIC[which(wIC$Year>1979&wIC$Year<2000),]$Rate)
SF[SF$Vintage.ACS=="2000-09",]$pw<-mean(wIC[which(wIC$Year>1999&wIC$Year<2010),]$Rate)
SF[SF$Vintage.ACS=="2010s",]$pw<-mean(wIC[which(wIC$Year>2009),]$Rate)

numren<-round(nrow(SF)*wren) # Number of units renovated, this approach avoids the downward bias from setting pw<wren for recently built units, since wren was calculated as the stock average rate, including recent units 
if (any(SF$last_wren>full+4)) {SF[SF$last_wren>full+4,]$pw<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(SF),numren,prob=SF$pw) # which rows are the renovated ones
SFwrensam<-SF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
SFwrensam$last_wren<-yr

# Define whfe, detailing renovations of water heating systems ###########
# assign electric standard to el standard/prem/tankless/HP with 92:4:2:2 odds
whfe[1:4,"Electric Standard"]<-c(0.92,0.04,0.02,0.02)*pwfuel_all["Electricity","Electricity",RGs[r]]
# assign electric standard to gas standard/prem/tankless with 85:5:10 odds, rougly based on https://www.eia.gov/analysis/studies/residential/pdf/res_ee_fuel_switch.pdf pg 14
whfe[5:7,"Electric Standard"]<-c(.85,.05,.1)*pwfuel_all["Gas","Electricity",RGs[r]]
# assign electric all types to oil standard with 100% odds, no evidence for market penetration of efficient oil water heaters https://www.eia.gov/analysis/studies/residential/pdf/res_ee_fuel_switch.pdf pg 82
whfe[8,1:4]<-pwfuel_all["Oil","Electricity",RGs[r]]
# assign electric standard to propane standard/prem/tankless with 85:5:10 odds, rougly based on https://www.eia.gov/analysis/studies/residential/pdf/res_ee_fuel_switch.pdf pg 71
whfe[12:14,"Electric Standard"]<-c(.85,.05,.1)*pwfuel_all["Propane","Electricity",RGs[r]]
# assign elec premium to elec premium/tankless/HP, with 40:30;30 odds, same for all efficient elec options
whfe[2:4,"Electric Premium"]<-c(0.4,0.3,0.3)*pwfuel_all["Electricity","Electricity",RGs[r]]
# assign elec premium to elec premium/tankless/HP, with 40:30;30 odds, same for all efficient elec options
whfe[2:4,"Electric Tankless"]<-c(0.3,0.4,0.3)*pwfuel_all["Electricity","Electricity",RGs[r]]
# assign elec premium to elec premium/tankless/HP, with 40:30;30 odds, same for all efficient elec options
whfe[2:4,"Electric Heat Pump, 80 gal"]<-c(0.3,0.3,0.4)*pwfuel_all["Electricity","Electricity",RGs[r]]
# elec premium/tankless/HP to gas standard/prem/tankless with 10:60:30 odds
whfe[5:7,2:4]<-c(.1,.6,.3)*pwfuel_all["Gas","Electricity",RGs[r]]
# Define values in technology/efficiecy/fuel switching probability matrix phfe.
# assign electric premium/tankless/HP to propane standard/prem/tankless with 10:60:30 odds
whfe[12:14,2:4]<-c(.1,.6,.3)*pwfuel_all["Propane","Electricity",RGs[r]]
### renovations of gas water heating systems ###
# assign gas standard to gas standard/prem/tankless with 50:20:30 odds
whfe[5:7,"Natural Gas Standard"]<-c(0.5,0.2,0.3)*pwfuel_all["Gas","Gas",RGs[r]]
# gas standard to elec with 92:4:2:2 odds
whfe[1:4,"Natural Gas Standard"]<-c(0.92,0.04,0.02,0.02)*pwfuel_all["Electricity","Gas",RGs[r]]
# all gas to oil standard
whfe[8,5:7]<-pwfuel_all["Oil","Gas",RGs[r]]
# gas stnard to propane standard/prem/tankless with 85:5:10 odds
whfe[12:14,"Natural Gas Standard"]<-c(.85,.05,.1)*pwfuel_all["Propane","Gas",RGs[r]]
# gas premium to gas premium tankless with 70:30 odds, and vice versa
whfe[6:7,"Natural Gas Premium"]<-c(0.7,0.3)*pwfuel_all["Gas","Gas",RGs[r]]
whfe[6:7,"Natural Gas Tankless"]<-c(0.3,0.7)*pwfuel_all["Gas","Gas",RGs[r]]
# gas prem/tankless to elec prem/tankless/HP with 50:25:25 odds
whfe[2:4,6:7]<-c(0.5,0.25,0.25)*pwfuel_all["Electricity","Gas",RGs[r]]
# assign gas premium to propane prem/tankless with 65:35 odds, and vice versa
whfe[13:14,"Natural Gas Premium"]<-c(.65,.35)*pwfuel_all["Propane","Gas",RGs[r]]
# assign gas tankless to propane prem/tankless with 35:65 odds, and vice versa
whfe[13:14,"Natural Gas Tankless"]<-c(.35,.65)*pwfuel_all["Propane","Gas",RGs[r]]
### renovations of oil water heating systems ###
whfe[8:9,"Fuel Oil Standard"]<-c(0.95,0.05)*pwfuel_all["Oil","Oil",RGs[r]] # most oil standard remain oil standard
# oil standard to elec with 92:4:2:2 odds
whfe[1:4,"Fuel Oil Standard"]<-c(0.92,0.04,0.02,0.02)*pwfuel_all["Electricity","Oil",RGs[r]]
# oil standard to gas standard/prem/tankless with 85:5:10 odds
whfe[5:7,"Fuel Oil Standard"]<-c(.85,.05,.1)*pwfuel_all["Gas","Oil",RGs[r]]
# oil standard to propane standard/prem/tankless with 85:5:10 odds
whfe[12:14,"Fuel Oil Standard"]<-c(.85,.05,.1)*pwfuel_all["Propane","Oil",RGs[r]]
# oil premium to oil premium
whfe[9,9]<-pwfuel_all["Oil","Oil",RGs[r]] 
# oil premium to elec prem/tankless/HP with 50:25:25 odds
whfe[2:4,9]<-c(0.5,0.25,0.25)*pwfuel_all["Electricity","Oil",RGs[r]]
# oil premium to gas preimum
whfe[6,9]<-pwfuel_all["Gas","Oil",RGs[r]] 
# oil premium to propane preimum
whfe[13,9]<-pwfuel_all["Propane","Oil",RGs[r]] 
whfe[10:11,10:11]<-diag(2) # oil indirect, other fuel stay the same
## renovation of propane water heating systems ###
# assign propane standard to propane standard/prem/tankless with 50:20:30 odds
whfe[12:14,"Propane Standard"]<-c(0.5,0.2,0.3)*pwfuel_all["Propane","Propane",RGs[r]]
# propane standard to elec with 92:4:2:2 odds
whfe[1:4,"Propane Standard"]<-c(0.92,0.04,0.02,0.02)*pwfuel_all["Electricity","Propane",RGs[r]]
# all propane to oil standard
whfe[8,12:14]<-pwfuel_all["Oil","Propane",RGs[r]]
# propane standard to gas standard/prem/tankless with 85:5:10 odds
whfe[5:7,"Propane Standard"]<-c(.85,.05,.1)*pwfuel_all["Gas","Propane",RGs[r]]
# propane premium to propane premium tankless with 70:30 odds, and vice versa
whfe[13:14,"Propane Premium"]<-c(0.7,0.3)*pwfuel_all["Propane","Propane",RGs[r]]
whfe[13:14,"Propane Tankless"]<-c(0.3,0.7)*pwfuel_all["Propane","Propane",RGs[r]]
# propane prem/tankless to elec prem/tankless/HP with 50:25:25 odds
whfe[2:4,13:14]<-c(0.5,0.25,0.25)*pwfuel_all["Electricity","Propane",RGs[r]]
# assign propane premium to gas prem/tankless with 65:35 odds, and vice versa
whfe[6:7,"Propane Premium"]<-c(.65,.35)*pwfuel_all["Gas","Propane",RGs[r]]
# assign propane tankless to propane prem/tankless with 35:65 odds, and vice versa
whfe[6:7,"Propane Tankless"]<-c(.35,.65)*pwfuel_all["Gas","Propane",RGs[r]]
# check
min(colSums(whfe))
max(colSums(whfe))

# CONTINUE, before ##########
table(SF$Water.Heater.Efficiency)
table(SFwrensam$Water.Heater.Efficiency)
SFwrensam$Water.Heater.Efficiency_new<-"NA"
for (i in 1:nrow(SFwrensam)) {
  SFwrensam$Water.Heater.Efficiency_new[i]<-sample(wheff_types,1,p=whfe[,SFwrensam$Water.Heater.Efficiency[i]])
  if (!SFwrensam$Water.Heater.Efficiency_new[i]==SFwrensam$Water.Heater.Efficiency[i]) {SFwrensam$change_wren[i]<-yr} # if a renovation actually makes a change, make note of that here
}

SFwrensam$Water.Heater.Efficiency<-SFwrensam$Water.Heater.Efficiency_new
SFwrensam<-SFwrensam[,!(names(SFwrensam) %in% c("Water.Heater.Efficiency_new"))]
SF[ren_rows,]<-SFwrensam
# after
table(SF$Water.Heater.Efficiency)
table(SFwrensam$Water.Heater.Efficiency)

# now insulation
SF$pi<-0 # probability of getting a heating system renovation
iren<-pren[RGs[r],"SF","Ins"] # the renovation rate for a given region, type, system combination
iLT<-round(1/iren) # average lifetime of equipment, or period for replacements
iIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(iLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-iLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
iIC[which(iIC$Year>(full-1)&iIC$Year<(half+1)),]$Rate<-rev(seq(0,iren,length.out = iLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
iIC[iIC$Year<full,]$Rate<-iren
SF[SF$Vintage.ACS=="<1940",]$pi<-iren
SF[SF$Vintage.ACS=="1940-59",]$pi<-mean(iIC[which(iIC$Year>1939&iIC$Year<1960),]$Rate)
SF[SF$Vintage.ACS=="1960-79",]$pi<-mean(iIC[which(iIC$Year>1959&iIC$Year<1980),]$Rate)
SF[SF$Vintage.ACS=="1980-99",]$pi<-mean(iIC[which(iIC$Year>1979&iIC$Year<2000),]$Rate)
SF[SF$Vintage.ACS=="2000-09",]$pi<-mean(iIC[which(iIC$Year>1999&iIC$Year<2010),]$Rate)
SF[SF$Vintage.ACS=="2010s",]$pi<-mean(iIC[which(iIC$Year>2009),]$Rate)

numren<-round(nrow(SF)*iren) # Number of units renovated, this approach avoids the downward bias from setting ph<iren for recently built units, since iren was calculated as the stock average rate, including recent units 
if (any(SF$last_iren>full+4)) {SF[SF$last_iren>full+4,]$pi<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(SF),numren,prob=SF$pi) # which rows are the renovated ones
SFirensam<-SF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
SFirensam$last_iren<-yr
# before
table(SFirensam$Insulation.Wall,SFirensam$Geometry.Wall.Type)
table(SF$Insulation.Wall,SF$Geometry.Wall.Type)

for (i in 1:nrow(SFirensam)) {
  SFirensam$Insulation.Wall_New[i]<-sample(wins_types,1,p=pwins[,SFirensam$Insulation.Wall[i]])
  SFirensam$Insulation.Crawlspace_New[i]<-sample(crins_types,1,p=pcrins[,SFirensam$Insulation.Crawlspace[i]])
  SFirensam$Insulation.Unfinished.Basement_New[i]<-sample(ubins_types,1,p=pubins[,SFirensam$Insulation.Unfinished.Basement[i]])
  SFirensam$Insulation.Unfinished.Attic_New[i]<-sample(uains_types,1,p=puains[,SFirensam$Insulation.Unfinished.Attic[i]])
  
  if (!SFirensam$Insulation.Wall_New[i]==SFirensam$Insulation.Wall[i] | # if any of these have been changed,,
      !SFirensam$Insulation.Crawlspace_New[i]==SFirensam$Insulation.Crawlspace[i] |
      !SFirensam$Insulation.Unfinished.Attic_New[i]==SFirensam$Insulation.Unfinished.Attic[i] |
      !SFirensam$Insulation.Unfinished.Basement_New[i]==SFirensam$Insulation.Unfinished.Basement[i]) {SFirensam$change_iren[i]<-yr} # make note if the insulation actually changes
}
SFirensam$Insulation.Wall<-SFirensam$Insulation.Wall_New
SFirensam$Insulation.Crawlspace<-SFirensam$Insulation.Crawlspace_New
SFirensam$Insulation.Unfinished.Attic<-SFirensam$Insulation.Unfinished.Attic_New
SFirensam$Insulation.Unfinished.Basement <-SFirensam$Insulation.Unfinished.Basement_New

SFirensam<-SFirensam[,!(names(SFirensam) %in% c("Insulation.Wall_New","Insulation.Crawlspace_New","Insulation.Unfinished.Attic_New","Insulation.Unfinished.Basement_New"))]
SF[ren_rows,]<-SFirensam
# after
table(SFirensam$Insulation.Wall,SFirensam$Geometry.Wall.Type)
table(SF$Insulation.Wall,SF$Geometry.Wall.Type)
table(SFirensam$Insulation.Crawlspace)
table(SFirensam$Insulation.Unfinished.Attic)
table(SFirensam$Insulation.Unfinished.Basement)
# and space cooling, first do changes of cooling type 
ctr<-pctype_all[,,RGs[r]] # rate of changing between no/room/central AC cooling type
ctren_none<-sum(ctr[c(1,3),2])
# do units from none first
numren<-round(nrow(SF[SF$HVAC.Cooling.Type=="None",])*ctren_none)
ctnoneLT<-round(1/ctren_none)
ctIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(ctnoneLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-ctnoneLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
ctIC[which(ctIC$Year>(full-1)&ctIC$Year<(half+1)),]$Rate<-rev(seq(0,ctren_none,length.out = ctnoneLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
ctIC[ctIC$Year<full,]$Rate<-ctren_none
SF[SF$HVAC.Cooling.Type=="None" & SF$Vintage.ACS=="<1940",]$pctnone<-ctren_none
SF[SF$HVAC.Cooling.Type=="None" & SF$Vintage.ACS=="1940-59",]$pctnone<-mean(ctIC[which(ctIC$Year>1939&ctIC$Year<1960),]$Rate)
SF[SF$HVAC.Cooling.Type=="None" & SF$Vintage.ACS=="1960-79",]$pctnone<-mean(ctIC[which(ctIC$Year>1959&ctIC$Year<1980),]$Rate)
SF[SF$HVAC.Cooling.Type=="None" & SF$Vintage.ACS=="1980-99",]$pctnone<-mean(ctIC[which(ctIC$Year>1979&ctIC$Year<2000),]$Rate)
SF[SF$HVAC.Cooling.Type=="None" & SF$Vintage.ACS=="2000-09",]$pctnone<-mean(ctIC[which(ctIC$Year>1999&ctIC$Year<2010),]$Rate)
SF[SF$HVAC.Cooling.Type=="None" & SF$Vintage.ACS=="2010s",]$pctnone<-mean(ctIC[which(ctIC$Year>2009),]$Rate)
if (any(SF$last_ctren_none>full+4)) {SF[SF$last_ctren_none>full+4,]$pctnone<-0}

ren_rows<-sample(nrow(SF),numren,prob=SF$pctnone) # which rows are the renovated ones
SFctnonerensam<-SF[ren_rows,] # housing units to change from no AC
# indicate that these units get a renovation this year
SFctnonerensam$last_ctren_none<-yr
# before
table(SFctnonerensam$HVAC.Cooling.Type)
table(SF$HVAC.Cooling.Type)
table(SF$HVAC.Cooling.Efficiency)
ctr2<-ctr
ctr2[2,]<-0
ctr2[,1]<-0
for (i in 1:nrow(SFctnonerensam)) {
  SFctnonerensam$HVAC.Cooling.Type[i]<-sample(ACtypes,1,p=ctr2[,SFctnonerensam$HVAC.Cooling.Type[i]])
  if (SFctnonerensam$HVAC.Cooling.Type[i]=="Room AC") {SFctnonerensam$HVAC.Cooling.Efficiency[i]<-sample(c("Room AC, EER 9.8","Room AC, EER 10.7"),1)}
  if (SFctnonerensam$HVAC.Cooling.Type[i]=="Central AC") {SFctnonerensam$HVAC.Cooling.Efficiency[i]<-"AC, SEER 13"}
  SFctnonerensam$change_cren[i]<-yr # note that the cooling system has changed
}
SF[ren_rows,]<-SFctnonerensam
# after
table(SF$HVAC.Cooling.Type)
table(SF$HVAC.Cooling.Efficiency)
# now do the same for moving from room AC
ctren_room<-ctr[1,3]
numren<-round(nrow(SF[SF$HVAC.Cooling.Type=="Room AC",])*ctren_room)
ctroomLT<-round(1/ctren_room)
ctIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(ctroomLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-ctroomLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
ctIC[which(ctIC$Year>(full-1)&ctIC$Year<(half+1)),]$Rate<-rev(seq(0,ctren_room,length.out = ctroomLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
ctIC[ctIC$Year<full,]$Rate<-ctren_room
SF[SF$HVAC.Cooling.Type=="Room AC" & SF$Vintage.ACS=="<1940",]$pctroom<-ctren_room
SF[SF$HVAC.Cooling.Type=="Room AC" & SF$Vintage.ACS=="1940-59",]$pctroom<-mean(ctIC[which(ctIC$Year>1939&ctIC$Year<1960),]$Rate)
SF[SF$HVAC.Cooling.Type=="Room AC" & SF$Vintage.ACS=="1960-79",]$pctroom<-mean(ctIC[which(ctIC$Year>1959&ctIC$Year<1980),]$Rate)
SF[SF$HVAC.Cooling.Type=="Room AC" & SF$Vintage.ACS=="1980-99",]$pctroom<-mean(ctIC[which(ctIC$Year>1979&ctIC$Year<2000),]$Rate)
SF[SF$HVAC.Cooling.Type=="Room AC" & SF$Vintage.ACS=="2000-09",]$pctroom<-mean(ctIC[which(ctIC$Year>1999&ctIC$Year<2010),]$Rate)
SF[SF$HVAC.Cooling.Type=="Room AC" & SF$Vintage.ACS=="2010s",]$pctroom<-mean(ctIC[which(ctIC$Year>2009),]$Rate)
if (any(SF$last_ctren_room>full+4)) {SF[SF$last_ctren_room>full+4,]$pctroom<-0}
if (any(SF$last_ctren_none>full+4)) {SF[SF$last_ctren_none>full+4,]$pctroom<-0} # don't allows homes which just put in a room ac to change from room to central

ren_rows<-sample(nrow(SF),numren,prob=SF$pctroom) # which rows are the renovated ones
SFctroomrensam<-SF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
SFctroomrensam$last_ctren_room<-yr
# before
table(SF$HVAC.Cooling.Efficiency)
table(SF$HVAC.Cooling.Type)
for (i in 1:nrow(SFctroomrensam)) {
  SFctroomrensam$HVAC.Cooling.Type[i]<-"Central AC"
  SFctroomrensam$HVAC.Cooling.Efficiency[i]<-"AC, SEER 13"
  SFctroomrensam$change_cren[i]<-yr # note that the cooling system has changed
}
SF[ren_rows,]<-SFctroomrensam

# next implement efficiency changes in space cooling
cren<-pren[RGs[r],"SF","Cool"] # chance of changing efficiency as defined in ce, only for those with room/central AC
cLT<-round(1/cren) # average lifetime of equipment, or period for replacements
cPC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(cLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-cLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
cPC[which(cPC$Year>(full-1)&cPC$Year<(half+1)),]$Rate<-rev(seq(0,cren,length.out = cLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
cPC[cPC$Year<full,]$Rate<-cren
SF[SF$Vintage.ACS=="<1940",]$pc<-cren
SF[SF$Vintage.ACS=="1940-59",]$pc<-mean(cPC[which(cPC$Year>1939&cPC$Year<1960),]$Rate)
SF[SF$Vintage.ACS=="1960-79",]$pc<-mean(cPC[which(cPC$Year>1959&cPC$Year<1980),]$Rate)
SF[SF$Vintage.ACS=="1980-99",]$pc<-mean(cPC[which(cPC$Year>1979&cPC$Year<2000),]$Rate)
SF[SF$Vintage.ACS=="2000-09",]$pc<-mean(cPC[which(cPC$Year>1999&cPC$Year<2010),]$Rate)
SF[SF$Vintage.ACS=="2010s",]$pc<-mean(cPC[which(cPC$Year>2009),]$Rate)

numren<-round(nrow(SF)*cren) # Number of units renovated, this approach avoids the downward bias from setting ph<cren for recently built units, since cren was calculated as the stock average rate, including recent units 
if (any(SF$last_cren>full+4)) {SF[SF$last_cren>full+4,]$pc<-0} # weed out units which were renovated recently, don't let them be renovated again
# avoid renovating units which have no AC, or which changed from no AC to AC within the last lifetime
if (any(SF$last_ctren_none>full+4)) {SF[SF$last_ctren_none>full+4,]$pc<-0}
if (any(SF$last_ctren_room>full+4)) {SF[SF$last_ctren_room>full+4,]$pc<-0}

SF[SF$HVAC.Cooling.Type=="Heat Pump" | SF$HVAC.Cooling.Type=="None",]$pc<-0 # no change to units with HP or No Cooling here
# in case numren is larger than the number of units with pc>0, reduce the number of renovations to 75% of the eligible units
if (numren>dim(SF[SF$pc>0,])[1]) {numren<-round(0.75*dim(SF[SF$pc>0,])[1])}
if (numren>0) { #if statement to check if there are actually any renovations.
ren_rows<-sample(nrow(SF),numren,prob=SF$pc) # which rows are the renovated ones
SFcrensam<-SF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
SFcrensam$last_cren<-yr
# before
table(SFcrensam$HVAC.Cooling.Efficiency)
table(SF$HVAC.Cooling.Efficiency)

for (i in 1:nrow(SFcrensam)) {
  SFcrensam$HVAC.Cooling.Efficiency_New[i]<-sample(ceff_types,1,p=ce[,SFcrensam$HVAC.Cooling.Efficiency[i]]) 
  if (!SFcrensam$HVAC.Cooling.Efficiency_New[i]==SFcrensam$HVAC.Cooling.Efficiency[i]) {SFcrensam$change_cren[i]<-yr} # note that the cooling system has changed, if it actually has
}
SFcrensam$HVAC.Cooling.Efficiency<-SFcrensam$HVAC.Cooling.Efficiency_New
SFcrensam<-SFcrensam[,!(names(SFcrensam) %in% c("HVAC.Cooling.Efficiency_New"))]
SF[ren_rows,]<-SFcrensam
# after
table(SFcrensam$HVAC.Cooling.Efficiency)
table(SF$HVAC.Cooling.Efficiency)
} # Close if statement to check if there are actually any renovations.
 
# # pick out MF units
MF<-RG[substr(RG$Geometry.Building.Type.RECS,1,6)=="Multi-",]
MF$pi<-MF$ph<-MF$pw<-MF$pc<-MF$pctnone<-MF$pctroom<-0
hren<-pren[RGs[r],"MF","Heat"] # the renovation rate for a given region, type, system combination
hLT<-round(1/hren) # average lifetime of equipment, or period for replacements
hIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(hLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-hLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
hIC[which(hIC$Year>(full-1)&hIC$Year<(half+1)),]$Rate<-rev(seq(0,hren,length.out = hLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
hIC[hIC$Year<full,]$Rate<-hren
MF[MF$Vintage.ACS=="<1940",]$ph<-hren
MF[MF$Vintage.ACS=="1940-59",]$ph<-mean(hIC[which(hIC$Year>1939&hIC$Year<1960),]$Rate)
MF[MF$Vintage.ACS=="1960-79",]$ph<-mean(hIC[which(hIC$Year>1959&hIC$Year<1980),]$Rate)
MF[MF$Vintage.ACS=="1980-99",]$ph<-mean(hIC[which(hIC$Year>1979&hIC$Year<2000),]$Rate)
MF[MF$Vintage.ACS=="2000-09",]$ph<-mean(hIC[which(hIC$Year>1999&hIC$Year<2010),]$Rate)
MF[MF$Vintage.ACS=="2010s",]$ph<-mean(hIC[which(hIC$Year>2009),]$Rate)

numren<-round(nrow(MF)*hren) # Number of units renovated, this approach avoids the downward bias from setting ph<hren for recently built units, since hren was calculated as the stock average rate, including recent units 
if (any(MF$last_hren>full+4)) {MF[MF$last_hren>full+4,]$ph<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(MF),numren,prob=MF$ph) # which rows are the renovated ones
MFhrensam<-MF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MFhrensam$last_hren<-yr

table(MF$Heating.Fuel)
table(MF$HVAC.Heating.Efficiency)
table(MFhrensam$Heating.Fuel)
table(MFhrensam$HVAC.Heating.Efficiency)
MFhrensam$Heating.Fuel_Efficiency_new<-"NA"
for (i in 1:nrow(MFhrensam)) {
  MFhrensam$Heating.Fuel_Efficiency_new[i]<-sample(hfeff_types,1,p=phfe[,MFhrensam$Heating.Fuel_Efficiency[i]])
  MFhrensam$HVAC.Heating.Type.And.Fuel[i]<-sample(gsub("Option=","",rownames(htft))[3:27],1,p=htft[3:27,which(htft[1,]==sub("_.*","",MFhrensam$Heating.Fuel_Efficiency_new[i])&htft[2,]== sub(".*_","",MFhrensam$Heating.Fuel_Efficiency_new[i]))])
  if (!MFhrensam$Heating.Fuel_Efficiency_new[i]==MFhrensam$Heating.Fuel_Efficiency[i]) {MFhrensam$change_hren[i]<-yr} # if a renovation actually makes a change, make note of that here
}
MFhrensam$Heating.Fuel<-sub("_.*","",MFhrensam$Heating.Fuel_Efficiency_new)
MFhrensam$HVAC.Heating.Efficiency<-sub(".*_","",MFhrensam$Heating.Fuel_Efficiency_new)
table(MFhrensam$Heating.Fuel)
table(MFhrensam$HVAC.Heating.Efficiency)
MFhrensam$Heating.Fuel_Efficiency<-MFhrensam$Heating.Fuel_Efficiency_new
MFhrensam<-MFhrensam[,!(names(MFhrensam) %in% c("Heating.Fuel_Efficiency_new"))]
MF[ren_rows,]<-MFhrensam

# same for water heating fuel and efficiency
wren<-pren[RGs[r],"MF","Water"] # the renovation rate for a given region, type, system combination
wLT<-round(1/wren) # average lifetime of equipment, or period for replacements
wIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(wLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-wLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
wIC[which(wIC$Year>(full-1)&wIC$Year<(half+1)),]$Rate<-rev(seq(0,wren,length.out = wLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
wIC[wIC$Year<full,]$Rate<-wren
MF[MF$Vintage.ACS=="<1940",]$pw<-wren
MF[MF$Vintage.ACS=="1940-59",]$pw<-mean(wIC[which(wIC$Year>1939&wIC$Year<1960),]$Rate)
MF[MF$Vintage.ACS=="1960-79",]$pw<-mean(wIC[which(wIC$Year>1959&wIC$Year<1980),]$Rate)
MF[MF$Vintage.ACS=="1980-99",]$pw<-mean(wIC[which(wIC$Year>1979&wIC$Year<2000),]$Rate)
MF[MF$Vintage.ACS=="2000-09",]$pw<-mean(wIC[which(wIC$Year>1999&wIC$Year<2010),]$Rate)
MF[MF$Vintage.ACS=="2010s",]$pw<-mean(wIC[which(wIC$Year>2009),]$Rate)

numren<-round(nrow(MF)*wren) # Number of units renovated, this approach avoids the downward bias from setting pw<wren for recently built units, since wren was calculated as the stock average rate, including recent units 
if (any(MF$last_wren>full+4)) {MF[MF$last_wren>full+4,]$pw<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(MF),numren,prob=MF$pw) # which rows are the renovated ones
MFwrensam<-MF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MFwrensam$last_wren<-yr

# CONTINUE, before 
table(MF$Water.Heater.Efficiency)
table(MFwrensam$Water.Heater.Efficiency)
MFwrensam$Water.Heater.Efficiency_new<-"NA"
for (i in 1:nrow(MFwrensam)) {
  MFwrensam$Water.Heater.Efficiency_new[i]<-sample(wheff_types,1,p=whfe[,MFwrensam$Water.Heater.Efficiency[i]])
  if (!MFwrensam$Water.Heater.Efficiency_new[i]==MFwrensam$Water.Heater.Efficiency[i]) {MFwrensam$change_wren[i]<-yr} # if a renovation actually makes a change, make note of that here
}

MFwrensam$Water.Heater.Efficiency<-MFwrensam$Water.Heater.Efficiency_new
MFwrensam<-MFwrensam[,!(names(MFwrensam) %in% c("Water.Heater.Efficiency_new"))]
MF[ren_rows,]<-MFwrensam
# after
table(MF$Water.Heater.Efficiency)
table(MFwrensam$Water.Heater.Efficiency)

# now insulation
MF$pi<-0 # probability of getting a heating system renovation
iren<-pren[RGs[r],"MF","Ins"] # the renovation rate for a given region, type, system combination
iLT<-round(1/iren) # average lifetime of equipment, or period for replacements
iIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(iLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-iLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
iIC[which(iIC$Year>(full-1)&iIC$Year<(half+1)),]$Rate<-rev(seq(0,iren,length.out = iLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
if(iIC$Year[1]<full){iIC[iIC$Year<full,]$Rate<-iren}
MF[MF$Vintage.ACS=="<1940",]$pi<-iren
MF[MF$Vintage.ACS=="1940-59",]$pi<-mean(iIC[which(iIC$Year>1939&iIC$Year<1960),]$Rate)
MF[MF$Vintage.ACS=="1960-79",]$pi<-mean(iIC[which(iIC$Year>1959&iIC$Year<1980),]$Rate)
MF[MF$Vintage.ACS=="1980-99",]$pi<-mean(iIC[which(iIC$Year>1979&iIC$Year<2000),]$Rate)
MF[MF$Vintage.ACS=="2000-09",]$pi<-mean(iIC[which(iIC$Year>1999&iIC$Year<2010),]$Rate)
MF[MF$Vintage.ACS=="2010s",]$pi<-mean(iIC[which(iIC$Year>2009),]$Rate)

numren<-round(nrow(MF)*iren) # Number of units renovated, this approach avoids the downward bias from setting ph<iren for recently built units, since iren was calculated as the stock average rate, including recent units 
if (any(MF$last_iren>full+4)) {MF[MF$last_iren>full+4,]$pi<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(MF),numren,prob=MF$pi) # which rows are the renovated ones
MFirensam<-MF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MFirensam$last_iren<-yr
# before
table(MFirensam$Insulation.Wall,MFirensam$Geometry.Wall.Type)
table(MF$Insulation.Wall,MF$Geometry.Wall.Type)

for (i in 1:nrow(MFirensam)) {
  MFirensam$Insulation.Wall_New[i]<-sample(wins_types,1,p=pwins[,MFirensam$Insulation.Wall[i]])
  MFirensam$Insulation.Crawlspace_New[i]<-sample(crins_types,1,p=pcrins[,MFirensam$Insulation.Crawlspace[i]])
  MFirensam$Insulation.Unfinished.Basement_New[i]<-sample(ubins_types,1,p=pubins[,MFirensam$Insulation.Unfinished.Basement[i]])
  
  if (!MFirensam$Insulation.Wall_New[i]==MFirensam$Insulation.Wall[i] | # if any of these have been changed,,
      !MFirensam$Insulation.Crawlspace_New[i]==MFirensam$Insulation.Crawlspace[i] |
      !MFirensam$Insulation.Unfinished.Basement_New[i]==MFirensam$Insulation.Unfinished.Basement[i]) {MFirensam$change_iren[i]<-yr} # make note if the insulation actually changes
}
MFirensam$Insulation.Wall<-MFirensam$Insulation.Wall_New
MFirensam$Insulation.Crawlspace<-MFirensam$Insulation.Crawlspace_New
MFirensam$Insulation.Unfinished.Basement<-MFirensam$Insulation.Unfinished.Basement_New

MFirensam<-MFirensam[,!(names(MFirensam) %in% c("Insulation.Wall_New","Insulation.Crawlspace_New","Insulation.Unfinished.Basement_New"))]
MF[ren_rows,]<-MFirensam
# after
table(MFirensam$Insulation.Wall,MFirensam$Geometry.Wall.Type)
table(MF$Insulation.Wall,MF$Geometry.Wall.Type)

# and space cooling, first do changes of cooling type 
ctr<-pctype_all[,,RGs[r]] # rate of changing between no/room/central AC cooling type
ctren_none<-sum(ctr[c(1,3),2])
# do units from none first
numren<-round(nrow(MF[MF$HVAC.Cooling.Type=="None",])*ctren_none)
ctnoneLT<-round(1/ctren_none)
ctIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(ctnoneLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-ctnoneLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
ctIC[which(ctIC$Year>(full-1)&ctIC$Year<(half+1)),]$Rate<-rev(seq(0,ctren_none,length.out = ctnoneLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
ctIC[ctIC$Year<full,]$Rate<-ctren_none
MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="<1940",]$pctnone<-ctren_none
MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="1940-59",]$pctnone<-mean(ctIC[which(ctIC$Year>1939&ctIC$Year<1960),]$Rate)
MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="1960-79",]$pctnone<-mean(ctIC[which(ctIC$Year>1959&ctIC$Year<1980),]$Rate)
MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="1980-99",]$pctnone<-mean(ctIC[which(ctIC$Year>1979&ctIC$Year<2000),]$Rate)
MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="2000-09",]$pctnone<-mean(ctIC[which(ctIC$Year>1999&ctIC$Year<2010),]$Rate)
if (any(MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="2010s")) {MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="2010s",]$pctnone<-mean(ctIC[which(ctIC$Year>2009),]$Rate)}
if (any(MF$last_ctren_none>full+4)) {MF[MF$last_ctren_none>full+4,]$pctnone<-0}

ren_rows<-sample(nrow(MF),numren,prob=MF$pctnone) # which rows are the renovated ones
MFctnonerensam<-MF[ren_rows,] # housing units to change from no AC
# indicate that these units get a renovation this year
MFctnonerensam$last_ctren_none<-yr
# before
table(MFctnonerensam$HVAC.Cooling.Type)
table(MF$HVAC.Cooling.Type)
ctr2<-ctr
ctr2[2,]<-0
ctr2[,1]<-0
for (i in 1:nrow(MFctnonerensam)) {
  MFctnonerensam$HVAC.Cooling.Type[i]<-sample(ACtypes,1,p=ctr2[,MFctnonerensam$HVAC.Cooling.Type[i]])
  if (MFctnonerensam$HVAC.Cooling.Type[i]=="Room AC") {MFctnonerensam$HVAC.Cooling.Efficiency[i]<-sample(c("Room AC, EER 9.8","Room AC, EER 10.7"),1)}
  if (MFctnonerensam$HVAC.Cooling.Type[i]=="Central AC") {MFctnonerensam$HVAC.Cooling.Efficiency[i]<-"AC, SEER 13"}
  MFctnonerensam$change_cren[i]<-yr # note that the cooling system has changed
}
MF[ren_rows,]<-MFctnonerensam
# after
table(MFctnonerensam$HVAC.Cooling.Type)
table(MFctnonerensam$HVAC.Cooling.Efficiency)
# now do the same for moving from room AC
ctren_room<-ctr[1,3]
numren<-round(nrow(MF[MF$HVAC.Cooling.Type=="Room AC",])*ctren_room)
ctroomLT<-round(1/ctren_room)
ctIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(ctroomLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-ctroomLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
ctIC[which(ctIC$Year>(full-1)&ctIC$Year<(half+1)),]$Rate<-rev(seq(0,ctren_room,length.out = ctroomLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
ctIC[ctIC$Year<full,]$Rate<-ctren_room
MF[MF$HVAC.Cooling.Type=="Room AC" & MF$Vintage.ACS=="<1940",]$pctroom<-ctren_room
MF[MF$HVAC.Cooling.Type=="Room AC" & MF$Vintage.ACS=="1940-59",]$pctroom<-mean(ctIC[which(ctIC$Year>1939&ctIC$Year<1960),]$Rate)
MF[MF$HVAC.Cooling.Type=="Room AC" & MF$Vintage.ACS=="1960-79",]$pctroom<-mean(ctIC[which(ctIC$Year>1959&ctIC$Year<1980),]$Rate)
MF[MF$HVAC.Cooling.Type=="Room AC" & MF$Vintage.ACS=="1980-99",]$pctroom<-mean(ctIC[which(ctIC$Year>1979&ctIC$Year<2000),]$Rate)
MF[MF$HVAC.Cooling.Type=="Room AC" & MF$Vintage.ACS=="2000-09",]$pctroom<-mean(ctIC[which(ctIC$Year>1999&ctIC$Year<2010),]$Rate)
if (any(MF$HVAC.Cooling.Type=="Room AC" & MF$Vintage.ACS=="2010s")) {MF[MF$HVAC.Cooling.Type=="Room AC" & MF$Vintage.ACS=="2010s",]$pctroom<-mean(ctIC[which(ctIC$Year>2009),]$Rate)}
if (any(MF$last_ctren_room>full+4)) {MF[MF$last_ctren_room>full+4,]$pctroom<-0}
if (any(MF$last_ctren_none>full+4)) {MF[MF$last_ctren_none>full+4,]$pctroom<-0} # don't allows homes which just put in a room ac to change from room to central

ren_rows<-sample(nrow(MF),numren,prob=MF$pctroom) # which rows are the renovated ones
MFctroomrensam<-MF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MFctroomrensam$last_ctren_room<-yr
# before
table(MFctroomrensam$HVAC.Cooling.Type)
table(MF$HVAC.Cooling.Type)
for (i in 1:nrow(MFctroomrensam)) {
  MFctroomrensam$HVAC.Cooling.Type[i]<-"Central AC"
  MFctroomrensam$HVAC.Cooling.Efficiency[i]<-"AC, SEER 13"
  MFctroomrensam$change_cren[i]<-yr # note that the cooling system has changed
}
MF[ren_rows,]<-MFctroomrensam

# next implement efficiency changes in space cooling
cren<-pren[RGs[r],"MF","Cool"] # chance of changing efficiency as defined in ce, only for those with room/central AC
cLT<-round(1/cren) # average lifetime of equipment, or period for replacements
cPC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(cLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-cLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
cPC[which(cPC$Year>(full-1)&cPC$Year<(half+1)),]$Rate<-rev(seq(0,cren,length.out = cLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
cPC[cPC$Year<full,]$Rate<-cren
MF[MF$Vintage.ACS=="<1940",]$pc<-cren
MF[MF$Vintage.ACS=="1940-59",]$pc<-mean(cPC[which(cPC$Year>1939&cPC$Year<1960),]$Rate)
MF[MF$Vintage.ACS=="1960-79",]$pc<-mean(cPC[which(cPC$Year>1959&cPC$Year<1980),]$Rate)
MF[MF$Vintage.ACS=="1980-99",]$pc<-mean(cPC[which(cPC$Year>1979&cPC$Year<2000),]$Rate)
MF[MF$Vintage.ACS=="2000-09",]$pc<-mean(cPC[which(cPC$Year>1999&cPC$Year<2010),]$Rate)
MF[MF$Vintage.ACS=="2010s",]$pc<-mean(cPC[which(cPC$Year>2009),]$Rate)

numren<-round(nrow(MF)*cren) # Number of units renovated, this approach avoids the downward bias from setting ph<cren for recently built units, since cren was calculated as the stock average rate, including recent units 
if (any(MF$last_cren>full+4)) {MF[MF$last_cren>full+4,]$pc<-0} # weed out units which were renovated recently, don't let them be renovated again
# avoid renovating units which have no AC, or which changed from no AC to AC within the last lifetime
if (any(MF$last_ctren_none>full+4)) {MF[MF$last_ctren_none>full+4,]$pc<-0}
if (any(MF$last_ctren_room>full+4)) {MF[MF$last_ctren_room>full+4,]$pc<-0}

MF[MF$HVAC.Cooling.Type=="Heat Pump" | MF$HVAC.Cooling.Type=="None",]$pc<-0
# in case numren is larger than the number of units with pc>0, reduce the number of renovations to 75% of the eligible units
if (numren>dim(MF[MF$pc>0,])[1]) {numren<-round(0.75*dim(MF[MF$pc>0,])[1])}
if (numren>0){ # if statement to check if there are actually any renovations.
ren_rows<-sample(nrow(MF),numren,prob=MF$pc) # which rows are the renovated ones
MFcrensam<-MF[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MFcrensam$last_cren<-yr
# before
# table(MFcrensam$HVAC.Cooling.Efficiency)
# table(MF$HVAC.Cooling.Efficiency)

for (i in 1:nrow(MFcrensam)) {
  MFcrensam$HVAC.Cooling.Efficiency_New[i]<-sample(ceff_types,1,p=ce[,MFcrensam$HVAC.Cooling.Efficiency[i]]) 
  if (!MFcrensam$HVAC.Cooling.Efficiency_New[i]==MFcrensam$HVAC.Cooling.Efficiency[i]) {MFcrensam$change_cren[i]<-yr} # note that the cooling system has changed, if it actually has
}
MFcrensam$HVAC.Cooling.Efficiency<-MFcrensam$HVAC.Cooling.Efficiency_New
MFcrensam<-MFcrensam[,!(names(MFcrensam) %in% c("HVAC.Cooling.Efficiency_New"))]
MF[ren_rows,]<-MFcrensam
# after
# table(MFcrensam$HVAC.Cooling.Efficiency)
# table(MF$HVAC.Cooling.Efficiency)
}  # close if statement to check if there are actually any renovations.
# # pick out MH units
MH<-RG[substr(RG$Geometry.Building.Type.RECS,1,6)=="Mobile",]
MH$pi<-MH$ph<-MH$pw<-MH$pc<-MH$pctnone<-MH$pctroom<-0
hren<-pren[RGs[r],"MH","Heat"] # the renovation rate for a given region, type, system combination
hLT<-round(1/hren) # average lifetime of equipment, or period for replacements
hIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(hLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-hLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
hIC[which(hIC$Year>(full-1)&hIC$Year<(half+1)),]$Rate<-rev(seq(0,hren,length.out = hLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
hIC[hIC$Year<full,]$Rate<-hren
if(any(MH$Vintage.ACS=="<1940")) {MH[MH$Vintage.ACS=="<1940",]$ph<-hren}
if(any(MH$Vintage.ACS=="1940-59")) {MH[MH$Vintage.ACS=="1940-59",]$ph<-mean(hIC[which(hIC$Year>1939&hIC$Year<1960),]$Rate)}
MH[MH$Vintage.ACS=="1960-79",]$ph<-mean(hIC[which(hIC$Year>1959&hIC$Year<1980),]$Rate)
MH[MH$Vintage.ACS=="1980-99",]$ph<-mean(hIC[which(hIC$Year>1979&hIC$Year<2000),]$Rate)
MH[MH$Vintage.ACS=="2000-09",]$ph<-mean(hIC[which(hIC$Year>1999&hIC$Year<2010),]$Rate)
if(any(MH$Vintage.ACS=="2010s")) {MH[MH$Vintage.ACS=="2010s",]$ph<-mean(hIC[which(hIC$Year>2009),]$Rate)}

numren<-round(nrow(MH)*hren) # Number of units renovated, this approach avoids the downward bias from setting ph<hren for recently built units, since hren was calculated as the stock average rate, including recent units 
if (any(MH$last_hren>full+4)) {MH[MH$last_hren>full+4,]$ph<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(MH),numren,prob=MH$ph) # which rows are the renovated ones
MHhrensam<-MH[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MHhrensam$last_hren<-yr

table(MH$Heating.Fuel)
table(MH$HVAC.Heating.Efficiency)
table(MHhrensam$Heating.Fuel)
table(MHhrensam$HVAC.Heating.Efficiency)
MHhrensam$Heating.Fuel_Efficiency_new<-"NA"
for (i in 1:nrow(MHhrensam)) {
  MHhrensam$Heating.Fuel_Efficiency_new[i]<-sample(hfeff_types,1,p=phfe[,MHhrensam$Heating.Fuel_Efficiency[i]])
  MHhrensam$HVAC.Heating.Type.And.Fuel[i]<-sample(gsub("Option=","",rownames(htft))[3:27],1,p=htft[3:27,which(htft[1,]==sub("_.*","",MHhrensam$Heating.Fuel_Efficiency_new[i])&htft[2,]== sub(".*_","",MHhrensam$Heating.Fuel_Efficiency_new[i]))])
  if (!MHhrensam$Heating.Fuel_Efficiency_new[i]==MHhrensam$Heating.Fuel_Efficiency[i]) {MHhrensam$change_hren[i]<-yr} # if a renovation actually makes a change, make note of that here
}
MHhrensam$Heating.Fuel<-sub("_.*","",MHhrensam$Heating.Fuel_Efficiency_new)
MHhrensam$HVAC.Heating.Efficiency<-sub(".*_","",MHhrensam$Heating.Fuel_Efficiency_new)
table(MHhrensam$Heating.Fuel)
table(MHhrensam$HVAC.Heating.Efficiency)
MHhrensam$Heating.Fuel_Efficiency<-MHhrensam$Heating.Fuel_Efficiency_new
MHhrensam<-MHhrensam[,!(names(MHhrensam) %in% c("Heating.Fuel_Efficiency_new"))]
MH[ren_rows,]<-MHhrensam

# same for water heating fuel and efficiency
wren<-pren[RGs[r],"MH","Water"] # the renovation rate for a given region, type, system combination
wLT<-round(1/wren) # average lifetime of equipment, or period for replacements
wIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(wLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-wLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
wIC[which(wIC$Year>(full-1)&wIC$Year<(half+1)),]$Rate<-rev(seq(0,wren,length.out = wLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
wIC[wIC$Year<full,]$Rate<-wren
if(any(MH$Vintage.ACS=="<1940")) {MH[MH$Vintage.ACS=="<1940",]$pw<-wren}
if(any(MH$Vintage.ACS=="1940-59")) {MH[MH$Vintage.ACS=="1940-59",]$pw<-mean(wIC[which(wIC$Year>1939&wIC$Year<1960),]$Rate)}
MH[MH$Vintage.ACS=="1960-79",]$pw<-mean(wIC[which(wIC$Year>1959&wIC$Year<1980),]$Rate)
MH[MH$Vintage.ACS=="1980-99",]$pw<-mean(wIC[which(wIC$Year>1979&wIC$Year<2000),]$Rate)
MH[MH$Vintage.ACS=="2000-09",]$pw<-mean(wIC[which(wIC$Year>1999&wIC$Year<2010),]$Rate)
if(any(MH$Vintage.ACS=="2010s")) {MH[MH$Vintage.ACS=="2010s",]$pw<-mean(wIC[which(wIC$Year>2009),]$Rate)}

numren<-round(nrow(MH)*wren) # Number of units renovated, this approach avoids the downward bias from setting pw<wren for recently built units, since wren was calculated as the stock average rate, including recent units 
if (any(MH$last_wren>full+4)) {MH[MH$last_wren>full+4,]$pw<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(MH),numren,prob=MH$pw) # which rows are the renovated ones
MHwrensam<-MH[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MHwrensam$last_wren<-yr

# CONTINUE, before 
table(MH$Water.Heater.Efficiency)
table(MHwrensam$Water.Heater.Efficiency)
MHwrensam$Water.Heater.Efficiency_new<-"NA"
for (i in 1:nrow(MHwrensam)) {
  MHwrensam$Water.Heater.Efficiency_new[i]<-sample(wheff_types,1,p=whfe[,MHwrensam$Water.Heater.Efficiency[i]])
  if (!MHwrensam$Water.Heater.Efficiency_new[i]==MHwrensam$Water.Heater.Efficiency[i]) {MHwrensam$change_wren[i]<-yr} # if a renovation actually makes a change, make note of that here
}

MHwrensam$Water.Heater.Efficiency<-MHwrensam$Water.Heater.Efficiency_new
MHwrensam<-MHwrensam[,!(names(MHwrensam) %in% c("Water.Heater.Efficiency_new"))]
MH[ren_rows,]<-MHwrensam
# after
table(MH$Water.Heater.Efficiency)
table(MHwrensam$Water.Heater.Efficiency)

# now insulation
MH$pi<-0 # probability of getting a insulation system renovation
iren<-pren[RGs[r],"MH","Ins"] # the renovation rate for a given region, type, system combination
iLT<-round(1/iren) # average lifetime of equipment, or period for replacements
iIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(iLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-iLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
iIC[which(iIC$Year>(full-1)&iIC$Year<(half+1)),]$Rate<-rev(seq(0,iren,length.out = iLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
if(iIC$Year[1]<full){iIC[iIC$Year<full,]$Rate<-iren}
if(any(MH$Vintage.ACS=="<1940")) {MH[MH$Vintage.ACS=="<1940",]$pi<-iren}
if(any(MH$Vintage.ACS=="1940-59")) {MH[MH$Vintage.ACS=="1940-59",]$pi<-mean(iIC[which(iIC$Year>1939&iIC$Year<1960),]$Rate)}
MH[MH$Vintage.ACS=="1960-79",]$pi<-mean(iIC[which(iIC$Year>1959&iIC$Year<1980),]$Rate)
MH[MH$Vintage.ACS=="1980-99",]$pi<-mean(iIC[which(iIC$Year>1979&iIC$Year<2000),]$Rate)
MH[MH$Vintage.ACS=="2000-09",]$pi<-mean(iIC[which(iIC$Year>1999&iIC$Year<2010),]$Rate)
if(any(MH$Vintage.ACS=="2010s")) {MH[MH$Vintage.ACS=="2010s",]$pi<-mean(iIC[which(iIC$Year>2009),]$Rate)}

numren<-round(nrow(MH)*iren) # Number of units renovated, this approach avoids the downward bias from setting ph<iren for recently built units, since iren was calculated as the stock average rate, including recent units 
if (any(MH$last_iren>full+4)) {MH[MH$last_iren>full+4,]$pi<-0} # weed out units which were renovated recently, don't let them be renovated again
ren_rows<-sample(nrow(MH),numren,prob=MH$pi) # which rows are the renovated ones
MHirensam<-MH[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MHirensam$last_iren<-yr
# before
table(MHirensam$Insulation.Wall,MHirensam$Geometry.Wall.Type)
table(MH$Insulation.Wall,MH$Geometry.Wall.Type)

for (i in 1:nrow(MHirensam)) {
  MHirensam$Insulation.Wall_New[i]<-sample(wins_types,1,p=pwins[,MHirensam$Insulation.Wall[i]])
  MHirensam$Insulation.Unfinished.Attic_New[i]<-sample(uains_types,1,p=puains[,MHirensam$Insulation.Unfinished.Attic[i]])
  
  if (!MHirensam$Insulation.Wall_New[i]==MHirensam$Insulation.Wall[i] | # if any of these have been changed,,
      !MHirensam$Insulation.Unfinished.Attic_New[i]==MHirensam$Insulation.Unfinished.Attic[i]) {MHirensam$change_iren[i]<-yr} # make note if the insulation actually changes
}
MHirensam$Insulation.Wall<-MHirensam$Insulation.Wall_New
MHirensam$Insulation.Unfinished.Attic<-MHirensam$Insulation.Unfinished.Attic_New

MHirensam<-MHirensam[,!(names(MHirensam) %in% c("Insulation.Wall_New","Insulation.Unfinished.Attic_New"))]
MH[ren_rows,]<-MHirensam
# after
table(MHirensam$Insulation.Wall,MHirensam$Geometry.Wall.Type)
table(MH$Insulation.Wall,MH$Geometry.Wall.Type)

# and space cooling, first do changes of cooling type 
ctr<-pctype_all[,,RGs[r]] # rate of changing between no/room/central AC cooling type
ctren_none<-sum(ctr[c(1,3),2])
# do units from none first
numren<-round(nrow(MH[MH$HVAC.Cooling.Type=="None",])*ctren_none)
ctnoneLT<-round(1/ctren_none)
ctIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(ctnoneLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-ctnoneLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
ctIC[which(ctIC$Year>(full-1)&ctIC$Year<(half+1)),]$Rate<-rev(seq(0,ctren_none,length.out = ctnoneLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
ctIC[ctIC$Year<full,]$Rate<-ctren_none
if(any(MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="<1940")) {MH[MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="<1940",]$pctnone<-ctren_none}
if(any(MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="1940-59")) {MH[MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="1940-59",]$pctnone<-mean(ctIC[which(ctIC$Year>1939&ctIC$Year<1960),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="1960-79")) {MH[MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="1960-79",]$pctnone<-mean(ctIC[which(ctIC$Year>1959&ctIC$Year<1980),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="1980-99")) {MH[MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="1980-99",]$pctnone<-mean(ctIC[which(ctIC$Year>1979&ctIC$Year<2000),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="2000-09")) {MH[MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="2000-09",]$pctnone<-mean(ctIC[which(ctIC$Year>1999&ctIC$Year<2010),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="2010S")) {MH[MH$HVAC.Cooling.Type=="None" & MH$Vintage.ACS=="2010s",]$pctnone<-mean(ctIC[which(ctIC$Year>2009),]$Rate)}
if (any(MH$last_ctren_none>full+4)) {MH[MH$last_ctren_none>full+4,]$pctnone<-0}

# in case numren is larger than the number of units with pc>0, reduce the number of renovations to 75% of the eligible units
if (numren>dim(MH[MH$pctnone>0,])[1]) {numren<-round(0.75*dim(MH[MH$pctnone>0,])[1])}
if (numren>0) {
ren_rows<-sample(nrow(MH),numren,prob=MH$pctnone) # which rows are the renovated ones
MHctnonerensam<-MH[ren_rows,] # housing units to change from no AC
# indicate that these units get a renovation this year
MHctnonerensam$last_ctren_none<-yr
# before
table(MHctnonerensam$HVAC.Cooling.Type)
table(MH$HVAC.Cooling.Type)
ctr2<-ctr
ctr2[2,]<-0
ctr2[,1]<-0
for (i in 1:nrow(MHctnonerensam)) {
  MHctnonerensam$HVAC.Cooling.Type[i]<-sample(ACtypes,1,p=ctr2[,MHctnonerensam$HVAC.Cooling.Type[i]])
  if (MHctnonerensam$HVAC.Cooling.Type[i]=="Room AC") {MHctnonerensam$HVAC.Cooling.Efficiency[i]<-sample(c("Room AC, EER 9.8","Room AC, EER 10.7"),1)}
  if (MHctnonerensam$HVAC.Cooling.Type[i]=="Central AC") {MHctnonerensam$HVAC.Cooling.Efficiency[i]<-"AC, SEER 13"}
  MHctnonerensam$change_cren[i]<-yr # note that the cooling system has changed
}
MH[ren_rows,]<-MHctnonerensam
# after
table(MHctnonerensam$HVAC.Cooling.Type)
table(MHctnonerensam$HVAC.Cooling.Efficiency)
}
# now do the same for moving from room AC
ctren_room<-ctr[1,3]
numren<-round(nrow(MH[MH$HVAC.Cooling.Type=="Room AC",])*ctren_room)
ctroomLT<-round(1/ctren_room)
ctIC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(ctroomLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-ctroomLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
ctIC[which(ctIC$Year>(full-1)&ctIC$Year<(half+1)),]$Rate<-rev(seq(0,ctren_room,length.out = ctroomLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
ctIC[ctIC$Year<full,]$Rate<-ctren_room
if(any(MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="<1940")) {MH[MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="<1940",]$pctroom<-ctren_room}
if(any(MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="1940-59")) {MH[MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="1940-59",]$pctroom<-mean(ctIC[which(ctIC$Year>1939&ctIC$Year<1960),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="1960-79")) {MH[MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="1960-79",]$pctroom<-mean(ctIC[which(ctIC$Year>1959&ctIC$Year<1980),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="1980-99")) {MH[MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="1980-99",]$pctroom<-mean(ctIC[which(ctIC$Year>1979&ctIC$Year<2000),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="2000-09")) {MH[MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="2000-09",]$pctroom<-mean(ctIC[which(ctIC$Year>1999&ctIC$Year<2010),]$Rate)}
if(any(MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="2010s")) {MH[MH$HVAC.Cooling.Type=="Room AC" & MH$Vintage.ACS=="2010s",]$pctroom<-mean(ctIC[which(ctIC$Year>2009),]$Rate)}
if (any(MH$last_ctren_room>full+4)) {MH[MH$last_ctren_room>full+4,]$pctroom<-0}
if (any(MH$last_ctren_none>full+4)) {MH[MH$last_ctren_none>full+4,]$pctroom<-0} # don't allows homes which just put in a room ac to change from room to central

# in case numren is larger than the number of units with pc>0, reduce the number of renovations to 75% of the eligible units
if (numren>dim(MH[MH$pctroom>0,])[1]) {numren<-round(0.75*dim(MH[MH$pctroom>0,])[1])}
if (numren>0) {
ren_rows<-sample(nrow(MH),numren,prob=MH$pctroom) # which rows are the renovated ones
MHctroomrensam<-MH[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MHctroomrensam$last_ctren_room<-yr
# before
table(MHctroomrensam$HVAC.Cooling.Type)
table(MH$HVAC.Cooling.Type)
for (i in 1:nrow(MHctroomrensam)) {
  MHctroomrensam$HVAC.Cooling.Type[i]<-"Central AC"
  MHctroomrensam$HVAC.Cooling.Efficiency[i]<-"AC, SEER 13"
  MHctroomrensam$change_cren[i]<-yr # note that the cooling system has changed
}
MH[ren_rows,]<-MHctroomrensam
}
# next implement efficiency changes in space cooling
cren<-pren[RGs[r],"MH","Cool"] # chance of changing efficiency as defined in ce, only for those with room/central AC
cLT<-round(1/cren) # average lifetime of equipment, or period for replacements
cPC<-data.frame("Year"=1900:yr,"Rate"=0) # implementation curve
half<-yr-(cLT/2) # half the lifetime, after which adoption increases from zero
full<-yr-cLT # age at which adoption rate matches the full rate
# scale up linearly to full rate, after half of the expected lifetime
cPC[which(cPC$Year>(full-1)&cPC$Year<(half+1)),]$Rate<-rev(seq(0,cren,length.out = cLT/2+1))
# calculate renovation rate (probability) by each ACS cohort, based on the implementation curve
cPC[cPC$Year<full,]$Rate<-cren
if(any(MH$Vintage.ACS=="<1940")) {MH[MH$Vintage.ACS=="<1940",]$pc<-cren}
if(any(MH$Vintage.ACS=="1940-59")) {MH[MH$Vintage.ACS=="1940-59",]$pc<-mean(cPC[which(cPC$Year>1939&cPC$Year<1960),]$Rate)}
MH[MH$Vintage.ACS=="1960-79",]$pc<-mean(cPC[which(cPC$Year>1959&cPC$Year<1980),]$Rate)
MH[MH$Vintage.ACS=="1980-99",]$pc<-mean(cPC[which(cPC$Year>1979&cPC$Year<2000),]$Rate)
MH[MH$Vintage.ACS=="2000-09",]$pc<-mean(cPC[which(cPC$Year>1999&cPC$Year<2010),]$Rate)
if(any(MH$Vintage.ACS=="2010s")) {MH[MH$Vintage.ACS=="2010s",]$pc<-mean(cPC[which(cPC$Year>2009),]$Rate)}

numren<-round(nrow(MH)*cren) # Number of units renovated, this approach avoids the downward bias from setting ph<cren for recently built units, since cren was calculated as the stock average rate, including recent units 
if (any(MH$last_cren>yr-20)) {MH[MH$last_cren>yr-20,]$pc<-0} # weed out units which were renovated recently, don't let them be renovated again, make this less binding for MH, avoiding only units which were renovated in the last 20 years
# avoid renovating units which have no AC, or which changed from no AC to AC within the last lifetime
if (any(MH$last_ctren_none>yr-20)) {MH[MH$last_ctren_none>yr-20,]$pc<-0}
if (any(MH$last_ctren_room>yr-20)) {MH[MH$last_ctren_room>yr-20,]$pc<-0}

MH[MH$HVAC.Cooling.Type=="Heat Pump" | MH$HVAC.Cooling.Type=="None",]$pc<-0 # this is the killer, it gets to a point where there are only HP and None left 
# in case numren is larger than the number of units with pc>0, reduce the number of renovations to 75% of the eligible units
if (numren>dim(MH[MH$pc>0,])[1]) {numren<-round(0.75*dim(MH[MH$pc>0,])[1])}
if (numren>0){ #if statement to check if there are actually any renovations.
ren_rows<-sample(nrow(MH),numren,prob=MH$pc) # which rows are the renovated ones
MHcrensam<-MH[ren_rows,] # housing units to renovate
# indicate that these units get a renovation this year
MHcrensam$last_cren<-yr
# before

for (i in 1:nrow(MHcrensam)) {
  MHcrensam$HVAC.Cooling.Efficiency_New[i]<-sample(ceff_types,1,p=ce[,MHcrensam$HVAC.Cooling.Efficiency[i]]) 
  if (!MHcrensam$HVAC.Cooling.Efficiency_New[i]==MHcrensam$HVAC.Cooling.Efficiency[i]) {MHcrensam$change_cren[i]<-yr} # note that the cooling system has changed, if it actually has
}
MHcrensam$HVAC.Cooling.Efficiency<-MHcrensam$HVAC.Cooling.Efficiency_New
MHcrensam<-MHcrensam[,!(names(MHcrensam) %in% c("HVAC.Cooling.Efficiency_New"))]
MH[ren_rows,]<-MHcrensam
# after
# table(MHcrensam$HVAC.Cooling.Efficiency)
# table(MH$HVAC.Cooling.Efficiency)
} # end here if statement to check if there are actually any renovations.


RG_new<-bind_rows(SF,MF,MH)
RG_new<-RG_new[order(RG_new$Building),]
assign(paste(RGs[r],"_new",sep=""),RG_new)
}

rs_new<-bind_rows(NE_new,MW_new,S_new,W_new)
rs_new<-rs_new[order(rs_new$Building),]
# rs_new$unchanged<-rs_new$change_hren*rs_new$change_cren*rs_new$change_iren*rs_new$change_wren
assign(paste("rs",yr,sep="_"),rs_new)
rs<-rs_new
}

# tabulate and visualize the fuels and efficiencies over the full period ##########

# df<-as.data.frame(table(rs_2020$Heating.Fuel))
# df$Year<-2020
# hfe<-as.data.frame(table(rs_2020$Heating.Fuel_Efficiency)) # heat fuel efficiency 
# wfe<-as.data.frame(table(rs_2020$Water.Heater.Efficiency)) # water fuel efficiency 
# wfe0<-data.frame("Var1"=wheff_types,"Freq"=0)
# wfe<-left_join(wfe0,wfe,by="Var1")
# wfe[is.na(wfe)]<-0
# wfe<-wfe[,c(1,3)]
# names(wfe)[2]<-"Freq"
# ins<-as.data.frame(table(rs_2020$Insulation.Wall)) # insulation
# cte<-as.data.frame(table(rs_2020$HVAC.Cooling.Efficiency)) # cooling type efficiency
# cte0<-data.frame("Var1"=ceff_types,"Freq=0")
# cte<-left_join(cte0,cte,by="Var1")
# cte[is.na(cte)]<-0
# cte<-cte[,c(1,3)]
# names(cte)[2]<-"Freq"
# cte$Year<-wfe$Year<-ins$Year<-hfe$Year<-2020
# for (yr in 2021:2060) {
# dd<-get(paste("rs",yr,sep = "_"))
# df2<-as.data.frame(table(dd$Heating.Fuel))
# df2$Year<-yr
# df<-bind_rows(df,df2)
# 
# hfe2<-as.data.frame(table(dd$Heating.Fuel_Efficiency))
# hfe2$Year<-yr
# hfe<-bind_rows(hfe,hfe2)
# 
# wfe2<-as.data.frame(table(dd$Water.Heater.Efficiency))
# wfe2$Year<-yr
# wfe<-bind_rows(wfe,wfe2)
# 
# ins2<-as.data.frame(table(dd$Insulation.Wall))
# ins2$Year<-yr
# ins<-bind_rows(ins,ins2)
# 
# cte2<-as.data.frame(table(dd$HVAC.Cooling.Efficiency))
# cte2$Year<-yr
# cte<-bind_rows(cte,cte2)
# }
# names(df)[1]<-"HeatFuel"
# windows()
# ggplot(df,aes(x=Year,y=Freq,fill=HeatFuel))+geom_area() + scale_y_continuous(labels = scales::comma)
# ggplot(df,aes(x=Year,y=Freq,fill=HeatFuel))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw()
# ggplot(df,aes(x=Year,y=Freq/150000,group=HeatFuel))+geom_line(aes(color=HeatFuel),size=1) + scale_y_continuous(labels = scales::percent) + theme_bw() + scale_fill_brewer(palette="Paired") +
#  labs(title = "2020 housing units by main heating fuel, 2020-2060", y = "Percent of stock")
# 
# names(wfe)[1]<-"WaterFuel"
# cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(wfe$WaterFuel)))
# windows()
# ggplot(wfe,aes(x=Year,y=Freq,fill=WaterFuel))+geom_area() + scale_y_continuous(labels = scales::comma)
# ggplot(wfe,aes(x=Year,y=Freq,fill=WaterFuel))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_manual(values = cols)+
#   labs(title = "2020 housing units by main water fuel, 2020-2060", y = "Percent of stock")
# ggplot(wfe,aes(x=Year,y=Freq/150000,group=WaterFuel))+geom_line(aes(color=WaterFuel),size=1) + scale_y_continuous(labels = scales::percent) + theme_bw() + scale_fill_brewer(palette="Paired") +
#   labs(title = "2020 housing units by main water fuel, 2020-2060", y = "Percent of stock")
# 
# 
# names(hfe)[1]<-"HeatFuel_Efficiency"
# hfe$HeatFuel<-sub("_.*","",hfe$HeatFuel_Efficiency)
# hfe$HeatEfficiency<-sub(".*_","",hfe$HeatFuel_Efficiency)
# # windows()
# # ggplot(hfe,aes(x=Year,y=Freq,group=HeatFuel))+geom_line(aes(color=HeatFuel),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") #+ 
# #   # labs(title = paste("Total Multifamily Units by Cohort,",location ), y = "Total MF Units",fill="Cohort")
# # windows()
# # ggplot(hfe,aes(x=Year,y=Freq,fill=HeatFuel))+geom_area() + scale_y_continuous(labels = scales::comma)
# # ggplot(hfe,aes(x=Year,y=Freq,fill=HeatFuel))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw()
# 
# 
# hfe_el<-hfe[hfe$HeatFuel=="Electricity",]
# cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_el$HeatEfficiency)))
# windows()
# ggplot(hfe_el,aes(x=Year,y=Freq,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() +scale_fill_manual(values = cols) +
#   labs(title = "Electric heating systems by equipment type and efficiency, 2020-2060", y = "Sampled Units",caption = "Total Sample = 100,000")
#   #scale_fill_brewer(palette="Paired")
# windows()
# ggplot(hfe_el,aes(x=Year,y=Freq,group=HeatEfficiency))+geom_line(aes(color=HeatEfficiency),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() #+ scale_fill_brewer(palette="Paired")
# 
# hfe_gas<-hfe[hfe$HeatFuel=="Natural Gas",]
# cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_gas$HeatEfficiency)))
# windows()
# ggplot(hfe_gas,aes(x=Year,y=Freq,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() + scale_fill_brewer(palette="Paired") + #scale_fill_manual(values = cols) +
#   labs(title = "Gas heating systems by equipment type and efficiency, 2020-2060", y = "Sampled Units",caption = "Total Sample = 100,000")
# 
# hfe_oil<-hfe[hfe$HeatFuel=="Fuel Oil",]
# # cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_gas$HeatEfficiency)))
# windows()
# ggplot(hfe_oil,aes(x=Year,y=Freq,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() + scale_fill_brewer(palette="Paired") + #scale_fill_manual(values = cols) +
#   labs(title = "Oil heating systems by equipment type and efficiency, 2020-2060", y = "Sampled Units",caption = "Total Sample = 100,000")
# 
# windows()
# ggplot(hfe_el,aes(x=Year,y=Freq,group=HeatEfficiency))+geom_line(aes(color=HeatEfficiency),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() #+ scale_fill_brewer(palette="Paired")
# 
# 
# names(ins)[1]<-"WallInsulation"
# windows()
# ggplot(ins,aes(x=Year,y=Freq,fill=WallInsulation))+geom_area() + scale_y_continuous(labels = scales::comma)
# ggplot(ins,aes(x=Year,y=Freq,fill=WallInsulation))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") +
#   labs(title = "2020 housing units by Wall Insulation, 2020-2060", y = "Sampled Units",caption = "Total Sample = 100,000")
# ggplot(ins,aes(x=Year,y=1e-5*Freq,group=WallInsulation))+geom_line(aes(color=WallInsulation),size=1) + scale_y_continuous(labels = scales::percent) + theme_bw() + scale_fill_brewer(palette="Paired") +
#   labs(title = "2020 housing units by Wall Insulation, 2020-2060", y = "Percent of stock")
# 
# names(cte)[1]<-"AC.Type"
# windows()
# ggplot(cte,aes(x=Year,y=Freq,fill=AC.Type))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") +
#   labs(title = "2020 housing units by AC Type, 2020-2060", y = "Sampled Units",caption = "Total Sample = 100,000")
# 
# save(df,hfe,hfe_el,hfe_gas,hfe_oil,ins,cte,wfe,file = "StandEffScenarioResults2.RData")


# rs_2020$Year<-2020
# rs_2025$Year<-2025
# rs_2030$Year<-2030
# rs_2035$Year<-2035
# rs_2040$Year<-2040
# rs_2045$Year<-2045
# rs_2050$Year<-2050
# rs_2055$Year<-2055
# rs_2060$Year<-2060
rs_2020_2025<-bind_rows(rs_2020,rs_2025)
rs_2020_2025[,131:142]<-0 # remove differences in columns which don't affect actual changes. CHECK  the col numbers are correct
# These columns are: last_iren/wren/cren/hren/ctren_room,ctren_none,pctroom,pctnone,ph,pc,pw,pi.
rs_2020_2025<-distinct(rs_2020_2025)
diff_20_25<-nrow(rs_2020_2025)-nrow(rs_2020)

rs_2020_2030<-bind_rows(rs_2020_2025,rs_2030)
rs_2020_2030[,131:142]<-0 # remove differences in columns which don't affect actual changes
rs_2020_2030<-distinct(rs_2020_2030)
diff_25_30<-nrow(rs_2020_2030)-nrow(rs_2020_2025)

rs_2020_2035<-bind_rows(rs_2020_2030,rs_2035)
rs_2020_2035[,131:142]<-0 # remove differences in columns which don't affect actual changes
rs_2020_2035<-distinct(rs_2020_2035)
diff_30_35<-nrow(rs_2020_2035)-nrow(rs_2020_2030)

rs_2020_2040<-bind_rows(rs_2020_2035,rs_2040)
rs_2020_2040[,131:142]<-0 # remove differences in columns which don't affect actual changes
rs_2020_2040<-distinct(rs_2020_2040)
diff_35_40<-nrow(rs_2020_2040)-nrow(rs_2020_2035)

rs_2020_2045<-bind_rows(rs_2020_2040,rs_2045)
rs_2020_2045[,131:142]<-0 # remove differences in columns which don't affect actual changes
rs_2020_2045<-distinct(rs_2020_2045)
diff_40_45<-nrow(rs_2020_2045)-nrow(rs_2020_2040)

rs_2020_2050<-bind_rows(rs_2020_2045,rs_2050)
rs_2020_2050[,131:142]<-0 # remove differences in columns which don't affect actual changes
rs_2020_2050<-distinct(rs_2020_2050)
diff_45_50<-nrow(rs_2020_2050)-nrow(rs_2020_2045)

rs_2020_2055<-bind_rows(rs_2020_2050,rs_2055)
rs_2020_2055[,131:142]<-0 # remove differences in columns which don't affect actual changes
rs_2020_2055<-distinct(rs_2020_2055)
diff_50_55<-nrow(rs_2020_2055)-nrow(rs_2020_2050)

rs_2020_2060<-bind_rows(rs_2020_2055,rs_2060)
rs_2020_2060[,131:142]<-0 # remove differences in columns which don't affect actual changes
rs_2020_2060<-distinct(rs_2020_2060)
diff_55_60<-nrow(rs_2020_2060)-nrow(rs_2020_2055)

rs_2020_2060$Year<-0
rs_2020_2060$Year<-c(rep(2020,nrow(rs)),rep(2025,diff_20_25),rep(2030,diff_25_30),rep(2035,diff_30_35),rep(2040,diff_35_40),rep(2045,diff_40_45),rep(2050,diff_45_50),
                     rep(2055,diff_50_55),rep(2060,diff_55_60))
# save(rs_2020_2060,file="RenStandard2.RData")
# example to track individual building over the period
# b1<-rs_2020_2060[rs_2020_2060$Building==1,]
# calculation of stock, energy, and GHG from <2020 buildings over the study period ################
rs_all<-rs_2020_2060[,-c(131:142)] # remove the zeroed out unused columns
rs_all<-rs_all[order(rs_all$Building),] # order by building, this lets us see the renovation history for individual buildings
rs_all<-rs_all[,-c(3:30,47:49,52:56,58:60,63,73,77,85:109)] # remove additional columns unneeded for regression based energy estimation. 
# These obv cannot be removed for the ResStock simulations, this step should be applied after the ResStock energy simulations when I do it that way.

# add weighting factors
load("decayFactors3.RData") 
load("~/Yale Courses/Research/Final Paper/StockModelCode/ctycode.RData")
ctycode[ctycode$GeoID==35013,]$RS_ID<-"NM, Dona Ana County"
ctycode[ctycode$GeoID==22059,]$RS_ID<-"LA, La Salle Parish"
sb<-merge(sb,ctycode)
shdr<-merge(shdr,ctycode)
shmf<-merge(shmf,ctycode)
shdm<-merge(shdm,ctycode)
sbm<-melt(sb)
sbm$variable<-gsub("p19","<19",sbm$variable)
sbm$TCY<-substr(sbm$variable,4,18)
sbm$TCY<-gsub("0_","0-",sbm$TCY)
# fix/revert the <1940_
sbm$TCY<-gsub("<1940-","<1940_",sbm$TCY)
sbm<-merge(sbm,ctycode)
sbm$ctyTCY<-paste(sbm$RS_ID,sbm$TCY,sep="")
sbm<-sbm[,c("ctyTCY","value")]
names(sbm)[2]<-"wf_base"
# organize so there are eight columns, one for each future year. 
sbm$Year<-substr(sbm$ctyTCY,nchar(sbm$ctyTCY)-3,nchar(sbm$ctyTCY))
sbm$ctyTCY<-substr(sbm$ctyTCY,1,nchar(sbm$ctyTCY)-5)
sbm<-dcast(sbm,ctyTCY~Year,value.var = "wf_base")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(sbm$ctyTCY,nchar(sbm$ctyTCY)-6,nchar(sbm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
sbm<-sbm[-w,]
names(sbm)[1]<-"ctyTC"
names(sbm)[2:9]<-c("wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060")
q<-which(sbm<0,arr.ind = TRUE) # shouldn't be any negatives, but for now need to fix this 
sbm[q]<-0

shdrm<-melt(shdr)
shdrm$variable<-gsub("p19","<19",shdrm$variable)
shdrm$TCY<-substr(shdrm$variable,4,18)
shdrm$TCY<-gsub("0_","0-",shdrm$TCY)
# fix/revert the <1940_
shdrm$TCY<-gsub("<1940-","<1940_",shdrm$TCY)
shdrm<-merge(shdrm,ctycode)
shdrm$ctyTCY<-paste(shdrm$RS_ID,shdrm$TCY,sep="")
shdrm<-shdrm[,c("ctyTCY","value")]
names(shdrm)[2]<-"wf_hiDR"
# organize so there are eight columns, one for each future year. 
shdrm$Year<-substr(shdrm$ctyTCY,nchar(shdrm$ctyTCY)-3,nchar(shdrm$ctyTCY))
shdrm$ctyTCY<-substr(shdrm$ctyTCY,1,nchar(shdrm$ctyTCY)-5)
shdrm<-dcast(shdrm,ctyTCY~Year,value.var = "wf_hiDR")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(shdrm$ctyTCY,nchar(shdrm$ctyTCY)-6,nchar(shdrm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
shdrm<-shdrm[-w,]
names(shdrm)[1]<-"ctyTC"
names(shdrm)[2:9]<-c("whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060")
q<-which(shdrm<0,arr.ind = TRUE) # shouldn't be any negatives, but for now need to fix this 
shdrm[q]<-0

shmfm<-melt(shmf)
shmfm$variable<-gsub("p19","<19",shmfm$variable)
shmfm$TCY<-substr(shmfm$variable,4,18)
shmfm$TCY<-gsub("0_","0-",shmfm$TCY)
# fix/revert the <1940_
shmfm$TCY<-gsub("<1940-","<1940_",shmfm$TCY)
shmfm<-merge(shmfm,ctycode)
shmfm$ctyTCY<-paste(shmfm$RS_ID,shmfm$TCY,sep="")
shmfm<-shmfm[,c("ctyTCY","value")]
names(shmfm)[2]<-"wf_hiMF"
# organize so there are eight columns, one for each future year. 
shmfm$Year<-substr(shmfm$ctyTCY,nchar(shmfm$ctyTCY)-3,nchar(shmfm$ctyTCY))
shmfm$ctyTCY<-substr(shmfm$ctyTCY,1,nchar(shmfm$ctyTCY)-5)
shmfm<-dcast(shmfm,ctyTCY~Year,value.var = "wf_hiMF")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(shmfm$ctyTCY,nchar(shmfm$ctyTCY)-6,nchar(shmfm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
shmfm<-shmfm[-w,]
names(shmfm)[1]<-"ctyTC"
names(shmfm)[2:9]<-c("whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")
q<-which(shmfm<0,arr.ind = TRUE) # shouldn't be any negatives, but for now need to fix this 
shmfm[q]<-0

shdmm<-melt(shdm)
shdmm$variable<-gsub("p19","<19",shdmm$variable)
shdmm$TCY<-substr(shdmm$variable,4,18)
shdmm$TCY<-gsub("0_","0-",shdmm$TCY)
# fix/revert the <1940_
shdmm$TCY<-gsub("<1940-","<1940_",shdmm$TCY)
shdmm<-merge(shdmm,ctycode)
shdmm$ctyTCY<-paste(shdmm$RS_ID,shdmm$TCY,sep="")
shdmm<-shdmm[,c("ctyTCY","value")]
names(shdmm)[2]<-"wf_hiDRMF"
# organize so there are eight columns, one for each future year. 
shdmm$Year<-substr(shdmm$ctyTCY,nchar(shdmm$ctyTCY)-3,nchar(shdmm$ctyTCY))
shdmm$ctyTCY<-substr(shdmm$ctyTCY,1,nchar(shdmm$ctyTCY)-5)
shdmm<-dcast(shdmm,ctyTCY~Year,value.var = "wf_hiDRMF")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(shdmm$ctyTCY,nchar(shdmm$ctyTCY)-6,nchar(shdmm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
shdmm<-shdmm[-w,]
names(shdmm)[1]<-"ctyTC"
names(shdmm)[2:9]<-c("whiDRMF_2025","whiDRMF_2030","whiDRMF_2035","whiDRMF_2040","whiDRMF_2045","whiDRMF_2050","whiDRMF_2055","whiDRMF_2060")
q<-which(shdmm<0,arr.ind = TRUE) # shouldn't be any negatives, but for now need to fix this 
shdmm[q]<-0

rs_all$TC<-"MF"
rs_all[rs_all$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all[rs_all$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all$TC<-paste(rs_all$TC,rs_all$Vintage.ACS,sep="_")
rs_all$ctyTC<-paste(rs_all$County,rs_all$TC,sep = "")
rs_all$ctyTC<-gsub("2010s","2010-19",rs_all$ctyTC)

#add columns for adjusted weights
rs_all<-left_join(rs_all,sbm,by="ctyTC")
rs_all<-left_join(rs_all,shdrm,by="ctyTC")
rs_all<-left_join(rs_all,shmfm,by="ctyTC")
rs_all<-left_join(rs_all,shdmm,by="ctyTC")

# predefine dataframes used to store and graph results
df<-data.frame(Count=tapply(rs_2020$base_weight,rs_2020$Heating.Fuel,sum))
df$HeatFuel<-rownames(df)
rownames(df)<-1:nrow(df)
df$Year<-2020
df2020<-df

hfe<-data.frame(Count=tapply(rs_2020$base_weight,rs_2020$Heating.Fuel_Efficiency,sum))
hfe$HeatFuel_Efficiency<-rownames(hfe)
rownames(hfe)<-1:nrow(hfe)
hfe0<-data.frame(Count=0,HeatFuel_Efficiency=hfeff_types)
hfe<-left_join(hfe0,hfe,by="HeatFuel_Efficiency")
hfe[is.na(hfe)]<-0
hfe<-hfe[,c(3,2)]
names(hfe)[1]<-"Count"

wfe<-data.frame(Count=tapply(rs_2020$base_weight,rs_2020$Water.Heater.Efficiency,sum))
wfe$WaterFuel_Efficiency<-rownames(wfe)
rownames(wfe)<-1:nrow(wfe)

ins<-data.frame(Count=tapply(rs_2020$base_weight,rs_2020$Insulation.Wall,sum))
ins$WallInsulation<-rownames(ins)
rownames(ins)<-1:nrow(ins)
ins0<-data.frame(Count=0,WallInsulation=wins_types)
ins<-left_join(ins0,ins,by="WallInsulation")
ins[is.na(ins)]<-0
ins<-ins[,c(3,2)]
names(ins)[1]<-"Count"

cte<-data.frame(Count=tapply(rs_2020$base_weight,rs_2020$HVAC.Cooling.Efficiency,sum))
cte$AC.Type<-rownames(cte)
rownames(cte)<-1:nrow(cte)
cte0<-data.frame(Count=0,AC.Type=ceff_types)
cte<-left_join(cte0,cte,by="AC.Type")
cte[is.na(cte)]<-0
cte<-cte[,c(3,2)]
names(cte)[1]<-"Count"

cte$Year<-wfe$Year<-ins$Year<-hfe$Year<-2020
cte2020<-cte
ins2020<-ins
wfe2020<-wfe
hfe2020<-hfe

En<-data.frame(Energy=tapply(rs_2020$base_weight*rs_2020$Total_Energy,rs_2020$Vintage,sum))
En$Cohort<-rownames(En)
rownames(En)<-1:nrow(En)

GHG<-data.frame(GHG=tapply(rs_2020$base_weight*rs_2020$EnGHG,rs_2020$Vintage,sum))
GHG$Cohort<-rownames(GHG)
rownames(GHG)<-1:nrow(GHG)
# define GHG emissions by fuel
GHGel<-data.frame(GHG=tapply(rs_2020$base_weight*rs_2020$ElGHG,rs_2020$Vintage,sum))
GHGel$Cohort<-rownames(GHGel)
rownames(GHGel)<-1:nrow(GHGel)

GHGng<-data.frame(GHG=tapply(rs_2020$base_weight*rs_2020$NGGHG,rs_2020$Vintage,sum))
GHGng$Cohort<-rownames(GHGng)
rownames(GHGng)<-1:nrow(GHGng)

GHGfo<-data.frame(GHG=tapply(rs_2020$base_weight*rs_2020$FOGHG,rs_2020$Vintage,sum))
GHGfo$Cohort<-rownames(GHGfo)
rownames(GHGfo)<-1:nrow(GHGfo)

GHGpr<-data.frame(GHG=tapply(rs_2020$base_weight*rs_2020$PrGHG,rs_2020$Vintage,sum))
GHGpr$Cohort<-rownames(GHGpr)
rownames(GHGpr)<-1:nrow(GHGpr)

En$Year<-GHG$Year<-GHGel$Year<-GHGng$Year<-GHGfo$Year<-GHGpr$Year<-2020
En2020<-En
GHG2020<-GHG
GHGel2020<-GHGel
GHGng2020<-GHGng
GHGfo2020<-GHGfo
GHGpr2020<-GHGpr

load("EnergyLinModels.RData")
# load("GHGI_MidCase.RData")
load("GHGI_LowRECost.RData")
gicty_rto<-gicty_rto_LREC

GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)
gicty_rto[gicty_rto$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto[gicty_rto$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto<-merge(gicty_rto,ctycode_num,by.x="geoid10",by.y="GeoID") # this will remove values for the no longer existing Beford City VA (51515)
gicty_rto_2020<-gicty_rto[gicty_rto$Year %in% c(2020),] # get only the RS simulation years
gicty_rto_2025<-gicty_rto[gicty_rto$Year %in% c(2025),] # get only the RS simulation years
gicty_rto_2030<-gicty_rto[gicty_rto$Year %in% c(2030),] # get only the RS simulation years
gicty_rto_2035<-gicty_rto[gicty_rto$Year %in% c(2035),] # get only the RS simulation years
gicty_rto_2040<-gicty_rto[gicty_rto$Year %in% c(2040),] # get only the RS simulation years
gicty_rto_2045<-gicty_rto[gicty_rto$Year %in% c(2045),] # get only the RS simulation years
gicty_rto_2050<-gicty_rto[gicty_rto$Year %in% c(2050),] # get only the RS simulation years
gicty_rto_2055<-gicty_rto[gicty_rto$Year %in% c(2050),] # get only the RS simulation years
gicty_rto_2055$GHG_int<-0.96*gicty_rto_2055$GHG_int # model modest reductions in GHGI between 2050 and 2055
gicty_rto_2055$Year<-2055
gicty_rto_2060<-gicty_rto_2055
gicty_rto_2060$GHG_int<-0.96*gicty_rto_2060$GHG_int # model modest reductions in GHGI between 2055 and 2060
gicty_rto_2060$Year<-2060

stock_scen<-c("base","hiDR","hiMF","hiDRMF")
weights_scen<-c("wbase","whiDR","whiMF","whiDRMF")
for (sts in 1:4) {
  print(sts)
  df<-df2020
  hfe<-hfe2020
  wfe<-wfe2020
  cte<-cte2020
  ins<-ins2020
  En<-En2020
  GHG<-GHG2020
  GHGel<-GHGel2020
  GHGng<-GHGng2020
  GHGfo<-GHGfo2020
  GHGpr<-GHGpr2020
  for (yr in c(seq(2025,2060,5))) {
    dd<-get(paste("rs",yr,sep = "_")) # i need to have all of these saved
    dd<-dd[,-c(3:30,47:49,52:56,58:66,70:71,73,77,85:109,123,131:142)] # remove columns currently unneed
    
    dd$TC<-"MF"
    dd[dd$Geometry.Building.Type.RECS=="Single-Family Attached" | dd$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
    dd[dd$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
    dd$TC<-paste(dd$TC,dd$Vintage.ACS,sep="_")
    dd$ctyTC<-paste(dd$County,dd$TC,sep = "")
    dd$ctyTC<-gsub("2010s","2010-19",dd$ctyTC)
    if (sts == 1) { # this step will differ depending on the stock scenario
      sbmy<-sbm[,c("ctyTC",paste("wbase",yr,sep="_"))]
      dd<-left_join(dd,sbmy,by="ctyTC")
    }
    if (sts == 2) { 
      shdrmy<-shdrm[,c("ctyTC",paste("whiDR",yr,sep="_"))]
      dd<-left_join(dd, shdrmy,by="ctyTC")
    }
    if (sts == 3) { 
      shmfmy<-shmfm[,c("ctyTC",paste("whiMF",yr,sep="_"))]
      dd<-left_join(dd, shmfmy,by="ctyTC")
    }
    if (sts == 4) { 
      shdmmy<-shdmm[,c("ctyTC",paste("whiDRMF",yr,sep="_"))]
      dd<-left_join(dd, shdmmy,by="ctyTC")
    }
    dd$Elec_MJ_new<-dd$Elec_MJ
    dd$NaturalGas_MJ_new<-dd$NaturalGas_MJ
    dd$Propane_MJ_new<-dd$Propane_MJ
    dd$FuelOil_MJ_new<-dd$FuelOil_MJ
    
    h<-which(dd$change_hren>0)
    dd$hv
    # recalculate fuel consumption for those homes that had heating upgrades, in case this involved a change in heating fuel. Changed to v2 of energy models
    dd$Elec_MJ_new[h]<-round(predict(lmEL2,data.frame(Type=dd$Geometry.Building.Type.RECS[h],Vintage=dd$Vintage.LM[h],IECC_Climate_Pub=dd$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=dd$Geometry.Floor.Area[h], HeatFuel=dd$Heating.Fuel[h],
                                                      ACType=dd$HVAC.Cooling.Type.LM[h],WaterHeatFuel=dd$Water.Heater.Fuel[h], DryerFuel=dd$Clothes.Dryer.Fuel.LM[h])))
    dd$NaturalGas_MJ_new[h]<-round(predict(lmNG2,data.frame(Type=dd$Geometry.Building.Type.RECS[h],Vintage=dd$Vintage.LM[h],IECC_Climate_Pub=dd$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=dd$Geometry.Floor.Area[h], HeatFuel=dd$Heating.Fuel[h],
                                                            WaterHeatFuel=dd$Water.Heater.Fuel[h], DryerFuel=dd$Clothes.Dryer.Fuel.LM[h])))
    dd$Propane_MJ_new[h]<-round(predict(lmPr2,data.frame(Type=dd$Geometry.Building.Type.RECS[h],Vintage=dd$Vintage.LM[h],IECC_Climate_Pub=dd$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=dd$Geometry.Floor.Area[h], HeatFuel=dd$Heating.Fuel[h],
                                                         WaterHeatFuel=dd$Water.Heater.Fuel[h], DryerFuel=dd$Clothes.Dryer.Fuel.LM[h])))
    dd$FuelOil_MJ_new[h]<-round(predict(lmFO2,data.frame(Type=dd$Geometry.Building.Type.RECS[h],Vintage=dd$Vintage.LM[h],IECC_Climate_Pub=dd$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=dd$Geometry.Floor.Area[h], HeatFuel=dd$Heating.Fuel[h],
                                                         WaterHeatFuel=dd$Water.Heater.Fuel[h])))
    dd[!dd$Heating.Fuel=="Fuel Oil" & !dd$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ<-0 # turn oil to 0 if neither water or space heater is oil
    # remove any negative values created
    dd[dd$Elec_MJ_new<0,]$Elec_MJ_new<-0
    dd[dd$NaturalGas_MJ_new<0,]$NaturalGas_MJ_new<-0
    dd[dd$Propane_MJ_new<0,]$Propane_MJ_new<-0
    dd[dd$FuelOil_MJ_new<0,]$FuelOil_MJ_new<-0
    # characterization of renovations updated on Feb 7
    dd[dd$change_hren>0&dd$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]$Elec_MJ_new<-
      round(0.92*dd[dd$change_hren>0&dd$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]$Elec_MJ_new) # if a heating system involved upgrading to a (more efficient) heat pump, reduce electricity consumption by 8%
    
    dd[dd$change_hren>0&dd$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.95*dd[dd$change_hren>0&dd$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to a new gas heating system
    dd[dd$change_hren>0&dd$Heating.Fuel=="Propane",]$Propane_MJ_new<-round(0.95*dd[dd$change_hren>0&dd$Heating.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to a new propane heating system
    dd[dd$change_hren>0&dd$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.88*dd[dd$change_hren>0&dd$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to a new FO heating system
    
    dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Electricity",]$Elec_MJ_new<-round(0.98*dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Electricity",]$Elec_MJ_new) # reduction from upgrade to new elec water heating system
    dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.95*dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to new gas water heating system
    dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Propane",]$Propane_MJ_new<-round(0.95*dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to new prop water heating system
    dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.98*dd[dd$change_wren>0&dd$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to new FO water heating system
    
    dd[dd$change_iren>0&dd$Heating.Fuel=="Electricity",]$Elec_MJ_new<-round(0.98*dd[dd$change_iren>0&dd$Heating.Fuel=="Electricity",]$Elec_MJ_new) # reduction from upgrade to insulation
    dd[dd$change_iren>0&dd$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.88*dd[dd$change_iren>0&dd$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to insulation
    dd[dd$change_iren>0&dd$Heating.Fuel=="Propane",]$Propane_MJ_new<-round(0.88*dd[dd$change_iren>0&dd$Heating.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to insulation
    dd[dd$change_iren>0&dd$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.83*dd[dd$change_iren>0&dd$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to insulation
    
    
    dd$Total_Energy_new<-dd$Elec_MJ_new+dd$NaturalGas_MJ_new+dd$Propane_MJ_new+dd$FuelOil_MJ_new
    dd$Total_Energy<-dd$Elec_MJ+dd$NaturalGas_MJ+dd$Propane_MJ+dd$FuelOil_MJ
    gicty_rto_yr<-get(paste("gicty_rto",yr,sep="_"))
    gicty_rto_yr$GHG_int<-gicty_rto_yr$GHG_int/3600 # convert to kg/MJ
    names(gicty_rto_yr)[3]<-paste("GHG_int",yr,sep="_")
    dd<-merge(dd,gicty_rto_yr,by.x="County",by.y="RS_ID")
    dd<-dd[,!names(dd) %in% c("geoid10.y","Year")]
    
    dd$EnGHG_new<-(dd$NaturalGas_MJ_new*GHGI_NG)+(dd$FuelOil_MJ_new*GHGI_FO)+(dd$Propane_MJ_new*GHGI_LP)+(dd$Elec_MJ_new*dd[,paste("GHG_int",yr,sep="_")]) # household emissions in kg CO2e
    dd$ElGHG_new<-dd$Elec_MJ_new*dd[,paste("GHG_int",yr,sep="_")]
    dd$NGGHG_new<-dd$NaturalGas_MJ_new*GHGI_NG
    dd$FOGHG_new<-dd$FuelOil_MJ_new*GHGI_FO
    dd$PrGHG_new<-dd$Propane_MJ_new*GHGI_LP
    
    df2<-data.frame(Count=tapply(dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Heating.Fuel,sum))
    df2$HeatFuel<-rownames(df2)
    rownames(df2)<-1:nrow(df2)
    df2$Year<-yr
    df<-bind_rows(df,df2)
    
    hfe2<-data.frame(Count=tapply(dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Heating.Fuel_Efficiency,sum))
    hfe2$HeatFuel_Efficiency<-rownames(hfe2)
    rownames(hfe2)<-1:nrow(hfe2)
    hfe2<-left_join(hfe0,hfe2,by="HeatFuel_Efficiency")
    hfe2[is.na(hfe2)]<-0
    hfe2<-hfe2[,c(3,2)]
    names(hfe2)[1]<-"Count"
    hfe2$Year<-yr
    hfe<-bind_rows(hfe,hfe2)
    
    wfe2<-data.frame(Count=tapply(dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Water.Heater.Efficiency,sum))
    wfe2$WaterFuel_Efficiency<-rownames(wfe2)
    rownames(wfe2)<-1:nrow(wfe2)
    wfe2$Year<-yr
    wfe<-bind_rows(wfe,wfe2)
    
    ins2<-data.frame(Count=tapply(dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Insulation.Wall,sum))
    ins2$WallInsulation<-rownames(ins2)
    rownames(ins2)<-1:nrow(ins2)
    ins2$Year<-yr
    ins<-bind_rows(ins,ins2)
    
    cte2<-data.frame(Count=tapply(dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$HVAC.Cooling.Efficiency,sum)) # need to check
    cte2$AC.Type<-rownames(cte2)
    rownames(cte2)<-1:nrow(cte2)
    cte2$Year<-yr
    cte<-bind_rows(cte,cte2)
    
    En2<-data.frame(Energy=tapply(dd$Total_Energy_new*dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Vintage,sum))
    En2$Cohort<-rownames(En2)
    rownames(En2)<-1:nrow(En2)
    En2$Year<-yr
    En<-rbind(En,En2)
    
    GHG2<-data.frame(GHG=tapply(dd$EnGHG_new*dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Vintage,sum))
    GHG2$Cohort<-rownames(GHG2)
    rownames(GHG2)<-1:nrow(GHG2)
    GHG2$Year<-yr
    GHG<-rbind(GHG,GHG2)
    
    GHGel2<-data.frame(GHG=tapply(dd$ElGHG_new*dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Vintage,sum))
    GHGel2$Cohort<-rownames(GHGel2)
    rownames(GHGel2)<-1:nrow(GHGel2)
    GHGel2$Year<-yr
    GHGel<-rbind(GHGel,GHGel2)
    
    GHGng2<-data.frame(GHG=tapply(dd$NGGHG_new*dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Vintage,sum))
    GHGng2$Cohort<-rownames(GHGng2)
    rownames(GHGng2)<-1:nrow(GHGng2)
    GHGng2$Year<-yr
    GHGng<-rbind(GHGng,GHGng2)
    
    GHGfo2<-data.frame(GHG=tapply(dd$FOGHG_new*dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Vintage,sum))
    GHGfo2$Cohort<-rownames(GHGfo2)
    rownames(GHGfo2)<-1:nrow(GHGfo2)
    GHGfo2$Year<-yr
    GHGfo<-rbind(GHGfo,GHGfo2)
    
    GHGpr2<-data.frame(GHG=tapply(dd$PrGHG_new*dd$base_weight*dd[,paste(weights_scen[sts],yr,sep="_")],dd$Vintage,sum))
    GHGpr2$Cohort<-rownames(GHGpr2)
    rownames(GHGpr2)<-1:nrow(GHGpr2)
    GHGpr2$Year<-yr
    GHGpr<-rbind(GHGpr,GHGpr2)
    
  }
  assign(paste("GHG_",stock_scen[sts],sep=""),GHG)
  assign(paste("GHGel_",stock_scen[sts],sep=""),GHGel)
  assign(paste("GHGng_",stock_scen[sts],sep=""),GHGng)
  assign(paste("GHGfo_",stock_scen[sts],sep=""),GHGfo)
  assign(paste("GHGpr_",stock_scen[sts],sep=""),GHGpr)
  assign(paste("En_",stock_scen[sts],sep=""),En)
  assign(paste("df_",stock_scen[sts],sep=""),df)
  assign(paste("ins_",stock_scen[sts],sep=""),ins)
  assign(paste("wfe_",stock_scen[sts],sep=""),wfe)
  assign(paste("cte_",stock_scen[sts],sep=""),cte)
  assign(paste("hfe_",stock_scen[sts],sep = ""),cte)
}
# graph the changes
scenario_names<-c("Baseline","High Stock Turnover","High MF Population","High Stock Turnover and MF Population")
sts=1 # vary from 1 to 4
df<-get(paste("df_",stock_scen[sts],sep=""))
hfe<-get(paste("hfe_",stock_scen[sts],sep = ""))
cte<-get(paste("cte_",stock_scen[sts],sep = ""))
wfe<-get(paste("wfe_",stock_scen[sts],sep = ""))
ins<-get(paste("ins_",stock_scen[sts],sep = ""))
GHG<-get(paste("GHG_",stock_scen[sts],sep = ""))
En<-get(paste("En_",stock_scen[sts],sep = ""))

windows()
# ggplot(df,aes(x=Year,y=Count,fill=HeatFuel))+geom_area() + scale_y_continuous(labels = scales::comma)
ggplot(df,aes(x=Year,y=Count,fill=HeatFuel))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw()
ggplot(df,aes(x=Year,y=Count,group=HeatFuel))+geom_line(aes(color=HeatFuel),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") +
  labs(title = "2020 housing units by main heating fuel, 2020-2060", y = "Percent of stock")

cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(wfe$WaterFuel_Efficiency)))
windows()
# ggplot(wfe,aes(x=Year,y=Count,fill=WaterFuel_Efficiency))+geom_area() + scale_y_continuous(labels = scales::comma)
ggplot(wfe,aes(x=Year,y=1e-6*Count,fill=WaterFuel_Efficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_manual(values = cols)+
  labs(title = "Pre-2020 housing units by main water fuel, 2020-2060", y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Advanced Renovation",sep=""))
# ggplot(wfe,aes(x=Year,y=Count,group=WaterFuel_Efficiency))+geom_line(aes(color=WaterFuel_Efficiency),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") +
labs(title = "Pre-2020 housing units by main water fuel, 2020-2060", y = "Percent of stock")

hfe$HeatFuel<-sub("_.*","",hfe$HeatFuel_Efficiency)
hfe$HeatEfficiency<-sub(".*_","",hfe$HeatFuel_Efficiency)
# windows()
# ggplot(hfe,aes(x=Year,y=Freq,group=HeatFuel))+geom_line(aes(color=HeatFuel),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") #+ 
#   # labs(title = paste("Total Multifamily Units by Cohort,",location ), y = "Total MF Units",fill="Cohort")
# windows()
# ggplot(hfe,aes(x=Year,y=Freq,fill=HeatFuel))+geom_area() + scale_y_continuous(labels = scales::comma)
# ggplot(hfe,aes(x=Year,y=Freq,fill=HeatFuel))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw()


hfe_el<-hfe[hfe$HeatFuel=="Electricity",]
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_el$HeatEfficiency)))
windows()
ggplot(hfe_el,aes(x=Year,y=Count,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() +scale_fill_manual(values = cols) +
  labs(title = "Electric heating systems by equipment type and efficiency, 2020-2060", y = "Sampled Units")
#scale_fill_brewer(palette="Paired")
windows()
ggplot(hfe_el,aes(x=Year,y=Count,group=HeatEfficiency))+geom_line(aes(color=HeatEfficiency),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() #+ scale_fill_brewer(palette="Paired")

hfe_gas<-hfe[hfe$HeatFuel=="Natural Gas",]
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_gas$HeatEfficiency)))
windows()
ggplot(hfe_gas,aes(x=Year,y=Count,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() + scale_fill_brewer(palette="Paired") + #scale_fill_manual(values = cols) +
  labs(title = "Gas heating systems by equipment type and efficiency, 2020-2060", y = "Sampled Units")

hfe_oil<-hfe[hfe$HeatFuel=="Fuel Oil",]
# cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_gas$HeatEfficiency)))
windows()
ggplot(hfe_oil,aes(x=Year,y=Count,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() + scale_fill_brewer(palette="Paired") + #scale_fill_manual(values = cols) +
  labs(title = "Oil heating systems by equipment type and efficiency, 2020-2060", y = "Sampled Units")

windows()
ggplot(hfe_el,aes(x=Year,y=Count,group=HeatEfficiency))+geom_line(aes(color=HeatEfficiency),size=1) + scale_y_continuous(labels = scales::comma) + theme_bw() #+ scale_fill_brewer(palette="Paired")


windows()
# ggplot(ins,aes(x=Year,y=Count,fill=WallInsulation))+geom_area() + scale_y_continuous(labels = scales::comma)
ggplot(ins,aes(x=Year,y=1e-6*Count,fill=WallInsulation))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") +
  labs(title = "Pre-2020 housing units by Wall Insulation, 2020-2060", y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Advanced Renovation",sep=""))
# ggplot(ins,aes(x=Year,y=1e-5*Count,group=WallInsulation))+geom_line(aes(color=WallInsulation),size=1) + scale_y_continuous(labels = scales::percent) + theme_bw() + scale_fill_brewer(palette="Paired") +
# labs(title = "2020 housing units by Wall Insulation, 2020-2060", y = "Percent of stock")

windows()
ggplot(cte,aes(x=Year,y=1e-6*Count,fill=AC.Type))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_brewer(palette="Paired") +
  labs(title = "Pre-2020 housing units by AC Type, 2020-2060", y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Advanced Renovation",sep=""))

windows()
ggplot(En,aes(x=Year,y=1e-12*Energy,fill=Cohort))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) + scale_y_continuous(labels = scales::comma)+ theme_bw() +scale_fill_manual(values = cols) +
  labs(title = "Final Energy Consumption in Pre-2020 Stock by Cohort, 2020-2060", y = "EJ",subtitle = paste(scenario_names[sts], "Stock, Advanced Renovation")) + guides(fill = guide_legend(reverse = TRUE))

windows()
ggplot(GHG,aes(x=Year,y=1e-9*GHG,fill=Cohort))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) + scale_y_continuous(labels = scales::comma)+ theme_bw() + scale_fill_brewer(palette="Paired") + #scale_fill_manual(values = cols) +
  labs(title = "GHG emissions from Pre-2020 Stock by Cohort, 2020-2060", y = "Mill ton CO2-eq",subtitle = paste(scenario_names[sts], "Stock, Advanced Renovation")) + guides(fill = guide_legend(reverse = TRUE))

# save the summary results here
# use a spline to fill in the missing years
GHG_base_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHG_base$GHG,GHG_base$Year,sum))
GHG_base_p2020RR<-data.frame(with(select(GHG_base_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHG_base_p2020RR)=c("Year","GHG")

GHG_hiDR_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHG_hiDR$GHG,GHG_hiDR$Year,sum))
GHG_hiDR_p2020RR<-data.frame(with(select(GHG_hiDR_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHG_hiDR_p2020RR)=c("Year","GHG")

GHG_hiMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHG_hiMF$GHG,GHG_hiMF$Year,sum))
GHG_hiMF_p2020RR<-data.frame(with(select(GHG_hiMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHG_hiMF_p2020RR)=c("Year","GHG")

GHG_hiDRMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHG_hiDRMF$GHG,GHG_hiDRMF$Year,sum))
GHG_hiDRMF_p2020RR<-data.frame(with(select(GHG_hiDRMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHG_hiDRMF_p2020RR)=c("Year","GHG")

GHGel_base_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGel_base$GHG,GHGel_base$Year,sum))
GHGel_base_p2020RR<-data.frame(with(select(GHGel_base_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGel_base_p2020RR)=c("Year","GHG")

GHGel_hiDR_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGel_hiDR$GHG,GHGel_hiDR$Year,sum))
GHGel_hiDR_p2020RR<-data.frame(with(select(GHGel_hiDR_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGel_hiDR_p2020RR)=c("Year","GHG")

GHGel_hiMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGel_hiMF$GHG,GHGel_hiMF$Year,sum))
GHGel_hiMF_p2020RR<-data.frame(with(select(GHGel_hiMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGel_hiMF_p2020RR)=c("Year","GHG")

GHGel_hiDRMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGel_hiDRMF$GHG,GHGel_hiDRMF$Year,sum))
GHGel_hiDRMF_p2020RR<-data.frame(with(select(GHGel_hiDRMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGel_hiDRMF_p2020RR)=c("Year","GHG")

GHGng_base_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGng_base$GHG,GHGng_base$Year,sum))
GHGng_base_p2020RR<-data.frame(with(select(GHGng_base_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGng_base_p2020RR)=c("Year","GHG")

GHGng_hiDR_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGng_hiDR$GHG,GHGng_hiDR$Year,sum))
GHGng_hiDR_p2020RR<-data.frame(with(select(GHGng_hiDR_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGng_hiDR_p2020RR)=c("Year","GHG")

GHGng_hiMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGng_hiMF$GHG,GHGng_hiMF$Year,sum))
GHGng_hiMF_p2020RR<-data.frame(with(select(GHGng_hiMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGng_hiMF_p2020RR)=c("Year","GHG")

GHGng_hiDRMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGng_hiDRMF$GHG,GHGng_hiDRMF$Year,sum))
GHGng_hiDRMF_p2020RR<-data.frame(with(select(GHGng_hiDRMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGng_hiDRMF_p2020RR)=c("Year","GHG")

GHGfo_base_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGfo_base$GHG,GHGfo_base$Year,sum))
GHGfo_base_p2020RR<-data.frame(with(select(GHGfo_base_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGfo_base_p2020RR)=c("Year","GHG")

GHGfo_hiDR_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGfo_hiDR$GHG,GHGfo_hiDR$Year,sum))
GHGfo_hiDR_p2020RR<-data.frame(with(select(GHGfo_hiDR_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGfo_hiDR_p2020RR)=c("Year","GHG")

GHGfo_hiMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGfo_hiMF$GHG,GHGfo_hiMF$Year,sum))
GHGfo_hiMF_p2020RR<-data.frame(with(select(GHGfo_hiMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGfo_hiMF_p2020RR)=c("Year","GHG")

GHGfo_hiDRMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGfo_hiDRMF$GHG,GHGfo_hiDRMF$Year,sum))
GHGfo_hiDRMF_p2020RR<-data.frame(with(select(GHGfo_hiDRMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGfo_hiDRMF_p2020RR)=c("Year","GHG")

GHGpr_base_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGpr_base$GHG,GHGpr_base$Year,sum))
GHGpr_base_p2020RR<-data.frame(with(select(GHGpr_base_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGpr_base_p2020RR)=c("Year","GHG")

GHGpr_hiDR_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGpr_hiDR$GHG,GHGpr_hiDR$Year,sum))
GHGpr_hiDR_p2020RR<-data.frame(with(select(GHGpr_hiDR_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGpr_hiDR_p2020RR)=c("Year","GHG")

GHGpr_hiMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGpr_hiMF$GHG,GHGpr_hiMF$Year,sum))
GHGpr_hiMF_p2020RR<-data.frame(with(select(GHGpr_hiMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGpr_hiMF_p2020RR)=c("Year","GHG")

GHGpr_hiDRMF_annRR<-data.frame(Year=seq(2020,2060,5),GHG=tapply(GHGpr_hiDRMF$GHG,GHGpr_hiDRMF$Year,sum))
GHGpr_hiDRMF_p2020RR<-data.frame(with(select(GHGpr_hiDRMF_annRR,Year,GHG),spline(Year,GHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGpr_hiDRMF_p2020RR)=c("Year","GHG")

E_base_annRR<-data.frame(Year=seq(2020,2060,5),En=tapply(En_base$Energy,En_base$Year,sum))
E_base_p2020RR<-data.frame(with(select(E_base_annRR,Year,En),spline(Year,En,xout = 2020:2060)),method="spline()")[,1:2]
names(E_base_p2020RR)=c("Year","Energy")

E_hiDR_annRR<-data.frame(Year=seq(2020,2060,5),En=tapply(En_hiDR$Energy,En_hiDR$Year,sum))
E_hiDR_p2020RR<-data.frame(with(select(E_hiDR_annRR,Year,En),spline(Year,En,xout = 2020:2060)),method="spline()")[,1:2]
names(E_hiDR_p2020RR)=c("Year","Energy")

E_hiMF_annRR<-data.frame(Year=seq(2020,2060,5),En=tapply(En_hiMF$Energy,En_hiMF$Year,sum))
E_hiMF_p2020RR<-data.frame(with(select(E_hiMF_annRR,Year,En),spline(Year,En,xout = 2020:2060)),method="spline()")[,1:2]
names(E_hiMF_p2020RR)=c("Year","Energy")

E_hiDRMF_annRR<-data.frame(Year=seq(2020,2060,5),En=tapply(En_hiDRMF$Energy,En_hiDRMF$Year,sum))
E_hiDRMF_p2020RR<-data.frame(with(select(E_hiDRMF_annRR,Year,En),spline(Year,En,xout = 2020:2060)),method="spline()")[,1:2]
names(E_hiDRMF_p2020RR)=c("Year","Energy")

# save(GHG_base_p2020RR,GHG_hiDR_p2020RR,GHG_hiMF_p2020RR,GHG_hiDRMF_p2020RR,
#      GHGel_base_p2020RR,GHGel_hiDR_p2020RR,GHGel_hiMF_p2020RR,GHGel_hiDRMF_p2020RR,
#      GHGng_base_p2020RR,GHGng_hiDR_p2020RR,GHGng_hiMF_p2020RR,GHGng_hiDRMF_p2020RR,
#      GHGfo_base_p2020RR,GHGfo_hiDR_p2020RR,GHGfo_hiMF_p2020RR,GHGfo_hiDRMF_p2020RR,
#      GHGpr_base_p2020RR,GHGpr_hiDR_p2020RR,GHGpr_hiMF_p2020RR,GHGpr_hiDRMF_p2020RR,
#      E_base_p2020RR,E_hiDR_p2020RR,E_hiMF_p2020RR,E_hiDRMF_p2020RR,
#      df_base,df_hiDR,df_hiMF,df_hiDRMF,file = "EG_RegRen_Summary3.RData")

save(GHG_base_p2020RR,GHG_hiDR_p2020RR,GHG_hiMF_p2020RR,GHG_hiDRMF_p2020RR,
     GHGel_base_p2020RR,GHGel_hiDR_p2020RR,GHGel_hiMF_p2020RR,GHGel_hiDRMF_p2020RR,
     GHGng_base_p2020RR,GHGng_hiDR_p2020RR,GHGng_hiMF_p2020RR,GHGng_hiDRMF_p2020RR,
     GHGfo_base_p2020RR,GHGfo_hiDR_p2020RR,GHGfo_hiMF_p2020RR,GHGfo_hiDRMF_p2020RR,
     GHGpr_base_p2020RR,GHGpr_hiDR_p2020RR,GHGpr_hiMF_p2020RR,GHGpr_hiDRMF_p2020RR,
     E_base_p2020RR,E_hiDR_p2020RR,E_hiMF_p2020RR,E_hiDRMF_p2020RR,
     df_base,df_hiDR,df_hiMF,df_hiDRMF,file = "EG_RegRen_Summary_LREC3.RData")
