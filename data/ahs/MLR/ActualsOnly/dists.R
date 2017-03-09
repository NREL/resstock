library(MASS)
library(ggplot2)
library(ggfortify)
library(leaps)
library(reshape2)
library(plyr)

df = read.csv('../ahs.csv', na.strings='')

df = subset(df, select=c('NUNIT2', 'ROOMS', 'BEDRMS', 'size', 'vintage', 'heatingfuel', 'ZINC2', 'POOR', 'WEIGHT'))
df$NUNIT2 = as.numeric(gsub("'", "", df$NUNIT2))
df = rename(df, c('ZINC2'='income', 'POOR'='fpl'))

x.vars.con = c()

# y.vars.con = c('income')
y.vars.con = c('fpl')

x.vars.cat = c('vintage', 'size')

y.vars.cat = c()

# filters
df = df[df$NUNIT2==1, ]

df[c(x.vars.cat, y.vars.cat)] = lapply(df[c(x.vars.cat, y.vars.cat)], factor) # apply factor to each of the categorical vars

sig_indep_vars = c(x.vars.con, x.vars.cat)

for (x in sig_indep_vars) {
  
  lvls = levels(as.factor(df[[x]]))
  counts = aggregate(df$WEIGHT, by=list(bin=df[[x]]), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(df, aes_string(x=y.vars.con[[1]])) + geom_density(aes_string(colour=x)) + scale_colour_discrete(name=x, labels=labels)
  ggsave(q, file=paste(x,'png',sep='_act.'), width=14)
  
}

for (vintage in levels(as.factor(df$vintage))){

  temp = df[df$vintage==vintage, ]
  
  temp$size_and_vintage = paste(temp$size, temp$vintage)
  
  lvls = levels(as.factor(temp$size_and_vintage))
  counts = aggregate(temp$WEIGHT, by=list(bin=temp$size_and_vintage), FUN=sum)$x
  labels = paste(lvls, ', n = ', round(counts), sep='')
  
  q = ggplot(temp, aes_string(x=y.vars.con[[1]])) + geom_density(aes(colour=size_and_vintage)) + scale_colour_discrete(name='size_and_vintage', labels=labels)
  ggsave(q, file=paste(gsub('<', '', vintage),'png',sep='_act.'), width=14)
  
}