# RS results interpretation 
# This script reads in the results csv and uses it to calculate energy consumption by fuel and end use
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")
# import ResStock results csvs
# 2020 base stock
rs2020<-read.csv("../Eagle_outputs/res_2020_complete.csv")
# Regular Renovated (RR) 2020 stock in each sim year
rs25RR<-read.csv("../Eagle_outputs/res_RR_2025.csv")
rs30RR<-read.csv("../Eagle_outputs/res_RR_2030_complete.csv")
rs35RR<-read.csv("../Eagle_outputs/res_RR_2035.csv")
rs40RR<-read.csv("../Eagle_outputs/res_RR_2040.csv")
rs45RR<-read.csv("../Eagle_outputs/res_RR_2045.csv")
rs50RR<-read.csv("../Eagle_outputs/res_RR_2050.csv")
rs55RR<-read.csv("../Eagle_outputs/res_RR_2055.csv")
rs60RR<-read.csv("../Eagle_outputs/res_RR_2060_complete.csv")


# import R modified bcsv files, these describe the characteristics of future cohorts in three stock scenarios (base, hiDR, hiMF) and 4 characteristics scenarios 'scen' (base, DE, RFA, DERFA)
load("../Intermediate_results/agg_bscsv.RData")

# import renovation metadata
load("../Intermediate_results/RenAdvanced.RData")
rs_2020_60_AR<-rs_2020_2060
rm(rs_2020_2060)
load("../Intermediate_results/RenStandard.RData")
rs_2020_60_RR<-rs_2020_2060
rm(rs_2020_2060)

# remove columns of job id simulation details, upgrade details, bathroom spot vent hour, cooling setpoint offset details, corridor, door area and type, eaves, EV, 
# heating setpoint offset details, lighting use (both 100%), some misc equip presence and type, overhangs, report.applicable, single door area, upgrade cost
View(names(rs2020))
rmcol<-c(2:4,6:8,10,12,28:30,34:35,37:38,57:58,84:85,93:96,100:101,106,130,131,199)
colremove<-names(rs2020)[rmcol]
# rs<-rs25RR
result_sum<-function(rs,yr) {
  # rs<-rs[rs$completed_status=="Success",] # hopefully this will not remove any rows.
  # remove unneeded columns to shrink data frame size
  rs<-rs[,-rmcol] 
  # tidy up names a bit
  names(rs)<-gsub("build_existing_model.","",names(rs))
  names(rs)<-gsub("simulation_output_report.","",names(rs))
  
  # calculate energy consumption by end use and fuel in SI units
  rs$Elec_GJ<-rs$total_site_electricity_kwh*0.0036
  rs$Elec_GJ_SPH<-(rs$electricity_heating_kwh+rs$electricity_heating_kwh+rs$electricity_heating_supplemental_kwh+rs$electricity_fans_heating_kwh +rs$electricity_pumps_heating_kwh )*0.0036
  rs$Elec_GJ_SPC<-(rs$electricity_cooling_kwh+rs$electricity_pumps_cooling_kwh +rs$electricity_fans_cooling_kwh)*0.0036
  rs$Elec_GJ_DHW<-(rs$electricity_water_systems_kwh)*0.0036
  rs$Elec_GJ_OTH<-rs$Elec_GJ-rs$Elec_GJ_SPH-rs$Elec_GJ_SPC-rs$Elec_GJ_DHW
  
  rs$Gas_GJ<-rs$total_site_natural_gas_therm*0.1055
  rs$Gas_GJ_SPH<-rs$natural_gas_heating_therm*0.1055
  rs$Gas_GJ_DHW<-rs$natural_gas_water_systems_therm*0.1055
  rs$Gas_GJ_OTH<-rs$Gas_GJ-rs$Gas_GJ_SPH-rs$Gas_GJ_DHW
  
  rs$Oil_GJ<-rs$total_site_fuel_oil_mbtu*1.055
  rs$Oil_GJ_SPH<-rs$fuel_oil_heating_mbtu*1.055
  rs$Oil_GJ_DHW<-rs$fuel_oil_water_systems_mbtu*1.055
  rs$Oil_GJ_OTH<-rs$Oil_GJ-rs$Oil_GJ_SPH-rs$Oil_GJ_DHW
  
  rs$Prop_GJ<-rs$total_site_propane_mbtu*1.055
  rs$Prop_GJ_SPH<-rs$propane_heating_mbtu*1.055
  rs$Prop_GJ_DHW<-rs$propane_water_systems_mbtu*1.055
  rs$Prop_GJ_OTH<-rs$Prop_GJ-rs$Prop_GJ_SPH-rs$Prop_GJ_DHW
  
  rs$Tot_GJ<-rs$Elec_GJ+rs$Gas_GJ+rs$Oil_GJ+rs$Prop_GJ
  
  rs$Tot_GJ_SPH<-rs$Elec_GJ_SPH+rs$Gas_GJ_SPH+rs$Oil_GJ_SPH+rs$Prop_GJ_SPH
  rs$Tot_GJ_SPC<-rs$Elec_GJ_SPC
  rs$Tot_GJ_DHW<-rs$Elec_GJ_DHW+rs$Gas_GJ_DHW+rs$Oil_GJ_DHW+rs$Prop_GJ_DHW
  rs$Tot_GJ_OTH<-rs$Elec_GJ_OTH+rs$Gas_GJ_OTH+rs$Oil_GJ_OTH+rs$Prop_GJ_OTH
  
  rs$Tot_MJ_m2<-1000*rs$Tot_GJ/(rs$floor_area_lighting_ft_2/10.765)
  rs$Year<-yr
  rs$Year_Building<-paste(rs$Year,rs$building_id,sep="_")
  rs
}


# xs<-25 # number of simulations for each year/scenario
rs2020_sum<-result_sum(rs2020,2020)
rs25RR_sum<-result_sum(rs25RR,2025)
rs30RR_sum<-result_sum(rs30RR,2030)
rs35RR_sum<-result_sum(rs35RR,2035)
rs40RR_sum<-result_sum(rs40RR,2040)
rs45RR_sum<-result_sum(rs45RR,2045)
rs50RR_sum<-result_sum(rs50RR,2050)
rs55RR_sum<-result_sum(rs55RR,2055)
rs60RR_sum<-result_sum(rs60RR,2060)

