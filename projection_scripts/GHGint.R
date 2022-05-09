# this script takes data of CO2 intensity of electricity by balancing area, and converts it to CO2 intensity of electricity by county
# modified March 2022 to add the intensities by GEA from Cambium
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(reshape2)
library(dplyr)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts/")

# Last Update Peter Berrill April 30 2022

# Purpose: Extract CO2 intensity of electricity by balancing area and aggregate to Cambium GEA region, and allocate to counties

# Inputs: - StScen20A_MidCase_annual_balancingArea.csv, from NREL Standard Scenarios 2020
#         - StScen20A_LowRECost_annual_balancingArea.csv, from NREL Standard Scenarios 2020
#         - lkup_dgen_county_to_reeds.csv, geographical concordance, from NREL Standard Scenarios 2020
#         - regions_default.csv, geographical concordance, from NREL Standard Scenarios 2020
#         - ReEDS_mapping.csv, geographical concordance of balancing area to GEA region, from NREL Standard Scenarios 2020

# Outputs: 
#         - ExtData/GHGI_MidCase.RData, intensities for mid-case
#         - ExtData/GHGI_maps.RData, geo concordances
#         - ExtData/GHGI_LowRECost.RData, intensities for LREC


GIba<-read.csv("../ExtData/StScen20A_MidCase_annual_balancingArea.csv",skip = 2)
gi<-GIba[,c(1,2,42)] # ghg intensities
gc<-dcast(gi,r~t)
gc$rr<-as.numeric(sub("p*","",gc$r)) # get the numeric value of the balancing areas
gc<-gc[order(gc$rr),] # order by balancing areas
g<-gc[,c(2:17)]

CC<-read.csv("../ExtData/lkup_dgen_county_to_reeds.csv")
cm<-dcast(CC[,c(3,11)],geoid10~pca_reg) # concordance matrix between county and balancing area
cm[is.na(cm)]<-0
cm<-cm[,1:135]
names(cm)[2:135]<-paste("p",names(cm)[2:135],sep="")
c<-cm[,2:135]
c[c>1]<-1
cm[,2:135]<-c

gicy<-as.matrix(c)%*%as.matrix(g) # ghg intensity by county and year

gidf<-as.data.frame(gicy)
gidf$geoid10<-cm$geoid10
gidf$`2025`<-rowMeans(cbind(gidf$`2024`,gidf$`2026`))
gidf$`2035`<-rowMeans(cbind(gidf$`2034`,gidf$`2036`))
gidf$`2045`<-rowMeans(cbind(gidf$`2044`,gidf$`2046`))
gicty<-melt(gidf,id.vars = c("geoid10"))
names(gicty)[2:3]<-c("Year","GHG_int")
gicty$Year<-as.numeric(as.character(gicty$Year))
gicty<-gicty[order(gicty$geoid10,gicty$Year),] # order by county
# now we have a dataframe showing ghg intensity for each countyfor each year, according to the counties membership of a given balancing area

# in case it is deemed preferable to calculate GHG int by RTO, I will do so now
reg<-read.csv("~/Yale Courses/Research/Final Paper/GHG_Standard_Scen/regions_default.csv")
reg<-reg[reg$country=="usa",]
reg<-reg[,2:3]
regd<-distinct(reg)
GIba2<-distinct(left_join(GIba,reg,by = c("r" = "p")))
gi2<-GIba2[,c(1,2,40,42,43)]
gi2$emission<-gi2$generation*gi2$co2_rate_avg_gen
giry<-tapply(gi2$emission,list(gi2$rto,gi2$t),sum)/tapply(gi2$generation,list(gi2$rto,gi2$t),sum) # ghg intensity by rto and year
girdf<-as.data.frame(giry)
girdf$`2025`<-rowMeans(cbind(girdf$`2024`,girdf$`2026`))
girdf$`2035`<-rowMeans(cbind(girdf$`2034`,girdf$`2036`))
girdf$`2045`<-rowMeans(cbind(girdf$`2044`,girdf$`2046`))
girdf$rto<-as.numeric(sub("rto*","", rownames(girdf)))
girdf<-girdf[order(girdf$rto),]

