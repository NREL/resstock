rm(list=ls()) # clear workspace
cat("\014") # clear console
graphics.off() # remove graphics windows
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")
library(dplyr)
library(ggplot2)
library(reshape2)

# Last Update Peter Berrill May 6 2022

# Purpose: Check on heating equipment characteristics by house type and tenure, to investigate the question of whether renovation is less likely in MF homes or rented homes

# Inputs: - Yale Courses/Research/RECS research/RECS2015/recs2015_public_v4.csv, from https://www.eia.gov/consumption/residential/data/2015/
#         - Yale Courses/Research/RECS research/RECS2009/recs2009_public.csv, from https://www.eia.gov/consumption/residential/data/2009/

# Outputs: 
#         - some figure data files

# get data #############
recs15<-read.csv('~/Yale Courses/Research/RECS research/RECS2015/recs2015_public_v4.csv') 

# rename water heat ages
recs15$WHEATAGE2<-as.factor(recs15$WHEATAGE)
levels(recs15$WHEATAGE2)<-levels(recode(recs15$WHEATAGE2,"-2"="NA/DontKnow","1"="<2YR","2"="2-4YR","3"="5-9YR","41"="10-14YR","42"="15-19YR","5"="20YR"))
recs15$WHEATAGE2<-factor(recs15$WHEATAGE2, ordered=TRUE, levels = c("<2YR","2-4YR","5-9YR","10-14YR","15-19YR","20YR","NA/DontKnow"))

# create a 3-type house type variable
recs15$TYPE<-'MF'
recs15[recs15$TYPEHUQ %in% c(2,3),]$TYPE<-'SF'
recs15[recs15$TYPEHUQ ==1,]$TYPE<-'MH'
table(recs15$TYPE)

wht<-tapply(recs15$NWEIGHT,list(recs15$WHEATAGE2,recs15$TYPE),sum)

