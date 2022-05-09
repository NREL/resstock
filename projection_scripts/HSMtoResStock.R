# script to convert outputs of housing stock model into data that can be combined with 
# ResStock housing characteristics to generate projection based housing characteristics
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
# Last Update Peter Berrill April 30 2022

# Purpose: Take inputs from housing stock model and base ResStock data describing housing stock by type, vintage, and geography and use it to generate similar data for each five years 2020-2060

# Inputs: - InitStock20.RData, stats of the housing stock by county in 2020
#         - ctycode.RData, county FIPS codes and names
#         - PUMA.tsv, concordance of housing stock between counties and PUMA, from ResStock housing characteristics
#         - Geometry Building Type ACS.tsv, housing types by PUMA, from ResStock housing characteristics
#         - Vintage.tsv, housing stock by vintage and type by PUMA, from ResStock housing characteristics
#         - ASHRAE IECC Climate Zone 2004.tsv, housing stock by IECC climate zone, from ResStock housing characteristics
#         - County.tsv, housing stock by county and IECC climate zone, from ResStock housing characteristics

# Outputs: (where 'yr' is every 5 years 2020-2060)
#         - project_national_yr/housing_characteristics/Vintage.tsv
#         - project_national_yr/housing_characteristics/Geometry Building Type ACS.tsv
#         - project_national_yr/housing_characteristics/County.tsv
#         - project_national_yr/housing_characteristics/ASHRAE IECC Climate Zone 2004.tsv

setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts")
library(readr)
library(stringr)
# function to remove dots from col names before saving as tsv
rm_dot<-function(df) {
  cn<-names(df)
  cn<-str_replace_all(cn,"Dependency.", "Dependency=")
  cn<-str_replace_all(cn,"Option..1940", "Option=<1940")
  cn<-str_replace_all(cn,"Option.", "Option=")
  cn<-str_replace_all(cn,"\\.", " ")
  cn<-str_replace_all(cn,"Single.","Single-")
  names(df)<-cn
  df
}
# 2020 occupied stock, files from HSM paper, see 'Intermediate Results' folder at https://github.com/peterberr/US_county_HSM
load("../ExtData/InitStock20.RData")
load("../ExtData/ctycode.RData")

h20pc<-merge(h20pc,ctycode)
h20pc<-h20pc[,c(1,2,76,3:75)] # bring RS_ID to the third colum

puma<-read_tsv('../project_national/housing_characteristics/PUMA.tsv',col_names = TRUE)
puma<-puma[1:3108,] # remove comments at bottom
type_acs<-read_tsv('../project_national/housing_characteristics/Geometry Building Type ACS.tsv',col_names = TRUE)
type_acs<-type_acs[1:(dim(type_acs)[1]-2),] # remove comments at bottom
type_new<-as.data.frame(type_acs)
type_new[,2:12]<-0
vintage<-read_tsv('../project_national/housing_characteristics/Vintage.tsv',col_names = TRUE)
vintage<-vintage[1:(dim(vintage)[1]-2),] # remove comments at 
vintage_new<-as.data.frame(vintage)
vintage_new[,3:13]<-0
puma_list<-unique(vintage$`Dependency=PUMA`)
y<-as.matrix(puma[,2:2337]) # cut out the sample county and weight columns

# rows by type in the vintage tsv
mf_row<-1:6
mh_row<-7
sf_row<-8:9
rows<-c("mf_row","mh_row","sf_row")

c<-rep(0,3142)
for (i in 1:3142) {
  if(any(h20pc$RS_ID[i]==puma$`Dependency=County`)) {c[i]<-1}
}
no_count<-h20pc[which(c<1),1:3] # should just be AK and HI counties in here, which are not represented in ResStock

