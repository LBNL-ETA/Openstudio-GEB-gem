# start the measure
class DRHVACLgOffice < OpenStudio::Measure::ModelMeasure
  # setup OpenStudio units that we will need
  TEMP_IP_UNIT = OpenStudio.createUnit('F').get
  TEMP_SI_UNIT = OpenStudio.createUnit('C').get
  
  # define the name that a user will see
  def name
    return 'DR HVAC'
  end

  # human readable description
  def description
    return 'This measure adjusts heating and cooling setpoints by a user-specified number of degrees and a user-specified time period. This is applied throughout the entire building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will clone all of the schedules that are used as heating and cooling setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values during a specified time period. There is a checkbox to determine if the thermostat for design days should be altered.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for adjustment to cooling setpoint
    cooling_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_adjustment', true)
    cooling_adjustment.setDisplayName('Degrees Fahrenheit to Adjust Cooling Setpoint By')
    cooling_adjustment.setDefaultValue(5.0)
    args << cooling_adjustment

    # make an argument for the start time of cooling adjustment
    starttime_cooling = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_cooling', true)
    starttime_cooling.setDisplayName('Start Time for Cooling Adjustment')
    starttime_cooling.setDefaultValue('16:01:00')
    args << starttime_cooling

    # make an argument for the end time of cooling adjustment
    endtime_cooling = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_cooling', true)
    endtime_cooling.setDisplayName('End Time for Cooling Adjustment')
    endtime_cooling.setDefaultValue('20:00:00')
    args << endtime_cooling

    # make an argument for the start time of heating adjustment
    starttime_heating1 = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_heating1', true)
    starttime_heating1.setDisplayName('Start Time for Heating Adjustment')
    starttime_heating1.setDefaultValue('16:01:00')
    args << starttime_heating1

    # make an argument for the end time of heating adjustment
    endtime_heating1 = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_heating1', true)
    endtime_heating1.setDisplayName('End Time for Heating Adjustment')
    endtime_heating1.setDefaultValue('20:00:00')
    args << endtime_heating1

    # make an argument for adjustment to heating setpoint
    heating_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_adjustment', true)
    heating_adjustment.setDisplayName('Degrees Fahrenheit to Adjust heating Setpoint By')
    heating_adjustment.setDefaultValue(-2.0)
    args << heating_adjustment

    # make an argument for the start time of heating adjustment
    starttime_heating2 = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_heating2', false)
    starttime_heating2.setDisplayName('Start Time for Heating Adjustment')
    starttime_heating2.setDefaultValue('16:01:00')
    args << starttime_heating2

    # make an argument for the end time of heating adjustment
    endtime_heating2 = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_heating2', false)
    endtime_heating2.setDisplayName('End Time for Heating Adjustment')
    endtime_heating2.setDefaultValue('20:00:00')
    args << endtime_heating2

    # make an argument if the thermostat for design days should be altered
    alter_design_days = OpenStudio::Measure::OSArgument.makeBoolArgument('alter_design_days', false)
    alter_design_days.setDisplayName('Alter Design Day Thermostats')
    alter_design_days.setDefaultValue(false)
    args << alter_design_days

    auto_date = OpenStudio::Measure::OSArgument.makeBoolArgument('auto_date', true)
    auto_date.setDisplayName('Enable Climate-specific Periods Setting ?')
    auto_date.setDefaultValue(true)
    args << auto_date

    alt_periods = OpenStudio::Measure::OSArgument.makeBoolArgument('alt_periods', true)
    alt_periods.setDisplayName('Alternate Peak and Take Periods')
    alt_periods.setDefaultValue(false)
    args << alt_periods

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
    cooling_adjustment = runner.getDoubleArgumentValue('cooling_adjustment', user_arguments)
    heating_adjustment = runner.getDoubleArgumentValue('heating_adjustment', user_arguments)
    starttime_cooling = runner.getStringArgumentValue('starttime_cooling', user_arguments)
    endtime_cooling = runner.getStringArgumentValue('endtime_cooling', user_arguments)
    starttime_heating1 = runner.getStringArgumentValue('starttime_heating1', user_arguments)
    endtime_heating1 = runner.getStringArgumentValue('endtime_heating1', user_arguments)
    starttime_heating2 = runner.getStringArgumentValue('starttime_heating2', user_arguments)
    endtime_heating2 = runner.getStringArgumentValue('endtime_heating2', user_arguments)
    alter_design_days = runner.getBoolArgumentValue('alter_design_days', user_arguments)   # not used yet
    auto_date = runner.getBoolArgumentValue('auto_date', user_arguments)
    alt_periods = runner.getBoolArgumentValue('alt_periods', user_arguments)

    winter_start_month1 = 1
    winter_end_month1 = 5
    summer_start_month = 6
    summer_end_month = 9
    winter_start_month2 = 10
    winter_end_month2 = 12