rs_all_RR<-rs_2020_60_RR
rs_all_RR$Year_Building<-paste(rs_all_RR$Year,rs_all_RR$Building,sep="_")

rs_all_RR<-rs_all_RR[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                        "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                        "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                        "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns
# numbered columns are base weight, energy by type, change in renovated systems

rs_all_RR<-rs_all_RR[order(rs_all_RR$Building),]

load("../Intermediate_results/decayFactorsProj.RData")


rs_all_RR$TC<-"MF"
rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all_RR$TC<-paste(rs_all_RR$TC,rs_all_RR$Vintage.ACS,sep="_")
rs_all_RR$ctyTC<-paste(rs_all_RR$County,rs_all_RR$TC,sep = "")
rs_all_RR$ctyTC<-gsub("2010s","2010-19",rs_all_RR$ctyTC)

# at this stage we are at 36 columns
# now add 9 columns for each stock scenario to bring us to 63
rs_all_RR<-left_join(rs_all_RR,sbm,by="ctyTC")
rs_all_RR<-left_join(rs_all_RR,shdrm,by="ctyTC")
rs_all_RR<-left_join(rs_all_RR,shmfm,by="ctyTC")
# rs_all_RR<-left_join(rs_all_RR,shdmm,by="ctyTC") excluding the high dem and high MF scenario

# replace the failed simulations in some TX counties, actually do this later, after adding the energy consumption data
load("../Intermediate_results/FailReplace.RData")

rs_all_RR$sim.range<-"Undefined"
for (b in 1:180000) { # this takes a while, started at 3.14pm
  # for (b in c(1:15,9900,9934)) {
  print(b)
  w<-which(rs_all_RR$Building==b)

  for (sr in 1:(length(w)-1)) {
    rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],rs_all_RR[w[sr+1],"Year"]-5,sep = ".")
  }
  for (sr in length(w)) {
    rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],"2060",sep = ".")
  }
  # create concordance matrix to identify which weighting factors should be zero and non-zero
  conc<-matrix(rep(0,9*length(w)),length(w),9)
  for (c in 1:length(w)) {
    conc[c, which(names(rs_all_RR[37:45])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],1,4),sep="_")):
           which(names(rs_all_RR[37:45])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],6,9),sep="_"))]<-1
  }

  rs_all_RR[w,37:45]<-rs_all_RR[w,37:45]*conc
  rs_all_RR[w,46:54]<-rs_all_RR[w,46:54]*conc
  rs_all_RR[w,55:63]<-rs_all_RR[w,55:63]*conc

}
save(rs_all_RR,file="../Intermediate_results/RenStandard_full.Rdata")
# merge with the energy results
rs_all_RR_res<-rbind(rs2020_sum,rs25RR_sum,rs30RR_sum,rs35RR_sum,rs40RR_sum,rs45RR_sum,rs50RR_sum,rs55RR_sum,rs60RR_sum)
# rs_all_RR_res<-rs_all_RR_res[,c(1:3,176:200)]
rs_all_RR_res<-rs_all_RR_res[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_RR<-merge(rs_all_RR,rs_all_RR_res)
rs_RR<-rs_RR[order(rs_RR$Building),]

# modify the failed TX simulations

rsRRf<-rs_RR[which(rs_RR$Building %in% failrep$fail),] # fail
rsRRr<-rs_RR[which(rs_RR$Building %in% failrep$replace),] # replace

rsRRfr<-rsRRr # fail replace

for (k in 1:nrow(failrep)) {
  f<-failrep$fail[k]
  r<-failrep$replace[k]
  
  rsRRfr[rsRRfr$Building==r,c("Building","building_id", "County","base_weight","ctyTC")]<-
    rsRRf[which(rsRRf$Building==f)[1],c("Building","building_id", "County","base_weight","ctyTC")]
  
  wb<-colSums(rsRRf[rsRRf$Building==f,37:45]) # base weights
  nr<-nrow(rsRRfr[rsRRfr$Building==f,37:45])
  co<-matrix(as.numeric(rsRRfr[rsRRfr$Building==f,37:45]>0),nr,9)
  wbn<-co*matrix(rep(wb,each=nr),nr,9) # new base weights
  
  whd<-colSums(rsRRf[rsRRf$Building==f,46:54]) # hi dr weights 
  whdn<-co*matrix(rep(whd,each=nr),nr,9) # new hi dr weights
  whm<-colSums(rsRRf[rsRRf$Building==f,55:63]) # hi mf weights
  whmn<-co*matrix(rep(whm,each=nr),nr,9) # new hi mf weigts
  
  rsRRfr[rsRRfr$Building==f,37:63]<-cbind(wbn,whdn,whmn)
}

rsRRfr$Year_Building<-paste(rsRRfr$Year,rsRRfr$Building,sep = "_")
# replace the failed with succesful simulations
rs_RRn<-rs_RR[-c(which(rs_RR$Building %in% failrep$fail)),] 
rs_RRn<-rbind(rs_RRn,rsRRfr)
# re-order by building
rs_RRn<-rs_RRn[order(rs_RRn$Building),]


load("../ExtData/ctycode.RData") # from the HSM repo
load("../ExtData/GHGI_MidCase.RData") # Elec GHG int data in Mid-Case scenario
load("../ExtData/GHGI_LowRECost.RData") # Elec GHG int data in Low RE Cost Scenario
ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)

