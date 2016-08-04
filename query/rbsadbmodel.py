'''
Created on Apr 17, 2013
Updated on May 24, 2013

@author: jrobert1
'''
import os
import sys

curpath = os.path.dirname(os.path.abspath(__file__))

from sqlalchemy import create_engine, Table, Column, Integer, Unicode, Boolean, Float, Date, ForeignKey #@UnresolvedImport
from sqlalchemy.ext.declarative import declarative_base #@UnresolvedImport
from sqlalchemy.orm import sessionmaker, relationship, backref #@UnresolvedImport
from sqlalchemy.orm.collections import attribute_mapped_collection #@UnresolvedImport

def create_session(filename):
    basename,ext = os.path.splitext(filename) #@UnusedVariable
    global engine
    if ext == '.sqlite':
        engine = create_engine('sqlite:///%s' % os.path.abspath(filename)) # use echo=True to print SQL statements
    else:
        raise ValueError('Unknown file type %s' % ext)
        
    global Session
    Session = sessionmaker(bind=engine)
    
    return Session()

class String(Unicode):
    '''
    This is my sub class of a sqlalchemy class to handle the weird text encoding
    in the rbsa database
    '''
    def result_processor(self, dialect, coltype):
        def resprocf(x):
            if x is None:
                return x
            else:
                return x.encode('latin_1').decode('utf-8')
        return resprocf
    
class Base(object):
    rowid = Column(Integer, primary_key=True)

Base = declarative_base(cls=Base)

class HTNotes(Base):
    __tablename__ = 'HTnotes'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    hvactestingnotes = Column('HVACTestingNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('htnotes', uselist=False))

class HVACCooling(Base):
    __tablename__ = 'HVACcooling'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    hvaccoolit = Column('HVACCool_it', Integer)
    hvacprimarycooling = Column('HVACPrimaryCooling', Boolean)
    hvactype = Column('HVACType', String)
    acyear = Column('AC_Year', Integer)
    evapcfm = Column('EvapCFM', Float)
    evapscale = Column('EvapScale', String)
    hvaccontrols = Column('HVACControls', String)
    hvacdistribution = Column('HVACDistribution', String)
    hvacfantype = Column('HVACFanType', String)
    hvacfilter = Column('HVACFilter', String)
    hvacgroundloop = Column('HVACGroundLoop', String)
    hvaclooptype = Column('HVACLoopType', String)
    hvacmanu = Column('HVACManu', String)
    hvacmodel = Column('HVACModel', String)
    hvacprimaryweights = Column('HVACPrimaryWeights', Float)
    hvacpumphp = Column('HVACPumpHP', Float)
    hvactons = Column('HVACTons', Float)
    unitacdaysofuse = Column('UnitACDaysOfUse', Integer)
    unitacquantity = Column('UnitACQuantity', Integer)
    seer = Column('SEER', Float)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='hvaccooling')
    
class HVACHeating(Base):
    __tablename__ = 'HVACheating'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    hvacheatit = Column('HVACHeat_it', Integer)
    hvacprimary = Column('HVACPrimary', Boolean)
    hvactype = Column('HVACType', String)
    elecresistquantity = Column('ElecResistQuantity', Integer)
    elecresistuse = Column('ElecResistUse', String)
    combventtype = Column('CombVentType', String)
    combventtypebackup = Column('CombVentTypeBackup', String)
    combeffic = Column('CombEffic', Float)
    hspf = Column('HSPF', Float)
    hvacbackup = Column('HVACBackup', String)
    hvaccompressorinheating = Column('HVACCompressorInHeating', Boolean)
    hvaccontrols = Column('HVACControls', String)
    hvacdistribution = Column('HVACDistribution', String)
    hvacfantype = Column('HVACFanType', String)
    hvacfilter = Column('HVACFilter', String)
    hvacfuel = Column('HVACFuel', String)
    hvacfuelbackup = Column('HVACFuelBackup', String)
    hvacgroundloop = Column('HVACGroundLoop', String)
    hvacignition = Column('HVACIgnition', String)
    hvacignitionbackup = Column('HVACIgnitionBackup', String)
    hvacignitionhstove = Column('HVACIgnitionHStove', String)
    hvacinput = Column('HVACInput', Integer)
    hvacinputbackup = Column('HVACInputBackup', Integer)
    hvackw = Column('HVACKW', Float)
    hvaclooptype = Column('HVACLoopType', String)
    hvacmanu = Column('HVACManu', String)
    hvacmanubackup = Column('HVACManuBackup', String)
    hvacmodel = Column('HVACModel', String)
    hvacmodelbackup = Column('HVACModelBackup', String)
    hvacoutput = Column('HVACOutput', Integer)
    hvacoutputbackup = Column('HVACOutputBackup', Integer)
    hvacprimaryweights = Column('HVACPrimaryWeights', Float)
    hvacpumphp = Column('HVACPumpHP', Float)
    hvacstripheatlock = Column('HVACStripHeatLock', Boolean)
    hvactons = Column('HVACTons', Float)
    hvacvoltage = Column('HVACVoltage', Integer)
    hvacyear = Column('HVACYear', Integer)
    hvacyearbackup = Column('HVACYearBackup', Integer)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='hvacheating')

