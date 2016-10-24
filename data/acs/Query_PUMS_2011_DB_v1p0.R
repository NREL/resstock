#====================================================================================
#   Program:  Query_PUMS_2011_DB.R                                         
#   Version:  1.0                                                                     
#   Analyst:  Mike Heaney                                                                   
#   Date:  2016-10-16      
#====================================================================================

setwd("C:/Projects/Year2017/Energy_Efficiency_Low_Income/")

#load("PUMS_2011_Analysis_v1p0.RData")

#save(list=ls(all=T), file="PUMS_2011_Analysis_v1p0.RData")

#=====================================================================================

library(RPostgreSQL)

# CONNECT TO PG
drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host = "gispgdb.nrel.gov", dbname = "dav-gis", user = "mheaney", password = "mheaney")

# Test
sql = "SELECT * 
       FROM pums_2011.ipums_acs_2011_5yr_de
       LIMIT 1000;"
pums_de_sample = dbGetQuery(con, sql)


sql = "SELECT * 
       FROM pums_2011.ipums_acs_2011_5yr_metadata
       LIMIT 100;"
metadatadf = dbGetQuery(con, sql)

write.csv(metadatadf, file = "pums_2011_acs_2011_5yr_metadata.csv", row.names=F)

attach(pums_de_sample)
pums_de_smpl_2 = data.frame(
  serial,
  acrehous,
  age,
  bedrooms,
  birthyr,
  cbnsubfam,
  cluster,
  commuse,
  costelec,
  costfuel,
  costgas,
  cpi99,
  datanum,
  educ,
  empstat,
  famsize,
  farm,
  ftotinc,
  gq,
  hhincome,
  hhtype,
  hhwt,
  hwsei,
  ind,
  indnaics,
  insincl,
  marst,
  mortamt1,
  mortamt2,
  mortgag2,
  movedin,
  nchild,
  npboss90,
  ownershp,
  pernum,
  perwt,
  prent,
  presgl,
  puma,
  race,
  rentgrs,
  rooms,
  sei,
  sex,
  statefip,
  stateicp,
  trantime,
  uhrswork,
  unitsstr,
  valueh,
  vehicles,
  vetstat,
  year,
  ownershpd,
  raced,
  vetstatd,
  educd,
  empstatd,
  builtyr2
)
detach(pums_de_sample)

summary(pums_de_smpl_2)

summary(pums_de_sample$builtyr2)

summary(pums_de_sample$builtyr)

plot(pums_de_sample$builtyr2, pums_de_sample$builtyr, pch=20, col='blue')





