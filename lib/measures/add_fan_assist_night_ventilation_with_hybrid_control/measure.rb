# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddFanAssistNightVentilationWithHybridControl < OpenStudio::Measure::ModelMeasure
  require 'time'
  require 'json'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add fan assist night ventilation with hybrid control'
  end

  # human readable description
  def description
    return 'This measure is modified based on the OS measure "fan_assist_night_ventilation" from "openstudio-ee-gem".  ' \
           'It adds night ventilation that is enabled by opening windows assisted by exhaust fans. Hybrid ventilation  ' \
           'control is added to avoid simultaneous operation of windows and HVAC.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure adds a zone ventilation object to each zone with operable windwos. The measure will first  " \
           "look for a celing opening to find a connection for zone a zone mixing object. If a ceiling isn't found,  " \
           "then it looks for a wall. The end result is zone ventilation object followed by a path of zone mixing objects.  " \
           "The exhaust fan consumption is modeled in the zone ventilation object, but no heat is brought in from the fan. \n " \
           "Different from the original 'fan_assist_night_ventilation' measure, this measure can be applied to models  " \
           "with mechenical systems. HybridVentilationAvailabilityManager is added to airloops and zonal systems to avoid  " \
           "simultaneous operation of windows and HVAC. The zone ventilation is controlled by a combination of schedule,  " \
           "indoor and outdoor temperature, and wind speed."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for night ventilation air change rate
    design_night_vent_ach = OpenStudio::Measure::OSArgument::makeDoubleArgument('design_night_vent_ach', true)
    design_night_vent_ach.setDisplayName('Design night ventilation air change rate defined by ACH-air changes per hour')
    design_night_vent_ach.setDefaultValue(3)
    args << design_night_vent_ach

    # add argument for exhaust fan pressure rise
    fan_pressure_rise = OpenStudio::Measure::OSArgument.makeDoubleArgument('fan_pressure_rise', true)
    fan_pressure_rise.setDisplayName('Fan Pressure Rise')
    fan_pressure_rise.setUnits('Pa')
    fan_pressure_rise.setDefaultValue(500.0)
    args << fan_pressure_rise

    # add argument for exhaust fan efficiency
    efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument('efficiency', true)
    efficiency.setDisplayName('Fan Total Efficiency')
    efficiency.setDefaultValue(0.65)
    args << efficiency

    # make an argument for min indoor temp
    min_indoor_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('min_indoor_temp', false)
    min_indoor_temp.setDisplayName('Minimum Indoor Temperature (degC)')
    min_indoor_temp.setDescription('The indoor temperature below which ventilation is shutoff.')
    min_indoor_temp.setDefaultValue(20)
    args << min_indoor_temp

    # make an argument for maximum indoor temperature
    max_indoor_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('max_indoor_temp', false)
    max_indoor_temp.setDisplayName('Maximum Indoor Temperature (degC)')
    max_indoor_temp.setDescription('The indoor temperature above which ventilation is shutoff.')
    max_indoor_temp.setDefaultValue(26)
    args << max_indoor_temp

    # make an argument for delta temperature
    delta_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('delta_temp', false)
    delta_temp.setDisplayName('Minimum Indoor-Outdoor Temperature Difference (degC)')
    delta_temp.setDescription('This is the temperature difference between the indoor and outdoor air dry-bulb '\
                              'temperatures below which ventilation is shutoff.  For example, a delta temperature '\
                              'of 2 degC means ventilation is available if the outside air temperature is at least '\
                              '2 degC cooler than the zone air temperature. Values can be negative.')
    delta_temp.setDefaultValue(2.0)
    args << delta_temp

    # make an argument for minimum outdoor temperature
    min_outdoor_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('min_outdoor_temp', true)
    min_outdoor_temp.setDisplayName('Minimum Outdoor Temperature (degC)')
    min_outdoor_temp.setDescription('The outdoor temperature below which ventilation is shut off.')
    min_outdoor_temp.setDefaultValue(18)
    args << min_outdoor_temp

    # make an argument for maximum outdoor temperature
    max_outdoor_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('max_outdoor_temp', true)
    max_outdoor_temp.setDisplayName('Maximum Outdoor Temperature (degC)')
    max_outdoor_temp.setDescription('The outdoor temperature above which ventilation is shut off.')
    max_outdoor_temp.setDefaultValue(26)
    args << max_outdoor_temp

    # make an argument for maximum wind speed
    max_wind_speed = OpenStudio::Measure::OSArgument::makeDoubleArgument('max_wind_speed', false)
    max_wind_speed.setDisplayName('Maximum Wind Speed (m/s)')
    max_wind_speed.setDescription('This is the wind speed above which ventilation is shut off.  The default values assume windows are closed when wind is above a gentle breeze to avoid blowing around papers in the space.')
    max_wind_speed.setDefaultValue(40)
    args << max_wind_speed

    # make an argument for the start time of natural ventilation
    night_vent_starttime = OpenStudio::Measure::OSArgument.makeStringArgument('night_vent_starttime', false)
    night_vent_starttime.setDisplayName('Daily Start Time for natural ventilation')
    night_vent_starttime.setDescription('Use 24 hour format (HR:MM)')
    night_vent_starttime.setDefaultValue('20:00')
    args << night_vent_starttime

    # make an argument for the end time of natural ventilation
    night_vent_endtime = OpenStudio::Measure::OSArgument.makeStringArgument('night_vent_endtime', false)
    night_vent_endtime.setDisplayName('Daily End Time for natural ventilation')
    night_vent_endtime.setDescription('Use 24 hour format (HR:MM)')
    night_vent_endtime.setDefaultValue('08:00')
    args << night_vent_endtime

    # make an argument for the start date of natural ventilation
    night_vent_startdate = OpenStudio::Measure::OSArgument.makeStringArgument('night_vent_startdate', false)
    night_vent_startdate.setDisplayName('Start Date for natural ventilation')
    night_vent_startdate.setDescription('In MM-DD format')
    night_vent_startdate.setDefaultValue('03-01')
    args << night_vent_startdate

    # make an argument for the end date of natural ventilation
    night_vent_enddate = OpenStudio::Measure::OSArgument.makeStringArgument('night_vent_enddate', false)
    night_vent_enddate.setDisplayName('End Date for natural ventilation')
    night_vent_enddate.setDescription('In MM-DD format')
    night_vent_enddate.setDefaultValue('10-31')
    args << night_vent_enddate

    # Make boolean arguments for natural ventilation schedule on weekends
    wknds = OpenStudio::Measure::OSArgument.makeBoolArgument('wknds', false)
    wknds.setDisplayName('Allow night time ventilation on weekends')
    wknds.setDefaultValue(true)
    args << wknds

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    design_night_vent_ach = runner.getDoubleArgumentValue('design_night_vent_ach', user_arguments)
    fan_pressure_rise = runner.getDoubleArgumentValue('fan_pressure_rise', user_arguments)
    efficiency = runner.getDoubleArgumentValue('efficiency', user_arguments)
    min_indoor_temp = runner.getDoubleArgumentValue('min_indoor_temp', user_arguments)
    max_indoor_temp = runner.getDoubleArgumentValue('max_indoor_temp', user_arguments)
    delta_temp = runner.getDoubleArgumentValue('delta_temp', user_arguments)
    min_outdoor_temp = runner.getDoubleArgumentValue('min_outdoor_temp', user_arguments)
    max_outdoor_temp = runner.getDoubleArgumentValue('max_outdoor_temp', user_arguments)
    max_wind_speed = runner.getDoubleArgumentValue('max_wind_speed', user_arguments)
    night_vent_starttime = runner.getStringArgumentValue('night_vent_starttime', user_arguments)
    night_vent_endtime = runner.getStringArgumentValue('night_vent_endtime', user_arguments)
    night_vent_startdate = runner.getStringArgumentValue('night_vent_startdate', user_arguments)
    night_vent_enddate = runner.getStringArgumentValue('night_vent_enddate', user_arguments)
    wknds = runner.getBoolArgumentValue('wknds', user_arguments)


    # check night ventilation ach input
    if design_night_vent_ach <= 0
      runner.registerError('Design night ventilation ACH should be positive. Please double check your input.')
      return false
    elsif design_night_vent_ach > 10
      runner.registerWarning("Design night ventilation ACH #{design_night_vent_ach} is higher than 10, which is unusually large. Please double check your input.")
    elsif design_night_vent_ach < 0.3
      runner.registerWarning("Design night ventilation ACH #{design_night_vent_ach} is lower than 0.3, which is unusually small. Please double check your input.")
    end

    # check fan efficiency input
    if efficiency <= 0
      runner.registerError('Exhaust fan efficiency should be positive. Please double check your input.')
      return false
    elsif efficiency > 1
      runner.registerError("Exhaust fan efficiency #{efficiency} is larger than 1. Exhaust fan efficiency should be between 0 and 1. Please double check your input.")
      return false
    end

    # check temp limit inputs
    if min_indoor_temp >= max_indoor_temp
      runner.registerError('Minimum indoor temperature should be lower than maximum outdoor temperature. Please double check your input.')
      return false
    end

    if min_outdoor_temp >= max_outdoor_temp
      runner.registerError('Minimum outdoor temperature should be lower than maximum outdoor temperature. Please double check your input.')
      return false
    end

    # check max wind speed input
    if max_wind_speed <= 0
      runner.registerError('Maximum wind speed should be positive. Please double check your input.')
      return false
    end

    # check delta temperature input
    if delta_temp < 0
      runner.registerWarning("delta_temp #{delta_temp} is negative. Normally delta temperature should be positive "\
                              "or at least 0 to enable free cooling and avoid introducing extra cooling load. "\
                              "Please double check your input.")
    end

    # check time format
    begin
      night_vent_starttime = Time.strptime(night_vent_starttime, '%H:%M')
      night_vent_endtime = Time.strptime(night_vent_endtime, '%H:%M')
    rescue ArgumentError
      runner.registerError('Natural ventilation start and end time are required, and should be in format of %H:%M, e.g., 16:00.')
      return false
    end
    if night_vent_starttime < night_vent_endtime
      runner.registerWarning('Night ventilation end time is later than start time, referring to non-overnight ' \
                          'natural ventilation. Make sure this is expected.')
    end

    # check date format
    md = /(\d\d)-(\d\d)/.match(night_vent_startdate)
    if md
      night_vent_start_month = md[1].to_i
      night_vent_start_day = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end

    md = /(\d\d)-(\d\d)/.match(night_vent_enddate)
    if md
      night_vent_end_month = md[1].to_i
      night_vent_end_day = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end

    night_vent_startdate_os = model.getYearDescription.makeDate(night_vent_start_month, night_vent_start_day)
    night_vent_enddate_os = model.getYearDescription.makeDate(night_vent_end_month, night_vent_end_day)

    # if_overnight: 1 or 0; wknds (if applicable to weekends): 1 or 0
    # by default schedule on value is 1, sometimes need specify, e.g., natural ventilation window open area fraction
    def create_sch(model, sch_name, start_time, end_time, start_date, end_date, wknds, sch_on_value=1, sch_off_value=0)
      day_start_time = Time.strptime("00:00", '%H:%M')
      # create discharging schedule
      new_sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
      new_sch_ruleset.setName(sch_name)
      new_sch_ruleset.defaultDaySchedule.setName(sch_name + ' default')
      if start_time > end_time
        if_overnight = sch_on_value  # assigned as schedule on value
      else
        if_overnight = sch_off_value  # assigned as schedule off value
      end

      for min in 1..24*60
        if ((end_time - day_start_time)/60).to_i == min
          time = OpenStudio::Time.new(0, 0, min)
          new_sch_ruleset.defaultDaySchedule.addValue(time, sch_on_value)
        elsif ((start_time - day_start_time)/60).to_i == min
          time = OpenStudio::Time.new(0, 0, min)
          new_sch_ruleset.defaultDaySchedule.addValue(time, sch_off_value)
        elsif min == 24*60
          time = OpenStudio::Time.new(0, 0, min)
          new_sch_ruleset.defaultDaySchedule.addValue(time, if_overnight)
        end
      end

      start_month = start_date.monthOfYear.value
      start_day = start_date.dayOfMonth
      end_month = end_date.monthOfYear.value
      end_day = end_date.dayOfMonth
      ts_rule = OpenStudio::Model::ScheduleRule.new(new_sch_ruleset, new_sch_ruleset.defaultDaySchedule)
      ts_rule.setName("#{new_sch_ruleset.name} #{start_month}/#{start_day}-#{end_month}/#{end_day} Rule")
      ts_rule.setStartDate(start_date)
      ts_rule.setEndDate(end_date)
      ts_rule.setApplyWeekdays(true)
      if wknds
        ts_rule.setApplyWeekends(true)
      else
        ts_rule.setApplyWeekends(false)
      end

      unless start_month == 1 && start_day == 1
        new_rule_day = OpenStudio::Model::ScheduleDay.new(model)
        new_rule_day.addValue(OpenStudio::Time.new(0,24), 0)
        new_rule = OpenStudio::Model::ScheduleRule.new(new_sch_ruleset, new_rule_day)
        new_rule.setName("#{new_sch_ruleset.name} 01/01-#{start_month}/#{start_day} Rule")
        new_rule.setStartDate(model.getYearDescription.makeDate(1, 1))
        new_rule.setEndDate(model.getYearDescription.makeDate(start_month, start_day))
        new_rule.setApplyAllDays(true)
      end

      unless end_month == 12 && end_day == 31
        new_rule_day = OpenStudio::Model::ScheduleDay.new(model)
        new_rule_day.addValue(OpenStudio::Time.new(0,24), 0)
        new_rule = OpenStudio::Model::ScheduleRule.new(new_sch_ruleset, new_rule_day)
        new_rule.setName("#{new_sch_ruleset.name} #{end_month}/#{end_day}-12/31 Rule")
        new_rule.setStartDate(model.getYearDescription.makeDate(end_month, end_day))
        new_rule.setEndDate(model.getYearDescription.makeDate(12, 31))
        new_rule.setApplyAllDays(true)
      end

      return new_sch_ruleset
    end

    def inspect_airflow_surfaces(zone)
      array = [] # [adjacent_zone,surfaceType]
      zone.spaces.each do |space|
        space.surfaces.each do |surface|
          next if surface.adjacentSurface.is_initialized != true
          next if !surface.adjacentSurface.get.space.is_initialized
          next if !surface.adjacentSurface.get.space.get.thermalZone.is_initialized
          adjacent_zone = surface.adjacentSurface.get.space.get.thermalZone.get
          if surface.surfaceType == 'RoofCeiling' || surface.surfaceType == 'Wall'
            if surface.isAirWall
              array << [adjacent_zone, surface.surfaceType]
            else
              surface.subSurfaces.each do |sub_surface|
                next if sub_surface.adjacentSubSurface.is_initialized != true
                next if !sub_surface.adjacentSubSurface.get.surface.get.space.is_initialized
                next if !sub_surface.adjacentSubSurface.get.surface.get.space.get.thermalZone.is_initialized
                adjacent_zone = sub_surface.adjacentSubSurface.get.surface.get.space.get.thermalZone.get
                # available subsurfacetypes: "FixedWindow", "OperableWindow", "Door", "GlassDoor", "OverheadDoor", "Skylight", "TubularDaylightDome", "TubularDaylightDiffuser"
                # Often windows are assigned as FixedWindow by default but not indicating it cannot be opened.
                if sub_surface.isAirWall || sub_surface.subSurfaceType == 'OperableWindow' || sub_surface.subSurfaceType == 'FixedWindow' ||
                  sub_surface.subSurfaceType == 'Door' || sub_surface.subSurfaceType == 'GlassDoor'
                  array << [adjacent_zone, surface.surfaceType]
                end
              end
            end
          end
        end
      end

      return array
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getZoneVentilationDesignFlowRates.size} "\
                                    " zone ventilation design flow rate objects and #{model.getZoneMixings.size} zone mixing objects.")


    #################### STEP 1: find ventilation path and create exhaust zones ################
    # setup hash to hold path objects and exhaust zones
    path_objects = {}
    exhaust_zones = {}
    zones_w_ext_windows = []
    nv_zone_list = {}  # save zones with exterior windows and their zone ventilation object info

    model.getSpaces.each do |space|
      next if space.thermalZone.empty?
      thermal_zone = space.thermalZone.get

      # store airflow paths for future use
      path_objects[thermal_zone] = inspect_airflow_surfaces(thermal_zone)

      # get the list of zones with exterior windows
      space.surfaces.sort.each do |surface|
        surface.subSurfaces.sort.each do |subsurface|
          if (subsurface.subSurfaceType == 'OperableWindow' || subsurface.subSurfaceType == 'FixedWindow') && subsurface.outsideBoundaryCondition == 'Outdoors'
            zones_w_ext_windows << thermal_zone unless zones_w_ext_windows.include?(thermal_zone)
          end
        end
      end
    end

    #################### STEP 2: add zone ventilation objects and zone mixing objects ################
    # setup has to store paths
    flow_paths = {}
    # setup night ventilation schedule
    night_vent_sch = create_sch(model, "night ventilation sch", night_vent_starttime, night_vent_endtime, night_vent_startdate_os, night_vent_enddate_os, wknds)

    # return as NA if no exterior operable windows
    if zones_w_ext_windows.empty?
      runner.registerAsNotApplicable('No zones with exterior operable windows were found. The model will not be altered')
      return true
    end

    # Loop through zones in hash and make natural ventilation objects so the sum equals the user specified target
    zones_w_ext_windows.each do |zone|
      zone_ventilation = OpenStudio::Model::ZoneVentilationDesignFlowRate.new(model)
      zone_ventilation.setName("PathStart_#{zone.name}")
      zone_ventilation.addToThermalZone(zone)
      zone_ventilation.setVentilationType('Exhaust') # switched from Natural to use power. Need to set fan properties. Used exhaust so no heat from fan in stream
      zone_ventilation.setAirChangesperHour(design_night_vent_ach)

      # inputs used for fan power
      zone_ventilation.setFanPressureRise(fan_pressure_rise)
      zone_ventilation.setFanTotalEfficiency(efficiency)

      # set schedule from user arg
      zone_ventilation.setSchedule(night_vent_sch)

      # set ventilation control thresholds
      zone_ventilation.setMinimumIndoorTemperature(min_indoor_temp)
      zone_ventilation.setMaximumIndoorTemperature(max_indoor_temp)
      zone_ventilation.setMinimumOutdoorTemperature(min_outdoor_temp)
      zone_ventilation.setMaximumOutdoorTemperature(max_outdoor_temp)
      zone_ventilation.setDeltaTemperature(delta_temp)
      zone_ventilation.setMaximumWindSpeed(max_wind_speed)
      nv_zone_list[zone.name.to_s] = zone_ventilation
      runner.registerInfo("Added natural ventilation object to #{zone.name} of #{design_night_vent_ach} air change rate per hour.")

      # start trace of path adding air mixing objects
      found_path_end = false
      flow_paths[zone] = []
      current_zone = zone
      zones_used_for_this_path = [current_zone]
      until found_path_end
        found_ceiling = false
        found_wall = false
        path_objects[current_zone].each do |object|
          next if zones_used_for_this_path.include?(object[0])
          next if object[1].to_s != 'RoofCeiling'
          next if zones_w_ext_windows.include?(object[0])
          if found_ceiling
            runner.registerWarning("Found more than one possible airflow path for #{current_zone.name}")
          else
            flow_paths[zone] << object[0]
            current_zone = object[0]
            zones_used_for_this_path << object[0]
            found_ceiling = true
          end
        end
        unless found_ceiling
          path_objects[current_zone].each do |object|
            next if zones_used_for_this_path.include?(object[0])
            next if object[1].to_s != 'Wall'
            next if zones_w_ext_windows.include?(object[0])
            if found_wall
              runner.registerWarning("Found more than one possible airflow path for #{current_zone.name}")
            else
              flow_paths[zone] << object[0]
              current_zone = object[0]
              zones_used_for_this_path << object[0]
              found_wall = true
            end
          end
        end
        if !found_ceiling && !found_wall
          found_path_end = true
        end
      end

      # add one way air mixing objects along path zones
      zone_path_string_array = [zone.name]
      vent_zone = zone
      source_zone = zone
      flow_paths[zone].each do |zone|
        zone_mixing = OpenStudio::Model::ZoneMixing.new(zone)
        zone_mixing.setName("PathStart_#{vent_zone.name}_#{source_zone.name}")
        zone_mixing.setSourceZone(source_zone)
        zone_mixing.setAirChangesperHour(design_night_vent_ach)

        # set min outdoor temp schedule
        min_outdoor_sch = OpenStudio::Model::ScheduleConstant.new(model)
        min_outdoor_sch.setValue(min_outdoor_temp)
        zone_mixing.setMinimumOutdoorTemperatureSchedule(min_outdoor_sch)

        # set schedule from user arg
        zone_mixing.setSchedule(night_vent_sch)

        # change source zone to what was just target zone
        zone_path_string_array << zone.name
        source_zone = zone
      end
      runner.registerInfo("Added Zone Mixing Path: #{zone_path_string_array.join(' > ')}")

      # add ach to exhaust zones
      if !flow_paths[zone].empty?
        if exhaust_zones.include? flow_paths[zone].last
          exhaust_zones[flow_paths[zone].last] += design_night_vent_ach
        else
          exhaust_zones[flow_paths[zone].last] = design_night_vent_ach
        end
      else
        # extra code if there is no path from entry zone
        if exhaust_zones.include? zone
          exhaust_zones[zone] += design_night_vent_ach
        else
          exhaust_zones[zone] = design_night_vent_ach
          runner.registerWarning("#{zone.name} doesn't have path to other zones. Exhaust assumed to be with the same zone as air enters.")
        end
      end
    end

    # report how much air (by ach) exhausts to each exhaust zone
    # when I add an exhaust fan to the top floor I want it to use energy but I don't want to move any additional air.
    # The air is already being brought into the zone by the zone mixing objects
    exhaust_zones.each do |zone, ach|
      runner.registerInfo("Zone Mixing flow rate into #{zone.name} is #{ach} air change per hour. Fan Consumption included with zone ventilation zones.")

      # check for exterior surface area
      if zone.exteriorSurfaceArea == 0
        runner.registerWarning("Exhaust Zone #{zone.name} doesn't appear to have any exterior exposure. Review the paths to see that this is the expected result.")
      end
    end

    # warn if zone multiplier are used
    non_default_multiplier = []
    model.getThermalZones.each do |zone|
      if zone.multiplier > 1
        non_default_multiplier << zone
      end
    end
    if !non_default_multiplier.empty?
      runner.registerWarning("This measure is not intended to be use when thermal zones have a non 1 multiplier. #{non_default_multiplier.size} zones in this model have multipliers greater than one. Results are likley invalid.")
    end


    #################### STEP 3: add hybrid ventilation control objects ################

    # TODO: Simple Airflow Control Type Schedule Name set as 1 denote group control
    # if a zone has more than one windows, group control allows them to be operated simultaneously
    # if an airloopHVAC controls more than one zone, only one AvailabilityManagerHybridVentilation is allowed for an airloop, group control will
    # decides the zones controlled by this airloop based on the selected ZoneVentilation object input
    vent_control_sch = create_sch(model, "ventilation control sch", night_vent_starttime, night_vent_endtime, night_vent_startdate_os, night_vent_enddate_os, wknds, 1, 0)
    simple_airflow_control_type_sch = OpenStudio::Model::ScheduleConstant.new(model)
    simple_airflow_control_type_sch.setName("simple airflow control type sch - group control")
    simple_airflow_control_type_sch.setValue(1)

    # part1: loop through all the airloopHVAC and add hybrid ventilation control
    model.getAirLoopHVACs.sort.each do |air_loop|
      max_zone_area = 0
      nv_zone_with_max_area = nil
      air_loop.thermalZones.each do |thermal_zone|
        if max_zone_area < thermal_zone.floorArea && nv_zone_list.key?(thermal_zone.name.to_s)
          max_zone_area = thermal_zone.floorArea
          nv_zone_with_max_area = thermal_zone.name.to_s
        end
      end
      next if nv_zone_with_max_area.nil? # if there is no NV zone in this airloop, skip
      has_hybrid_avail_manager = false
      air_loop.availabilityManagers.sort.each do |avail_mgr|
        next if avail_mgr.to_AvailabilityManagerHybridVentilation.empty?
        if avail_mgr.to_AvailabilityManagerHybridVentilation.is_initialized
          has_hybrid_avail_manager = true
          avail_mgr_hybr_vent = avail_mgr.to_AvailabilityManagerHybridVentilation.get
          avail_mgr_hybr_vent.setVentilationControlModeSchedule(vent_control_sch)
          avail_mgr_hybr_vent.setControlledZone(model.getThermalZoneByName(nv_zone_with_max_area).get)
          avail_mgr_hybr_vent.setMinimumOutdoorTemperature(min_outdoor_temp)
          avail_mgr_hybr_vent.setMaximumOutdoorTemperature(max_outdoor_temp)
          avail_mgr_hybr_vent.setMaximumWindSpeed(max_wind_speed)
          avail_mgr_hybr_vent.setSimpleAirflowControlTypeSchedule(simple_airflow_control_type_sch)
          avail_mgr_hybr_vent.setZoneVentilationObject(nv_zone_list[nv_zone_with_max_area])
        end
      end

      unless has_hybrid_avail_manager
        avail_mgr_hybr_vent = OpenStudio::Model::AvailabilityManagerHybridVentilation.new(model)
        avail_mgr_hybr_vent.setName(air_loop.name.to_s + " HybridVentilation AvailabilityManager")
        avail_mgr_hybr_vent.setVentilationControlModeSchedule(vent_control_sch)
        avail_mgr_hybr_vent.setControlledZone(model.getThermalZoneByName(nv_zone_with_max_area).get)
        avail_mgr_hybr_vent.setMinimumOutdoorTemperature(min_outdoor_temp)
        avail_mgr_hybr_vent.setMaximumOutdoorTemperature(max_outdoor_temp)
        avail_mgr_hybr_vent.setMaximumWindSpeed(max_wind_speed)
        avail_mgr_hybr_vent.setSimpleAirflowControlTypeSchedule(simple_airflow_control_type_sch)
        avail_mgr_hybr_vent.setZoneVentilationObject(nv_zone_list[nv_zone_with_max_area])
        air_loop.addAvailabilityManager(avail_mgr_hybr_vent)
      end

      # remove thermal zones in this airloop from the nv_zone_list hash
      air_loop.thermalZones.each do |thermal_zone|
        if nv_zone_list.key?(thermal_zone.name.to_s)
          nv_zone_list.delete(thermal_zone.name.to_s)
        end
      end
    end

    # part2: loop through all spaces, add hybrid vent control to zones that are not connected to airloopHVAC but uses zonal equipment
    nv_zone_list.each do |zone_name, nv_obj|
      avail_mgr_hybr_vent = OpenStudio::Model::AvailabilityManagerHybridVentilation.new(model)
      avail_mgr_hybr_vent.setName(zone_name + " HybridVentilation AvailabilityManager")
      avail_mgr_hybr_vent.setVentilationControlModeSchedule(vent_control_sch)
      avail_mgr_hybr_vent.setControlledZone(model.getThermalZoneByName(zone_name).get)
      avail_mgr_hybr_vent.setMinimumOutdoorTemperature(min_outdoor_temp)
      avail_mgr_hybr_vent.setMaximumOutdoorTemperature(max_outdoor_temp)
      avail_mgr_hybr_vent.setMaximumWindSpeed(max_wind_speed)
      avail_mgr_hybr_vent.setSimpleAirflowControlTypeSchedule(simple_airflow_control_type_sch)
      avail_mgr_hybr_vent.setZoneVentilationObject(nv_obj)
    end

    # echo added AvailabilityManagerHybridVentilation object number to the user
    runner.registerInfo("A total of #{model.getAvailabilityManagerHybridVentilations.size} AvailabilityManagerHybridVentilations were added.")

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getZoneVentilationDesignFlowRates.size} zone ventilation design flow rate objects and #{model.getZoneMixings.size} zone mixing objects.")

    # adding useful output variables for diagnostics
    OpenStudio::Model::OutputVariable.new('Zone Mixing Current Density Air Volume Flow Rate', model)
    OpenStudio::Model::OutputVariable.new('Zone Ventilation Current Density Volume Flow Rate', model)
    OpenStudio::Model::OutputVariable.new('Zone Ventilation Fan Electric Energy', model)
    OpenStudio::Model::OutputVariable.new('Zone Outdoor Air Drybulb Temperature', model)

    return true
  end
end

# register the measure to be used by the application
AddFanAssistNightVentilationWithHybridControl.new.registerWithApplication
