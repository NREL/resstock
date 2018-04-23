library(MASS)
library(ggplot2)
library(ggfortify)
library(leaps)
library(reshape2)
library(plyr)

x.vars.con = c('temphome', 'temphomeac', 'nhsldmem')

y.vars.con = c('rand_income')

x.vars.cat = c('vintage', 'size', 'reportable_domain', 'equipm', 'fuelheat', 'equipage', 'cooltype', 'agecenac', 'typeglass')
# x.vars.cat = c('vintage') # 0.039
# x.vars.cat = c('size') # 0.150
# x.vars.cat = c('reportable_domain') # 0.044
# x.vars.cat = c('equipm') # 0.040
# x.vars.cat = c('fuelheat') # 0.009
# x.vars.cat = c('equipage') # 0.008
# x.vars.cat = c('temphome') # 0.040
# x.vars.cat = c('cooltype') # 0.023
# x.vars.cat = c('agecenac') # 0.026
# x.vars.cat = c('temphomeac') # 0.020
# x.vars.cat = c('typeglass') # 0.045
# x.vars.cat = c('nhsldmem') # 0.080

y.vars.cat = c()

dep_vars = c(y.vars.con, y.vars.cat)
indep_vars = c(x.vars.con, x.vars.cat)

df = read.csv('recs.csv')

# filters
df[df==-2] = NA

levels(df$yearmaderange) = c(levels(df$yearmaderange), '<1950')
df[df$yearmaderange=='1950-pre', 'yearmaderange'] = '<1950'
df$yearmaderange = as.factor(df$yearmaderange)
df = rename(df, c('yearmaderange'='vintage', 'Size'='size'))
df = subset(df, select=c(x.vars.con, y.vars.con, x.vars.cat, y.vars.cat, c('nweight')))

df$values = 'actual'

df[c(x.vars.cat, y.vars.cat)] = lapply(df[c(x.vars.cat, y.vars.cat)], factor) # apply factor to each of the categorical vars
df = na.omit(df) # this removes rows with at least one NA

# change the reference factors
df$vintage = relevel(df$vintage, ref='1960s')
df$reportable_domain = relevel(df$reportable_domain, ref='15')
# df$temphome = relevel(df$temphome, ref='50')
# df$temphomeac = relevel(df$temphomeac, ref='63')
df$equipm = relevel(df$equipm, ref='Floor or Wall Pipeless Furnace')
df$fuelheat = relevel(df$fuelheat, ref='Other Fuel')
df$equipage = relevel(df$equipage, ref='15-19 yrs')
df$agecenac = relevel(df$agecenac, ref='20+ yrs')
# df$nhsldmem = relevel(df$nhsldmem, ref='10')

# FIRST PASS
attach(df)
df.lm1 = lm(paste(dep_vars, paste(indep_vars, collapse=' + '), sep=' ~ '), weights=nweight, data=df, x=T)
detach(df)
summary(df.lm1)
table = as.data.frame.matrix(summary(df.lm1)$coefficients)
table = table[order(table[['Pr(>|t|)']]), ]
table[['Pr(>|t|)']] = formatC(table[['Pr(>|t|)']], format='e', digits=5)
table[['Estimate']] = round(table[['Estimate']], 5)
table[['Std. Error']] = round(table[['Std. Error']], 5)
table[['t value']] = round(table[['t value']], 5)
write.csv(table, 'lm1.csv') # write out first pass to csv
write.csv(data.frame("R^2"=summary(df.lm1)$r.squared[1], "Adj-R^2"=summary(df.lm1)$adj.r.squared[1]), "stat1.csv", row.names=F)
###

sig_indep_vars_factors = rownames(data.frame(summary(df.lm1)$coefficients)[data.frame(summary(df.lm1)$coefficients)$'Pr...t..' <= 0.05, ]) # remove insignificant vars
sig_indep_vars_factors = sig_indep_vars_factors[!sig_indep_vars_factors %in% c('(Intercept)')]
sig_indep_vars = c()
for (x in indep_vars) {
  for (y in sig_indep_vars_factors) {
    if (grepl(x, y)) {
      if (!(x %in% sig_indep_vars)) {
        sig_indep_vars = c(sig_indep_vars, x)
      }
    }
  }
}

