## modelling of efficiency and technology upgrade scenarios to existing pre-2020 units, under the Regular Renovation scenario

rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console

# Last Update Peter Berrill April 30 2022

# Purpose: This script takes the building characteristics of the housing stock existing in 2020 and applies equipment and insulation upgrades in line with the assumptions of the Regular Renovation scenario

# Inputs: - RenovationStats_new.RData, probabilities of renovation characteristics by renovation type and Census Region and House Type (3), extracted from AHS surveys
#         - rencombs.RData, probabilistic pre/post renovation technology/efficiency combinations       
#         - bs2020_180k.csv, 180,000 size sample (buildstock.csv file) descrbining 2020 housing stock
#         - decayFactorsRen.RData, stock decay factors showing decay of <2020 housing stock to 2060, by county, house type (3), and cohort (Vintage ACS)

# Outputs:- Intermediate_results/RenStandard.RData, projection of the <2020 housing stock to 2060 including all characteristics changes due to renovations
#         - Intermediate_results/RegRenSummary.RData, summary of changes in <2020 housing stock 2020-2060 by different equipment/efficiency characteristics and total stock numbers

library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(readr)
library(reshape2)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts")

load("../ExtData/RenovationStats_new.RData") # produced by script AHS_new_ren2.R
load('../Intermediate_results/rencombs.RData') # Lists of possible heat fuel/efficiencies, water heat fuel/efficiencies, cooling efficiencies, insulation types
rs<-read.csv("../scen_bscsv/bs2020_180k.csv") # load sample of 2020 housing stock
nms<-names(rs) # see which columns can be removed, none until after the RS simulations have been done

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
write.csv(pfuel_all,"../SI_Tables/pfuel_RR.csv")
# define the matrix for wall insulation switching. 
#wins_types pre-loaded in rencombs
pwins<-matrix(0,length(wins_types),length(wins_types))
colnames(pwins)<-rownames(pwins)<-wins_types
# probability matrices are organised by post renovation level (rows) and pre renovation level (cols)
# Define that insulation switches 50:50 to levels 1:2 levels higher, unless on the second-to-top or top level, in which they can only go 1 or 0 levels higher
# brick and concrete walls
pwins[1:4,1]<-c(0.5,0,0.25,0.25) # it's difficult to insulate a brick wall, so in 50% of cases no change will be made to this wall type
pwins[3:4,2]<-0.5
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
# again define switching 50:50 up 1/2 levels where possible
pcrins[2:3,1]<-0.5
pcrins[3,2:3]<-1
pcrins[4,4]<-1 # None remains None (no crawlspace)
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

rs$base_weight<-122516868/nrow(rs) # total occupied units in 2020 excluding HI and AK (see InitStock20 dataframe), divided by sample size. Tot occ units in all states in 2020 is 123260336, in all states excl. AK & HI is 122516868
rs_2020<-rs
# define regions and types
Regions<-c("Northeast","Midwest","South","West")
RGs<-c("NE","MW","S","W")

