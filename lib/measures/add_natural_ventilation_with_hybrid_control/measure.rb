# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddNaturalVentilationWithHybridControl < OpenStudio::Measure::ModelMeasure
  require 'time'
  require 'json'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add natural ventilation with hybrid control'
  end

  # human readable description
  def description
    return 'This measure adds natural ventilation to all the zones with operable windows, and controls natural  ' \
            'ventilation together with HVAC in a hybrid manner. More specifically, HVAC will be disabled  ' \
            'when windows are open,  and HVAC will be available when windows are closed.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measures adds ZoneVentilation:WindandStackOpenArea objects to zones with operable windwos to model ' \
            'natural ventilation, then adds AvailabilityManager:HybridVentilation to each zone with natural ventilation and ' \
            'control HVAC and natural ventilation in a hybrid manner. When windows are open, HVAC will be disabled; ' \
            'when windows are closed, HVAC will be available. HVAC can be an airloop system or a zonal system. '
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for window's open area fraction
    open_area_fraction = OpenStudio::Measure::OSArgument::makeDoubleArgument('open_area_fraction', true)
    open_area_fraction.setDisplayName('Window Open Area Fraction (0-1)')
    open_area_fraction.setDescription('A typical operable window does not open fully. The actual opening area in a zone is the product of the area of operable windows and the open area fraction schedule. Default 50% open.')
    open_area_fraction.setDefaultValue(0.5)
    args << open_area_fraction

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
    max_indoor_temp.setDefaultValue(24)
    args << max_indoor_temp

    # make an argument for delta temperature
    delta_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('delta_temp', false)
    delta_temp.setDisplayName('Maximum Indoor-Outdoor Temperature Difference (degC)')
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
    min_outdoor_temp.setDefaultValue(20)
    args << min_outdoor_temp

    # make an argument for maximum outdoor temperature
    max_outdoor_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('max_outdoor_temp', true)
    max_outdoor_temp.setDisplayName('Maximum Outdoor Temperature (degC)')
    max_outdoor_temp.setDescription('The outdoor temperature above which ventilation is shut off.')
    max_outdoor_temp.setDefaultValue(24)
    args << max_outdoor_temp

    # make an argument for maximum wind speed
    max_wind_speed = OpenStudio::Measure::OSArgument::makeDoubleArgument('max_wind_speed', false)
    max_wind_speed.setDisplayName('Maximum Wind Speed (m/s)')
    max_wind_speed.setDescription('This is the wind speed above which ventilation is shut off.  The default values assume windows are closed when wind is above a gentle breeze to avoid blowing around papers in the space.')
    max_wind_speed.setDefaultValue(40)
    args << max_wind_speed

    # make an argument for the start time of natural ventilation
    nv_starttime = OpenStudio::Measure::OSArgument.makeStringArgument('nv_starttime', false)
    nv_starttime.setDisplayName('Daily Start Time for natural ventilation')
    nv_starttime.setDescription('Use 24 hour format (HR:MM)')
    nv_starttime.setDefaultValue('07:00')
    args << nv_starttime

    # make an argument for the end time of natural ventilation
    nv_endtime = OpenStudio::Measure::OSArgument.makeStringArgument('nv_endtime', false)
    nv_endtime.setDisplayName('Daily End Time for natural ventilation')
    nv_endtime.setDescription('Use 24 hour format (HR:MM)')
    nv_endtime.setDefaultValue('21:00')
    args << nv_endtime

    # make an argument for the start date of natural ventilation
    nv_startdate = OpenStudio::Measure::OSArgument.makeStringArgument('nv_startdate', false)
    nv_startdate.setDisplayName('Start Date for natural ventilation')
    nv_startdate.setDescription('In MM-DD format')
    nv_startdate.setDefaultValue('03-01')
    args << nv_startdate

    # make an argument for the end date of natural ventilation
    nv_enddate = OpenStudio::Measure::OSArgument.makeStringArgument('nv_enddate', false)
    nv_enddate.setDisplayName('End Date for natural ventilation')
    nv_enddate.setDescription('In MM-DD format')
    nv_enddate.setDefaultValue('10-31')
    args << nv_enddate

    # Make boolean arguments for natural ventilation schedule on weekends
    wknds = OpenStudio::Measure::OSArgument.makeBoolArgument('wknds', false)
    wknds.setDisplayName('Allow Natural Ventilation on Weekends')
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
    open_area_fraction = runner.getDoubleArgumentValue('open_area_fraction', user_arguments)
    min_indoor_temp = runner.getDoubleArgumentValue('min_indoor_temp', user_arguments)
    max_indoor_temp = runner.getDoubleArgumentValue('max_indoor_temp', user_arguments)
    delta_temp = runner.getDoubleArgumentValue('delta_temp', user_arguments)
    min_outdoor_temp = runner.getDoubleArgumentValue('min_outdoor_temp', user_arguments)
    max_outdoor_temp = runner.getDoubleArgumentValue('max_outdoor_temp', user_arguments)
    max_wind_speed = runner.getDoubleArgumentValue('max_wind_speed', user_arguments)
    nv_starttime = runner.getStringArgumentValue('nv_starttime', user_arguments)
    nv_endtime = runner.getStringArgumentValue('nv_endtime', user_arguments)
    nv_startdate = runner.getStringArgumentValue('nv_startdate', user_arguments)
    nv_enddate = runner.getStringArgumentValue('nv_enddate', user_arguments)
    wknds = runner.getBoolArgumentValue('wknds', user_arguments)

    # check open_area_fraction input
    if open_area_fraction < 0
      runner.registerError('Window open area fraction should be between 0 and 1. Please double check your input.')
      return false
    elsif open_area_fraction > 1
      runner.registerError("open_area_fraction #{open_area_fraction} is a larger than 1. Window open area fraction should be between 0 and 1. Please double check your input.")
      return false
    elsif open_area_fraction == 0
      runner.registerWarning("open_area_fraction #{open_area_fraction} is set as 0, meaning the windows will not be opened at all. Please double check your input.")
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
      nv_starttime = Time.strptime(nv_starttime, '%H:%M')
      nv_endtime = Time.strptime(nv_endtime, '%H:%M')
    rescue ArgumentError
      runner.registerError('Natural ventilation start and end time are required, and should be in format of %H:%M, e.g., 16:00.')
      return false
    end
    if nv_starttime > nv_endtime
      runner.registerInfo('Natural ventilation start time is later than end time, referring to overnight ' \
                          'natural ventilation. Make sure this is expected.')
    end

    # check date format
    md = /(\d\d)-(\d\d)/.match(nv_startdate)
    if md
      nv_start_month = md[1].to_i
      nv_start_day = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end

    md = /(\d\d)-(\d\d)/.match(nv_enddate)
    if md
      nv_end_month = md[1].to_i
      nv_end_day = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end

    nv_startdate_os = model.getYearDescription.makeDate(nv_start_month, nv_start_day)
    nv_enddate_os = model.getYearDescription.makeDate(nv_end_month, nv_end_day)

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


    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getZoneVentilationWindandStackOpenAreas.size} "\
                                    "ZoneVentilation:WindandStackOpenArea objects and #{model.getZoneVentilationDesignFlowRates.size}.")



    #################### STEP 1: add zone ventilation objects ################
    # TODO: update
    # for spaces with existing NV object (1. ZoneVentilation:DesignFlowRate with 'Natural' as the ventilation type; or 2. ZoneVentilation:WindandStackOpenArea), skip

    nv_zone_list = {}  # if NV object is added, add the key-value (zone name-NV object) to this hash
    window_open_area_sch = create_sch(model, "window open area fraction sch", nv_starttime, nv_endtime, nv_startdate_os, nv_enddate_os, wknds, open_area_fraction, 0)
    model.getSpaces.each do |space|
      next if space.thermalZone.empty?
      thermal_zone = space.thermalZone.get

      # check if this space has existing NV object, if yes then skip
      has_nv = false
      nv_objs = []
      thermal_zone.equipment.each do |zone_equipment|
        if zone_equipment.to_ZoneVentilationDesignFlowRate.is_initialized
          if zone_equipment.to_ZoneVentilationDesignFlowRate.get.ventilationType.lowercase == "natural"
            has_nv = true
            nv_objs << zone_equipment.to_ZoneVentilationDesignFlowRate.get
          end
        elsif zone_equipment.to_ZoneVentilationWindandStackOpenArea.is_initialized
          has_nv = true
          nv_objs << zone_equipment.to_ZoneVentilationWindandStackOpenArea.get
        end
      end
      if has_nv
        nv_zone_list[thermal_zone.name.to_s] = nv_objs
        next
      end

      # add NV objects
      space.surfaces.sort.each do |surface|
        surface.subSurfaces.sort.each do |subsurface|
          if (subsurface.subSurfaceType == 'OperableWindow' || subsurface.subSurfaceType == 'FixedWindow') && subsurface.outsideBoundaryCondition == 'Outdoors'
            window_azimuth_deg = OpenStudio.convert(subsurface.azimuth, 'rad', 'deg').get
            window_area = subsurface.netArea

            ##### Add the "ZoneVentilation:WindandStackOpenArea" for NV.
            zn_vent_wind_and_stack = OpenStudio::Model::ZoneVentilationWindandStackOpenArea.new(model)
            zn_vent_wind_and_stack.setName(subsurface.name.to_s + " NV object")
            zn_vent_wind_and_stack.setOpeningArea(window_area)
            zn_vent_wind_and_stack.setOpeningAreaFractionSchedule(window_open_area_sch)
            zn_vent_wind_and_stack.setEffectiveAngle(window_azimuth_deg)
            zn_vent_wind_and_stack.setMinimumIndoorTemperature(min_indoor_temp)
            zn_vent_wind_and_stack.setMaximumIndoorTemperature(max_indoor_temp)
            zn_vent_wind_and_stack.setMinimumOutdoorTemperature(min_outdoor_temp)
            zn_vent_wind_and_stack.setMaximumOutdoorTemperature(max_outdoor_temp)
            zn_vent_wind_and_stack.setDeltaTemperature(delta_temp)
            zn_vent_wind_and_stack.setMaximumWindSpeed(max_wind_speed)
            zn_vent_wind_and_stack.addToThermalZone(thermal_zone)
            nv_zone_list[thermal_zone.name.to_s] = [] unless nv_zone_list.key?(thermal_zone.name.to_s)
            nv_zone_list[thermal_zone.name.to_s] << zn_vent_wind_and_stack
          end
        end
      end
    end

    #################### STEP 2: add hybrid ventilation control objects ################

    # TODO: Simple Airflow Control Type Schedule Name set as 1 denote group control
    # if a zone has more than one windows, group control allows them to be operated simultaneously
    # if an airloopHVAC controls more than one zone, only one AvailabilityManagerHybridVentilation is allowed for an airloop, group control will
    # decides the zones controlled by this airloop based on the selected ZoneVentilation object input

    vent_control_sch = create_sch(model, "ventilation control sch", nv_starttime, nv_endtime, nv_startdate_os, nv_enddate_os, wknds, 1, 0)
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

          # if zone has more than one window, set control based on the biggest window
          nv_objs = nv_zone_list[nv_zone_with_max_area]
          max_open_area = 0
          nv_objs.each do |nv_obj|
            max_open_area = nv_obj.openingArea if max_open_area < nv_obj.openingArea
            avail_mgr_hybr_vent.setZoneVentilationObject(nv_obj)
          end
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

        # if controlled zone has more than one window, set control based on the biggest window
        nv_objs = nv_zone_list[nv_zone_with_max_area]
        max_open_area = 0
        nv_objs.each do |nv_obj|
          max_open_area = nv_obj.openingArea if max_open_area < nv_obj.openingArea
          avail_mgr_hybr_vent.setZoneVentilationObject(nv_obj)
        end
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
    nv_zone_list.each do |zone_name, nv_objs|
      avail_mgr_hybr_vent = OpenStudio::Model::AvailabilityManagerHybridVentilation.new(model)
      avail_mgr_hybr_vent.setName(zone_name + " HybridVentilation AvailabilityManager")
      avail_mgr_hybr_vent.setVentilationControlModeSchedule(vent_control_sch)
      avail_mgr_hybr_vent.setControlledZone(model.getThermalZoneByName(zone_name).get)
      avail_mgr_hybr_vent.setMinimumOutdoorTemperature(min_outdoor_temp)
      avail_mgr_hybr_vent.setMaximumOutdoorTemperature(max_outdoor_temp)
      avail_mgr_hybr_vent.setMaximumWindSpeed(max_wind_speed)
      avail_mgr_hybr_vent.setSimpleAirflowControlTypeSchedule(simple_airflow_control_type_sch)

      # if controlled zone has more than one window, set control based on the biggest window
      max_open_area = 0
      nv_objs.each do |nv_obj|
        max_open_area = nv_obj.openingArea if max_open_area < nv_obj.openingArea
        avail_mgr_hybr_vent.setZoneVentilationObject(nv_obj)
      end
    end

    # echo added AvailabilityManagerHybridVentilation object number to the user
    runner.registerInfo("A total of #{model.getAvailabilityManagerHybridVentilations.size} AvailabilityManagerHybridVentilations were added.")

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getAvailabilityManagerHybridVentilations.size} AvailabilityManagerHybridVentilations.")

    return true
  end
end

# register the measure to be used by the application
AddNaturalVentilationWithHybridControl.new.registerWithApplication
