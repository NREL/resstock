import os, sys
from sqlalchemy import create_engine, Column, Integer, String, Float, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, backref
from configparser import ConfigParser

Base = declarative_base()

def create_session(driver):

  global engine
  engine = create_engine(driver) # use echo=True to print SQL statements
      
  global Session
  Session = sessionmaker(bind=engine)
  
  Base.metadata.drop_all(engine)
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
  
  datapoint_id = Column('datapoint_id', String, ForeignKey('Building.datapoint_id'), primary_key=True)
  upgrade_id = Column('upgrade_id', Integer, ForeignKey('Upgrade.upgrade_id'), primary_key=True)
  upgrade_cost_usd = Column('upgrade_cost_usd', Float)
    
  def __init__(self, datapoint_id, upgrade_id, upgrade_cost_usd):
    self.datapoint_id = datapoint_id
    self.upgrade_id = upgrade_id
    self.upgrade_cost_usd = upgrade_cost_usd
    
class Building(Base):
  __tablename__ = 'Building'

  datapoint_id = Column('datapoint_id', String, primary_key=True)
  building_id = Column('building_id', Integer)
  
  def __init__(self, datapoint_id, building_id):
    self.datapoint_id = datapoint_id
    self.building_id = building_id    

class Upgrade(Base):
  __tablename__ = 'Upgrade'
  
  upgrade_id = Column(Integer, primary_key=True)
  upgrade_name = Column(String, unique=True)
  
  def __init__(self, upgrade_id, upgrade_name):
    self.upgrade_id = upgrade_id
    self.upgrade_name = upgrade_name
  
class ParameterOption(Base):
  __tablename__ = 'ParameterOption'
  
  parameteroption_id = Column('parameteroption_id', Integer, primary_key=True)
  parameter_id = Column('parameter_id', Integer, ForeignKey('Parameter.parameter_id'))
  parameteroption_name = Column('parameteroption_name', String)
  
  def __init__(self, parameteroption_id, parameter_id, paramteroption_name):
    self.parameteroption_id = parameteroption_id
    self.parameter_id = parameter_id
    self.parameteroption_name = parameteroption_name
  
class Parameter(Base):
  __tablename__ = 'Parameter'
  
  parameter_id = Column('parameter_id', Integer, primary_key=True)
  parameter_name = Column('parameter_name', String, unique=True)
  
  def __init__(self, parameter_id, parameter_name):
    self.parameter_id = parameter_id
    self.parameter_name = parameter_name
  
class Enduse(Base):
  __tablename__ = 'Enduse'
  
  enduse_id = Column('enduse_id', Integer, primary_key=True)
  enduse_name = Column('enduse_name', String)
  
  def __init__(self, enduse_id, enduse_name):
    self.enduse_id = enduse_id
    self.enduse_name = enduse_name
  
class FuelType(Base):
  __tablename__ = 'FuelType'
  
  fueltype_id = Column('fueltype_id', Integer, primary_key=True)
  fueltype_name = Column('fueltype_name', String)
  
  def __init__(self, fueltype_id, fueltype_name):
    self.fueltype_id = fueltype_id
    self.fueltype_name = fueltype_name
    
class DatapointSimulationOutput(Base):
  __tablename__ = 'DatapointSimulationOutput'
  
  datapoint_id = Column('datapoint_id', Integer, ForeignKey('Datapoint.datapoint_id'), primary_key=True)
  enduse_id = Column('enduse_id', Integer, ForeignKey('Enduse.enduse_id'), primary_key=True)
  fueltype_id = Column('fueltype_id', Integer, ForeignKey('FuelType.fueltype_id'), primary_key=True)
  value = Column('value', Float)
  
  def __init__(self, datapoint_id, enduse_id, fueltype_id, value):
    self.datapoint_id = datapoint_id
    self.enduse_id = enduse_id
    self.fueltype_id = fueltype_id    
    self.value = value
  
class DatapointParameterOption(Base):
  __tablename__ = 'DatapointParameterOption'

  datapoint_id = Column('datapoint_id', Integer, ForeignKey('Datapoint.datapoint_id'), primary_key=True)
  parameteroption_id = Column('parameteroption_id', Integer, ForeignKey('ParameterOption.parameteroption_id'), primary_key=True)
  
  def __init__(self, datapoint_id, parameteroption_id):
    self.datapoint_id = datapoint_id
    self.parameteroption_id = parameteroption_id