# calculate h20pc occupied unit only totals by type (3) and cohort
h20pc[,c("SF_pre40", "SF_4059", "SF_6079",  "SF_8099",  "SF_2000",  "SF_2010","SF_2020","SF_2030","SF_2040","SF_2050")]<-h20pc$Tot_HU_SF*(h20pc[,8:17])
h20pc[,c("MF_pre40", "MF_4059", "MF_6079",  "MF_8099",  "MF_2000",  "MF_2010","MF_2020","MF_2030","MF_2040","MF_2050")]<-h20pc$Tot_HU_MF*(h20pc[,28:37])
h20pc[,c("MH_pre40", "MH_4059", "MH_6079",  "MH_8099",  "MH_2000",  "MH_2010","MH_2020","MH_2030","MH_2040","MH_2050")]<-h20pc$Tot_HU_MH*(h20pc[,48:57])
# first run the script without a loop for 2020, afterwards run for scenarios for 2025-2060 in a loop #########
total<-merge(h20pc,puma,by.x = "RS_ID",by.y = "Dependency=County")
tc_puma<-t(as.matrix(total[,77:106]))%*%y # convert type cohort stocks from counties into pumas
total$TotOccUnits<-rowSums(total[,77:106])
x<-total$TotOccUnits # total housing units 
for (i in 1:length(puma_list)) {
  puma_i<-puma_list[i]
  ptc<-as.data.frame(vintage[vintage$`Dependency=PUMA`==puma_i,])
  tc<-round(ptc[,3:11]*ptc[,13])
  
  # replace all zero submatrices with equal distribution
  for (a in 1:length(rows)) {
    if (all(tc[get(rows[a]),"Option=<1940"]==0)) {tc[get(rows[a]),"Option=<1940"]<-1/length(unlist(tc[get(rows[a]),"Option=<1940"]))}
    if (all(tc[get(rows[a]),c("Option=1940s","Option=1950s")]==0)) {tc[get(rows[a]),c("Option=1940s","Option=1950s")]<-1/length(unlist(tc[get(rows[a]),c("Option=1940s","Option=1950s")]))}
    if (all(tc[get(rows[a]),c("Option=1960s","Option=1970s")]==0)) {tc[get(rows[a]),c("Option=1960s","Option=1970s")]<-1/length(unlist(tc[get(rows[a]),c("Option=1960s","Option=1970s")]))}
    if (all(tc[get(rows[a]),c("Option=1980s","Option=1990s")]==0)) {tc[get(rows[a]),c("Option=1980s","Option=1990s")]<-1/length(unlist(tc[get(rows[a]),c("Option=1980s","Option=1990s")]))}
    if (all(tc[get(rows[a]),"Option=2000s"]==0)) {tc[get(rows[a]),"Option=2000s"]<-1/length(unlist(tc[get(rows[a]),"Option=2000s"]))}
    if (all(tc[get(rows[a]),"Option=2010s"]==0)) {tc[get(rows[a]),"Option=2010s"]<-1/length(unlist(tc[get(rows[a]),"Option=2010s"]))}
  }
  
  tcn<-ptc
  tcn[,3:13]<-0
  tcn[mf_row,"Option=<1940"]<-tc_puma[which(row.names(tc_puma)=="MF_pre40"),i]*tc[mf_row,"Option=<1940"]/sum(tc[mf_row,"Option=<1940"])
  tcn[mf_row,c("Option=1940s","Option=1950s")]<-tc_puma[which(row.names(tc_puma)=="MF_4059"),i]*tc[mf_row,c("Option=1940s","Option=1950s")]/sum(tc[mf_row,c("Option=1940s","Option=1950s")])
  tcn[mf_row,c("Option=1960s","Option=1970s")]<-tc_puma[which(row.names(tc_puma)=="MF_6079"),i]*tc[mf_row,c("Option=1960s","Option=1970s")]/sum(tc[mf_row,c("Option=1960s","Option=1970s")])
  tcn[mf_row,c("Option=1980s","Option=1990s")]<-tc_puma[which(row.names(tc_puma)=="MF_8099"),i]*tc[mf_row,c("Option=1980s","Option=1990s")]/sum(tc[mf_row,c("Option=1980s","Option=1990s")])
  tcn[mf_row,c("Option=2000s")]<-tc_puma[which(row.names(tc_puma)=="MF_2000"),i]*tc[mf_row,c("Option=2000s")]/sum(tc[mf_row,c("Option=2000s")])
  tcn[mf_row,c("Option=2010s")]<-tc_puma[which(row.names(tc_puma)=="MF_2010"),i]*tc[mf_row,c("Option=2010s")]/sum(tc[mf_row,c("Option=2010s")])
  
  tcn[sf_row,"Option=<1940"]<-tc_puma[which(row.names(tc_puma)=="SF_pre40"),i]*tc[sf_row,"Option=<1940"]/sum(tc[sf_row,"Option=<1940"])
  tcn[sf_row,c("Option=1940s","Option=1950s")]<-tc_puma[which(row.names(tc_puma)=="SF_4059"),i]*tc[sf_row,c("Option=1940s","Option=1950s")]/sum(tc[sf_row,c("Option=1940s","Option=1950s")])
  tcn[sf_row,c("Option=1960s","Option=1970s")]<-tc_puma[which(row.names(tc_puma)=="SF_6079"),i]*tc[sf_row,c("Option=1960s","Option=1970s")]/sum(tc[sf_row,c("Option=1960s","Option=1970s")])
  tcn[sf_row,c("Option=1980s","Option=1990s")]<-tc_puma[which(row.names(tc_puma)=="SF_8099"),i]*tc[sf_row,c("Option=1980s","Option=1990s")]/sum(tc[sf_row,c("Option=1980s","Option=1990s")])
  tcn[sf_row,c("Option=2000s")]<-tc_puma[which(row.names(tc_puma)=="SF_2000"),i]*tc[sf_row,c("Option=2000s")]/sum(tc[sf_row,c("Option=2000s")])
  tcn[sf_row,c("Option=2010s")]<-tc_puma[which(row.names(tc_puma)=="SF_2010"),i]*tc[sf_row,c("Option=2010s")]/sum(tc[sf_row,c("Option=2010s")])
  
  tcn[mh_row,"Option=<1940"]<-tc_puma[which(row.names(tc_puma)=="MH_pre40"),i]*tc[mh_row,"Option=<1940"]/sum(tc[mh_row,"Option=<1940"])
  tcn[mh_row,c("Option=1940s","Option=1950s")]<-tc_puma[which(row.names(tc_puma)=="MH_4059"),i]*tc[mh_row,c("Option=1940s","Option=1950s")]/sum(tc[mh_row,c("Option=1940s","Option=1950s")])
  tcn[mh_row,c("Option=1960s","Option=1970s")]<-tc_puma[which(row.names(tc_puma)=="MH_6079"),i]*tc[mh_row,c("Option=1960s","Option=1970s")]/sum(tc[mh_row,c("Option=1960s","Option=1970s")])
  tcn[mh_row,c("Option=1980s","Option=1990s")]<-tc_puma[which(row.names(tc_puma)=="MH_8099"),i]*tc[mh_row,c("Option=1980s","Option=1990s")]/sum(tc[mh_row,c("Option=1980s","Option=1990s")])
  tcn[mh_row,c("Option=2000s")]<-tc_puma[which(row.names(tc_puma)=="MH_2000"),i]*tc[mh_row,c("Option=2000s")]/sum(tc[mh_row,c("Option=2000s")])
  tcn[mh_row,c("Option=2010s")]<-tc_puma[which(row.names(tc_puma)=="MH_2010"),i]*tc[mh_row,c("Option=2010s")]/sum(tc[mh_row,c("Option=2010s")])
  
  tcn$sample_weight<-rowSums(tcn[,3:11])
  type_new[i,2:10]<-tcn$sample_weight/sum(tcn$sample_weight)
  vint_prob<-tcn[,3:11]/tcn$sample_weight
  vint_prob[is.na(vint_prob)]<-0# replaces NAN with 0
  vintage_new[vintage_new$`Dependency=PUMA`==puma_i,3:11]<-vint_prob
}
vrs<-rowSums(vintage_new[,3:11])
for (l in which(vrs==0)) { # make sure there are no rows with a 0 row sum
  if (vrs[l]==0) {
    vintage_new[l,3:11]<-1/ncol(vintage_new[,3:11])
  }
}