girto<-melt(girdf,id.vars = c("rto"))
names(girto)[2:3]<-c("Year","GHG_int")
girto$Year<-as.numeric(as.character(girto$Year))
girto<-girto[order(girto$rto,girto$Year),] # order by rto

reg$p2<-as.numeric(sub("p*","",reg$p))
CC2<-distinct(left_join(CC,reg,by = c("pca_reg" = "p2")))
CC2$rto<-as.numeric(sub("rto*","",CC2$rto))
cm2<-dcast(CC2[,c(3,16)],geoid10~rto) # conconrdance matrix of counties to rtos
cm2[is.na(cm2)]<-0
cm2<-cm2[,1:19]
names(cm2)[2:19]<-paste("rto",names(cm2)[2:19],sep="")
c2<-cm2[,2:19]
c2[c2>1]<-1 # county to rto concordance
#cm2[,2:135]<-c2 # i don't think this does anything

gicyrto<-as.matrix(c2)%*%as.matrix(girdf[,1:19]) # multiply countyXrto concordance by rtoXyear matrix to get a countyXyear matrix

gidf2<-as.data.frame(gicyrto)
gidf2$geoid10<-cm2$geoid10
gicty_rto<-melt(gidf2,id.vars = c("geoid10"))
names(gicty_rto)[2:3]<-c("Year","GHG_int")
gicty_rto$Year<-as.numeric(as.character(gicty_rto$Year))
gicty_rto<-gicty_rto[order(gicty_rto$geoid10,gicty_rto$Year),] # order by county

# yet another alternative regional grouping of intensities, this time by Cambium GEA
gea<-read.csv("~/Yale Courses/Research/Final Paper/GHG_Standard_Scen/ReEDS_mapping.csv")
GIba3<-distinct(left_join(GIba,gea,by = "r"))

gi3<-GIba3[,c(1,2,40,42,43)]
gi3$emission<-gi3$generation*gi3$co2_rate_avg_gen
gigy<-tapply(gi3$emission,list(gi3$gea,gi3$t),sum)/tapply(gi3$generation,list(gi3$gea,gi3$t),sum) # ghg intensity by gea and year
gigdf<-as.data.frame(gigy)
gigdf$`2025`<-rowMeans(cbind(gigdf$`2024`,gigdf$`2026`))
gigdf$`2035`<-rowMeans(cbind(gigdf$`2034`,gigdf$`2036`))
gigdf$`2045`<-rowMeans(cbind(gigdf$`2044`,gigdf$`2046`))
gigdf$gea<-rownames(gigdf)

gigea<-melt(gigdf,id.vars = c("gea"))
names(gigea)[2:3]<-c("Year","GHG_int")
gigea$Year<-as.numeric(as.character(gigea$Year))
#gigea<-gigea[order(gigea$gea,gigea$Year),] # order by gea

#reg$p2<-as.numeric(sub("p*","",reg$p))
CC3<-distinct(left_join(CC2,gea,by = c("p" = "r")))

#CC2$gea<-as.numeric(sub("gea*","",CC2$gea))
cm3<-dcast(CC3[,c(3,17)],geoid10~gea) # conconrdance matrix of counties to geas
cm3[is.na(cm3)]<-0
cm3<-cm3[,1:21]
#names(cm3)[2:21]<-paste("gea",names(cm3)[2:19],sep="")
c3<-cm3[,2:21]
c3[c3>1]<-1 # county to gea concordance

for (n in names(c3)) {
  c3[,n]<-as.numeric(unlist(c3[,n]))
}

#cm3[,2:135]<-c3

gicygea<-as.matrix(c3)%*%as.matrix(gigdf[,1:19])

