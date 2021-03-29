# this is a script to identify failed simulations in the resstock results files, and replace them with succesful simlulations

# for the failed simulations due to incompatible garages and hot water systems, I should only have three files to fix:
# 1) 2020, 2030_RR, 2060_RR.
# For all files, I will need to look for fails due to missing weather files in some TX counties, and replace with comparable houses

rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
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

bs<-read.csv("../scen_bscsv/bs2020_180k.csv")
failed<-read.csv("../Eagle_outputs/results_2020.csv")
fail<-failed[failed$completed_status=="Fail",]
f<-fail$building_id

success<-read.csv("../Eagle_outputs/res_2020_fail_success.csv")
f2<-success$building_id

fr <- f[which(f %in% f2 == FALSE)]

rn<-rep(0,length(fr))

for (k in 1:length(fr)) {
  rn[k]<-which(fail$building_id==fr[k])
}

failr<-fail[rn,]

# first fix the easy fails, due to incompatible geometry garage and water heating fuel ######
for (j in 1:nrow(success)) {
  failed[failed$building_id==success$building_id[j],]<-success[j,]
}

fail_fixed<-failed[f,]
# Now fix the TX sims ########
failedTX<-bs[bs$County %in% c("TX, Fisher County", "TX, Nolan County","TX, Stonewall County"),]
# check that all the remaining failed simulations are from the three TX counties with no weather files
all.equal(failedTX$Building, fr)
# see all the sim outputs (fail and success) from TX, 02600 & CZ 3B
# pumaTX<-failed[failed$build_existing_model.puma=="TX, 02600" & failed$build_existing_model.ashrae_iecc_climate_zone_2004=="3B",]

bspumaTX<-bs[bs$PUMA=="TX, 02600" & bs$ASHRAE.IECC.Climate.Zone.2004=="3B",]
table(bspumaTX$County,bspumaTX$Geometry.Building.Type.RECS)

# puma0<-failed[failed$build_existing_model.puma=="TX, 02600",]

TX_repl_SF<-failed[failed$build_existing_model.county %in% c("TX, Scurry County","TX, Mitchell County") & failed$build_existing_model.geometry_building_type_recs=="Single-Family Detached",]
TX_repl_MH<-failed[failed$build_existing_model.puma == "TX, 02600" & failed$build_existing_model.ashrae_iecc_climate_zone_2004 =="3B" & failed$build_existing_model.geometry_building_type_recs=="Mobile Home",]

for (r in 1:length(fr)) {

rs_fail<-failed[fr[r],]
if (bs[bs$Building==rs_fail$building_id,]$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached")) {
  rns<-sample(1:nrow(TX_repl_SF),1)
  rs_fail[,5:204]<-TX_repl_SF[rns,5:204]
  rs_fail$build_existing_model.county<-bs[bs$Building==rs_fail$building_id,]$County
}

if (bs[bs$Building==rs_fail$building_id,]$Geometry.Building.Type.RECS %in% c("Mobile Home")) {
  rns<-sample(1:nrow(TX_repl_MH),1)
  rs_fail[,5:204]<-TX_repl_MH[rns,5:204]
  rs_fail$build_existing_model.county<-bs[bs$Building==rs_fail$building_id,]$County
}

# failr[failr$building_id==fr[r],]<-rs_fail
# fail[fail$building_id==fr[r],]<-rs_fail
failed[failed$building_id==fr[r],]<-rs_fail
}

fail_fixed2<-failed[f,]

failed_save<-rm_dot2(failed)

write.csv(failed_save,file="../Eagle_outputs/res_2020_complete.csv",row.names = FALSE)

# now do the same for the RR_2030 sims ####

rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
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

bs<-read.csv("../scen_bscsv_sim/bs_RR_2030.csv")
failed<-read.csv("../Eagle_outputs/res_RR_2030.csv")
fail<-failed[failed$completed_status=="Fail",]
f<-fail$building_id

success<-read.csv("../Eagle_outputs/res_RR_2030_fail_success.csv")
f2<-success$building_id

fr <- f[which(f %in% f2 == FALSE)]

rn<-rep(0,length(fr))

for (k in 1:length(fr)) {
  rn[k]<-which(fail$building_id==fr[k])
}

failr<-fail[rn,]

# first fix the easy fails, due to incompatible geometry garage and water heating fuel ######
for (j in 1:nrow(success)) {
  failed[failed$building_id==success$building_id[j],]<-success[j,]
}

fail_fixed<-failed[which(failed$building_id %in% f),]
# Now fix the TX sims ########
failedTX<-bs[bs$County %in% c("TX, Fisher County", "TX, Nolan County","TX, Stonewall County"),]
# check that all the remaining failed simulations are from the three TX counties with no weather files
all.equal(failedTX$Building, fr)
# see all the sim outputs (fail and success) from TX, 02600 & CZ 3B
# pumaTX<-failed[failed$build_existing_model.puma=="TX, 02600" & failed$build_existing_model.ashrae_iecc_climate_zone_2004=="3B",]

bspumaTX<-bs[bs$PUMA=="TX, 02600" & bs$ASHRAE.IECC.Climate.Zone.2004=="3B",]
table(bspumaTX$County,bspumaTX$Geometry.Building.Type.RECS)