gicty_rto[gicty_rto$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto[gicty_rto$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto<-merge(gicty_rto,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_yr<-gicty_rto[gicty_rto$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic<-dcast(gicty_rto_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic)[2:8]<-paste("GHG_int",names(gic)[2:8],sep="_")
gic$GHG_int_2055<-0.95* gic$GHG_int_2050
gic$GHG_int_2060<-0.95* gic$GHG_int_2055
gic[,2:10]<-gic[,2:10]/3600 # convert from kg/MWh to kg/MJ

# do the same process for the Low RE Cost electricity data
gicty_rto_LREC[gicty_rto_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto_LREC[gicty_rto_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto_LREC<-merge(gicty_rto_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_LREC_yr<-gicty_rto_LREC[gicty_rto_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic_LRE<-dcast(gicty_rto_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic_LRE)[2:8]<-paste("GHG_int",names(gic_LRE)[2:8],sep="_")
gic_LRE$GHG_int_2055<-0.93* gic_LRE$GHG_int_2050 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE$GHG_int_2060<-0.9* gic_LRE$GHG_int_2055 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE[,2:10]<-gic_LRE[,2:10]/3600 # convert from kg/MWh to kg/MJ
names(gic_LRE)[2:10]<-paste(names(gic_LRE)[2:10],"LRE",sep = "_")

# add GHG intensities, Mid-Case
rs_RRn<-left_join(rs_RRn,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_RRn<-left_join(rs_RRn,gic_LRE,by = c("County" = "RS_ID"))

# calculation total energy and GHG
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

# total energy in GJ
rs_RRn[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_RRn$base_weight*rs_RRn[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_RRn$Elec_GJ+rs_RRn$Gas_GJ+rs_RRn$Prop_GJ+rs_RRn$Oil_GJ)

rs_RRn[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_RRn$base_weight*rs_RRn[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_RRn$Elec_GJ+rs_RRn$Gas_GJ+rs_RRn$Prop_GJ+rs_RRn$Oil_GJ)

rs_RRn[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_RRn$base_weight*rs_RRn[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_RRn$Elec_GJ+rs_RRn$Gas_GJ+rs_RRn$Prop_GJ+rs_RRn$Oil_GJ)


# tot kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# tot kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# tot kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))




# calculate avg reductions per renovation type
rs_RRn$redn_hren<-rs_RRn$redn_wren<-rs_RRn$redn_iren<-rs_RRn$redn_cren<-0
rs_RRn$change_hren_only<-rs_RRn$change_wren_only<-rs_RRn$change_iren_only<-rs_RRn$change_cren_only<-FALSE
for (k in 1:180000) { print(k) # this will probably take a while, about 3hs
  w<-which(rs_RRn$Building==k) 
  if (length(w) > 1) { # if there are any renovations
  for (j in 1:(length(w)-1)) {
   if (rs_RRn[w[j+1],]$change_cren!=rs_RRn[w[j],]$change_cren & identical(as.numeric(rs_RRn[w[j+1],31:33]),as.numeric(rs_RRn[w[j],31:33])) ) { # if only change_cren changes
     rs_RRn$redn_cren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
     rs_RRn$change_cren_only[w[j+1]]<-TRUE
   }
    if (rs_RRn[w[j+1],]$change_iren!=rs_RRn[w[j],]$change_iren & identical(as.numeric(rs_RRn[w[j+1],c(30,32,33)]),as.numeric(rs_RRn[w[j],c(30,32,33)])) ) { # if only change_iren changes
      rs_RRn$redn_iren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_iren_only[w[j+1]]<-TRUE
    } 
    if (rs_RRn[w[j+1],]$change_wren!=rs_RRn[w[j],]$change_wren & identical(as.numeric(rs_RRn[w[j+1],c(30,31,33)]),as.numeric(rs_RRn[w[j],c(30,31,33)])) ) { # if only change_wren changes
      rs_RRn$redn_wren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_wren_only[w[j+1]]<-TRUE
    }
    if (rs_RRn[w[j+1],]$change_hren!=rs_RRn[w[j],]$change_hren & identical(as.numeric(rs_RRn[w[j+1],30:32]),as.numeric(rs_RRn[w[j],30:32])) ) { # if only change_hren changes
      rs_RRn$redn_hren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_hren_only[w[j+1]]<-TRUE
    }
  }
  }
}

tapply(rs_RRn$redn_cren,rs_RRn$change_cren_only,mean)
tapply(rs_RRn$redn_iren,rs_RRn$change_iren_only,mean)
tapply(rs_RRn$redn_wren,rs_RRn$change_wren_only,mean)
tapply(rs_RRn$redn_hren,rs_RRn$change_hren_only,mean)

tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Geometry.Building.Type.RECS), mean)
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Geometry.Building.Type.RECS), mean)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Geometry.Building.Type.RECS), mean)
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Geometry.Building.Type.RECS), mean)

tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Vintage), mean)
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Vintage), mean)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Vintage), mean)
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Vintage), mean)

tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Census.Region), mean)
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Census.Region), mean)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Census.Region), mean)
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Census.Region), mean)

# save this modified dataframe
save(rs_RRn,file = "../Intermediate_results/RenStandard_EG.RData")

colSums(rs_RRn[,196:204])*1e-9 # now they look correct

# repeat the long function of adding decay factors with the AR files ########
rs_all_AR<-rs_2020_60_AR
rs_all_AR$Year_Building<-paste(rs_all_AR$Year,rs_all_AR$Building,sep="_")

rs_all_AR<-rs_all_AR[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                        "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                        "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                        "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns

rs_all_AR<-rs_all_AR[order(rs_all_AR$Building),]

rs_all_AR$TC<-"MF"
rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all_AR$TC<-paste(rs_all_AR$TC,rs_all_AR$Vintage.ACS,sep="_")
rs_all_AR$ctyTC<-paste(rs_all_AR$County,rs_all_AR$TC,sep = "")
rs_all_AR$ctyTC<-gsub("2010s","2010-19",rs_all_AR$ctyTC)

# at this stage we are at 36 columns
# now add 9 columns for each stock scenario to bring us to 63
rs_all_AR<-left_join(rs_all_AR,sbm,by="ctyTC")
rs_all_AR<-left_join(rs_all_AR,shdrm,by="ctyTC")
rs_all_AR<-left_join(rs_all_AR,shmfm,by="ctyTC")
# rs_all_AR<-left_join(rs_all_AR,shdmm,by="ctyTC") excluding the high dem and high MF scenario


rs_all_AR$sim.range<-"Undefined"
for (b in 1:180000) { # this takes a while, up to 4 hours
  # for (b in c(1:15,9900,9934)) {
  print(b)
  w<-which(rs_all_AR$Building==b)
  
  for (sr in 1:(length(w)-1)) {
    rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],rs_all_AR[w[sr+1],"Year"]-5,sep = ".")
  }
  for (sr in length(w)) {
    rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],"2060",sep = ".")
  }
  # create concordance matrix to identify which weighting factors should be zero and non-zero
  conc<-matrix(rep(0,9*length(w)),length(w),9)
  for (c in 1:length(w)) {
    conc[c, which(names(rs_all_AR[37:45])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],1,4),sep="_")):
           which(names(rs_all_AR[37:45])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],6,9),sep="_"))]<-1
  }
  
  rs_all_AR[w,37:45]<-rs_all_AR[w,37:45]*conc
  rs_all_AR[w,46:54]<-rs_all_AR[w,46:54]*conc
  rs_all_AR[w,55:63]<-rs_all_AR[w,55:63]*conc
  
}
save(rs_all_AR,file="../Intermediate_results/RenAdvanced_full.Rdata")




