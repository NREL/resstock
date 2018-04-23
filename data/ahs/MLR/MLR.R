library(MASS)
library(ggplot2)
library(ggfortify)
library(leaps)
library(reshape2)
library(plyr)

df = read.csv('ahs.csv', na.strings='')

df = subset(df, select=c('NUNIT2', 'ROOMS', 'BEDRMS', 'size', 'vintage', 'heatingtype', 'heatingfuel', 'actype', 'ZINC2', 'POOR', 'WEIGHT', 'smsa', 'cmsa', 'metro3', 'division', 'location'))
df$NUNIT2 = as.numeric(gsub("'", "", df$NUNIT2))
df = rename(df, c('ZINC2'='income', 'POOR'='fpl'))

x.vars.con = c()

y.vars.con = c('income')
# y.vars.con = c('fpl')

x.vars.cat = c('vintage', 'size', 'heatingtype', 'heatingfuel', 'actype', 'division')
# x.vars.cat = c('vintage', 'size', 'heatingtype', 'heatingfuel', 'actype', 'smsa')
# x.vars.cat = c('vintage') # 0.030
# x.vars.cat = c('size') # 0.105
# x.vars.cat = c('heatingtype') # 0.019
# x.vars.cat = c('heatingfuel') # 0.009
# x.vars.cat = c('actype') # 0.014
# x.vars.cat = c('division') # 0.012
# x.vars.cat = c('smsa') # 0.023

y.vars.cat = c()

df$values = 'actual'

df[c(x.vars.cat, y.vars.cat)] = lapply(df[c(x.vars.cat, y.vars.cat)], factor) # apply factor to each of the categorical vars
df = na.omit(df) # this removes rows with at least one NA
df = df[df$size!='Blank', ]

dep_vars = c(y.vars.con, y.vars.cat)
indep_vars = c(x.vars.con, x.vars.cat)

# change the reference factors
df$vintage = relevel(df$vintage, ref='<1950') # income, division
# df$vintage = relevel(df$vintage, ref='1960s') # income, smsa
df$actype = relevel(df$actype, ref='Room')
df$heatingtype = relevel(df$heatingtype, ref='Cooking stove')
df$division = relevel(df$division, ref='South Atlantic - East South Central')
# df$smsa = relevel(df$smsa, ref='Hartford, CT')

# FIRST PASS
attach(df)
df.lm1 = lm(paste(dep_vars, paste(indep_vars, collapse=' + '), sep=' ~ '), weights=WEIGHT, data=df, x=T)
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
df.lm2 = lm(paste(dep_vars, paste(sig_indep_vars, collapse=' + '), sep=' ~ '), weights=WEIGHT, data=df, x=T)
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
df2[[y.vars.con[[1]]]] = predict(df.lm2, newdata=subset(df2, select=sig_indep_vars)) # this is the same as the fitted values

counts = c(sum(df$WEIGHT), sum(df2$WEIGHT))
labels = paste(c('actual', 'predict'), ', n = ', round(counts), sep='')

p = ggplot(NULL, aes_string(x=y.vars.con[[1]], colour='values')) + geom_density(data=df2) + geom_density(data=df) + scale_colour_discrete(name='model', labels=labels)
ggsave(p, file='dist.png', width=14)

p = autoplot(df.lm2, label.size=3)
ggsave(p, file='stat.png', width=14)

for (x in sig_indep_vars) {
  
  lvls = levels(as.factor(df2[[x]]))
  counts = aggregate(df2$WEIGHT, by=list(bin=df2[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  p = ggplot(df2, aes_string(x=y.vars.con[[1]])) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels)
  ggsave(p, file=paste(x,'png',sep='_pre.'), width=14)
  
  lvls = levels(as.factor(df[[x]]))
  counts = aggregate(df$WEIGHT, by=list(bin=df[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(df, aes_string(x=y.vars.con[[1]])) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels)
  ggsave(q, file=paste(x,'png',sep='_act.'), width=14)
  
}

stop()

# size and vintage
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
  counts = aggregate(temp2$WEIGHT, by=list(bin=temp2$size_and_vintage), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  p = ggplot(temp2, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=size_and_vintage)) + scale_colour_discrete(name='size_and_vintage', labels=labels)
  ggsave(p, file=paste(gsub('<', '', vintage),'png',sep='_pre.'), width=14)
  
  lvls = levels(as.factor(temp$size_and_vintage))
  counts = aggregate(temp$WEIGHT, by=list(bin=temp$size_and_vintage), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(temp, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=size_and_vintage)) + scale_colour_discrete(name='size_and_vintage', labels=labels)
  ggsave(q, file=paste(gsub('<', '', vintage),'png',sep='_act.'), width=14)
  
}