gidf3<-as.data.frame(gicygea)
gidf3$geoid10<-cm3$geoid10
gicty_gea<-melt(gidf3,id.vars = c("geoid10"))
names(gicty_gea)[2:3]<-c("Year","GHG_int")
gicty_gea$Year<-as.numeric(as.character(gicty_gea$Year))
gicty_gea<-gicty_gea[order(gicty_gea$geoid10,gicty_gea$Year),] # order by county


# gicty_rto is an alternative calculation of GHGI by county, based on rto averages rather than balancing area averages
# gicty_gea is an alternative calculation of GHGI by county, based on gea averages rather than balancing area averages
save(gicty,girto,gigea,gicty_rto,gicty_gea,file="../ExtData/GHGI_MidCase.RData")

# create a mapping of County and State to balancing area and RTO, using the CC and reg dfs.
map<-CC[,c('geoid10','county','state_abbr','pca_reg')]
map$p<-paste('p',map$pca_reg,sep="")
map<-merge(map,reg[,c('p','rto')],by='p')
map<-merge(map,gea,by.x = 'p',by.y='r')
map$RS_ID<-paste(map$state_abbr,", ",map$county, " County",sep="")

save(map,file = '../ExtData/GHGI_maps.RData')

# now for the LowRECost scenario #######

GIlr<-read.csv("../ExtData/StScen20A_LowRECost_annual_balancingArea.csv",skip = 2)
gi<-GIlr[,c(1,2,42)] # ghg intensities
gc<-dcast(gi,r~t)
gc$rr<-as.numeric(sub("p*","",gc$r)) # get the numeric value of the balancing areas
gc<-gc[order(gc$rr),] # order by balancing areas
g<-gc[,c(2:17)]

gicy<-as.matrix(c)%*%as.matrix(g) # ghg intensity by county and year

gidf<-as.data.frame(gicy)
gidf$geoid10<-cm$geoid10
gidf$`2025`<-rowMeans(cbind(gidf$`2024`,gidf$`2026`))
gidf$`2035`<-rowMeans(cbind(gidf$`2034`,gidf$`2036`))
gidf$`2045`<-rowMeans(cbind(gidf$`2044`,gidf$`2046`))
gicty<-melt(gidf,id.vars = c("geoid10"))
names(gicty)[2:3]<-c("Year","GHG_int")
gicty$Year<-as.numeric(as.character(gicty$Year))
gicty<-gicty[order(gicty$geoid10,gicty$Year),] # order by county
# now we have a dataframe showing ghg intensity for each countyfor each year, according to the counties membership of a given balancing area

# in case it is deemed preferable to calculate GHG int by RTO, I will do so now
reg<-read.csv("../ExtData/regions_default.csv")
reg<-reg[reg$country=="usa",]
reg<-reg[,2:3]
GIlr2<-distinct(left_join(GIlr,reg,by = c("r" = "p")))
gi2<-GIlr2[,c(1,2,40,42,43)]
gi2$emission<-gi2$generation*gi2$co2_rate_avg_gen
giry<-tapply(gi2$emission,list(gi2$rto,gi2$t),sum)/tapply(gi2$generation,list(gi2$rto,gi2$t),sum) # ghg intensity by rto and year
girdf<-as.data.frame(giry)
girdf$`2025`<-rowMeans(cbind(girdf$`2024`,girdf$`2026`))
girdf$`2035`<-rowMeans(cbind(girdf$`2034`,girdf$`2036`))
girdf$`2045`<-rowMeans(cbind(girdf$`2044`,girdf$`2046`))
girdf$rto<-as.numeric(sub("rto*","", rownames(girdf)))
girdf<-girdf[order(girdf$rto),]

girto<-melt(girdf,id.vars = c("rto"))
names(girto)[2:3]<-c("Year","GHG_int")
girto$Year<-as.numeric(as.character(girto$Year))
girto<-girto[order(girto$rto,girto$Year),] # order by rto