# add GHG intensities, Mid-Case
rs_all_AR<-left_join(rs_all_AR,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_all_AR<-left_join(rs_all_AR,gic_LRE,by = c("County" = "RS_ID"))
# merge resstock baseline stock scenario results with pre-simulation meta data ###### for this step i need the completed simulation of the future cohorts
rs_base_sum<-result_sum(rs_base)
bs_base_meta<-bs_base_all[,c("Building","sim_year","scen","Building_id")]
rs_base_sum<-merge(rs_base_sum,bs_base_meta,by.x = "building_id",by.y = "Building")
# extract individual results for base stock scenarios, with different combinations of electrification/floor area characteristics
rs_base_base<-rs_base_sum[rs_base_sum$scen=="base",]
rs_base_base$cht_group<-0
rs_base_base[rs_base_base$sim_year==2030,]$cht_group<-1
rs_base_base[rs_base_base$sim_year==2035,]$cht_group<-2
rs_base_base[rs_base_base$sim_year==2040,]$cht_group<-3
rs_base_base[rs_base_base$sim_year==2045,]$cht_group<-4
rs_base_base[rs_base_base$sim_year==2050,]$cht_group<-5
rs_base_base[rs_base_base$sim_year==2055,]$cht_group<-6
rs_base_base[rs_base_base$sim_year==2060,]$cht_group<-7
rs_base_base$Building_id0<-(xs*rs_base_base$cht_group)+rs_base_base$Building_id
bid<-data.frame(bid=dupe_base-xs)
rs_base_base<-rbind(rs_base_base,inner_join(rs_base_base,bid,by=c("Building_id0"="bid")))
rs_base_base[(nrow(rs_base_base)-length(dupe_base)+1):nrow(rs_base_base),]$Building_id0<-dupe_base
rs_base_base<-rs_base_base[order(rs_base_base$Building_id0),]
rs_base_base$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_base$Tot_MJ_m2,rs_base_base$sim_year,mean)
tapply(rs_base_base$Tot_GJ,rs_base_base$sim_year,mean)

# deep electrification
rs_base_DE<-rs_base_sum[rs_base_sum$scen=="baseDE",]
rs_base_DE$cht_group<-0
rs_base_DE[rs_base_DE$sim_year==2030,]$cht_group<-1
rs_base_DE[rs_base_DE$sim_year==2035,]$cht_group<-2
rs_base_DE[rs_base_DE$sim_year==2040,]$cht_group<-3
rs_base_DE[rs_base_DE$sim_year==2045,]$cht_group<-4
rs_base_DE[rs_base_DE$sim_year==2050,]$cht_group<-5
rs_base_DE[rs_base_DE$sim_year==2055,]$cht_group<-6
rs_base_DE[rs_base_DE$sim_year==2060,]$cht_group<-7
rs_base_DE$Building_id0<-(xs*rs_base_DE$cht_group)+rs_base_DE$Building_id
bid<-data.frame(bid=dupe_baseDE-xs)
rs_base_DE<-rbind(rs_base_DE,inner_join(rs_base_DE,bid,by=c("Building_id0"="bid")))
rs_base_DE[(nrow(rs_base_DE)-length(dupe_baseDE)+1):nrow(rs_base_DE),]$Building_id0<-dupe_baseDE
rs_base_DE<-rs_base_DE[order(rs_base_DE$Building_id0),]
rs_base_DE$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_DE$Tot_MJ_m2,rs_base_DE$sim_year,mean)
tapply(rs_base_DE$Tot_GJ,rs_base_DE$sim_year,mean)

# reduced Floor Area
rs_base_RFA<-rs_base_sum[rs_base_sum$scen=="baseRFA",]
rs_base_RFA$cht_group<-0
rs_base_RFA[rs_base_RFA$sim_year==2030,]$cht_group<-1
rs_base_RFA[rs_base_RFA$sim_year==2035,]$cht_group<-2
rs_base_RFA[rs_base_RFA$sim_year==2040,]$cht_group<-3
rs_base_RFA[rs_base_RFA$sim_year==2045,]$cht_group<-4
rs_base_RFA[rs_base_RFA$sim_year==2050,]$cht_group<-5
rs_base_RFA[rs_base_RFA$sim_year==2055,]$cht_group<-6
rs_base_RFA[rs_base_RFA$sim_year==2060,]$cht_group<-7
rs_base_RFA$Building_id0<-(xs*rs_base_RFA$cht_group)+rs_base_RFA$Building_id
bid<-data.frame(bid=dupe_baseRFA-xs)
rs_base_RFA<-rbind(rs_base_RFA,inner_join(rs_base_RFA,bid,by=c("Building_id0"="bid")))
rs_base_RFA[(nrow(rs_base_RFA)-length(dupe_baseRFA)+1):nrow(rs_base_RFA),]$Building_id0<-dupe_baseRFA
rs_base_RFA<-rs_base_RFA[order(rs_base_RFA$Building_id0),]
rs_base_RFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_RFA$Tot_MJ_m2,rs_base_RFA$sim_year,mean)
tapply(rs_base_RFA$Tot_GJ,rs_base_RFA$sim_year,mean)

