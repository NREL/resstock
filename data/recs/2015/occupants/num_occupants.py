import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt

# NWEIGHT
# 1235.521529 - 139307.4534

# TYPEHUQ
# 1 Mobile home
# 2 Single-family detached house 
# 3 Single-family attached house
# 4 Apartment in a building with 2 to 4 units
# 5 Apartment in a building with 5 or more units

# BEDROOMS
# 0 - 30

# NHSLDMEM
# 1 - 20

### RECS 2015 ###
print '2015'
df = pd.read_csv('c:/recs2015/recs2015_public_v4.csv')

# SFD

sfd = df.loc[df['TYPEHUQ'].isin([1, 2]), :]

X = sfd['BEDROOMS'].values
X = X.reshape(len(X), 1)

y = sfd['NHSLDMEM'].values
y = y.reshape(len(y), 1)

sample_weight = sfd['NWEIGHT']

regr = LinearRegression()
regr.fit(X=X, y=y, sample_weight=sample_weight)
r2 = regr.score(X, y)

y = regr.intercept_[0].round(2)
x = regr.coef_[0][0].round(2)
print '\tSFD: NHSLDMEM = {} + {}*BEDROOMS, R2: {}'.format(y, x, r2)

nbeds = range(0, 11)

noccupants_2015 = regr.predict(np.array(nbeds).reshape(len(nbeds), 1))
noccupants_2009 = [1.02 + 0.55 * nbed for nbed in nbeds] # taken from below
noccupants_2001 = [0.87 + 0.59 * nbed for nbed in nbeds] # taken from BEopt

plt.figure(figsize=(12, 8))
plt.plot(nbeds, noccupants_2015, label='RECS 2015')
plt.plot(nbeds, noccupants_2009, label='RECS 2009')
plt.plot(nbeds, noccupants_2001, label='RECS 2001')
plt.title('SFD')
plt.xlabel('bedrooms')
plt.ylabel('occupants')
plt.legend()
plt.savefig('SFD_num_occupants.png')

plt.figure(figsize=(12, 8))
plt.scatter(sfd['BEDROOMS'].values, sfd['NHSLDMEM'].values)
plt.plot(nbeds, noccupants_2015, label='RECS 2015')
plt.title('SFD')
plt.xlabel('bedrooms')
plt.ylabel('occupants')
plt.legend()
plt.savefig('SFD_2015_num_occupants.png')

# MF

mf = df.loc[df['TYPEHUQ'].isin([3, 4, 5]), :]

X = mf['BEDROOMS'].values
X = X.reshape(len(X), 1)

y = mf['NHSLDMEM'].values
y = y.reshape(len(y), 1)

sample_weight = mf['NWEIGHT'].values

regr = LinearRegression()
regr.fit(X=X, y=y, sample_weight=sample_weight)
r2 = regr.score(X, y)

y = regr.intercept_[0].round(2)
x = regr.coef_[0][0].round(2)
print '\tMF: NHSLDMEM = {} + {}*BEDROOMS, R2: {}'.format(y, x, r2)

nbeds = range(0, 11)

noccupants_2015 = regr.predict(np.array(nbeds).reshape(len(nbeds), 1))
noccupants_2009 = [0.61 + 0.82 * nbed for nbed in nbeds] # taken from below
noccupants_2001 = [0.63 + 0.92 * nbed for nbed in nbeds] # taken from BEopt

plt.figure(figsize=(12, 8))
plt.plot(nbeds, noccupants_2015, label='RECS 2015')
plt.plot(nbeds, noccupants_2009, label='RECS 2009')
plt.plot(nbeds, noccupants_2001, label='RECS 2001')
plt.title('MF')
plt.xlabel('bedrooms')
plt.ylabel('occupants')
plt.legend()
plt.savefig('MF_num_occupants.png')

plt.figure(figsize=(12, 8))
plt.scatter(mf['BEDROOMS'].values, mf['NHSLDMEM'].values)
plt.plot(nbeds, noccupants_2015, label='RECS 2015')
plt.title('MF')
plt.xlabel('bedrooms')
plt.ylabel('occupants')
plt.legend()
plt.savefig('MF_2015_num_occupants.png')
#################

### RECS 2009 ###
print '2009'
df = pd.read_csv('c:/recs2009/recs2009_public.csv', index_col=['DOEID'], usecols=['DOEID', 'TYPEHUQ', 'BEDROOMS', 'NHSLDMEM', 'NWEIGHT'])
df = df[df['BEDROOMS']!=-2]

# SFD

sfd = df.loc[df['TYPEHUQ'].isin([1, 2]), :]

X = sfd['BEDROOMS'].values
X = X.reshape(len(X), 1)

y = sfd['NHSLDMEM'].values
y = y.reshape(len(y), 1)

sample_weight = sfd['NWEIGHT']

regr = LinearRegression()
regr.fit(X=X, y=y, sample_weight=sample_weight)
r2 = regr.score(X, y)

y = regr.intercept_[0].round(2)
x = regr.coef_[0][0].round(2)
print '\tSFD: NHSLDMEM = {} + {}*BEDROOMS, R2: {}'.format(y, x, r2)

# MF

mf = df.loc[df['TYPEHUQ'].isin([3, 4, 5]), :]

X = mf['BEDROOMS'].values
X = X.reshape(len(X), 1)

y = mf['NHSLDMEM'].values
y = y.reshape(len(y), 1)

sample_weight = mf['NWEIGHT'].values

regr = LinearRegression()
regr.fit(X=X, y=y, sample_weight=sample_weight)
r2 = regr.score(X, y)

y = regr.intercept_[0].round(2)
x = regr.coef_[0][0].round(2)
print '\tMF: NHSLDMEM = {} + {}*BEDROOMS, R2: {}'.format(y, x, r2)