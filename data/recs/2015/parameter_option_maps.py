def map_geometry_building_type(df):
    typehuqs = [1, 2, 3, 4, 5]
    geometry_building_types = ['Mobile Home', 'Single-Family Detached', 'Single-Family Attached', 'Multi-Family with 2 -4 Units', 'Multi-Family with 5+ Units']
    df['Geometry Building Type'] = df['TYPEHUQ'].map({1: 'Mobile Home',
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
    df['Bedrooms'] = df['BEDROOMS']
    return df
    
def map_occupants(df):
    df['Occupants'] = df['NHSLDMEM']
    return df