# puma0<-failed[failed$build_existing_model.puma=="TX, 02600",]

TX_repl_SF<-failed[failed$build_existing_model.county %in% c("TX, Scurry County","TX, Mitchell County") & failed$build_existing_model.geometry_building_type_recs=="Single-Family Detached",]
TX_repl_MH<-failed[failed$build_existing_model.puma == "TX, 02600" & failed$build_existing_model.ashrae_iecc_climate_zone_2004 =="3B" & failed$build_existing_model.geometry_building_type_recs=="Mobile Home",]

for (r in 1:length(fr)) {
  
  rs_fail<-failed[failed$building_id==fr[r],]
  if (bs[bs$Building==rs_fail$building_id,]$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached")) {
    rns<-sample(1:nrow(TX_repl_SF),1)
    rs_fail[,5:204]<-TX_repl_SF[rns,5:204]
    rs_fail$build_existing_model.county<-bs[bs$Building==rs_fail$building_id,]$County
  }
  
  if (bs[bs$Building==rs_fail$building_id,]$Geometry.Building.Type.RECS %in% c("Mobile Home")) {
    rns<-sample(1:nrow(TX_repl_MH),1)
    rs_fail[,5:204]<-TX_repl_MH[rns,5:204]
    rs_fail$build_existing_model.county<-bs[bs$Building==rs_fail$building_id,]$County
  }
  
  # failr[failr$building_id==fr[r],]<-rs_fail
  # fail[fail$building_id==fr[r],]<-rs_fail
  failed[failed$building_id==fr[r],]<-rs_fail
}

fail_fixed2<-failed[which(failed$building_id %in% f),]

failed_save<-rm_dot2(failed)

write.csv(failed_save,file="../Eagle_outputs/res_RR_2030_complete.csv",row.names = FALSE)

# now do the same for the RR_2060 sims ####

rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
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

bs<-read.csv("../scen_bscsv_sim/bs_RR_2060.csv")
failed<-read.csv("../Eagle_outputs/res_RR_2060.csv")
fail<-failed[failed$completed_status=="Fail",]
f<-fail$building_id

success<-read.csv("../Eagle_outputs/res_RR_2060_fail_success.csv")
f2<-success$building_id

fr <- f[which(f %in% f2 == FALSE)]

rn<-rep(0,length(fr))

for (k in 1:length(fr)) {
  rn[k]<-which(fail$building_id==fr[k])
}

failr<-fail[rn,]

# first fix the easy fails, due to incompatible geometry garage and water heating fuel ######
for (j in 1:nrow(success)) {
  failed[failed$building_id==success$building_id[j],]<-success[j,]
}

fail_fixed<-failed[which(failed$building_id %in% f),]
# Now fix the TX sims ########
failedTX<-bs[bs$County %in% c("TX, Fisher County", "TX, Nolan County","TX, Stonewall County"),]
# check that all the remaining failed simulations are from the three TX counties with no weather files
all.equal(failedTX$Building, fr)
# see all the sim outputs (fail and success) from TX, 02600 & CZ 3B
# pumaTX<-failed[failed$build_existing_model.puma=="TX, 02600" & failed$build_existing_model.ashrae_iecc_climate_zone_2004=="3B",]

bspumaTX<-bs[bs$PUMA=="TX, 02600" & bs$ASHRAE.IECC.Climate.Zone.2004=="3B",]
table(bspumaTX$County,bspumaTX$Geometry.Building.Type.RECS)

# puma0<-failed[failed$build_existing_model.puma=="TX, 02600",]

TX_repl_SF<-failed[failed$build_existing_model.county %in% c("TX, Scurry County","TX, Mitchell County") & failed$build_existing_model.geometry_building_type_recs=="Single-Family Detached",]
TX_repl_MH<-failed[failed$build_existing_model.puma == "TX, 02600" & failed$build_existing_model.ashrae_iecc_climate_zone_2004 =="3B" & failed$build_existing_model.geometry_building_type_recs=="Mobile Home",]

for (r in 1:length(fr)) {
  
  rs_fail<-failed[failed$building_id==fr[r],]
  if (bs[bs$Building==rs_fail$building_id,]$Geometry.Building.Type.RECS %in% c("Single-Family Detached","Single-Family Attached")) {
    rns<-sample(1:nrow(TX_repl_SF),1)
    rs_fail[,5:204]<-TX_repl_SF[rns,5:204]
    rs_fail$build_existing_model.county<-bs[bs$Building==rs_fail$building_id,]$County
  }
  
  if (bs[bs$Building==rs_fail$building_id,]$Geometry.Building.Type.RECS %in% c("Mobile Home")) {
    rns<-sample(1:nrow(TX_repl_MH),1)
    rs_fail[,5:204]<-TX_repl_MH[rns,5:204]
    rs_fail$build_existing_model.county<-bs[bs$Building==rs_fail$building_id,]$County
  }
  
  # failr[failr$building_id==fr[r],]<-rs_fail
  # fail[fail$building_id==fr[r],]<-rs_fail
  failed[failed$building_id==fr[r],]<-rs_fail
}

fail_fixed2<-failed[which(failed$building_id %in% f),]

failed_save<-rm_dot2(failed)

write.csv(failed_save,file="../Eagle_outputs/res_RR_2060_complete.csv",row.names = FALSE)