# SECOND PASS
attach(df)
df.lm2 = lm(paste(dep_vars, paste(sig_indep_vars, collapse=' + '), sep=' ~ '), weights=nweight, data=df, x=T)
detach(df)
summary(df.lm2)
table = as.data.frame.matrix(summary(df.lm2)$coefficients)
table = table[order(table[['Pr(>|t|)']]), ]
table[['Pr(>|t|)']] = formatC(table[['Pr(>|t|)']], format='e', digits=5)
table[['Estimate']] = round(table[['Estimate']], 5)
table[['Std. Error']] = round(table[['Std. Error']], 5)
table[['t value']] = round(table[['t value']], 5)
write.csv(table, 'lm2.csv') # write out second pass to csv
write.csv(data.frame("R^2"=summary(df.lm2)$r.squared[1], "Adj-R^2"=summary(df.lm2)$adj.r.squared[1]), "stat2.csv", row.names=F)
###

stop()

df2 = df
df2$values = 'predict'
df2$rand_income = predict(df.lm2, newdata=subset(df2, select=sig_indep_vars)) # this is the same as the fitted values

counts = c(sum(df$nweight), sum(df2$nweight))
labels = paste(c('actual', 'predict'), ', n = ', round(counts), sep='')

p = ggplot(NULL, aes(x=rand_income, colour=values, weight=nweight/sum(nweight))) + geom_density(data=df2) + geom_density(data=df) + scale_colour_discrete(name='model', labels=labels)
ggsave(p, file='dist.png', width=14)

p = autoplot(df.lm2, label.size=3)
ggsave(p, file='stat.png', width=14)

for (x in sig_indep_vars) {

  lvls = levels(as.factor(df2[[x]]))
  counts = aggregate(df2$nweight, by=list(bin=df2[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  p = ggplot(df2, aes(x=rand_income, weight=nweight/sum(nweight))) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels)
  ggsave(p, file=paste(x,'png',sep='_pre.'), width=14)
  
  lvls = levels(as.factor(df[[x]]))
  counts = aggregate(df$nweight, by=list(bin=df[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(df, aes(x=rand_income, weight=nweight/sum(nweight))) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels)
  ggsave(q, file=paste(x,'png',sep='_act.'), width=14)
  
}

# size and vintage
levels(df$vintage) = c('<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s')
sizes_and_vintages = expand.grid(levels(df$size), levels(df$vintage))
sizes_and_vintages = rename(sizes_and_vintages, c('Var1'='size', 'Var2'='vintage'))
sizes_and_vintages$income = predict(df.lm2, newdata=sizes_and_vintages)
write.csv(sizes_and_vintages, 'income_estimates.csv', row.names=F)

for (vintage in levels(as.factor(df$vintage))){

  temp = df[df$vintage==vintage, ]
  temp2 = df2[df2$vintage==vintage, ]
  
  temp$size_and_vintage = paste(temp$size, temp$vintage)
  temp2$size_and_vintage = paste(temp2$size, temp2$vintage)
      
  lvls = levels(as.factor(temp2$size_and_vintage))
  counts = aggregate(temp2$nweight, by=list(bin=temp2$size_and_vintage), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  p = ggplot(temp2, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=size_and_vintage)) + scale_colour_discrete(name='size_and_vintage', labels=labels)
  ggsave(p, file=paste(gsub('<', '', vintage),'png',sep='_pre.'), width=14)
  
  lvls = levels(as.factor(temp$size_and_vintage))
  counts = aggregate(temp$nweight, by=list(bin=temp$size_and_vintage), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(temp, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=size_and_vintage)) + scale_colour_discrete(name='size_and_vintage', labels=labels)
  ggsave(q, file=paste(gsub('<', '', vintage),'png',sep='_act.'), width=14)
  
}