######### GET CLIMATE ZONES ################
    if auto_date
      ashraeClimateZone = ''
      #climateZoneNUmber = ''
      climateZones = model.getClimateZones
      climateZones.climateZones.each do |climateZone|
        if climateZone.institution == 'ASHRAE'
          ashraeClimateZone = climateZone.value
          runner.registerInfo("Using ASHRAE Climate zone #{ashraeClimateZone}.")
        end
      end

      if ashraeClimateZone == '' # should this be not applicable or error?
        runner.registerError("Please assign an ASHRAE Climate Zone to your model using the site tab in the OpenStudio application. The measure can't make AEDG recommendations without this information.")
        return false # note - for this to work need to check for false in measure.rb and add return false there as well.
      end

      if alt_periods
        case ashraeClimateZone
        when '3A', '4A'
          starttime_cooling = '18:01:00'
          endtime_cooling = '21:59:00'
          starttime_heating1 = '17:01:00'
          endtime_heating1 = '20:59:00'
          starttime_heating2 = '17:01:00'
          endtime_heating2 = '20:59:00'
        when '5A'
          starttime_cooling = '14:01:00'
          endtime_cooling = '17:59:00'
          starttime_heating1 = '18:01:00'
          endtime_heating1 = '21:59:00'
          starttime_heating2 = '18:01:00'
          endtime_heating2 = '21:59:00'
        when '6A'
          starttime_cooling = '13:01:00'
          endtime_cooling = '16:59:00'
          starttime_heating1 = '17:01:00'
          endtime_heating1 = '20:59:00'
          starttime_heating2 = '17:01:00'
          endtime_heating2 = '20:59:00'
        end
      else
        case ashraeClimateZone
        when '2A', '2B', '4B', '4C', '5B', '5C', '6B'
          starttime_cooling = '17:01:00'
          endtime_cooling = '20:59:00'
          starttime_heating1 = '17:01:00'
          endtime_heating1 = '20:59:00'
          starttime_heating2 = '17:01:00'
          endtime_heating2 = '20:59:00'
        when '3A', '3C'
          starttime_cooling = '19:01:00'
          endtime_cooling = '22:59:00'
          starttime_heating1 = '17:01:00'
          endtime_heating1 = '20:59:00'
          starttime_heating2 = '17:01:00'
          endtime_heating2 = '20:59:00'
        when '3B'
          starttime_cooling = '18:01:00'
          endtime_cooling = '21:59:00'
          starttime_heating1 = '19:01:00'
          endtime_heating1 = '22:59:00'
          starttime_heating2 = '19:01:00'
          endtime_heating2 = '22:59:00'
        when '4A'
          starttime_cooling = '12:01:00'
          endtime_cooling = '15:59:00'
          starttime_heating1 = '16:01:00'
          endtime_heating1 = '19:59:00'
          starttime_heating2 = '16:01:00'
          endtime_heating2 = '19:59:00'
        when '5A'
          starttime_cooling = '20:01:00'
          endtime_cooling = '23:59:00'
          starttime_heating1 = '17:01:00'
          endtime_heating1 = '20:59:00'
          starttime_heating2 = '17:01:00'
          endtime_heating2 = '20:59:00'
        when '6A', '7A'
          starttime_cooling = '16:01:00'
          endtime_cooling = '19:59:00'
          starttime_heating1 = '18:01:00'
          endtime_heating1 = '21:59:00'
          starttime_heating2 = '18:01:00'
          endtime_heating2 = '21:59:00'
        end
      end
    end

    if starttime_cooling.to_f > endtime_cooling.to_f
      runner.registerError('For cooling adjustment, the end time should be larger than the start time.')
      return false
    end
    if starttime_heating1.to_f > endtime_heating1.to_f
      runner.registerError('For heating adjustment, the end time should be larger than the start time.')
      return false
    end
    if starttime_heating2.to_f > endtime_heating2.to_f
      runner.registerError('For heating adjustment, the end time should be larger than the start time.')
      return false
    end
    # if starttime_heating2.to_f < endtime_heating1.to_f
    #   runner.registerError('For heating adjustment, the second adjustment period should not overlap with the first one.')
    #   return false
    # end

    # ruby test to see if first charter of string is uppercase letter
    if cooling_adjustment < 0
      runner.registerWarning('Lowering the cooling setpoint will increase energy use.')
    elsif cooling_adjustment.abs > 500
      runner.registerError("#{cooling_adjustment} is a larger than typical setpoint adjustment")
      return false
    elsif cooling_adjustment.abs > 50
      runner.registerWarning("#{cooling_adjustment} is a larger than typical setpoint adjustment")
    end
    if heating_adjustment > 0
      runner.registerWarning('Raising the heating setpoint will increase energy use.')
    elsif heating_adjustment.abs > 500
      runner.registerError("#{heating_adjustment} is a larger than typical setpoint adjustment")
      return false
    elsif heating_adjustment.abs > 50
      runner.registerWarning("#{heating_adjustment} is a larger than typical setpoint adjustment")
    end

    # define starting units
    cooling_adjustment_ip = OpenStudio::Quantity.new(cooling_adjustment, TEMP_IP_UNIT)
    heating_adjustment_ip = OpenStudio::Quantity.new(heating_adjustment, TEMP_IP_UNIT)

    # push schedules to hash to avoid making unnecessary duplicates
    clg_set_schs = {}
    htg_set_schs = {}
    # get spaces
    thermostats = model.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      # setup new cooling setpoint schedule
      clg_set_sch = thermostat.coolingSetpointTemperatureSchedule
      if !clg_set_sch.empty?
        runner.registerInfo("#{clg_set_sch.get.name.to_s}")
        # clone of not alredy in hash
        if clg_set_schs.key?(clg_set_sch.get.name.to_s)
          new_clg_set_sch = clg_set_schs[clg_set_sch.get.name.to_s]
        else
          new_clg_set_sch = clg_set_sch.get.clone(model)
          new_clg_set_sch = new_clg_set_sch.to_Schedule.get
          new_clg_set_sch_name = new_clg_set_sch.setName("#{new_clg_set_sch.name} adjusted by #{cooling_adjustment_ip}")

          # add to the hash
          clg_set_schs[clg_set_sch.get.name.to_s] = new_clg_set_sch
        end
        # hook up clone to thermostat
        thermostat.setCoolingSetpointTemperatureSchedule(new_clg_set_sch)
        #runner.registerInfo("#{new_clg_set_sch.get.name.to_s}")
      else
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a cooling setpoint schedule")
      end

      # setup new heating setpoint schedule
      htg_set_sch = thermostat.heatingSetpointTemperatureSchedule
      if !htg_set_sch.empty?
        # clone of not already in hash
        if htg_set_schs.key?(htg_set_sch.get.name.to_s)
          new_htg_set_sch = htg_set_schs[htg_set_sch.get.name.to_s]
        else
          new_htg_set_sch = htg_set_sch.get.clone(model)
          new_htg_set_sch = new_htg_set_sch.to_Schedule.get
          new_htg_set_sch_name = new_htg_set_sch.setName("#{new_htg_set_sch.name} adjusted by #{heating_adjustment_ip}")

          # add to the hash
          htg_set_schs[htg_set_sch.get.name.to_s] = new_htg_set_sch
        end
        # hook up clone to thermostat
        thermostat.setHeatingSetpointTemperatureSchedule(new_htg_set_sch)
      else
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a heating setpoint schedule.")
      end
    end

    # setting up variables to use for initial and final condition
    clg_sch_set_values = [] # may need to flatten this
    htg_sch_set_values = [] # may need to flatten this
    final_clg_sch_set_values = []
    final_htg_sch_set_values = []

    # consider issuing a warning if the model has un-conditioned thermal zones (no ideal air loads or hvac)
    zones = model.getThermalZones
    zones.each do |zone|
      # if you have a thermostat but don't have ideal air loads or zone equipment then issue a warning
      if !zone.thermostatSetpointDualSetpoint.empty? && !zone.useIdealAirLoads && (zone.equipment.size <= 0)
        runner.registerWarning("Thermal zone '#{zone.name}' has a thermostat but does not appear to be conditioned.")
      end
    end
    shift_time1 = OpenStudio::Time.new(starttime_cooling)
    shift_time2 = OpenStudio::Time.new(endtime_cooling)
    shift_time3 = OpenStudio::Time.new(0, 24, 0, 0)    # not used
    shift_time4 = OpenStudio::Time.new(starttime_heating1)
    shift_time5 = OpenStudio::Time.new(endtime_heating1)
    shift_time6 = OpenStudio::Time.new(starttime_heating2)
    shift_time7 = OpenStudio::Time.new(endtime_heating2)
    # make cooling schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset


    clg_set_schs.each do |sch_name, os_sch| # old name and new object for schedule
      if !os_sch.to_ScheduleRuleset.empty?

        schedule = os_sch.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules

        days_covered = Array.new(7, false)

        if rules.length > 0
          rules.each do |rule|
            winterStartDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month1), 1)
            winterEndDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month1), 31)

            winter_rule1 = rule.clone(model).to_ScheduleRule.get
            winter_rule1.setStartDate(winterStartDate1)
            winter_rule1.setEndDate(winterEndDate1)

            allDaysCovered(winter_rule1, days_covered)

            cloned_day_winter = rule.daySchedule.clone(model)
            cloned_day_winter.setParent(winter_rule1)

            winterStartDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month2), 1)
            winterEndDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month2), 31)

            winter_rule2 = winter_rule1.clone(model).to_ScheduleRule.get
            winter_rule2.setStartDate(winterStartDate2)
            winter_rule2.setEndDate(winterEndDate2)

            cloned_day_winter2 = cloned_day_winter.clone(model)
            cloned_day_winter2.setParent(winter_rule2)

            summerStartDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_start_month), 1)
            summerEndDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_end_month), 30)

            summer_rule = rule #rule.clone(model).to_ScheduleRule.get
            summer_rule.setStartDate(summerStartDate)
            summer_rule.setEndDate(summerEndDate)

            cloned_day_summer = rule.daySchedule.clone(model)
            cloned_day_summer.setParent(summer_rule)

            summer_day = summer_rule.daySchedule
            day_time_vector = summer_day.times
            day_value_vector = summer_day.values
            summer_day.clearValues

            summer_day = updateDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time1, shift_time2, cooling_adjustment_ip)
            final_clg_sch_set_values << summer_day.values
          end
        end


        if days_covered.include?(false)
          winterStartDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month1), 1)
          winterEndDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month1), 31)

          winter_rule1 = OpenStudio::Model::ScheduleRule.new(schedule)
          winter_rule1.setStartDate(winterStartDate1)
          winter_rule1.setEndDate(winterEndDate1)

          coverSomeDays(winter_rule1, days_covered)
          allDaysCovered(winter_rule1, days_covered)

          cloned_day_winter = default_rule.clone(model)
          cloned_day_winter.setParent(winter_rule1)

          winterStartDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month2), 1)
          winterEndDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month2), 31)

          winter_rule2 = winter_rule1.clone(model).to_ScheduleRule.get
          winter_rule2.setStartDate(winterStartDate2)
          winter_rule2.setEndDate(winterEndDate2)

          cloned_day_winter2 = cloned_day_winter.clone(model)
          cloned_day_winter2.setParent(winter_rule2)

          summerStartDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_start_month), 1)
          summerEndDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_end_month), 30)

          summer_rule = winter_rule1.clone(model).to_ScheduleRule.get
          summer_rule.setStartDate(summerStartDate)
          summer_rule.setEndDate(summerEndDate)

          cloned_day_summer = default_rule.clone(model)
          cloned_day_summer.setParent(summer_rule)

          summer_day = summer_rule.daySchedule
          day_time_vector = summer_day.times
          day_value_vector = summer_day.values
          summer_day.clearValues

          summer_day = updateDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time1, shift_time2, cooling_adjustment_ip)
          final_clg_sch_set_values << summer_day.values
        end

        ######################################################################
      else
        runner.registerWarning("Schedule '#{sch_name}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        os_sch.remove # remove un-used clone
      end
    end

    # make heating schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
    htg_set_schs.each do |sch_name, os_sch| # old name and new object for schedule
      if !os_sch.to_ScheduleRuleset.empty?
        schedule = os_sch.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules

        days_covered = Array.new(7, false)

        if rules.length > 0
          rules.each do |rule|
            summerStartDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_start_month), 1)
            summerEndDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_end_month), 30)

            summer_rule = rule.clone(model).to_ScheduleRule.get
            summer_rule.setStartDate(summerStartDate)
            summer_rule.setEndDate(summerEndDate)

            allDaysCovered(summer_rule, days_covered)

            cloned_day_summer = rule.daySchedule.clone(model)
            cloned_day_summer.setParent(summer_rule)

            winterStartDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month1), 1)
            winterEndDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month1), 31)

            winter_rule1 = rule #rule.clone(model).to_ScheduleRule.get
            winter_rule1.setStartDate(winterStartDate1)
            winter_rule1.setEndDate(winterEndDate1)

            cloned_day_winter = rule.daySchedule.clone(model)
            cloned_day_winter.setParent(winter_rule1)

            winter_day1 = winter_rule1.daySchedule
            day_time_vector = winter_day1.times
            day_value_vector = winter_day1.values
            winter_day1.clearValues

            winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time4, shift_time5, heating_adjustment_ip)
            if shift_time4 != shift_time6
            	winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time6, shift_time7, heating_adjustment_ip)
            end

            final_htg_sch_set_values << winter_day1.values

            winterStartDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month2), 1)
            winterEndDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month2), 31)

            winter_rule2 = winter_rule1.clone(model).to_ScheduleRule.get
            winter_rule2.setStartDate(winterStartDate2)
            winter_rule2.setEndDate(winterEndDate2)

            cloned_day_winter2 = winter_day1.clone(model)
            cloned_day_winter2.setParent(winter_rule2)

          end
        end


        if days_covered.include?(false)

            summerStartDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_start_month), 1)
            summerEndDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(summer_end_month), 30)

            summer_rule = OpenStudio::Model::ScheduleRule.new(schedule)
            summer_rule.setStartDate(summerStartDate)
            summer_rule.setEndDate(summerEndDate)

            coverSomeDays(summer_rule, days_covered)
            allDaysCovered(summer_rule, days_covered)

            cloned_day_summer = default_rule.clone(model)
            cloned_day_summer.setParent(summer_rule)

            winterStartDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month1), 1)
            winterEndDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month1), 31)

            winter_rule1 = summer_rule.clone(model).to_ScheduleRule.get
            winter_rule1.setStartDate(winterStartDate1)
            winter_rule1.setEndDate(winterEndDate1)

            cloned_day_winter = default_rule.clone(model)
            cloned_day_winter.setParent(winter_rule1)

            winter_day1 = winter_rule1.daySchedule
            day_time_vector = winter_day1.times
            day_value_vector = winter_day1.values
            winter_day1.clearValues

            winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time4, shift_time5, heating_adjustment_ip)
            if shift_time4 != shift_time6
            	winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time6, shift_time7, heating_adjustment_ip)
            end

            final_htg_sch_set_values << winter_day1.values

            winterStartDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_start_month2), 1)
            winterEndDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(winter_end_month2), 31)

            winter_rule2 = winter_rule1.clone(model).to_ScheduleRule.get
            winter_rule2.setStartDate(winterStartDate2)
            winter_rule2.setEndDate(winterEndDate2)

            cloned_day_winter2 = winter_day1.clone(model)
            cloned_day_winter2.setParent(winter_rule2)

        end

      else
        runner.registerWarning("Schedule '#{sch_name}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        os_sch.remove # remove un-used clone
      end
    end


    # get min and max heating and cooling and convert to IP
    clg_sch_set_values = clg_sch_set_values.flatten
    htg_sch_set_values = htg_sch_set_values.flatten

    # set NA flag if can't get values for schedules (e.g. if all compact)
    applicable_flag = false

    # get min and max if values exist
    if !clg_sch_set_values.empty?
      min_clg_si = OpenStudio::Quantity.new(clg_sch_set_values.min, TEMP_SI_UNIT)
      max_clg_si = OpenStudio::Quantity.new(clg_sch_set_values.max, TEMP_SI_UNIT)
      min_clg_ip = OpenStudio.convert(min_clg_si, TEMP_IP_UNIT).get
      max_clg_ip = OpenStudio.convert(max_clg_si, TEMP_IP_UNIT).get
      applicable_flag = true
    else
      min_clg_ip = 'NA'
      max_clg_ip = 'NA'
    end

    # get min and max if values exist
    if !htg_sch_set_values.empty?
      min_htg_si = OpenStudio::Quantity.new(htg_sch_set_values.min, TEMP_SI_UNIT)
      max_htg_si = OpenStudio::Quantity.new(htg_sch_set_values.max, TEMP_SI_UNIT)
      min_htg_ip = OpenStudio.convert(min_htg_si, TEMP_IP_UNIT).get
      max_htg_ip = OpenStudio.convert(max_htg_si, TEMP_IP_UNIT).get
      applicable_flag = true
    else
      min_htg_ip = 'NA'
      max_htg_ip = 'NA'
    end

    # not applicable if no schedules can be altered
    if applicable_flag == false
      runner.registerAsNotApplicable('No thermostat schedules in the models could be altered.')
    end

    # reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("Initial cooling setpoints used in the model range from #{min_clg_ip} to #{max_clg_ip}. Initial heating setpoints used in the model range from #{min_htg_ip} to #{max_htg_ip}.")

    # get min and max heating and cooling and convert to IP for final
    final_clg_sch_set_values = final_clg_sch_set_values.flatten
    final_htg_sch_set_values = final_htg_sch_set_values.flatten

    if !clg_sch_set_values.empty?
      final_min_clg_si = OpenStudio::Quantity.new(final_clg_sch_set_values.min, TEMP_SI_UNIT)
      final_max_clg_si = OpenStudio::Quantity.new(final_clg_sch_set_values.max, TEMP_SI_UNIT)
      final_min_clg_ip = OpenStudio.convert(final_min_clg_si, TEMP_IP_UNIT).get
      final_max_clg_ip = OpenStudio.convert(final_max_clg_si, TEMP_IP_UNIT).get
    else
      final_min_clg_ip = 'NA'
      final_max_clg_ip = 'NA'
    end

    # get min and max if values exist
    if !htg_sch_set_values.empty?
      final_min_htg_si = OpenStudio::Quantity.new(final_htg_sch_set_values.min, TEMP_SI_UNIT)
      final_max_htg_si = OpenStudio::Quantity.new(final_htg_sch_set_values.max, TEMP_SI_UNIT)
      final_min_htg_ip = OpenStudio.convert(final_min_htg_si, TEMP_IP_UNIT).get
      final_max_htg_ip = OpenStudio.convert(final_max_htg_si, TEMP_IP_UNIT).get
    else
      final_min_htg_ip = 'NA'
      final_max_htg_ip = 'NA'
    end

    # reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("Final cooling setpoints used in the model range from #{final_min_clg_ip} to #{final_max_clg_ip}. Final heating setpoints used in the model range from #{final_min_htg_ip} to #{final_max_htg_ip}.\n The cooling setpoints are increased by #{cooling_adjustment}F，from #{starttime_cooling} to #{endtime_cooling}. \n The heating setpoints are decreased by #{0-heating_adjustment}F，from #{starttime_heating2} to #{endtime_heating2}.")

    return true
  end


  def allDaysCovered(sch_rule, sch_day_covered)
    if sch_rule.applySunday
      sch_day_covered[0] = true
    end
    if sch_rule.applyMonday
      sch_day_covered[1] = true
    end
    if sch_rule.applyTuesday
      sch_day_covered[2] = true
    end
    if sch_rule.applyWednesday
      sch_day_covered[3] = true
    end
    if sch_rule.applyThursday
      sch_day_covered[4] = true
    end
    if sch_rule.applyFriday
      sch_day_covered[5] = true
    end
    if sch_rule.applySaturday
      sch_day_covered[6] = true
    end
  end

  def coverSomeDays(sch_rule, sch_day_covered)
    if sch_day_covered[0] == false
      sch_rule.setApplySunday(true)
    end
    if sch_day_covered[1] == false
      sch_rule.setApplyMonday(true)
    end
    if sch_day_covered[2] == false
      sch_rule.setApplyTuesday(true)
    end
    if sch_day_covered[3] == false
      sch_rule.setApplyWednesday(true)
    end
    if sch_day_covered[4] == false
      sch_rule.setApplyThursday(true)
    end
    if sch_day_covered[5] == false
      sch_rule.setApplyFriday(true)
    end
    if sch_day_covered[6] == false
      sch_rule.setApplySaturday(true)
    end

  end

  def updateDaySchedule(sch_day, vec_time, vec_value, time_begin, time_end, adjustment)
    # indicator: 0:schedule unchanged, 1:schedule changed at least once, 2:schedule change completed
    count = 0
    for i in 0..(vec_time.size - 1)
      v_si = OpenStudio::Quantity.new(vec_value[i], TEMP_SI_UNIT)
      v_ip = OpenStudio.convert(v_si, TEMP_IP_UNIT).get
      target_v_ip = v_ip + adjustment
      target_temp_si = OpenStudio.convert(target_v_ip, TEMP_SI_UNIT).get
      if vec_time[i]>time_begin&&vec_time[i]<time_end && count == 0
        sch_day.addValue(time_begin, vec_value[i])
        sch_day.addValue(vec_time[i],target_temp_si.value)
        count = 1
      elsif vec_time[i]>time_end && count == 0
        sch_day.addValue(time_begin,vec_value[i])
        sch_day.addValue(time_end,target_temp_si.value)
        sch_day.addValue(vec_time[i],vec_value[i])
        count = 2
      elsif vec_time[i]>time_begin && vec_time[i]<=time_end && count==1
        sch_day.addValue(vec_time[i], vec_value[i])
      elsif vec_time[i]>time_end && count == 1
        sch_day.addValue(time_end, target_temp_si)
        sch_day.addValue(vec_time[i], vec_value[i])
        count = 2
      else
        # override
        target_v_ip = v_ip
        target_temp_si = OpenStudio.convert(target_v_ip, TEMP_SI_UNIT).get
        sch_day.addValue(vec_time[i], target_temp_si.value)
      end
    end
    return sch_day
  end
end



# this allows the measure to be used by the application
DRHVACLgOffice.new.registerWithApplication