# reduced Floor Area
rs_base_DERFA<-rs_base_sum[rs_base_sum$scen=="baseDERFA",]
rs_base_DERFA$cht_group<-0
rs_base_DERFA[rs_base_DERFA$sim_year==2030,]$cht_group<-1
rs_base_DERFA[rs_base_DERFA$sim_year==2035,]$cht_group<-2
rs_base_DERFA[rs_base_DERFA$sim_year==2040,]$cht_group<-3
rs_base_DERFA[rs_base_DERFA$sim_year==2045,]$cht_group<-4
rs_base_DERFA[rs_base_DERFA$sim_year==2050,]$cht_group<-5
rs_base_DERFA[rs_base_DERFA$sim_year==2055,]$cht_group<-6
rs_base_DERFA[rs_base_DERFA$sim_year==2060,]$cht_group<-7
rs_base_DERFA$Building_id0<-(xs*rs_base_DERFA$cht_group)+rs_base_DERFA$Building_id
bid<-data.frame(bid=dupe_baseDERFA-xs)
rs_base_DERFA<-rbind(rs_base_DERFA,inner_join(rs_base_DERFA,bid,by=c("Building_id0"="bid")))
rs_base_DERFA[(nrow(rs_base_DERFA)-length(dupe_baseDERFA)+1):nrow(rs_base_DERFA),]$Building_id0<-dupe_baseDERFA
rs_base_DERFA<-rs_base_DERFA[order(rs_base_DERFA$Building_id0),]
rs_base_DERFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_DERFA$Tot_MJ_m2,rs_base_DERFA$sim_year,mean)
tapply(rs_base_DERFA$Tot_GJ,rs_base_DERFA$sim_year,mean)


# merge resstock hiDR stock scenario results with pre-simulation meta data #########
rs_hiDR_sum<-result_sum(rs_hiDR)
bs_hiDR_meta<-bs_hiDR_all[,c("Building","sim_year","scen","Building_id")]
rs_hiDR_sum<-merge(rs_hiDR_sum,bs_hiDR_meta,by.x = "building_id",by.y = "Building")
# extract individual results for hiDR stock scenarios, with different combinations of electrification/floor area characteristics
rs_hiDR_base<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDR",]
rs_hiDR_base$cht_group<-0
rs_hiDR_base[rs_hiDR_base$sim_year==2030,]$cht_group<-1
rs_hiDR_base[rs_hiDR_base$sim_year==2035,]$cht_group<-2
rs_hiDR_base[rs_hiDR_base$sim_year==2040,]$cht_group<-3
rs_hiDR_base[rs_hiDR_base$sim_year==2045,]$cht_group<-4
rs_hiDR_base[rs_hiDR_base$sim_year==2050,]$cht_group<-5
rs_hiDR_base[rs_hiDR_base$sim_year==2055,]$cht_group<-6
rs_hiDR_base[rs_hiDR_base$sim_year==2060,]$cht_group<-7
rs_hiDR_base$Building_id0<-(xs*rs_hiDR_base$cht_group)+rs_hiDR_base$Building_id
bid<-data.frame(bid=dupe_hiDR-xs)
rs_hiDR_base<-rbind(rs_hiDR_base,inner_join(rs_hiDR_base,bid,by=c("Building_id0"="bid")))
rs_hiDR_base[(nrow(rs_hiDR_base)-length(dupe_hiDR)+1):nrow(rs_hiDR_base),]$Building_id0<-dupe_hiDR
rs_hiDR_base<-rs_hiDR_base[order(rs_hiDR_base$Building_id0),]
rs_hiDR_base$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_base$Tot_MJ_m2,rs_hiDR_base$sim_year,mean)
tapply(rs_hiDR_base$Tot_GJ,rs_hiDR_base$sim_year,mean)

# deep electrification
rs_hiDR_DE<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDRDE",]
rs_hiDR_DE$cht_group<-0
rs_hiDR_DE[rs_hiDR_DE$sim_year==2030,]$cht_group<-1
rs_hiDR_DE[rs_hiDR_DE$sim_year==2035,]$cht_group<-2
rs_hiDR_DE[rs_hiDR_DE$sim_year==2040,]$cht_group<-3
rs_hiDR_DE[rs_hiDR_DE$sim_year==2045,]$cht_group<-4
rs_hiDR_DE[rs_hiDR_DE$sim_year==2050,]$cht_group<-5
rs_hiDR_DE[rs_hiDR_DE$sim_year==2055,]$cht_group<-6
rs_hiDR_DE[rs_hiDR_DE$sim_year==2060,]$cht_group<-7
rs_hiDR_DE$Building_id0<-(xs*rs_hiDR_DE$cht_group)+rs_hiDR_DE$Building_id
bid<-data.frame(bid=dupe_hiDRDE-xs)
rs_hiDR_DE<-rbind(rs_hiDR_DE,inner_join(rs_hiDR_DE,bid,by=c("Building_id0"="bid")))
rs_hiDR_DE[(nrow(rs_hiDR_DE)-length(dupe_hiDRDE)+1):nrow(rs_hiDR_DE),]$Building_id0<-dupe_hiDRDE
rs_hiDR_DE<-rs_hiDR_DE[order(rs_hiDR_DE$Building_id0),]
rs_hiDR_DE$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_DE$Tot_MJ_m2,rs_hiDR_DE$sim_year,mean)
tapply(rs_hiDR_DE$Tot_GJ,rs_hiDR_DE$sim_year,mean)

# reduced Floor Area
rs_hiDR_RFA<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDRRFA",]
rs_hiDR_RFA$cht_group<-0
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2030,]$cht_group<-1
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2035,]$cht_group<-2
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2040,]$cht_group<-3
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2045,]$cht_group<-4
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2050,]$cht_group<-5
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2055,]$cht_group<-6
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2060,]$cht_group<-7
rs_hiDR_RFA$Building_id0<-(xs*rs_hiDR_RFA$cht_group)+rs_hiDR_RFA$Building_id
bid<-data.frame(bid=dupe_hiDRRFA-xs)
rs_hiDR_RFA<-rbind(rs_hiDR_RFA,inner_join(rs_hiDR_RFA,bid,by=c("Building_id0"="bid")))
rs_hiDR_RFA[(nrow(rs_hiDR_RFA)-length(dupe_hiDRRFA)+1):nrow(rs_hiDR_RFA),]$Building_id0<-dupe_hiDRRFA
rs_hiDR_RFA<-rs_hiDR_RFA[order(rs_hiDR_RFA$Building_id0),]
rs_hiDR_RFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_RFA$Tot_MJ_m2,rs_hiDR_RFA$sim_year,mean)
tapply(rs_hiDR_RFA$Tot_GJ,rs_hiDR_RFA$sim_year,mean)

