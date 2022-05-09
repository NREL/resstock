rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console

# Last Update Peter Berrill May 8 2022

# Purpose: Calculate land-use requirements related to growth of wind and solar capacity in electricity supply scenarios

# Inputs: - Electricity Capacity Densities from literature

# Outputs: 
#         - Estimates of land use in different scenarios


# renewable capacity densities: in km2/MW
wind_cd=1/3 # https://www.nrel.gov/docs/fy17osti/70032.pdf
upv_cd=1/50 # https://www.nrel.gov/docs/fy12osti/52409-1.pdf
dpv_cd=0
csp_cd=1/25 # https://www.nrel.gov/docs/fy13osti/56290.pdf

MC_wind20_MW=121582
MC_wind50_MW=240971

MC_windoff20_MW=30
MC_windoff50_MW=29813

LREC_wind20_MW=122077
LREC_wind50_MW=421995

LREC_windoff20_MW=30
LREC_windoff50_MW=33091

CFE_wind20_MW=121720
CFE_wind50_MW=454346

CFE_windoff20_MW=30
CFE_windoff50_MW=34996

MC_upv20_MW=56221
MC_upv50_MW=582484

LREC_upv20_MW=56088
LREC_upv50_MW=604407

CFE_upv20_MW=52104.5+4479
CFE_upv50_MW=1293814+50483

MC_dpv20_MW=27195
MC_dpv50_MW=141080

LREC_dpv20_MW=27168
LREC_dpv50_MW=186532

CFE_dpv20_MW=27195
CFE_dpv50_MW=141080

MC_csp20_MW=1888
MC_csp50_MW=0

LREC_csp20_MW=1888
LREC_csp50_MW=0

CFE_csp20_MW=1888
CFE_csp50_MW=24517

MC_wind20_km2=MC_wind20_MW*wind_cd
MC_wind50_km2=MC_wind50_MW*wind_cd

LREC_wind20_km2=LREC_wind20_MW*wind_cd
LREC_wind50_km2=LREC_wind50_MW*wind_cd

CFE_wind20_km2=CFE_wind20_MW*wind_cd
CFE_wind50_km2=CFE_wind50_MW*wind_cd

MC_upv20_km2=MC_upv20_MW*upv_cd
MC_upv50_km2=MC_upv50_MW*upv_cd

LREC_upv20_km2=LREC_upv20_MW*upv_cd
LREC_upv50_km2=LREC_upv50_MW*upv_cd

CFE_upv20_km2=CFE_upv20_MW*upv_cd
CFE_upv50_km2=CFE_upv50_MW*upv_cd

MC_dpv20_km2=MC_dpv20_MW*dpv_cd
MC_dpv50_km2=MC_dpv50_MW*dpv_cd

LREC_dpv20_km2=LREC_dpv20_MW*dpv_cd
LREC_dpv50_km2=LREC_dpv50_MW*dpv_cd

CFE_dpv20_km2=CFE_dpv20_MW*dpv_cd
CFE_dpv50_km2=CFE_dpv50_MW*dpv_cd

MC_csp20_km2=MC_csp20_MW*csp_cd
MC_csp50_km2=MC_csp50_MW*csp_cd

LREC_csp20_km2=LREC_csp20_MW*csp_cd
LREC_csp50_km2=LREC_csp50_MW*csp_cd

CFE_csp20_km2=CFE_csp20_MW*csp_cd
CFE_csp50_km2=CFE_csp50_MW*csp_cd

MC_LU_20_km2<-MC_wind20_km2+MC_upv20_km2+MC_dpv20_km2+MC_csp20_km2
MC_LU_50_km2<-MC_wind50_km2+MC_upv50_km2+MC_dpv50_km2+MC_csp50_km2

LREC_LU_20_km2<-LREC_wind20_km2+LREC_upv20_km2+LREC_dpv20_km2+LREC_csp20_km2
LREC_LU_50_km2<-LREC_wind50_km2+LREC_upv50_km2+LREC_dpv50_km2+LREC_csp50_km2

CFE_LU_20_km2<-CFE_wind20_km2+CFE_upv20_km2+CFE_dpv20_km2+CFE_csp20_km2
CFE_LU_50_km2<-CFE_wind50_km2+CFE_upv50_km2+CFE_dpv50_km2+CFE_csp50_km2

# All if these are around 42,000 km2
MC_LU_20_km2
LREC_LU_20_km2
CFE_LU_20_km2

MC_LU_50_km2 # 91,975 km2
LREC_LU_50_km2 # 152,755 km2
CFE_LU_50_km2 # 179,315 km2

MC_RE_20=MC_wind20_MW+MC_windoff20_MW+MC_upv20_MW+MC_dpv20_MW+MC_csp20_MW
MC_RE_50=MC_wind50_MW+MC_windoff50_MW+MC_upv50_MW+MC_dpv50_MW+MC_csp50_MW
MC_RE_50/MC_RE_20 # factor 4.8 growth in wind and solar in MC

LREC_RE_20=LREC_wind20_MW+LREC_windoff20_MW+LREC_upv20_MW+LREC_dpv20_MW+LREC_csp20_MW
LREC_RE_50=LREC_wind50_MW+LREC_windoff50_MW+LREC_upv50_MW+LREC_dpv50_MW+LREC_csp50_MW
round(LREC_RE_50/LREC_RE_20,1) # factor 6 growth in wind and solar in LREC

CFE_RE_20=CFE_wind20_MW+CFE_windoff20_MW+CFE_upv20_MW+CFE_dpv20_MW+CFE_csp20_MW
CFE_RE_50=CFE_wind50_MW+CFE_windoff50_MW+CFE_upv50_MW+CFE_dpv50_MW+CFE_csp50_MW
round(CFE_RE_50/CFE_RE_20,1) # factor 9.6 growth in wind and solar in CFE

MC_ann_inc=(MC_RE_50-MC_RE_20)/30

LREC_ann_inc=(LREC_RE_50-LREC_RE_20)/30

CFE_ann_inc=(CFE_RE_50-CFE_RE_20)/15