# loop to implement renovations
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
      phfe[rc+1:2,rc]<-pfuel_all["Electricity HP","Electricity HP",RGs[r]]*0.5 # multiply the chance of remaining with a heat pump by 0.5 as we split this into two efficiency levels
    }
    # assign the two most efficient ASHPs to the most efficient ASHP
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
    
    SFwrensam$Water.Heater.Efficiency_new<-"NA"
    for (i in 1:nrow(SFwrensam)) {
      SFwrensam$Water.Heater.Efficiency_new[i]<-sample(wheff_types,1,p=whfe[,SFwrensam$Water.Heater.Efficiency[i]])
      if (!SFwrensam$Water.Heater.Efficiency_new[i]==SFwrensam$Water.Heater.Efficiency[i]) {SFwrensam$change_wren[i]<-yr} # if a renovation actually makes a change, make note of that here
    }
    
    SFwrensam$Water.Heater.Efficiency<-SFwrensam$Water.Heater.Efficiency_new
    SFwrensam<-SFwrensam[,!(names(SFwrensam) %in% c("Water.Heater.Efficiency_new"))]
    SF[ren_rows,]<-SFwrensam
    
    # now insulation
    SF$pi<-0 # probability of getting an insulation system renovation
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
    
    for (i in 1:nrow(SFirensam)) {
      SFirensam$Insulation.Wall_New[i]<-sample(wins_types,1,p=pwins[,SFirensam$Insulation.Wall[i]])
      SFirensam$Insulation.Crawlspace_New[i]<-sample(crins_types,1,p=pcrins[,SFirensam$Insulation.Crawlspace[i]])
      SFirensam$Insulation.Unfinished.Basement_New[i]<-sample(ubins_types,1,p=pubins[,SFirensam$Insulation.Unfinished.Basement[i]])
      SFirensam$Insulation.Unfinished.Attic_New[i]<-sample(uains_types,1,p=puains[,SFirensam$Insulation.Unfinished.Attic[i]])
      SFirensam$Infiltration_New[i]<-sample(inf_types,1,p=pinf[,SFirensam$Infiltration[i]])
      
      if (!SFirensam$Insulation.Wall_New[i]==SFirensam$Insulation.Wall[i] | # if any of these have been changed,,
          !SFirensam$Insulation.Crawlspace_New[i]==SFirensam$Insulation.Crawlspace[i] |
          !SFirensam$Insulation.Unfinished.Attic_New[i]==SFirensam$Insulation.Unfinished.Attic[i] |
          !SFirensam$Insulation.Unfinished.Basement_New[i]==SFirensam$Insulation.Unfinished.Basement[i] |
          !SFirensam$Infiltration_New[i]==SFirensam$Infiltration[i]) {SFirensam$change_iren[i]<-yr} # make note if the insulation/infiltration actually changes
    }
    SFirensam$Insulation.Wall<-SFirensam$Insulation.Wall_New
    SFirensam$Insulation.Crawlspace<-SFirensam$Insulation.Crawlspace_New
    SFirensam$Insulation.Unfinished.Attic<-SFirensam$Insulation.Unfinished.Attic_New
    SFirensam$Insulation.Unfinished.Basement <-SFirensam$Insulation.Unfinished.Basement_New
    SFirensam$Infiltration<-SFirensam$Infiltration_New
    
    SFirensam<-SFirensam[,!(names(SFirensam) %in% c("Insulation.Wall_New","Insulation.Crawlspace_New","Insulation.Unfinished.Attic_New","Insulation.Unfinished.Basement_New","Infiltration_New"))]
    SF[ren_rows,]<-SFirensam
    
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
    
    MFwrensam$Water.Heater.Efficiency_new<-"NA"
    for (i in 1:nrow(MFwrensam)) {
      MFwrensam$Water.Heater.Efficiency_new[i]<-sample(wheff_types,1,p=whfe[,MFwrensam$Water.Heater.Efficiency[i]])
      if (!MFwrensam$Water.Heater.Efficiency_new[i]==MFwrensam$Water.Heater.Efficiency[i]) {MFwrensam$change_wren[i]<-yr} # if a renovation actually makes a change, make note of that here
    }
    
    MFwrensam$Water.Heater.Efficiency<-MFwrensam$Water.Heater.Efficiency_new
    MFwrensam<-MFwrensam[,!(names(MFwrensam) %in% c("Water.Heater.Efficiency_new"))]
    MF[ren_rows,]<-MFwrensam
    
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
    
    for (i in 1:nrow(MFirensam)) {
      MFirensam$Insulation.Wall_New[i]<-sample(wins_types,1,p=pwins[,MFirensam$Insulation.Wall[i]])
      MFirensam$Insulation.Crawlspace_New[i]<-sample(crins_types,1,p=pcrins[,MFirensam$Insulation.Crawlspace[i]])
      MFirensam$Insulation.Unfinished.Basement_New[i]<-sample(ubins_types,1,p=pubins[,MFirensam$Insulation.Unfinished.Basement[i]])
      MFirensam$Infiltration_New[i]<-sample(inf_types,1,p=pinf[,MFirensam$Infiltration[i]])
      
      if (!MFirensam$Insulation.Wall_New[i]==MFirensam$Insulation.Wall[i] | # if any of these have been changed,,
          !MFirensam$Insulation.Crawlspace_New[i]==MFirensam$Insulation.Crawlspace[i] |
          !MFirensam$Insulation.Unfinished.Basement_New[i]==MFirensam$Insulation.Unfinished.Basement[i] |
          !MFirensam$Infiltration_New[i]==MFirensam$Infiltration[i]) {MFirensam$change_iren[i]<-yr} # make note if the insulation actually changes
    }
    MFirensam$Insulation.Wall<-MFirensam$Insulation.Wall_New
    MFirensam$Insulation.Crawlspace<-MFirensam$Insulation.Crawlspace_New
    MFirensam$Insulation.Unfinished.Basement<-MFirensam$Insulation.Unfinished.Basement_New
    MFirensam$Infiltration<-MFirensam$Infiltration_New
    
    MFirensam<-MFirensam[,!(names(MFirensam) %in% c("Insulation.Wall_New","Insulation.Crawlspace_New","Insulation.Unfinished.Basement_New","Infiltration_New"))]
    MF[ren_rows,]<-MFirensam
    
    # and space cooling, first do changes of cooling type 
    ctr<-pctype_all[,,RGs[r]] # (cooling type rate) rate of changing between no/room/central AC cooling type
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
    if (any(MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="2000-09")) {MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="2000-09",]$pctnone<-mean(ctIC[which(ctIC$Year>1999&ctIC$Year<2010),]$Rate)}
    if (any(MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="2010s")) {MF[MF$HVAC.Cooling.Type=="None" & MF$Vintage.ACS=="2010s",]$pctnone<-mean(ctIC[which(ctIC$Year>2009),]$Rate)}
    if (any(MF$last_ctren_none>full+4)) {MF[MF$last_ctren_none>full+4,]$pctnone<-0}
    
    ren_rows<-sample(nrow(MF),numren,prob=MF$pctnone) # which rows are the renovated ones
    MFctnonerensam<-MF[ren_rows,] # housing units to change from no AC
    # indicate that these units get a renovation this year
    MFctnonerensam$last_ctren_none<-yr

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
      
      for (i in 1:nrow(MFcrensam)) {
        MFcrensam$HVAC.Cooling.Efficiency_New[i]<-sample(ceff_types,1,p=ce[,MFcrensam$HVAC.Cooling.Efficiency[i]]) 
        if (!MFcrensam$HVAC.Cooling.Efficiency_New[i]==MFcrensam$HVAC.Cooling.Efficiency[i]) {MFcrensam$change_cren[i]<-yr} # note that the cooling system has changed, if it actually has
      }
      MFcrensam$HVAC.Cooling.Efficiency<-MFcrensam$HVAC.Cooling.Efficiency_New
      MFcrensam<-MFcrensam[,!(names(MFcrensam) %in% c("HVAC.Cooling.Efficiency_New"))]
      MF[ren_rows,]<-MFcrensam
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
    
    MHhrensam$Heating.Fuel_Efficiency_new<-"NA"
    for (i in 1:nrow(MHhrensam)) {
      MHhrensam$Heating.Fuel_Efficiency_new[i]<-sample(hfeff_types,1,p=phfe[,MHhrensam$Heating.Fuel_Efficiency[i]])
      MHhrensam$HVAC.Heating.Type.And.Fuel[i]<-sample(gsub("Option=","",rownames(htft))[3:27],1,p=htft[3:27,which(htft[1,]==sub("_.*","",MHhrensam$Heating.Fuel_Efficiency_new[i])&htft[2,]== sub(".*_","",MHhrensam$Heating.Fuel_Efficiency_new[i]))])
      if (!MHhrensam$Heating.Fuel_Efficiency_new[i]==MHhrensam$Heating.Fuel_Efficiency[i]) {MHhrensam$change_hren[i]<-yr} # if a renovation actually makes a change, make note of that here
    }
    MHhrensam$Heating.Fuel<-sub("_.*","",MHhrensam$Heating.Fuel_Efficiency_new)
    MHhrensam$HVAC.Heating.Efficiency<-sub(".*_","",MHhrensam$Heating.Fuel_Efficiency_new)

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
    
    MHwrensam$Water.Heater.Efficiency_new<-"NA"
    for (i in 1:nrow(MHwrensam)) {
      MHwrensam$Water.Heater.Efficiency_new[i]<-sample(wheff_types,1,p=whfe[,MHwrensam$Water.Heater.Efficiency[i]])
      if (!MHwrensam$Water.Heater.Efficiency_new[i]==MHwrensam$Water.Heater.Efficiency[i]) {MHwrensam$change_wren[i]<-yr} # if a renovation actually makes a change, make note of that here
    }
    
    MHwrensam$Water.Heater.Efficiency<-MHwrensam$Water.Heater.Efficiency_new
    MHwrensam<-MHwrensam[,!(names(MHwrensam) %in% c("Water.Heater.Efficiency_new"))]
    MH[ren_rows,]<-MHwrensam
    
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
    
    for (i in 1:nrow(MHirensam)) {
      MHirensam$Insulation.Wall_New[i]<-sample(wins_types,1,p=pwins[,MHirensam$Insulation.Wall[i]])
      MHirensam$Insulation.Unfinished.Attic_New[i]<-sample(uains_types,1,p=puains[,MHirensam$Insulation.Unfinished.Attic[i]])
      MHirensam$Infiltration_New[i]<-sample(inf_types,1,p=pinf[,MHirensam$Infiltration[i]])
      
      if (!MHirensam$Insulation.Wall_New[i]==MHirensam$Insulation.Wall[i] | # if any of these have been changed,,
          !MHirensam$Insulation.Unfinished.Attic_New[i]==MHirensam$Insulation.Unfinished.Attic[i] |
          !MHirensam$Infiltration_New[i]==MHirensam$Infiltration[i]) {MHirensam$change_iren[i]<-yr} # make note if the insulation actually changes
    }
    MHirensam$Insulation.Wall<-MHirensam$Insulation.Wall_New
    MHirensam$Insulation.Unfinished.Attic<-MHirensam$Insulation.Unfinished.Attic_New
    MHirensam$Infiltration<-MHirensam$Infiltration_New
    
    MHirensam<-MHirensam[,!(names(MHirensam) %in% c("Insulation.Wall_New","Insulation.Unfinished.Attic_New","Infiltration_New"))]
    MH[ren_rows,]<-MHirensam
    
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
    } # end here if statement to check if there are actually any renovations.
    
    RG_new<-bind_rows(SF,MF,MH)
    RG_new<-RG_new[order(RG_new$Building),]
    assign(paste(RGs[r],"_new",sep=""),RG_new)
  }
  
  rs_new<-bind_rows(NE_new,MW_new,S_new,W_new)
  rs_new<-rs_new[order(rs_new$Building),]
  assign(paste("rs",yr,sep="_"),rs_new)
  rs<-rs_new
}