w<-melt(wht)
colnames(w)<-c("Age","Type","Value")
windows()
ggplot(w,aes(fill=Age,x =Type, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of water heating equipment, 2015",y="Percentage of households",x="Type") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

wht[is.na(wht)]<-0
wht_pc<-round(wht/rep(colSums(wht),each=7),3)
write.csv(wht_pc,file = '../Figures/Renovate_RECS/wht_pc_15.csv')

recs15$TENURE<-'Rented'
recs15[recs15$KOWNRENT==1,]$TENURE<-'Owned'

wht2<-tapply(recs15$NWEIGHT,list(recs15$WHEATAGE2,recs15$TENURE),sum)

w2<-melt(wht2)
colnames(w2)<-c("Age","Tenure","Value")
windows()
ggplot(w2,aes(fill=Age,x =Tenure, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of water heating equipment, 2015",y="Percentage of households",x="Tenure") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

wht2[is.na(wht2)]<-0
wht_pc_ten<-round(wht2/rep(colSums(wht2),each=7),3)
write.csv(wht_pc_ten,file = '../Figures/Renovate_RECS/wht_pc_ten_15.csv')

# now space heating 
# rename speat heat ages
recs15$EQUIPAGE2<-as.factor(recs15$EQUIPAGE)
levels(recs15$EQUIPAGE2)<-levels(recode(recs15$EQUIPAGE2,"-2"="NA/DontKnow","1"="<2YR","2"="2-4YR","3"="5-9YR","41"="10-14YR","42"="15-19YR","5"="20YR"))
recs15$EQUIPAGE2<-factor(recs15$EQUIPAGE2, ordered=TRUE, levels = c("<2YR","2-4YR","5-9YR","10-14YR","15-19YR","20YR","NA/DontKnow"))


sph<-tapply(recs15$NWEIGHT,list(recs15$EQUIPAGE2,recs15$TYPE),sum)

s<-melt(sph[1:6,])
colnames(s)<-c("Age","Type","Value")
windows()
ggplot(s,aes(fill=Age,x =Type, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of space heating equipment, 2015",y="Percentage of households",x="Type") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

sph[is.na(sph)]<-0
sph_pc<-round(sph/rep(colSums(sph),each=7),3)
write.csv(sph_pc,file = '../Figures/Renovate_RECS/sph_pc_15.csv')

sph2<-tapply(recs15$NWEIGHT,list(recs15$EQUIPAGE2,recs15$TENURE),sum)

s2<-melt(sph2[1:6,])
colnames(s2)<-c("Age","Tenure","Value")
windows()
ggplot(s2,aes(fill=Age,x =Tenure, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of space heating equipment, 2015",y="Percentage of households",x="Tenure") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

sph2[is.na(sph2)]<-0
sph_pc_ten<-round(sph2/rep(colSums(sph2),each=7),3)
write.csv(sph_pc_ten,file = '../Figures/Renovate_RECS/sph_pc_ten_15.csv')

# now for 2009 ###########

recs09<-read.csv('~/Yale Courses/Research/RECS research/RECS2009/recs2009_public.csv')

# rename water heat ages
recs09$WHEATAGE2<-as.factor(recs09$WHEATAGE)
levels(recs09$WHEATAGE2)<-levels(recode(recs09$WHEATAGE2,"-2"="NA/DontKnow","1"="<2YR","2"="2-4YR","3"="5-9YR","41"="10-14YR","42"="15-19YR","5"="20YR"))
recs09$WHEATAGE2<-factor(recs09$WHEATAGE2, ordered=TRUE, levels = c("<2YR","2-4YR","5-9YR","10-14YR","15-19YR","20YR","NA/DontKnow"))

# create a 3-type house type variable
recs09$TYPE<-'MF'
recs09[recs09$TYPEHUQ %in% c(2,3),]$TYPE<-'SF'
recs09[recs09$TYPEHUQ ==1,]$TYPE<-'MH'
table(recs09$TYPE)

wht<-tapply(recs09$NWEIGHT,list(recs09$WHEATAGE2,recs09$TYPE),sum)

w<-melt(wht[1:6,])
colnames(w)<-c("Age","Type","Value")
windows()
ggplot(w,aes(fill=Age,x =Type, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of water heating equipment, 2009",y="Percentage of households",x="Type") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

wht[is.na(wht)]<-0
wht_pc<-round(wht/rep(colSums(wht),each=7),3)
write.csv(wht_pc,file = '../Figures/Renovate_RECS/wht_pc_09.csv')

recs09$TENURE<-'Rented'
recs09[recs09$KOWNRENT==1,]$TENURE<-'Owned'

wht2<-tapply(recs09$NWEIGHT,list(recs09$WHEATAGE2,recs09$TENURE),sum)

w2<-melt(wht2[1:6,])
colnames(w2)<-c("Age","Tenure","Value")
windows()
ggplot(w2,aes(fill=Age,x =Tenure, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of water heating equipment, 2009",y="Percentage of households",x="Tenure") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

wht2[is.na(wht2)]<-0
wht_pc_ten<-round(wht2/rep(colSums(wht2),each=7),3)
write.csv(wht_pc_ten,file = '../Figures/Renovate_RECS/wht_pc_ten_09.csv')

# space heating 
# rename speat heat ages
recs09$EQUIPAGE2<-as.factor(recs09$EQUIPAGE)
levels(recs09$EQUIPAGE2)<-levels(recode(recs09$EQUIPAGE2,"-2"="NA/DontKnow","1"="<2YR","2"="2-4YR","3"="5-9YR","41"="10-14YR","42"="15-19YR","5"="20YR"))
recs09$EQUIPAGE2<-factor(recs09$EQUIPAGE2, ordered=TRUE, levels = c("<2YR","2-4YR","5-9YR","10-14YR","15-19YR","20YR","NA/DontKnow"))


sph<-tapply(recs09$NWEIGHT,list(recs09$EQUIPAGE2,recs09$TYPE),sum)

s<-melt(sph[1:6,])
colnames(s)<-c("Age","Type","Value")
windows()
ggplot(s,aes(fill=Age,x =Type, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of space heating equipment, 2009",y="Percentage of households",x="Type") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

sph[is.na(sph)]<-0
sph_pc<-round(sph/rep(colSums(sph),each=7),3)
write.csv(sph_pc,file = '../Figures/Renovate_RECS/sph_pc_09.csv')

sph2<-tapply(recs09$NWEIGHT,list(recs09$EQUIPAGE2,recs09$TENURE),sum)

s2<-melt(sph2[1:6,])
colnames(s2)<-c("Age","Tenure","Value")
windows()
ggplot(s2,aes(fill=Age,x =Tenure, y = Value)) + 
  geom_bar(position="fill", stat="identity",width = 0.75) +
  labs(title = "Age distribution of space heating equipment, 2009",y="Percentage of households",x="Tenure") + scale_y_continuous(labels=scales::percent) +
  theme(axis.text=element_text(size=10.5),
        axis.title=element_text(size=12,face = "bold"),
        plot.title = element_text(size = 14, face = "bold")) + scale_fill_brewer(palette="Dark2")

sph2[is.na(sph2)]<-0
sph_pc_ten<-round(sph2/rep(colSums(sph2),each=7),3)
write.csv(sph_pc_ten,file = '../Figures/Renovate_RECS/sph_pc_ten_09.csv')