# reduced Floor Area
rs_hiDR_DERFA<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDRDERFA",]
rs_hiDR_DERFA$cht_group<-0
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2030,]$cht_group<-1
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2035,]$cht_group<-2
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2040,]$cht_group<-3
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2045,]$cht_group<-4
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2050,]$cht_group<-5
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2055,]$cht_group<-6
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2060,]$cht_group<-7
rs_hiDR_DERFA$Building_id0<-(xs*rs_hiDR_DERFA$cht_group)+rs_hiDR_DERFA$Building_id
bid<-data.frame(bid=dupe_hiDRDERFA-xs)
rs_hiDR_DERFA<-rbind(rs_hiDR_DERFA,inner_join(rs_hiDR_DERFA,bid,by=c("Building_id0"="bid")))
rs_hiDR_DERFA[(nrow(rs_hiDR_DERFA)-length(dupe_hiDRDERFA)+1):nrow(rs_hiDR_DERFA),]$Building_id0<-dupe_hiDRDERFA
rs_hiDR_DERFA<-rs_hiDR_DERFA[order(rs_hiDR_DERFA$Building_id0),]
rs_hiDR_DERFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_DERFA$Tot_MJ_m2,rs_hiDR_DERFA$sim_year,mean)
tapply(rs_hiDR_DERFA$Tot_GJ,rs_hiDR_DERFA$sim_year,mean)

# merge resstock hiDR stock scenario results with pre-simulation meta data #########
rs_hiMF_sum<-result_sum(rs_hiMF)
bs_hiMF_meta<-bs_hiMF_all[,c("Building","sim_year","scen","Building_id")]
rs_hiMF_sum<-merge(rs_hiMF_sum,bs_hiMF_meta,by.x = "building_id",by.y = "Building")
# extract individual results for hiMF stock scenarios, with different combinations of electrification/floor area characteristics
rs_hiMF_base<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMF",]
rs_hiMF_base$cht_group<-0
rs_hiMF_base[rs_hiMF_base$sim_year==2030,]$cht_group<-1
rs_hiMF_base[rs_hiMF_base$sim_year==2035,]$cht_group<-2
rs_hiMF_base[rs_hiMF_base$sim_year==2040,]$cht_group<-3
rs_hiMF_base[rs_hiMF_base$sim_year==2045,]$cht_group<-4
rs_hiMF_base[rs_hiMF_base$sim_year==2050,]$cht_group<-5
rs_hiMF_base[rs_hiMF_base$sim_year==2055,]$cht_group<-6
rs_hiMF_base[rs_hiMF_base$sim_year==2060,]$cht_group<-7
rs_hiMF_base$Building_id0<-(xs*rs_hiMF_base$cht_group)+rs_hiMF_base$Building_id
bid<-data.frame(bid=dupe_hiMF-xs)
rs_hiMF_base<-rbind(rs_hiMF_base,inner_join(rs_hiMF_base,bid,by=c("Building_id0"="bid")))
rs_hiMF_base[(nrow(rs_hiMF_base)-length(dupe_hiMF)+1):nrow(rs_hiMF_base),]$Building_id0<-dupe_hiMF
rs_hiMF_base<-rs_hiMF_base[order(rs_hiMF_base$Building_id0),]
rs_hiMF_base$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_base$Tot_MJ_m2,rs_hiMF_base$sim_year,mean)
tapply(rs_hiMF_base$Tot_GJ,rs_hiMF_base$sim_year,mean)

# deep electrification
rs_hiMF_DE<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMFDE",]
rs_hiMF_DE$cht_group<-0
rs_hiMF_DE[rs_hiMF_DE$sim_year==2030,]$cht_group<-1
rs_hiMF_DE[rs_hiMF_DE$sim_year==2035,]$cht_group<-2
rs_hiMF_DE[rs_hiMF_DE$sim_year==2040,]$cht_group<-3
rs_hiMF_DE[rs_hiMF_DE$sim_year==2045,]$cht_group<-4
rs_hiMF_DE[rs_hiMF_DE$sim_year==2050,]$cht_group<-5
rs_hiMF_DE[rs_hiMF_DE$sim_year==2055,]$cht_group<-6
rs_hiMF_DE[rs_hiMF_DE$sim_year==2060,]$cht_group<-7
rs_hiMF_DE$Building_id0<-(xs*rs_hiMF_DE$cht_group)+rs_hiMF_DE$Building_id
bid<-data.frame(bid=dupe_hiMFDE-xs)
rs_hiMF_DE<-rbind(rs_hiMF_DE,inner_join(rs_hiMF_DE,bid,by=c("Building_id0"="bid")))
rs_hiMF_DE[(nrow(rs_hiMF_DE)-length(dupe_hiMFDE)+1):nrow(rs_hiMF_DE),]$Building_id0<-dupe_hiMFDE
rs_hiMF_DE<-rs_hiMF_DE[order(rs_hiMF_DE$Building_id0),]
rs_hiMF_DE$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_DE$Tot_MJ_m2,rs_hiMF_DE$sim_year,mean)
tapply(rs_hiMF_DE$Tot_GJ,rs_hiMF_DE$sim_year,mean)

