# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class Preheating < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return "Preheating"
  end
  # human readable description
  def description
    return "This measure adjusts heating schedules by a user specified number of degrees for the specified time period of a day. User can also specify the start and end date for the adjustment. This is applied throughout the entire building."
  end
  # human readable description of modeling approach
  def modeler_description
    return "This measure will clone all of the schedules that are used as heating setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values. HVAC operation schedule will also be changed. "
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for adjustment to cooling setpoint
    heating_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_adjustment', true)
    heating_adjustment.setDisplayName('Degrees Fahrenheit to Adjust Heating Setpoint By')
    heating_adjustment.setDefaultValue(4.0)
    args << heating_adjustment
    
    # make an argument for the start date of cooling adjustment
    heating_startdate1 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_startdate1', false)
    heating_startdate1.setDisplayName('First Start Date for Pre-heating')
    heating_startdate1.setDescription('In MM-DD format')
    heating_startdate1.setDefaultValue('01-01')
    args << heating_startdate1

    # make an argument for the end date of cooling adjustment
    heating_enddate1 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_enddate1', false)
    heating_enddate1.setDisplayName('First End Date for Pre-heating')
    heating_enddate1.setDescription('In MM-DD format')
    heating_enddate1.setDefaultValue('05-31')
    args << heating_enddate1


    # make an argument for the start date of cooling adjustment
    heating_startdate2 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_startdate2', false)
    heating_startdate2.setDisplayName('Second Start Date for Pre-heating')
    heating_startdate2.setDescription('In MM-DD format')
    heating_startdate2.setDefaultValue('10-01')
    args << heating_startdate2

    # make an argument for the end date of cooling adjustment
    heating_enddate2 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_enddate2', false)
    heating_enddate2.setDisplayName('First End Date for Pre-heating')
    heating_enddate2.setDescription('In MM-DD format')
    heating_enddate2.setDefaultValue('12-31')
    args << heating_enddate2
    
    starttime_heating = OpenStudio::Measure::OSArgument.makeStringArgument('starttime_heating', true)
    starttime_heating.setDisplayName('Start Time for Pre-heating')
    starttime_heating.setDescription('In HH:MM:SS format')
    starttime_heating.setDefaultValue('00:01:00')
    args << starttime_heating

    # make an argument for the end time of pre-cooling/heating
    endtime_heating = OpenStudio::Measure::OSArgument.makeStringArgument('endtime_heating', true)
    endtime_heating.setDisplayName('End Time for Pre-heating')
    endtime_heating.setDescription('In HH:MM:SS format')
    endtime_heating.setDefaultValue('04:59:00')
    args << endtime_heating

    # alter_design_days = OpenStudio::Measure::OSArgument.makeBoolArgument('alter_design_days', true)
    # alter_design_days.setDisplayName('Alter Design Day Thermostats')
    # alter_design_days.setDefaultValue(false)
    # args << alter_design_days

    auto_date = OpenStudio::Measure::OSArgument.makeBoolArgument('auto_date', true)
    auto_date.setDisplayName('Enable Climate-specific Periods Setting ?')
    auto_date.setDefaultValue(true)
    args << auto_date

    alt_periods = OpenStudio::Measure::OSArgument.makeBoolArgument('alt_periods', true)
    alt_periods.setDisplayName('Alternate Peak and Take Periods ?')
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
    heating_adjustment = runner.getDoubleArgumentValue('heating_adjustment', user_arguments)
    # alter_design_days = runner.getBoolArgumentValue('alter_design_days', user_arguments)
    starttime_heating = runner.getStringArgumentValue('starttime_heating', user_arguments)
    endtime_heating = runner.getStringArgumentValue('endtime_heating', user_arguments)

    heating_startdate1 = runner.getStringArgumentValue('heating_startdate1', user_arguments)
    heating_enddate1 = runner.getStringArgumentValue('heating_enddate1', user_arguments)
    heating_startdate2 = runner.getStringArgumentValue('heating_startdate2', user_arguments)
    heating_enddate2 = runner.getStringArgumentValue('heating_enddate2', user_arguments)
    auto_date = runner.getBoolArgumentValue('auto_date', user_arguments)
    alt_periods = runner.getBoolArgumentValue('alt_periods', user_arguments)


    heating_start_month1 = nil
    heating_start_day1 = nil
    md = /(\d\d)-(\d\d)/.match(heating_startdate1)
    if md
      heating_start_month1 = md[1].to_i
      heating_start_day1 = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    
    heating_end_month1 = nil
    heating_end_day1 = nil
    md = /(\d\d)-(\d\d)/.match(heating_enddate1)
    if md
      heating_end_month1 = md[1].to_i
      heating_end_day1 = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end
    
    heating_start_month2 = nil
    heating_start_day2 = nil
    md = /(\d\d)-(\d\d)/.match(heating_startdate2)
    if md
      heating_start_month2 = md[1].to_i
      heating_start_day2 = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    
    heating_end_month2 = nil
    heating_end_day2 = nil
    md = /(\d\d)-(\d\d)/.match(heating_enddate2)
    if md
      heating_end_month2 = md[1].to_i
      heating_end_day2 = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end


    winterStartDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_start_month1), heating_start_day1)
    winterEndDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_end_month1), heating_end_day1)
    winterStartDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_start_month2), heating_start_day2)
    winterEndDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_end_month2), heating_end_day2)
    summerStartDate = winterEndDate1 + OpenStudio::Time.new(1)
    summerEndDate = winterStartDate2 - OpenStudio::Time.new(1)


    ######### GET CLIMATE ZONES ################
    if auto_date
      ashraeClimateZone = nil
      #climateZoneNUmber = ''
      climateZones = model.getClimateZones
      climateZones.climateZones.each do |climateZone|
        if climateZone.institution == 'ASHRAE'
          ashraeClimateZone = climateZone.value
          runner.registerInfo("Using ASHRAE Climate zone #{ashraeClimateZone}.")
        end
      end

      unless ashraeClimateZone # should this be not applicable or error?
        runner.registerError("If you select to use alternative default start and end time based on the climate zone, please assign an ASHRAE climate zone to your model.")
        return false # note - for this to work need to check for false in measure.rb and add return false there as well.
      end

      if alt_periods
        case ashraeClimateZone
        when '3A','4A'
          starttime_heating = '14:01:00'
          endtime_heating = '17:59:00'
        when '5A'
          starttime_heating = '10:01:00'
          endtime_heating = '13:59:00'
        when '6A'
          starttime_heating = '9:01:00'
          endtime_heating = '12:59:00'
        end

      else
        case ashraeClimateZone
        when '2A', '2B', '4B', '4C', '5B', '5C', '6B'
          starttime_heating = '13:01:00'
          endtime_heating = '16:59:00'
        when '3A', '3C'
          starttime_heating = '15:01:00'
          endtime_heating = '18:59:00'
        when '3B'
          starttime_heating = '14:01:00'
          endtime_heating = '17:59:00'
        when '4A'
          starttime_heating = '8:01:00'
          endtime_heating = '11:59:00'
        when '5A'
          starttime_heating = '16:01:00'
          endtime_heating = '19:59:00'
        when '6A', '7A'
          starttime_heating = '12:01:00'
          endtime_heating = '15:59:00'
        end

      end
    end

    # shift_time1 = OpenStudio::Time.new(starttime_heating)
    # shift_time2 = OpenStudio::Time.new(endtime_heating)
    # shift_time3 = OpenStudio::Time.new(0,6,0,0)
    # shift_time4 = OpenStudio::Time.new(starttime_heating)
    # shift_time5 = OpenStudio::Time.new(endtime_heating)

    if /(\d\d):(\d\d):(\d\d)/.match(starttime_heating)
      shift_time1 = OpenStudio::Time.new(starttime_heating)
    else
      runner.registerError('Start time must be in HH-MM-SS format.')
      return false
    end

    if /(\d\d):(\d\d):(\d\d)/.match(endtime_heating)
      shift_time2 = OpenStudio::Time.new(endtime_heating)
    else
      runner.registerError('End time must be in HH-MM-SS format.')
      return false
    end

    if starttime_heating.to_f > endtime_heating.to_f
      runner.registerError('The end time should be larger than the start time.')
      return false
    end

    # ruby test to see if first charter of string is uppercase letter
    if heating_adjustment < 0
      runner.registerWarning('Lowering heating setpoint will not do pre-heating.')
    elsif heating_adjustment.abs > 500
      runner.registerError("Adjustment #{heating_adjustment} is too large to be correct. Please double check your input")
      return false
    elsif heating_adjustment.abs > 50
      runner.registerWarning("Adjustment #{heating_adjustment} is larger than typical setpoint adjustment. Please double check your input")
    end

    # setup OpenStudio units that we will need
    temperature_ip_unit = OpenStudio.createUnit('F').get
    temperature_si_unit = OpenStudio.createUnit('C').get
    # define starting units
    # heating_adjustment_ip = OpenStudio::Quantity.new(heating_adjustment, temperature_ip_unit)
    heating_adjustment_si = heating_adjustment*5/9

    # update the availability schedule
    air_loop_avail_schs = {}
    air_loops = model.getAirLoopHVACs
    air_loops.each do |air_loop|
      avail_sch = air_loop.availabilitySchedule

      if air_loop_avail_schs.key?(avail_sch.name.to_s)
        new_avail_sch = air_loop_avail_schs[avail_sch.name.to_s]
      else
        new_avail_sch = avail_sch.clone(model).to_Schedule.get
        new_avail_sch.setName("#{avail_sch.name.to_s} adjusted")
        # add to the hash
        air_loop_avail_schs[avail_sch.name.to_s] = new_avail_sch
      end
      air_loop.setAvailabilitySchedule(new_avail_sch)

    end

    air_loop_avail_schs.each do |sch_name, air_loop_sch|
      runner.registerInfo("Air Loop Schedule #{sch_name}:")
      if air_loop_sch.to_ScheduleRuleset.empty?
        runner.registerWarning("Schedule #{sch_name} isn't a ScheduleRuleset object and won't be altered by this measure.")
        air_loop_sch.remove # remove un-used clone
      else
        schedule = air_loop_sch.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules
        days_covered = Array.new(7, false)

        rules.each do |rule|
          winter_avail_rule1 = copy_sch_rule_for_period(model, rule, rule.daySchedule, winterStartDate1, winterEndDate1)
          winter_avail_rule2 = copy_sch_rule_for_period(model, rule, rule.daySchedule, winterStartDate2, winterEndDate2)
          runner.registerInfo("    ------------ time: #{rule.daySchedule.times.map {|os_time| os_time.toString}}")
          runner.registerInfo("    ------------ values: #{rule.daySchedule.values}")
          summer_avail_rule = rule.clone(model).to_ScheduleRule.get
          summer_avail_rule.setStartDate(summerStartDate)
          summer_avail_rule.setEndDate(summerEndDate)

          checkDaysCovered(summer_avail_rule, days_covered)

          summer_avail_day = summer_avail_rule.daySchedule
          day_time_vector = summer_avail_day.times
          day_value_vector = summer_avail_day.values
          summer_avail_day.clearValues

          summer_avail_day = updateAvailDaySchedule(summer_avail_day, day_time_vector, day_value_vector, shift_time1, shift_time2)
          runner.registerInfo("    ------------ updated time: #{summer_avail_day.times.map {|os_time| os_time.toString}}")
          runner.registerInfo("    ------------ uodated values: #{summer_avail_day.values}")

        end

        if days_covered.include?(false)

          winter_rule1 = create_sch_rule_from_default(model, schedule, default_rule, winterStartDate1, winterEndDate1)
          winter_rule2 = create_sch_rule_from_default(model, schedule, default_rule, winterStartDate2, winterEndDate2)

          coverMissingDays(winter_rule1, days_covered)
          checkDaysCovered(winter_rule1, days_covered)

          summer_rule = copy_sch_rule_for_period(model, winter_rule1, default_rule, summerStartDate, summerEndDate)

          summer_day = summer_rule.daySchedule
          day_time_vector = summer_day.times
          day_value_vector = summer_day.values
          summer_day.clearValues

          summer_day = updateAvailDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time1, shift_time2)

        end
      end
    end


    applicable =  false
    # push schedules to hash to avoid making unnecessary duplicates
    htg_set_schs = {}
    # get spaces
    thermostats = model.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      # setup new cooling setpoint schedule
      htg_set_sch = thermostat.heatingSetpointTemperatureSchedule
      if htg_set_sch.empty?
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a heating setpoint schedule")
      else
        # clone of not alredy in hash
        if htg_set_schs.key?(htg_set_sch.get.name.to_s)
          new_htg_set_sch = htg_set_schs[htg_set_sch.get.name.to_s]
        else
          new_htg_set_sch = htg_set_sch.get.clone(model).to_Schedule.get
          new_htg_set_sch.setName("#{htg_set_sch.get.name.to_s} adjusted by #{heating_adjustment}")
          htg_set_schs[htg_set_sch.get.name.to_s] = new_htg_set_sch
        end
        # hook up clone to thermostat
        thermostat.setHeatingSetpointTemperatureSchedule(new_htg_set_sch)
      end

    end


    # consider issuing a warning if the model has un-conditioned thermal zones (no ideal air loads or hvac)
    zones = model.getThermalZones
    zones.each do |zone|
      # if you have a thermostat but don't have ideal air loads or zone equipment then issue a warning
      if !zone.thermostatSetpointDualSetpoint.empty? && !zone.useIdealAirLoads && (zone.equipment.size <= 0)
        runner.registerWarning("Thermal zone '#{zone.name}' has a thermostat but does not appear to be conditioned.")
      end
    end

    # make cooling schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
    htg_set_schs.each do |sch_name, heating_schedule| # old name and new object for schedule
      if heating_schedule.to_ScheduleRuleset.empty?
        runner.registerWarning("Schedule #{sch_name} isn't a ScheduleRuleset object and won't be altered by this measure.")
        heating_schedule.remove # remove un-used clone
      else
        schedule = heating_schedule.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules
        days_covered = Array.new(7, false)
        if rules.length > 0
          runner.registerInfo("Schedule #{sch_name} has #{rules.length} rules.")
          rules.each do |rule|
            runner.registerInfo("------------ Rule #{rule.ruleIndex}: #{rule.daySchedule.name.to_s}")
            # Use the original schedule rule to cover the rest of the year
            summer_rule = copy_sch_rule_for_period(model, rule, rule.daySchedule, summerStartDate, summerEndDate)
            winter_rule1 = rule
            checkDaysCovered(winter_rule1, days_covered)
            winter_rule1.setStartDate(winterStartDate1)
            winter_rule1.setEndDate(winterEndDate1)

            winter_day1 = winter_rule1.daySchedule
            day_time_vector = winter_day1.times
            day_value_vector = winter_day1.values
            unless day_value_vector.empty?
              applicable = true
            end
            winter_day1.clearValues

            winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time1, shift_time2, heating_adjustment_si)
            winter_rule2 = copy_sch_rule_for_period(model, winter_rule1, winter_rule1.daySchedule, winterStartDate2, winterEndDate2)

          end
        else
          runner.registerWarning("Heating setpoint schedule #{sch_name} is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
        end

        if days_covered.include?(false)
          summer_rule = create_sch_rule_from_default(model, schedule, default_rule, summerStartDate, summerEndDate)
          coverMissingDays(summer_rule, days_covered)
          checkDaysCovered(summer_rule, days_covered)

          winter_rule1 = copy_sch_rule_for_period(model, summer_rule, default_rule, winterStartDate1, winterEndDate1)
          winter_day1 = winter_rule1.daySchedule
          day_time_vector = winter_day1.times
          day_value_vector = winter_day1.values
          winter_day1.clearValues

          winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time1, shift_time2, heating_adjustment_si)
          winter_rule2 = copy_sch_rule_for_period(model, winter_rule1, winter_rule1.daySchedule, winterStartDate2, winterEndDate2)

        end
      end
    end

    # not applicable if no schedules can be altered
    unless applicable
      runner.registerAsNotApplicable('No thermostat schedules in the models could be altered.')
    end

    return true
  end



  def updateAvailDaySchedule(sch_day, vec_time, vec_value, time_begin, time_end)
    count = 0
    vec_time.each_with_index do |exist_timestamp, i|
      adjusted_value = 1
      if exist_timestamp > time_begin && exist_timestamp < time_end && count == 0
        sch_day.addValue(time_begin, vec_value[i])
        sch_day.addValue(exist_timestamp, adjusted_value)
        count = 1
      elsif exist_timestamp == time_end && count == 0
        sch_day.addValue(time_begin, vec_value[i])
        sch_day.addValue(exist_timestamp, adjusted_value)
        count = 2
      elsif exist_timestamp == time_begin && count == 0
        sch_day.addValue(exist_timestamp, vec_value[i])
        count = 1
      elsif exist_timestamp > time_end && count == 0
        sch_day.addValue(time_begin, vec_value[i])
        sch_day.addValue(time_end, adjusted_value)
        sch_day.addValue(exist_timestamp,  vec_value[i])
        count = 2
      elsif exist_timestamp > time_begin && exist_timestamp < time_end && count==1
        sch_day.addValue(exist_timestamp, adjusted_value)
      elsif exist_timestamp == time_end && count==1
        sch_day.addValue(exist_timestamp, adjusted_value)
        count = 2
      elsif exist_timestamp > time_end && count == 1
        sch_day.addValue(time_end, adjusted_value)
        sch_day.addValue(exist_timestamp, vec_value[i])
        count = 2
      else
        sch_day.addValue(exist_timestamp, vec_value[i])
      end
    end

    return sch_day
  end


  def copy_sch_rule_for_period(model, sch_rule, sch_day, start_date, end_date)
    new_rule = sch_rule.clone(model).to_ScheduleRule.get
    new_rule.setStartDate(start_date)
    new_rule.setEndDate(end_date)

    new_day_sch = sch_day.clone(model)
    new_day_sch.setParent(new_rule)

    return new_rule
  end

  def create_sch_rule_from_default(model, sch_ruleset, default_sch_fule, start_date, end_date)
    new_rule = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    new_rule.setStartDate(start_date)
    new_rule.setEndDate(end_date)

    new_day_sch = default_sch_fule.clone(model)
    new_day_sch.setParent(new_rule)

    return new_rule
  end

  def updateDaySchedule(sch_day, vec_time, vec_value, time_begin, time_end, adjustment)
    count = 0
    vec_time.each_with_index do |exist_timestamp, i|
      adjusted_value = vec_value[i] + adjustment
      if exist_timestamp > time_begin && exist_timestamp < time_end && count == 0
        sch_day.addValue(time_begin, vec_value[i])
        sch_day.addValue(exist_timestamp, adjusted_value)
        count = 1
      elsif exist_timestamp == time_end && count == 0
        sch_day.addValue(time_begin, vec_value[i])
        sch_day.addValue(exist_timestamp, adjusted_value)
        count = 2
      elsif exist_timestamp == time_begin && count == 0
        sch_day.addValue(exist_timestamp, vec_value[i])
        count = 1
      elsif exist_timestamp > time_end && count == 0
        sch_day.addValue(time_begin, vec_value[i])
        sch_day.addValue(time_end, adjusted_value)
        sch_day.addValue(exist_timestamp,  vec_value[i])
        count = 2
      elsif exist_timestamp > time_begin && exist_timestamp < time_end && count==1
        sch_day.addValue(exist_timestamp, adjusted_value)
      elsif exist_timestamp == time_end && count==1
        sch_day.addValue(exist_timestamp, adjusted_value)
        count = 2
      elsif exist_timestamp > time_end && count == 1
        sch_day.addValue(time_end, adjusted_value)
        sch_day.addValue(exist_timestamp, vec_value[i])
        count = 2
      else
        sch_day.addValue(exist_timestamp, vec_value[i])
      end
    end

    return sch_day
  end

  def checkDaysCovered(sch_rule, sch_day_covered)
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

  def coverMissingDays(sch_rule, sch_day_covered)
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


end

# this allows the measure to be used by the application
Preheating.new.registerWithApplication
