# FINAL results plotting for final results paper. This needs updating
library(ggplot2)
library(dplyr)
library(reshape2)
library(RColorBrewer)
# Nov 22 2020
# Updated with new results Jan 21 2021
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")
# load in results
# load("~/Yale Courses/Research/Final Paper/StockModelCode/us_FA_summaries.RData") # created by bs_combine
load("~/Yale Courses/Research/Final Paper/HSM_github/Summary_results/us_FA_summaries.RData")
load("~/Yale Courses/Research/Final Paper/StockModelCode/EG_NC_Summary4.RData") # created by bs_combine_NCEG
load("~/Yale Courses/Research/Final Paper/StockModelCode/EG_RegRen_Summary3.RData") # #3 done with updated characterisation of renovations
load("~/Yale Courses/Research/Final Paper/StockModelCode/EG_AdvRen_Summary3.RData") # #3 done with updated characterisation of renovations

# load("~/Yale Courses/Research/Final Paper/StockModelCode/EG_NC_Summary_LREC4.RData")
# load("~/Yale Courses/Research/Final Paper/StockModelCode/EG_RegRen_Summary_LREC3.RData")
# load("~/Yale Courses/Research/Final Paper/StockModelCode/EG_AdvRen_Summary_LREC3.RData")
## RR stands for regular renovations
tot<-data.frame(Year=2020:2060,EmGHG_base_RR=1e9*us_base_FA$EmGHG_tot,EmGHG_hiDR_RR=1e9*us_hiDR_FA$EmGHG_tot,EmGHG_hiMF_RR=1e9*us_hiMF_FA$EmGHG_tot,EmGHG_hiDRMF_RR=1e9*us_hiDRMF_FA$EmGHG_tot,EmGHG_redFA_RR=1e9*us_RFA_FA$EmGHG_tot,
                OpGHG_base_RR=GHG_base_p2020RR$GHG, OpGHG_hiDR_RR=GHG_hiDR_p2020RR$GHG, OpGHG_hiMF_RR=GHG_hiMF_p2020RR$GHG,OpGHG_hiDRMF_RR=GHG_hiDRMF_p2020RR$GHG,OpGHG_redFA_RR=GHG_base_p2020RR$GHG,
                OpGHG_base_AR=GHG_base_p2020$GHG, OpGHG_hiDR_AR=GHG_hiDR_p2020$GHG, OpGHG_hiMF_AR=GHG_hiMF_p2020$GHG,OpGHG_hiDRMF_AR=GHG_hiDRMF_p2020$GHG, OpGHG_redFA_AR=GHG_base_p2020$GHG,
                OpGHG_base_NC_RR=GHG_base$GHG,OpGHG_hiDR_NC_RR=GHG_hiDR$GHG,OpGHG_hiMF_NC_RR=GHG_hiMF$GHG,OpGHG_hiDRMF_NC_RR=GHG_hiDRMF$GHG,OpGHG_redFA_NC_RR=GHG_redFA$GHG)
tot[41,2:6]<-tot[40,2:6] # guess construction emissions for 2060

