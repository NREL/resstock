library(MASS)
library(ggplot2)
library(ggfortify)
library(leaps)
library(reshape2)
library(plyr)

# recs vintage + heatingfuel + bedrooms + rooms ~ totsqft
df = read.csv('../../recs/MLR/recs.csv')
df = subset(df, select=c('yearmaderange', 'fuelheat', 'bedrooms', 'totrooms', 'tothsqft', 'totcsqft', 'nweight'))
df = transform(df, totsqft=pmax(tothsqft, totcsqft))
df = df[df$totsqft > 0, ]
levels(df$yearmaderange) = c(levels(df$yearmaderange), '<1950')
df[df$yearmaderange=='1950-pre', 'yearmaderange'] = '<1950'
df$yearmaderange = as.factor(df$yearmaderange)
df$bedrooms = as.factor(df$bedrooms)
df$totrooms = as.factor(df$totrooms)
df = rename(df, c('yearmaderange'='vintage', 'totrooms'='rooms', 'fuelheat'='heatingfuel'))
attach(df)
df.lm0 = lm(totsqft ~ vintage + heatingfuel + bedrooms + rooms, weights=nweight, data=df, x=T)
detach(df)
summary(df.lm0)

# state = 'CA'
state = 'all'

x.vars.con = c()

y.vars.con = c('hhincome')

x.vars.cat = c('vintage', 'size')

y.vars.cat = c()

df = read.csv('pums.csv')
df[df$rooms==1, 'rooms'] = 2 # change all pums rooms=1 to rooms=2 since recs doesn't have totrooms=1
df$bedrooms = as.factor(df$bedrooms)
df$rooms = as.factor(df$rooms)
df$totsqft = predict(df.lm0, newdata=df)
df[df$totsqft < 1500, 'size'] = '0-1499'
df[df$totsqft >= 1500 & df$totsqft < 2500, 'size'] = '1500-2499'
df[df$totsqft >= 2500 & df$totsqft < 3500, 'size'] = '2500-3499'
df[df$totsqft >= 3500, 'size'] = '3500+'
df$size = as.factor(df$size)

write.csv(df, 'pums_size.csv', row.names=F)

# filters
df = df[df$hhincome>=0, ]
df = df[df$nfams==1, ]

if (state != 'all'){
  df = df[df$state_abbr==state, ]
}

df = subset(df, select=c(x.vars.con, y.vars.con, x.vars.cat, y.vars.cat, c('hhwt', 'state_abbr')))

df$values = 'actual'

df[c(x.vars.cat, y.vars.cat)] = lapply(df[c(x.vars.cat, y.vars.cat)], factor) # apply factor to each of the categorical vars
df = na.omit(df) # this removes rows with at least one NA

dep_vars = c(y.vars.con, y.vars.cat)
indep_vars = c(x.vars.con, x.vars.cat)

# FIRST PASS
attach(df)
df.lm1 = lm(paste(dep_vars, paste(indep_vars, collapse=' + '), sep=' ~ '), weights=hhwt, data=df, x=T)
detach(df)
summary(df.lm1)
write.csv(summary(df.lm1)$coefficients, 'lm1.csv') # write out first pass to csv
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
df.lm2 = lm(paste(dep_vars, paste(sig_indep_vars, collapse=' + '), sep=' ~ '), weights=hhwt, data=df, x=T)
detach(df)
summary(df.lm2)
write.csv(summary(df.lm2)$coefficients, 'lm2.csv') # write out first pass to csv
###

df2 = df
df2$values = 'predict'
df2[[y.vars.con[[1]]]] = predict(df.lm2, newdata=subset(df2, select=sig_indep_vars)) # this is the same as the fitted values

counts = c(sum(df$hhwt), sum(df2$hhwt))
labels = paste(c('actual', 'predict'), ', n = ', round(counts), sep='')

p = ggplot(NULL, aes_string(x=y.vars.con[[1]], colour='values')) + geom_density(data=df2) + geom_density(data=df) + scale_colour_discrete(name='model', labels=labels)
ggsave(p, file='dist.png', width=14)

p = autoplot(df.lm2, label.size=3)
ggsave(p, file='stat.png', width=14)

for (x in sig_indep_vars) {
  
  lvls = levels(as.factor(df2[[x]]))
  counts = aggregate(df2$hhwt, by=list(bin=df2[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  p = ggplot(df2, aes_string(x=y.vars.con[[1]])) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels)
  ggsave(p, file=paste(x,'png',sep='_pre.'), width=14)
  
  lvls = levels(as.factor(df[[x]]))
  counts = aggregate(df$hhwt, by=list(bin=df[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(df, aes_string(x=y.vars.con[[1]])) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels)
  ggsave(q, file=paste(x,'png',sep='_act.'), width=14)
  
}

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
  counts = aggregate(temp2$hhwt, by=list(bin=temp2$size_and_vintage), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  p = ggplot(temp2, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=size_and_vintage)) + scale_colour_discrete(name='size_and_vintage', labels=labels)
  ggsave(p, file=paste(gsub('<', '', vintage),'png',sep='_pre.'), width=14)
  
  lvls = levels(as.factor(temp$size_and_vintage))
  counts = aggregate(temp$hhwt, by=list(bin=temp$size_and_vintage), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(temp, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=size_and_vintage)) + scale_colour_discrete(name='size_and_vintage', labels=labels)
  ggsave(q, file=paste(gsub('<', '', vintage),'png',sep='_act.'), width=14)
  
}

# if (state == 'all'){
  
  # lvls = levels(as.factor(df2$state_abbr))
  # counts = aggregate(df2$hhwt, by=list(bin=df2$state_abbr), FUN=sum)$x
  # labels = paste(lvls, ', n = ', round(counts), sep='')
  
  # p = ggplot(df2, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=state_abbr)) + scale_colour_discrete(name='state_abbr', labels=labels)
  # ggsave(p, file='state_pre.png', width=14)
  
  # lvls = levels(as.factor(df$state_abbr))
  # counts = aggregate(df$hhwt, by=list(bin=df$state_abbr), FUN=sum)$x
  # labels = paste(lvls, ', n = ', round(counts), sep='')
  
  # q = ggplot(df, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=state_abbr)) + scale_colour_discrete(name='state_abbr', labels=labels)
  # ggsave(q, file='state_act.png', width=14)
  
# }