# reduced Floor Area
rs_hiMF_RFA<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMFRFA",]
rs_hiMF_RFA$cht_group<-0
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2030,]$cht_group<-1
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2035,]$cht_group<-2
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2040,]$cht_group<-3
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2045,]$cht_group<-4
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2050,]$cht_group<-5
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2055,]$cht_group<-6
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2060,]$cht_group<-7
rs_hiMF_RFA$Building_id0<-(xs*rs_hiMF_RFA$cht_group)+rs_hiMF_RFA$Building_id
bid<-data.frame(bid=dupe_hiMFRFA-xs)
rs_hiMF_RFA<-rbind(rs_hiMF_RFA,inner_join(rs_hiMF_RFA,bid,by=c("Building_id0"="bid")))
rs_hiMF_RFA[(nrow(rs_hiMF_RFA)-length(dupe_hiMFRFA)+1):nrow(rs_hiMF_RFA),]$Building_id0<-dupe_hiMFRFA
rs_hiMF_RFA<-rs_hiMF_RFA[order(rs_hiMF_RFA$Building_id0),]
rs_hiMF_RFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_RFA$Tot_MJ_m2,rs_hiMF_RFA$sim_year,mean)
tapply(rs_hiMF_RFA$Tot_GJ,rs_hiMF_RFA$sim_year,mean)

# reduced Floor Area
rs_hiMF_DERFA<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMFDERFA",]
rs_hiMF_DERFA$cht_group<-0
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2030,]$cht_group<-1
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2035,]$cht_group<-2
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2040,]$cht_group<-3
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2045,]$cht_group<-4
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2050,]$cht_group<-5
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2055,]$cht_group<-6
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2060,]$cht_group<-7
rs_hiMF_DERFA$Building_id0<-(xs*rs_hiMF_DERFA$cht_group)+rs_hiMF_DERFA$Building_id
bid<-data.frame(bid=dupe_hiMFDERFA-xs)
rs_hiMF_DERFA<-rbind(rs_hiMF_DERFA,inner_join(rs_hiMF_DERFA,bid,by=c("Building_id0"="bid")))
rs_hiMF_DERFA[(nrow(rs_hiMF_DERFA)-length(dupe_hiMFDERFA)+1):nrow(rs_hiMF_DERFA),]$Building_id0<-dupe_hiMFDERFA
rs_hiMF_DERFA<-rs_hiMF_DERFA[order(rs_hiMF_DERFA$Building_id0),]
rs_hiMF_DERFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_DERFA$Tot_MJ_m2,rs_hiMF_DERFA$sim_year,mean)
tapply(rs_hiMF_DERFA$Tot_GJ,rs_hiMF_DERFA$sim_year,mean)

# compare efficiencies
tapply(rs_base_base$Tot_GJ,rs_base_base$vintage,mean)
tapply(rs_base_DE$Tot_GJ,rs_base_DE$vintage,mean)
tapply(rs_base_RFA$Tot_GJ,rs_base_RFA$vintage,mean)
tapply(rs_base_DERFA$Tot_GJ,rs_base_DERFA$vintage,mean)

tapply(rs_hiDR_base$Tot_GJ,rs_hiDR_base$vintage,mean)
tapply(rs_hiDR_DE$Tot_GJ,rs_hiDR_DE$vintage,mean)
tapply(rs_hiDR_RFA$Tot_GJ,rs_hiDR_RFA$vintage,mean)
tapply(rs_hiDR_DERFA$Tot_GJ,rs_hiDR_DERFA$vintage,mean)

tapply(rs_hiMF_base$Tot_GJ,rs_hiMF_base$vintage,mean)
tapply(rs_hiMF_DE$Tot_GJ,rs_hiMF_DE$vintage,mean)
tapply(rs_hiMF_RFA$Tot_GJ,rs_hiMF_RFA$vintage,mean)
tapply(rs_hiMF_DERFA$Tot_GJ,rs_hiMF_DERFA$vintage,mean)

tapply(rs_2020_sum$Tot_GJ,rs_2020_sum$vintage,mean)

save(rs_2020_sum,rs_base_base,rs_base_DE,rs_base_RFA,rs_base_DERFA,
     rs_hiDR_base,rs_hiDR_DE,rs_hiDR_RFA,rs_hiDR_DERFA,
     rs_hiMF_base,rs_hiMF_DE,rs_hiMF_RFA,rs_hiMF_DERFA,file="../Final_results/results_summaries.RData")

# compared household energy by different groups
# tapply(d$Tot_GJ_unit,d$building_america_climate_zone,mean)
# 
# tapply(d$Tot_GJ_unit,d$geometry_building_type_recs,mean)
# 
# tapply(d$Tot_GJ_unit,d$vintage,mean)
# 
# tapply(d$Tot_MJ_m2,d$geometry_building_type_recs,mean)

d10<-result_sum(rs2010)
d20<-result_sum(rs2020)
d30<-result_sum(rs2030)
d40<-result_sum(rs2040)
d50<-result_sum(rs2050)

tapply(d10$Oil_GJ,d10$heating_fuel,mean)
tapply(d20$Oil_GJ,d20$heating_fuel,mean) # ok there are no new homes built with oil

tapply(d10$Gas_GJ,d10$heating_fuel,mean)
tapply(d20$Gas_GJ,d20$heating_fuel,mean)
tapply(d30$Gas_GJ,d30$heating_fuel,mean)
tapply(d40$Gas_GJ,d40$heating_fuel,mean)
tapply(d50$Gas_GJ,d50$heating_fuel,mean)

tapply(d10$Gas_GJ,list(d10$heating_fuel,d10$water_heater_fuel),mean)
# compare 2010s with 2020s ##########
d10$Gas_GJ_20<-NA
d10$Elec_GJ_20<-NA
d10$Prop_GJ_20<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d20)) {
    # d10[d10$building_id[i]==d20$building_id[j],]$Gas_GJ_20<-d20$Gas_GJ[j]
    if (d10$building_id[i]==d20$building_id[j] & d10$heating_fuel[i]==d20$heating_fuel[j] &d10$water_heater_fuel[i]==d20$water_heater_fuel[j]) {
      d10$Gas_GJ_20[i]<-d20$Gas_GJ[j]
      d10$Elec_GJ_20[i]<-d20$Elec_GJ[j]
      d10$Prop_GJ_20[i]<-d20$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_20_10<-d10$Gas_GJ_20/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_20_10) | is.infinite((d10$Gas_GJ_20_10)),]$Gas_GJ_20_10<-NA
mean(d10$Gas_GJ_20_10,na.rm = TRUE) # 15% reduction in gas in 2020 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_20_10,na.rm = TRUE ) # 14% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_20_10,na.rm = TRUE ) # 26% in MF

