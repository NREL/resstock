# script to add housing characteristics for new cohorts, for all stock scenarios
# Will create 33 sets of new tsvs each in separate folders. one for each model year (2025 - 2060) for each (four) housing stock scenario, and one for 2020
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(readr)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts")
# list the names of the project folders
projects<-list.files(pattern = "project_national_",path="../")
projects<-paste("../",projects,sep="")

# windows ##########
# first create the windows file for the 2025 and 2030 new construction cohorts, both based on the 2020s characteristics
windows<-read_tsv('../project_national/housing_characteristics/Windows.tsv',col_names = TRUE)
windows<-windows[1:450,1:6] # remove the count and weight columns, and the references in the bottom row
# add two new options. With U-factors of 0.29 (hi-gain) and 0.26 (lo-gain), they are compatible with both IECC 2015 and 2021
# these already exist in options_lookup so no need for any change
windows$`Option=Low-E, Double, High-Gain`<-0 # add "Low-E, Double, High-Gain" option
windows$`Option=Low-E, Double, Low-Gain`<-0 # add "Low-E, Double, Low-Gainn" option
w2020<-windows[windows$`Dependency=Vintage`=="2010s",]
w2020$`Dependency=Vintage`<-"2020s"
# first remove all single pane windows
w2020$`Option=1 Pane`<-0
w2020$`Option=No Windows`<-0
w2020$`Option=2+ Pane`<-1
# for custom regions 3,6,and 11, adjust windows to IECC 2015 values. corresponds to climate regions 5,4C, and 3
w2020[w2020$`Dependency=Location Region`=="CR06"|w2020$`Dependency=Location Region`=="CR11",]$`Option=Low-E, Double, High-Gain`<-1
w2020[w2020$`Dependency=Location Region`=="CR06"|w2020$`Dependency=Location Region`=="CR11",]$`Option=2+ Pane`<-0
w2020[w2020$`Dependency=Location Region`=="CR03",]$`Option=Low-E, Double, Low-Gain`<-1
w2020[w2020$`Dependency=Location Region`=="CR03",]$`Option=2+ Pane`<-0

# initially define windows made in 2030s 2040s and 2050s as the same as those made in 2020s
w2030<-w2040<-w2050<-w2020
# who newly makes it into the IECC 2015+ club in the 2030s? custom regions 2,4,5,7, corresponding to climate regions 6 and 5, meaning they can have high SHGC 
w2030$`Dependency=Vintage`<-"2030s"
w2030[w2030$`Dependency=Location Region`=="CR02"|w2030$`Dependency=Location Region`=="CR04"|w2030$`Dependency=Location Region`=="CR05"|w2030$`Dependency=Location Region`=="CR07",]$`Option=Low-E, Double, High-Gain`<-1

