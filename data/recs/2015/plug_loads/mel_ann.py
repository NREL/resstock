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

# TOTHSQFT, TOTCSQFT

# MELS: KWHMICRO, KWHTVREL, KWHEVAPCOL, KWHDHUM, KWHHUM, KWHNEC

### RECS 2015 ###
print '2015'
df = pd.read_csv('c:/recs2015/recs2015_public_v4.csv')
df['TOTSQFT'] = df[['TOTHSQFT', 'TOTCSQFT']].max(axis=1)
# df['MELS'] = df['KWHMICRO'] + df['KWHTVREL'] + df['KWHEVAPCOL'] + df['KWHDHUM'] + df['KWHHUM'] + df['KWHNEC']
df['MELS'] = df['KWHMICRO'] + df['KWHTVREL'] + df['KWHDHUM'] + df['KWHHUM'] + df['KWHNEC']

# NHSLDMEM, TOTSQFT

X = df[['NHSLDMEM', 'TOTSQFT']]
y = df['MELS']

sample_weight = df['NWEIGHT']

regr = LinearRegression()
regr.fit(X=X, y=y, sample_weight=sample_weight)

y = regr.intercept_.round(2)
x = regr.coef_
print '\tMELS = {} + {}*NHSLDMEM + {}*TOTSQFT'.format(y, round(x[0], 2), round(x[1], 2))

nbeds = range(0, 11)
SFD_noccupants = [1.15 + 0.5 * nbed for nbed in nbeds] # taken from occupants/num_occupants.py
MF_noccupants = [1.17 + 0.56 * nbed for nbed in nbeds] # taken from occupants/num_occupants.py

# SFD

mels_450 = [regr.predict([[noccupant, 450.0]])[0] for noccupant in SFD_noccupants]
mels_600 = [regr.predict([[noccupant, 600.0]])[0] for noccupant in SFD_noccupants]
mels_750 = [regr.predict([[noccupant, 750.0]])[0] for noccupant in SFD_noccupants]
mels_1100 = [regr.predict([[noccupant, 1100.0]])[0] for noccupant in SFD_noccupants]
mels_1150 = [regr.predict([[noccupant, 1150.0]])[0] for noccupant in SFD_noccupants]
mels_1200 = [regr.predict([[noccupant, 1200.0]])[0] for noccupant in SFD_noccupants]
mels_1500 = [regr.predict([[noccupant, 1500.0]])[0] for noccupant in SFD_noccupants]

plt.figure(figsize=(12, 8))
plt.plot(nbeds, mels_450, label='450')
plt.plot(nbeds, mels_600, label='600')
plt.plot(nbeds, mels_750, label='750')
plt.plot(nbeds, mels_1100, label='1100')
plt.plot(nbeds, mels_1150, label='1150')
plt.plot(nbeds, mels_1200, label='1200')
plt.plot(nbeds, mels_1500, label='1500')
plt.title('SFD')
plt.xlabel('bedrooms')
plt.ylabel('mel_ann')
plt.legend()
plt.savefig('SFD_2015_mel_ann.png')

ffa = 1500.0
mels_2009 = [635.08 + 1419.79 * nbed + 1.0 * ffa for nbed in nbeds]
mels_2001 = [1108.1 + 180.2 * nbed + 0.2785 * ffa for nbed in nbeds]

plt.figure(figsize=(12, 8))
plt.plot(nbeds, mels_1500, label='RECS 2015')
# plt.plot(nbeds, mels_2009, label='RECS 2009')
plt.plot(nbeds, mels_2001, label='RECS 2001')
plt.title('SFD')
plt.xlabel('bedrooms')
plt.ylabel('mel_ann')
plt.legend()
plt.savefig('SFD_mel_ann.png')

# MF

mels_450 = [regr.predict([[noccupant, 450.0]])[0] for noccupant in MF_noccupants]
mels_600 = [regr.predict([[noccupant, 600.0]])[0] for noccupant in MF_noccupants]
mels_750 = [regr.predict([[noccupant, 750.0]])[0] for noccupant in MF_noccupants]
mels_1100 = [regr.predict([[noccupant, 1100.0]])[0] for noccupant in MF_noccupants]
mels_1150 = [regr.predict([[noccupant, 1150.0]])[0] for noccupant in MF_noccupants]
mels_1200 = [regr.predict([[noccupant, 1200.0]])[0] for noccupant in MF_noccupants]
mels_1500 = [regr.predict([[noccupant, 1500.0]])[0] for noccupant in MF_noccupants]

plt.figure(figsize=(12, 8))
plt.plot(nbeds, mels_450, label='450')
plt.plot(nbeds, mels_600, label='600')
plt.plot(nbeds, mels_750, label='750')
plt.plot(nbeds, mels_1100, label='1100')
plt.plot(nbeds, mels_1150, label='1150')
plt.plot(nbeds, mels_1200, label='1200')
plt.plot(nbeds, mels_1500, label='1500')
plt.title('MF')
plt.xlabel('bedrooms')
plt.ylabel('mel_ann')
plt.legend()
plt.savefig('MF_2015_mel_ann.png')

ffa = 600.0
mels_2009 = [635.08 + 1419.79 * nbed + 1.0 * ffa for nbed in nbeds]
mels_2001 = [1108.1 + 180.2 * nbed + 0.2785 * ffa for nbed in nbeds]

plt.figure(figsize=(12, 8))
plt.plot(nbeds, mels_600, label='RECS 2015')
# plt.plot(nbeds, mels_2009, label='RECS 2009')
plt.plot(nbeds, mels_2001, label='RECS 2001')
plt.title('MF')
plt.xlabel('bedrooms')
plt.ylabel('mel_ann')
plt.legend()
plt.savefig('MF_mel_ann.png')
#################

### RECS 2009 ###
print '2009'
df = pd.read_csv('c:/recs2009/recs2009_public.csv', index_col=['DOEID'], usecols=['DOEID', 'TYPEHUQ', 'BEDROOMS', 'NWEIGHT', 'TOTHSQFT', 'TOTCSQFT', 'KWHOTH'])
df = df[df['BEDROOMS']!=-2]
df['TOTSQFT'] = df[['TOTHSQFT', 'TOTCSQFT']].max(axis=1)
df['MELS'] = df['KWHOTH']

# BEDROOMS, TOTSQFT

X = df[['BEDROOMS', 'TOTSQFT']]
y = df['MELS']

sample_weight = df['NWEIGHT']

regr = LinearRegression()
regr.fit(X=X, y=y, sample_weight=sample_weight)

y = regr.intercept_.round(2)
x = regr.coef_
print '\tMELS = {} + {}*BEDROOMS + {}*TOTSQFT'.format(y, round(x[0], 2), round(x[1], 2))
#################