# tabulate and visualize the fuels and efficiencies over the full period ##########

rs_2020_2025<-bind_rows(rs_2020,rs_2025)
# remove differences in columns which don't affect actual changes. CHECK  the col numbers are correct
# These columns are: last_iren/wren/cren/hren/ctren_room,ctren_none,pctroom,pctnone,ph,pc,pw,pi.
rs_2020_2025<-rs_2020_2025[,-c(115:126)]
rs_2020_2025<-distinct(rs_2020_2025)
diff_20_25<-nrow(rs_2020_2025)-nrow(rs_2020)

rs_2020_2030<-bind_rows(rs_2020_2025,rs_2030[,-c(115:126)])
rs_2020_2030<-distinct(rs_2020_2030)
diff_25_30<-nrow(rs_2020_2030)-nrow(rs_2020_2025)

rs_2020_2035<-bind_rows(rs_2020_2030,rs_2035[,-c(115:126)])
rs_2020_2035<-distinct(rs_2020_2035)
diff_30_35<-nrow(rs_2020_2035)-nrow(rs_2020_2030)

rs_2020_2040<-bind_rows(rs_2020_2035,rs_2040[,-c(115:126)])
rs_2020_2040<-distinct(rs_2020_2040)
diff_35_40<-nrow(rs_2020_2040)-nrow(rs_2020_2035)