# first spline to calculate emissions by fuel type in new construction, for adv ren scenario
GHGel_base_NC<-data.frame(with(select(us_base_EG,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGel_base_NC)=c("Year","GHG")
GHGng_base_NC<-data.frame(with(select(us_base_EG,Year,NGGHG),spline(Year,NGGHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGng_base_NC)=c("Year","GHG")
GHGfo_base_NC<-data.frame(with(select(us_base_EG,Year,FOGHG),spline(Year,FOGHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGfo_base_NC)=c("Year","GHG")
GHGpr_base_NC<-data.frame(with(select(us_base_EG,Year,PrGHG),spline(Year,PrGHG,xout = 2020:2060)),method="spline()")[,1:2]
names(GHGpr_base_NC)=c("Year","GHG")

# emissions by construction and fuel, AR scenario
totf<-data.frame(Year=2020:2060,EmGHG_base_RR=1e9*us_base_FA$EmGHG_tot,
                OpGHG_base_El_OS=GHGel_base_p2020$GHG,OpGHG_base_NG_OS=GHGng_base_p2020$GHG,OpGHG_base_FO_OS=GHGfo_base_p2020$GHG,OpGHG_base_Pr_OS=GHGpr_base_p2020$GHG,
                OpGHG_base_El_NC=GHGel_base_NC$GHG,OpGHG_base_NG_NC=GHGng_base_NC$GHG,OpGHG_base_FO_NC=GHGfo_base_NC$GHG,OpGHG_base_Pr_NC=GHGpr_base_NC$GHG)
                
totf[41,2]<-totf[40,2] # guess construction emissions for 2060

tfm<-melt(totf,id.vars = "Year")
names(tfm)<-c("Year","Stage_Scen_Fuel_Stock","GHG")
tfm$Source<-"NA"
tfm[which(grepl("EmGHG",tfm$Stage_Scen_Fuel_Stock)),]$Source<-"Total Construction"
tfm[which(grepl("El",tfm$Stage_Scen_Fuel_Stock)),]$Source<-"Electricity"
tfm[which(grepl("NG",tfm$Stage_Scen_Fuel_Stock)),]$Source<-"Natural Gas"
tfm[which(grepl("FO",tfm$Stage_Scen_Fuel_Stock)),]$Source<-"Fuel Oil/Propane"
tfm[which(grepl("Pr",tfm$Stage_Scen_Fuel_Stock)),]$Source<-"Fuel Oil/Propane"

tot$GHGtot_base_RR<-tot$EmGHG_base_RR+tot$OpGHG_base_RR+tot$OpGHG_base_NC_RR
tot$GHGtot_hiDR_RR<-tot$EmGHG_hiDR_RR+tot$OpGHG_hiDR_RR+tot$OpGHG_hiDR_NC_RR    
tot$GHGtot_hiMF_RR<-tot$EmGHG_hiMF_RR+tot$OpGHG_hiMF_RR+tot$OpGHG_hiMF_NC_RR    
tot$GHGtot_hiDRMF_RR<-tot$EmGHG_hiDRMF_RR+tot$OpGHG_hiDRMF_RR+tot$OpGHG_hiDRMF_NC_RR  
tot$GHGtot_redFA_RR<-tot$EmGHG_redFA_RR+tot$OpGHG_redFA_RR+tot$OpGHG_redFA_NC_RR

tot$GHGtot_base_AR<-tot$EmGHG_base_RR+tot$OpGHG_base_AR+tot$OpGHG_base_NC_RR
tot$GHGtot_hiDR_AR<-tot$EmGHG_hiDR_RR+tot$OpGHG_hiDR_AR+tot$OpGHG_hiDR_NC_RR    
tot$GHGtot_hiMF_AR<-tot$EmGHG_hiMF_RR+tot$OpGHG_hiMF_AR+tot$OpGHG_hiMF_NC_RR    
tot$GHGtot_hiDRMF_AR<-tot$EmGHG_hiDRMF_RR+tot$OpGHG_hiDRMF_AR+tot$OpGHG_hiDRMF_NC_RR   
tot$GHGtot_redFA_AR<-tot$EmGHG_redFA_RR+tot$OpGHG_redFA_AR+tot$OpGHG_redFA_NC_RR

tot[,c("EmGHG_base_AR", "EmGHG_hiDR_AR","EmGHG_hiMF_AR", "EmGHG_hiDRMF_AR","EmGHG_redFA_AR")]<-tot[,c("EmGHG_base_RR", "EmGHG_hiDR_RR", "EmGHG_hiMF_RR", "EmGHG_hiDRMF_RR","EmGHG_redFA_RR")]
tot[,c("OpGHG_base_NC_AR", "OpGHG_hiDR_NC_AR","OpGHG_hiMF_NC_AR", "OpGHG_hiDRMF_NC_AR","OpGHG_redFA_NC_AR")]<-tot[,c("OpGHG_base_NC_RR", "OpGHG_hiDR_NC_RR", "OpGHG_hiMF_NC_RR", "OpGHG_hiDRMF_NC_RR","OpGHG_redFA_NC_RR")]

tm<-melt(tot[,c(1,22:31)],id.vars = "Year") # tot melt, total emissions
names(tm)[2:3]<-c("HSM_RS","GHG")
# no need to replicate and modify these files
tm_ee1<-melt(tot[seq(1,41,5),c(1:17,26:29)],id.vars = "Year") # tot melt; embodied, and energy related emissions
tm_ee<-melt(tot[seq(1,41,5),c(1:17,26:33)],id.vars = "Year") # tot melt; embodied, and energy related emissions
names(tm_ee)[2:3]<-c("Stage_HSM_RS","GHG")
tm_ee$Stage<-substr(tm_ee$Stage_HSM_RS,1,5)
# tm_ee$Scenario<-substr(tm_ee$Stage_HSM_RS,7,nchar(as.character(tm_ee$Stage_HSM_RS))-3)
tm_ee$Scenario<-"Baseline"
tm_ee[which(grepl("hiDR",tm_ee$Stage_HSM_RS)),]$Scenario<-"High Stock Turnover"
tm_ee[which(grepl("hiMF",tm_ee$Stage_HSM_RS)),]$Scenario<-"High Multifamily"
tm_ee[which(grepl("hiDRMF",tm_ee$Stage_HSM_RS)),]$Scenario<-"High TO & MF"
tm_ee$Renovation<-substr(tm_ee$Stage_HSM_RS,nchar(as.character(tm_ee$Stage_HSM_RS))-1,nchar(as.character(tm_ee$Stage_HSM_RS)))
tm_ee[tm_ee$Stage=="EmGHG",]$Stage<-"Construction"
tm_ee[tm_ee$Stage=="OpGHG",]$Stage<-"Energy"
tm_ee$Source<-"Pre-2020 Housing Energy"
tm_ee[tm_ee$Stage=="Construction",]$Source<-"Construction"
tm_ee[which(grepl("NC",tm_ee$Stage_HSM_RS)),]$Source<-"Post-2020 Housing Energy"
# pick up here
tm_base_diff<-tot[,c(1:21,32:41)]
# remove the baseline RR values
tm_base_diff[,2:6]<-tm_base_diff[,2:6]-tm_base_diff[,2]
tm_base_diff[,8:11]<-tm_base_diff[,8:11]-tm_base_diff[,7]
tm_base_diff[,12:16]<-tm_base_diff[,12:16]-tm_base_diff[,7]
tm_base_diff[,17:21]<-tm_base_diff[,17:21]-tm_base_diff[,17]
tm_base_diff[,22:26]<-tm_base_diff[,22:26]-tm_base_diff[,22]
tm_base_diff[,27:31]<-tm_base_diff[,27:31]-tm_base_diff[,27] # 
tm_base_diff[,c(7)]<-0

tmbds<-as.data.frame(colSums(tm_base_diff[,2:31]))
tmbds$Stage_HSM_Ren<-rownames(tmbds)
rownames(tmbds)<-1:nrow(tmbds)
tmbds$Stage<-"Pre-2020 Housing Energy"
tmbds[which(grepl("EmGHG",tmbds$Stage_HSM_Ren)),]$Stage<-"Total Construction"
tmbds[which(grepl("NC",tmbds$Stage_HSM_Ren)),]$Stage<-"Post-2020 Housing Energy"
tmbds$Scenario<-"Baseline"
tmbds[which(grepl("hiDR",tmbds$Stage_HSM_Ren)),]$Scenario<-"High Stock Turnover"
tmbds[which(grepl("hiMF",tmbds$Stage_HSM_Ren)),]$Scenario<-"High Multifamily"
tmbds[which(grepl("hiDRMF",tmbds$Stage_HSM_Ren)),]$Scenario<-"High TO & MF"
tmbds[which(grepl("redFA",tmbds$Stage_HSM_Ren)),]$Scenario<-"Red. Floor Area"
tmbds$Renovation<-"Regular"
tmbds[which(grepl("AR",tmbds$Stage_HSM_Ren)),]$Renovation<-"Advanced"
names(tmbds)[1]<-"GHG"

tm_coh<-melt(tm_base_diff,id.vars = "Year")
names(tm_coh)<-c("Year","Stage_HSM_Ren","GHG")
tm_coh$Stage<-"Pre-2020 Housing Energy"
tm_coh[which(grepl("EmGHG",tm_coh$Stage_HSM_Ren)),]$Stage<-"Total Construction"
tm_coh[which(grepl("NC",tm_coh$Stage_HSM_Ren)),]$Stage<-"Post-2020 Housing Energy"
tm_coh$Scenario<-"Baseline"
tm_coh[which(grepl("hiDR",tm_coh$Stage_HSM_Ren)),]$Scenario<-"High Stock Turnover"
tm_coh[which(grepl("hiMF",tm_coh$Stage_HSM_Ren)),]$Scenario<-"High Multifamily"
tm_coh[which(grepl("hiDRMF",tm_coh$Stage_HSM_Ren)),]$Scenario<-"High TO & MF"
tm_coh$Renovation<-"Regular"
tm_coh[which(grepl("AR",tm_coh$Stage_HSM_Ren)),]$Renovation<-"Advanced"

tm$StockScenario<-substr(tm$HSM_RS,8,nchar(as.character(tm$HSM_RS))-3)
tm$Renovation<-substr(tm$HSM_RS,nchar(as.character(tm$HSM_RS))-1,nchar(as.character(tm$HSM_RS)))

tm[tm$StockScenario=="base",]$StockScenario<-"1. Baseline"
tm[tm$StockScenario=="hiDR",]$StockScenario<-"2. High Turnover"
tm[tm$StockScenario=="hiMF",]$StockScenario<-"3. High Multifamily"
tm[tm$StockScenario=="hiDRMF",]$StockScenario<-"4. High TO & MF"
tm[tm$StockScenario=="redFA",]$StockScenario<-"5. Red. Floor Area"
tm[tm$Renovation=="RR",]$Renovation<-"Regular"
tm[tm$Renovation=="AR",]$Renovation<-"Advanced"
pdf<-data.frame(xa=2050,ya=330) # 20% of 2005 emissions (1.65 Gt total from residential sector energy + construction). Based on US GHGI plus Berrill et al JIE 
odf<-data.frame(xa=2030,ya=450) # 50% of 2020 emissions based on this study
windows(width = 7.4,height = 6)
ggplot(tm,aes(Year,1e-9*GHG,group=HSM_RS)) + geom_line(aes(color=StockScenario,linetype=Renovation),size=1)+ scale_y_continuous(labels = scales::comma,limits = c(300,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  labs(title ="a) Total annual residential GHG emissions, 2020-2060",y="Mton CO2e",subtitle = "Mid-Case Electricity GHG Scenario") + theme_bw() + scale_color_brewer(palette="Set1")  + scale_linetype_manual(values=c("dotdash", "solid")) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))
# ggplot(tm,aes(Year,1e-9*GHG,group=HSM_RS)) + geom_line(aes(color=StockScenario,linetype=Renovation),size=1)+ scale_y_continuous(labels = scales::comma,limits = c(300,1000)) + 
#   geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
#   geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
#   labs(title ="b) Total annual residential GHG emissions, 2020-2060",y="Mton CO2e",subtitle = "Low RE Cost Electricity GHG Scenario") + theme_bw() + scale_color_brewer(palette="Set1")  + scale_linetype_manual(values=c("dotdash", "solid")) +
#   theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))



windows()
ggplot(tm[tm$Renovation=="Regular",],aes(Year,1e-9*GHG,group=HSM_RS)) + geom_line(aes(color=StockScenario),size=1)+ scale_y_continuous(labels = scales::comma,limits = c(350,1000)) + 
  labs(title ="a) Total annual residential GHG emissions, 2020-2060",y="Mton CO2e",subtitle = "Mid-Case Electricity GHG Scenario") + theme_bw() + scale_color_brewer(palette="Set1")  + scale_linetype_manual(values=c("dotdash", "solid")) + 
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))

tot$GHG_cum_base_RR<-0
for (r in 1:41) {tot$GHG_cum_base_RR[r]<-sum(tot$GHGtot_base_RR[1:r])}
tot$GHG_cum_hiDR_RR<-0
for (r in 1:41) {tot$GHG_cum_hiDR_RR[r]<-sum(tot$GHGtot_hiDR_RR[1:r])}
tot$GHG_cum_hiMF_RR<-0
for (r in 1:41) {tot$GHG_cum_hiMF_RR[r]<-sum(tot$GHGtot_hiMF_RR[1:r])}
tot$GHG_cum_hiDRMF_RR<-0
for (r in 1:41) {tot$GHG_cum_hiDRMF_RR[r]<-sum(tot$GHGtot_hiDRMF_RR[1:r])}
tot$GHG_cum_redFA_RR<-0
for (r in 1:41) {tot$GHG_cum_redFA_RR[r]<-sum(tot$GHGtot_redFA_RR[1:r])}

tot$GHG_cum_base_AR<-0
for (r in 1:41) {tot$GHG_cum_base_AR[r]<-sum(tot$GHGtot_base_AR[1:r])}
tot$GHG_cum_hiDR_AR<-0
for (r in 1:41) {tot$GHG_cum_hiDR_AR[r]<-sum(tot$GHGtot_hiDR_AR[1:r])}
tot$GHG_cum_hiMF_AR<-0
for (r in 1:41) {tot$GHG_cum_hiMF_AR[r]<-sum(tot$GHGtot_hiMF_AR[1:r])}
tot$GHG_cum_hiDRMF_AR<-0
for (r in 1:41) {tot$GHG_cum_hiDRMF_AR[r]<-sum(tot$GHGtot_hiDRMF_AR[1:r])}
tot$GHG_cum_redFA_AR<-0
for (r in 1:41) {tot$GHG_cum_redFA_AR[r]<-sum(tot$GHGtot_redFA_AR[1:r])}
# cumulative emissions
tmc<-melt(tot[,c(1,26:33)],id.vars = "Year")
names(tmc)[2:3]<-c("HSM_RS","GHG")

tmc$StockScenario<-substr(tmc$HSM_RS,9,nchar(as.character(tmc$HSM_RS))-3)
tmc$Renovation<-substr(tmc$HSM_RS,nchar(as.character(tmc$HSM_RS))-1,nchar(as.character(tmc$HSM_RS)))
# these names need fixed if I want to redo the graph of cumulative emission
tmc[tmc$StockScenario=="base",]$StockScenario<-"Baseline"
tmc[tmc$StockScenario=="hiDR",]$StockScenario<-"High Turnover"
tmc[tmc$StockScenario=="hiMF",]$StockScenario<-"High Multifamily"
tmc[tmc$StockScenario=="hiDRMF",]$StockScenario<-"High TO & MF"
tmc[tmc$Renovation=="RR",]$Renovation<-"Regular"
tmc[tmc$Renovation=="AR",]$Renovation<-"Advanced"

windows() # a less impressive graph
ggplot(tmc,aes(Year,1e-9*GHG,group=HSM_RS)) + geom_line(aes(color=StockScenario,linetype=Renovation),size=1)+ scale_y_continuous(labels = scales::comma) + 
  labs(title ="Cumulative residential GHG emissions, 2020-2060",y="Mton CO2e") + theme_bw() + scale_color_brewer(palette="Set1") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))

## barplot of annual emissions, embodied and energy, every 5 years
cols<-colorRampPalette(brewer.pal(9,"Set1"))(9)[c(3,1,2)]
df<-tm_ee[tm_ee$Renovation=="RR" ,]
windows()
ggplot(df[df$Scenario=="Baseline",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() +  scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "Baseline, Regular Renovation") + guides(fill = guide_legend(reverse = TRUE))
windows()
ggplot(df[df$Scenario=="High Stock Turnover",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() + scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "High Stock Turnover, Regular Renovation") + guides(fill = guide_legend(reverse = TRUE))
windows()
ggplot(df[df$Scenario=="High Multifamily",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() + scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "High Multifamily, Regular Renovation") + guides(fill = guide_legend(reverse = TRUE))
windows()
ggplot(df[df$Scenario=="High TO & MF",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() + scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "High Stock Turnover & Multifamily, Regular Renovation") + guides(fill = guide_legend(reverse = TRUE))

df2<-tm_ee[tm_ee$Renovation=="AR" ,]
windows()
ggplot(df2[df2$Scenario=="Baseline",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() +  scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "Baseline, Advanced Renovation") + guides(fill = guide_legend(reverse = TRUE))
windows()
ggplot(df2[df2$Scenario=="High Stock Turnover",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() + scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "High Stock Turnover, Advanced Renovation") + guides(fill = guide_legend(reverse = TRUE))
windows()
ggplot(df2[df2$Scenario=="High Multifamily",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() + scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "High Multifamily, Advanced Renovation") + guides(fill = guide_legend(reverse = TRUE))
windows()
ggplot(df2[df2$Scenario=="High TO & MF",],aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity",position = position_stack(reverse = TRUE)) +  theme_bw() + scale_fill_manual(values = cols) + ylim(0,950) +
  labs(title = "Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "High Stock Turnover & Multifamily, Advanced Renovation") + guides(fill = guide_legend(reverse = TRUE))

tfm<-tfm[tfm$Year %in% c(seq(2020,2060,5)),]
windows()
ggplot(tfm,aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity") +  theme_bw() + scale_fill_brewer(palette="Dark2") + ylim(0,950) +
  labs(title = "a) Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "Baseline, Advanced Renovation, Mid-Case Electricity") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))
windows()
ggplot(tfm,aes(x=Year,y=1e-9*GHG,fill=Source))+geom_bar(stat="identity") +  theme_bw() + scale_fill_brewer(palette="Dark2") + ylim(0,950) +
  labs(title = "b) Annual GHG Emissions from Construction and Energy, 2020-2060", y = "Mt CO2e",subtitle = "Baseline, Advanced Renovation, Low RE Cost Electricity") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))

### stacked bar showing differences to baseline
# tm cohort compare
tm_cc<-tmbds[-c(which(tmbds$Scenario=="Baseline" & tmbds$Renovation =="Regular")),]
tm_cc$HSM_Ren<-NA
tm_cc[which(grepl("base",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("AR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"1 Base_AdvRen"
tm_cc[which(grepl("hiDR_",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("RR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"2 HiTO_RegRen"
tm_cc[which(grepl("hiDR_",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("AR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"2 HiTO_AdvRen"
tm_cc[which(grepl("hiMF",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("RR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"3 HiMF_RegRen"
tm_cc[which(grepl("hiMF",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("AR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"3 HiMF_AdvRen"
tm_cc[which(grepl("hiDRMF",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("RR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"4 HiTO.MF_RegRen"
tm_cc[which(grepl("hiDRMF",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("AR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"4 HiTO.MF_AdvRen"
tm_cc[which(grepl("redFA",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("RR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"5 RedFA_RegRen"
tm_cc[which(grepl("redFA",tm_cc$Stage_HSM_Ren,fixed = TRUE) & grepl("AR",tm_cc$Stage_HSM_Ren,fixed = TRUE)),]$HSM_Ren<-"5 RedFA_AdvRen"
or<-c(4,5,6,1,7,2,3,8,9)
or<-1:9
tsc<-as.data.frame(tapply(tm_cc$GHG,tm_cc$HSM_Ren,sum)) # tot scenario compare
names(tsc)<-"GHG"
tsc$HSM_Ren<-rownames(tsc)
rownames(tsc)<-1:nrow(tsc)
tsc<-tsc[order(tsc$GHG),]
tsc$or<-order(tsc$GHG,decreasing = TRUE)

tmc2<-merge(tm_cc,tsc,by="HSM_Ren")
tmc2$HSM_Ren<-gsub("_","\n",tmc2$HSM_Ren)
tsc$HSM_Ren<-gsub("_","\n",tsc$HSM_Ren)
tmc2$Source<-tmc2$Stage

# tm_cc$netGHG<-NA
# tm_cc[which(tm_cc$HSM_Ren=="1 Base_AdvRen")[1],]$netGHG<-tsc[tsc$HSM_Ren=="1 Base_AdvRen",]$GHG
# tm_cc[which(tm_cc$HSM_Ren=="4 HiDR.MF_RegRen")[1],]$netGHG<-tsc[tsc$HSM_Ren=="4 HiDR.MF_RegRen",]$GHG
# 
# windows()
# ggplot(tm_cc,aes(x=HSM_Ren,y=1e-9*GHG,fill=Stage)) + geom_bar(stat="identity") +  theme_bw() + scale_fill_brewer(palette="Dark2") +
#    geom_line(data=tsc, aes(x=HSM_Ren,y=1e-9*GHG))
# 
# windows()
# ggplot(tmc2,aes(x=reorder(HSM_Ren,or), y=1e-9*GHG.x,fill=Stage)) + geom_bar(stat="identity") +  theme_bw() + scale_fill_brewer(palette="Dark2") #+
#   geom_line(data=tsc, aes(x=reorder(HSM_Ren,or),y=1e-9*GHG))

windows() # Finally this works
plotS1 <- ggplot(tmc2) 
plotS1 +  geom_bar(aes(x=reorder(HSM_Ren,or),y=1e-9*GHG.x,fill=Source), stat="identity") +
  geom_line(data=tsc, aes(x=HSM_Ren,y=1e-9*GHG,group=1,color="Line"),size=1) + geom_point(data=tsc, aes(x=HSM_Ren,y=1e-9*GHG,group=1,color="Line"),size=2.5) +
 scale_color_manual(name = NULL, values = c("Line" = "black"),labels = "Net Diff in GHG vs\nBaseline Reg. Ren")  +  theme_bw() + scale_fill_brewer(palette="Set1") +
  labs(title = "Difference in cumulative 2020-2060 emissions by scenario, relative to Baseline with Reg. Renovation", y = "Mt CO2e", x = "Stock and Renovation Scenario", subtitle = "Mid-Case Electricity GHG Scenario")+ scale_y_continuous(labels = scales::comma) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 13, face = "bold"),legend.text = element_text(size = 11)) +
  geom_hline(yintercept=0, color = "black", size=1)

# start again ###########
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
# load("bs2020GHG2.RData")
load("../Intermediate_results/RenAdvanced.RData")
rs_2020_60_AR<-rs_2020_2060
rm(rs_2020_2060)
load("../Intermediate_results/RenStandard.RData")
rs_2020_60_RR<-rs_2020_2060
rm(rs_2020_2060)
load("NC_EG_full.RData") # the 32 data frames describing energy consumption in new cohorts in each sim year - scenario
load("../ExtData/GHGI_MidCase.RData") # Elec GHG int data in Mid-Case scenario
load("../ExtData/GHGI_LowRECost.RData") # Elec GHG int data in Low RE Cost Scenario
# load("EnergyLinModels.RData") # Linear models for esimating energy consumption


colselNC<-function(bs) {
  bs$Year_Building<-paste(bs$Year,bs$Building,sep=".b")
  bs<-bs[,c("Year_Building","Year", "County","State","Geometry.Building.Type.ACS","Geometry.Building.Type.RECS","Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","HVAC.Heating.Type.And.Fuel",
            "Water.Heater.Fuel","Water.Heater.Efficiency","HVAC.Cooling.Type" ,"HVAC.Cooling.Efficiency","Insulation.Wall","Insulation.Slab",
            names(bs)[c(111,113:116,120:127,129:153)])] # numbered columns are base weight, energy by type, elec intensities by year, TC, ctyTC, weighg adjustents, total energy, and total energy GHG. # add heating fuel and type
  
}
ll<-list(bs2025b,bs2030b,bs2035b,bs2040b,bs2045b,bs2050b,bs2055b,bs2060b,
         bs2025hdr,bs2030hdr,bs2035hdr,bs2040hdr,bs2045hdr,bs2050hdr,bs2055hdr,bs2060hdr,
         bs2025hmf,bs2030hmf,bs2035hmf,bs2040hmf,bs2045hmf,bs2050hmf,bs2055hmf,bs2060hmf,
         bs2025hdrmf,bs2030hdrmf,bs2035hdrmf,bs2040hdrmf,bs2045hdrmf,bs2050hdrmf,bs2055hdrmf,bs2060hdrmf)

lln<-c('bs2025b','bs2030b','bs2035b','bs2040b','bs2045b','bs2050b','bs2055b','bs2060b',
       'bs2025hdr','bs2030hdr','bs2035hdr','bs2040hdr','bs2045hdr','bs2050hdr','bs2055hdr','bs2060hdr',
       'bs2025hmf','bs2030hmf','bs2035hmf','bs2040hmf','bs2045hmf','bs2050hmf','bs2055hmf','bs2060hmf',
       'bs2025hdrmf','bs2030hdrmf','bs2035hdrmf','bs2040hdrmf','bs2045hdrmf','bs2050hdrmf','bs2055hdrmf','bs2060hdrmf')

ll2<-lapply(ll, colselNC) # changed here from com_calc
for (i in 1:length(lln)) {
  assign(lln[i],ll2[[i]])
}

bs_base_NC<-rbind(bs2025b,bs2030b,bs2035b,bs2040b,bs2045b,bs2050b,bs2055b,bs2060b)
# new lines added to enabling summing up characteritsics over the whole stock and time perion with one tapply function
bsb_NCm<-melt(bs_base_NC,id.vars = names(bs_base_NC)[-c(32:39)])
names(bsb_NCm)[2]<-"Sample.Year"
bsb_NCm$Sim.Year<-substr(bsb_NCm$variable,7,10)
bsb_NCm$Stock.Scenario<-substr(bsb_NCm$variable,2,5)
bsb_NCm<-bsb_NCm[,-48] # remove the 'wbase_year' column, now summarized in two other new colums
names(bsb_NCm)[48]<-"w_adj"

tapply(bsb_NCm$base_weight*bsb_NCm$w_adj,bsb_NCm$Sim.Year,sum)
hf<-as.data.frame(tapply(bsb_NCm$base_weight*bsb_NCm$w_adj,list(bsb_NCm$Sim.Year,bsb_NCm$Heating.Fuel),sum))
hf$Year<-rownames(hf)
hfm<-melt(hf,id.vars = "Year")
names(hfm)[2:3]<-c("HeatFuel","Count")
windows()
ggplot(hfm,aes(x=Year,y=1e-6*Count,fill=HeatFuel))+geom_bar(stat="identity") +  theme_bw() + scale_fill_brewer(palette="Dark2") + 
  labs(title = "New Housing Construction by Main Heat FUel", y = "Million Housing Units",subtitle = "Baseline") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))
# heat fuel and heating system type
htf<-as.data.frame(tapply(bsb_NCm$base_weight*bsb_NCm$w_adj,list(bsb_NCm$Sim.Year,bsb_NCm$HVAC.Heating.Type.And.Fuel),sum))
htf$Year<-rownames(htf)
names(htf)[which(names(htf) %in% c("None None","Other Fuel Shared Heating","Void"))]<-"Other/None"
htfm<-melt(htf,id.vars = "Year")
names(htfm)[2:3]<-c("HeatFuelType","Count")
# cols<-colorRampPalette(brewer.pal(8,"Dark2"))(length(unique(htfm$HeatFuelType)))
cols<-colorRampPalette(brewer.pal(9,"Set1"))(length(unique(htfm$HeatFuelType)))
windows()
ggplot(htfm,aes(x=Year,y=1e-6*Count,fill=HeatFuelType))+geom_bar(stat="identity") +  theme_bw() + scale_fill_manual(values = cols) +# scale_fill_brewer(palette="Dark2") + 
  labs(title = "New Housing Construction by Space Heating Fuel and Technology", y = "Million Housing Units",subtitle = "Baseline") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))
# water heating fuel and heating system type
wf<-as.data.frame(tapply(bsb_NCm$base_weight*bsb_NCm$w_adj,list(bsb_NCm$Sim.Year,bsb_NCm$Water.Heater.Efficiency),sum))
wf$Year<-rownames(wf)
wfm<-melt(wf,id.vars = "Year")
names(wfm)[2:3]<-c("DHWFuelType","Count")
cols<-colorRampPalette(brewer.pal(9,"Set1"))(length(unique(wfm$DHWFuelType)))
windows()
ggplot(wfm,aes(x=Year,y=1e-6*Count,fill=DHWFuelType))+geom_bar(stat="identity") +  theme_bw()  + scale_fill_manual(values = cols) + 
  labs(title = "New Housing Construction by Water Heating Fuel and Technology", y = "Million Housing Units",subtitle = "Baseline") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))

# cooling system type
cte<-as.data.frame(tapply(bsb_NCm$base_weight*bsb_NCm$w_adj,list(bsb_NCm$Sim.Year,bsb_NCm$HVAC.Cooling.Efficiency),sum))
cte$Year<-rownames(cte)
ctem<-melt(cte,id.vars = "Year")
names(ctem)[2:3]<-c("ACType","Count")
cols<-colorRampPalette(brewer.pal(9,"Set1"))(length(unique(ctem$ACType)))
windows()
ggplot(ctem,aes(x=Year,y=1e-6*Count,fill=ACType))+geom_bar(stat="identity") +  theme_bw()  + scale_fill_manual(values = cols) + 
  labs(title = "New Housing Construction by Space Cooling Technology", y = "Million Housing Units",subtitle = "Baseline") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))

# wall insulation
iw<-as.data.frame(tapply(bsb_NCm$base_weight*bsb_NCm$w_adj,list(bsb_NCm$Sim.Year,bsb_NCm$Insulation.Wall),sum))
iw$Year<-rownames(iw)
iwm<-melt(iw,id.vars = "Year")
names(iwm)[2:3]<-c("WallInsulation","Count")
cols<-colorRampPalette(brewer.pal(9,"Set1"))(length(unique(iwm$WallInsulation)))
windows()
ggplot(iwm,aes(x=Year,y=1e-6*Count,fill=WallInsulation))+geom_bar(stat="identity") +  theme_bw()  + scale_fill_manual(values = cols) + 
  labs(title = "New Housing Construction by Wall Insulation Type", y = "Million Housing Units",subtitle = "Baseline") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))

is<-as.data.frame(tapply(bsb_NCm$base_weight*bsb_NCm$w_adj,list(bsb_NCm$Sim.Year,bsb_NCm$Insulation.Slab),sum))
is$Year<-rownames(is)
ism<-melt(is,id.vars = "Year")
names(ism)[2:3]<-c("SlabInsulation","Count")
ism<-ism[!ism$SlabInsulation=="None",]
cols<-colorRampPalette(brewer.pal(9,"Set1"))(length(unique(ism$SlabInsulation)))
windows()
ggplot(ism,aes(x=Year,y=1e-6*Count,fill=SlabInsulation))+geom_bar(stat="identity") +  theme_bw()  + scale_fill_manual(values = cols) + 
  labs(title = "New Housing Construction by Slab Insulation Type", y = "Million Housing Units",subtitle = "Baseline, Houses with Slab Foundation Only") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))

bs_base_NC$weight_yr<-0
bs_base_NC[bs_base_NC$Year==2025,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2025,]$base_weight*bs_base_NC[bs_base_NC$Year==2025,]$wbase_2025
bs_base_NC[bs_base_NC$Year==2030,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2030,]$base_weight*bs_base_NC[bs_base_NC$Year==2030,]$wbase_2030
bs_base_NC[bs_base_NC$Year==2035,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2035,]$base_weight*bs_base_NC[bs_base_NC$Year==2035,]$wbase_2035
bs_base_NC[bs_base_NC$Year==2025,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2025,]$base_weight*bs_base_NC[bs_base_NC$Year==2025,]$wbase_2025
bs_base_NC[bs_base_NC$Year==2025,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2025,]$base_weight*bs_base_NC[bs_base_NC$Year==2025,]$wbase_2025
bs_base_NC[bs_base_NC$Year==2025,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2025,]$base_weight*bs_base_NC[bs_base_NC$Year==2025,]$wbase_2025
bs_base_NC[bs_base_NC$Year==2025,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2025,]$base_weight*bs_base_NC[bs_base_NC$Year==2025,]$wbase_2025
bs_base_NC[bs_base_NC$Year==2025,]$weight_yr<-bs_base_NC[bs_base_NC$Year==2025,]$base_weight*bs_base_NC[bs_base_NC$Year==2025,]$wbase_2025

# rs_2020_60_AR$Year_Building<-paste(rs_2020_60_AR$Year,rs_2020_60_AR$Building,sep="_")
rs_all_AR<-rs_2020_60_AR
rs_all_AR$Year_Building<-paste(rs_all_AR$Year,rs_all_AR$Building,sep="_")

rs_all_AR<-rs_all_AR[,c("Year_Building","Year", "Building", "County","State","Geometry.Building.Type.ACS","Geometry.Building.Type.RECS","Vintage","Vintage.ACS",
                        "Heating.Fuel","Geometry.Floor.Area","Water.Heater.Fuel","HVAC.Cooling.Type.LM","Vintage.LM","ASHRAE.IECC.Climate.Zone.LM",
                        "Clothes.Dryer.Fuel.LM",names(rs_all_AR)[c(122,112:115,143:146)])] # i can't take out so many columns here, i need to keep those needed for the linear models. currently comes to 25 cols
# numbered columns are base weight, energy by type, change in renovated systems
# All these columns obv cannot be removed for the ResStock simulations, this step should be applied after the ResStock energy simulations when I do it that way.
rs_all_AR<-rs_all_AR[order(rs_all_AR$Building),]
# SAME  for Reg Reno
rs_all_RR<-rs_2020_60_RR
rs_all_RR$Year_Building<-paste(rs_all_RR$Year,rs_all_RR$Building,sep="_")

rs_all_RR<-rs_all_RR[,c("Year_Building","Year", "Building", "County","State","Geometry.Building.Type.ACS","Geometry.Building.Type.RECS","Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area",
                        "Water.Heater.Fuel","HVAC.Cooling.Type.LM","Vintage.LM","ASHRAE.IECC.Climate.Zone.LM","Clothes.Dryer.Fuel.LM",names(rs_all_RR)[c(122,112:115,143:146)])] # i can't take out so many columns here, i need to keep those needed for the linear models. currently comes to 25 cols
# numbered columns are base weight, energy by type, change in renovated systems
# All these columns obv cannot be removed for the ResStock simulations, this step should be applied after the ResStock energy simulations when I do it that way.
rs_all_RR<-rs_all_RR[order(rs_all_RR$Building),]


# add weighting factors to renovation files
load("decayFactors3.RData") 
load("~/Yale Courses/Research/Final Paper/StockModelCode/ctycode.RData")
ctycode[ctycode$GeoID==35013,]$RS_ID<-"NM, Dona Ana County"
ctycode[ctycode$GeoID==22059,]$RS_ID<-"LA, La Salle Parish"
ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)

gicty_rto[gicty_rto$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto[gicty_rto$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto<-merge(gicty_rto,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_yr<-gicty_rto[gicty_rto$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic<-dcast(gicty_rto_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic)[2:8]<-paste("GHG_int",names(gic)[2:8],sep="_")
gic$GHG_int_2055<-0.96* gic$GHG_int_2050
gic$GHG_int_2060<-0.96* gic$GHG_int_2055
gic[,2:10]<-gic[,2:10]/3600 # convert from kg/MWh to kg/MJ

# do the same process for the Low RE Cost electricity data
gicty_rto_LREC[gicty_rto_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto_LREC[gicty_rto_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto_LREC<-merge(gicty_rto_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_LREC_yr<-gicty_rto_LREC[gicty_rto_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic_LRE<-dcast(gicty_rto_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic_LRE)[2:8]<-paste("GHG_int",names(gic_LRE)[2:8],sep="_")
gic_LRE$GHG_int_2055<-0.96* gic_LRE$GHG_int_2050
gic_LRE$GHG_int_2060<-0.96* gic_LRE$GHG_int_2055
gic_LRE[,2:10]<-gic_LRE[,2:10]/3600 # convert from kg/MWh to kg/MJ
names(gic_LRE)[2:10]<-paste(names(gic_LRE)[2:10],"LRE",sep = "_")


sb<-merge(sb,ctycode)
shdr<-merge(shdr,ctycode)
shmf<-merge(shmf,ctycode)
shdm<-merge(shdm,ctycode)

sbm<-melt(sb)
sbm$variable<-gsub("p19","<19",sbm$variable)
sbm$TCY<-substr(sbm$variable,4,18)
sbm$TCY<-gsub("0_","0-",sbm$TCY)
# fix/revert the <1940_
sbm$TCY<-gsub("<1940-","<1940_",sbm$TCY)
sbm<-merge(sbm,ctycode)
sbm$ctyTCY<-paste(sbm$RS_ID,sbm$TCY,sep="")
sbm<-sbm[,c("ctyTCY","value")]
names(sbm)[2]<-"wf_base"
# organize so there are eight columns, one for each future year. 
sbm$Year<-substr(sbm$ctyTCY,nchar(sbm$ctyTCY)-3,nchar(sbm$ctyTCY))
sbm$ctyTCY<-substr(sbm$ctyTCY,1,nchar(sbm$ctyTCY)-5)
sbm<-dcast(sbm,ctyTCY~Year,value.var = "wf_base")
sbm[is.na(sbm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(sbm)[1:9]<-c("ctyTC","wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060")
sbm$wbase_2020<-c(1,1,1,1,1,1,0,0,0,0)
sbm<-sbm[,c(1,10,2:9)]

# create the desirable data frame for weighting factors in the hiDR scenario
shdrm<-melt(shdr)
shdrm$variable<-gsub("p19","<19",shdrm$variable)
shdrm$TCY<-substr(shdrm$variable,4,18)
shdrm$TCY<-gsub("0_","0-",shdrm$TCY)
# fix/revert the <1940_
shdrm$TCY<-gsub("<1940-","<1940_",shdrm$TCY)
shdrm<-merge(shdrm,ctycode)
shdrm$ctyTCY<-paste(shdrm$RS_ID,shdrm$TCY,sep="")
shdrm<-shdrm[,c("ctyTCY","value")]
names(shdrm)[2]<-"wf_hiDR"
# organize so there are eight columns, one for each future year. 
shdrm$Year<-substr(shdrm$ctyTCY,nchar(shdrm$ctyTCY)-3,nchar(shdrm$ctyTCY))
shdrm$ctyTCY<-substr(shdrm$ctyTCY,1,nchar(shdrm$ctyTCY)-5)
shdrm<-dcast(shdrm,ctyTCY~Year,value.var = "wf_hiDR")
shdrm[is.na(shdrm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(shdrm)[1:9]<-c("ctyTC","whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060")
shdrm$whiDR_2020<-c(1,1,1,1,1,1,0,0,0,0)
shdrm<-shdrm[,c(1,10,2:9)]

# create the desirable data frame for weighting factors in the hiMF scenario
shmfm<-melt(shmf)
shmfm$variable<-gsub("p19","<19",shmfm$variable)
shmfm$TCY<-substr(shmfm$variable,4,18)
shmfm$TCY<-gsub("0_","0-",shmfm$TCY)
# fix/revert the <1940_
shmfm$TCY<-gsub("<1940-","<1940_",shmfm$TCY)
shmfm<-merge(shmfm,ctycode)
shmfm$ctyTCY<-paste(shmfm$RS_ID,shmfm$TCY,sep="")
shmfm<-shmfm[,c("ctyTCY","value")]
names(shmfm)[2]<-"wf_hiMF"
# organize so there are eight columns, one for each future year. 
shmfm$Year<-substr(shmfm$ctyTCY,nchar(shmfm$ctyTCY)-3,nchar(shmfm$ctyTCY))
shmfm$ctyTCY<-substr(shmfm$ctyTCY,1,nchar(shmfm$ctyTCY)-5)
shmfm<-dcast(shmfm,ctyTCY~Year,value.var = "wf_hiMF")
shmfm[is.na(shmfm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(shmfm)[1:9]<-c("ctyTC","whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")
shmfm$whiMF_2020<-c(1,1,1,1,1,1,0,0,0,0)
shmfm<-shmfm[,c(1,10,2:9)]

# create the desirable data frame for weighting factors in the hiDRMF scenario
shdmm<-melt(shdm)
shdmm$variable<-gsub("p19","<19",shdmm$variable)
shdmm$TCY<-substr(shdmm$variable,4,18)
shdmm$TCY<-gsub("0_","0-",shdmm$TCY)
# fix/revert the <1940_
shdmm$TCY<-gsub("<1940-","<1940_",shdmm$TCY)
shdmm<-merge(shdmm,ctycode)
shdmm$ctyTCY<-paste(shdmm$RS_ID,shdmm$TCY,sep="")
shdmm<-shdmm[,c("ctyTCY","value")]
names(shdmm)[2]<-"wf_hiDRMF"
# organize so there are eight columns, one for each future year. 
shdmm$Year<-substr(shdmm$ctyTCY,nchar(shdmm$ctyTCY)-3,nchar(shdmm$ctyTCY))
shdmm$ctyTCY<-substr(shdmm$ctyTCY,1,nchar(shdmm$ctyTCY)-5)
shdmm<-dcast(shdmm,ctyTCY~Year,value.var = "wf_hiDRMF")
shdmm[is.na(shdmm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(shdmm)[1:9]<-c("ctyTC","whiDRMF_2025","whiDRMF_2030","whiDRMF_2035","whiDRMF_2040","whiDRMF_2045","whiDRMF_2050","whiDRMF_2055","whiDRMF_2060")
shdmm$whiDRMF_2020<-c(1,1,1,1,1,1,0,0,0,0)
shdmm<-shdmm[,c(1,10,2:9)]

rs_all_AR$TC<-"MF"
rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all_AR$TC<-paste(rs_all_AR$TC,rs_all_AR$Vintage.ACS,sep="_")
rs_all_AR$ctyTC<-paste(rs_all_AR$County,rs_all_AR$TC,sep = "")
rs_all_AR$ctyTC<-gsub("2010s","2010-19",rs_all_AR$ctyTC)

# at this stage we are at 27 columns
# now add 9 columns for each stock scenario to bring us to 63
rs_all_AR<-left_join(rs_all_AR,sbm,by="ctyTC")
rs_all_AR<-left_join(rs_all_AR,shdrm,by="ctyTC")
rs_all_AR<-left_join(rs_all_AR,shmfm,by="ctyTC")
rs_all_AR<-left_join(rs_all_AR,shdmm,by="ctyTC")

rs_all_AR$sim.range<-"Undefined"
for (b in 1:150000) { # this takes a while, about an hour and ten, but it seems to work. it actually contains errors in the calculation of sim.range. think i fixed the errors, now takes ~3.5 hours
# for (b in c(1:15,9900,9934)) {
  print(b)
  w<-which(rs_all_AR$Building==b)
  #ren_hist<-sort(unique(unlist(rs_all_AR[w,22:25]))) # make sure these columns are correct
  #ren_hist[ren_hist==0]<-2020
  for (sr in 1:(length(w)-1)) {
  # rs_all_AR$sim.range[w[sr]]<-paste(ceiling(ren_hist[sr]/5)*5,floor((ren_hist[sr+1]-1)/5)*5,sep = ".")
    rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],rs_all_AR[w[sr+1],"Year"]-5,sep = ".")
  }
  for (sr in length(w)) {
    # rs_all_AR$sim.range[w[sr]]<-paste(ceiling(ren_hist[sr]/5)*5,"2060",sep = ".")
    rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],"2060",sep = ".")
  }
  # create concordance matrix to identify which weighting factors should be zero and non-zero
  conc<-matrix(rep(0,9*length(w)),length(w),9)
  for (c in 1:length(w)) {
    conc[c, which(names(rs_all_AR[28:36])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],1,4),sep="_")):
           which(names(rs_all_AR[28:36])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],6,9),sep="_"))]<-1
  }
  rs_all_AR[w,28:36]<-rs_all_AR[w,28:36]*conc
  rs_all_AR[w,37:45]<-rs_all_AR[w,37:45]*conc
  rs_all_AR[w,46:54]<-rs_all_AR[w,46:54]*conc
  rs_all_AR[w,55:63]<-rs_all_AR[w,55:63]*conc
  
}
rs_all_ARyay<-rs_all_AR
save(rs_all_ARyay,file="updatedRenAdvanced.RData")
# add GHG intensities, Mid-Case
rs_all_AR<-left_join(rs_all_AR,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_all_AR<-left_join(rs_all_AR,gic_LRE,by = c("County" = "RS_ID"))

# recalculate energy with the energy models
rs_all_AR$Elec_MJ_new<-rs_all_AR$Elec_MJ
rs_all_AR$NaturalGas_MJ_new<-rs_all_AR$NaturalGas_MJ
rs_all_AR$Propane_MJ_new<-rs_all_AR$Propane_MJ
rs_all_AR$FuelOil_MJ_new<-rs_all_AR$FuelOil_MJ
h<-which(rs_all_AR$change_hren>0)
# this shouldn't need to be done
rs_all_AR$HVAC.Cooling.Type.LM<-rs_all_AR$HVAC.Cooling.Type
rs_all_AR[rs_all_AR$HVAC.Cooling.Type=="Heat Pump",]$HVAC.Cooling.Type.LM<-"Central AC"

rs_all_AR$Elec_MJ_new[h]<-round(predict(lmEL2,data.frame(Type=rs_all_AR$Geometry.Building.Type.RECS[h],Vintage=rs_all_AR$Vintage.LM[h],IECC_Climate_Pub=rs_all_AR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_AR$Geometry.Floor.Area[h], HeatFuel=rs_all_AR$Heating.Fuel[h],
                                                  ACType=rs_all_AR$HVAC.Cooling.Type.LM[h],WaterHeatFuel=rs_all_AR$Water.Heater.Fuel[h], DryerFuel=rs_all_AR$Clothes.Dryer.Fuel.LM[h])))
rs_all_AR$NaturalGas_MJ_new[h]<-round(predict(lmNG2,data.frame(Type=rs_all_AR$Geometry.Building.Type.RECS[h],Vintage=rs_all_AR$Vintage.LM[h],IECC_Climate_Pub=rs_all_AR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_AR$Geometry.Floor.Area[h], HeatFuel=rs_all_AR$Heating.Fuel[h],
                                                        WaterHeatFuel=rs_all_AR$Water.Heater.Fuel[h], DryerFuel=rs_all_AR$Clothes.Dryer.Fuel.LM[h])))
rs_all_AR$Propane_MJ_new[h]<-round(predict(lmPr2,data.frame(Type=rs_all_AR$Geometry.Building.Type.RECS[h],Vintage=rs_all_AR$Vintage.LM[h],IECC_Climate_Pub=rs_all_AR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_AR$Geometry.Floor.Area[h], HeatFuel=rs_all_AR$Heating.Fuel[h],
                                                     WaterHeatFuel=rs_all_AR$Water.Heater.Fuel[h], DryerFuel=rs_all_AR$Clothes.Dryer.Fuel.LM[h])))
rs_all_AR$FuelOil_MJ_new[h]<-round(predict(lmFO2,data.frame(Type=rs_all_AR$Geometry.Building.Type.RECS[h],Vintage=rs_all_AR$Vintage.LM[h],IECC_Climate_Pub=rs_all_AR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_AR$Geometry.Floor.Area[h], HeatFuel=rs_all_AR$Heating.Fuel[h],
                                                     WaterHeatFuel=rs_all_AR$Water.Heater.Fuel[h])))
rs_all_AR[!rs_all_AR$Heating.Fuel=="Fuel Oil" & !rs_all_AR$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ<-0 # turn oil to 0 if neither water or space heater is oil

rs_all_AR[rs_all_AR$Elec_MJ_new<0,]$Elec_MJ_new<-0
rs_all_AR[rs_all_AR$NaturalGas_MJ_new<0,]$NaturalGas_MJ_new<-0
rs_all_AR[rs_all_AR$Propane_MJ_new<0,]$Propane_MJ_new<-0
rs_all_AR[rs_all_AR$FuelOil_MJ_new<0,]$FuelOil_MJ_new<-0
# renovation modifications, updated Feb 7 consistent with the two renovation files
rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]$Elec_MJ_new<-
  round(0.9*rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]$Elec_MJ_new) # if a heating system involved upgrading to a (more efficient) heat pump, reduce electricity consumption by 8%

rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.93*rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to a new gas heating system
rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$Heating.Fuel=="Propane",]$Propane_MJ_new<-round(0.93*rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$Heating.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to a new propane heating system
rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.86*rs_all_AR[rs_all_AR$change_hren>0&rs_all_AR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to a new FO heating system

rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Electricity",]$Elec_MJ_new<-round(0.95*rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Electricity",]$Elec_MJ_new) # reduction from upgrade to new elec water heating system
rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.93*rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to new gas water heating system
rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Propane",]$Propane_MJ_new<-round(0.93*rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to new prop water heating system
rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.95*rs_all_AR[rs_all_AR$change_wren>0&rs_all_AR$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to new FO water heating system

rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Electricity",]$Elec_MJ_new<-round(0.96*rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Electricity",]$Elec_MJ_new) # reduction from upgrade to insulation
rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.85*rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to insulation
rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Propane",]$Propane_MJ_new<-round(0.85*rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to insulation
rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.8*rs_all_AR[rs_all_AR$change_iren>0&rs_all_AR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to insulation

# calculation total energy and GHG
rs_all_AR[,c("Total_Energy_2020",  "Total_Energy_2025","Total_Energy_2030","Total_Energy_2035","Total_Energy_2040","Total_Energy_2045","Total_Energy_2050","Total_Energy_2055","Total_Energy_2060")]<-
  (rs_all_AR$base_weight*rs_all_AR[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_all_AR$Elec_MJ_new+rs_all_AR$NaturalGas_MJ_new+rs_all_AR$Propane_MJ_new+rs_all_AR$FuelOil_MJ_new)
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

rs_all_AR[,c("EnGHG_2020","EnGHG_2025","EnGHG_2030","EnGHG_2035","EnGHG_2040","EnGHG_2045","EnGHG_2050","EnGHG_2055","EnGHG_2060")]<-
  (rs_all_AR$base_weight*rs_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_all_AR$Elec_MJ_new*rs_all_AR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_all_AR$NaturalGas_MJ_new*GHGI_NG,9),nrow(rs_all_AR),9)+ matrix(rep(rs_all_AR$FuelOil_MJ_new*GHGI_FO,9),nrow(rs_all_AR),9)+ matrix(rep(rs_all_AR$Propane_MJ_new*GHGI_LP,9),nrow(rs_all_AR),9))
# first save this modified dataframe, it took a lot of computation to produce
save(rs_all_AR,file = "RenAdvanced_EG.RData")
# now prepare to combine the <2020 renovated and NC dataframes, for the baseline scenario with advanced renovation
bs_base_all<-rs_all_AR
bs_base_all[,c("Elec_MJ","NaturalGas_MJ","FuelOil_MJ","Propane_MJ")]<-bs_base_all[,c("Elec_MJ_new","NaturalGas_MJ_new","FuelOil_MJ_new","Propane_MJ_new")]
n1<-names(bs_base_all)
n2<-names(bs_base_NC)
bdiff<-bs_base_all[,!n1 %in% n2]

bs_base_NC[,c("GHG_int_2020","wbase_2020","Total_Energy_2020","EnGHG_2020")]<-0
# i shouldn't have taken out building
bs_base_NC$Building<-as.numeric(substr(bs_base_NC$Year_Building,7,nchar(as.character(bs_base_NC$Year_Building))))
bs_base_NC$sim.range<-"Undefined"

bs_base_NC<-left_join(bs_base_NC,gic_LRE,by = c("County" = "RS_ID"))

bs_base_all<-bind_rows(bs_base_all,bs_base_NC)

bs_base_all<-bs_base_all[,names(bs_base_all) %in% names(bs_base_NC)]

# example of calculating national level emissions in each year for some reason they seem larger than what I calculate currently for Fig 2
# they are larger than the energy related emissions in tm_ee
# colSums(bs_base_all[,48:56])*1e-9
colSums(bs_base_all[,57:65])*1e-9 # now they look correct
# example of calculation state level emissions in one year
tapply(bs_base_all$EnGHG_2020,bs_base_all$State,sum)*1e-9
save(bs_base_all,file="Baseline_AR_EG.RData")

# repeat the process for creating Baseline_AR_EG for RR

rs_all_RR$TC<-"MF"
rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all_RR$TC<-paste(rs_all_RR$TC,rs_all_RR$Vintage.ACS,sep="_")
rs_all_RR$ctyTC<-paste(rs_all_RR$County,rs_all_RR$TC,sep = "")
rs_all_RR$ctyTC<-gsub("2010s","2010-19",rs_all_RR$ctyTC)

# at this stage we are at 27 columns
# now add 9 columns for each stock scenario to bring us to 63
rs_all_RR<-left_join(rs_all_RR,sbm,by="ctyTC")
rs_all_RR<-left_join(rs_all_RR,shdrm,by="ctyTC")
rs_all_RR<-left_join(rs_all_RR,shmfm,by="ctyTC")
rs_all_RR<-left_join(rs_all_RR,shdmm,by="ctyTC")

rs_all_RR$sim.range<-"Undefined"
for (b in 1:150000) { # this takes a while, about an hour and ten, but it seems to work. it actually contains errors in the calculation of sim.range. think i fixed the errors, now takes ~3.5 hours
  # for (b in c(1:15,9900,9934)) {
  print(b)
  w<-which(rs_all_RR$Building==b)
  #ren_hist<-sort(unique(unlist(rs_all_RR[w,22:25]))) # make sure these columns are correct
  #ren_hist[ren_hist==0]<-2020
  for (sr in 1:(length(w)-1)) {
    # rs_all_RR$sim.range[w[sr]]<-paste(ceiling(ren_hist[sr]/5)*5,floor((ren_hist[sr+1]-1)/5)*5,sep = ".")
    rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],rs_all_RR[w[sr+1],"Year"]-5,sep = ".")
  }
  for (sr in length(w)) {
    # rs_all_RR$sim.range[w[sr]]<-paste(ceiling(ren_hist[sr]/5)*5,"2060",sep = ".")
    rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],"2060",sep = ".")
  }
  # create concordance matrix to identify which weighting factors should be zero and non-zero
  conc<-matrix(rep(0,9*length(w)),length(w),9)
  for (c in 1:length(w)) {
    conc[c, which(names(rs_all_RR[28:36])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],1,4),sep="_")):
           which(names(rs_all_RR[28:36])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],6,9),sep="_"))]<-1
  }
  rs_all_RR[w,28:36]<-rs_all_RR[w,28:36]*conc
  rs_all_RR[w,37:45]<-rs_all_RR[w,37:45]*conc
  rs_all_RR[w,46:54]<-rs_all_RR[w,46:54]*conc
  rs_all_RR[w,55:63]<-rs_all_RR[w,55:63]*conc
  
}
rs_all_RRyay<-rs_all_RR
save(rs_all_RRyay,file="updatedRenStandard.RData")
# add GHG intensities, Mid-Case
rs_all_RR<-left_join(rs_all_RR,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_all_RR<-left_join(rs_all_RR,gic_LRE,by = c("County" = "RS_ID"))

# recalculate energy with the energy models
rs_all_RR$Elec_MJ_new<-rs_all_RR$Elec_MJ
rs_all_RR$NaturalGas_MJ_new<-rs_all_RR$NaturalGas_MJ
rs_all_RR$Propane_MJ_new<-rs_all_RR$Propane_MJ
rs_all_RR$FuelOil_MJ_new<-rs_all_RR$FuelOil_MJ
h<-which(rs_all_RR$change_hren>0)
# this shouldn't need to be done
# rs_all_RR$HVAC.Cooling.Type.LM<-rs_all_RR$HVAC.Cooling.Type
# rs_all_RR[rs_all_RR$HVAC.Cooling.Type=="Heat Pump",]$HVAC.Cooling.Type.LM<-"Central AC"

rs_all_RR$Elec_MJ_new[h]<-round(predict(lmEL2,data.frame(Type=rs_all_RR$Geometry.Building.Type.RECS[h],Vintage=rs_all_RR$Vintage.LM[h],IECC_Climate_Pub=rs_all_RR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_RR$Geometry.Floor.Area[h], HeatFuel=rs_all_RR$Heating.Fuel[h],
                                                         ACType=rs_all_RR$HVAC.Cooling.Type.LM[h],WaterHeatFuel=rs_all_RR$Water.Heater.Fuel[h], DryerFuel=rs_all_RR$Clothes.Dryer.Fuel.LM[h])))
rs_all_RR$NaturalGas_MJ_new[h]<-round(predict(lmNG2,data.frame(Type=rs_all_RR$Geometry.Building.Type.RECS[h],Vintage=rs_all_RR$Vintage.LM[h],IECC_Climate_Pub=rs_all_RR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_RR$Geometry.Floor.Area[h], HeatFuel=rs_all_RR$Heating.Fuel[h],
                                                               WaterHeatFuel=rs_all_RR$Water.Heater.Fuel[h], DryerFuel=rs_all_RR$Clothes.Dryer.Fuel.LM[h])))
rs_all_RR$Propane_MJ_new[h]<-round(predict(lmPr2,data.frame(Type=rs_all_RR$Geometry.Building.Type.RECS[h],Vintage=rs_all_RR$Vintage.LM[h],IECC_Climate_Pub=rs_all_RR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_RR$Geometry.Floor.Area[h], HeatFuel=rs_all_RR$Heating.Fuel[h],
                                                            WaterHeatFuel=rs_all_RR$Water.Heater.Fuel[h], DryerFuel=rs_all_RR$Clothes.Dryer.Fuel.LM[h])))
rs_all_RR$FuelOil_MJ_new[h]<-round(predict(lmFO2,data.frame(Type=rs_all_RR$Geometry.Building.Type.RECS[h],Vintage=rs_all_RR$Vintage.LM[h],IECC_Climate_Pub=rs_all_RR$ASHRAE.IECC.Climate.Zone.LM[h],FloorArea=rs_all_RR$Geometry.Floor.Area[h], HeatFuel=rs_all_RR$Heating.Fuel[h],
                                                            WaterHeatFuel=rs_all_RR$Water.Heater.Fuel[h])))
rs_all_RR[!rs_all_RR$Heating.Fuel=="Fuel Oil" & !rs_all_RR$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ<-0 # turn oil to 0 if neither water or space heater is oil

rs_all_RR[rs_all_RR$Elec_MJ_new<0,]$Elec_MJ_new<-0
rs_all_RR[rs_all_RR$NaturalGas_MJ_new<0,]$NaturalGas_MJ_new<-0
rs_all_RR[rs_all_RR$Propane_MJ_new<0,]$Propane_MJ_new<-0
rs_all_RR[rs_all_RR$FuelOil_MJ_new<0,]$FuelOil_MJ_new<-0
# renovation modifications
rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]$Elec_MJ_new<-
  round(0.92*rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]$Elec_MJ_new) # if a heating system involved upgrading to a (more efficient) heat pump, reduce electricity consumption by 8%

rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.95*rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to a new gas heating system
rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$Heating.Fuel=="Propane",]$Propane_MJ_new<-round(0.95*rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$Heating.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to a new propane heating system
rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.88*rs_all_RR[rs_all_RR$change_hren>0&rs_all_RR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to a new FO heating system

rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Electricity",]$Elec_MJ_new<-round(0.98*rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Electricity",]$Elec_MJ_new) # reduction from upgrade to new elec water heating system
rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.95*rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to new gas water heating system
rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Propane",]$Propane_MJ_new<-round(0.95*rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to new prop water heating system
rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.98*rs_all_RR[rs_all_RR$change_wren>0&rs_all_RR$Water.Heater.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to new FO water heating system

rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Electricity",]$Elec_MJ_new<-round(0.98*rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Electricity",]$Elec_MJ_new) # reduction from upgrade to insulation
rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new<-round(0.88*rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Natural Gas",]$NaturalGas_MJ_new) # reduction from upgrade to insulation
rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Propane",]$Propane_MJ_new<-round(0.88*rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Propane",]$Propane_MJ_new) # reduction from upgrade to insulation
rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new<-round(0.83*rs_all_RR[rs_all_RR$change_iren>0&rs_all_RR$Heating.Fuel=="Fuel Oil",]$FuelOil_MJ_new) # reduction from upgrade to insulation

# calculation total energy and GHG
rs_all_RR[,c("Total_Energy_2020",  "Total_Energy_2025","Total_Energy_2030","Total_Energy_2035","Total_Energy_2040","Total_Energy_2045","Total_Energy_2050","Total_Energy_2055","Total_Energy_2060")]<-
  (rs_all_RR$base_weight*rs_all_RR[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_all_RR$Elec_MJ_new+rs_all_RR$NaturalGas_MJ_new+rs_all_RR$Propane_MJ_new+rs_all_RR$FuelOil_MJ_new)
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

rs_all_RR[,c("EnGHG_2020","EnGHG_2025","EnGHG_2030","EnGHG_2035","EnGHG_2040","EnGHG_2045","EnGHG_2050","EnGHG_2055","EnGHG_2060")]<-
  (rs_all_RR$base_weight*rs_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_all_RR$Elec_MJ_new*rs_all_RR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_all_RR$NaturalGas_MJ_new*GHGI_NG,9),nrow(rs_all_RR),9)+ matrix(rep(rs_all_RR$FuelOil_MJ_new*GHGI_FO,9),nrow(rs_all_RR),9)+ matrix(rep(rs_all_RR$Propane_MJ_new*GHGI_LP,9),nrow(rs_all_RR),9))
# first save this modified dataframe, it took a lot of computation to produce
save(rs_all_RR,file = "RenStandard_EG.RData")
# now prepare to combine the <2020 renovated and NC dataframes, for the baseline scenario with advanced renovation
bs_base_all_RR<-rs_all_RR
bs_base_all_RR[,c("Elec_MJ","NaturalGas_MJ","FuelOil_MJ","Propane_MJ")]<-bs_base_all_RR[,c("Elec_MJ_new","NaturalGas_MJ_new","FuelOil_MJ_new","Propane_MJ_new")]
n1<-names(bs_base_all_RR)
n2<-names(bs_base_NC)
bdiff<-bs_base_all_RR[,!n1 %in% n2]

bs_base_NC[,c("GHG_int_2020","wbase_2020","Total_Energy_2020","EnGHG_2020")]<-0
# i shouldn't have taken out building
bs_base_NC$Building<-as.numeric(substr(bs_base_NC$Year_Building,7,nchar(as.character(bs_base_NC$Year_Building))))
bs_base_NC$sim.range<-"Undefined"

bs_base_NC<-left_join(bs_base_NC,gic_LRE,by = c("County" = "RS_ID"))

bs_base_all_RR<-bind_rows(bs_base_all_RR,bs_base_NC)

bs_base_all_RR<-bs_base_all_RR[,names(bs_base_all_RR) %in% names(bs_base_NC)]

# example of calculating national level emissions in each year for some reason they seem larger than what I calculate currently for Fig 2
# they are larger than the energy related emissions in tm_ee
# colSums(bs_base_all[,48:56])*1e-9
colSums(bs_base_all_RR[,56:64])*1e-9 # now they look correct
# example of calculation state level emissions in one year
tapply(bs_base_all_RR$EnGHG_2020,bs_base_all_RR$State,sum)*1e-9
save(bs_base_all_RR,file="Baseline_RR_EG.RData")


# # try to debug and see why energy related emissions are higher in bs_base_all than in the baseline emissions calculated in 'tot_ee' above
# # first I extract results for 2020. this removes sources of change from electricity factors, or characteristics of new housing.
# # i will compare against total energy emissions by fuel type in 2020
# bs_base_all$ElGHG_2020<-bs_base_all$Elec_MJ*bs_base_all$base_weight*bs_base_all$wbase_2020*bs_base_all$GHG_int_2020
# # this is the problem, the sum of adjusted base weights in 2020 is 136.6 million, too high by about 11.5%
# sum(bs_base_all$base_weight*bs_base_all$wbase_2020)/122500000
# 
# # sum houses by vintage
# tapply(bs_base_all$base_weight*bs_base_all$wbase_2020,bs_base_all$Vintage,sum)*1e-6
# # it's too large in the renovation data frame.
# tapply(rs_all_AR$base_weight*rs_all_AR$wbase_2020,rs_all_AR$Vintage,sum)*1e-6
# 
# 
# length(unique(rs_all_AR$Building)) # this is 150,000 as it should be
# sum(rs_all_AR$wbase_2020) # but this is 167,213, too high by 17,213, or 11%
# 
# bb<-rs_all_AR[,c("Year_Building", "Building","wbase_2020")]

# can pick out columns of interest and melt years to calculate combinations desired using tapply
# for (yr in c(seq(2025,2060,5))) {
#   rs_all_AR[rs_all_AR$Year==yr, ]
# }
# 
# for (r in 1:nrow(rs_all_AR)))) {
#   yr<-rs_all_AR$Year[r]
#   
# # add weight adjustments for all stock scenarios
#   
#     sbmy<-sbm[,c("ctyTC",paste("wbase",yr,sep="_"))]
#     dd<-left_join(dd,sbmy,by="ctyTC")
# 
# 
# rs_all_AR$TC<-"MF"
# rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
# rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
# rs_all_AR$TC<-paste(rs_all_AR$TC,rs_all_AR$Vintage.ACS,sep="_")
# rs_all_AR$ctyTC<-paste(rs_all_AR$County,rs_all_AR$TC,sep = "")
# rs_all_AR$ctyTC<-gsub("2010s","2010-19",rs_all_AR$ctyTC)

#add columns for adjusted weights
# rs_all_AR<-left_join(rs_all_AR,sbm,by="ctyTC")
# rs_all_AR<-left_join(rs_all_AR,shdrm,by="ctyTC")
# rs_all_AR<-left_join(rs_all_AR,shmfm,by="ctyTC")
# rs_all_AR<-left_join(rs_all_AR,shdmm,by="ctyTC")
load("updatedRenAdvanced.RData")
rs<-rs_all_ARyay
table(rs$Year)

tapply(rs$base_weight*rs$wbase_2020,rs$Heating.Fuel,sum)
# load("Baseline_RR_EG.RData")
# rs<-bs_base_all_RR
load("Baseline_AR_EG.RData")
rs<-bs_base_all # adv ren
# rs<-rs[,-c(22:25,64)]
rs<-rs[,c(1:27,65:70)]
rs<-rs[,c(1:28)] # adv ren
# new lines added to enabling summing up characteritsics over the whole stock and time perion with one tapply function
rsm<-melt(rs,id.vars = names(rs)[-c(19:27)])
rsm<-melt(rs,id.vars = names(rs)[-c(20:28)]) # adv ren
names(rsm)[2]<-"Sample.Year"
rsm$Sim.Year<-substr(rsm$variable,nchar(as.character(rsm$variable))-3,nchar(as.character(rsm$variable)))
rsm$Stock.Scenario<-substr(rsm$variable,2,nchar(as.character(rsm$variable))-5)
rsm<-rsm[,-25] # remove the 'wbase_year' column, now summarized in two other new colums
names(rsm)[25]<-"w_adj"

rsm<-rsm[,-20] # remove the 'wbase_year' column, now summarized in two other new colums, adv ren
names(rsm)[20]<-"w_adj"

# rsmb<-rsm[rsm$Stock.Scenario=="base",]
tapply(rsm$base_weight*rsm$w_adj,rsm$Sim.Year,sum)
hf<-as.data.frame(tapply(rsm$base_weight*rsm$w_adj,list(rsm$Sim.Year,rsm$Heating.Fuel),sum))
hf$Year<-rownames(hf)
hfm<-melt(hf,id.vars = "Year")
names(hfm)[2:3]<-c("HeatFuel","Count")
windows()
ggplot(hfm,aes(x=Year,y=1e-6*Count,fill=HeatFuel))+geom_bar(stat="identity") +  theme_bw() + scale_fill_brewer(palette="Dark2") + 
  labs(title = "Occupied housing by main heat fuel", y = "Million Housing Units",subtitle = "Baseline, Advanced Renovation") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))
# heat fuel and heating system type
htf<-as.data.frame(tapply(rsm$base_weight*rsm$w_adj,list(rsm$Sim.Year,rsm$HVAC.Heating.Type.And.Fuel),sum))
htf$Year<-rownames(htf)
names(htf)[which(names(htf) %in% c("None None","Other Fuel Shared Heating","Void"))]<-"Other/None"
htfm<-melt(htf,id.vars = "Year")
names(htfm)[2:3]<-c("HeatFuelType","Count")
# cols<-colorRampPalette(brewer.pal(8,"Dark2"))(length(unique(htfm$HeatFuelType)))
cols<-colorRampPalette(brewer.pal(9,"Set1"))(length(unique(htfm$HeatFuelType)))
windows()
ggplot(htfm,aes(x=Year,y=1e-6*Count,fill=HeatFuelType))+geom_bar(stat="identity") +  theme_bw() + scale_fill_manual(values = cols) +# scale_fill_brewer(palette="Dark2") + 
  labs(title = "New Housing Construction by Space Heating Fuel and Technology", y = "Million Housing Units",subtitle = "Baseline") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"))
