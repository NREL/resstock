library(MASS)
library(ggplot2)
library(ggfortify)
library(leaps)

# x.vars.con = c('yearmade', 'Intsize')
x.vars.con = c()

y.vars.con = c('rand_income')

# x.vars.cat = c('yearmaderange', 'fuelheat', 'Size', 'CR', 'cooltype')
x.vars.cat = c('ur', 'yearmaderange', 'fuelheat', 'Size', 'CR', 'cooltype', 'stories', 'totrooms', 'sizeofgarage', 'kownrent', 'stovefuel', 'ovenfuel', 'outgrillfuel', 'numfrig', 'sizrfri1', 'esfrig', 'agerfri1', 'windows', 'typeglass', 'householder_race', 'education', 'hhage', 'wwacage', 'fuelh2o')
# x.vars.cat = c('fuelheat', 'CR', 'cooltype')
# x.vars.cat = c('equipm')
# x.vars.cat = c('Size')
# x.vars.cat = c('temphome')
# x.vars.cat = c('cooltype')
# x.vars.cat = c('FPL_BINS')
# x.vars.cat = c('fuelheat')
# x.vars.cat = c('education')
# x.vars.cat = c('householder_race')
# x.vars.cat = c('FPL_BINS')

y.vars.cat = c()

dep_vars = c(y.vars.con, y.vars.cat)
indep_vars = c(x.vars.con, x.vars.cat)

df = read.csv('recs.csv')
df = subset(df, select=c(x.vars.con, y.vars.con, x.vars.cat, y.vars.cat, c('nweight')))
df$values = 'actual'
# df$actual = df$rand_income

df[c(x.vars.cat, y.vars.cat)] = lapply(df[c(x.vars.cat, y.vars.cat)], factor) # apply factor to each of the categorical vars
df = na.omit(df) # this removes rows with at least one NA

# FIRST PASS
attach(df)
df.lm1 = lm(paste(dep_vars, paste(indep_vars, collapse=' + '), sep=' ~ '), weights=nweight, data=df, x=T)
detach(df)
summary(df.lm1)
write.csv(summary(df.lm1)$coefficients, 'lm1.csv') # write out first pass to csv
###

# df.lm1.step1 = stepAIC(df.lm1, direction='both') # step-wise regression
# summary(df.lm1.step1)

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
write.csv(summary(df.lm2)$coefficients, 'lm2.csv') # write out first pass to csv
###

# attach(df)
# leaps = regsubsets(rand_income ~ yearmaderange + fuelheat + Size + CR, data=df, nbest=10)
# detach(df)
# png(filename="leaps.png", width=10, height=5, units="in", res=1200)
# par(cex.axis=0.5, cex.lab=0.5)
# plot(leaps, scale='r2')
# dev.off()

df2 = df
df2$values = 'predict'
df2$rand_income = predict(df.lm2, newdata=subset(df2, select=sig_indep_vars)) # this is the same as the fitted values
# df2$actual = df$rand_income

counts = c(sum(df$nweight), sum(df2$nweight))
labels = paste(c('actual', 'predict'), ', n = ', round(counts), sep='')

p = ggplot(NULL, aes(x=rand_income, colour=values, weight=nweight/sum(nweight))) + geom_density(data=df2) + geom_density(data=df) + scale_colour_discrete(name='model', labels=labels) + xlim(0, 250000) + ylim(0, 0.00002)
# binwidth = 1000
# p = ggplot(NULL, aes(x=rand_income, colour=values, weight=nweight/sum(nweight))) + geom_histogram(data=df2, binwidth=binwidth, alpha=0.1) + geom_histogram(data=df, binwidth=binwidth, alpha=0.1) + scale_colour_discrete(name='model', labels=labels) + xlim(0, 250000) + ylim(0, 0.03)
ggsave(p, file='dist.png', width=14)

# p = ggplot(df2) + geom_point(aes(x=actual, y=rand_income), size=0.8, colour="blue") + geom_smooth(data=df2, aes(x=actual, y=rand_income), size=0.8, colour="red", se=T) + xlim(0, 250000)
# ggsave(p, file='conf.png', width=14)

p = autoplot(df.lm2, label.size=3)
ggsave(p, file='stat.png', width=14)

for (x in sig_indep_vars) {

  lvls = levels(as.factor(df2[[x]]))
  counts = aggregate(df2$nweight, by=list(bin=df2[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  p = ggplot(df2, aes(x=rand_income, weight=nweight/sum(nweight))) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels) + xlim(0, 250000) + ylim(0, 0.00002)
  ggsave(p, file=paste(x,'png',sep='_pre.'), width=14)
  
  lvls = levels(as.factor(df[[x]]))
  counts = aggregate(df$nweight, by=list(bin=df[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(df, aes(x=rand_income, weight=nweight/sum(nweight))) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels) + xlim(0, 250000) + ylim(0, 0.00002)
  ggsave(q, file=paste(x,'png',sep='_act.'), width=14)
  
}

# size and vintage

df$size_and_vintage = paste(df$Size, df$yearmaderange)
df2$size_and_vintage = paste(df2$Size, df2$yearmaderange)

x = 'size_and_vintage'

lvls = levels(as.factor(df2[[x]]))
counts = aggregate(df2$nweight, by=list(bin=df2[[x]]), FUN=sum)$x
labels = paste(lvls, ', n = ', round(counts), sep='')

p = ggplot(df2, aes(x=rand_income, weight=nweight/sum(nweight))) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels) + xlim(0, 250000) + ylim(0, 0.00002)
ggsave(p, file=paste(x,'png',sep='_pre.'), width=14)

lvls = levels(as.factor(df[[x]]))
counts = aggregate(df$nweight, by=list(bin=df[[x]]), FUN=sum)$x
labels = paste(lvls, ', n = ', round(counts), sep='')

q = ggplot(df, aes(x=rand_income, weight=nweight/sum(nweight))) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels) + xlim(0, 250000) + ylim(0, 0.00002)
ggsave(q, file=paste(x,'png',sep='_act.'), width=14)