reg$p2<-as.numeric(sub("p*","",reg$p))
CC2<-distinct(left_join(CC,reg,by = c("pca_reg" = "p2")))
CC2$rto<-as.numeric(sub("rto*","",CC2$rto))
cm2<-dcast(CC2[,c(3,16)],geoid10~rto) # conconrdance matrix of counties to rtos
cm2[is.na(cm2)]<-0
cm2<-cm2[,1:19]
names(cm2)[2:19]<-paste("rto",names(cm2)[2:19],sep="")
c2<-cm2[,2:19]
c2[c2>1]<-1
#cm2[,2:135]<-c2

gicyrto<-as.matrix(c2)%*%as.matrix(girdf[,1:19])

gidf2<-as.data.frame(gicyrto)
gidf2$geoid10<-cm2$geoid10
gicty_rto<-melt(gidf2,id.vars = c("geoid10"))
names(gicty_rto)[2:3]<-c("Year","GHG_int")
gicty_rto$Year<-as.numeric(as.character(gicty_rto$Year))
gicty_rto<-gicty_rto[order(gicty_rto$geoid10,gicty_rto$Year),] # order by county

# now by GEA

GIlr3<-distinct(left_join(GIlr,gea,by = "r"))

gi3<-GIlr3[,c(1,2,40,42,43)]
gi3$emission<-gi3$generation*gi3$co2_rate_avg_gen
gigy<-tapply(gi3$emission,list(gi3$gea,gi3$t),sum)/tapply(gi3$generation,list(gi3$gea,gi3$t),sum) # ghg intensity by gea and year
gigdf<-as.data.frame(gigy)
gigdf$`2025`<-rowMeans(cbind(gigdf$`2024`,gigdf$`2026`))
gigdf$`2035`<-rowMeans(cbind(gigdf$`2034`,gigdf$`2036`))
gigdf$`2045`<-rowMeans(cbind(gigdf$`2044`,gigdf$`2046`))
gigdf$gea<-rownames(gigdf)

gigea<-melt(gigdf,id.vars = c("gea"))
names(gigea)[2:3]<-c("Year","GHG_int")
gigea$Year<-as.numeric(as.character(gigea$Year))
#gigea<-gigea[order(gigea$gea,gigea$Year),] # order by gea

#reg$p2<-as.numeric(sub("p*","",reg$p))
#CC3<-distinct(left_join(CC2,gea,by = c("p" = "r")))

#CC2$gea<-as.numeric(sub("gea*","",CC2$gea))
# cm3<-dcast(CC3[,c(3,17)],geoid10~gea) # conconrdance matrix of counties to geas
# cm3[is.na(cm3)]<-0
# cm3<-cm3[,1:21]
# #names(cm3)[2:21]<-paste("gea",names(cm3)[2:19],sep="")
# c3<-cm3[,2:21]
# c3[c3>1]<-1 # county to gea concordance
# 
# for (n in names(c3)) {
#   c3[,n]<-as.numeric(unlist(c3[,n]))
# }

#cm3[,2:135]<-c3

gicygea<-as.matrix(c3)%*%as.matrix(gigdf[,1:19])

gidf3<-as.data.frame(gicygea)
gidf3$geoid10<-cm3$geoid10
gicty_gea<-melt(gidf3,id.vars = c("geoid10"))
names(gicty_gea)[2:3]<-c("Year","GHG_int")
gicty_gea$Year<-as.numeric(as.character(gicty_gea$Year))
gicty_gea<-gicty_gea[order(gicty_gea$geoid10,gicty_gea$Year),] # order by county


# rename to distinguish
gicty_LREC<-gicty
gicty_rto_LREC<-gicty_rto
girto_LREC<-girto
gicty_gea_LREC<-gicty_gea
gigea_LREC<-gigea


# gicty_rto is an alternative calculation of GHGI by county, based on rto averages rather than balancing area averages
save(gicty_LREC,girto_LREC,gicty_rto_LREC,gicty_gea_LREC,gigea_LREC,file="../ExtData/GHGI_LowRECost.RData")