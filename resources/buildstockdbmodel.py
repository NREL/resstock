import os, sys
from sqlalchemy import create_engine, Column, Integer, String, Float, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, backref
from configparser import ConfigParser

Base = declarative_base()

def create_session(file, driver):
  basename, ext = os.path.splitext(file) #@UnusedVariable
  global engine
  if driver == 'sqlite':
    engine = create_engine('{}:///{}'.format(driver, os.path.abspath(file))) # use echo=True to print SQL statements
  elif driver == 'postgresql':
    params = config()
    engine = create_engine('postgresql://{user}:{password}@{host}:{port}/{database}'.format(**params))    
  else:
    raise ValueError('Unknown file type %s' % ext)
      
  global Session
  Session = sessionmaker(bind=engine)
  
  Base.metadata.create_all(engine)
  
  return Session()

def config(filename='buildstock.ini', section='postgresql'):

  # create a parser
  parser = ConfigParser()
  # read config file
  parser.read(filename)

  # get section, default to postgresql
  db = {}
  if parser.has_section(section):
    params = parser.items(section)
    for param in params:
      db[param[0]] = param[1]
  else:
    raise Exception('Section {0} not found in the {1} file'.format(section, filename))

  return db
  
class Datapoint(Base):
  __tablename__ = 'Datapoint'
  datapoint_id = Column('datapoint_id', String, primary_key=True)
  building_id = Column('building_id', Integer, ForeignKey('Building.building_id'))
  parameteroption_id = Column('parameteroption_id', Integer, ForeignKey('ParameterOption.parameteroption_id'))
  ugprade_id = Column('upgrade_id', Integer, ForeignKey('Upgrade.upgrade_id'))
  upgrade_cost_usd = Column('upgrade_cost_usd', Float)
    
class Building(Base):
  __tablename__ = 'Building'
  building_id = Column('building_id', Integer, primary_key=True)

class Upgrade(Base):
  __tablename__ = 'Upgrade'
  upgrade_id = Column(Integer, primary_key=True)
  upgrade_name = Column(String)
  
  # datapoint = relationship('Datapoint', backref='Upgrade')
  
class ParameterOption(Base):
  __tablename__ = 'ParameterOption'
  parameteroption_id = Column('parameteroption_id', Integer, primary_key=True)
  parameter_id = Column('parameter_id', Integer, ForeignKey('Parameter.parameter_id'))
  parameteroption_name = Column('parameteroption_name', String)
  
class Parameter(Base):
  __tablename__ = 'Parameter'
  parameter_id = Column('parameter_id', Integer, primary_key=True)
  parameter_name = Column('parameter_name', String)
  
class SimulationOutput(Base):
  __tablename__ = 'SimulationOutput'
  simulationoutput_id = Column('simulationoutput_id', Integer, primary_key=True)
  fueltype_id = Column('fueltype_id', Integer, ForeignKey('FuelType.fueltype_id'))
  enduse_id = Column('enduse_id', Integer, ForeignKey('Enduse.enduse_id'))
  value = Column('value', Float)
  
class Enduse(Base):
  __tablename__ = 'Enduse'
  enduse_id = Column('enduse_id', Integer, primary_key=True)
  enduse_name = Column('enduse_name', String)
  
class FuelType(Base):
  __tablename__ = 'FuelType'
  fueltype_id = Column('fueltype_id', Integer, primary_key=True)
  fueltype_name = Column('fueltype_name', String)