class SFMasterHouseGeometry(Base):
    __tablename__ = 'SFMaster_housegeometry'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    sfbuildingtype = Column('SFBuildingType', String)
    sffloors = Column('SFFloors', Float)
    sffoundation = Column('SFFoundation', String)
    summarynumberofroomscalculated = Column('SummaryNumberOfRooms_Calculated', Integer)
    summaryroomvolumecalculated = Column('SummaryRoomVolume_Calculated', Float)
    summarysketchsqftcalculated = Column('SummarySketchSqFt_Calculated', Float)
    summarysketchvolumecalculated = Column('SummarySketchVolume_Calculated', Float)
    summarywindowfractioncalculated = Column('SummaryWindowFraction_Calculated', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfmasterhousegeometry', uselist=False))

class SFMasterLocation(Base):
    __tablename__ = 'SFMaster_location'
    
    siteid = Column('siteid', Integer, primary_key=True)
    city = Column('city', String)
    state = Column('state', String)
    postcode = Column('postcode', String)
    county = Column('county', String)
      
class SFMasterPopulations(Base):
    __tablename__ = 'SFMaster_populations'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    utilityid = Column('utility_id', Integer)
    utilityname = Column('utility_name', String)
    cell = Column('cell', String)
    stratum = Column('stratum', String)
    popct = Column('pop_ct', Float)
    svywt = Column('svy_wt', Float)
    heatclimzone = Column('heat_clim_zone', Integer)
    coolclimzone = Column('cool_clim_zone', Integer)
    bparegion = Column('BPA_region', String)
    naturalgasutilityname = Column('naturalgas_utilityname', String)
    gasflag = Column('gasflag', Boolean)
    zipzcta = Column('zip_zcta', String)
    utilitytype = Column('UtilityType', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfmasterpopulations', uselist=False))
    
class SFMasterSiteDetails(Base):
    __tablename__ = 'SFMaster_sitedetails'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    entereddate = Column('entereddate', String)
    topcflstored = Column('Top_CFLStored', Integer)
    topincansstored = Column('Top_IncansStored', Integer)
    topotherbulbstored = Column('Top_OtherBulbStored', Integer)
    topoutbuildingfuel = Column('Top_OutbuildingFuel', String)
    topoutbuildings = Column('Top_Outbuildings', Boolean)
    topsolarpv = Column('Top_SolarPV', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfmastersitedetails', uselist=False))

class SFRiCons(Base):
    __tablename__ = 'SF_ri_cons'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    resintheatreplaced = Column('ResInt_HeatReplaced', String)
    resintheatreplaceddescnew = Column('ResInt_HeatReplaced_DescNew', String)
    resintheatreplaceddiffer = Column('ResInt_HeatReplaced_Differ', String)
    resintheatreplacedfuelswitch = Column('ResInt_HeatReplaced_FuelSwitch', Boolean)
    resintheatreplacedolddesc = Column('ResInt_HeatReplaced_OldDesc', String)
    resintheatreplacedtype = Column('ResInt_HeatReplaced_Type', String)
    resintselfairsealing = Column('ResInt_SelfAirSealing', Boolean)
    resintselfappliance = Column('ResInt_SelfAppliance', Boolean)
    resintselfappliancetype = Column('ResInt_SelfApplianceType', String)
    resintselfaudit = Column('ResInt_SelfAudit', Boolean)
    resintselfceilingins = Column('ResInt_SelfCeilingIns', Boolean)
    resintselfcooling = Column('ResInt_SelfCooling', Boolean)
    resintselfdoorreplacement = Column('ResInt_SelfDoorReplacement', Boolean)
    resintselfductins = Column('ResInt_SelfDuctIns', Boolean)
    resintselfductsealing = Column('ResInt_SelfDuctSealing', Boolean)
    resintselffloorins = Column('ResInt_SelfFloorIns', Boolean)
    resintselfheating = Column('ResInt_SelfHeating', Boolean)
    resintselflighting = Column('ResInt_SelfLighting', Boolean)
    resintselfother = Column('ResInt_SelfOther', Boolean)
    resintselfprogram = Column('ResInt_SelfProgram', Boolean)
    resintselfshower = Column('ResInt_SelfShower', Boolean)
    resintselftaxcredit = Column('ResInt_SelfTaxCredit', Boolean)
    resintselftaxcreditfederal = Column('ResInt_SelfTaxCredit_Federal', Boolean)
    resintselftaxcreditother = Column('ResInt_SelfTaxCredit_Other', Boolean)
    resintselftaxcreditstate = Column('ResInt_SelfTaxCredit_State', Boolean)
    resintselfwallins = Column('ResInt_SelfWallIns', Boolean)
    resintselfwaterheat = Column('ResInt_SelfWaterHeat', Boolean)
    resintselfwindowreplacement = Column('ResInt_SelfWindowReplacement', Boolean)
    resintselfwx = Column('ResInt_SelfWx', Boolean)
    resintutilityairsealing = Column('ResInt_UtilityAirSealing', Boolean)
    resintutilityappliance = Column('ResInt_UtilityAppliance', Boolean)
    resintutilityappliancetype = Column('ResInt_UtilityApplianceType', Boolean)
    resintutilityaudit = Column('ResInt_UtilityAudit', Boolean)
    resintutilityceilingins = Column('ResInt_UtilityCeilingIns', Boolean)
    resintutilitycooling = Column('ResInt_UtilityCooling', Boolean)
    resintutilitydoorreplacement = Column('ResInt_UtilityDoorReplacement', Boolean)
    resintutilityductins = Column('ResInt_UtilityDuctIns', Boolean)
    resintutilityductsealing = Column('ResInt_UtilityDuctSealing', Boolean)
    resintutilityfloorins = Column('ResInt_UtilityFloorIns', Boolean)
    resintutilityheating = Column('ResInt_UtilityHeating', Boolean)
    resintutilitylighting = Column('ResInt_UtilityLighting', Boolean)
    resintutilityother = Column('ResInt_UtilityOther', Boolean)
    resintutilityprogram = Column('ResInt_UtilityProgram', Boolean)
    resintutilityshower = Column('ResInt_UtilityShower', Boolean)
    resintutilitytaxcredit = Column('ResInt_UtilityTaxCredit', Boolean)
    resintutilitytaxcreditfederal = Column('ResInt_UtilityTaxCredit_Federal', Boolean)
    resintutilitytaxcreditother = Column('ResInt_UtilityTaxCredit_Other', Boolean)
    resintutilitytaxcreditstate = Column('ResInt_UtilityTaxCredit_State', Boolean)
    resintutilitywallins = Column('ResInt_UtilityWallIns', Boolean)
    resintutilitywaterheat = Column('ResInt_UtilityWaterHeat', Boolean)
    resintutilitywindowreplacement = Column('ResInt_UtilityWindowReplacement', Boolean)
    resintutilitywx = Column('ResInt_UtilityWx', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfricons')
    
class SFRiCustdat(Base):    
    __tablename__ = 'SF_ri_custdat'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    resintbath = Column('ResInt_Bath', Integer)
    resintbedrooms = Column('ResInt_Bedrooms', Integer)
    resintcoalarm = Column('ResInt_COAlarm', Boolean)
    resintmovein = Column('ResInt_MoveIn', Integer)
    resintyearbuilt = Column('ResInt_YearBuilt', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfricustdat', uselist=False))
    
class SFRiDemog(Base):
    __tablename__ = 'SF_ri_demog'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    generalnotes = Column('GeneralNotes', String)
    resint1 = Column('ResInt_1', Integer)
    resint1118 = Column('ResInt_11_18', Integer)
    resint1945 = Column('ResInt_19_45', Integer)
    resint15 = Column('ResInt_1_5', Integer)
    resint4664 = Column('ResInt_46_64', Integer)
    resint65 = Column('ResInt_65', Integer)
    resint610 = Column('ResInt_6_10', Integer)
    resintaddedoccupant = Column('ResInt_AddedOccupant', Boolean)
    resintelectricassistance = Column('ResInt_ElectricAssistance', Float)
    resintelectricpayment = Column('ResInt_ElectricPayment', String)
    resintgasassistance = Column('ResInt_GasAssistance', Float)
    resintgaypayment = Column('ResInt_GasPayment', String)
    resinthomebusiness = Column('ResInt_HomeBusiness', Boolean)
    resinthomeownership = Column('ResInt_HomeOwnership', String)
    resintoccjustmoved = Column('ResInt_OccJustMoved', Boolean)
    resintoccupantmoved = Column('ResInt_OccupantMoved', Boolean)
    resintplannedmove = Column('ResInt_PlannedMove', Boolean)
    resintprimaryres = Column('ResInt_PrimaryRes', String)
    resintpublicassistance = Column('ResInt_PublicAssistance', Boolean)
    resintworkingoutside = Column('ResInt_WorkingOutside', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfridemog', uselist=False))
    
class SFRiHeu(Base):
    __tablename__ = 'SF_ri_heu'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    resintdwloads = Column('ResIntDWLoads', Float)
    resintwasherloads = Column('ResIntWasherLoads', Float)
    resintwasherloadsdried = Column('ResIntWasherLoadsDried', Float)
    resintwasherloadshot = Column('ResIntWasherLoadsHot', Float)
    resintacnight = Column('ResInt_ACNight', Integer)
    resintactemp = Column('ResInt_ACTemp', Integer)
    resintacused = Column('ResInt_ACUsed', Boolean)
    resintadditionaltvs = Column('ResInt_AdditionalTVs', Integer)
    resintadditionaltvshours = Column('ResInt_AdditionalTVsHours', Float)
    resintdrafty = Column('ResInt_Drafty', Boolean)
    resintfueloil = Column('ResInt_FuelOil', Integer)
    resintfuelpellets = Column('ResInt_FuelPellets', Float)
    resintfuelpropane = Column('ResInt_FuelPropane', Integer)
    resintfuelwood = Column('ResInt_FuelWood', Float)
    resinthvacproblems = Column('ResInt_HVACProblems', Boolean)
    resintheatmostused = Column('ResInt_HeatMostUsed', String)
    resintheattemp = Column('ResInt_HeatTemp', Integer)
    resintheattempnight = Column('ResInt_HeatTempNight', Integer)
    resintinternetongamesystem = Column('ResInt_InternetOnGameSystem', Boolean)
    resintmildew = Column('ResInt_Mildew', Boolean)
    resintnonutilityfuel = Column('ResInt_NonUtilityFuel', Boolean)
    resintodors = Column('ResInt_Odors', Boolean)
    resintoutsidetempforac = Column('ResInt_OutsideTempForAC', Integer)
    resintportablecooling = Column('ResInt_PortableCooling', Boolean)
    resintportableheat = Column('ResInt_PortableHeat', Boolean)
    resintportionblockedoff = Column('ResInt_PortionBlockedOff', Float)
    resintprimaryshowerhead = Column('ResInt_PrimaryShowerhead', String)
    resintshowerheads = Column('ResInt_Showerheads', Integer)
    resintstuffy = Column('ResInt_Stuffy', Boolean)
    resinttvage = Column('ResInt_TVAge', Integer)
    resinttvhours = Column('ResInt_TVHours', Float)
    resinttvsecondaryage = Column('ResInt_TVSecondaryAge', Integer)
    resinttvsecondaryhours = Column('ResInt_TVSecondaryHours', Float)
    resinttvsmostused = Column('ResInt_TVsMostUsed', String)
    resintvideosongamesystem = Column('ResInt_VideosOnGameSystem', Boolean)
    propane = Column('propane', String)
    gasuser = Column('Gas_user', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfriheu', uselist=False))
    
class SFRiPp(Base):
    __tablename__ = 'SF_ri_pp'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    generalnotes = Column('GeneralNotes', String)
    resintestarappliances = Column('ResInt_EStarAppliances', Boolean)
    resintestaraware = Column('ResInt_EStarAware', Boolean)
    resintestarsatisfied = Column('ResInt_EStarSatisfied', Boolean)
    resintplannedappliance = Column('ResInt_Planned_Appliance', Boolean)
    resintplanneddishwasher = Column('ResInt_Planned_Dishwasher', Boolean)
    resintplannedfridge = Column('ResInt_Planned_Fridge', Boolean)
    resintplannedheatupgd = Column('ResInt_Planned_HeatUpgd', String)
    resintplannedother = Column('ResInt_Planned_Other', Boolean)
    resintplannedotherdesc = Column('ResInt_Planned_OtherDesc', String)
    resintplannedspaceheater = Column('ResInt_Planned_SpaceHeater', Boolean)
    resintplannedtv = Column('ResInt_Planned_TV', Boolean)
    resintplannedwheatupgd = Column('ResInt_Planned_WHeatUpgd', String)
    resintplannedwasherdryer = Column('ResInt_Planned_WasherDryer', Boolean)
    resintplannedwindowac = Column('ResInt_Planned_WindowAC', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfripp', uselist=False))
    
class SFAdiabaticCeiling(Base):
    __tablename__ = 'SFadiabaticceiling'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    adiabaticceilingarea = Column('AdiabaticCeilingArea', Integer)
    adiabaticceilingfloortype = Column('AdiabaticCeilingFloorType', String)
    adiabaticceilinginslvl = Column('AdiabaticCeilingInsLvl', String)
    adiabaticceilinginstype = Column('AdiabaticCeilingInsType', String)
    adiabaticceilingtype = Column('AdiabaticCeilingType', String)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfadiabaticceiling')
    
class SFAdiabaticWall(Base):
    __tablename__ = 'SFadiabaticwall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    adiabaticwallit = Column('adiabaticwall_it', Integer)
    adiabaticarea = Column('AdiabaticArea', Integer)
    adiabaticins = Column('AdiabaticIns', Boolean)
    adiabaticotherdesc = Column('AdiabaticOtherDesc', String)
    adiabatictype = Column('AdiabaticType', String)
    adiabaticwalltype = Column('AdiabaticWallType', String)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfadiabaticwall')
    
class SFApplianceNotes(Base):
    __tablename__ = 'SFappliancenotes'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    appliancenotes = Column('ApplianceNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfappliancenotes', uselist=False))
    
class SFAtticCeiling(Base):
    __tablename__ = 'SFatticceiling'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    atticceilingit = Column('atticceiling_it', Integer)
    atticinslvl = Column('AtticInsLvl', String)
    atticinscond = Column('AtticInsCond', Float)
    atticarea = Column('AtticArea', Integer)
    atticestimprovement = Column('AtticEstImprovement', Integer)
    atticinstype = Column('AtticInsType', String)
    generalnotes = Column('GeneralNotes', String)
    uatticceil = Column('u_atticceil', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfatticceiling')
    
class SFBlowerDoor(Base):
    __tablename__ = 'SFblowerdoor'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    bdflowa = Column('BD_FlowA', Integer)
    bdhousepressurea = Column('BD_HousePressureA', Float)
    bdflowb = Column('BD_FlowB', Integer)
    bdhousepressureb = Column('BD_HousePressureB', Float)
    flowexponent = Column('flowexponent', Float)
    flowcoefficient = Column('flowcoefficient', Float)
    q50 = Column('Q50', Float)
    ela = Column('ELA', Float)
    ach50 = Column('ACH50', Float)
    ach622 = Column('ACH622', Float)
    qinf = Column('Qinf', Float)
    floorarea = Column('floorarea', Integer)
    volume = Column('volume', Float)
    buildingheight = Column('buildingheight', Float)
    bdnotes = Column('BD_Notes', String)
    wsf = Column('WSF', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfblowerdoor', uselist=False))
    
class SFCeiling(Base):
    __tablename__ = 'SFceiling'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    avgceilingheight = Column('AvgCeilingHeight', Float)
    ceilingnotes = Column('CeilingNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfceiling', uselist=False))
    
class SFCeilingUA(Base):
    __tablename__ = 'SFceilingua'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    uaceil = Column('ua_ceil', Float)
    elementspresent = Column('elements_present', String)
    elementsmissing = Column('elements_missing', String)
    baddata = Column('bad_data', Boolean)
    sfheatlossinclude = Column('sfheatlossinclude', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfceilingua')
    
class SFClWasher(Base):
    __tablename__ = 'SFclwasher'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    clotheswasherit = Column('clotheswasher_it', Integer)
    generalnotes = Column('GeneralNotes', String)
    washermanu = Column('WasherManu', String)
    washertype = Column('WasherType', String)
    washeryear = Column('WasherYear', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfclwasher')
    
class SFComputer(Base):
    __tablename__ = 'SFcomputer'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomit = Column('room_it', Integer, ForeignKey('SFroom.room_it'))
    computerit = Column('computer_it', Integer)
    computeraccessories = Column('Computer_Accessories', Integer)
    computerscreen1 = Column('Computer_Screen1', Integer)
    computerscreen2 = Column('Computer_Screen2', Integer)
    computerscreen3 = Column('Computer_Screen3', Integer)
    computerscreens = Column('Computer_Screens', Integer)
    computersinglestrip = Column('Computer_SingleStrip', Boolean)
    computertype = Column('Computer_Type', String)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfcomputer')
    
class SFCookEq(Base):
    __tablename__ = 'SFcookeq'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    cookit = Column('cook_it', Integer)
    cooktopfuel = Column('CooktopFuel', String)
    generalnotes = Column('GeneralNotes', String)
    ovenfuel = Column('OvenFuel', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfcookeq')
    
class SFDishwasher(Base):
    __tablename__ = 'SFdishwasher'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    dishwasherit = Column('dishwasher_it', Integer)
    dwloads = Column('DWLoads', Integer)
    dwyear = Column('DWYear', Integer)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfdishwasher')
    
class SFDoor(Base):
    __tablename__ = 'SFdoor'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    doorit = Column('door_it', Integer)
    doortype = Column('DoorType', String)
    doorarea = Column('DoorArea', Integer)
    generalnotes = Column('GeneralNotes', String)
    udoorwall = Column('u_doorwall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfdoor')
    
class SFDryer(Base):
    __tablename__ = 'SFdryer'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    dryerit = Column('dryer_it', Integer)
    dryerfuel = Column('DryerFuel', String)
    dryeryear = Column('DryerYear', Integer)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfdryer')
    
class SFDucts(Base):
    __tablename__ = 'SFducts'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    ductsit = Column('ducts_it', Integer)
    ductcondition = Column('DuctCondition', Float)
    ductinsulationtype = Column('DuctInsulationType', String)
    ductnotes = Column('DuctNotes', String)
    ductplenum = Column('DuctPlenum', Boolean)
    ducttype = Column('DuctType', String)
    ductsinconditioned = Column('DuctsInConditioned', Integer)
    ductsinunconditioned = Column('DuctsInUnconditioned', Integer)
    ductsreturninunconditioned = Column('DuctsReturnInUnconditioned', Integer)
    ductssupplyininaccessiblespace = Column('DuctsSupplyInInaccessibleSpace', Integer)
    ductspresent = Column('Ducts_Present', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfducts')

class SFDuctTestingDBase(Base):
    __tablename__ = 'SFducttesting_dbase'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    ductsit = Column('ducts_it', Integer)
    dbbothsidesflowexponentcalculated = Column('DB_BothSides_FlowExponent_Calculated', Float)
    dbonesideflowexponentcalculated = Column('DB_OneSide_FlowExponent_Calculated', Float)
    dbonesidewhichside = Column('DB_OneSide_WhichSide', String)
    dbbothsidesc = Column('DB_BothSides_C', Float)
    dbonesidec = Column('DB_OneSide_C', Float)
    supq50calc = Column('Sup_Q50_Calc', Float)
    retq50calc = Column('Ret_Q50_Calc', Float)
    supq25calc = Column('Sup_Q25_Calc', Float)
    retq25calc = Column('Ret_Q25_Calc', Float)
    trueflowstaticreturnpressure = Column('TrueFlow_Static_ReturnPressure', Float)
    trueflowstaticsupplypressure = Column('TrueFlow_Static_SupplyPressure', Float)
    trueflowstatictotalpressurecalculated = Column('TrueFlow_Static_TotalPressure_Calculated', Integer)
    trueflowcorrectionfactorcalculated = Column('TrueFlow_CorrectionFactor_Calculated', Float)
    trueflowcorrectedflowcalculated = Column('TrueFlow_CorrectedFlow_Calculated', Integer)
    trueflownotes = Column('TrueFlow_Notes', String)
    slfhalfplen = Column('slf_halfplen', Float)
    rlfhalfplen = Column('rlf_halfplen', Float)
    dbfantype = Column('DB_FanType', String)
    dbmajorityreturnlocation = Column('DB_MajorityReturnLocation', String)
    dbmajoritysupplylocation = Column('DB_MajoritySupplyLocation', String)
    dbremainderreturnlocation = Column('DB_RemainderReturnLocation', String)
    dbremaindersupplylocation = Column('DB_RemainderSupplyLocation', String)
    dbsqft = Column('DB_SqFt', Integer)
    dbwholehouse = Column('DB_WholeHouse', Boolean)
    summarysketchsqftcalculated = Column('SummarySketchSqFt_Calculated', Integer)
    ductsurfacereturnbranch = Column('DuctSurfaceReturnBranch', Float)
    ductsurfacereturnplenum = Column('DuctSurfaceReturnPlenum', Float)    
    ductsurfacesupplybranch = Column('DuctSurfaceSupplyBranch', Float)
    ductsurfacesupplyplenum = Column('DuctSurfaceSupplyPlenum', Float)
    ductsurfacereturnsqft = Column('DuctSurfaceReturnSqft', Float)
    ductsurfacesupplysqft = Column('DuctSurfaceSupplySqft', Float)
    ductsurfacetotalsqft = Column('DuctSurfaceTotalSqft', Float)
    dbnotes = Column('DB_Notes', String)
    dbbothsidestestfailed = Column('DB_BothSides_Testfailed', Boolean)
    dbonesidetestfailed = Column('DB_OneSide_Testfailed', Boolean)
    tftestfailed = Column('TF_Testfailed', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfducttestingdbase')    

class SFElectronics(Base):
    __tablename__ = 'SFelectronics'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomit = Column('room_it', Integer, ForeignKey('SFroom.room_it'))
    electronicsaudio = Column('Electronics_Audio', Integer)
    electronicschargers = Column('Electronics_Chargers', Integer)
    electronicscomputers = Column('Electronics_Computers', Integer)
    electronicsgames = Column('Electronics_Games', Integer)
    electronicssub = Column('Electronics_Sub', String)
    electronicssubpowered = Column('Electronics_Subpowered', Boolean)
    electronicstvs = Column('Electronics_TVs', Integer)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfelectronics')

class SFEnergySum(Base):
    __tablename__ = 'SFenergy_sum'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    gas = Column('gas', Boolean)
    gheat1y = Column('gheat1_y', Float)
    thmy = Column('thm_y', Float)
    thmnrmsel = Column('thm_nrm_sel', Float)
    thmnrmy = Column('thm_nrm_y', Float)
    gheatnrmy = Column('gheat_nrm_y', Float)
    eheat1y = Column('eheat1_y', Float)
    kwhy = Column('kwh_y', Float)
    kwhnrmsel = Column('kwh_nrm_sel', Float)
    kwhnrmy = Column('kwh_nrm_y', Float)
    eheatnrmy = Column('eheat_nrm_y', Float)
    kbtuy = Column('kBtu_y', Float)
    kbtunrmsel = Column('kBtu_nrm_sel', Float)
    binfuelwood = Column('bin_FuelWood', String)
    woodkbtu = Column('wood_kBtu', Integer)
    binfuelpellets = Column('bin_FuelPellets', String)
    pelletskbtu = Column('pellets_kBtu', Integer)
    binfueloil = Column('bin_FuelOil', String)
    oilkbtu = Column('oil_kBtu', Integer)
    binfuelpropane = Column('bin_FuelPropane', String)
    propanekbtu = Column('propane_kBtu', Integer)
    kbtuallother = Column('kBtu_all_other', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfenergysum', uselist=False))
    
class SFEnergySumTMY3(Base):
    __tablename__ = 'SFenergy_sum_TMY3'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    kwhnrmy = Column('kwh_nrm_y', Float)
    thmnrmy = Column('thm_nrm_y', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfenergysumtmy3', uselist=False))

class SFExhaustTest(Base):
    __tablename__ = 'SFexhausttest'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    testit = Column('test_it', Integer)
    venttype = Column('VentType', String)
    exhaustflowit = Column('exhaustflow_it', Integer)
    exhaustfanflow = Column('Exhaust_FanFlow', Integer)
    exhaustroom = Column('Exhaust_Room', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfexhausttest')

class SFExtWatts(Base):
    __tablename__ = 'SFext_watts'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    extwatts = Column('ExtWatts', Integer)
    extflag = Column('extflag', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfextwatts')

class SFExtLighting(Base):
    __tablename__ = 'SFextlighting'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    fixtureit = Column('fixture_it', Integer)
    generalnotes = Column('GeneralNotes', String)
    lightingfixturecontrol = Column('LightingFixtureControl', String)
    lightingfixturequantity = Column('LightingFixtureQuantity', Integer)
    lightingfixturetype = Column('LightingFixtureType', String)
    lightinglampcategory = Column('LightingLampCategory', String)
    lightinglamplength = Column('LightingLampLength', Integer)
    lightinglamptype = Column('LightingLampType', String)
    lightinglampsperfixture = Column('LightingLampsPerFixture', Integer)
    lightingwattsperlamp = Column('LightingWattsPerLamp', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfextlighting')

class SFExtRoomNotes(Base):
    __tablename__ = 'SFextroomnotes'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfextroomnotes', uselist=False))

class SFFlBasement(Base):
    __tablename__ = 'SFflbasement'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    basementit = Column('basement_it', Integer)
    basementslabheated = Column('BasementSlabHeated', Boolean)
    basementslabins = Column('BasementSlabIns', String)
    basementslabinsposition = Column('BasementSlabInsPosition', String)
    basementflooraboveins = Column('BasementFloorAboveIns', Boolean)
    basementfloorinsulation = Column('BasementFloorInsulation', String)
    basementfloorinsulationcond = Column('BasementFloorInsulationCond', Float)
    basementconditioned = Column('BasementConditioned', Boolean)
    basementfloorarea = Column('BasementFloorArea', Integer)
    basementfloorinsulationtype = Column('BasementFloorInsulationType', String)
    basementslabarea = Column('BasementSlabArea', Integer)
    basementslabperimeter = Column('BasementSlabPerimeter', Integer)
    generalnotes = Column('GeneralNotes', String)
    ubsmntslabperimfloor = Column('u_bsmntslabperimfloor', Float)
    ubsmntfloor = Column('u_bsmntfloor', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfflbasement')

class SFFlCantilever(Base):
    __tablename__ = 'SFflcantilever'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    cantileverit = Column('cantilever_it', Integer)
    stdfloorinsulation = Column('StdFloorInsulation', String)
    cantileverarea = Column('CantileverArea', Integer)
    ucantileverfloor = Column('u_cantileverfloor', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfflcantilever')

class SFFlCrawl(Base):
    __tablename__ = 'SFflcrawl'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    crawlit = Column('crawl_it', Integer)
    stdfloorinsulation = Column('StdFloorInsulation', String)
    stdfloorinsulationcondition = Column('StdFloorInsulationCondition', Float)
    crawlwallinsulated = Column('CrawlWallInsulated', Boolean)
    crawlwallinslevel = Column('CrawlWallInsLevel', String)
    crawlventspresent = Column('CrawlVentsPresent', Boolean)
    crawlventsblocked = Column('CrawlVentsBlocked', Boolean)
    crawlarea = Column('CrawlArea', Integer)
    crawlframing = Column('CrawlFraming', String)
    crawljoistsize = Column('CrawlJoistSize', String)
    crawlmoreinsulation = Column('CrawlMoreInsulation', Boolean)
    crawlwallinstype = Column('CrawlWallInsType', String)
    generalnotes = Column('GeneralNotes', String)
    stdfloorinsulationtype = Column('StdFloorInsulationType', String)
    ucrawlfloor = Column('u_crawlfloor', Float)
    ucrawlwall = Column('u_crawlwall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfflcrawl')

class SFFloorNotes(Base):
    __tablename__ = 'SFfloornotes'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    floorsnotes = Column('FloorsNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sffloornotes', uselist=False))

class SFFloorOverArea(Base):
    __tablename__ = 'SFflooroverarea'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    flooroverareait = Column('flooroverarea_it', Integer)
    stdfloorinsulation = Column('StdFloorInsulation', String)
    stdfloorinsulationcondition = Column('StdFloorInsulationCondition', Float)
    floorarea = Column('FloorArea', Integer)
    floorareabelow = Column('FloorAreaBelow', String)
    floorareaheated = Column('FloorAreaHeated', Boolean)
    floortype = Column('FloorType', String)
    stdfloorinsulationtype = Column('StdFloorInsulationType', String)
    uoverareafloor = Column('u_overareafloor', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfflooroverarea')

class SFFloorUA(Base):
    __tablename__ = 'SFfloorua'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    uafloor = Column('ua_floor', Float)
    elementspresent = Column('elements_present', String)
    elementsmissing = Column('elements_missing', String)
    baddata = Column('bad_data', Boolean)
    sfheatlossinclude = Column('sfheatlossinclude', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sffloorua')

class SFFlSlab(Base):
    __tablename__ = 'SFflslab'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    slabit = Column('slab_it', Integer)
    slabheated = Column('SlabHeated', Boolean)
    slabinsulated = Column('SlabInsulated', Boolean)
    slabinsulationlevel = Column('SlabInsulationLevel', String)
    slabinsulationposition = Column('SlabInsulationPosition', String)
    generalnotes = Column('GeneralNotes', String)
    slabperimeter = Column('SlabPerimeter', Integer)
    stdarea = Column('StdArea', Integer)
    uslabperimfloor = Column('u_slabperimfloor', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfflslab')

class SFFramedWall(Base):
    __tablename__ = 'SFframedwall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    framedwallit = Column('framedwall_it', Integer)
    framedtype = Column('FramedType', String)
    framedinslvl = Column('FramedInsLvl', String)
    framedinssheathing = Column('FramedInsSheathing', String)
    framedinstype = Column('FramedInsType', String)
    framedwallaltthickness = Column('FramedWallAltThickness', String)
    framedwallarea = Column('FramedWallArea', Integer)
    uframedwall = Column('u_framedwall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfframedwall')

class SFGame(Base):
    __tablename__ = 'SFgame'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomit = Column('room_it', Integer, ForeignKey('SFroom.room_it'))
    gameit = Column('game_it', Integer)
    gamebrand = Column('Game_Brand', String)
    gameinternet = Column('Game_Internet', Boolean)
    gamerelease = Column('Game_Release', String)
    gamevideoplayer = Column('Game_VideoPlayer', Boolean)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfgame')

class SFHvacNotes(Base):
    __tablename__ = 'SFhvacnotes'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    hvacnotes = Column('HVACNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfhvacnotes', uselist=False))

class SFIcfWall(Base):
    __tablename__ = 'SFicfwall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    icfwallthickness = Column('ICFWallThickness', String)
    icfarea = Column('ICFArea', Integer)
    icftype = Column('ICFType', String)
    generalnotes = Column('GeneralNotes', String)
    uicfwall = Column('u_icfwall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sficfwall')

class SFInfillWall(Base):
    __tablename__ = 'SFinfillwall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    generalnotes = Column('GeneralNotes', String)
    infillarea = Column('InfillArea', Integer)
    infillframetype = Column('InfillFrameType', String)
    infillinslvl = Column('InfillInsLvl', String)
    infillinsulationtype = Column('InfillInsulationType', String)
    infillrigidsheathing = Column('InfillRigidSheathing', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfinfillwall')

class SFLighting(Base):
    __tablename__ = 'SFlighting'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomit = Column('room_it', Integer, ForeignKey('SFroom.room_it'))
    fixtureit = Column('fixture_it', Integer)
    generalnotes = Column('GeneralNotes', String)
    lightingfixturecontrol = Column('LightingFixtureControl', String)
    lightingfixturequantity = Column('LightingFixtureQuantity', Integer)
    lightingfixturetype = Column('LightingFixtureType', String)
    lightinglampcategory = Column('LightingLampCategory', String)
    lightinglamplength = Column('LightingLampLength', Integer)
    lightinglamptype = Column('LightingLampType', String)
    lightinglampsperfixture = Column('LightingLampsPerFixture', Integer)
    lightingwattsperlamp = Column('LightingWattsPerLamp', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sflighting')

class SFLogWall(Base):
    __tablename__ = 'SFlogwall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    logthickness = Column('LogThickness', String)
    logarea = Column('LogArea', Integer)
    generalnotes = Column('GeneralNotes', String)
    ulogwall = Column('u_logwall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sflogwall')

class SFLrgUnusualLoad(Base):
    __tablename__ = 'SFlrg_unusual_load'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    loadit = Column('load_it', Integer)
    lulcode = Column('LUL_Code', String)
    lulnotes = Column('LUL_Notes', String)
    lulqty = Column('LUL_Qty', Integer)
    lullocation = Column('LUL_Location', String)
    lultype = Column('LUL_Type', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sflrgunusualload')    

class SFMasonryBasement(Base):
    __tablename__ = 'SFmasonrybasement'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    masonrybasementit = Column('masonrybasement_it', Integer)
    basementmasonwallinslvl = Column('BasementMasonWallInsLvl', String)
    basementmasonwallabovegrade = Column('BasementMasonWallAboveGrade', String)
    basementmasonwallarea = Column('BasementMasonWallArea', Integer)
    generalnotes = Column('GeneralNotes', String)
    ubsmntmasonrywall = Column('u_bsmntmasonrywall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfmasonrybasement')

class SFMasonryWall(Base):
    __tablename__ = 'SFmasonrywall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    masonryframinginslvl = Column('MasonryFramingInsLvl', String)
    masonryinsulated = Column('MasonryInsulated', Boolean)
    masonryframinginstype = Column('MasonryFramingInsType', String)
    generalnotes = Column('GeneralNotes', String)
    masonryarea = Column('MasonryArea', Integer)
    masonryframinginslvlexterior = Column('MasonryFramingInsLvlExterior', String)
    masonryframingsize = Column('MasonryFramingSize', String)
    masonryfurred = Column('MasonryFurred', Boolean)
    masonrytype = Column('MasonryType', String)
    umasonrywall = Column('u_masonrywall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfmasonrywall')
    
class SFOtherCeiling(Base):
    __tablename__ = 'SFotherceiling'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    otherceilinginsvalue = Column('OtherCeilingInsValue', String)
    generalnotes = Column('GeneralNotes', String)
    otherceilingarea = Column('OtherCeilingArea', Integer)
    otherceilingtype = Column('OtherCeilingType', String)
    uotherceil = Column('u_otherceil', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfotherceiling')
    
class SFOtherWall(Base):
    __tablename__ = 'SFotherwall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    framedinssheathing = Column('FramedInsSheathing', String)
    framedinstype = Column('FramedInsType', String)
    framedtype = Column('FramedType', String)
    otherinslevel = Column('OtherInsLevel', String)
    otherthickness = Column('OtherThickness', Float)
    otherwallarea = Column('OtherWallArea', Integer)
    otherwalltype = Column('OtherWallType', String)
    uotherwall = Column('u_otherwall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfotherwall')
    
class SFRefrig(Base):
    __tablename__ = 'SFrefrig'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    refrigeratorit = Column('refrigerator_it', Integer)
    generalnotes = Column('GeneralNotes', String)
    refestar = Column('RefEStar', Boolean)
    reficemaker = Column('RefIcemaker', String)
    reficemakerworks = Column('RefIcemakerWorks', Boolean)
    reflocation = Column('RefLocation', String)
    refmanufacturer = Column('RefManufacturer', String)
    refmodel = Column('RefModel', String)
    refstyle = Column('RefStyle', String)
    refuse = Column('RefUse', Float)
    refvolume = Column('RefVolume', Float)
    refyear = Column('RefYear', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfrefrig')
    
class SFRoofDeckCeiling(Base):
    __tablename__ = 'SFroofdeckceiling'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    rigidceilinginslvl = Column('RigidCeilingInsLvl', String)
    generalnotes = Column('GeneralNotes', String)
    rigidceilingarea = Column('RigidCeilingArea', Integer)
    urdeckceil = Column('u_rdeckceil', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfroofdeckceiling')
    
class SFRoom(Base):
    __tablename__ = 'SFroom'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomit = Column('room_it', Integer)
    roomsqft = Column('RoomSqFt', Integer)
    roomtype = Column('RoomType', String)
    roomconditioned = Column('Room_Conditioned', Boolean)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfroom')
    
class SFRoomLPD(Base):
    __tablename__ = 'SFroom_LPD'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomit = Column('room_it', Integer, ForeignKey('SFroom.room_it'))
    roomlpd = Column('RoomLPD', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfroomlpd')
    
class SFRoomsNotes(Base):
    __tablename__ = 'SFroomsnotes'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomslightingnotes = Column('RoomsLightingNotes', String)
    roomsplugloadnotes = Column('RoomsPlugLoadNotes', String)
    roomswindowsnotes = Column('Rooms_WindowsNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfroomsnotes', uselist=False))
    
class SFShowerhead(Base):
    __tablename__ = 'SFshowerhead'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    generalnotes = Column('GeneralNotes', String)
    shflow = Column('SHFlow', Float)
    shquantity = Column('SHQuantity', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfshowerhead', uselist=False))
    
class SFSipsWall(Base):
    __tablename__ = 'SFsipswall'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    sipthickness = Column('SIPThickness', String)
    generalnotes = Column('GeneralNotes', String)
    siparea = Column('SIPArea', Integer)
    usipswall = Column('u_sipswall', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfsipswall')
    
class SFSiteLPD(Base):
    __tablename__ = 'SFsite_LPD'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    houselpdsketch = Column('HouseLPD_Sketch', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfsitelpd')
    
class SFSiteUA(Base):
    __tablename__ = 'SFsite_UA'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    uaconductive = Column('ua_conductive', Float)
    baddata = Column('bad_data', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfsiteua')

class SFSkylight(Base):
    __tablename__ = 'SFskylight'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    skylightarea = Column('skylightarea', Integer)
    uskylight = Column('u_skylight', Float)
    sfskylitepanes = Column('SFskylitepanes', Integer)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfskylight')
    
class SFTV(Base):
    __tablename__ = 'SFtv'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    roomit = Column('room_it', Integer, ForeignKey('SFroom.room_it'))
    tvit = Column('tv_it', Integer)
    generalnotes = Column('GeneralNotes', String)
    tvage = Column('TV_Age', Integer)
    tvauxitems = Column('TV_AuxItems', Integer)
    tvbrand = Column('TV_Brand', String)
    tvmodel = Column('TV_Model', String)
    tvprimary = Column('TV_Primary', String)
    tvstb = Column('TV_STB', String)
    tvstbfullsize = Column('TV_STBFullSize', String)
    tvstbrecording = Column('TV_STBRecording', Boolean)
    tvstbyear = Column('TV_STBYear', Integer)
    tvsinglestrip = Column('TV_SingleStrip', Boolean)
    tvsize = Column('TV_Size', Integer)
    tvtype = Column('TV_Type', String)
    tvwatts = Column('TV_Watts', Integer)
    tvstbpresent = Column('TV_STBPresent', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sftv')

class SFVaultCeiling(Base):
    __tablename__ = 'SFvaultceiling'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    vaultceilingit = Column('vaultceiling_it', Integer)
    vaultinslvl = Column('VaultInsLvl', String)
    generalnotes = Column('GeneralNotes', String)
    vaultarea = Column('VaultArea', Integer)
    vaultframing = Column('VaultFraming', String)
    uvaultceil = Column('u_vaultceil', Float)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfvaultceiling')
    
class SFVentilation(Base):
    __tablename__ = 'SFventilation'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    testit = Column('test_it', Integer)
    venttype = Column('VentType', String)
    ventit = Column('vent_it', Integer)
    venthours = Column('VentHours', Float)
    ventcontrols = Column('VentControls', String)
    ventdescription = Column('VentDescription', String)
    ventworking = Column('VentWorking', Boolean)
    generalnotes = Column('GeneralNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfventilation')
    
class SFWallsNotes(Base):
    __tablename__ = 'SFwallsnotes'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    wallnotes = Column('WallNotes', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref=backref('sfwallsnotes', uselist=False))

class SFWallUA(Base):
    __tablename__ = 'SFwallua'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    uawall = Column('ua_wall', Float)
    elementspresent = Column('elements_present', String)
    elementsmissing = Column('elements_missing', String)
    baddata = Column('bad_data', Boolean)
    sfheatlossinclude = Column('sfheatlossinclude', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfwallua')
    
class SFWHeater(Base):
    __tablename__ = 'SFwheater'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    waterheaterit = Column('waterheater_it', Integer)
    whfuel = Column('WHFuel', String)
    generalnotes = Column('GeneralNotes', String)
    solarwaterheating = Column('SolarWaterheating', Boolean)
    whbrand = Column('WHBrand', String)
    whcapacitybtu = Column('WHCapacityBTU', Integer)
    whcapacitykw = Column('WHCapacityKW', Float)
    whclearance = Column('WHClearance', Boolean)
    whdraintype = Column('WHDrainType', String)
    whexhausttogarage = Column('WHExhaustToGarage', Boolean)
    whheatpump = Column('WHHeatPump', Boolean)
    whinconditionedspace = Column('WHInConditionedSpace', Boolean)
    whmanyear = Column('WHManYear', Integer)
    whneardrain = Column('WHNearDrain', Boolean)
    whroomover1000ft3 = Column('WHRoomOver1000ft3', Boolean)
    whsupplyair = Column('WHSupplyAir', Boolean)
    whtanksize = Column('WHTankSize', Integer)
    whtankwrap = Column('WHTankWrap', Boolean)
    whwholehouse = Column('WHWholeHouse', Boolean)
    waterheaterequipment = Column('WaterheaterEquipment', String)
    waterheaterlocation = Column('WaterheaterLocation', String)
    waterheaterpilot = Column('WaterheaterPilot', Boolean)
    waterheatertype = Column('WaterheaterType', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfwheater')
    
class SFWindow(Base):
    __tablename__ = 'SFwindow'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    windowtypeit = Column('windowtype_it', Integer)
    primarysecondary = Column('Primary_Secondary', String)
    windowarea = Column('windowArea', Integer)
    stormspresent = Column('storms_present', Boolean)
    windowtypeclass = Column('WindowTypeClass', String)
    uwindow = Column('u_window', Float)
    windowtype = Column('WindowType', String)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfwindow')
    
class SFWindowUA(Base):
    __tablename__ = 'SFwindowua'
    
    siteid = Column('siteid', Integer, ForeignKey('SFMaster_location.siteid'), primary_key=True)
    uawindow = Column('ua_window', Float)
    elementspresent = Column('elements_present', String)
    elementsmissing = Column('elements_missing', String)
    baddata = Column('bad_data', Boolean)
    sfheatlossinclude = Column('sfheatlossinclude', Boolean)
    
    sfmasterlocation = relationship('SFMasterLocation', backref='sfwindowua')
        
def main():
    db = os.path.abspath(os.path.join(curpath,'rbsa.sqlite'))
    session = create_session(db)
                
if __name__ == '__main__':
    main()