rs_2020_2045<-bind_rows(rs_2020_2040,rs_2045[,-c(115:126)])
rs_2020_2045<-distinct(rs_2020_2045)
diff_40_45<-nrow(rs_2020_2045)-nrow(rs_2020_2040)

rs_2020_2050<-bind_rows(rs_2020_2045,rs_2050[,-c(115:126)])
rs_2020_2050<-distinct(rs_2020_2050)
diff_45_50<-nrow(rs_2020_2050)-nrow(rs_2020_2045)

rs_2020_2055<-bind_rows(rs_2020_2050,rs_2055[,-c(115:126)])
rs_2020_2055<-distinct(rs_2020_2055)
diff_50_55<-nrow(rs_2020_2055)-nrow(rs_2020_2050)

rs_2020_2060<-bind_rows(rs_2020_2055,rs_2060[,-c(115:126)])
rs_2020_2060<-distinct(rs_2020_2060)
diff_55_60<-nrow(rs_2020_2060)-nrow(rs_2020_2055)

rs_2020_2060$Year<-0
rs_2020_2060$Year<-c(rep(2020,nrow(rs)),rep(2025,diff_20_25),rep(2030,diff_25_30),rep(2035,diff_30_35),rep(2040,diff_35_40),rep(2045,diff_40_45),rep(2050,diff_45_50),
                     rep(2055,diff_50_55),rep(2060,diff_55_60))
save(rs_2020_2060,file="../Intermediate_results/RenStandard.RData")

# summarize and visualize stock characteristic changes #########
load('../Intermediate_results/decayFactorsRen.RData')

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
# cooling type and efficiency
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

