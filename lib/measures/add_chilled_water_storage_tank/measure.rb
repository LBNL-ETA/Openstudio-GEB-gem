# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddChilledWaterStorageTank < OpenStudio::Measure::ModelMeasure
  require 'json'
  require 'time'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add Chilled Water Storage Tank'
  end

  # human readable description
  def description
    return 'This measure adds a chilled water storage tank to a chilled water loop for the purpose of thermal energy storage.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure adds a chilled water storage tank and links it to an existing chilled water loop.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # inputs: (1) tank volume
    # if tank volume is given, use user-specific value, otherwise:
    # run sizing run first, and get the total cooling capacity of the chillers on the primary loop, based on which tank volume is sized.
    tank_vol = OpenStudio::Measure::OSArgument.makeDoubleArgument('tank_vol', false)
    tank_vol.setDisplayName('Thermal storage chilled water tank volume in m3')
    args << tank_vol

    # Make choice argument for energy storage objective
    objective = OpenStudio::Measure::OSArgument.makeChoiceArgument('objective', ['Full Storage', 'Partial Storage'], true)
    objective.setDisplayName('Select Energy Storage Objective:')
    objective.setDefaultValue('Partial Storage')
    args << objective

    # Make list of chilled water loop(s) from which user can select
    plant_loops = model.getPlantLoops
    loop_choices = OpenStudio::StringVector.new
    plant_loops.each do |loop|
      if loop.sizingPlant.loopType.to_s == 'Cooling'
        loop_choices << loop.name.to_s
      end
    end
    loop_choices << ""
    # Make choice argument for primary loop selection
    selected_primary_loop_name = OpenStudio::Measure::OSArgument.makeChoiceArgument('selected_primary_loop_name', loop_choices, false)
    selected_primary_loop_name.setDisplayName('Select Primary Loop:')
    selected_primary_loop_name.setDescription('This is the primary cooling loop on which the chilled water tank will be added.')
    pri_loop_name = nil
    loop_choices.each do |loop_name|
      pri_loop_name = loop_name if loop_name.downcase.include?('chilled water loop')
    end
    if !pri_loop_name.nil?
      selected_primary_loop_name.setDefaultValue(pri_loop_name)
    else
      selected_primary_loop_name.setDescription('Error: No Cooling Loop Found')
      selected_primary_loop_name.setDefaultValue("")
    end
    args << selected_primary_loop_name

    # TODO: In the future may have the need to add tank to existing secondary loop if any.
    # But need to check if the found secondary loop matches the selected primary loop
    # # Make choice argument for secondary loop selection
    # selected_secondary_loop = OpenStudio::Measure::OSArgument.makeChoiceArgument('selected_secondary_loop', loop_choices, false)
    # selected_secondary_loop.setDisplayName('Select Secondary Loop:')
    # selected_secondary_loop.setDescription('This is the secondary cooling loop on which the chilled water tank will be added.')
    # # Check if any loop includes string "secondary"
    # sec_loop = nil
    # loop_choices.each do |loop_name|
    #   sec_loop = loop_name if loop_name.include?('secondary')
    # end
    # if !sec_loop.nil?
    #   selected_secondary_loop.setDefaultValue(sec_loop)
    # else
    #   selected_secondary_loop.setDefaultValue(nil)
    # end
    # args << selected_secondary_loop

    # Make double argument for loop setpoint temperature
    primary_loop_sp = OpenStudio::Measure::OSArgument.makeDoubleArgument('primary_loop_sp', true)
    primary_loop_sp.setDisplayName('Primary Loop (charging) Setpoint Temperature degree C:')
    primary_loop_sp.setDefaultValue(6.7)
    args << primary_loop_sp

    # Make double argument for loop setpoint temperature
    secondary_loop_sp = OpenStudio::Measure::OSArgument.makeDoubleArgument('secondary_loop_sp', true)
    secondary_loop_sp.setDisplayName('Secondary Loop (discharging) Setpoint Temperature degree C:')
    # secondary_loop_sp.setDefaultValue(8.5)
    secondary_loop_sp.setDefaultValue(6.7)
    args << secondary_loop_sp

    # Make double argument for loop temperature for chilled water charging
    tank_charge_sp = OpenStudio::Measure::OSArgument.makeDoubleArgument('tank_charge_sp', true)
    tank_charge_sp.setDisplayName('Chilled Water Tank Setpoint Temperature degree C:')
    # tank_charge_sp.setDefaultValue(7.5)
    tank_charge_sp.setDefaultValue(6.7)
    args << tank_charge_sp

    # Make double argument for loop design delta T
    primary_delta_t = OpenStudio::Measure::OSArgument.makeStringArgument('primary_delta_t', true)
    primary_delta_t.setDisplayName('Loop Design Temperature Difference degree C:')
    primary_delta_t.setDescription('Enter numeric value to adjust selected loop settings.')
    primary_delta_t.setDefaultValue('Use Existing Loop Value')
    args << primary_delta_t

    # Make double argument for secondary loop design delta T
    secondary_delta_t = OpenStudio::Measure::OSArgument.makeDoubleArgument('secondary_delta_t', true)
    secondary_delta_t.setDisplayName('Secondary Loop Design Temperature Difference degree C')
    secondary_delta_t.setDefaultValue(4.5)
    args << secondary_delta_t

    # Make string argument for ctes seasonal availabilty
    thermal_storage_season = OpenStudio::Measure::OSArgument.makeStringArgument('thermal_storage_season', true)
    thermal_storage_season.setDisplayName('Enter Seasonal Availability of Chilled Water Storage:')
    thermal_storage_season.setDescription('Use MM/DD-MM/DD format, e.g., 04/01-10/31, default is full year.')
    thermal_storage_season.setDefaultValue('01/01-12/31')
    args << thermal_storage_season

    # Make string arguments for ctes discharge times
    discharge_start = OpenStudio::Measure::OSArgument.makeStringArgument('discharge_start', true)
    discharge_start.setDisplayName('Enter Starting Time for Chilled Water Tank Discharge:')
    discharge_start.setDescription('Use 24 hour format (HR:MM)')
    discharge_start.setDefaultValue('08:00')
    args << discharge_start

    discharge_end = OpenStudio::Measure::OSArgument.makeStringArgument('discharge_end', true)
    discharge_end.setDisplayName('Enter End Time for Chilled Water Tank Discharge:')
    discharge_end.setDescription('Use 24 hour format (HR:MM)')
    discharge_end.setDefaultValue('21:00')
    args << discharge_end

    # Make string arguments for ctes charge times
    charge_start = OpenStudio::Measure::OSArgument.makeStringArgument('charge_start', true)
    charge_start.setDisplayName('Enter Starting Time for Chilled Water Tank charge:')
    charge_start.setDescription('Use 24 hour format (HR:MM)')
    charge_start.setDefaultValue('23:00')
    args << charge_start

    charge_end = OpenStudio::Measure::OSArgument.makeStringArgument('charge_end', true)
    charge_end.setDisplayName('Enter End Time for Chilled Water Tank charge:')
    charge_end.setDescription('Use 24 hour format (HR:MM)')
    charge_end.setDefaultValue('07:00')
    args << charge_end

    # Make boolean arguments for thermal storage schedule on weekends
    wknds = OpenStudio::Measure::OSArgument.makeBoolArgument('wknds', true)
    wknds.setDisplayName('Allow Chilled Water Tank Work on Weekends')
    wknds.setDefaultValue(false)
    args << wknds

    # Output path, for sizing run
    run_output_path = OpenStudio::Measure::OSArgument.makePathArgument('run_output_path', true, "", false)
    run_output_path.setDisplayName('Output path for tank sizing run (if tank volume is not provided)')
    run_output_path.setDefaultValue(".")
    args << run_output_path

    # epw file path, for sizing run
    epw_path = OpenStudio::Measure::OSArgument.makePathArgument('epw_path', true, "", false)
    epw_path.setDisplayName('epw file path for tank sizing run (if tank volume is not provided)')
    args << epw_path

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    def run_osw(osw_path)
      cli_path = OpenStudio.getOpenStudioCLI
      cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
      puts cmd
      system(cmd)
    end

    # assign the user inputs to variables
    objective = runner.getStringArgumentValue('objective', user_arguments)
    selected_primary_loop_name = runner.getStringArgumentValue('selected_primary_loop_name', user_arguments)
    # if user_arguments['selected_primary_loop_name'].hasValue
    #   selected_primary_loop_name = runner.getStringArgumentValue('selected_primary_loop_name', user_arguments)
    if !selected_primary_loop_name.empty?
      # get the primary cooling loop
      selected_primary_loop = model.getModelObjectByName(selected_primary_loop_name)
      if selected_primary_loop.is_initialized
        selected_primary_loop = selected_primary_loop.get.to_PlantLoop.get
      else
        # The provided value is not a plant loop in the model
        runner.registerError("The provided primary loop name doesn't exist in the model.")
        return false
      end
    else
      loop_choices = []
      model.getPlantLoops.each do |loop|
        if loop.sizingPlant.loopType.to_s == 'Cooling'
          loop_choices << loop.name.to_s
        end
      end
      if loop_choices.empty?
        # No cooling loop; the measure is not applicable
        runner.registerAsNotApplicable("No cooling loop in the model. The measure is not applicable.")
        return true
      else
        # There is cooling loop in the model but user didn't specify one,
        # and the cooling loop name does not include 'chilled water loop'
        runner.registerError("Please select a primary loop name to run the measure. The available cooling loop(s) in the model is #{loop_choices.join(', ')}")
        return false
      end
    end
    primary_loop_sp = runner.getDoubleArgumentValue('primary_loop_sp', user_arguments)
    secondary_loop_sp = runner.getDoubleArgumentValue('secondary_loop_sp', user_arguments)
    tank_charge_sp = runner.getDoubleArgumentValue('tank_charge_sp', user_arguments)
    primary_delta_t = runner.getStringArgumentValue('primary_delta_t', user_arguments)
    secondary_delta_t = runner.getDoubleArgumentValue('secondary_delta_t', user_arguments)
    thermal_storage_season = runner.getStringArgumentValue('thermal_storage_season', user_arguments)
    discharge_start = runner.getStringArgumentValue('discharge_start', user_arguments)
    discharge_end = runner.getStringArgumentValue('discharge_end', user_arguments)
    charge_start = runner.getStringArgumentValue('charge_start', user_arguments)
    charge_end = runner.getStringArgumentValue('charge_end', user_arguments)
    wknds = runner.getBoolArgumentValue('wknds', user_arguments)


    # check time format
    begin
      discharge_start = Time.strptime(discharge_start, '%H:%M')
      discharge_end = Time.strptime(discharge_end, '%H:%M')
      charge_start = Time.strptime(charge_start, '%H:%M')
      charge_end = Time.strptime(charge_end, '%H:%M')
    rescue ArgumentError
      runner.registerError('Both discharge start and end time, charge start and end time are required, and should be in format of %H:%M, e.g., 16:00.')
      return false
    end

    # if_overnight: 1 or 0; wknds (if applicable to weekends): 1 or 0
    def create_sch(model, sch_name, start_time, end_time, thermal_storage_season, wknds)
      day_start_time = Time.strptime("00:00", '%H:%M')
      # create discharging schedule
      new_sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
      new_sch_ruleset.setName(sch_name)
      new_sch_ruleset.defaultDaySchedule.setName(sch_name + ' default')
      if start_time > end_time
        if_overnight = 1
      else
        if_overnight = 0
      end

      for min in 1..24*60
        if ((end_time - day_start_time)/60).to_i == min
          time = OpenStudio::Time.new(0, 0, min)
          new_sch_ruleset.defaultDaySchedule.addValue(time, 1)
        elsif ((start_time - day_start_time)/60).to_i == min
          time = OpenStudio::Time.new(0, 0, min)
          new_sch_ruleset.defaultDaySchedule.addValue(time, 0)
        elsif min == 24*60
          time = OpenStudio::Time.new(0, 0, min)
          new_sch_ruleset.defaultDaySchedule.addValue(time, if_overnight)
        end
      end

      date_range = thermal_storage_season.delete(' ').split('-')
      start_date = date_range[0].split('/')
      end_date = date_range[1].split('/')
      ts_rule = OpenStudio::Model::ScheduleRule.new(new_sch_ruleset, new_sch_ruleset.defaultDaySchedule)
      ts_rule.setName("#{new_sch_ruleset.name} #{start_date[0].to_i}/#{start_date[1].to_i}-#{end_date[0].to_i}/#{end_date[1].to_i} Rule")
      ts_rule.setStartDate(model.getYearDescription.makeDate(start_date[0].to_i, start_date[1].to_i))
      ts_rule.setEndDate(model.getYearDescription.makeDate(end_date[0].to_i, end_date[1].to_i))
      ts_rule.setApplyWeekdays(true)
      if wknds
        ts_rule.setApplyWeekends(true)
      else
        ts_rule.setApplyWeekends(false)
      end

      unless start_date[0].to_i == 1 && start_date[1].to_i == 1
        new_rule_day = OpenStudio::Model::ScheduleDay.new(model)
        new_rule_day.addValue(OpenStudio::Time.new(0,24), 0)
        new_rule = OpenStudio::Model::ScheduleRule.new(new_sch_ruleset, new_rule_day)
        new_rule.setName("#{new_sch_ruleset.name} 01/01-#{start_date[0]}/#{start_date[1]} Rule")
        new_rule.setStartDate(model.getYearDescription.makeDate(1, 1))
        new_rule.setEndDate(model.getYearDescription.makeDate(start_date[0].to_i, start_date[1].to_i))
        new_rule.setApplyAllDays(true)
      end

      unless end_date[0].to_i == 12 && end_date[1].to_i == 31
        new_rule_day = OpenStudio::Model::ScheduleDay.new(model)
        new_rule_day.addValue(OpenStudio::Time.new(0,24), 0)
        new_rule = OpenStudio::Model::ScheduleRule.new(new_sch_ruleset, new_rule_day)
        new_rule.setName("#{new_sch_ruleset.name} #{end_date[0].to_i}/#{end_date[1].to_i}-12/31 Rule")
        new_rule.setStartDate(model.getYearDescription.makeDate(end_date[0].to_i, end_date[1].to_i))
        new_rule.setEndDate(model.getYearDescription.makeDate(12, 31))
        new_rule.setApplyAllDays(true)
      end

      return new_sch_ruleset
    end

    if discharge_start > discharge_end
      runner.registerWarning('Dischage start time is later than discharge ' \
                             'end time (discharge overnight). Verify schedule inputs.')
    end

    if charge_start.between?(discharge_start, discharge_end) || charge_end.between?(discharge_start, discharge_end)
      runner.registerWarning('The tank charge and discharge periods overlap. ' \
                             'Examine results for unexpected operation; ' \
                             'verify schedule inputs.')
    end

    if objective == 'Full Storage'
      lasting_hrs = (discharge_end - discharge_start)/3600   # delta Time in second, convert to hours
    elsif objective == 'Partial Storage'
      lasting_hrs = (discharge_end - discharge_start)/3600/2.0
    else
      runner.registerError("Wrong energy storage objective input, can be either 'Full Storage' or 'Partial Storage'. ")
      return false
    end


    # report initial condition of model
    runner.registerInitialCondition("Original primary chilled water loop: #{selected_primary_loop.name}.")

    # Convert Delta T if needed from F to C (Overwrites string variables as floats)
    if primary_delta_t != 'Use Existing Loop Value' && primary_delta_t.to_f != 0.0
      primary_delta_t = primary_delta_t.to_f
    else
      # Could add additional checks here for invalid (non-numerical) entries
      primary_delta_t = selected_primary_loop.sizingPlant.loopDesignTemperatureDifference
    end

    # get the condenser water loop
    cw_loop = nil
    model.getPlantLoops.each do |loop|
      if loop.sizingPlant.loopType.to_s.downcase == 'condenser'
        cw_loop = loop if cw_loop.nil?
        # confirm if this condenser loop contains demand component of chiller that is in the selected_primary_loop
        common_comps = cw_loop.demandComponents & selected_primary_loop.supplyComponents
        chiller_in_both_loops = false
        common_comps.each do |comp|
          chiller_in_both_loops = true if comp.to_ChillerElectricEIR.is_initialized || comp.to_ChillerAbsorption.is_initialized || comp.to_ChillerAbsorptionIndirect.is_initialized
        end
        cw_loop = nil unless chiller_in_both_loops
      end
    end
    # not necessarily can find a cw_loop as the existing primary chiller might be air cooled.

    def hardsize_cooling_tower_two_speed(tower)
      # implement the applySizingValues function for CoolingTowerTwoSpeed here since it's not yet implemented in OS standards
      rated_water_flow_rate = tower.autosizedDesignWaterFlowRate
      if rated_water_flow_rate.is_initialized
        tower.setDesignWaterFlowRate(rated_water_flow_rate.get)
      end

      high_fan_speed_fan_power = tower.autosizedHighFanSpeedFanPower
      if high_fan_speed_fan_power.is_initialized
        tower.setHighFanSpeedFanPower(high_fan_speed_fan_power.get)
      end

      high_fan_speed_air_flow_rate = tower.autosizedHighFanSpeedAirFlowRate
      if high_fan_speed_air_flow_rate.is_initialized
        tower.setHighFanSpeedAirFlowRate(high_fan_speed_air_flow_rate.get)
      end

      high_fan_speed_u_factor_times_area_value = tower.autosizedHighFanSpeedUFactorTimesAreaValue
      if high_fan_speed_u_factor_times_area_value.is_initialized
        tower.setHighFanSpeedUFactorTimesAreaValue(high_fan_speed_u_factor_times_area_value.get)
      end

      low_fan_speed_air_flow_rate = tower.autosizedLowFanSpeedAirFlowRate
      if low_fan_speed_air_flow_rate.is_initialized
        tower.setLowFanSpeedAirFlowRate(low_fan_speed_air_flow_rate.get)
      end

      low_fan_speed_fan_power = tower.autosizedLowFanSpeedFanPower
      if low_fan_speed_fan_power.is_initialized
        tower.setLowFanSpeedFanPower(low_fan_speed_fan_power.get)
      end

      low_fan_speed_u_factor_times_area_value = tower.autosizedLowFanSpeedUFactorTimesAreaValue
      if low_fan_speed_u_factor_times_area_value.is_initialized
        tower.setLowFanSpeedUFactorTimesAreaValue(low_fan_speed_u_factor_times_area_value.get)
      end

      free_convection_regime_air_flow_rate = tower.autosizedFreeConvectionRegimeAirFlowRate
      if free_convection_regime_air_flow_rate.is_initialized
        tower.setFreeConvectionRegimeAirFlowRate(free_convection_regime_air_flow_rate.get)
      end

      free_convection_regime_u_factor_times_area_value = tower.autosizedFreeConvectionRegimeUFactorTimesAreaValue
      if free_convection_regime_u_factor_times_area_value.is_initialized
        tower.setFreeConvectionRegimeUFactorTimesAreaValue(free_convection_regime_u_factor_times_area_value.get)
      end
    end

    # if user provides this input, if not, do autosizing
    if user_arguments['tank_vol'].hasValue
      tank_vol = runner.getDoubleArgumentValue('tank_vol', user_arguments)
      if cw_loop
        # autosize cooling tower in the condenser loop to avoid invalid hard-sized parameters
        cw_loop.supplyComponents.each do |comp|
          if comp.to_CoolingTowerSingleSpeed.is_initialized
            cooling_tower = comp.to_CoolingTowerSingleSpeed.get
            cooling_tower.autosizeDesignWaterFlowRate
            cooling_tower.autosizeFanPoweratDesignAirFlowRate
            cooling_tower.autosizeDesignAirFlowRate
            cooling_tower.autosizeUFactorTimesAreaValueatDesignAirFlowRate
            cooling_tower.autosizeAirFlowRateinFreeConvectionRegime
            cooling_tower.autosizeUFactorTimesAreaValueatFreeConvectionAirFlowRate
            runner.registerInfo("CoolingTowerSingleSpeed #{cooling_tower.name} has been set to autosize.")
          elsif comp.to_CoolingTowerTwoSpeed.is_initialized
            cooling_tower = comp.to_CoolingTowerTwoSpeed.get
            cooling_tower.autosizeDesignWaterFlowRate
            cooling_tower.autosizeHighFanSpeedFanPower
            cooling_tower.autosizeHighFanSpeedAirFlowRate
            cooling_tower.autosizeHighFanSpeedUFactorTimesAreaValue
            cooling_tower.autosizeLowFanSpeedAirFlowRate
            cooling_tower.autosizeLowFanSpeedFanPower
            cooling_tower.autosizeLowFanSpeedUFactorTimesAreaValue
            cooling_tower.autosizeFreeConvectionRegimeAirFlowRate
            cooling_tower.autosizeFreeConvectionRegimeUFactorTimesAreaValue
            runner.registerInfo("CoolingTowerTwoSpeed #{cooling_tower.name} has been set to autosize.")
          elsif comp.to_CoolingTowerVariableSpeed.is_initialized
            cooling_tower = comp.to_CoolingTowerVariableSpeed.get
            cooling_tower.autosize
            runner.registerInfo("CoolingTowerVariableSpeed #{cooling_tower.name} has been set to autosize.")
          end
        end
      end
    else
      # unless user_arguments['run_output_path'].hasValue
      #   runner.registerError("Need to provide run output path for sizing run of tank volume. ")
      #   return false
      # end
      run_output_path = runner.getPathArgumentValue('run_output_path', user_arguments)
      Dir.mkdir(run_output_path.to_s) unless File.exists?(run_output_path.to_s)
      sizing_output_path = File.expand_path(File.join(run_output_path.to_s, 'sizing_run'))
      Dir.mkdir(sizing_output_path.to_s) unless File.exists?(sizing_output_path.to_s)

      # Change the simulation to only run the sizing days
      sim_control = model.getSimulationControl
      sim_control.setRunSimulationforSizingPeriods(true)
      sim_control.setRunSimulationforWeatherFileRunPeriods(false)

      sizing_osw_path = File.join(sizing_output_path.to_s, 'sizing.osm')
      model.save(sizing_osw_path, true)  # true is overwrite

      if File.exist?(model.weatherFile.get.path.get.to_s)
        epw_path = model.weatherFile.get.path.get
      else
        unless user_arguments['epw_path'].hasValue
          runner.registerError("Need to provide epw file path for sizing run of tank volume, the current epw file specified in osm cannot be found. ")
          return false
        end
        epw_path = runner.getPathArgumentValue('epw_path', user_arguments)
      end

      # create_osw for sizing
      osw = {}
      osw["weather_file"] = epw_path
      osw["seed_file"] = sizing_osw_path
      osw_path = File.join(sizing_output_path.to_s, "sizing.osw")
      File.open(osw_path, 'w') do |f|
        f << JSON.pretty_generate(osw)
      end
      model.resetSqlFile
      run_osw(osw_path)
      sleep(1)
      sql_path = OpenStudio::Path.new(File.join(sizing_output_path.to_s, "run", "eplusout.sql"))
      if OpenStudio.exists(sql_path)
        sql = OpenStudio::SqlFile.new(sql_path)
        unless sql.connectionOpen
          runner.registerError("The sizing run failed without valid a sql file. Look at the eplusout.err file in #{File.dirname(sql_path.to_s)} to see the cause.")
          return false
        end
        # Attach the sql file from the run to the model
        model.setSqlFile(sql)
      end

      total_cooling_cap = 0  # initial
      selected_primary_loop.supplyComponents.each do |comp|
        if comp.to_ChillerElectricEIR.is_initialized
          total_cooling_cap += comp.to_ChillerElectricEIR.get.autosizedReferenceCapacity.get
        elsif comp.to_ChillerAbsorption.is_initialized
          total_cooling_cap += comp.to_ChillerAbsorption.get.autosizedNominalCapacity.get
        elsif comp.to_ChillerAbsorptionIndirect.is_initialized
          total_cooling_cap += comp.to_ChillerAbsorptionIndirect.get.autosizedNominalCapacity.get
        end
      end
      if cw_loop
        # hard size cooling tower in the condenser loop
        cw_loop.supplyComponents.each do |comp|
          if comp.to_CoolingTowerSingleSpeed.is_initialized
            cooling_tower = comp.to_CoolingTowerSingleSpeed.get
            cooling_tower.applySizingValues
            runner.registerInfo("Autosized parameters from the sizing run have been set to CoolingTowerSingleSpeed #{cooling_tower.name}")
          elsif comp.to_CoolingTowerTwoSpeed.is_initialized
            cooling_tower = comp.to_CoolingTowerTwoSpeed.get
            hardsize_cooling_tower_two_speed(cooling_tower)
            runner.registerInfo("Autosized parameters from the sizing run have been set to CoolingTowerTwoSpeed #{cooling_tower.name}")
          elsif comp.to_CoolingTowerVariableSpeed.is_initialized
            cooling_tower = comp.to_CoolingTowerVariableSpeed.get
            cooling_tower.applySizingValues
            runner.registerInfo("Autosized parameters from the sizing run have been set to CoolingTowerVariableSpeed #{cooling_tower.name}")
          end
        end
      end

      # assuming average load ratio of chiller is 1/3 throughout the day
      tank_vol = total_cooling_cap/3.0 * 3600 * lasting_hrs / (4182 * 1000 * secondary_delta_t)  # heat capacity of water 4182J/kg.K, water density 1000g/m3, lasting 8 hours
    end
    
    # change back to normal run
    sim_control = model.getSimulationControl
    sim_control.setRunSimulationforSizingPeriods(false)
    sim_control.setRunSimulationforWeatherFileRunPeriods(true)

    sec_loop = OpenStudio::Model::PlantLoop.new(model)
    sec_loop.setName("Chilled Water Secondary Loop")
    selected_primary_loop.setName("Chilled Water Primary Loop")
    sizing_sec_plant = sec_loop.sizingPlant
    sizing_sec_plant.setLoopType('Cooling')
    sizing_sec_plant.setDesignLoopExitTemperature(tank_charge_sp)
    sizing_sec_plant.setLoopDesignTemperatureDifference(secondary_delta_t)
    sizing_pri_plant = selected_primary_loop.sizingPlant
    sizing_pri_plant.setLoopType('Cooling')
    sizing_pri_plant.setDesignLoopExitTemperature(primary_loop_sp)
    sizing_pri_plant.setLoopDesignTemperatureDifference(primary_delta_t)

    # add chilled water tank to the primary loop as demand and secondary loop as supply
    chw_storage_tank = OpenStudio::Model::ThermalStorageChilledWaterStratified.new(model)
    tank_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    tank_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), tank_charge_sp)
    chw_storage_tank.setTankVolume(tank_vol)
    chw_storage_tank.setSetpointTemperatureSchedule(tank_temp_sch)
    sec_loop.addSupplyBranchForComponent(chw_storage_tank)
    selected_primary_loop.addDemandBranchForComponent(chw_storage_tank)

    # create discharging and charging schedule and apply to chilled water tank and primary loop
    discharge_sch = create_sch(model, 'Chilled water tank discharge schedule', discharge_start, discharge_end, thermal_storage_season, wknds)
    charge_sch = create_sch(model, 'Chilled water tank charge schedule', charge_start, charge_end, thermal_storage_season, wknds)
    chw_storage_tank.setUseSideAvailabilitySchedule(discharge_sch)
    chw_storage_tank.setSourceSideAvailabilitySchedule(charge_sch)
    avm_sch =  OpenStudio::Model::AvailabilityManagerScheduled.new(model)
    avm_sch.setSchedule(charge_sch)
    selected_primary_loop.addAvailabilityManager(avm_sch)

    if objective == "Partial Storage"
      sec_chiller = OpenStudio::Model::ChillerElectricEIR.new(model)  # use default curves
      sec_chiller.setName("CoolSysSecondary Chiller")
      sec_loop.addSupplyBranchForComponent(sec_chiller)
      if cw_loop.nil?
        sec_chiller.setCondenserType("AirCooled")
      else
        sec_chiller.setCondenserType("WaterCooled")
        cw_loop.addDemandBranchForComponent(sec_chiller)
      end

      # add plant equipment operation schema if partial storage
      clg_op_scheme_tank = OpenStudio::Model::PlantEquipmentOperationCoolingLoad.new(model)
      clg_op_scheme_tank.addEquipment(chw_storage_tank)
      clg_op_scheme_sec_chiller = OpenStudio::Model::PlantEquipmentOperationCoolingLoad.new(model)
      clg_op_scheme_sec_chiller.addEquipment(sec_chiller)
      undischarge_sch = create_sch(model, 'Chilled water tank not discharge schedule', discharge_end, discharge_start, thermal_storage_season, wknds)
      # in this way, sequence in E+ will be tank first then chiller. In fact the sequence here doesn't matter as each schema is coupled with schedule
      sec_loop.setPlantEquipmentOperationCoolingLoad(clg_op_scheme_tank)
      sec_loop.setPlantEquipmentOperationCoolingLoadSchedule(discharge_sch)
      sec_loop.setPrimaryPlantEquipmentOperationScheme(clg_op_scheme_sec_chiller)
      sec_loop.setPrimaryPlantEquipmentOperationSchemeSchedule(undischarge_sch)

      # clg_op_scheme = OpenStudio::Model::PlantEquipmentOperationCoolingLoad.new(model)
      # tank_supply_watt = 2.0 * (4182 * tank_vol * 1000 * secondary_delta_t / (3600 * lasting_hrs))   # double the cooling cap in case thermal storage is not used at larger cooling load.
      # # the sequence of addEquipment and addLoadRange can't be switched
      # clg_op_scheme.addEquipment(sec_chiller)
      # clg_op_scheme.addLoadRange(tank_supply_watt, [chw_storage_tank])
      # sec_loop.setPlantEquipmentOperationCoolingLoad(clg_op_scheme)
    end
    # add secondary loop bypass pipe
    sec_supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    sec_supply_bypass.setName("Chilled Water Secondary Loop Supply Bypass Pipe")
    sec_loop.addSupplyBranchForComponent(sec_supply_bypass)

    # move all primary loop demand components (except inlet and outlet pipes) to the secondary loop
    selected_primary_loop.demandComponents(selected_primary_loop.demandSplitter, selected_primary_loop.demandMixer).each do |demand_comp|
      if demand_comp.to_StraightComponent.is_initialized
        next if demand_comp.to_Node.is_initialized || demand_comp.to_PipeAdiabatic.is_initialized
        demand_comp.to_StraightComponent.get.removeFromLoop
        sec_loop.addDemandBranchForComponent(demand_comp.to_StraightComponent.get)
      elsif demand_comp.to_WaterToAirComponent.is_initialized
        demand_comp.to_WaterToAirComponent.get.removeFromPlantLoop
        sec_loop.addDemandBranchForComponent(demand_comp.to_WaterToAirComponent.get)
      elsif demand_comp.to_WaterToWaterComponent.is_initialized
        next if demand_comp.to_ThermalStorageChilledWaterStratified.is_initialized  # skip the newly added chilled water tank
        demand_comp.to_WaterToWaterComponent.get.removeFromPlantLoop
        sec_loop.addDemandBranchForComponent(demand_comp.to_WaterToWaterComponent.get)
      end
    end

    # move pump from demand component if any to secondary loop
    selected_primary_loop.demandComponents.each do |comp|
      if comp.to_PumpConstantSpeed.is_initialized
        comp.to_PumpConstantSpeed.get.removeFromLoop
        comp.to_PumpConstantSpeed.get.addToNode(sec_loop.demandInletNode)
      elsif comp.to_PumpVariableSpeed.is_initialized
        comp.to_PumpVariableSpeed.get.removeFromLoop
        comp.to_PumpVariableSpeed.get.addToNode(sec_loop.demandInletNode)
      end
    end

    # set common pipe simulation to "None", meaning primary-only, not mixing primary and secondary in one loop.
    selected_primary_loop.setCommonPipeSimulation("None")
    sec_loop.setCommonPipeSimulation("None")

    # add node setpoint manager
    pri_supply_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    pri_supply_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), primary_loop_sp)
    sec_supply_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    sec_supply_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), secondary_loop_sp)

    chw_pri_supply_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, pri_supply_temp_sch)
    chw_pri_supply_stpt_manager.addToNode(selected_primary_loop.supplyOutletNode)
    chw_sec_supply_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, sec_supply_temp_sch)
    chw_sec_supply_stpt_manager.addToNode(sec_loop.supplyOutletNode)

    # echo the new space's name back to the user
    runner.registerInfo("Chilled water tank #{chw_storage_tank.name} was added.")

    # report final condition of model
    runner.registerFinalCondition("The building finished with new chilled water tank #{chw_storage_tank.name} added to the chilled water loop #{selected_primary_loop.name}.")

    return true
  end
end

# register the measure to be used by the application
AddChilledWaterStorageTank.new.registerWithApplication
