require 'csv'

class SchedulesFile
  def initialize(runner:,
                 model:,
                 schedules_output_path: nil,
                 num_bedrooms: nil,
                 num_occupants: nil,
                 **remainder)

    @validated = true
    @runner = runner
    @model = model
    @schedules_output_path = schedules_output_path
    @num_bedrooms = num_bedrooms
    @num_occupants = num_occupants

    @schedules = {}
    if File.exist? @schedules_output_path
      @external_file = import
    end
  end

  def validated?
    return @validated
  end

  def create_occupant_schedule
    return false if @num_occupants.nil?

    @schedules['occupants'] = Array.new(8760) { rand }

    return true
  end

  def create_refrigerator_schedule
    @schedules['refrigerator'] = Array.new(8760) { rand }

    return true
  end

  def schedules
    return @schedules
  end

  def external_file
    return @external_file
  end

  def get_col_index(col_name:)
    headers = CSV.open(@schedules_output_path, 'r') { |csv| csv.first }
    col_num = headers.index(col_name)
    return col_num
  end

  def createScheduleFile(sch_file_name:,
                         col_name:,
                         rows_to_skip: 1)

    if @schedules[col_name].nil?
      @runner.registerError("Could not find the '#{col_name}' schedule.")
      return false
    end

    col_index = get_col_index(col_name: col_name)
    year_description = @model.getYearDescription
    num_hrs_in_year = Constants.NumHoursInYear(year_description.isLeapYear)
    schedule_length = @schedules[col_name].length
    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)

    schedule_file = OpenStudio::Model::ScheduleFile.new(@external_file)
    schedule_file.setName(sch_file_name)
    schedule_file.setColumnNumber(col_index + 1)
    schedule_file.setRowstoSkipatTop(rows_to_skip)
    schedule_file.setNumberofHoursofData(num_hrs_in_year.to_i)
    schedule_file.setMinutesperItem("#{min_per_item.to_i}")

    return schedule_file
  end

  def annual_equivalent_full_load_hrs(col_name:)
    year_description = @model.getYearDescription
    num_hrs_in_year = Constants.NumHoursInYear(year_description.isLeapYear)
    schedule_length = @schedules[col_name].length
    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)

    ann_equiv_full_load_hrs = @schedules[col_name].reduce(:+) / (60.0 / min_per_item)

    return ann_equiv_full_load_hrs
  end

  def calcDesignLevelFromAnnualkWh(col_name:,
                                   annual_kwh:)

    ann_equiv_full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    design_level = annual_kwh * 1000.0 / ann_equiv_full_load_hrs # W

    return design_level
  end

  def calcDesignLevelFromAnnualTherm(col_name:,
                                     annual_therm:)

    annual_kwh = UnitConversions.convert(annual_therm, 'therm', 'kWh')
    design_level = calcDesignLevelFromAnnualkWh(col_name: col_name, annual_kwh: annual_kwh)

    return design_level
  end

  def calcPeakFlowFromDailygpm(col_name:,
                               gpd:)

    peak_flow = 0.00027469463117786927 # FIXME: use the HotWaterMinuteDrawProfilesMaxFlows.csv lookup for these?

    return peak_flow
  end

  def validateSchedule(col_name:,
                       values:)

    year_description = @model.getYearDescription
    num_hrs_in_year = Constants.NumHoursInYear(year_description.isLeapYear)
    schedule_length = values.length

    if values.max > 1
      @runner.registerError("The max value of schedule '#{col_name}' is greater than 1.")
      @validated = false
    end

    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)
    unless [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60].include? min_per_item
      @runner.registerError("Calculated an invalid schedule min_per_item=#{min_per_item}.")
      @validated = false
    end
  end

  def import
    columns = CSV.read(@schedules_output_path).transpose
    columns.each do |col|
      col_name = col[0]
      values = col[1..-1].reject { |v| v.nil? }
      values = values.map { |v| v.to_f }
      validateSchedule(col_name: col_name, values: values)
      @schedules[col_name] = values
    end

    external_file = OpenStudio::Model::ExternalFile::getExternalFile(@model, @schedules_output_path)
    if external_file.is_initialized
      external_file = external_file.get
      external_file.setName(external_file.fileName)
    end

    return external_file
  end

  def export
    return false if @schedules_output_path.nil?

    CSV.open(@schedules_output_path, 'wb') do |csv|
      csv << @schedules.keys
      rows = @schedules.values.transpose
      rows.each do |row|
        csv << row
      end
    end

    return true
  end
end