# who newly makes it into the IECC 2015+ club in the 2040s? custom regions 8,9,10, corresponding to climate regions 4,3,2, meaning they can have low SHGC 
w2040$`Dependency=Vintage`<-"2040s"
w2040[w2040$`Dependency=Location Region`=="CR08"|w2040$`Dependency=Location Region`=="CR09"|w2040$`Dependency=Location Region`=="CR10",]$`Option=Low-E, Double, Low-Gain`<-1
# no changes between 2040s and 2050s
w2050<-w2040
w2050$`Dependency=Vintage`<-"2050s"
# save tsvs for each year/scenario project
# 2020s
windows_new<-as.data.frame(rbind(windows,w2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Windows.tsv',sep = "")
  write.table(format(windows_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# 2030s
windows_new<-as.data.frame(rbind(windows,w2020,w2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Windows.tsv',sep = "")
  write.table(format(windows_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# 2040s
windows_new<-as.data.frame(rbind(windows,w2020,w2030,w2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Windows.tsv',sep = "")
  write.table(format(windows_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# 2050s
windows_new<-as.data.frame(rbind(windows,w2020,w2030,w2040,w2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Windows.tsv',sep = "")
  write.table(format(windows_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# ducts #############
ducts<-read_tsv('../project_national/housing_characteristics/Ducts.tsv',col_names = TRUE)
ducts<-ducts[1:450,] # remove the count and weight columns, and the references in the bottom row

d2020<-ducts[ducts$`Dependency=Vintage`=="2010s",]
d2020$`Dependency=Vintage`<-"2020s"
# IECC 2015 R403.3: ducts in attics min R8 if diameter greater than 3in, greater than R-6 if less than 3in. Seems like no change between 2015 and 2018
# In other parts of building R6 for >3in, and R4.2 for <3in.
# This characteristic does not vary by geography, so we need to assume same characteristics for all new construction
# Also leakage is defined by % in the characteristic and by m3/m2minute in the code
# 2010s characteristics show R6 insulation for crawlspace and unheated basements, and R8 insulation for PierBeam and Slab foundations
#  keep insulation the same.  reduce leakage from 26:47:27 10%:20%:30% to 30:50:20 in 2020
d2020[d2020$`Dependency=HVAC Has Ducts`=="Yes" & d2020$`Dependency=Geometry Foundation Type`=="Crawl",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<- matrix(rep(c(0.3,0.5,0.2),each=5),5,3)
d2020[d2020$`Dependency=HVAC Has Ducts`=="Yes" & d2020$`Dependency=Geometry Foundation Type`=="Unheated Basement",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<- matrix(rep(c(0.3,0.5,0.2),each=5),5,3)

d2020[d2020$`Dependency=HVAC Has Ducts`=="Yes" & d2020$`Dependency=Geometry Foundation Type`=="Pier and Beam",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.3,0.5,0.2),each=5),5,3)
d2020[d2020$`Dependency=HVAC Has Ducts`=="Yes" & d2020$`Dependency=Geometry Foundation Type`=="Slab",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.3,0.5,0.2),each=5),5,3)

# initially define ducts made in 2030s 2040s and 2050s as the same as those made in 2020s
d2030<-d2040<-d2050<-d2020
# define vintage names
d2030$`Dependency=Vintage`<-"2030s"
d2040$`Dependency=Vintage`<-"2040s"
d2050$`Dependency=Vintage`<-"2050s"
# make changes to 2030 ducts here
#  keep insulation the same.  reduce leakage from 30:50:20 10%:20%:30% to 35:55:10 in 2030
d2030[d2030$`Dependency=HVAC Has Ducts`=="Yes" & d2030$`Dependency=Geometry Foundation Type`=="Crawl",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<- matrix(rep(c(0.35,0.55,0.1),each=5),5,3)
d2030[d2030$`Dependency=HVAC Has Ducts`=="Yes" & d2030$`Dependency=Geometry Foundation Type`=="Unheated Basement",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<- matrix(rep(c(0.35,0.55,0.1),each=5),5,3)

d2030[d2030$`Dependency=HVAC Has Ducts`=="Yes" & d2030$`Dependency=Geometry Foundation Type`=="Pier and Beam",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.35,0.55,0.1),each=5),5,3)
d2030[d2030$`Dependency=HVAC Has Ducts`=="Yes" & d2030$`Dependency=Geometry Foundation Type`=="Slab",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.35,0.55,0.1),each=5),5,3)
# make changes to 2040s ducts here 
#  keep insulation the same.  reduce leakage from 35:55:10 10%:20%:30% to 40:57:3 in 2040
d2040[d2040$`Dependency=HVAC Has Ducts`=="Yes" & d2040$`Dependency=Geometry Foundation Type`=="Crawl",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<- matrix(rep(c(0.4,0.57,0.03),each=5),5,3)
d2040[d2040$`Dependency=HVAC Has Ducts`=="Yes" & d2040$`Dependency=Geometry Foundation Type`=="Unheated Basement",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<- matrix(rep(c(0.4,0.57,0.03),each=5),5,3)

d2040[d2040$`Dependency=HVAC Has Ducts`=="Yes" & d2040$`Dependency=Geometry Foundation Type`=="Pier and Beam",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.4,0.57,0.03),each=5),5,3)
d2040[d2040$`Dependency=HVAC Has Ducts`=="Yes" & d2040$`Dependency=Geometry Foundation Type`=="Slab",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.4,0.57,0.03),each=5),5,3)
# make changes to 2050s ducts here
# Move all insulation to R8.  reduce leakage from 40:57:3 10%:20%:30% to 55:45:0 in 2050
d2050[d2050$`Dependency=HVAC Has Ducts`=="Yes" & d2050$`Dependency=Geometry Foundation Type`=="Crawl",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<-0
d2050[d2050$`Dependency=HVAC Has Ducts`=="Yes" & d2050$`Dependency=Geometry Foundation Type`=="Unheated Basement",c("Option=10% Leakage, R-6","Option=20% Leakage, R-6","Option=30% Leakage, R-6")]<-0

d2050[d2050$`Dependency=HVAC Has Ducts`=="Yes" & d2050$`Dependency=Geometry Foundation Type`=="Crawl",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.55,0.45,0),each=5),5,3)
d2050[d2050$`Dependency=HVAC Has Ducts`=="Yes" & d2050$`Dependency=Geometry Foundation Type`=="Unheated Basement",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.55,0.45,0),each=5),5,3)

d2050[d2050$`Dependency=HVAC Has Ducts`=="Yes" & d2050$`Dependency=Geometry Foundation Type`=="Pier and Beam",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.55,0.45,0),each=5),5,3)
d2050[d2050$`Dependency=HVAC Has Ducts`=="Yes" & d2050$`Dependency=Geometry Foundation Type`=="Slab",c("Option=10% Leakage, R-8","Option=20% Leakage, R-8","Option=30% Leakage, R-8")]<- matrix(rep(c(0.55,0.45,0),each=5),5,3)

# then save the new ducts characteristics
# 2020
ducts_new<-as.data.frame(rbind(ducts,d2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Ducts.tsv',sep = "")
  write.table(format(ducts_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s ducts
ducts_new<-as.data.frame(rbind(ducts,d2020,d2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Ducts.tsv',sep = "")
  write.table(format(ducts_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2040s ducts
ducts_new<-as.data.frame(rbind(ducts,d2020,d2030,d2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Ducts.tsv',sep = "")
  write.table(format(ducts_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2050s ducts
ducts_new<-as.data.frame(rbind(ducts,d2020,d2030,d2040,d2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Ducts.tsv',sep = "")
  write.table(format(ducts_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Num Units HL #############
NUHL<-read_tsv('../project_national/housing_characteristics/Geometry Building Number Units HL.tsv',col_names = TRUE)
NUHL<-NUHL[1:81,1:11] # remove comment at bottom, and count and weight columns
# this is one characteristics that I don't intend to change at all, apart from adding the column names for new vintages
# I am not sure if it influences the resstock simulation or not.
nu2020<-NUHL[NUHL$`Dependency=Vintage`=="2010s",]
nu2020$`Dependency=Vintage`<-"2020s"
# define NU made in 2030s 2040s and 2050s as the same as those made in 2020s
nu2030<-nu2040<-nu2050<-nu2020
# define vintage names
nu2030$`Dependency=Vintage`<-"2030s"
nu2040$`Dependency=Vintage`<-"2040s"
nu2050$`Dependency=Vintage`<-"2050s"

NUHL_new<-as.data.frame(rbind(NUHL,nu2020,nu2030,nu2040,nu2050))
# save same file to all new projects 
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Geometry Building Number Units HL.tsv',sep = "")
  write.table(format(NUHL_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# Garage ###########
gar<-read_tsv('../project_national/housing_characteristics/Geometry Garage.tsv',col_names = TRUE)
gar<-gar[1:900,1:8]
# seeing as multifamily already have no garage, make no change for future cohorts
gar2020<-gar[gar$`Dependency=Vintage`=="2010s",]
gar2020$`Dependency=Vintage`<-"2020s"
# define gar made in 2030s 2040s and 2050s as the same as those made in 2020s
gar2030<-gar2040<-gar2050<-gar2020
# define vintage names
gar2030$`Dependency=Vintage`<-"2030s"
gar2040$`Dependency=Vintage`<-"2040s"
gar2050$`Dependency=Vintage`<-"2050s"
gar_new<-as.data.frame(rbind(gar2020,gar2030,gar2040,gar2050))
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Geometry Garage.tsv',sep = "")
  write.table(format(gar_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Cooling Efficiency ###########
ceff<-read_tsv('../project_national/housing_characteristics/HVAC Cooling Efficiency.tsv',col_names = TRUE)
ceff<-ceff[1:144,1:14] # remove comments and count and weight columns
# add columes for AC, SEER 18. Current max efficiency for Room AC (EER 12) should be sufficient, can move distribution into this category as time goes on)
ceff$`Option=AC, SEER 18`<-0 # this already exists in options_lookup
ceff<-ceff[,c(1:7,15,8:14)]
ceff2020<-ceff[ceff$`Dependency=Vintage`=="2010s",]
ceff2020$`Dependency=Vintage`<-"2020s"
# make changes to 2020 cooling eff here.
# There is no geo dependence here, but AC efficiencies will are and will be higher in southern states (https://www.ecfr.gov/cgi-bin/text-idx?rgn=div8&node=10:3.0.1.4.18.3.9.2)
# Make changes in the bs.csv after generation to represent higher efficiencies in those states
# for national baseline, increase the penetration of SEER 15 and SEER 18 units
# efficiency of heat pump based cooling is defined in elsewhere in HVAC Heating Efficiency
ceff2020[ceff2020$`Dependency=HVAC Cooling Type`=="Central AC" & (ceff2020$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2020$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=AC, SEER 10","Option=AC, SEER 13","Option=AC, SEER 15","Option=AC, SEER 18")]<-matrix(rep(c(0,0.6,0.38,0.02),each=2),2,4)
# for room ACs, increase the penetration of ACs with EER>10
ceff2020[ceff2020$`Dependency=HVAC Cooling Type`=="Room AC" & (ceff2020$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2020$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=Room AC, EER 8.5","Option=Room AC, EER 9.8","Option=Room AC, EER 10.7","Option=Room AC, EER 12.0")]<-matrix(rep(c(0,0.15,0.65,0.2),each=2),2,4)

# initially define cooling equipment made in 2030s 2040s and 2050s as the same as those made in 2020s
ceff2030<-ceff2040<-ceff2050<-ceff2020
# define vintage names
ceff2030$`Dependency=Vintage`<-"2030s"
ceff2040$`Dependency=Vintage`<-"2040s"
ceff2050$`Dependency=Vintage`<-"2050s"
# make changes to 2030 ceff here
# for national baseline, increase the penetration of SEER 15 and SEER 18 units
ceff2030[ceff2030$`Dependency=HVAC Cooling Type`=="Central AC" & (ceff2030$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2030$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=AC, SEER 10","Option=AC, SEER 13","Option=AC, SEER 15","Option=AC, SEER 18")]<-matrix(rep(c(0,0.53,0.41,0.06),each=2),2,4)
# for room ACs, increase the penetration of ACs with EER>10
ceff2030[ceff2030$`Dependency=HVAC Cooling Type`=="Room AC" & (ceff2030$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2030$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=Room AC, EER 8.5","Option=Room AC, EER 9.8","Option=Room AC, EER 10.7","Option=Room AC, EER 12.0")]<-matrix(rep(c(0,0.07,0.63,0.3),each=2),2,4)
# make changes to 2040s ceff here 
# for national baseline, increase the penetration of SEER 15 and SEER 18 units more drastically
ceff2040[ceff2040$`Dependency=HVAC Cooling Type`=="Central AC" & (ceff2040$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2040$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=AC, SEER 10","Option=AC, SEER 13","Option=AC, SEER 15","Option=AC, SEER 18")]<-matrix(rep(c(0,0.39,0.44,0.17),each=2),2,4)
# for room ACs, reduce EEC<10 to 0, with almost all increase going to EER=12
ceff2040[ceff2040$`Dependency=HVAC Cooling Type`=="Room AC" & (ceff2040$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2040$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=Room AC, EER 8.5","Option=Room AC, EER 9.8","Option=Room AC, EER 10.7","Option=Room AC, EER 12.0")]<-matrix(rep(c(0,0,0.5,0.5),each=2),2,4)
# make changes to 2050s ceff here
# for national baseline, increase the penetration of SEER 15 and SEER 18 units more drastically, very few SEER 13 now
ceff2050[ceff2050$`Dependency=HVAC Cooling Type`=="Central AC" & (ceff2050$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2050$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=AC, SEER 10","Option=AC, SEER 13","Option=AC, SEER 15","Option=AC, SEER 18")]<-matrix(rep(c(0,0.1,0.4,0.5),each=2),2,4)
# for room ACs, most new homes now have EER=12
ceff2050[ceff2050$`Dependency=HVAC Cooling Type`=="Room AC" & (ceff2050$`Dependency=HVAC Has Shared System`=="Heating Only" | ceff2050$`Dependency=HVAC Has Shared System`=="None"),
         c("Option=Room AC, EER 8.5","Option=Room AC, EER 9.8","Option=Room AC, EER 10.7","Option=Room AC, EER 12.0")]<-matrix(rep(c(0,0,0.25,0.75),each=2),2,4)

# then save the new cooling efficiency file complete with new 2020 characteristics
ceff_new<-as.data.frame(rbind(ceff,ceff2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Efficiency.tsv',sep = "")
  write.table(format(ceff_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s ceff
ceff_new<-as.data.frame(rbind(ceff,ceff2020,ceff2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Efficiency.tsv',sep = "")
  write.table(format(ceff_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s ceff
ceff_new<-as.data.frame(rbind(ceff,ceff2020,ceff2030,ceff2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Efficiency.tsv',sep = "")
  write.table(format(ceff_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s ceff
ceff_new<-as.data.frame(rbind(ceff,ceff2020,ceff2030,ceff2040,ceff2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Efficiency.tsv',sep = "")
  write.table(format(ceff_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# HVAC shared system ###########
hss<-read_tsv('../project_national/housing_characteristics/HVAC Has Shared System.tsv',col_names = TRUE)
hss<-hss[1:900,1:8] # remove comments and count and weight columns
hss2020<-hss[hss$`Dependency=Vintage`=="2010s",]
hss2020$`Dependency=Vintage`<-"2020s"
# Unclear how this may change in future, so no changes to this characteristic
# define hss made in 2030s 2040s and 2050s as the same as those made in 2020s
hss2030<-hss2040<-hss2050<-hss2020
# define vintage names
hss2030$`Dependency=Vintage`<-"2030s"
hss2040$`Dependency=Vintage`<-"2040s"
hss2050$`Dependency=Vintage`<-"2050s"
hss_new<-as.data.frame(rbind(hss,hss2020,hss2030,hss2040,hss2050))
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Has Shared System.tsv',sep = "")
  write.table(format(hss_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# HVAC heating type ########
# need to create, in each project folder, the scenario_dependent_characteristics subdirectory, and sub-subdirectories of Unchanged, Deep_Electrification, and Reduced_FloorArea before defining htt
htt<-read_tsv('../project_national/housing_characteristics/HVAC Heating Type.tsv',col_names = TRUE)
htt<-htt[1:810,1:8] # remove comments and count and weight columns
htt2020<-htt[htt$`Dependency=Vintage`=="2010s",] 
htt2020$`Dependency=Vintage`<-"2020s"
# Here is the place to increase the % of electrically heated homes that use heat pumps
# this file is a dependency for heating efficiency, determining the detailed conversion device type
# based on trends from Census characteristics of new housing for sf and mf homes, 1999-2019: https://www.census.gov/construction/chars/xls/heatfuelbysystem_cust.xls
# make changes to 2020s Heat type here. I do so by groups of IECC CZ that correspond closely to census regions, for which the stats are given in CNH
# First cz in the South. where HP are very dominant, especially in SF homes. I represent an increasing share in ductless (minisplit) HPs, as they are expected to grow in market share.
# NB this share has far more HP than the ResStock 2010s shares, which are based on RECS 2009. Throughout the 2010s, 88% (77%) of new electric heated SF (MF) homes in the South used HP heating
htt2020[htt2020$`Dependency=Heating Fuel`=="Electricity" & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "1A" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "2A" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "3A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.83,0.12,0.05,0),each=3),3,4)
# Second CZ in the West excluding very cold zone 7. Here resistance heating is surprisingly high, especially in MF. 
# In the entire West through the 2010s, of new electric homes, 66% (41%) of SF (MF) used HP, 21% (15%) used air furnaces, and 13% (40%) used electric resistance
htt2020[htt2020$`Dependency=Heating Fuel`=="Electricity" & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "2B" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "3B" | 
                                                              htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "3C" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "4B" |
                                                              htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "4C" |htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "5B" | 
                                                              htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "6B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.6,0.17,0.02,0.21),each=7),7,4)
# Third CZ in the MW excluding very cold zone 7. HP less common here, around 55% (27%) in SF (MF) in the second half of 2010s. Furnace share much higher, around 36% (64%). Some elec resistance: 5-10%
htt2020[htt2020$`Dependency=Heating Fuel`=="Electricity" & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "6A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.54,0.4,0.01,0.05),each=1),1,4)
# Fourth for CZ 4A, which is a mix between South and NE, with higher Southern representation (also some MW here). Heat pumps around 60% in NE, and over 85% in the south . Go with 75%. Other (Resistance, non-ducted) around 25% in NE and dropping, 1% in S. assume 9%. Leaves around 16% for furnace
htt2020[htt2020$`Dependency=Heating Fuel`=="Electricity" & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "4A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.71,0.16,0.04,0.09),each=1),1,4)
# Fifth for CZ 5A, which we assume is a mix between MW and NE, with higher MW representation. Heat pump share in SF quite similar in NE/MW (around 60%), but quite lower in MF (around 40%), go with 55%. 32% furnace, and 13% other (Resistance) which is relatively high in NE, 22% (31%) in SF (MF)
htt2020[htt2020$`Dependency=Heating Fuel`=="Electricity" & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "5A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.52,0.32,0.03,0.13),each=1),1,4)
# Last the two cold climate 7A and 7B, where heat pumps will be less common. ResStock value for 2010s is 100% electric resistance (non-ducted heating). Reduce to 80% in 2020s. Assume a higher share of HP are minisplit, non-ducted, than in other regions
htt2020[htt2020$`Dependency=Heating Fuel`=="Electricity" & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "7A" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "7B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.1,0.05,0.05,0.8),each=2),2,4)

# now for combustion fuels. Based on NRC data, almost all new heating systems are ducted air furnaces. Water/steam systems are rare, except for in MF homes in the NE and W, where they make up almost 30%
# Define all values here based on SF-MF split except for W and NE MF. They can be overwritten afterwards in the bs.csv
# First South (SF and MF), 97% ducted
htt2020[htt2020$`Dependency=Heating Fuel`!="Electricity" & htt2020$`Dependency=Heating Fuel`!="None"  & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "1A" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "2A" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "3A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.97,0.03),each=12),12,2)
# Second West (excl MF), 99% ducted
htt2020[htt2020$`Dependency=Heating Fuel`!="Electricity" & htt2020$`Dependency=Heating Fuel`!="None"  & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "2B" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "3B" |
                                                                                                           htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "3C" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "4B" |
                                                                                                           htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "4C" |htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "5B" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "6B"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.99,0.01),each=28),28,2)
# Third MW, excl cold region 7, including CZ 5A, 96% ducted
htt2020[htt2020$`Dependency=Heating Fuel`!="Electricity" & htt2020$`Dependency=Heating Fuel`!="None"  & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "5A" |htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "6A" ),
       c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.96,0.04),each=8),8,2)
# Fourth for CZ 4A, which we assume is a mix between South and NE, with higher Southern representation (also some MW here). 97% ducted
htt2020[htt2020$`Dependency=Heating Fuel`!="Electricity" & htt2020$`Dependency=Heating Fuel`!="None"  & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "4A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.97,0.03),each=4),4,2)
# Last the two cold regions 7, where steam/hot water is still more common
htt2020[htt2020$`Dependency=Heating Fuel`!="Electricity" & htt2020$`Dependency=Heating Fuel`!="None"  & (htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "7A" | htt2020$`Dependency=ASHRAE IECC Climate Zone 2004` == "7B"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.7,0.3),each=8),8,2)

htt2030<-htt2020
# define vintage names
htt2030$`Dependency=Vintage`<-"2030s"

# update 2030s data
# First cz in the South.
htt2030[htt2030$`Dependency=Heating Fuel`=="Electricity" & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "1A" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "2A" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "3A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.85,0.09,0.06,0),each=3),3,4)
# Second CZ in the West excluding very cold zone 7
htt2030[htt2030$`Dependency=Heating Fuel`=="Electricity" & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "2B" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "3B" | 
                                                              htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "3C" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "4B" |
                                                              htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "4C" |htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "5B"| htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "6B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.62,0.14,0.08,0.16),each=7),7,4)
# Third CZ in the MW excluding very cold zone 7. 
htt2030[htt2030$`Dependency=Heating Fuel`=="Electricity" & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "6A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.57,0.36,0.05,0.02),each=1),1,4)
# Fourth for CZ 4A, which we assume is a mix between South and NE, with higher Southern representation (also some MW here). 
htt2030[htt2030$`Dependency=Heating Fuel`=="Electricity" & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "4A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.73,0.14,0.07,0.06),each=1),1,4)
# Fifth for CZ 5A, which we assume is a mix between MW and NE, with higher MW representation.
htt2030[htt2030$`Dependency=Heating Fuel`=="Electricity" & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "5A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.57,0.26,0.07,0.1),each=1),1,4)
# Last the two cold climate 7A and 7B, where heat pumps will be less common
htt2030[htt2030$`Dependency=Heating Fuel`=="Electricity" & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "7A" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "7B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.2,0.05,0.1,0.65),each=2),2,4)

# now for combustion fuels. 
# First South, 99% ducted
htt2030[htt2030$`Dependency=Heating Fuel`!="Electricity" & htt2030$`Dependency=Heating Fuel`!="None"  & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "1A" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "2A" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "3A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.99,0.01),each=12),12,2)
# Second West (excl MF), 100% ducted
htt2030[htt2030$`Dependency=Heating Fuel`!="Electricity" & htt2030$`Dependency=Heating Fuel`!="None"  & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "2B" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "3B" |
                                                                                                           htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "3C" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "4B" |
                                                                                                           htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "4C" |htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "5B" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "6B"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(1,0),each=28),28,2)
# Third MW, excl cold region 7, including CZ 5a 98% ducted
htt2030[htt2030$`Dependency=Heating Fuel`!="Electricity" & htt2030$`Dependency=Heating Fuel`!="None"  & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "5A" |htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "6A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.98,0.02),each=8),8,2)
# Fourth for CZ 4A, which we assume is a mix between South and NE, with higher Southern representation (also some MW here). 99% ducted
htt2030[htt2030$`Dependency=Heating Fuel`!="Electricity" & htt2030$`Dependency=Heating Fuel`!="None"  & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "4A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.99,0.01),each=4),4,2)
# Last the two cold regions 7, where steam/hot water is still more common
htt2030[htt2030$`Dependency=Heating Fuel`!="Electricity" & htt2030$`Dependency=Heating Fuel`!="None"  & (htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "7A" | htt2030$`Dependency=ASHRAE IECC Climate Zone 2004` == "7B"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.7,0.3),each=8),8,2)
# update 2040s data
htt2040<-htt2030
# define vintage names
htt2040$`Dependency=Vintage`<-"2040s"
# First cz in the South.
htt2040[htt2040$`Dependency=Heating Fuel`=="Electricity" & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "1A" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "2A" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "3A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.89,0.02,0.09,0),each=3),3,4)
# Second CZ in the West excluding very cold zone 7. 
htt2040[htt2040$`Dependency=Heating Fuel`=="Electricity" & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "2B" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "3B" | 
                                                              htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "3C" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "4B" |
                                                              htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "4C" |htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "5B"| htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "6B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.67,0.08,0.14,0.11),each=7),7,4)
# Third CZ in the MW excluding very cold zone 7. 
htt2040[htt2040$`Dependency=Heating Fuel`=="Electricity" & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "6A" ),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.59,0.3,0.1,0.01),each=1),1,4)
# Fourth for CZ 4A, which is a mix between South and NE, with higher Southern representation (also some MW here). 
htt2040[htt2040$`Dependency=Heating Fuel`=="Electricity" & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "4A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.8,0.07,0.1,0.03),each=1),1,4)
# Fifth for CZ 5A, which is a mix between MW and NE, with higher MW representation.
htt2040[htt2040$`Dependency=Heating Fuel`=="Electricity" & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "5A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.61,0.22,0.11,0.06),each=1),1,4)
# Last the two cold climate 7A and 7B, where heat pumps will be less common
htt2040[htt2040$`Dependency=Heating Fuel`=="Electricity" & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "7A" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "7B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.25,0,0.15,0.6),each=2),2,4)

# now for combustion fuels. Based on NRC data, almost all new heating systems are ducted air furnaces. Water/steam systems are rare, except for in MF homes in the NE and W, where they make up almost 30%
# Define all values here based on SF-MF split except for W and NE MF. They can be overwritten afterwards in the bs.csv
# First South, 100% ducted
htt2040[htt2040$`Dependency=Heating Fuel`!="Electricity" & htt2040$`Dependency=Heating Fuel`!="None"  & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "1A" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "2A" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "3A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(1,0),each=12),12,2)
# Second West (excl MF), 100% ducted
htt2040[htt2040$`Dependency=Heating Fuel`!="Electricity" & htt2040$`Dependency=Heating Fuel`!="None"  & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "2B" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "3B" |
                                                                                                           htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "3C" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "4B" |
                                                                                                           htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "4C" |htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "5B" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "6B"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(1,0),each=28),28,2)
# Third MW, excl cold region 7, including CZ 5a 99% ducted
htt2040[htt2040$`Dependency=Heating Fuel`!="Electricity" & htt2040$`Dependency=Heating Fuel`!="None"  & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "5A" |htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "6A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.99,0.01),each=8),8,2)
# Fourth for CZ 4A, which is a mix between South and NE, with higher Southern representation (also some MW here). 100% ducted
htt2040[htt2040$`Dependency=Heating Fuel`!="Electricity" & htt2040$`Dependency=Heating Fuel`!="None"  & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "4A"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(1,0),each=4),4,2)
# Last the two cold regions 7, where steam/hot water is still more common. Climate change may make ducted systems more common as the temperatures rise
htt2040[htt2040$`Dependency=Heating Fuel`!="Electricity" & htt2040$`Dependency=Heating Fuel`!="None"  & (htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "7A" | htt2040$`Dependency=ASHRAE IECC Climate Zone 2004` == "7B"),
        c("Option=Ducted Heating"  ,"Option=Non-Ducted Heating")]<-matrix(rep(c(0.75,0.25),each=8),8,2)
htt2050<-htt2040
htt2050$`Dependency=Vintage`<-"2050s"
# update 2050s data, changing only the elec share, fuels stay the same
# First cz in the South.
htt2050[htt2050$`Dependency=Heating Fuel`=="Electricity" & (htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "1A" | htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "2A" | htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "3A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.89,0.01,0.1,0),each=3),3,4)
# Second CZ in the West excluding very cold zone 7.
htt2050[htt2050$`Dependency=Heating Fuel`=="Electricity" & (htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "2B" | htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "3B" | 
                                                              htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "3C" | htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "4B" |
                                                              htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "4C" |htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "5B"| htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "6B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.71,0.05,0.19,0.05),each=7),7,4)
# Third CZ in the MW excluding very cold zone 7. 
htt2050[htt2050$`Dependency=Heating Fuel`=="Electricity" & (htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "6A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.68,0.15,0.16,0.01),each=1),1,4)
# Fourth for CZ 4A, which we assume is a mix between South and NE, with higher Southern representation (also some MW here). 
htt2050[htt2050$`Dependency=Heating Fuel`=="Electricity" & (htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "4A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.83,0.02,0.14,0.01),each=1),1,4)
# Fifth for CZ 5A, which we assume is a mix between MW and NE, with higher MW representation.
htt2050[htt2050$`Dependency=Heating Fuel`=="Electricity" & (htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "5A"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.64,0.15,0.19,0.02),each=1),1,4)
# Last the two cold climate 7A and 7B. Here, both warming due to climate chanage, and improved cold climate HP technology raise the HP share, but resistance heating is still common.
htt2050[htt2050$`Dependency=Heating Fuel`=="Electricity" & (htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "7A" | htt2050$`Dependency=ASHRAE IECC Climate Zone 2004` == "7B"),
        c("Option=Ducted Heat Pump" , "Option=Ducted Heating"  ,"Option=Non-Ducted Heat Pump","Option=Non-Ducted Heating")]<-matrix(rep(c(0.3,0,0.2,0.5),each=2),2,4)
# now save changes for 2020s
htt_new<-as.data.frame(rbind(htt,htt2020))
for (p in 2:7) { # which projects do these changes apply to? in this case 2025 and 2030s
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# now save changes for 2030s
htt_new<-as.data.frame(rbind(htt,htt2020,htt2030))
for (p in 8:13) { # which projects do these changes apply to? in this case 2035 and 2040s
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
htt_new<-as.data.frame(rbind(htt,htt2020,htt2030,htt2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
htt_new<-as.data.frame(rbind(htt,htt2020,htt2030,htt2040,htt2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# add scenario dependent files for deep electrification, incorporating a higher share of heat pumps
# make the same proportional changes for all construction cohorts
# 2020s
htt2020_de<-htt2020
# allocate half of the electric ducted heating shares to ducted heat pumps
htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`<-
  htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`+0.5*htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`
htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`<-0.5*htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`

# allocate 30% of the electric non-ducted heating shares to non-ducted heat pumps
htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`<-
  htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`+0.3*htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`<-0.7*htt2020_de[htt2020_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
# 2030s
htt2030_de<-htt2030
# allocate half of the electric ducted heating shares to ducted heat pumps
htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`<-
  htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`+0.5*htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`
htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`<-0.5*htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`

# allocate 30% of the electric non-ducted heating shares to non-ducted heat pumps
htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`<-
  htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`+0.3*htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`<-0.7*htt2030_de[htt2030_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
# 2040s
htt2040_de<-htt2040
# allocate half of the electric ducted heating shares to ducted heat pumps
htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`<-
  htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`+0.5*htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`
htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`<-0.5*htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`

# allocate 30% of the electric non-ducted heating shares to non-ducted heat pumps
htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`<-
  htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`+0.3*htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`<-0.7*htt2040_de[htt2040_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
# 2050s
htt2050_de<-htt2050
# allocate half of the electric ducted heating shares to ducted heat pumps
htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`<-
  htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heat Pump`+0.5*htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`
htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`<-0.5*htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Ducted Heating`

# allocate 30% of the electric non-ducted heating shares to non-ducted heat pumps
htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`<-
  htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heat Pump`+0.3*htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`<-0.7*htt2050_de[htt2050_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Non-Ducted Heating`
# save deep electrification files
htt_new<-as.data.frame(rbind(htt,htt2020_de))
for (p in 2:7) { # which projects do these changes apply to? in this case 2025 and 2030s
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# now save changes for 2030s
htt_new<-as.data.frame(rbind(htt,htt2020_de,htt2030_de))
for (p in 8:13) { # which projects do these changes apply to? in this case 2035 and 2040s
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
htt_new<-as.data.frame(rbind(htt,htt2020_de,htt2030_de,htt2040_de))
for (p in 14:19) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
htt_new<-as.data.frame(rbind(htt,htt2020_de,htt2030_de,htt2040_de,htt2050_de))
for (p in 20:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/HVAC Heating Type.tsv',sep = "")
  write.table(format(htt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# HVAC Cooling type ######
hct<-read_tsv('../project_national/housing_characteristics/HVAC Cooling Type.tsv',col_names = TRUE)
hct<-hct[1:2250,1:8] # remove comments and count/weight columns
hct2020<-hct[hct$`Dependency=Vintage ACS`=="2010s",] # this file is dependent on Vintage ACS
hct2010<-hct2020
hct2020$`Dependency=Vintage ACS`<-"2020s"
# roughly divide climate regions into Cold climates, where AC access grows most slowly, Slow AC growth climates (moderate climates), and Moderate AC growth (hot) climates. 
# Based on Characteristics of New Housing surveys (https://www.census.gov/construction/chars/xls/aircond_cust.xls; https://www.census.gov/construction/chars/xls/mfu_aircond_cust.xls),
# few new homes in the South are built without AC now
Cold<-c("6A","6B","7A","7B","4C")
Slow<-c("3B","3C","4A","4B","5A","5B")
Mod<-c("1A","2A","2B","3A")
# Here we only change cooling types between None, Central AC, and Room AC, basically reducing the share of homes with no AC to represent further growth of AC access.
# House using HP based cooling are automatcically assigned a HP AC system based on them having a HP, which is defined elsewhere, in HVAC Heating Type.
# About one fifth of homes or less in the NE and W are built without AC
for (l in 1:nrow(hct2020)) { # solution to model growth in AC
  if (hct2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Cold) {
  none<-hct2020$`Option=None`[l]
  hct2020$`Option=None`[l]<-0.9*none # reduce the share of housing that have no AC by 10%
  # then add those deducted shares in a 50:50 split to central and room AC
  hct2020$`Option=Central AC`[l]<- hct2020$`Option=Central AC`[l]+0.05*none
  hct2020$`Option=Room AC`[l]<- hct2020$`Option=Room AC`[l]+0.05*none
  }
  if (hct2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Slow) {
    none<-hct2020$`Option=None`[l]
    hct2020$`Option=None`[l]<-0.75*none # reduce the share of housing that have no AC by 25%, assign a higher share to Central AC
    hct2020$`Option=Central AC`[l]<- hct2020$`Option=Central AC`[l]+0.2*none
    hct2020$`Option=Room AC`[l]<- hct2020$`Option=Room AC`[l]+0.05*none
  }
  if (hct2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Mod) {
    none<-hct2020$`Option=None`[l]
    hct2020$`Option=None`[l]<-0.5*none # reduce the share of housing that have no AC by 50%, assign a higher share to Central AC
    hct2020$`Option=Central AC`[l]<- hct2020$`Option=Central AC`[l]+0.35*none
    hct2020$`Option=Room AC`[l]<- hct2020$`Option=Room AC`[l]+0.15*none
  }
}
# Apply the same growth rates to 2030s, 2040s, 2050s
hct2030<-hct2020
hct2030$`Dependency=Vintage ACS`<-"2030s"
for (l in 1:nrow(hct2030)) { 
  if (hct2030$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Cold) {
    none<-hct2030$`Option=None`[l]
    hct2030$`Option=None`[l]<-0.9*none
    hct2030$`Option=Central AC`[l]<- hct2030$`Option=Central AC`[l]+0.05*none
    hct2030$`Option=Room AC`[l]<- hct2030$`Option=Room AC`[l]+0.05*none
  }
  if (hct2030$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Slow) {
    none<-hct2030$`Option=None`[l]
    hct2030$`Option=None`[l]<-0.75*none
    hct2030$`Option=Central AC`[l]<- hct2030$`Option=Central AC`[l]+0.2*none
    hct2030$`Option=Room AC`[l]<- hct2030$`Option=Room AC`[l]+0.05*none
  }
  if (hct2030$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Mod) {
    none<-hct2030$`Option=None`[l]
    hct2030$`Option=None`[l]<-0.5*none
    hct2030$`Option=Central AC`[l]<- hct2030$`Option=Central AC`[l]+0.35*none
    hct2030$`Option=Room AC`[l]<- hct2030$`Option=Room AC`[l]+0.15*none
  }
}
hct2040<-hct2030
hct2040$`Dependency=Vintage ACS`<-"2040s"
for (l in 1:nrow(hct2040)) { 
  if (hct2040$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Cold) {
    none<-hct2040$`Option=None`[l]
    hct2040$`Option=None`[l]<-0.9*none
    hct2040$`Option=Central AC`[l]<- hct2040$`Option=Central AC`[l]+0.05*none
    hct2040$`Option=Room AC`[l]<- hct2040$`Option=Room AC`[l]+0.05*none
  }
  if (hct2040$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Slow) {
    none<-hct2040$`Option=None`[l]
    hct2040$`Option=None`[l]<-0.75*none
    hct2040$`Option=Central AC`[l]<- hct2040$`Option=Central AC`[l]+0.2*none
    hct2040$`Option=Room AC`[l]<- hct2040$`Option=Room AC`[l]+0.05*none
  }
  if (hct2040$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Mod) {
    none<-hct2040$`Option=None`[l]
    hct2040$`Option=None`[l]<-0.5*none
    hct2040$`Option=Central AC`[l]<- hct2040$`Option=Central AC`[l]+0.35*none
    hct2040$`Option=Room AC`[l]<- hct2040$`Option=Room AC`[l]+0.15*none
  }
}
hct2050<-hct2040
hct2050$`Dependency=Vintage ACS`<-"2050s"
for (l in 1:nrow(hct2050)) { # solution to model growth in AC. Pick up from here!
  if (hct2050$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Cold) {
    none<-hct2050$`Option=None`[l]
    hct2050$`Option=None`[l]<-0.9*none
    hct2050$`Option=Central AC`[l]<- hct2050$`Option=Central AC`[l]+0.05*none
    hct2050$`Option=Room AC`[l]<- hct2050$`Option=Room AC`[l]+0.05*none
  }
  if (hct2050$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Slow) {
    none<-hct2050$`Option=None`[l]
    hct2050$`Option=None`[l]<-0.75*none
    hct2050$`Option=Central AC`[l]<- hct2050$`Option=Central AC`[l]+0.2*none
    hct2050$`Option=Room AC`[l]<- hct2050$`Option=Room AC`[l]+0.05*none
  }
  if (hct2050$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% Mod) {
    none<-hct2050$`Option=None`[l]
    hct2050$`Option=None`[l]<-0.5*none
    hct2050$`Option=Central AC`[l]<- hct2050$`Option=Central AC`[l]+0.35*none
    hct2050$`Option=Room AC`[l]<- hct2050$`Option=Room AC`[l]+0.15*none
  }
}
# then save the new hvac cooling file complete with new 2020 characteristics
hct_new<-as.data.frame(rbind(hct,hct2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Type.tsv',sep = "")
  write.table(format(hct_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s hct
hct_new<-as.data.frame(rbind(hct,hct2020,hct2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Type.tsv',sep = "")
  write.table(format(hct_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2040s hct
hct_new<-as.data.frame(rbind(hct,hct2020,hct2030,hct2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Type.tsv',sep = "")
  write.table(format(hct_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2050s hct
hct_new<-as.data.frame(rbind(hct,hct2020,hct2030,hct2040,hct2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Cooling Type.tsv',sep = "")
  write.table(format(hct_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Heating fuel #################
load("../../StockModelCode/buildstock100.RData")
rp<-as.data.frame(table(rs$Census.Region,rs$PUMA))
rpp<-rp[rp$Freq>0,]
rpp<-rpp[,1:2]
names(rpp)<-c("Region","puma")

hf<-read_tsv('../project_national/housing_characteristics/Heating Fuel.tsv',col_names = TRUE)
hf<-hf[1:105120,1:9] # remove comments and additional columns
hf2020<-hf[hf$`Dependency=Vintage`=="2010s",]
hf2010<-hf[hf$`Dependency=Vintage`=="2010s",]

hf2020$`Dependency=Vintage`<-"2020s"

hf2020<-merge(hf2020,rpp,by.x = "Dependency=PUMA",by.y="puma") # add census region to the heating fuel files
# define an alternative which will be used to model more advanced electrification
hf2020adv<-hf2020
# make changes to 2020 heating fuel here, I will show increased electrification, with geo resolution of census regions, which captures major differences in projected price differentials b/w gas and electricity
for (l in 1:nrow(hf2020)) {
  if (hf2020$`Region`[l] == "Northeast") { # in the Northeast, the move away from gas is the slowest, due to higher priced electricity
    gas0<-hf2020$`Option=Natural Gas`[l]
    lpg0<-hf2020$`Option=Propane`[l]
    oil0<-hf2020$`Option=Fuel Oil`[l]
    
    hf2020$`Option=Electricity`[l]<-hf2020$`Option=Electricity`[l]+0.03*gas0+0.03*lpg0+0.15*oil0 # 3% of gas/lpg becomes electric, 15% of oil becomes electric
    hf2020$`Option=Natural Gas`[l]<-0.97*hf2020$`Option=Natural Gas`[l]+0.65*oil0 # 3% of gas becomes electric, 65% of oil becomes gas
    hf2020$`Option=Propane`[l]<-0.97*hf2020$`Option=Propane`[l]+0.1*oil0 # 3% of lpg becomes electric, 10% of oil becomes lpg
    hf2020$`Option=Fuel Oil`[l]<-0.1*hf2020$`Option=Fuel Oil`[l] # 65% of oil becomes gas, 15% becomes electric, 10% becomes lpg
    # advanced electrification scenario
    hf2020adv$`Option=Electricity`[l]<-hf2020adv$`Option=Electricity`[l]+0.2*gas0+0.2*lpg0+0.8*oil0 # 20% of gas/lpg becomes electric, 80% of oil becomes electric
    hf2020adv$`Option=Natural Gas`[l]<-0.8*hf2020adv$`Option=Natural Gas`[l]+0.15*oil0 # 20% of gas becomes electric, 15% of oil becomes gas
    hf2020adv$`Option=Propane`[l]<-0.8*hf2020adv$`Option=Propane`[l]+0.05*oil0 # 20% of lpg becomes electric, 5% of oil becomes lpg
    hf2020adv$`Option=Fuel Oil`[l]<-0 # no more oil
  }

  if (hf2020$`Region`[l] == "Midwest") { # similar rates as West, but a little bit slower in the 2020s
    oil0<-hf2020$`Option=Fuel Oil`[l] 
    gas0<-hf2020$`Option=Natural Gas`[l]
    lpg0<-hf2020$`Option=Propane`[l]
    
    hf2020$`Option=Electricity`[l]<-hf2020$`Option=Electricity`[l]+0.04*gas0+0.04*lpg0+0.15*oil0 # 4% of gas/lpg becomes electric, 15% of oil becomes electric
    hf2020$`Option=Natural Gas`[l]<-0.96*hf2020$`Option=Natural Gas`[l]+0.7*oil0 # 4% of gas becomes electric, 70% of oil becomes gas
    hf2020$`Option=Propane`[l]<-0.96*hf2020$`Option=Propane`[l]+0.1*oil0 # 4% of gas becomes electric, 10% of oil becomes lpg
    hf2020$`Option=Fuel Oil`[l]<-0.05*hf2020$`Option=Fuel Oil`[l] # 70% of oil becomes gas, 15% becomes electric, 10% becomes lpg
    # advanced electrification scenario
    hf2020adv$`Option=Electricity`[l]<-hf2020adv$`Option=Electricity`[l]+0.3*gas0+0.3*lpg0+0.9*oil0 # 30% of gas/lpg becomes electric, 90% of oil becomes electric
    hf2020adv$`Option=Natural Gas`[l]<-0.7*hf2020adv$`Option=Natural Gas`[l]+0.1*oil0 # 30% of gas becomes electric, 10% of oil becomes gas
    hf2020adv$`Option=Propane`[l]<-0.7*hf2020adv$`Option=Propane`[l]# 30% of lpg becomes electric
    hf2020adv$`Option=Fuel Oil`[l]<-0 # no more oil
    
  }
  
  if (hf2020$`Region`[l] == "South") { # higest rate of electrification here.
    gas0<-hf2020$`Option=Natural Gas`[l]
    lpg0<-hf2020$`Option=Propane`[l]
    oil0<-hf2020$`Option=Fuel Oil`[l]
    
    hf2020$`Option=Electricity`[l]<-hf2020$`Option=Electricity`[l]+0.1*gas0+0.1*lpg0+0.9*oil0 # 10% of gas/lpg becomes electric, 90% of oil becomes electric
    hf2020$`Option=Natural Gas`[l]<-0.9*hf2020$`Option=Natural Gas`[l] # 10% of gas becomes electric
    hf2020$`Option=Propane`[l]<-0.9*hf2020$`Option=Propane`[l] # 10% of lpg becomes electric
    hf2020$`Option=Fuel Oil`[l]<-0.1*hf2020$`Option=Fuel Oil`[l] # 90% of oil becomes electric
    # advanced electrification scenario
    hf2020adv$`Option=Electricity`[l]<-hf2020adv$`Option=Electricity`[l]+0.5*gas0+0.5*lpg0+oil0 # 50% of gas/lpg becomes electric, 100% of oil becomes electric
    hf2020adv$`Option=Natural Gas`[l]<-0.5*hf2020adv$`Option=Natural Gas`[l] # 30% of gas becomes electric, 
    hf2020adv$`Option=Propane`[l]<-0.5*hf2020adv$`Option=Propane`[l]# 30% of lpg becomes electric
    hf2020adv$`Option=Fuel Oil`[l]<-0 # no more oil
  }
  
  if (hf2020$`Region`[l] == "West") { # similar rates as MidWest, but a little bit faster in the 2020s
    gas0<-hf2020$`Option=Natural Gas`[l]
    lpg0<-hf2020$`Option=Propane`[l]
    oil0<-hf2020$`Option=Fuel Oil`[l]
    
    hf2020$`Option=Electricity`[l]<-hf2020$`Option=Electricity`[l]+0.05*gas0+0.05*lpg0+0.25*oil0 # 5% of gas/lpg becomes electric, 25% of oil becomes electric
    hf2020$`Option=Natural Gas`[l]<-0.95*hf2020$`Option=Natural Gas`[l]+0.5*oil0 # 5% of gas becomes electric, 50% of oil becomes gas
    hf2020$`Option=Propane`[l]<-0.95*hf2020$`Option=Propane`[l]+0.25*oil0 # 5% of lpg becomes electric, 25% of oil becomes lpg
    hf2020$`Option=Fuel Oil`[l]<-0 # no more oil
    # advanced electrification scenario
    hf2020adv$`Option=Electricity`[l]<-hf2020adv$`Option=Electricity`[l]+0.35*gas0+0.35*lpg0+0.95*oil0 # 35% of gas/lpg becomes electric, 95% of oil becomes electric
    hf2020adv$`Option=Natural Gas`[l]<-0.65*hf2020adv$`Option=Natural Gas`[l]+0.05*oil0 # 35% of gas becomes electric, 5% of oil becomes gas
    hf2020adv$`Option=Propane`[l]<-0.65*hf2020adv$`Option=Propane`[l]# 35% of lpg becomes electric
    hf2020adv$`Option=Fuel Oil`[l]<-0 # no more oil
  }
}
# check if rowsums are  = 1
# hf2020$rs<-rowSums(hf2020[,4:9])
# hf2020adv$rs<-rowSums(hf2020adv[,4:9])
# define 2030s distributions
hf2030<-hf2020
hf2030adv<-hf2020adv
hf2030adv$`Dependency=Vintage`<-hf2030$`Dependency=Vintage`<-"2030s"
for (l in 1:nrow(hf2030)) {
  if (hf2030$`Region`[l] == "Northeast") {  # in the Northeast, the move away from gas is the slowest, due to higher priced electricity
    gas0<-hf2030$`Option=Natural Gas`[l]
    lpg0<-hf2030$`Option=Propane`[l]
    oil0<-hf2030$`Option=Fuel Oil`[l]
    
    hf2030$`Option=Electricity`[l]<-hf2030$`Option=Electricity`[l]+0.07*gas0+0.07*lpg0+0.6*oil0
    hf2030$`Option=Natural Gas`[l]<-0.93*hf2030$`Option=Natural Gas`[l]+0.3*oil0
    hf2030$`Option=Propane`[l]<-0.93*hf2030$`Option=Propane`[l]+0.05*oil0
    hf2030$`Option=Fuel Oil`[l]<-0.05*hf2030$`Option=Fuel Oil`[l]
    # adv elec scenario
    gas0<-hf2030adv$`Option=Natural Gas`[l]
    lpg0<-hf2030adv$`Option=Propane`[l]
    
    hf2030adv$`Option=Electricity`[l]<-hf2030adv$`Option=Electricity`[l]+0.65*gas0+0.65*lpg0
    hf2030adv$`Option=Natural Gas`[l]<-0.35*hf2030adv$`Option=Natural Gas`[l]
    hf2030adv$`Option=Propane`[l]<-0.35*hf2030adv$`Option=Propane`[l]
  }
  
  if (hf2030$`Region`[l] == "Midwest") {
    gas0<-hf2030$`Option=Natural Gas`[l]
    lpg0<-hf2030$`Option=Propane`[l]
    oil0<-hf2030$`Option=Fuel Oil`[l]
    
    hf2030$`Option=Electricity`[l]<-hf2030$`Option=Electricity`[l]+0.1*gas0+0.1*lpg0+0.8*oil0
    hf2030$`Option=Natural Gas`[l]<-0.9*hf2030$`Option=Natural Gas`[l]+0.15*oil0
    hf2030$`Option=Propane`[l]<-0.9*hf2030$`Option=Propane`[l]+0.05*oil0
    hf2030$`Option=Fuel Oil`[l]<-0 # no more oil
    # adv elec scenario
    gas0<-hf2030adv$`Option=Natural Gas`[l]
    lpg0<-hf2030adv$`Option=Propane`[l]
    
    hf2030adv$`Option=Electricity`[l]<-hf2030adv$`Option=Electricity`[l]+gas0+lpg0 # all electric
    hf2030adv$`Option=Natural Gas`[l]<-0 # no more gas
    hf2030adv$`Option=Propane`[l]<-0 # no more lpg
  }
  
  if (hf2030$`Region`[l] == "South") {
    gas0<-hf2030$`Option=Natural Gas`[l]
    lpg0<-hf2030$`Option=Propane`[l]
    oil0<-hf2030$`Option=Fuel Oil`[l]
    
    hf2030$`Option=Electricity`[l]<-hf2030$`Option=Electricity`[l]+0.2*gas0+0.2*lpg0+oil0
    hf2030$`Option=Natural Gas`[l]<-0.8*hf2030$`Option=Natural Gas`[l]
    hf2030$`Option=Propane`[l]<-0.8*hf2030$`Option=Propane`[l]
    hf2030$`Option=Fuel Oil`[l]<-0
    # adv elec scenario
    gas0<-hf2030adv$`Option=Natural Gas`[l]
    lpg0<-hf2030adv$`Option=Propane`[l]
    
    hf2030adv$`Option=Electricity`[l]<-hf2030adv$`Option=Electricity`[l]+gas0+lpg0 # all electric
    hf2030adv$`Option=Natural Gas`[l]<-0 # no more gas
    hf2030adv$`Option=Propane`[l]<-0 # no more lpg
  }
  
  if (hf2030$`Region`[l] == "West") {
    gas0<-hf2030$`Option=Natural Gas`[l]
    lpg0<-hf2030$`Option=Propane`[l]
    
    hf2030$`Option=Electricity`[l]<-hf2030$`Option=Electricity`[l]+0.12*gas0+0.12*lpg0
    hf2030$`Option=Natural Gas`[l]<-0.88*hf2030$`Option=Natural Gas`[l]
    hf2030$`Option=Propane`[l]<-0.88*hf2030$`Option=Propane`[l]
    # adv elec scenario
    gas0<-hf2030adv$`Option=Natural Gas`[l]
    lpg0<-hf2030adv$`Option=Propane`[l]
    
    hf2030adv$`Option=Electricity`[l]<-hf2030adv$`Option=Electricity`[l]+gas0+lpg0 # all electric
    hf2030adv$`Option=Natural Gas`[l]<-0 # no more gas
    hf2030adv$`Option=Propane`[l]<-0 # no more lpg
  }
} 
# check if rowsums are  = 1
# hf2030$rs<-rowSums(hf2030[,4:9])
# hf2030adv$rs<-rowSums(hf2030adv[,4:9])
hf2040<-hf2030
hf2040adv<-hf2030adv
hf2040adv$`Dependency=Vintage`<-hf2040$`Dependency=Vintage`<-"2040s"
for (l in 1:nrow(hf2040)) {
  if (hf2040$`Region`[l] == "Northeast") {
    gas0<-hf2040$`Option=Natural Gas`[l]
    lpg0<-hf2040$`Option=Propane`[l]
    oil0<-hf2040$`Option=Fuel Oil`[l]
    
    hf2040$`Option=Electricity`[l]<-hf2040$`Option=Electricity`[l]+0.1*gas0+0.1*lpg0+oil0
    hf2040$`Option=Natural Gas`[l]<-0.9*hf2040$`Option=Natural Gas`[l]
    hf2040$`Option=Propane`[l]<-0.9*hf2040$`Option=Propane`[l]
    hf2040$`Option=Fuel Oil`[l]<-0 # no more oil
    # adv elec scenario
    gas0<-hf2040adv$`Option=Natural Gas`[l]
    lpg0<-hf2040adv$`Option=Propane`[l]
    
    hf2040adv$`Option=Electricity`[l]<-hf2040adv$`Option=Electricity`[l]+gas0+lpg0 # all electric
    hf2040adv$`Option=Natural Gas`[l]<-0 # no more gas
    hf2040adv$`Option=Propane`[l]<-0 # no more lpg
  }
  
  if (hf2040$`Region`[l] == "Midwest") {
    gas0<-hf2040$`Option=Natural Gas`[l]
    lpg0<-hf2040$`Option=Propane`[l]
    
    hf2040$`Option=Electricity`[l]<-hf2040$`Option=Electricity`[l]+0.15*gas0+0.15*lpg0
    hf2040$`Option=Natural Gas`[l]<-0.85*hf2040$`Option=Natural Gas`[l]
    hf2040$`Option=Propane`[l]<-0.85*hf2040$`Option=Propane`[l]
  }
  
  if (hf2040$`Region`[l] == "South") {
    gas0<-hf2040$`Option=Natural Gas`[l]
    lpg0<-hf2040$`Option=Propane`[l]
    
    hf2040$`Option=Electricity`[l]<-hf2040$`Option=Electricity`[l]+0.25*gas0+0.25*lpg0
    hf2040$`Option=Natural Gas`[l]<-0.75*hf2040$`Option=Natural Gas`[l]
    hf2040$`Option=Propane`[l]<-0.75*hf2040$`Option=Propane`[l]
  }
  
  if (hf2040$`Region`[l] == "West") {
    gas0<-hf2040$`Option=Natural Gas`[l]
    lpg0<-hf2040$`Option=Propane`[l]
    
    hf2040$`Option=Electricity`[l]<-hf2040$`Option=Electricity`[l]+0.15*gas0+0.15*lpg0
    hf2040$`Option=Natural Gas`[l]<-0.85*hf2040$`Option=Natural Gas`[l]
    hf2040$`Option=Propane`[l]<-0.85*hf2040$`Option=Propane`[l]
  }
} 
# check if rowsums are  = 1
# hf2040$rs<-rowSums(hf2040[,4:9])
# hf2040adv$rs<-rowSums(hf2040adv[,4:9])
hf2050<-hf2040
hf2050adv<-hf2040adv
hf2050adv$`Dependency=Vintage`<-hf2050$`Dependency=Vintage`<-"2050s"
for (l in 1:nrow(hf2050)) {
  if (hf2050$`Region`[l] == "Northeast") {
    gas0<-hf2050$`Option=Natural Gas`[l]
    lpg0<-hf2050$`Option=Propane`[l]
    
    hf2050$`Option=Electricity`[l]<-hf2050$`Option=Electricity`[l]+0.12*gas0+0.12*lpg0
    hf2050$`Option=Natural Gas`[l]<-0.88*hf2050$`Option=Natural Gas`[l]
    hf2050$`Option=Propane`[l]<-0.88*hf2050$`Option=Propane`[l]
  }
  
  if (hf2050$`Region`[l] == "Midwest") {
    gas0<-hf2050$`Option=Natural Gas`[l]
    lpg0<-hf2050$`Option=Propane`[l]
    
    hf2050$`Option=Electricity`[l]<-hf2050$`Option=Electricity`[l]+0.2*gas0+0.2*lpg0
    hf2050$`Option=Natural Gas`[l]<-0.8*hf2050$`Option=Natural Gas`[l]
    hf2050$`Option=Propane`[l]<-0.8*hf2050$`Option=Propane`[l]
  }
  
  if (hf2050$`Region`[l] == "South") {
    gas0<-hf2050$`Option=Natural Gas`[l]
    lpg0<-hf2050$`Option=Propane`[l]
    
    hf2050$`Option=Electricity`[l]<-hf2050$`Option=Electricity`[l]+0.4*gas0+0.4*lpg0
    hf2050$`Option=Natural Gas`[l]<-0.6*hf2050$`Option=Natural Gas`[l]
    hf2050$`Option=Propane`[l]<-0.6*hf2050$`Option=Propane`[l]
  }
  
  if (hf2050$`Region`[l] == "West") {
    gas0<-hf2050$`Option=Natural Gas`[l]
    lpg0<-hf2050$`Option=Propane`[l]
    
    hf2050$`Option=Electricity`[l]<-hf2050$`Option=Electricity`[l]+0.2*gas0+0.2*lpg0
    hf2050$`Option=Natural Gas`[l]<-0.8*hf2050$`Option=Natural Gas`[l]
    hf2050$`Option=Propane`[l]<-0.8*hf2050$`Option=Propane`[l]
  }
} 
# check if rowsums are  = 1
# hf2050$rs<-rowSums(hf2050[,4:9])
# hf2050adv$rs<-rowSums(hf2050adv[,4:9])
# now save the new heat fuel files complete with new 2020 characteristics
hf_new<-as.data.frame(rbind(hf,hf2020[,1:9])) # 
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s ceff
hf_new<-as.data.frame(rbind(hf,hf2020[,1:9],hf2030[,1:9])) 
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s hf
hf_new<-as.data.frame(rbind(hf,hf2020[,1:9],hf2030[,1:9],hf2040[,1:9])) 
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s hf
hf_new<-as.data.frame(rbind(hf,hf2020[,1:9],hf2030[,1:9],hf2040[,1:9],hf2050[,1:9])) 
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save advanced elec chars
hf_new<-as.data.frame(rbind(hf,hf2020adv[,1:9])) # 
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s ceff
hf_new<-as.data.frame(rbind(hf,hf2020adv[,1:9],hf2030adv[,1:9]))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s hf
hf_new<-as.data.frame(rbind(hf,hf2020adv[,1:9],hf2030adv[,1:9],hf2040adv[,1:9]))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s hf
hf_new<-as.data.frame(rbind(hf,hf2020adv[,1:9],hf2030adv[,1:9],hf2040adv[,1:9],hf2050adv[,1:9]))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/Heating Fuel.tsv',sep = "")
  write.table(format(hf_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Hot Water Distribution #############
hwd<-read_tsv('../project_national/housing_characteristics/Hot Water Distribution.tsv',col_names = TRUE)
hwd<-hwd[1:9,]
hwd2020<-hwd[hwd$`Dependency=Vintage`=="2010s",]
hwd2020$`Dependency=Vintage`<-"2020s"
hwd2020$`Option=R-2, HomeRun, PEX`<-0.25 # add insulated option, assume 25% of buildings covered in 2020s
hwd2020$`Option=Uninsulated, HomeRun, PEX`<-0.75
# define 30s-50s as same as 2020s
hwd2030<-hwd2040<-hwd2050<-hwd2020
# define vintage names
hwd2030$`Dependency=Vintage`<-"2030s"
hwd2040$`Dependency=Vintage`<-"2040s"

# make changes here for each vintage depending on adoption of IECC 2015 or higher, will need to aggregate to national average values.
hwd2030$`Option=R-2, HomeRun, PEX`<-0.5 # assume 50% of buildings covered in 2030s
hwd2030$`Option=Uninsulated, HomeRun, PEX`<-0.5

hwd2040$`Option=R-2, HomeRun, PEX`<-1 # assume 100% of buildings covered in 2040s
hwd2040$`Option=Uninsulated, HomeRun, PEX`<-0

hwd2050<-hwd2040
hwd2050$`Dependency=Vintage`<-"2050s"

hwd$`Option=R-2, HomeRun, PEX`<-0
# then save the new heat fuel file complete with new 2020 characteristics
hwd_new<-as.data.frame(rbind(hwd,hwd2020,hwd2030,hwd2040,hwd2050))
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Hot Water Distribution.tsv',sep = "")
  write.table(format(hwd_new,nsmall=6,digits=1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Infiltration ######
inf<-read_tsv('../project_national/housing_characteristics/Infiltration.tsv',col_names = TRUE)
inf<-inf[1:1215,]
inf2020<-inf[inf$`Dependency=Vintage`=="2010s",]
inf2020$`Dependency=Vintage`<-"2020s"

# make changes to 2020 infiltration here, I will be making changes here, to reflect the reduction of ACH50 to about 3-5 in homes with IECC 2015 or higher
# which CZ make it to IECC 2015 by the 2020s? 4C, 4A, 2A, 3B and 3C.
# IECC 2015 defines ACH<5 in CZ 1 and 2, and ACH<3 in other CZ.
for (l in 1:nrow(inf2020)) {
  if(inf2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="1A"|inf2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="2A") {
    inf2020[l,9:18]<-0 # turn all ach of 6 and higher to 0. Still allow some units to have ACH==5, to reflect imperfect code adoption and enforcement
    inf2020[l,4:8]<-inf2020[l,4:8]/sum(inf2020[l,4:8]) # distribute all units to ach 1:5 based on their current distribution
  }
  if(inf2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="3B"|inf2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="3C"|inf2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="4A"|inf2020$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="4C") {
    inf2020[l,7:18]<-0 # turn all ach of 4 and higher to 0 Still allow some units to have ACH==3, to reflect imperfect code adoption and enforcement
    inf2020[l,4:6]<-inf2020[l,4:6]/sum(inf2020[l,4:6]) # distribute all units to ach 1:3 based on their current distribution
  }
}
inf2030<-inf2020
inf2030$`Dependency=Vintage`<-"2030s"
# in the 2030s, 6A, 5A, 5B also have at least IECC 2015 applied
for (l in 1:nrow(inf2030)) {
  if(inf2030$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="5A"|inf2030$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="5B"|inf2030$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="6A") {
      inf2030[l,7:18]<-0 # turn all ach of 4 and higher to 0 Still allow some units to have ACH==3, to reflect imperfect code adoption and enforcement
      inf2030[l,4:6]<-inf2030[l,4:6]/sum(inf2030[l,4:6]) # distribute all units to ach 1:3 based on their current distribution
  }
}

inf2040<-inf2030
inf2040$`Dependency=Vintage`<-"2040s"
# in the 2040s, 2B and 3A, 4B, 6B and 7 also join the club. 
ach3zones<-c("3A","4B","6B","7A","7B")
for (l in 1:nrow(inf2040)) {
  if(inf2040$`Dependency=ASHRAE IECC Climate Zone 2004`[l]=="2B") {
    inf2040[l,9:18]<-0 # turn all ach of 6 and higher to 0. Still allow some units to have ACH==5, to reflect imperfect code adoption and enforcement
    inf2040[l,4:8]<-inf2040[l,4:8]/sum(inf2040[l,4:8]) # distribute all units to ach 1:5 based on their current distribution
  }
  if(inf2040$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% ach3zones) {
    inf2040[l,7:18]<-0 # turn all ach of 4 and higher to 0 Still allow some units to have ACH==3, to reflect imperfect code adoption and enforcement
    inf2040[l,4:6]<-inf2040[l,4:6]/sum(inf2040[l,4:6]) # distribute all units to ach 1:3 based on their current distribution
  }
}

inf2050<-inf2040
inf2050$`Dependency=Vintage`<-"2050s"
# climate zones which are required to have either ach3 or ach5 in IECC 2015 and higher
ach3zones<-c("3A","3B","3C","4A","4B","4C","5A","5B","6A","6B","7A","7B")
ach5zones<-c("1A","2A","2B")

for (l in 1:nrow(inf2050)) {
  if(inf2050$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% ach5zones) {
    inf2050[l,8:18]<-0 # turn all ach of 5 and higher to 0. This reflects increased stringency and better enforcement of codes
    inf2050[l,4:7]<-inf2050[l,4:7]/sum(inf2050[l,4:7]) # distribute all units to ach 1:5 based on their current distribution
  }
  if(inf2050$`Dependency=ASHRAE IECC Climate Zone 2004`[l] %in% ach3zones) {
    inf2050[l,6:18]<-0 # turn all ach of 4 and higher to 0 Still allow some units to have ACH==3, to reflect imperfect code adoption and enforcement
    inf2050[l,4:5]<-inf2050[l,4:5]/sum(inf2050[l,4:5]) # distribute all units to ach 1:3 based on their current distribution
  }
}

# then save the new infiltration file complete with new 2020 characteristics
inf_new<-as.data.frame(rbind(inf,inf2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Infiltration.tsv',sep = "")
  write.table(format(inf_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s inf
inf_new<-as.data.frame(rbind(inf,inf2020,inf2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Infiltration.tsv',sep = "")
  write.table(format(inf_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s inf
inf_new<-as.data.frame(rbind(inf,inf2020,inf2030,inf2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Infiltration.tsv',sep = "")
  write.table(format(inf_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s inf
inf_new<-as.data.frame(rbind(inf,inf2020,inf2030,inf2040,inf2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Infiltration.tsv',sep = "")
  write.table(format(inf_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Crawlspace ############
# no diff b/w IECC 2015 and IECC 2021
incr<-read_tsv('../project_national/housing_characteristics/Insulation Crawlspace.tsv',col_names = TRUE)
incr<-incr[1:2250,] # remove comment row
incr2020<-incr[incr$`Dependency=Vintage`=="2010s",]
incr2020$`Dependency=Vintage`<-"2020s"

# make changes to 2020 insulation here
# first add new insulation option. This required addition to options lookup (R15, Unvented). This refers to rigid continuous insulation levels
incr$`Option=Wall R-15, Unvented`<-incr2020$`Option=Wall R-15, Unvented`<-0
incr2020<-incr2020[,c(1:7,11,8:10)] # bring the new option into the right place (column)
incr<-incr[,c(1:7,11,8:10)] # bring the new option into the right place (column)
# which resstock custom regions make it to IECC 2015 by 2020s? CR3 (CZ5A), CR6 (CZ4C), CR11 (CZ3C), as well as the states TX, FL, NY, NE, DE, MD (these will be adjusted in the bs.csv)
# in CZ 3 make sure insulation is at least R-5
for (l in 1:nrow(incr2020)) {
  if (incr2020$`Dependency=Location Region`[l]=="CR11") { # climate zone 3c
    unin<-incr2020$`Option=Uninsulated, Vented`[l]
    incr2020$`Option=Wall R-5, Unvented`[l]<-incr2020$`Option=Wall R-5, Unvented`[l]+unin # add the uninsulated fraction to the min allowable level
    incr2020$`Option=Uninsulated, Vented`[l]<-0
  }
  if (incr2020$`Dependency=Location Region`[l]=="CR06"|incr2020$`Dependency=Location Region`[l]=="CR03") { # climate zone 4C (marine) and 5a
    unvent<-sum(incr2020[l,6:7])
    vent<-sum(incr2020[l,c(5,9,10)])
    incr2020$`Option=Wall R-15, Unvented`[l]<-unvent # make all unvented the mim allowable level
    incr2020[l,6:7]<-0
    incr2020$`Option=Ceiling R-19, Vented`[l]<-vent # make all vented the mim allowable level
    incr2020[l,c(5,9)]<-0
  }
}
incr2030<-incr2020
incr2030$`Dependency=Vintage`<-"2030s"
# which resstock custom regions make it to IECC 2015 by 2030s? CR2 (CZ6A), CR4 (CZ5A), CR5 (CZ5B), CR7 (CZ 5A)
for (l in 1:nrow(incr2030)) {
# all are in CZ 5 or 6, same regulations apply
  if (incr2030$`Dependency=Location Region`[l]=="CR02"|incr2030$`Dependency=Location Region`[l]=="CR04"|incr2030$`Dependency=Location Region`[l]=="CR05"|incr2030$`Dependency=Location Region`[l]=="CR07") { 
    unvent<-sum(incr2030[l,6:7])
    vent<-sum(incr2030[l,c(5,9,10)])
    incr2030$`Option=Wall R-15, Unvented`[l]<-unvent # make all unvented the mim allowable level
    incr2030[l,6:7]<-0
    incr2030$`Option=Ceiling R-19, Vented`[l]<-vent # make all vented the mim allowable level
    incr2030[l,c(5,9)]<-0
  }
}
incr2040<-incr2030
incr2040$`Dependency=Vintage`<-"2040s"
# which resstock custom regions make it to IECC 2015 by 2040s? CR08 (CZ4A), CR9 (CZ 3A) CR10 (CZ2A). No restriction for CR10 (CZ 2A)
for (l in 1:nrow(incr2040)) {
  if (incr2040$`Dependency=Location Region`[l]=="CR09") { # climate zone 3c
    unin<-incr2040$`Option=Uninsulated, Vented`[l]
    incr2040$`Option=Wall R-5, Unvented`[l]<-incr2040$`Option=Wall R-5, Unvented`[l]+unin # add the uninsulated fraction to the min allowable level
    incr2040$`Option=Uninsulated, Vented`[l]<-0
  }
  if (incr2040$`Dependency=Location Region`[l]=="CR08") { # cz 4
    unin<-incr2040$`Option=Uninsulated, Vented`[l]
    incr2040$`Option=Ceiling R-13, Vented`[l]<-incr2040$`Option=Ceiling R-13, Vented`[l]+unin # add the uninsulated fraction to the min allowable level, keep vented
    incr2040$`Option=Uninsulated, Vented`[l]<-0 # turn the uninsulated fraction to 0
    incr2040$`Option=Wall R-10, Unvented`[l]<-incr2040$`Option=Wall R-10, Unvented`[l]+incr2040$`Option=Wall R-5, Unvented`[l] # make all unvented at least R-10
    incr2040$`Option=Wall R-5, Unvented`[l]<-0 # turn the R5 fraction to 0
  }
}
incr2050<-incr2040
incr2050$`Dependency=Vintage`<-"2050s"
# for 2050s, we don't know about code changes, but we reflect increased code stringency and adoption by increasing the most efficient option by 50% of the other options
for (l in 1:nrow(incr2050)) {
  incr2050$`Option=Wall R-15, Unvented`[l]<-incr2050$`Option=Wall R-15, Unvented`[l]+0.5*incr2050$`Option=Wall R-5, Unvented`[l]+0.5*incr2050$`Option=Wall R-10, Unvented`[l]
  incr2050$`Option=Wall R-5, Unvented`[l]<-0.5*incr2050$`Option=Wall R-5, Unvented`[l]
  incr2050$`Option=Wall R-10, Unvented`[l]<-0.5*incr2050$`Option=Wall R-10, Unvented`[l]
  
  incr2050$`Option=Ceiling R-19, Vented`[l]<-incr2050$`Option=Ceiling R-19, Vented`[l]+0.5*incr2050$`Option=Ceiling R-13, Vented`[l]
  incr2050$`Option=Ceiling R-13, Vented`[l]<-0.5*incr2050$`Option=Ceiling R-13, Vented`[l]
}

# then save the new incr file complete with new 2020 characteristics
incr_new<-as.data.frame(rbind(incr,incr2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Crawlspace.tsv',sep = "")
  write.table(format(incr_new,nsmall=6,digits=1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2030s incr
incr_new<-as.data.frame(rbind(incr,incr2020,incr2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Crawlspace.tsv',sep = "")
  write.table(format(incr_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s incr
incr_new<-as.data.frame(rbind(incr,incr2020,incr2030,incr2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Crawlspace.tsv',sep = "")
  write.table(format(incr_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s incr
incr_new<-as.data.frame(rbind(incr,incr2020,incr2030,incr2040,incr2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Crawlspace.tsv',sep = "")
  write.table(format(incr_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Finished Basement ############
# no diff b/w IECC 2015 and 2021
infb<-read_tsv('../project_national/housing_characteristics/Insulation Finished Basement.tsv',col_names = TRUE)
infb<-infb[1:2250,] # remove comment row
infb2020<-infb[infb$`Dependency=Vintage`=="2010s",]
infb2020$`Dependency=Vintage`<-"2020s"

# make changes to 2020 insulation here. requirements are same as for crawlspace
# which resstock custom regions make it to IECC 2015 by 2020s? CR3 (CZ5A), CR6 (CZ4C), CR11 (CZ3C), as well as the states TX, FL, NY, NE, DE, MD (these will be adjusted in the bs.csv)
# in CZ 3 make sure insulation is at least R-5
for (l in 1:nrow(infb2020)) {
  if (infb2020$`Dependency=Location Region`[l]=="CR11" &infb2020$`Dependency=Geometry Foundation Type`[l]=="Heated Basement") { # climate zone 3c
    unin<-infb2020$`Option=Uninsulated`[l]
    infb2020$`Option=Wall R-5`[l]<-infb2020$`Option=Wall R-5`[l]+unin # add the uninsulated fraction to the min allowable level
    infb2020$`Option=Uninsulated`[l]<-0
  }
  if ((infb2020$`Dependency=Location Region`[l]=="CR06"|infb2020$`Dependency=Location Region`[l]=="CR03")&infb2020$`Dependency=Geometry Foundation Type`[l]=="Heated Basement") { # climate zone 4C (marine) and 5a
      infb2020[l,5:7]<-0
      infb2020$`Option=Wall R-15`[l]<-1 # make all insulation the min allowable level
   }
}
infb2030<-infb2020
infb2030$`Dependency=Vintage`<-"2030s" 
# which resstock custom regions make it to IECC 2015 by 2030s? CR2 (CZ6A), CR4 (CZ5A), CR5 (CZ5B), CR7 (CZ 5A)
for (l in 1:nrow(infb2030)) {
  # all are in CZ 5 or 6, same regulations apply
  if ((infb2030$`Dependency=Location Region`[l]=="CR02"|infb2030$`Dependency=Location Region`[l]=="CR04"|infb2030$`Dependency=Location Region`[l]=="CR05"|infb2030$`Dependency=Location Region`[l]=="CR07")&infb2020$`Dependency=Geometry Foundation Type`[l]=="Heated Basement") { 
    infb2030[l,5:7]<-0
    infb2030$`Option=Wall R-15`[l]<-1 # make all insulation the min allowable level
  }
}
infb2040<-infb2030
infb2040$`Dependency=Vintage`<-"2040s"
# which resstock custom regions make it to IECC 2015 by 2040s? CR08 (CZ4A), CR9 (CZ 3A) CR10 (CZ2A). No restriction for CR10 (CZ 2A)
for (l in 1:nrow(infb2040)) {
  if (infb2040$`Dependency=Location Region`[l]=="CR09"&infb2040$`Dependency=Geometry Foundation Type`[l]=="Heated Basement") { # climate zone 3a
    unin<-infb2040$`Option=Uninsulated`[l]
    infb2040$`Option=Wall R-5`[l]<-infb2040$`Option=Wall R-5`[l]+unin # add the uninsulated fraction to the min allowable level
    infb2040$`Option=Uninsulated`[l]<-0
  }
  if (infb2040$`Dependency=Location Region`[l]=="CR08"&infb2040$`Dependency=Geometry Foundation Type`[l]=="Heated Basement") { # cz 4a
    infb2040$`Option=Wall R-10`[l]<-infb2040$`Option=Wall R-10`[l]+infb2040$`Option=Wall R-5`[l]+infb2040$`Option=Uninsulated`[l] # make all insulation at least R-10
    infb2040$`Option=Wall R-5`[l]<-infb2040$`Option=Uninsulated`[l]<-0 # turn the R5 and uninsulated fractions to 0
  }
}
infb2050<-infb2040
infb2050$`Dependency=Vintage`<-"2050s"
# for 2050s, we don't know about code changes, but we reflect increased code stringency and adoption by increasing the most efficient option by 50% of the other options
for (l in 1:nrow(infb2050)) {
  infb2050$`Option=Wall R-15`[l]<-infb2050$`Option=Wall R-15`[l]+0.5*infb2050$`Option=Wall R-5`[l]+0.5*infb2050$`Option=Wall R-10`[l]
  infb2050$`Option=Wall R-5`[l]<-0.5*infb2050$`Option=Wall R-5`[l]
  infb2050$`Option=Wall R-10`[l]<-0.5*infb2050$`Option=Wall R-10`[l]
}
# then save the new infb file complete with new 2020 characteristics
infb_new<-as.data.frame(rbind(infb,infb2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Basement.tsv',sep = "")
  write.table(format(infb_new,nsmall=6,digits=1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2030s infb
infb_new<-as.data.frame(rbind(infb,infb2020,infb2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Basement.tsv',sep = "")
  write.table(format(infb_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s infb
infb_new<-as.data.frame(rbind(infb,infb2020,infb2030,infb2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Basement.tsv',sep = "")
  write.table(format(infb_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s infb
infb_new<-as.data.frame(rbind(infb,infb2020,infb2030,infb2040,infb2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Basement.tsv',sep = "")
  write.table(format(infb_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Interzonal Floor #############  no changes
inif<-read_tsv('../project_national/housing_characteristics/Insulation Interzonal Floor.tsv',col_names = TRUE)
inif<-inif[1:90,]
inif2020<-inif[inif$`Dependency=Vintage`=="2010s",]
inif2020$`Dependency=Vintage`<-"2020s"

# define hvac characteristics in 2030s 2040s and 2050s as the same as those in 2020s
inif2030<-inif2040<-inif2050<-inif2020
# define vintage names
inif2030$`Dependency=Vintage`<-"2030s"
inif2040$`Dependency=Vintage`<-"2040s"
inif2050$`Dependency=Vintage`<-"2050s"

# save 2020s inif
inif_new<-as.data.frame(rbind(inif,inif2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Interzonal Floor.tsv',sep = "")
  write.table(format(inif_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s inif
inif_new<-as.data.frame(rbind(inif,inif2020,inif2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Interzonal Floor.tsv',sep = "")
  write.table(format(inif_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s inif
inif_new<-as.data.frame(rbind(inif,inif2020,inif2030,inif2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Interzonal Floor.tsv',sep = "")
  write.table(format(inif_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s inif
inif_new<-as.data.frame(rbind(inif,inif2020,inif2030,inif2040,inif2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Interzonal Floor.tsv',sep = "")
  write.table(format(inif_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Pier Beam ################ # no changes
inpb<-read_tsv('../project_national/housing_characteristics/Insulation Pier Beam.tsv',col_names = TRUE)
inpb<-inpb[1:2250,] # remove comments
inpb2020<-inpb[inpb$`Dependency=Vintage`=="2010s",]
inpb2020$`Dependency=Vintage`<-"2020s"

# initially define inpb made in 2030s 2040s and 2050s as the same as those made in 2020s
inpb2030<-inpb2040<-inpb2050<-inpb2020
# define vintage names
inpb2030$`Dependency=Vintage`<-"2030s"
inpb2040$`Dependency=Vintage`<-"2040s"
inpb2050$`Dependency=Vintage`<-"2050s"

# save 2020s inpb
inpb_new<-as.data.frame(rbind(inpb,inpb2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Pier Beam.tsv',sep = "")
  write.table(format(inpb_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s inpb
inpb_new<-as.data.frame(rbind(inpb,inpb2020,inpb2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Pier Beam.tsv',sep = "")
  write.table(format(inpb_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2040s inpb
inpb_new<-as.data.frame(rbind(inpb,inpb2020,inpb2030,inpb2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Pier Beam.tsv',sep = "")
  write.table(format(inpb_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2050s inpb
inpb_new<-as.data.frame(rbind(inpb,inpb2020,inpb2030,inpb2040,inpb2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Pier Beam.tsv',sep = "")
  write.table(format(inpb_new,nsmall=6,digits = 1, scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Slab ###########
# some changes b/w/ IECC 2015 and IECC 2021
insl<-read_tsv('../project_national/housing_characteristics/Insulation Slab.tsv',col_names = TRUE)
insl<-insl[1:2250,] # remove comments
insl2020<-insl[insl$`Dependency=Vintage`=="2010s",]
insl2020$`Dependency=Vintage`<-"2020s"
# make changes to 2020 insulation here
# add new options, also added in options lookup
insl2020$`Option=4ft R10 Perimeter, R10 Gap`<-insl2020$`Option=4ft R10 Exterior`<-0
insl$`Option=4ft R10 Perimeter, R10 Gap`<-insl$`Option=4ft R10 Exterior`<-0
insl2020<-insl2020[,c(1:7,12,8,9,11,10)] # reorder columns
insl<-insl[,c(1:7,12,8,9,11,10)] # reorder columns
# which resstock custom regions make it to IECC 2015 by 2020s? CR3 (CZ5A), CR6 (CZ4C), CR11 (CZ3C), as well as the states TX, FL, NY, NE, DE, MD (these will be adjusted in the bs.csv)
# no code requirement for climate zone 3
for (l in 1:nrow(insl2020)) {
  if ((insl2020$`Dependency=Location Region`[l]=="CR06"|insl2020$`Dependency=Location Region`[l]=="CR03")&insl2020$`Dependency=Geometry Foundation Type`[l]=="Slab") { # climate zone 4C (marine) and 5a
    insl2020$`Option=2ft R10 Exterior`[l]<-insl2020$`Option=2ft R10 Exterior`[l]+insl2020$`Option=Uninsulated`[l] # set all the uninsulated to the min level, R10 2ft
    insl2020$`Option=Uninsulated`[l]<-0
  }
}
insl2030<-insl2020
insl2030$`Dependency=Vintage`<-"2030s" 
# which resstock custom regions make it to IECC 2015 by 2030s? CR2 (CZ6A), CR4 (CZ5A), CR5 (CZ5B), CR7 (CZ 5A). 
# which regions make it to IECC 2021? CR6 (CZ 4C), CR11 (CZ 3C) plus the rogue states. Change these to 4ft + R-10, except for CR11, which goes to 2ft + 10
for (l in 1:nrow(insl2030)) { # cz 5, all below 2ft R-10 go to 2ft R-10
  if ((insl2030$`Dependency=Location Region`[l]=="CR04"|insl2030$`Dependency=Location Region`[l]=="CR05"|insl2030$`Dependency=Location Region`[l]=="CR07")&insl2020$`Dependency=Geometry Foundation Type`[l]=="Slab") { 
      insl2030$`Option=2ft R10 Perimeter, R10 Gap`[l]<-insl2030$`Option=2ft R10 Perimeter, R10 Gap`[l]+insl2030$`Option=2ft R5 Perimeter, R5 Gap`[l] # set all perimeter and gap to R10
      insl2030$`Option=2ft R5 Perimeter, R5 Gap`[l]<-0
      
      insl2030$`Option=2ft R10 Exterior`[l]<-insl2030$`Option=2ft R10 Exterior`[l]+insl2030$`Option=2ft R5 Exterior`[l]+insl2030$`Option=Uninsulated`[l] # set all exterior, and insulated, to R10
      insl2030$`Option=2ft R5 Exterior`[l]<-insl2030$`Option=Uninsulated`[l]<-0
  }
  # cz 6, and cz 4c (2021). all go to 4ft R-10
  if ((insl2030$`Dependency=Location Region`[l]=="CR02"|insl2030$`Dependency=Location Region`[l]=="CR06" )&insl2020$`Dependency=Geometry Foundation Type`[l]=="Slab") { 
      insl2030[l,5:12]<-0 # first set all to 0
      # then set att to 4ft R10, based on the current mix of perimeter/gap insulation and exterior insulation
      insl2030$`Option=4ft R10 Perimeter, R10 Gap`[l]<-0.15
      insl2030$`Option=4ft R10 Exterior`[l]<-0.85
  }
  if ((insl2030$`Dependency=Location Region`[l]=="CR11" )&insl2020$`Dependency=Geometry Foundation Type`[l]=="Slab") { 
    insl2030[l,5:12]<-0 # first set all to 0
    # then set att to 4ft R10, based on the current mix of perimeter/gap insulation and exterior insulation
    insl2030$`Option=4ft R10 Perimeter, R10 Gap`[l]<-0.5
    insl2030$`Option=4ft R10 Exterior`[l]<-0.5
  }
  
}
insl2040<-insl2030
insl2040$`Dependency=Vintage`<-"2040s"

# which resstock custom regions make it to IECC 2015 by 2040s? CR08 (CZ4A), CR9 (CZ 3A) CR10 (CZ2A). No restriction for CR10 (CZ 2A) or CR9 (CZ 3A)
# which makes is to IECC 2021? CR3 (5A), goes to 4ft + 10
for (l in 1:nrow(insl2040)) {
  if (insl2040$`Dependency=Location Region`[l]=="CR08"&insl2040$`Dependency=Geometry Foundation Type`[l]=="Slab") { # cz 4
    insl2040$`Option=2ft R10 Perimeter, R10 Gap`[l]<-insl2040$`Option=2ft R10 Perimeter, R10 Gap`[l]+insl2040$`Option=2ft R5 Perimeter, R5 Gap`[l] # set all perimeter and gap to R10
    insl2040$`Option=2ft R5 Perimeter, R5 Gap`[l]<-0
    
    insl2040$`Option=2ft R10 Exterior`[l]<-insl2040$`Option=2ft R10 Exterior`[l]+insl2040$`Option=2ft R5 Exterior`[l]+insl2040$`Option=Uninsulated`[l] # set all exterior, and insulated, to R10
    insl2040$`Option=2ft R5 Exterior`[l]<-insl2040$`Option=Uninsulated`[l]<-0
  }
  if ((insl2040$`Dependency=Location Region`[l]=="CR11" )&insl2020$`Dependency=Geometry Foundation Type`[l]=="Slab") { 
    insl2040[l,5:12]<-0 # first set all to 0
    # then set att to 4ft R10, based on the current mix of perimeter/gap insulation and exterior insulation
    insl2040$`Option=4ft R10 Perimeter, R10 Gap`[l]<-0.5
    insl2040$`Option=4ft R10 Exterior`[l]<-0.5
  }
}
insl2050<-insl2040
insl2050$`Dependency=Vintage`<-"2050s"
# who makes it to 2021 in the 2050s? CR4 (CZ5), CR5 (CZ5), CR7 (CZ5), CR9 (CZ3), CZ10 (CZ2). CZ2 has no restriction. CZ3 goes to 2ft R-10, CZ5 goes to 4ft, R-10
for (l in 1:nrow(insl2050)) {
  if (insl2050$`Dependency=Location Region`[l]=="CR09"&insl2050$`Dependency=Geometry Foundation Type`[l]=="Slab") { # cz 4
    insl2050$`Option=2ft R10 Perimeter, R10 Gap`[l]<-insl2050$`Option=2ft R10 Perimeter, R10 Gap`[l]+insl2050$`Option=2ft R5 Perimeter, R5 Gap`[l] # set all perimeter and gap to R10
    insl2050$`Option=2ft R5 Perimeter, R5 Gap`[l]<-0
    
    insl2050$`Option=2ft R10 Exterior`[l]<-insl2050$`Option=2ft R10 Exterior`[l]+insl2050$`Option=2ft R5 Exterior`[l]+insl2050$`Option=Uninsulated`[l] # set all exterior, and insulated, to R10
    insl2050$`Option=2ft R5 Exterior`[l]<-insl2050$`Option=Uninsulated`[l]<-0
  }
  if ((insl2050$`Dependency=Location Region`[l]=="CR04"|insl2050$`Dependency=Location Region`[l]=="CR05"|insl2050$`Dependency=Location Region`[l]=="CR07")&insl2020$`Dependency=Geometry Foundation Type`[l]=="Slab") { 
    insl2050[l,5:12]<-0 # first set all to 0
    # then set att to 4ft R10, based on the current mix of perimeter/gap insulation and exterior insulation
    insl2050$`Option=4ft R10 Perimeter, R10 Gap`[l]<-0.5
    insl2050$`Option=4ft R10 Exterior`[l]<-0.5
  }
}

# no other changes to 2050s
# then save the new infiltration file complete with new 2020 characteristics
insl_new<-as.data.frame(rbind(insl,insl2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Slab.tsv',sep = "")
  write.table(format(insl_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s insl
insl_new<-as.data.frame(rbind(insl,insl2020,insl2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Slab.tsv',sep = "")
  write.table(format(insl_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2040s insl
insl_new<-as.data.frame(rbind(insl,insl2020,insl2030,insl2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Slab.tsv',sep = "")
  write.table(format(insl_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2050s insl
insl_new<-as.data.frame(rbind(insl,insl2020,insl2030,insl2040,insl2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Slab.tsv',sep = "")
  write.table(format(insl_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Unfinished Attic ############
inua<-read_tsv('../project_national/housing_characteristics/Insulation Unfinished Attic.tsv',col_names = TRUE)
inua<-inua[1:450,]
inua2020<-inua[inua$`Dependency=Vintage`=="2010s",]
inua2020$`Dependency=Vintage`<-"2020s"

# make changes to 2020 insulation here, I will be making changes here
# first add option for R-60 insulation (only used from the 2021 code onwards). Already exists in options lookup so no need for changes there
inua$`Option=Ceiling R-60, Vented`<-inua2020$`Option=Ceiling R-60, Vented`<-0
# which resstock custom regions make it to IECC 2015 by 2020s? CR3 (CZ5A), CR6 (CZ4C), CR11 (CZ3C), as well as the states TX, FL, NY, NE, DE, MD (these will be adjusted in the bs.csv)
for (l in 1:nrow(inua2020)) {
  if (inua2020$`Dependency=Location Region`[l]=="CR11") { # climate zone 3c
      inua2020$`Option=Ceiling R-38, Vented`[l]<-sum(inua2020[l,5:10]) # set R-38 to the sum of all 0 - R38
      inua2020[l,5:9]<-0 # set all below R-38 to 0
  }
  if ((inua2020$`Dependency=Location Region`[l]=="CR06"|inua2020$`Dependency=Location Region`[l]=="CR03")) { # climate zone 4C (marine) and 5a
    inua2020$`Option=Ceiling R-49, Vented`[l]<-sum(inua2020[l,5:11]) # set all to R-49
    inua2020[l,5:10]<-0 # set all below R-49 to 0
  }
}
inua2030<-inua2020
inua2030$`Dependency=Vintage`<-"2030s" 
# which resstock custom regions make it to IECC 2015 by 2030s? CR2 (CZ6A), CR4 (CZ5A), CR5 (CZ5B), CR7 (CZ 5A). All require R-49
# which regions makes it to 2021? CR6 (CZ 4C) requires R-60, CR11 (CZ 3C) require R-49, and the rogue states (TX, FL, NY, NE, DE, MD )
for (l in 1:nrow(inua2030)) {
  # all are in CZ 5 or 6, same regulations apply
  if (inua2030$`Dependency=Location Region`[l]=="CR02"|inua2030$`Dependency=Location Region`[l]=="CR04"|inua2030$`Dependency=Location Region`[l]=="CR05"|
      inua2030$`Dependency=Location Region`[l]=="CR07"|inua2030$`Dependency=Location Region`[l]=="CR11") { 
    inua2030$`Option=Ceiling R-49, Vented`[l]<-sum(inua2030[l,5:11]) # set all to R-49
    inua2030[l,5:10]<-0 # set all below R-49 to 0
  }
  if (inua2030$`Dependency=Location Region`[l]=="CR06") {
    inua2030$`Option=Ceiling R-60, Vented`[l]<-sum(inua2030[l,5:12]) # set all to R-60
    inua2030[l,5:11]<-0 # set all below R-60 to 0
  }
}
inua2040<-inua2030
inua2040$`Dependency=Vintage`<-"2040s"
# which resstock custom regions make it to IECC 2015 by 2040s? CR08 (CZ4A), CR9 (CZ 3A) CR10 (CZ2A). No restriction for CR10 (CZ 2A). 4 requires R-49, 3,2 require R-38
# which regions made it to IECC 2021 or higher by 2040s? CR3 (CZ5A) update from R-38 to R-60
for (l in 1:nrow(inua2040)) {
  if (inua2040$`Dependency=Location Region`[l]=="CR09") { # climate zone 3c
    inua2040$`Option=Ceiling R-38, Vented`[l]<-sum(inua2040[l,5:10]) # set R-38 to the sum of all 0 - R38
    inua2040[l,5:9]<-0 # set all below R-38 to 0
  }
  if (inua2040$`Dependency=Location Region`[l]=="CR08") { # cz 4
    inua2040$`Option=Ceiling R-49, Vented`[l]<-sum(inua2040[l,5:11]) # set all to R-49
    inua2040[l,5:10]<-0 # set all below R-49 to 0
  }
  if (inua2040$`Dependency=Location Region`[l]=="CR03") { # cz 5 (iecc 2021)
    inua2040$`Option=Ceiling R-60, Vented`[l]<-sum(inua2040[l,5:12]) # set all to R-60
    inua2040[l,5:11]<-0 # set all below R-60 to 0
  }
}
inua2050<-inua2040
inua2050$`Dependency=Vintage`<-"2050s"
#  which regions make it to 2021 or higher? CR4 (5A), CR5 (5B), CR 7 (5A), CR 9 (3A), CR 10 (2A). CZ 2,3 go to R-49, CZ5 goes to R-60
for (l in 1:nrow(inua2050)) {
  if (inua2050$`Dependency=Location Region`[l]=="CR09"|inua2050$`Dependency=Location Region`[l]=="CR10") { 
    inua2050$`Option=Ceiling R-49, Vented`[l]<-sum(inua2050[l,5:11]) # set all to R-49
    inua2050[l,5:10]<-0 # set all below R-49 to 0
  }
  if (inua2050$`Dependency=Location Region`[l]=="CR04"|inua2050$`Dependency=Location Region`[l]=="CR05"|inua2050$`Dependency=Location Region`[l]=="CR07") { 
    inua2050$`Option=Ceiling R-60, Vented`[l]<-sum(inua2050[l,5:12]) # set all to R-60
    inua2050[l,5:11]<-0 # set all below R-60 to 0
  }
}

# then save the new infiltration files complete with new 2020 characteristics
inua_new<-as.data.frame(rbind(inua,inua2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Attic.tsv',sep = "")
  write.table(format(inua_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s inua
inua_new<-as.data.frame(rbind(inua,inua2020,inua2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Attic.tsv',sep = "")
  write.table(format(inua_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2040s inua
inua_new<-as.data.frame(rbind(inua,inua2020,inua2030,inua2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Attic.tsv',sep = "")
  write.table(format(inua_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s inua
inua_new<-as.data.frame(rbind(inua,inua2020,inua2030,inua2040,inua2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Attic.tsv',sep = "")
  write.table(format(inua_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Unfinished Basement ############
# No difference between IECC 2015 and 2021
inub<-read_tsv('../project_national/housing_characteristics/Insulation Unfinished Basement.tsv',col_names = TRUE)
inub<-inub[1:2250,]
inub2020<-inub[inub$`Dependency=Vintage`=="2010s",]
inub2020$`Dependency=Vintage`<-"2020s"
# make changes to 2020 insulation here
# which resstock custom regions make it to IECC 2015 by 2020s? CR3 (CZ5A), CR6 (CZ4C), CR11 (CZ3C), as well as the states TX, FL, NY, NE, DE, MD (these will be adjusted in the bs.csv)
for (l in 1:nrow(inub2020)) {
  if (inub2020$`Dependency=Location Region`[l]=="CR11") { # climate zone 3c
    inub2020$`Option=Ceiling R-13`[l]<-inub2020$`Option=Ceiling R-13`[l]+inub2020$`Option=Uninsulated`[l] # add the uninsulated fraction to the min allowable level
    inub2020$`Option=Uninsulated`[l] <-0
  }
  if (inub2020$`Dependency=Location Region`[l]=="CR06"|inub2020$`Dependency=Location Region`[l]=="CR03") { # climate zone 4C (marine) and 5a
      inub2020$`Option=Ceiling R-19`[l]<-sum(inub2020[l,5:7]) # convert R-13 and 0 to R-19
      inub2020$`Option=Uninsulated`[l]<-inub2020$`Option=Ceiling R-13`[l]<-0
  }
}
inub2030<-inub2020
inub2030$`Dependency=Vintage`<-"2030s"

# which resstock custom regions make it to IECC 2015 by 2030s? CR2 (CZ6A), CR4 (CZ5A), CR5 (CZ5B), CR7 (CZ 5A). All set to R-19
# which regions make it to IECC 2021 or higher by 2030s? CR6 (CZ 4C), CR11 (CZ 3C) and the rogue states. but no change in insulation level required
for (l in 1:nrow(inub2030)) {
  # all are in CZ 5 or 6, same regulations apply
  if (inub2030$`Dependency=Location Region`[l]=="CR02"|inub2030$`Dependency=Location Region`[l]=="CR04"|inub2030$`Dependency=Location Region`[l]=="CR05"|inub2030$`Dependency=Location Region`[l]=="CR07") { 
    inub2030$`Option=Ceiling R-19`[l]<-sum(inub2030[l,5:7]) # convert R-13 and 0 to R-19
    inub2030$`Option=Uninsulated`[l]<-inub2030$`Option=Ceiling R-13`[l]<-0
  }
}
inub2040<-inub2030
inub2040$`Dependency=Vintage`<-"2040s"
# which resstock custom regions make it to IECC 2015 by 2040s? CR08 (CZ4A), CR9 (CZ 3A) CR10 (CZ2A). No restriction for CR10 (CZ 2A), 3 and 4 set to 13
for (l in 1:nrow(inub2040)) {
  if (inub2040$`Dependency=Location Region`[l]=="CR08"|inub2040$`Dependency=Location Region`[l]=="CR09") { # climate zone 3c
    inub2040$`Option=Ceiling R-13`[l]<-inub2040$`Option=Ceiling R-13`[l]+inub2040$`Option=Uninsulated`[l] # add the uninsulated fraction to the min allowable level
    inub2040$`Option=Uninsulated`[l] <-0
  }
}
inub2050<-inub2040
inub2050$`Dependency=Vintage`<-"2050s"
# no further change in the 2050s

# then save the new infiltration file complete with new 2020 characteristics
inub_new<-as.data.frame(rbind(inub,inub2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Basement.tsv',sep = "")
  write.table(format(inub_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2030s inub
inub_new<-as.data.frame(rbind(inub,inub2020,inub2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Basement.tsv',sep = "")
  write.table(format(inub_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2040s inub
inub_new<-as.data.frame(rbind(inub,inub2020,inub2030,inub2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Basement.tsv',sep = "")
  write.table(format(inub_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# save 2050s inub
inub_new<-as.data.frame(rbind(inub,inub2020,inub2030,inub2040,inub2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Unfinished Basement.tsv',sep = "")
  write.table(format(inub_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Wall ###########
# no difference between IECC 2015 and 2021
inw<-read_tsv('../project_national/housing_characteristics/Insulation Wall.tsv',col_names = TRUE)
inw<-inw[1:180,]

inw2020<-inw[inw$`Dependency=Vintage`=="2010s",] # note that none of this cohort have wood, CMU, or brick walls that are completely uninsulated
inw2020$`Dependency=Vintage`<-"2020s"

# make changes to 2020 insulation here
# first add extra option, already exists in options lookup so no need for changes there
inw$`Option=Wood Stud, R-19, R-5 Sheathing`<-inw2020$`Option=Wood Stud, R-19, R-5 Sheathing`<-0
inw2020<-inw2020[,c(1:8,15,9:14)] # reorder columns
inw<-inw[,c(1:8,15,9:14)] # reorder columns
# which resstock custom regions make it to IECC 2015 by 2020s? CR3 (CZ5A), CR6 (CZ4C), CR11 (CZ3C), as well as the states TX, FL, NY, NE, DE, MD (these will be adjusted in the bs.csv)
# climate zone 3,4,5, all wood go to R-20, approximated by R-19. Masonry CZ3 goes to R-8 (approx. 11, but no change) and CZ 4C, 5 goes to 13 (approx 15)
for (l in 1:nrow(inw2020)) {
  if (inw2020$`Dependency=Location Region`[l]=="CR11") {
      inw2020$`Option=Wood Stud, R-19`[l]<-sum(inw2020[l,6:8])
      inw2020[l,6:7]<-0# set those below R-19 wood to 0.
      
  }
  if (inw2020$`Dependency=Location Region`[l]=="CR03"|inw2020$`Dependency=Location Region`[l]=="CR06") {
    inw2020$`Option=Wood Stud, R-19`[l]<-sum(inw2020[l,6:8])
    inw2020[l,6:7]<-0# set those below R-19 wood to 0.
    
    inw2020$`Option=CMU, 6-in Hollow, R-15`[l]<-sum(inw2020[l,12:13])
    inw2020[l,12]<-0# set those below R-15 CMU to 0.
  }
}
inw2030<-inw2020
inw2030$`Dependency=Vintage`<-"2030s"

# which resstock custom regions make it to IECC 2015 by 2030s? CR2 (CZ6A), CR4 (CZ5A), CR5 (CZ5B), CR7 (CZ 5A). 
# For wood CZ5 goes to 20, CZ6 gpes tp 20 + 5. For masonry CZ 5 goes to 13, CZ6 to 15, set both to 15
for (l in 1:nrow(inw2030)) {
  # all are in CZ 5 or 6, same regulations apply
  if (inw2030$`Dependency=Location Region`[l]=="CR04"|inw2030$`Dependency=Location Region`[l]=="CR05"|inw2030$`Dependency=Location Region`[l]=="CR07") { 
      inw2030$`Option=Wood Stud, R-19`[l]<-sum(inw2030[l,6:8])
      inw2030[l,6:7]<-0 # set those below r-19 to 0
      
      inw2030$`Option=CMU, 6-in Hollow, R-15`[l]<-sum(inw2030[l,12:13])
      inw2030[l,12]<-0# set those below R-15 CMU to 0.
  }
  if (inw2030$`Dependency=Location Region`[l]=="CR02") {
    inw2030$`Option=Wood Stud, R-19, R-5 Sheathing`[l]<-sum(inw2030[l,6:9])
    inw2030[l,6:8]<-0 # set those below r-19 + 5 to 0
    
    inw2030$`Option=CMU, 6-in Hollow, R-15`[l]<-sum(inw2030[l,12:13])
    inw2030[l,12]<-0# set those below R-15 CMU to 0.
  }
}
inw2040<-inw2030
inw2040$`Dependency=Vintage`<-"2040s"
# which resstock custom regions make it to IECC 2015 by 2040s? CR08 (CZ4A), CR9 (CZ 3A) CR10 (CZ2A). 
# for wood set CZ2 to R-15 and CZ 3/4 to 19. For Masonry no change
for (l in 1:nrow(inw2040)) {
  # all are in CZ 5 or 6, same regulations apply
  if (inw2040$`Dependency=Location Region`[l]=="CR08"|inw2040$`Dependency=Location Region`[l]=="CR09") { 
    inw2040$`Option=Wood Stud, R-19`[l]<-sum(inw2040[l,6:8])
    inw2040[l,6:7]<-0 # set those below r-19 to 0
  }
  if (inw2040$`Dependency=Location Region`[l]=="CR10") {
    inw2040$`Option=Wood Stud, R-15`[l]<-sum(inw2040[l,6:7])
    inw2040[l,6]<-0 # set those below r-15
  }
}
inw2050<-inw2040
inw2050$`Dependency=Vintage`<-"2050s"
# in 2050s set some of CR3 and CR5 to the higher insulation level for wood frame, seeing as they contain some of CZ6 and 7
for (l in 1:nrow(inw2050)) {
  if (inw2050$`Dependency=Location Region`[l]=="CR03"|inw2050$`Dependency=Location Region`[l]=="CR05") { 
    inw2050$`Option=Wood Stud, R-19, R-5 Sheathing`[l]<-0.15
    inw2050$`Option=Wood Stud, R-19`[l]<-0.85
  }
}

# then save the new infiltration file complete with new 2020 characteristics
inw_new<-as.data.frame(rbind(inw,inw2020))
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Wall.tsv',sep = "")
  write.table(format(inw_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2030s inw
inw_new<-as.data.frame(rbind(inw,inw2020,inw2030))
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Wall.tsv',sep = "")
  write.table(format(inw_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2040s inw
inw_new<-as.data.frame(rbind(inw,inw2020,inw2030,inw2040))
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Wall.tsv',sep = "")
  write.table(format(inw_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# save 2050s inw
inw_new<-as.data.frame(rbind(inw,inw2020,inw2030,inw2040,inw2050))
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Wall.tsv',sep = "")
  write.table(format(inw_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Insulation Finshed Roof #############
# NB there are no vintage dependencies here, and this characteristics applies to MF homes only.
# From 2020s on, no homes with Roof less than R30. This is true even with IECC 2009.
# Future distributions are based on assumptions of increased efficienc, but do not relate to specific code updates.
infr<-read_tsv('../project_national/housing_characteristics/Insulation Finished Roof.tsv',col_names = TRUE)
infr2020<-infr[1:5,]
infr2020$`Option=R-60`<-0 # add new option, this does not previously exist in options lookup, and needs to be added.
infr2020<-infr2020[,c(1:8,10,9)] # reorder columns
# set all below R-30 to 0
infr2020[,2:5]<-0
infr2020[4:5,6:9]<-matrix(rep(c(0.05,0.45,0.5,0),each =2),2,4) # set  R-30:38:49:60 in 2020s
infr_new<-as.data.frame(infr2020)
for (p in 2:7) { # which projects do these changes apply to? in this case all 2025 and 2030 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Roof.tsv',sep = "")
  write.table(format(infr_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
infr2030<-infr2020
infr2030[4:5,6:9]<-matrix(rep(c(0,0.45,0.45,0.1),each =2),2,4) # set  R-30:38:49:60 in 2030s

infr_new<-as.data.frame(infr2030)
for (p in 8:13) { # which projects do these changes apply to? in this case all 2035 and 2040 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Roof.tsv',sep = "")
  write.table(format(infr_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

infr2040<-infr2030
infr2040[4:5,6:9]<-matrix(rep(c(0,0.35,0.5,0.15),each =2),2,4) # set  R-30:38:49:60 in 2050s

infr_new<-as.data.frame(infr2040)
for (p in 14:19) { # which projects do these changes apply to? in this case all 2045 and 2050 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Roof.tsv',sep = "")
  write.table(format(infr_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

infr2050<-infr2040
infr2050[4:5,6:9]<-matrix(rep(c(0,0.15,0.55,0.3),each =2),2,4) # set  R-30:38:49:60 in 2050s

infr_new<-as.data.frame(infr2050)
for (p in 20:25) { # which projects do these changes apply to? in this case all 2055 and 2060 projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Insulation Finished Roof.tsv',sep = "")
  write.table(format(infr_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

## change files dependent on Vintage ACS #############
# Geometry Floor Area
# For this characteristics, we will define alternative versions for the reduced floor area scenario.
gfa<-read_tsv('../project_national/housing_characteristics/Geometry Floor Area.tsv',col_names = TRUE)
gfa<-gfa[1:720,] # remove comments additional columns
gfa2020<-gfa[gfa$`Dependency=Vintage ACS`=="2010s",]
gfa2020$`Dependency=Vintage ACS`<-"2020s"
# replace distributions for MH with very low (<4) sample count to the distribution for the observation with most sample obsv:  "Non-CBSA West South Central"
# This prevents unrealistic sampling of mobile homes with floor area over 3000 or 4000
gfa2020[gfa2020$sample_count<4&gfa2020$`Dependency=Geometry Building Type RECS`=="Mobile Home",4:12]<-
  gfa2020[gfa2020$`Dependency=Geometry Building Type RECS`=="Mobile Home"&gfa2020$`Dependency=AHS Region`=="Non-CBSA West South Central",4:12]
# do the same for MF 2-4, using "Non-CBSA South Atlantic" as representative for regions with no/low sample counts
gfa2020[gfa2020$sample_count<4&gfa2020$`Dependency=Geometry Building Type RECS`=="Multi-Family with 2 - 4 Units",4:12]<-
  gfa2020[gfa2020$`Dependency=Geometry Building Type RECS`=="Multi-Family with 2 - 4 Units"&gfa2020$`Dependency=AHS Region`=="Non-CBSA South Atlantic",4:12]
# do the same for SFA, using "CBSA Washington-Arlington-Alexandria, DC-VA-MD-WV" as representative for regions with no/low sample counts
gfa2020[gfa2020$sample_count<4&gfa2020$`Dependency=Geometry Building Type RECS`=="Single-Family Attached",4:12]<-
  gfa2020[gfa2020$`Dependency=Geometry Building Type RECS`=="Single-Family Attached"&gfa2020$`Dependency=AHS Region`=="CBSA Washington-Arlington-Alexandria, DC-VA-MD-WV",4:12]
# for SFD, only region affected is "CBSA New York-Newark-Jersey City, NY-NJ-PA". Here using the 2000s distribution to represent 2020s onwards. This has a lot more sample points than 2010s
gfa2020[gfa2020$sample_count<4&gfa2020$`Dependency=Geometry Building Type RECS`=="Single-Family Detached",4:12]<-
  gfa[gfa$`Dependency=Vintage ACS`=="2000-09" & gfa$`Dependency=Geometry Building Type RECS`=="Single-Family Detached" & gfa$`Dependency=AHS Region`=="CBSA New York-Newark-Jersey City, NY-NJ-PA",4:12]

# also modity small-sample gfa characteristics for the 2020 stock
# based on avg characteristics of Non-CBSA Mountain and Non-CBSA South Atlantic
nr<-nrow(gfa[gfa$sample_count<3 & gfa$`Dependency=Geometry Building Type RECS`=="Mobile Home" & gfa$`Dependency=Vintage ACS` %in% c("<1940","1940-59"),4:12])
gfa[gfa$sample_count<3 & gfa$`Dependency=Geometry Building Type RECS`=="Mobile Home" & gfa$`Dependency=Vintage ACS` %in% c("<1940","1940-59"),4:12]<-
  matrix(rep(c(0.197,0.397,0.098,0.229,0.079,0,0,0,0),each=nr),nr,9)
gfa[gfa$`Dependency=Geometry Building Type RECS`=="Single-Family Attached"&gfa$`Dependency=Vintage ACS`=="<1940" & gfa$`Dependency=AHS Region`=="CBSA Atlanta-Sandy Springs-Roswell, GA",4:12]<-
  gfa[gfa$`Dependency=Geometry Building Type RECS`=="Single-Family Attached"&gfa$`Dependency=Vintage ACS`=="1940-59" & gfa$`Dependency=AHS Region`=="CBSA Atlanta-Sandy Springs-Roswell, GA",4:12]  

gfa2010<-gfa2020<-gfa2020[,1:12] # remove the sample count/weight columns, define 2010s with same floor area distributin modifications applied to 2020s
gfa2010$`Dependency=Vintage ACS`<-"2010s"
gfa<-gfa[!gfa$`Dependency=Vintage ACS`=="2010s",1:12]
gfa<-rbind(gfa,gfa2010)
gfa_new<-as.data.frame(gfa)
for (p in 1) { # which projects do these changes apply to? in this case 2020 only
  fol_fn<-paste(projects[p],'/housing_characteristics/Geometry Floor Area.tsv',sep = "")
  write.table(format(gfa_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# Define no changes
# define floor area made in 2030s 2040s and 2050s as the same as those made in 2020s
gfa2030<-gfa2040<-gfa2050<-gfa2020
# define vintage names
gfa2030$`Dependency=Vintage ACS`<-"2030s"
gfa2040$`Dependency=Vintage ACS`<-"2040s"
gfa2050$`Dependency=Vintage ACS`<-"2050s"
gfa_new<-as.data.frame(rbind(gfa,gfa2020,gfa2030,gfa2040,gfa2050))
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Geometry Floor Area.tsv',sep = "")
  write.table(format(gfa_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Geometry Floor Area.tsv',sep = "")
  write.table(format(gfa_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  
}

# reduced floor area scenario file
gfa_rfa<-gfa_new
# remove floor area greater than 3000 sqft, add those large homes to either 2000-2499 or 2500-2999 in 50:50 ratio
for (l in 1:nrow(gfa_rfa)) {
  big<-sum(gfa_rfa[l,11:12]) 
  gfa_rfa[l,11:12]<-0
  gfa_rfa[l,9:10]<-gfa_rfa[l,9:10]+0.5*big
}
# save reduced floor area characteristics
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Reduced_FloorArea/Geometry Floor Area.tsv',sep = "")
  write.table(format(gfa_rfa,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  
}
# Geometry Foundation Type #########
gft<-read_tsv('../project_national/housing_characteristics/Geometry Foundation Type.tsv',col_names = TRUE)
gft<-gft[1:450,1:8]
gft2020<-gft[gft$`Dependency=Vintage ACS`=="2010s",]
gft2020$`Dependency=Vintage ACS`<-"2020s"
# make no changes
# define foundations made in 2030s 2040s and 2050s as the same as those made in 2020s
gft2030<-gft2040<-gft2050<-gft2020
# define vintage names
gft2030$`Dependency=Vintage ACS`<-"2030s"
gft2040$`Dependency=Vintage ACS`<-"2040s"
gft2050$`Dependency=Vintage ACS`<-"2050s"
gft_new<-as.data.frame(rbind(gft,gft2020,gft2030,gft2040,gft2050))
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Geometry Foundation Type.tsv',sep = "")
  write.table(format(gft_new,nsmall=6,digits = 0,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Geometry Stories ############
gs<-read_tsv('../project_national/housing_characteristics/Geometry Stories.tsv',col_names = TRUE)
gs<-gs[1:120,1:6]
gs2020<-gs[gs$`Dependency=Vintage ACS`=="2010s",]
# No changes here
gs2020$`Dependency=Vintage ACS`<-"2020s"
# define stories made in 2030s 2040s and 2050s as the same as those made in 2020s
gs2030<-gs2040<-gs2050<-gs2020
# define vintage names
gs2030$`Dependency=Vintage ACS`<-"2030s"
gs2040$`Dependency=Vintage ACS`<-"2040s"
gs2050$`Dependency=Vintage ACS`<-"2050s"
gs_new<-as.data.frame(rbind(gs,gs2020,gs2030,gs2040,gs2050))
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Geometry Stories.tsv',sep = "")
  write.table(format(gs_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Water Heater In Units ############
whiu<-read_tsv('../project_national/housing_characteristics/Water Heater In Unit.tsv',col_names = TRUE)
whiu<-whiu[1:300,1:5]
whiu2020<-whiu[whiu$`Dependency=Vintage ACS`=="2010s",]
# Make no changes
whiu2020$`Dependency=Vintage ACS`<-"2020s"
# define stories made in 2030s 2040s and 2050s as the same as those made in 2020s
whiu2030<-whiu2040<-whiu2050<-whiu2020
# define vintage names
whiu2030$`Dependency=Vintage ACS`<-"2030s"
whiu2040$`Dependency=Vintage ACS`<-"2040s"
whiu2050$`Dependency=Vintage ACS`<-"2050s"
whiu_new<-as.data.frame(rbind(whiu,whiu2020,whiu2030,whiu2040,whiu2050))
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Water Heater In Unit.tsv',sep = "")
  write.table(format(whiu_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# non vintage related characteristics ########
# Clothes Dryers ########
cdr<-read_tsv('../project_national/housing_characteristics/Clothes Dryer.tsv',col_names = TRUE)
cdr<-cdr[1:5760,1:15]
# add new options here and in options_lookup. Make sure correct spelling in options_lookup
cdr$`Option=Electric, Premium, 80% Usage`<-cdr$`Option=Electric, Premium, 120% Usage`<-cdr$`Option=Electric, Premium, 100% Usage`<-
  cdr$`Option=Gas, Premium, 80% Usage`<-cdr$`Option=Gas, Premium, 120% Usage`<-cdr$`Option=Gas, Premium, 100% Usage`<-0
# in line with the new standard effective 2015, define all gas and electric dryers in new construction as premium efficiency. This applies to all future years.
cdr[,19:21]<-cdr[,6:8] # replace electric standard with electric premium
cdr[,6:8]<-0
cdr[,16:18]<-cdr[,9:11] # replace gas standard with gas premium
cdr[9:11]<-0
# save new clothes dryer characteristics
cdr_new<-as.data.frame(cdr)
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Clothes Dryer.tsv',sep = "")
  write.table(format(cdr_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Clothes Dryer.tsv',sep = "")
  write.table(format(cdr_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# deep electrification scenario
# remove propane and gas dryers, convert to electric
cdr_de<-cdr_new
cdr_de$`Option=Electric, Premium, 100% Usage`<-cdr_de$`Option=Electric, Premium, 100% Usage`+cdr_de$`Option=Gas, Premium, 100% Usage`+cdr_de$`Option=Propane, 100% Usage`
cdr_de$`Option=Gas, Premium, 100% Usage`<-cdr_de$`Option=Propane, 100% Usage`<-0
cdr_de$`Option=Electric, Premium, 80% Usage`<-cdr_de$`Option=Electric, Premium, 80% Usage`+cdr_de$`Option=Gas, Premium, 80% Usage`+cdr_de$`Option=Propane, 80% Usage`
cdr_de$`Option=Gas, Premium, 80% Usage`<-cdr_de$`Option=Propane, 80% Usage`<-0
cdr_de$`Option=Electric, Premium, 120% Usage`<-cdr_de$`Option=Electric, Premium, 120% Usage`+cdr_de$`Option=Gas, Premium, 120% Usage`+cdr_de$`Option=Propane, 120% Usage`
cdr_de$`Option=Gas, Premium, 120% Usage`<-cdr_de$`Option=Propane, 120% Usage`<-0
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/Clothes Dryer.tsv',sep = "")
  write.table(format(cdr_de,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Clothes Washers ############
cw<-read_tsv('../project_national/housing_characteristics/Clothes Washer.tsv',col_names = TRUE)
cw<-cw[1:8,]
cw[5:8,7:9]<-cw[5:8,7:9]+cw[5:8,4:6] # make all clothes washers energy star which gives imef=2.07, lower (less efficient) than what ES products are standard sold today
cw[5:8,4:6]<-0
cw_new<-as.data.frame(cw)
for (p in 2:25) { # which projects do these changes apply to? in this case all projects
  fol_fn<-paste(projects[p],'/housing_characteristics/Clothes Washer.tsv',sep = "")
  write.table(format(cw_new,nsmall=6,digits = 1,scientific = FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Lighting. # Reflect higher shares of efficient lighting ######
lgt<-read_tsv('../project_national/housing_characteristics/Lighting.tsv',col_names = TRUE)
lgt<-lgt[1:50,1:5]
for (l in 1:nrow(lgt)) {
  inc<-lgt$`Option=100% Incandescent`[l]
  cfl<-lgt$`Option=100% CFL`[l]
  # add 80% of CFL and 60% Incandescent to LED
  lgt$`Option=100% LED`[l]<-lgt$`Option=100% LED`[l]+0.8*lgt$`Option=100% CFL`[l]+0.6*lgt$`Option=100% Incandescent`[l]
  lgt$`Option=100% CFL`[l]<-0.2*lgt$`Option=100% CFL`[l]
  lgt$`Option=100% Incandescent`[l]<-0.4*lgt$`Option=100% Incandescent`[l]
}
lgt_new<-as.data.frame(lgt)
for (p in 2:7) { # which projects do these changes apply to? in this case 2025 and 2030
  fol_fn<-paste(projects[p],'/housing_characteristics/Lighting.tsv',sep = "")
  write.table(format(lgt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# from 2030s onwards, 98% LED
lgt$`Option=100% LED`<-0.98
lgt$`Option=100% CFL`<-0.01
lgt$`Option=100% Incandescent`<-0.01
lgt_new<-as.data.frame(lgt)
for (p in 10:25) { # which projects do these changes apply to? in this case 2035 onwards
  fol_fn<-paste(projects[p],'/housing_characteristics/Lighting.tsv',sep = "")
  write.table(format(lgt_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# water heater efficiency #########
whe<-read_tsv('../project_national/housing_characteristics/Water Heater Efficiency.tsv',col_names = TRUE)
whe2020<-whe[1:50,1:16]
# define improvement rates that are steady for each cohort
for (l in 1:nrow(whe2020)) {
      elst<-whe2020$`Option=Electric Standard`[l]
      # reduce the fraction that is standard and increase the other fractions as follows
      whe2020$`Option=Electric Standard`[l]<-0.8*elst # elec standard reduced by 20%, add this fraction to HP (4%), elec prem (15%), and elec tankless (1%)
      whe2020$`Option=Electric Heat Pump, 80 gal`[l]<-whe2020$`Option=Electric Heat Pump, 80 gal`[l]+0.04*elst
      whe2020$`Option=Electric Premium`[l]<-whe2020$`Option=Electric Premium`[l]+0.15*elst
      whe2020$`Option=Electric Tankless`[l]<-whe2020$`Option=Electric Tankless`[l]+0.01*elst
      # reduce the fraction that is standard and increase the other fractions as follows
      ngst<-whe2020$`Option=Natural Gas Standard`[l]
      whe2020$`Option=Natural Gas Standard`[l]<-0.85*ngst  # gas standard reduced by 15%, add this fraction to gas  prem (13%), and gas tankless (2%)
      whe2020$`Option=Natural Gas Premium`[l]<-whe2020$`Option=Natural Gas Premium`[l]+0.13*ngst
      whe2020$`Option=Natural Gas Tankless`[l]<-whe2020$`Option=Natural Gas Tankless`[l]+0.02*ngst
      
      prst<-whe2020$`Option=Propane Standard`[l]
      whe2020$`Option=Propane Standard`[l]<-0.9*prst # lpg standard reduced by 10%, add this fraction to lpg prem (7%), and lpg tankless (3%)
      whe2020$`Option=Propane Premium`[l]<-whe2020$`Option=Propane Premium`[l]+0.07*prst
      whe2020$`Option=Propane Tankless`[l]<-whe2020$`Option=Propane Tankless`[l]+0.03*prst
}
whe_new<-as.data.frame(whe2020)
for (p in 2:7) { # which projects do these changes apply to? in this case 2025 and 2030
  fol_fn<-paste(projects[p],'/housing_characteristics/Water Heater Efficiency.tsv',sep = "")
  write.table(format(whe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
whe2030<-whe2020
for (l in 1:nrow(whe2030)) {
  elst<-whe2030$`Option=Electric Standard`[l]
  # reduce the fraction that is standard and increase the other fractions as followed
  whe2030$`Option=Electric Standard`[l]<-0.8*elst
  whe2030$`Option=Electric Heat Pump, 80 gal`[l]<-whe2030$`Option=Electric Heat Pump, 80 gal`[l]+0.04*elst
  whe2030$`Option=Electric Premium`[l]<-whe2030$`Option=Electric Premium`[l]+0.15*elst
  whe2030$`Option=Electric Tankless`[l]<-whe2030$`Option=Electric Tankless`[l]+0.01*elst
  
  ngst<-whe2030$`Option=Natural Gas Standard`[l]
  whe2030$`Option=Natural Gas Standard`[l]<-0.85*ngst
  whe2030$`Option=Natural Gas Premium`[l]<-whe2030$`Option=Natural Gas Premium`[l]+0.13*ngst
  whe2030$`Option=Natural Gas Tankless`[l]<-whe2030$`Option=Natural Gas Tankless`[l]+0.02*ngst
  
  prst<-whe2030$`Option=Propane Standard`[l]
  whe2030$`Option=Propane Standard`[l]<-0.9*prst
  whe2030$`Option=Propane Premium`[l]<-whe2030$`Option=Propane Premium`[l]+0.07*prst
  whe2030$`Option=Propane Tankless`[l]<-whe2030$`Option=Propane Tankless`[l]+0.03*prst
}
whe_new<-as.data.frame(whe2030)
for (p in 8:13) { # which projects do these changes apply to? in this case 2035 and 2040
  fol_fn<-paste(projects[p],'/housing_characteristics/Water Heater Efficiency.tsv',sep = "")
  write.table(format(whe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

whe2040<-whe2030
for (l in 1:nrow(whe2040)) {
  elst<-whe2040$`Option=Electric Standard`[l]
  # reduce the fraction that is standard and increase the other fractions as followed
  whe2040$`Option=Electric Standard`[l]<-0.8*elst
  whe2040$`Option=Electric Heat Pump, 80 gal`[l]<-whe2040$`Option=Electric Heat Pump, 80 gal`[l]+0.04*elst
  whe2040$`Option=Electric Premium`[l]<-whe2040$`Option=Electric Premium`[l]+0.15*elst
  whe2040$`Option=Electric Tankless`[l]<-whe2040$`Option=Electric Tankless`[l]+0.01*elst
  
  ngst<-whe2040$`Option=Natural Gas Standard`[l]
  whe2040$`Option=Natural Gas Standard`[l]<-0.85*ngst
  whe2040$`Option=Natural Gas Premium`[l]<-whe2040$`Option=Natural Gas Premium`[l]+0.13*ngst
  whe2040$`Option=Natural Gas Tankless`[l]<-whe2040$`Option=Natural Gas Tankless`[l]+0.02*ngst
  
  prst<-whe2040$`Option=Propane Standard`[l]
  whe2040$`Option=Propane Standard`[l]<-0.9*prst
  whe2040$`Option=Propane Premium`[l]<-whe2040$`Option=Propane Premium`[l]+0.07*prst
  whe2040$`Option=Propane Tankless`[l]<-whe2040$`Option=Propane Tankless`[l]+0.03*prst
}
whe_new<-as.data.frame(whe2040)
for (p in 14:19) { # which projects do these changes apply to? in this case 2045 and 2050
  fol_fn<-paste(projects[p],'/housing_characteristics/Water Heater Efficiency.tsv',sep = "")
  write.table(format(whe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# accelerate the change for the 2050s
whe2050<-whe2040
for (l in 1:nrow(whe2050)) {
  elst<-whe2050$`Option=Electric Standard`[l]
  # reduce the fraction that is standard and increase the other fractions as followed
  whe2050$`Option=Electric Standard`[l]<-0.5*elst
  whe2050$`Option=Electric Heat Pump, 80 gal`[l]<-whe2050$`Option=Electric Heat Pump, 80 gal`[l]+0.3*elst
  whe2050$`Option=Electric Premium`[l]<-whe2050$`Option=Electric Premium`[l]+0.15*elst
  whe2050$`Option=Electric Tankless`[l]<-whe2050$`Option=Electric Tankless`[l]+0.05*elst
  
  ngst<-whe2050$`Option=Natural Gas Standard`[l]
  whe2050$`Option=Natural Gas Standard`[l]<-0.5*ngst
  whe2050$`Option=Natural Gas Premium`[l]<-whe2050$`Option=Natural Gas Premium`[l]+0.45*ngst
  whe2050$`Option=Natural Gas Tankless`[l]<-whe2050$`Option=Natural Gas Tankless`[l]+0.05*ngst
  
  prst<-whe2050$`Option=Propane Standard`[l]
  whe2050$`Option=Propane Standard`[l]<-0.5*prst
  whe2050$`Option=Propane Premium`[l]<-whe2050$`Option=Propane Premium`[l]+0.35*prst
  whe2050$`Option=Propane Tankless`[l]<-whe2050$`Option=Propane Tankless`[l]+0.15*prst
}
whe_new<-as.data.frame(whe2050)
for (p in 20:25) { # which projects do these changes apply to? in this case 2055 and 2060
  fol_fn<-paste(projects[p],'/housing_characteristics/Water Heater Efficiency.tsv',sep = "")
  write.table(format(whe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# water heater fuel #########
whf<-read_tsv('../project_national/housing_characteristics/Water Heater Fuel.tsv',col_names = TRUE)
whf2020<-whf[1:300,1:8]
# assumptions. Reduce new builds with fuel oil
for (l in 1:nrow(whf2020)) {
  fo<-whf2020$`Option=Fuel Oil`[l]
  whf2020$`Option=Fuel Oil`[l]<-0.03*fo # greatly reduce new builds with fuel oil water heat
  whf2020$`Option=Natural Gas`[l]<-whf2020$`Option=Natural Gas`[l]+0.55*fo
  whf2020$`Option=Electricity`[l]<-whf2020$`Option=Electricity`[l]+0.25*fo
  whf2020$`Option=Propane`[l]<-whf2020$`Option=Propane`[l]+0.17*fo
}
# otherwise leave as defined by heating fuel. 
whf_new<-as.data.frame(whf2020)
for (p in 2:7) { # which projects do these changes apply to? in this case 2025 and 2030
  fol_fn<-paste(projects[p],'/housing_characteristics/Water Heater Fuel.tsv',sep = "")
  write.table(format(whf_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Water Heater Fuel.tsv',sep = "")
  write.table(format(whf_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
whf2030<-whf2020
# for rest of years. turn oil to electricity
whf2030$`Option=Electricity`<-whf2030$`Option=Electricity`+whf2030$`Option=Fuel Oil` 
whf2030$`Option=Fuel Oil` <-0

whf_new<-as.data.frame(whf2030)
for (p in 10:25) { # which projects do these changes apply to? in this case 2035 onwards
  fol_fn<-paste(projects[p],'/housing_characteristics/Water Heater Fuel.tsv',sep = "")
  write.table(format(whf_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Water Heater Fuel.tsv',sep = "")
  write.table(format(whf_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

## deep electrification 
whf_de<-whf_new # all years based of the 2030 base, i.e. no more oil, all becomes elec
# turn all houses with electric space heating into houses with electric water heating
whf_de[whf_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Electricity`<-1
whf_de[whf_de$`Dependency=Heating Fuel`=="Electricity",5:8]<-0

for (p in 2:25) { # which projects do these changes apply to? in this case all
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/Water Heater Fuel.tsv',sep = "")
  write.table(format(whf_de,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# Refrigerators ########
rfg<-read_tsv('../project_national/housing_characteristics/Refrigerator.tsv',col_names = TRUE)
rfg<-rfg[1:20,1:7]
rfg$`Option=EF 21.9`<-rfg$`Option=EF 19.9`<-0 # add two more efficient radiators. Already exist in options lookup
rfg<-rfg[,c(1,2,7,3:6,8,9)]
rfg[,3:9]<-0 # set all values to 0
rfg[,6:9]<-matrix(rep(c(0.05,0.25,0.6,0.1),each=20),20,4) # define distributions so that most homes have the 19.9 EF refrigerator
rfg_new<-as.data.frame(rfg)
for (p in 2:7) { # which projects do these changes apply to? in this case 2025 and 2030
  fol_fn<-paste(projects[p],'/housing_characteristics/Refrigerator.tsv',sep = "")
  write.table(format(rfg_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# update for 2030s
rfg[,6:9]<-matrix(rep(c(0,0.15,0.6,0.25),each=20),20,4) # increase the proportion of 21.9
rfg_new<-as.data.frame(rfg)
for (p in 8:13) { # which projects do these changes apply to? in this case 2035 and 2040
  fol_fn<-paste(projects[p],'/housing_characteristics/Refrigerator.tsv',sep = "")
  write.table(format(rfg_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# update for 2040s
rfg[,6:9]<-matrix(rep(c(0,0.05,0.6,0.35),each=20),20,4) # increase the proportion of 21.9
rfg_new<-as.data.frame(rfg)
for (p in 14:19) { # which projects do these changes apply to? in this case 2045 and 2050
  fol_fn<-paste(projects[p],'/housing_characteristics/Refrigerator.tsv',sep = "")
  write.table(format(rfg_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
# update for 2050s
rfg[,6:9]<-matrix(rep(c(0,0,0.4,0.6),each=20),20,4) # majority of homes now use 21.9
rfg_new<-as.data.frame(rfg)
for (p in 20:25) { # which projects do these changes apply to? in this case 2045 and 2050
  fol_fn<-paste(projects[p],'/housing_characteristics/Refrigerator.tsv',sep = "")
  write.table(format(rfg_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# add the new heating efficiency options in HVAC Heating Type and Fuel ################
htf<-read_tsv('../project_national/housing_characteristics/HVAC Heating Type and Fuel.tsv',col_names = TRUE)
htf<-htf[1:132,]
htf[htf$`Dependency=HVAC Heating Efficiency`=="MSHP, SEER 29.3, 14 HSPF",]$`Dependency=HVAC Heating Efficiency`<-"MSHP, SEER 25, 12.7 HSPF" # replace the hi-eff MSHP with a more reasonably hi-eff option
# define htfe, the htf extra combinations which don't currently exist
htfe<-htf[1:7,]
htfe$`Dependency=Heating Fuel`<-c(rep("Electricity",4),"Natural Gas","Fuel Oil","Propane")
htfe$`Dependency=HVAC Heating Efficiency`<-c("ASHP, SEER 16, 9.0 HSPF","ASHP, SEER 18, 9.3 HSPF","ASHP, SEER 22, 10 HSPF",
                                             "MSHP, SEER 17, 9.5 HSPF","Fuel Boiler, 96% AFUE","Fuel Boiler, 96% AFUE","Fuel Boiler, 96% AFUE")
htfe[,3:29]<-0
htfe$`Option=Electricity ASHP`<-c(1,1,1,0,0,0,0)
htfe$`Option=Electricity MSHP`<-c(0,0,0,1,0,0,0)
htfe$`Option=Natural Gas Fuel Boiler`<-c(0,0,0,0,1,0,0)
htfe$`Option=Fuel Oil Fuel Boiler`<-c(0,0,0,0,0,1,0)
htfe$`Option=Propane Fuel Boiler`<-c(0,0,0,0,0,0,1)
htf<-rbind(htf,htfe)
htf<-htf[order(htf$`Dependency=Heating Fuel`,htf$`Dependency=HVAC Heating Efficiency`),]
htf_new<-as.data.frame(htf)

for (p in 2:25) { # which projects do these changes apply to? in this case all
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Type and Fuel.tsv',sep = "")
  write.table(format(htf_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# HVAC heating efficiency ##########
hhe<-read_tsv('../project_national/housing_characteristics/HVAC Heating Efficiency.tsv',col_names = TRUE)
hhe<-hhe[1:120,1:25]
# add new options, all already exist in options lookup
names(hhe)[which(names(hhe)=="Option=MSHP, SEER 29.3, 14 HSPF")]<-"MSHP, SEER 25, 12.7 HSPF" # replace the hi-eff MSHP with a more reasonably hi-eff option
hhe$`Option=ASHP, SEER 16, 9.0 HSPF`<-hhe$`Option=ASHP, SEER 18, 9.3 HSPF`<-hhe$`Option=ASHP, SEER 22, 10 HSPF`<-
  hhe$`Option=MSHP, SEER 17, 9.5 HSPF`<-hhe$`Option=Fuel Boiler, 96% AFUE`<-0
hhe<-hhe[,c(1:6,30,29,28,7:13,26,14:20,27,21:25)]
hhe2020<-hhe
# define updates for 2020s
#ASHPs
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Electricity" & hhe2020$`Dependency=HVAC Heating Type`=="Ducted Heat Pump"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),4:9]<-
  matrix(rep(c(0.04,0.7,0.2,0.06,0,0),each=2),2,6)
#MSHPs
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Electricity" & hhe2020$`Dependency=HVAC Heating Type`=="Non-Ducted Heat Pump"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),24:26]<-
  matrix(rep(c(0.5,0.48,0.02),each=2),2,3)
# Fuel Oil Furnaces
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2020$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.9,0.1),each=2),2,4) # 10% condensing furnaces
# Fuel Oil Non-Ducted
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2020$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0.65,0.3,0,0.01,0.04),each=2),2,6) # 30% condensing boilers
# Natural Gas Furnaces
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Natural Gas" & hhe2020$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.6,0.4),each=2),2,4) # 40% condensing furnaces
# Natural Gas Non-Ducted
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Natural Gas" & hhe2020$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0.4,0.15,0,0.05,0.4),each=2),2,6) # 15% condensing boilers
# Propane Furnaces
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Propane" & hhe2020$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.65,0.35),each=2),2,4) # 35% condensing furnaces
# Propane Non-Ducted
hhe2020[hhe2020$`Dependency=Heating Fuel`=="Propane" & hhe2020$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2020$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0.1,0.15,0,0.15,0.6),each=2),2,6) # 15% condensing boilers
# no change to non-heat pump electric efficiencies
hhe_new<-as.data.frame(hhe2020)
for (p in 2:7) { # which projects do these changes apply to? in this case 2025 and 2030
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Efficiency.tsv',sep = "")
  write.table(format(hhe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
hhe2030<-hhe2020
# define updates for 2030s
#ASHPs
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Electricity" & hhe2030$`Dependency=HVAC Heating Type`=="Ducted Heat Pump"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),4:9]<-
  matrix(rep(c(0,0.5,0.25,0.15,0.1,0),each=2),2,6) # 50:25:15:10 SEER 13:15:16:18
#MSHPs
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Electricity" & hhe2030$`Dependency=HVAC Heating Type`=="Non-Ducted Heat Pump"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),24:26]<-
  matrix(rep(c(0.3,0.6,0.1),each=2),2,3) # 30:60:10 SEER 14.5:17:25
# Fuel Oil Furnaces
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2030$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.55,0.45),each=2),2,4) # 45% condensing furnaces
# Fuel Oil Non-Ducted
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2030$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0.45,0.53,0,0,0.02),each=2),2,6) # 53% condensing boilers
# Natural Gas Furnaces
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Natural Gas" & hhe2030$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.35,0.65),each=2),2,4) # 65% condensing furnaces
# Natural Gas Non-Ducted
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Natural Gas" & hhe2030$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0.2,0.5,0,0,0.3),each=2),2,6) # 50% condensing boilers
# Propane Furnaces
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Propane" & hhe2030$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.45,0.55),each=2),2,4) # 55% condensing furnaces
# Propane Non-Ducted
hhe2030[hhe2030$`Dependency=Heating Fuel`=="Propane" & hhe2030$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2030$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0,0.35,0,0,0.65),each=2),2,6) # 35% condensing boilers
# no change to non-heat pump electric efficiencies
hhe_new<-as.data.frame(hhe2030)
for (p in 8:13) { # which projects do these changes apply to? in this case 2035 and 2040
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Efficiency.tsv',sep = "")
  write.table(format(hhe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

hhe2040<-hhe2030
# define updates for 2040s
#ASHPs
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Electricity" & hhe2040$`Dependency=HVAC Heating Type`=="Ducted Heat Pump"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),4:9]<-
  matrix(rep(c(0,0.3,0.3,0.15,0.15,0.1),each=2),2,6) # 30:30:15:15:10 SEER 13:15:16:18:22
#MSHPs
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Electricity" & hhe2040$`Dependency=HVAC Heating Type`=="Non-Ducted Heat Pump"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),24:26]<-
  matrix(rep(c(0.1,0.75,0.15),each=2),2,3) # 10:70:15 SEER 14.5:17:25
# Fuel Oil Furnaces
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2040$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.15,0.85),each=2),2,4) # 85% condensing furnaces
# Fuel Oil Non-Ducted
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2040$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0.15,0.85,0,0,0),each=2),2,6) # 85% condensing boilers
# Natural Gas Furnaces
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Natural Gas" & hhe2040$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.15,0.85),each=2),2,4) # 85% condensing furnaces
# Natural Gas Non-Ducted
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Natural Gas" & hhe2040$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0.05,0.75,0,0,0.2),each=2),2,6) # 75% condensing boilers
# Propane Furnaces
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Propane" & hhe2040$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0.2,0.8),each=2),2,4) # 80% condensing furnaces
# Propane Non-Ducted
hhe2040[hhe2040$`Dependency=Heating Fuel`=="Propane" & hhe2040$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2040$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0,0.65,0,0,0.35),each=2),2,6) # 65% condensing boilers
# no change to non-heat pump electric efficiencies
hhe_new<-as.data.frame(hhe2040)
for (p in 14:19) { # which projects do these changes apply to? in this case 2045 and 2050
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Efficiency.tsv',sep = "")
  write.table(format(hhe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

hhe2050<-hhe2040
# define updates for 2050s
#ASHPs
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Electricity" & hhe2050$`Dependency=HVAC Heating Type`=="Ducted Heat Pump"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),4:9]<-
  matrix(rep(c(0,0.05,0.4,0.2,0.2,0.15),each=2),2,6) # 5:40:20:20:15 SEER 13:15:16:18:22
#MSHPs
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Electricity" & hhe2050$`Dependency=HVAC Heating Type`=="Non-Ducted Heat Pump"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),24:26]<-
  matrix(rep(c(0,0.65,0.35),each=2),2,3) # 0:65:35 SEER 14.5:17:25
# Fuel Oil Furnaces
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2050$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0,1),each=2),2,4) # 100% condensing furnaces
# Fuel Oil Non-Ducted
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Fuel Oil" & hhe2050$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0,0.5,0.5,0,0),each=2),2,6) # 100% condensing boilers
# Natural Gas Furnaces
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Natural Gas" & hhe2050$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0,1),each=2),2,4) # 100% condensing furnaces
# Natural Gas Non-Ducted
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Natural Gas" & hhe2050$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0,0.55,0.4,0,0.05),each=2),2,6) # 95% condensing boilers
# Propane Furnaces
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Propane" & hhe2050$`Dependency=HVAC Heating Type`=="Ducted Heating"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),18:21]<-
  matrix(rep(c(0,0,0,1),each=2),2,4) # 100% condensing furnaces
# Propane Non-Ducted
hhe2050[hhe2050$`Dependency=Heating Fuel`=="Propane" & hhe2050$`Dependency=HVAC Heating Type`=="Non-Ducted Heating"&hhe2050$`Dependency=HVAC Has Shared System` %in% c("Cooling Only","None"),c(14:17,22,23)]<-
  matrix(rep(c(0,0,0.4,0.5,0,0.1),each=2),2,6) # 90% condensing boilers
# no change to non-heat pump electric efficiencies
hhe_new<-as.data.frame(hhe2050)
for (p in 20:25) { # which projects do these changes apply to? in this case 2055 and 2060
  fol_fn<-paste(projects[p],'/housing_characteristics/HVAC Heating Efficiency.tsv',sep = "")
  write.table(format(hhe_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# HVAC Has Zonal Electric Heating ###############
ZHE<-read_tsv('../project_national/housing_characteristics/HVAC Has Zonal Electric Heating.tsv',col_names = TRUE)


# cooking range ##########
# set to complete conformity with heating fuel for advanced electrification scenarios
cr<-read_tsv('../project_national/housing_characteristics/Cooking Range.tsv',col_names = TRUE)
cr<-cr[1:240,]

cr_de<-cr
cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Electric, 100% Usage`<-
  cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Electric, 100% Usage`+cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Gas, 100% Usage`+
  cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Propane, 100% Usage`
cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Gas, 100% Usage`<-cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Propane, 100% Usage`<-0

cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Electric, 80% Usage`<-
  cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Electric, 80% Usage`+cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Gas, 80% Usage`+
  cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Propane, 80% Usage`
cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Gas, 80% Usage`<-cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Propane, 80% Usage`<-0

cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Electric, 120% Usage`<-
  cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Electric, 120% Usage`+cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Gas, 120% Usage`+
  cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Propane, 120% Usage`
cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Gas, 120% Usage`<-cr_de[cr_de$`Dependency=Heating Fuel`=="Electricity",]$`Option=Propane, 120% Usage`<-0

cr_new<-as.data.frame(cr_de)
for (p in 2:25) { # which projects do these changes apply to? in this case all
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Deep_Electrification/Cooking Range.tsv',sep = "")
  write.table(format(cr_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
} 

cr_new<-as.data.frame(cr)
for (p in 2:25) { # which projects do these changes apply to? in this case all
  fol_fn<-paste(projects[p],'/scenario_dependent_characteristics/Unchanged/Cooking Range.tsv',sep = "")
  write.table(format(cr_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
} 
  
## vacancy ##########
# Finally, change all units to occupied
vac<-read_tsv('../project_national/housing_characteristics/Vacancy Status.tsv',col_names = TRUE)
vac<-vac[1:11680,1:4] # remove comment at bottom, and count and weight columns
vac$`Option=Occupied`<-1
vac$`Option=Vacant`<-0

vac_new<-as.data.frame(vac)
# save same file to all new projects 
for (p in 1:33) { # which projects do these changes apply to? in this case all projects, including 2020
  fol_fn<-paste(projects[p],'/housing_characteristics/Vacancy Status.tsv',sep = "")
  write.table(format(vac_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}

# # vintage ACS ####### already fixed
# vacs<-read_tsv('project_national/housing_characteristics/Vintage ACS.tsv',col_names = TRUE)
# vacs<-vacs[1:9,1:7]
# vacs$`Option=2050s`<-vacs$`Option=2040s`<-vacs$`Option=2030s`<-vacs$`Option=2020s`<-0
# vacs<-rbind(vacs,vacs[5:8,])
# vacs[10:13,1]<-c("2020s","2030s","2040s","2050s")
# vacs[10:13,2:11]<-0
# vacs[10:13,8:11]<-diag(4)
# vacs_new<-as.data.frame(vacs)
# for (p in 2:25) { # which projects do these changes apply to? in this case all
#   fol_fn<-paste(projects[p],'/housing_characteristics/Vintage ACS.tsv',sep = "")
#   write.table(format(vacs_new,nsmall=6,digits=1,scientific=FALSE),fol_fn,append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
# }
