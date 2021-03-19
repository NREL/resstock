# create csv files for simulation
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

load("../Intermediate_results/RenStandard.RData")
rs_RR<-rs_2020_2060
load("../Intermediate_results/RenAdvanced.RData")
rs_AR<-rs_2020_2060
rm(rs_2020_2060)

rs_RR_2025<-rm_dot2(rs_RR[rs_RR$Year==2025,1:114])
rs_RR_2030<-rm_dot2(rs_RR[rs_RR$Year==2030,1:114])
rs_RR_2035<-rm_dot2(rs_RR[rs_RR$Year==2035,1:114])
rs_RR_2040<-rm_dot2(rs_RR[rs_RR$Year==2040,1:114])
rs_RR_2045<-rm_dot2(rs_RR[rs_RR$Year==2045,1:114])
rs_RR_2050<-rm_dot2(rs_RR[rs_RR$Year==2050,1:114])
rs_RR_2055<-rm_dot2(rs_RR[rs_RR$Year==2055,1:114])
rs_RR_2060<-rm_dot2(rs_RR[rs_RR$Year==2060,1:114])

rs_AR_2025<-rm_dot2(rs_AR[rs_AR$Year==2025,1:114])
rs_AR_2030<-rm_dot2(rs_AR[rs_AR$Year==2030,1:114])
rs_AR_2035<-rm_dot2(rs_AR[rs_AR$Year==2035,1:114])
rs_AR_2040<-rm_dot2(rs_AR[rs_AR$Year==2040,1:114])
rs_AR_2045<-rm_dot2(rs_AR[rs_AR$Year==2045,1:114])
rs_AR_2050<-rm_dot2(rs_AR[rs_AR$Year==2050,1:114])
rs_AR_2055<-rm_dot2(rs_AR[rs_AR$Year==2055,1:114])
rs_AR_2060<-rm_dot2(rs_AR[rs_AR$Year==2060,1:114])


write.csv(rs_RR_2025,file='../scen_bscsv_sim/bs_RR_2025.csv', row.names = FALSE)
write.csv(rs_RR_2030,file='../scen_bscsv_sim/bs_RR_2030.csv', row.names = FALSE)
write.csv(rs_RR_2035,file='../scen_bscsv_sim/bs_RR_2035.csv', row.names = FALSE)
write.csv(rs_RR_2040,file='../scen_bscsv_sim/bs_RR_2040.csv', row.names = FALSE)
write.csv(rs_RR_2045,file='../scen_bscsv_sim/bs_RR_2045.csv', row.names = FALSE)
write.csv(rs_RR_2050,file='../scen_bscsv_sim/bs_RR_2050.csv', row.names = FALSE)
write.csv(rs_RR_2055,file='../scen_bscsv_sim/bs_RR_2055.csv', row.names = FALSE)
write.csv(rs_RR_2060,file='../scen_bscsv_sim/bs_RR_2060.csv', row.names = FALSE)

write.csv(rs_AR_2025,file='../scen_bscsv_sim/bs_AR_2025.csv', row.names = FALSE)
write.csv(rs_AR_2030,file='../scen_bscsv_sim/bs_AR_2030.csv', row.names = FALSE)
write.csv(rs_AR_2035,file='../scen_bscsv_sim/bs_AR_2035.csv', row.names = FALSE)
write.csv(rs_AR_2040,file='../scen_bscsv_sim/bs_AR_2040.csv', row.names = FALSE)
write.csv(rs_AR_2045,file='../scen_bscsv_sim/bs_AR_2045.csv', row.names = FALSE)
write.csv(rs_AR_2050,file='../scen_bscsv_sim/bs_AR_2050.csv', row.names = FALSE)
write.csv(rs_AR_2055,file='../scen_bscsv_sim/bs_AR_2055.csv', row.names = FALSE)
write.csv(rs_AR_2060,file='../scen_bscsv_sim/bs_AR_2060.csv', row.names = FALSE)

# load("../Intermediate_results/agg_bscsv.RData")
# 
# bs_base_base<-rm_dot2(bs_base_all[bs_base_all$scen=="base",1:113])
# bs_base_DE<-rm_dot2(bs_base_all[bs_base_all$scen=="baseDE",1:113])
# bs_base_RFA<-rm_dot2(bs_base_all[bs_base_all$scen=="baseRFA",1:113])
# bs_base_DERFA<-rm_dot2(bs_base_all[bs_base_all$scen=="baseDERFA",1:113])
# 
# bs_hiDR_base<-rm_dot2(bs_hiDR_all[bs_hiDR_all$scen=="hiDR",1:113])
# bs_hiDR_DE<-rm_dot2(bs_hiDR_all[bs_hiDR_all$scen=="hiDRDE",1:113])
# bs_hiDR_RFA<-rm_dot2(bs_hiDR_all[bs_hiDR_all$scen=="hiDRRFA",1:113])
# bs_hiDR_DERFA<-rm_dot2(bs_hiDR_all[bs_hiDR_all$scen=="hiDRDERFA",1:113])
# 
# bs_hiMF_base<-rm_dot2(bs_hiMF_all[bs_hiMF_all$scen=="hiMF",1:113])
# bs_hiMF_DE<-rm_dot2(bs_hiMF_all[bs_hiMF_all$scen=="hiMFDE",1:113])
# bs_hiMF_RFA<-rm_dot2(bs_hiMF_all[bs_hiMF_all$scen=="hiMFRFA",1:113])
# bs_hiMF_DERFA<-rm_dot2(bs_hiMF_all[bs_hiMF_all$scen=="hiMFDERFA",1:113])
# 
# write.csv(bs_base_base,file='../scen_bscsv_sim/bs_base_base.csv', row.names = FALSE)
# write.csv(bs_base_DE,file='../scen_bscsv_sim/bs_base_DE.csv', row.names = FALSE)
# write.csv(bs_base_RFA,file='../scen_bscsv_sim/bs_base_RFA.csv', row.names = FALSE)
# write.csv(bs_base_DERFA,file='../scen_bscsv_sim/bs_base_DERFA.csv', row.names = FALSE)
# 
# write.csv(bs_hiDR_base,file='../scen_bscsv_sim/bs_hiDR_base.csv', row.names = FALSE)
# write.csv(bs_hiDR_DE,file='../scen_bscsv_sim/bs_hiDR_DE.csv', row.names = FALSE)
# write.csv(bs_hiDR_RFA,file='../scen_bscsv_sim/bs_hiDR_RFA.csv', row.names = FALSE)
# write.csv(bs_hiDR_DERFA,file='../scen_bscsv_sim/bs_hiDR_DERFA.csv', row.names = FALSE)
# 
# write.csv(bs_hiMF_base,file='../scen_bscsv_sim/bs_hiMF_base.csv', row.names = FALSE)
# write.csv(bs_hiMF_DE,file='../scen_bscsv_sim/bs_hiMF_DE.csv', row.names = FALSE)
# write.csv(bs_hiMF_RFA,file='../scen_bscsv_sim/bs_hiMF_RFA.csv', row.names = FALSE)
# write.csv(bs_hiMF_DERFA,file='../scen_bscsv_sim/bs_hiMF_DERFA.csv', row.names = FALSE)
