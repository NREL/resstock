# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ResidentialPhotovoltaics < OpenStudio::Ruleset::ModelUserScript

  class PVSystem
    def initialize
    end
    attr_accessor(:derate, :derated_num_modules, :inv_tare_loss, :inv_capacity_factor)   
  end
  
  class PVAzimuth
    def initialize
    end
    attr_accessor(:abs)
  end

  class PVTilt
    def initialize   
    end
    attr_accessor(:abs)
  end

  # human readable name
  def name
    return "Set Residential Photovoltaics"
  end

  # human readable description
  def description
    return "This measure..."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Uses..."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for size
    size = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("size", false)
    size.setDisplayName("Size")
    size.setUnits("kW")
    size.setDescription("Size (power) per unit of the photovoltaic array in kW DC.")
    size.setDefaultValue(2.5)
    args << size
    
    #make a choice arguments for module type
    module_types_names = OpenStudio::StringVector.new
    module_types_names << Constants.PVModuleTypeCSI
    module_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("module_type", module_types_names, true)
    module_type.setDisplayName("Module Type")
    module_type.setDescription("Type of module to use for the PV simulation.")
    module_type.setDefaultValue(Constants.PVModuleTypeCSI)
    args << module_type

    #make a double argument for system losses
    system_losses = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("system_losses", false)
    system_losses.setDisplayName("System Losses")
    system_losses.setUnits("frac")
    system_losses.setDescription("Difference between theoretical module-level and actual PV system performance due to wiring resistance losses, dust, module mismatch, etc.")
    system_losses.setDefaultValue(0.14)
    args << system_losses
    
    #make a double argument for inverter efficiency
    inverter_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("inverter_efficiency", false)
    inverter_efficiency.setDisplayName("Inverter Efficiency")
    inverter_efficiency.setUnits("frac")
    inverter_efficiency.setDescription("The efficiency of the inverter.")
    inverter_efficiency.setDefaultValue(0.96)
    args << inverter_efficiency
    
    #make a choice arguments for azimuth type
    azimuth_types_names = OpenStudio::StringVector.new
    azimuth_types_names << Constants.CoordRelative
    azimuth_types_names << Constants.CoordAbsolute
    azimuth_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("azimuth_type", azimuth_types_names, true)
    azimuth_type.setDisplayName("Azimuth Type")
    azimuth_type.setDescription("Relative azimuth angle is measured clockwise from the front of the house. Absolute azimuth angle is measured clockwise from due south.")
    azimuth_type.setDefaultValue(Constants.CoordRelative)
    args << azimuth_type    
    
    #make a double argument for azimuth
    azimuth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("azimuth", false)
    azimuth.setDisplayName("Azimuth")
    azimuth.setUnits("degrees")
    azimuth.setDescription("The azimuth angle is measured clockwise.")
    azimuth.setDefaultValue(0)
    args << azimuth
    
    #make a choice arguments for tilt type
    tilt_types_names = OpenStudio::StringVector.new
    tilt_types_names << Constants.TiltPitch
    tilt_types_names << Constants.CoordAbsolute
    tilt_types_names << Constants.TiltLatitude
    tilt_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("tilt_type", tilt_types_names, true)
    tilt_type.setDisplayName("Tilt Type")
    tilt_type.setDescription("Type of tilt angle referenced.")
    tilt_type.setDefaultValue(Constants.TiltPitch)
    args << tilt_type      
    
    #make a double argument for tilt
    tilt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("tilt", false)
    tilt.setDisplayName("Tilt")
    tilt.setUnits("degrees")
    tilt.setDescription("Angle of the tilt.")
    tilt.setDefaultValue(0)
    args << tilt
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    size = runner.getDoubleArgumentValue("size",user_arguments)
    module_type = runner.getStringArgumentValue("module_type",user_arguments)
    system_losses = runner.getDoubleArgumentValue("system_losses",user_arguments)
    inverter_efficiency = runner.getDoubleArgumentValue("inverter_efficiency",user_arguments)
    azimuth_type = runner.getStringArgumentValue("azimuth_type",user_arguments)
    azimuth = runner.getDoubleArgumentValue("azimuth",user_arguments)
    tilt_type = runner.getStringArgumentValue("tilt_type",user_arguments)
    tilt = runner.getDoubleArgumentValue("tilt",user_arguments)
    
    if azimuth > 360 or azimuth < 0
      runner.registerError("Invalid azimuth entered.")
      return false
    end	    
    
    pv_system = PVSystem.new
    pv_azimuth = PVAzimuth.new
    pv_tilt = PVTilt.new
    
    @weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if @weather.error?
      return false
    end
    
    pv_module = _getPVModuleCharacteristics(module_type)
    if pv_module.nil?
      return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    # Calculate number of PV modules (Should we round to the nearest integer?)    
    pv_system.derated_num_modules = OpenStudio::convert(size,"kW","W").get / (pv_module["Impo"] * pv_module["Vmpo"]) * (1.0 - system_losses)
    
    highest_roof_pitch = Geometry.get_roof_pitch(model.getSurfaces)
    pv_tilt.abs = get_abs_tilt(tilt_type, tilt, highest_roof_pitch, @weather.header.Latitude)
    
    if azimuth_type == Constants.CoordRelative
      pv_azimuth.abs = azimuth + model.getBuilding.northAxis
    elsif azimuth_type == Constants.CoordAbsolute
      pv_azimuth.abs = azimuth
    end
    
    pv_system.inv_tare_loss = 0.003
    pv_system.inv_capacity_factor = 1.2
    
    # Ensure Azimuth is >=0 and <=360
    if pv_azimuth.abs < 0.0
      pv_azimuth.abs += 360.0
    end

    if pv_azimuth.abs >= 360.0
      pv_azimuth.abs -= 360.0
    end

    panel_length = (pv_module["Area"] * pv_system.derated_num_modules) ** 0.5
    run = Math::cos(Math::atan(pv_tilt.abs)) * panel_length
    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(OpenStudio::convert(100.0,"ft","m").get, OpenStudio::convert(100.0,"ft","m").get, 0)
    vertices << OpenStudio::Point3d.new(OpenStudio::convert(100.0,"ft","m").get + panel_length * units.length, OpenStudio::convert(100.0,"ft","m").get, 0)
    vertices << OpenStudio::Point3d.new(OpenStudio::convert(100.0,"ft","m").get + panel_length * units.length, OpenStudio::convert(100.0,"ft","m").get + run, pv_tilt.abs * run)
    vertices << OpenStudio::Point3d.new(OpenStudio::convert(100.0,"ft","m").get, OpenStudio::convert(100.0,"ft","m").get + run, pv_tilt.abs * run)
    
    m = OpenStudio::Matrix.new(4,4,0)
    m[0,0] = Math::cos(-pv_azimuth.abs * Math::PI / 180.0)
    m[1,1] = Math::cos(-pv_azimuth.abs * Math::PI / 180.0)
    m[0,1] = -Math::sin(-pv_azimuth.abs * Math::PI / 180.0)
    m[1,0] = Math::sin(-pv_azimuth.abs * Math::PI / 180.0)
    m[2,2] = 1
    m[3,3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices
    
    shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    shading_surface_group.setName("PV Panel")
    shading_surface = OpenStudio::Model::ShadingSurface.new(vertices, model)
    shading_surface.setName("PV Panel")
    shading_surface.setShadingSurfaceGroup(shading_surface_group)      

    inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
    inverter.setName("PV Inverter")
    inverter.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    inverter.setInverterEfficiency(inverter_efficiency)
    
    electric_load_center_dist = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    electric_load_center_dist.setName("Electric Load Center")
    electric_load_center_dist.setInverter(inverter)
    electric_load_center_dist.setGeneratorOperationSchemeType("Baseload")
    electric_load_center_dist.setElectricalBussType("DirectCurrentWithInverter")

    panel = OpenStudio::Model::GeneratorPhotovoltaic::simple(model)
    panel.setName("PV System")
    panel.setSurface(shading_surface)
    panel.setHeatTransferIntegrationMode("Decoupled")
    panel.setNumberOfModulesInParallel(1)
    panel.setNumberOfModulesInSeries(pv_system.derated_num_modules)
    panel.setRatedElectricPowerOutput(OpenStudio::convert(size,"kW","W").get)
    panel.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    performance = panel.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
    performance.setName("PV Module")
    performance.setFractionOfSurfaceAreaWithActiveSolarCells(1)
    performance.setFixedEfficiency(1)

    electric_load_center_dist.addGenerator(panel)
    
    runner.registerInfo("Added #{OpenStudio::convert(panel_length ** 2,"m^2","ft^2").get.round(1)} square feet of PV.")
    
    return true

  end
  
  def _getPVModuleCharacteristics(module_type)
  
    modules_csv = File.join(File.dirname(__FILE__), "resources", 'Modules.csv')
    modules_csvlines = []
    File.open(modules_csv) do |file|
      file.each do |line|
        line = line.strip.chomp.chomp(',').chomp(',').chomp # remove RHS whitespace and extra commas
        modules_csvlines << line
      end
    end

    pv_module = nil
    modules_csvlines[1..-1].each_with_index do |line, i|
      pv_module = Hash[modules_csvlines[0].split(',').zip(line.split(','))]
      break if pv_module["Material"].downcase == module_type
    end
    
    if pv_module.nil?
      runner.registerError("Could not find PV module characteristics.")
    else
      pv_module["Impo"] = pv_module["Impo"].to_f
      pv_module["Vmpo"] = pv_module["Vmpo"].to_f
      pv_module["Area"] = pv_module["Area"].to_f
    end
    
    return pv_module
  
  end
  
  def get_abs_tilt(tiltType, relative_tilt, highest_roof_pitch, latitude)
    if tiltType == Constants.TiltPitch
      return relative_tilt + highest_roof_pitch
    elsif tiltType == Constants.TiltLatitude
      return relative_tilt + latitude
    elsif tiltType == Constants.CoordAbsolute
      return relative_tilt
    end
  end
  
end

# register the measure to be used by the application
ResidentialPhotovoltaics.new.registerWithApplication
