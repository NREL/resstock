def map_geometry_building_type(df):
    df['Geometry Building Type RECS'] = df['TYPEHUQ'].map({1: 'Mobile Home',
                                                           2: 'Single-Family Detached',
                                                           3: 'Single-Family Attached',
                                                           4: 'Multi-Family with 2 - 4 Units',
                                                           5: 'Multi-Family with 5+ Units'})
    return df

def map_geometry_house_size(df):
    df['TOTSQFT'] = df[['TOTHSQFT', 'TOTCSQFT']].max(axis=1)
    df.loc[:, 'Geometry House Size'] = 0
    df.loc[(df['TOTSQFT'] < 1500), 'Geometry House Size'] = '0-1499'
    df.loc[(df['TOTSQFT'] >= 1500) & (df['TOTSQFT'] < 2500), 'Geometry House Size'] = '1500-2499'
    df.loc[(df['TOTSQFT'] >= 2500) & (df['TOTSQFT'] < 3500), 'Geometry House Size'] = '2500-3499'
    df.loc[(df['TOTSQFT'] >= 3500), 'Geometry House Size'] = '3500+'
    return df

def map_bedrooms(df):
    df['Bedrooms'] = df['BEDROOMS'].map({0: 1,
                                         1: 1,
                                         2: 2,
                                         3: 3,
                                         4: 4,
                                         5: 5,
                                         6: 5,
                                         7: 5,
                                         8: 5,
                                         9: 5,
                                         10: 5})
    return df

def map_occupants(df):
    df['Occupants'] = df['NHSLDMEM'].map({1: 1,
                                          2: 2,
                                          3: 3,
                                          4: 4,
                                          5: 5,
                                          6: 6,
                                          7: 6,
                                          8: 6,
                                          9: 6,
                                          10: 6,
                                          11: 6,
                                          12: 6})
    return df