stock_scen<-c("base","hiDR","hiMF","hiDRMF")
weights_scen<-c("wbase","whiDR","whiMF","whiDRMF")
for (sts in 1:4) {
  print(sts)
  df<-df2020
  hfe<-hfe2020
  wfe<-wfe2020
  cte<-cte2020
  ins<-ins2020
  for (yr in c(seq(2025,2060,5))) {
    dd<-get(paste("rs",yr,sep = "_")) # need to have all of these saved
    
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
  }
  
  assign(paste("df_",stock_scen[sts],sep=""),df)
  assign(paste("ins_",stock_scen[sts],sep=""),ins)
  assign(paste("wfe_",stock_scen[sts],sep=""),wfe)
  assign(paste("cte_",stock_scen[sts],sep=""),cte)
  assign(paste("hfe_",stock_scen[sts],sep = ""),hfe)
}

# graph the changes
scenario_names<-c("Baseline","High Turnover","High MF")
sts=1 # vary from 1 to 3
df<-get(paste("df_",stock_scen[sts],sep=""))
hfe<-get(paste("hfe_",stock_scen[sts],sep = ""))
cte<-get(paste("cte_",stock_scen[sts],sep = ""))
wfe<-get(paste("wfe_",stock_scen[sts],sep = ""))
ins<-get(paste("ins_",stock_scen[sts],sep = ""))

windows(width=6.5,height=5.5)
ggplot(df,aes(x=Year,y=1e-6*Count,fill=HeatFuel))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + 
  labs(title = "Pre-2020 housing units by main heat fuel, 2020-2060", y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Regular Renovation",sep=""))

cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(wfe$WaterFuel_Efficiency)))
windows(width=7,height=5.5)
wfe[wfe$WaterFuel_Efficiency=="FIXME Fuel Oil Indirect",]$WaterFuel_Efficiency<-"Fuel Oil Indirect"
ggplot(wfe,aes(x=Year,y=1e-6*Count,fill=WaterFuel_Efficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw() + scale_fill_manual(values = cols)+
  labs(title = "Pre-2020 housing units by main water heating system, 2020-2060", y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Regular Renovation",sep=""))

hfe$HeatFuel<-sub("_.*","",hfe$HeatFuel_Efficiency)
hfe$HeatEfficiency<-sub(".*_","",hfe$HeatFuel_Efficiency)
hfe_el<-hfe[hfe$HeatFuel=="Electricity",]
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_el$HeatEfficiency)))
windows(width=7.5,height=5.8)
ggplot(hfe_el,aes(x=Year,y=1e-6*Count,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() +scale_fill_manual(values = cols) +
  labs(title = "Electric heating systems by equipment type and efficiency, 2020-2060",  y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Regular Renovation",sep=""))

hfe_gas<-hfe[hfe$HeatFuel=="Natural Gas",]
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(hfe_gas$HeatEfficiency)))
cols[which(cols=="#F0EB99")]<-"#BA5993" # Replace the bright yellow
windows(width=7.5,height=5.8)
ggplot(hfe_gas,aes(x=Year,y=1e-6*Count,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw()  + scale_fill_manual(values = cols) +
  labs(title = "Gas heating systems by equipment type and efficiency, 2020-2060",  y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Regular Renovation",sep=""))

hfe_oil<-hfe[hfe$HeatFuel=="Fuel Oil",]
cols<-cols[c(1:3,6:11)]
windows(width=7.5,height=5.8)
ggplot(hfe_oil,aes(x=Year,y=1e-6*Count,fill=HeatEfficiency))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma)+ theme_bw() + scale_fill_manual(values = cols) +
  labs(title = "Oil heating systems by equipment type and efficiency, 2020-2060",y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Regular Renovation",sep=""))

windows(width=7,height=5.5)
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(ins$WallInsulation)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
ggplot(ins,aes(x=Year,y=1e-6*Count,fill=WallInsulation))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw()  + scale_fill_manual(values = cols)+  #scale_fill_brewer(palette="Paired") +
  labs(title = "Pre-2020 housing units by Wall Insulation, 2020-2060", y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Regular Renovation",sep=""))

windows(width=7,height=5.5)
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(cte$AC.Type)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
ggplot(cte,aes(x=Year,y=1e-6*Count,fill=AC.Type))+geom_bar(position="stack", stat="identity") + scale_y_continuous(labels = scales::comma) + theme_bw()+ scale_fill_manual(values = cols) +
  labs(title = "Pre-2020 housing units by AC Type, 2020-2060", y = "Million Housing Units",subtitle = paste(scenario_names[sts], ", Regular Renovation",sep=""))

save(df_base,df_hiDR,hfe_base,hfe_hiDR,ins_base,ins_hiDR,cte_base,cte_hiDR,wfe_base,wfe_hiDR,file="../Intermediate_results/RegRenSummary.RData")