d10$Elec_GJ_20_10<-d10$Elec_GJ_20/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_20_10) | is.infinite((d10$Elec_GJ_20_10)),]$Elec_GJ_20_10<-NA # not applicable to elec
mean(d10$Elec_GJ_20_10,na.rm = TRUE) # 9% reduction in Elec in 2020 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_20_10,na.rm = TRUE ) # 8% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_20_10,na.rm = TRUE ) # 14% in MF

d10$Prop_GJ_20_10<-d10$Prop_GJ_20/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_20_10) | is.infinite((d10$Prop_GJ_20_10)),]$Prop_GJ_20_10<-NA
mean(d10$Prop_GJ_20_10,na.rm = TRUE) # 42% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample
# compare with 2030s ########
d10$Gas_GJ_30<-NA
d10$Elec_GJ_30<-NA
d10$Prop_GJ_30<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d30)) {
    # d10[d10$building_id[i]==d30$building_id[j],]$Gas_GJ_30<-d30$Gas_GJ[j]
    if (d10$building_id[i]==d30$building_id[j] & d10$heating_fuel[i]==d30$heating_fuel[j] &d10$water_heater_fuel[i]==d30$water_heater_fuel[j]) {
      d10$Gas_GJ_30[i]<-d30$Gas_GJ[j]
      d10$Elec_GJ_30[i]<-d30$Elec_GJ[j]
      d10$Prop_GJ_30[i]<-d30$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_30_10<-d10$Gas_GJ_30/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_30_10) | is.infinite((d10$Gas_GJ_30_10)),]$Gas_GJ_30_10<-NA
mean(d10$Gas_GJ_30_10,na.rm = TRUE) # 28% reduction in gas in 2030 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_30_10,na.rm = TRUE ) # 28% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_30_10,na.rm = TRUE ) # 24% in MF

d10$Elec_GJ_30_10<-d10$Elec_GJ_30/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_30_10) | is.infinite((d10$Elec_GJ_30_10)),]$Elec_GJ_30_10<-NA # not applicable to elec
mean(d10$Elec_GJ_30_10,na.rm = TRUE) # 16% reduction in Elec in 2030 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_30_10,na.rm = TRUE ) # 16% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_30_10,na.rm = TRUE ) # 15% in MF

d10$Prop_GJ_30_10<-d10$Prop_GJ_30/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_30_10) | is.infinite((d10$Prop_GJ_30_10)),]$Prop_GJ_30_10<-NA
mean(d10$Prop_GJ_30_10,na.rm = TRUE) # 54% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample

# compare with 2040s ########
d10$Gas_GJ_40<-NA
d10$Elec_GJ_40<-NA
d10$Prop_GJ_40<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d40)) {
    # d10[d10$building_id[i]==d40$building_id[j],]$Gas_GJ_40<-d40$Gas_GJ[j]
    if (d10$building_id[i]==d40$building_id[j] & d10$heating_fuel[i]==d40$heating_fuel[j] &d10$water_heater_fuel[i]==d40$water_heater_fuel[j]) {
      d10$Gas_GJ_40[i]<-d40$Gas_GJ[j]
      d10$Elec_GJ_40[i]<-d40$Elec_GJ[j]
      d10$Prop_GJ_40[i]<-d40$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_40_10<-d10$Gas_GJ_40/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_40_10) | is.infinite((d10$Gas_GJ_40_10)),]$Gas_GJ_40_10<-NA
mean(d10$Gas_GJ_40_10,na.rm = TRUE) # 35% reduction in gas in 2040 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_40_10,na.rm = TRUE ) # 36% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_40_10,na.rm = TRUE ) # 29% in MF, 8 observations

d10$Elec_GJ_40_10<-d10$Elec_GJ_40/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_40_10) | is.infinite((d10$Elec_GJ_40_10)),]$Elec_GJ_40_10<-NA # not applicable to elec
mean(d10$Elec_GJ_40_10,na.rm = TRUE) # 22% reduction in Elec in 2040 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_40_10,na.rm = TRUE ) # 23% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_40_10,na.rm = TRUE ) # 18% in MF, 14 observations

d10$Prop_GJ_40_10<-d10$Prop_GJ_40/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_40_10) | is.infinite((d10$Prop_GJ_40_10)),]$Prop_GJ_40_10<-NA
mean(d10$Prop_GJ_40_10,na.rm = TRUE) # 60% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample

# compare with 2050s ########
d10$Gas_GJ_50<-NA
d10$Elec_GJ_50<-NA
d10$Prop_GJ_50<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d50)) {
    # d10[d10$building_id[i]==d50$building_id[j],]$Gas_GJ_50<-d50$Gas_GJ[j]
    if (d10$building_id[i]==d50$building_id[j] & d10$heating_fuel[i]==d50$heating_fuel[j] &d10$water_heater_fuel[i]==d50$water_heater_fuel[j]) {
      d10$Gas_GJ_50[i]<-d50$Gas_GJ[j]
      d10$Elec_GJ_50[i]<-d50$Elec_GJ[j]
      d10$Prop_GJ_50[i]<-d50$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_50_10<-d10$Gas_GJ_50/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_50_10) | is.infinite((d10$Gas_GJ_50_10)),]$Gas_GJ_50_10<-NA
mean(d10$Gas_GJ_50_10,na.rm = TRUE) # 36% reduction in gas in 2050 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_50_10,na.rm = TRUE ) # 43% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_50_10,na.rm = TRUE ) # 7% in MF, base on only 5 observations

d10$Elec_GJ_50_10<-d10$Elec_GJ_50/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_50_10) | is.infinite((d10$Elec_GJ_50_10)),]$Elec_GJ_50_10<-NA # not applicable to elec
mean(d10$Elec_GJ_50_10,na.rm = TRUE) # 25% reduction in Elec in 2050 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_50_10,na.rm = TRUE ) # 26% in SF, 48 observation
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_50_10,na.rm = TRUE ) # 24% in MF, 10 observations

d10$Prop_GJ_50_10<-d10$Prop_GJ_50/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_50_10) | is.infinite((d10$Prop_GJ_50_10)),]$Prop_GJ_50_10<-NA
mean(d10$Prop_GJ_50_10,na.rm = TRUE) # 0% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample