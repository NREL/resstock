# script to alter incompatible Garage and Water Heater Fuel combinations in order to avoid failed resstock simulations.
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console

# Last Update Peter Berrill April 30 2022

# Purpose: Fix some housing characteristics which are mutually incompatible and lead to failed simulations

# Inputs: - All simulation bs files (Except 'fail' files for debugging) in scen_bscsv_sim

# Outputs:- Same as inputs, overwrite. This file has to be run after the scen_bscsv_sim files are initially created by bs_adjust

setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts")
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

filenames<-list.files("../scen_bscsv_sim")
filenames<-filenames[-c(grep("fails",filenames))]
filenames<-filenames[-c(grep("fail",filenames))]

for (k in 1:length(filenames)) { print(k) 
fn<-paste("../scen_bscsv_sim/",filenames[k],sep = "")
bs<-read.csv(fn)

table(bs$Geometry.Garage,bs$Geometry.Floor.Area.Bin,bs$Geometry.Stories)
table(bs$Water.Heater.Fuel,bs$Heating.Fuel,bs$HVAC.Has.Shared.System)
tryCatch({
# first amend garages based on this bug fix https://github.com/NREL/resstock/pull/560

# 1. 0-1499 square foot units: Can only have a 1 stall garage
bs[bs$Geometry.Floor.Area.Bin=="0-1499" & !bs$Geometry.Garage == "None",]$Geometry.Garage <- "1 Car"
# 1B. 0-749 square foot units with 2 stories cannot have an attached garage
bs[bs$Geometry.Floor.Area %in% c("0-499","500-749") & bs$Geometry.Stories==2,]$Geometry.Garage <- "None"
# 2. 0-1499 square foot units and 3 stories: cannot have an attached garage
bs[bs$Geometry.Floor.Area.Bin=="0-1499" & bs$Geometry.Stories==3,]$Geometry.Garage <- "None"
# 3. 1500-2499 square foot units: Cannot have a 3 stall garage
bs[bs$Geometry.Floor.Area.Bin=="1500-2499" & bs$Geometry.Garage=="3 Car",]$Geometry.Garage <- "2 Car"
# 4. 2500-3999 square foot units with heated basements: Cannot have a 3 stall garage
bs[bs$Geometry.Floor.Area.Bin=="2500-3999" & bs$Geometry.Foundation.Type == "Heated Basement" & bs$Geometry.Garage=="3 Car",]$Geometry.Garage  <- "2 Car"

# Next amend the water heating fuel situation, to avoid failed simulations, if heating fuel is electricity, no shared HVAC, and water heater fuel is other, change water heater fuel to Electric

bs[bs$Heating.Fuel=="Electricity" & !bs$HVAC.Has.Shared.System=="None" & bs$Water.Heater.Fuel=="Other Fuel",]$Water.Heater.Fuel<-"Electricity"
bs[bs$Heating.Fuel=="Electricity" & !bs$HVAC.Has.Shared.System=="None" & bs$Water.Heater.Efficiency=="Other Fuel",]$Water.Heater.Efficiency<-"Electric Standard"
}, error = function(err) {print(err)})
table(bs$Geometry.Garage,bs$Geometry.Floor.Area.Bin,bs$Geometry.Stories)
table(bs$Water.Heater.Fuel,bs$Heating.Fuel,bs$HVAC.Has.Shared.System)

bs_save<-rm_dot2(bs)

write.csv(bs_save,file=fn, row.names = FALSE)
rm(bs)
}