vin<-format(vintage_new,nsmall=6,digits=0,scientific=FALSE)
ty<-format(type_new,nsmall=6,digits=0,scientific=FALSE)
# save the 2020 vintage and geometry type acs
write.table(vin,'../project_national_2020/housing_characteristics/Vintage.tsv',append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
write.table(ty,'../project_national_2020/housing_characteristics/Geometry Building Type ACS.tsv',append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
tc_pumaold<-tc_puma

## generate new county and IECC climate zone tsv files
county<-read_tsv('../project_national/housing_characteristics/County.tsv',col_names = TRUE)
county<-county[1:(dim(county)[1]-3),] # remove comments at bottom

iecc<-read_tsv('../project_national/housing_characteristics/ASHRAE IECC Climate Zone 2004.tsv',col_names = TRUE)
iecc<-iecc[1:(dim(iecc)[1]-4),] # remove comments at bottom
iecc[1]<-as.numeric(iecc[1]) # convert from character to numeric

cty_new<-as.data.frame(county)
cty_new[,2:3109][cty_new[,2:3109]>0]<-1 # turn this into a matching concordance matrix
cty_new[,3110]<-0 # turn sample count to 0
cz_cty<-as.matrix(cty_new[,2:3109])%*%diag(x) # creates a 15x3108 matrix of occupied housing units by climate zone and county
cz_cty_pc<-cz_cty/rowSums(cz_cty) # creates a matrix of occupied units by climate zone and county, normalized by climate zone. each cell tells us what percentage of cz x is in cty y
cty_new[,2:3109]<-cz_cty_pc
cty_new[,3111]<-rowSums(cz_cty) # this is the sample weight, i.e. total housing units per climate zone. will be used to define iecc

cty_cn<-names(cty_new)[2:3109]

iecc_new<-as.data.frame(iecc)
iecc_new[1,1:15]<-rowSums(cz_cty)/sum(cz_cty)
iecc_new[1,16]<-0
iecc_new[1,17]<-sum(cz_cty)

cty<-format(as.data.frame(cty_new),nsmall=6,digits=0,scientific=FALSE)
ie<-format(iecc_new,nsmall=6,digits=0,scientific=FALSE)
# save the 2020 county and IECC Cz
write.table(cty,'../project_national_2020/housing_characteristics/County.tsv',append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
write.table(ie,'../project_national_2020/housing_characteristics/ASHRAE IECC Climate Zone 2004.tsv',append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')

# now run for scenarios 2025-2060 ############
load("../../HSM_github/HSM_results/County_Scenario_SM_Results.RData") # path to outputs of stock model scenario runs, see HSM github page
scenarios<-paste(as.character(rep(seq(2025,2060,5),each=3)), c("base","hiDR","hiMF"),sep="_")
Years<-c(2020:2060)
for (s in 1:24) {
  scen<-scenarios[s]
  year<-as.numeric(substr(scen,1,4))
  stock<-substr(scen,6,nchar(scen))
  # get columns of geoid, year, total occupied stock by type, occupancy, and vintage ACS (cohort)
  hstock<-as.data.frame(get(paste("smop",stock,sep = "_"))[[3]][[1]][which(Years==year),c(1,2,110:119,130:139,150:159)])
  for (i in 2:3142){ # get the same data for all counties
    hstock[i,]<-as.data.frame(get(paste("smop",stock,sep = "_"))[[3]][[i]][which(Years==year),c(1,2,110:119,130:139,150:159)])
  }
  hstockold<-hstock
  hstockold[,2:32]<-0
  if (s>3) {
    for (j in 1:3142) {
      hstockold[j,]<-as.data.frame(get(paste("smop",stock,sep = "_"))[[3]][[j]][which(Years==(year-5)),c(1,2,110:119,130:139,150:159)])
    }
  }
  hstock[,c(9:12,19:22,29:32)]<-hstock[,c(9:12,19:22,29:32)]-hstockold[,c(9:12,19:22,29:32)] # for scenarios 2030 onwards. the newly construction occupied stock in the new cohorts equals the difference between the total stock in the current year, and the stock 5 years ago. 
  # I then remove negative values to remove decline of new construction cohorts, seeing as we want to represent growth of new construction cohorts here.  Decline is accounted for separately through the weighting factors
  # With the new approach on modeling stock growth and decline for nc cohorts after their decade officially finishes, I want to represent here only nc cohort construction that happens within the appropriate decade.
  # For instance, in 2035 and 2040 new construction should be new construction in the 2030s cohort only. In 2045 and 2050, new construction in the 2040s cohort only, etc. 
  for (c in c(9:12,19:22,29:32)) { # remove negative values, which come about from stock decline of new cohorts.
      hstock[which(hstock[,c]<0),c]<-0
    }
 
  hstock<-merge(hstock,ctycode)
  total<-merge(hstock,puma,by.x = "RS_ID",by.y = "Dependency=County")
  # multiply occupied units by type (3) and cohort (all) by the y matrix to convert from cty to puma to produce a matrix of t-c (30 rows) housing units by puma (2336 cols)
  tc_puma<-t(as.matrix(total[,4:33]))%*%y  # for 2025 onwards
  # tc_puma<-t(as.matrix(total[,77:106]))%*%y # only for the 2020 version
  rownames(tc_puma)<-rownames(tc_pumaold) # this is needed
  # total$TotOccUnits<-rowSums(total[,c(10:13,20:23,30:33)]) # sum up housing units from new, post-2020 cohorts only. by individual cohort depending on the year
  if (s<7) {total$TotOccUnits<-rowSums(total[,c(10,20,30)])} # 2020s cohort
  if (s>6 & s<13) {total$TotOccUnits<-rowSums(total[,c(11,21,31)])} # 2030s cohort
  if (s>12 & s<19) {total$TotOccUnits<-rowSums(total[,c(12,22,32)])} # 2040s cohort
  if (s>18) {total$TotOccUnits<-rowSums(total[,c(13,23,33)])} # 2050s cohort
  x<-total$TotOccUnits # total new occ housing units by county 

  type_new<-as.data.frame(type_acs)
  type_new[,2:12]<-0

  vintage_new<-as.data.frame(vintage)
  vintage_new[,3:13]<-0
  vintage_new$`Option=2050s`<-vintage_new$`Option=2040s`<-vintage_new$`Option=2030s`<-vintage_new$`Option=2020s`<-0 # add the new cohorts
  vintage_new<-vintage_new[,c(1,2,11,3:10,14:17,12,13)]
  tcn<-vintage_new[1:9,] # create template for the type cohort new matrix
  tcn[,3:17]<-0
  # with new approach, all new units are strictly within cohort.
  if (s<7) {vintage_new$`Option=2020s`<-1}
  if (s>6 & s<13) {vintage_new$`Option=2030s`<-1}
  if (s>12 & s<19) {vintage_new$`Option=2040s`<-1}
  if (s>18) {vintage_new$`Option=2050s`<-1}

# make this a function to create vintage and type files, arguments are 'all', 'vintage'. 
for (i in 1:length(puma_list)) { # need to figure this function out, and bring it into the world of new vintages.? For 2020 its fine. For future years will need an equivalent of h20pc and an assumption of the breakout of specific MF types (prob use 2010 split)
puma_i<-puma_list[i]
ptc<-as.data.frame(vintage[vintage$`Dependency=PUMA`==puma_i,]) # puma matrix of units by type and cohort. For 2020 stock, only 9 vintages
tc<-round(ptc[,3:11]*ptc[,13]) # restrict to numerical data only, col names are vintages

# replace all zero submatrices with equal distribution
for (a in 1:length(rows)) { # for mf, mh, and sf
  if (all(tc[get(rows[a]),"Option=2010s"]==0)) {tc[get(rows[a]),"Option=2010s"]<-1/length(unlist(tc[get(rows[a]),"Option=2010s"]))}
}

tcn$`Dependency=PUMA`<-puma_i # this seems redundant now, actually maybe not
tcn[,3:17]<-0 # bringing this back too
# add if statements to make sure only within cohort new construction is considered
if (s<7) { tcn[mf_row,c("Option=2020s")]<-tc_puma[which(row.names(tc_puma)=="MF_2020"),i]*tc[mf_row,c("Option=2010s")]/sum(tc[mf_row,c("Option=2010s")]);  # use 2010s split of MF types for tc_puma future MF splits
            tcn[sf_row,c("Option=2020s")]<-tc_puma[which(row.names(tc_puma)=="SF_2020"),i]*tc[sf_row,c("Option=2010s")]/sum(tc[sf_row,c("Option=2010s")]); # use 2010s split of SF types for all future SF splits
            tcn[mh_row,c("Option=2020s")]<-tc_puma[which(row.names(tc_puma)=="MH_2020"),i]}
if (s>6 & s<13) {tcn[mf_row,c("Option=2030s")]<-tc_puma[which(row.names(tc_puma)=="MF_2030"),i]*tc[mf_row,c("Option=2010s")]/sum(tc[mf_row,c("Option=2010s")]);
                  tcn[sf_row,c("Option=2030s")]<-tc_puma[which(row.names(tc_puma)=="SF_2030"),i]*tc[sf_row,c("Option=2010s")]/sum(tc[sf_row,c("Option=2010s")]);
                  tcn[mh_row,c("Option=2030s")]<-tc_puma[which(row.names(tc_puma)=="MH_2030"),i]}

if (s>12 & s<19) { tcn[mf_row,c("Option=2040s")]<-tc_puma[which(row.names(tc_puma)=="MF_2040"),i]*tc[mf_row,c("Option=2010s")]/sum(tc[mf_row,c("Option=2010s")]);
                    tcn[sf_row,c("Option=2040s")]<-tc_puma[which(row.names(tc_puma)=="SF_2040"),i]*tc[sf_row,c("Option=2010s")]/sum(tc[sf_row,c("Option=2010s")]);
                    tcn[mh_row,c("Option=2040s")]<-tc_puma[which(row.names(tc_puma)=="MH_2040"),i]}
if (s>18) {tcn[mf_row,c("Option=2050s")]<-tc_puma[which(row.names(tc_puma)=="MF_2050"),i]*tc[mf_row,c("Option=2010s")]/sum(tc[mf_row,c("Option=2010s")]);
                    tcn[sf_row,c("Option=2050s")]<-tc_puma[which(row.names(tc_puma)=="SF_2050"),i]*tc[sf_row,c("Option=2010s")]/sum(tc[sf_row,c("Option=2010s")]);
                    tcn[mh_row,c("Option=2050s")]<-tc_puma[which(row.names(tc_puma)=="MH_2050"),i]}

tcn$sample_weight<-rowSums(tcn[,3:15]) # get sums of housing units by Type ACS
type_new[i,2:10]<-tcn$sample_weight/sum(tcn$sample_weight) # use counts of housing units by Type ACS to define the type split for this puma for this cohort-year
# vint_prob<-tcn[,3:15]/tcn$sample_weight # calculated probability of vintage for each ACS type
# vint_prob[is.na(vint_prob)]<-0# replaces NAN with 0, this will only happy for types with 0 chance of selection, so should never be a problem
# vintage_new[vintage_new$`Dependency=PUMA`==puma_i,3:15]<-vint_prob
}

vin<-format(vintage_new,nsmall=6,digits=0,scientific=FALSE)
ty<-format(type_new,nsmall=6,digits=0,scientific=FALSE)
fol<-paste('../project_national_',scen,sep="")
write.table(vin,paste(fol,'/housing_characteristics/Vintage.tsv',sep=""),append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
write.table(ty,paste(fol,'/housing_characteristics/Geometry Building Type ACS.tsv',sep=""),append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')

cty_new<-as.data.frame(county)
cty_new[,2:3109][cty_new[,2:3109]>0]<-1 # turn this into a matching concordance matrix
cty_new[,3110]<-0 # turn sample count to 0
cz_cty<-as.matrix(cty_new[,2:3109])%*%diag(x) # creates a 15x3108 matrix of occupied housing units by climate zone and county
cz_cty_pc<-cz_cty/rowSums(cz_cty) # creates a matrix of occupied units by climate zone and county, normalized by climate zone. each cell tells us what percentage of cz x is in cty y
cty_new[,2:3109]<-cz_cty_pc
cty_new[,3111]<-rowSums(cz_cty) # this is the sample weight, i.e. total housing units per climate zone. will be used to define iecc

iecc_new<-as.data.frame(iecc)
iecc_new[1,1:15]<-rowSums(cz_cty)/sum(cz_cty)
iecc_new[1,16]<-0 # turn sample count to 0
iecc_new[1,17]<-sum(cz_cty)

cty<-format(as.data.frame(cty_new),nsmall=6,digits=0,scientific=FALSE) # this needs to be zero
ie<-format(iecc_new,nsmall=6,digits=0,scientific=FALSE)

write.table(cty,paste(fol,'/housing_characteristics/County.tsv',sep=""),append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
write.table(ie,paste(fol,'/housing_characteristics/ASHRAE IECC Climate Zone 2004.tsv',sep=""),append = FALSE,quote = FALSE, row.names = FALSE, col.names = TRUE,sep='\t')
}
