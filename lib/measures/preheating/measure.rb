# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
require 'json'
require 'set'
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
    heating_adjustment.setDescription('Use positive value for increasing heating setpoint during preheating period')
    heating_adjustment.setDefaultValue(4.0)
    args << heating_adjustment

    start_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date1', true)
    start_date1.setDisplayName('First start date for preheating')
    start_date1.setDescription('In MM-DD format')
    start_date1.setDefaultValue('06-01')
    args << start_date1
    end_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date1', true)
    end_date1.setDisplayName('First end date for preheating')
    end_date1.setDescription('In MM-DD format')
    end_date1.setDefaultValue('09-30')
    args << end_date1

    start_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date2', false)
    start_date2.setDisplayName('Second start date for preheating (optional)')
    start_date2.setDescription('Specify a date in MM-DD format if you want a second season of preheating; leave blank if not needed.')
    start_date2.setDefaultValue('')
    args << start_date2
    end_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date2', false)
    end_date2.setDisplayName('Second end date for preheating')
    end_date2.setDescription('Specify a date in MM-DD format if you want a second season of preheating; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date2.setDefaultValue('')
    args << end_date2


    start_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date3', false)
    start_date3.setDisplayName('Third start date for preheating (optional)')
    start_date3.setDescription('Specify a date in MM-DD format if you want a third season of preheating; leave blank if not needed.')
    start_date3.setDefaultValue('')
    args << start_date3
    end_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date3', false)
    end_date3.setDisplayName('Third end date for preheating')
    end_date3.setDescription('Specify a date in MM-DD format if you want a third season of preheating; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date3.setDefaultValue('')
    args << end_date3

    start_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date4', false)
    start_date4.setDisplayName('Fourth start date for preheating (optional)')
    start_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of preheating; leave blank if not needed.')
    start_date4.setDefaultValue('')
    args << start_date4
    end_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date4', false)
    end_date4.setDisplayName('Fourth end date for preheating')
    end_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of preheating; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date4.setDefaultValue('')
    args << end_date4


    start_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date5', false)
    start_date5.setDisplayName('Fifth start date for preheating (optional)')
    start_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of preheating; leave blank if not needed.')
    start_date5.setDefaultValue('')
    args << start_date5
    end_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date5', false)
    end_date5.setDisplayName('Fifth end date for preheating')
    end_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of preheating; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date5.setDefaultValue('')
    args << end_date5

    start_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time1', true)
    start_time1.setDisplayName('Start time of preheating for the first season')
    start_time1.setDescription('In HH:MM:SS format')
    start_time1.setDefaultValue('17:00:00')
    args << start_time1
    end_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time1', true)
    end_time1.setDisplayName('End time of preheating for the first season')
    end_time1.setDescription('In HH:MM:SS format')
    end_time1.setDefaultValue('21:00:00')
    args << end_time1


    start_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time2', false)
    start_time2.setDisplayName('Start time of preheating for the second season (optional)')
    start_time2.setDescription('In HH:MM:SS format')
    start_time2.setDefaultValue('')
    args << start_time2
    end_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time2', false)
    end_time2.setDisplayName('End time of preheating for the second season (optional)')
    end_time2.setDescription('In HH:MM:SS format')
    end_time2.setDefaultValue('')
    args << end_time2


    start_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time3', false)
    start_time3.setDisplayName('Start time of preheating for the third season (optional)')
    start_time3.setDescription('In HH:MM:SS format')
    start_time3.setDefaultValue('')
    args << start_time3
    end_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time3', false)
    end_time3.setDisplayName('End time of preheating for the third season (optional)')
    end_time3.setDescription('In HH:MM:SS format')
    end_time3.setDefaultValue('')
    args << end_time3


    start_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time4', false)
    start_time4.setDisplayName('Start time of preheating for the fourth season (optional)')
    start_time4.setDescription('In HH:MM:SS format')
    start_time4.setDefaultValue('')
    args << start_time4
    end_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time4', false)
    end_time4.setDisplayName('End time of preheating for the fourth season (optional)')
    end_time4.setDescription('In HH:MM:SS format')
    end_time4.setDefaultValue('')
    args << end_time4


    start_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time5', false)
    start_time5.setDisplayName('Start time of preheating for the fifth season (optional)')
    start_time5.setDescription('In HH:MM:SS format')
    start_time5.setDefaultValue('')
    args << start_time5
    end_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time5', false)
    end_time5.setDisplayName('End time of preheating for the fifth season (optional)')
    end_time5.setDescription('In HH:MM:SS format')
    end_time5.setDefaultValue('')
    args << end_time5


    # Use alternative default start and end time for different climate zone
    alt_periods = OpenStudio::Measure::OSArgument.makeBoolArgument('alt_periods', true)
    alt_periods.setDisplayName('Use alternative default start and end time based on the state of the model from the Cambium load profile peak period?')
    alt_periods.setDescription('This will overwrite the start and end time and date provided by the user')
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
    start_time1 = runner.getStringArgumentValue('start_time1', user_arguments)
    end_time1 = runner.getStringArgumentValue('end_time1', user_arguments)
    start_time2 = runner.getStringArgumentValue('start_time2', user_arguments)
    end_time2 = runner.getStringArgumentValue('end_time2', user_arguments)
    start_time3 = runner.getStringArgumentValue('start_time3', user_arguments)
    end_time3 = runner.getStringArgumentValue('end_time3', user_arguments)
    start_time4 = runner.getStringArgumentValue('start_time4', user_arguments)
    end_time4 = runner.getStringArgumentValue('end_time4', user_arguments)
    start_time5 = runner.getStringArgumentValue('start_time5', user_arguments)
    end_time5 = runner.getStringArgumentValue('end_time5', user_arguments)
    start_date1 = runner.getStringArgumentValue('start_date1', user_arguments)
    end_date1 = runner.getStringArgumentValue('end_date1', user_arguments)
    start_date2 = runner.getStringArgumentValue('start_date2', user_arguments)
    end_date2 = runner.getStringArgumentValue('end_date2', user_arguments)
    start_date3 = runner.getStringArgumentValue('start_date3', user_arguments)
    end_date3 = runner.getStringArgumentValue('end_date3', user_arguments)
    start_date4 = runner.getStringArgumentValue('start_date4', user_arguments)
    end_date4 = runner.getStringArgumentValue('end_date4', user_arguments)
    start_date5 = runner.getStringArgumentValue('start_date5', user_arguments)
    end_date5 = runner.getStringArgumentValue('end_date5', user_arguments)
    alt_periods = runner.getBoolArgumentValue('alt_periods', user_arguments)

    if alt_periods
      state = model.getWeatherFile.stateProvinceRegion
      if state == ''
        runner.registerError('Unable to find state in model WeatherFile. The measure cannot be applied.')
        return false
      end
      file = File.open(File.join(File.dirname(__FILE__), "../../../files/seasonal_shifting_take_hours.json"))
      default_peak_periods = JSON.load(file)
      file.close
      unless default_peak_periods.key?state
        runner.registerAsNotApplicable("No default inputs for the state of the WeatherFile #{state}")
        return false
      end
      peak_periods = default_peak_periods[state]
      start_time1 = peak_periods["winter_take_start"].split[1]
      end_time1 = peak_periods["winter_take_end"].split[1]
      start_time2 = peak_periods["intermediate_take_start"].split[1]
      end_time2 = peak_periods["intermediate_take_end"].split[1]
      start_time3 = peak_periods["summer_take_start"].split[1]
      end_time3 = peak_periods["summer_take_end"].split[1]
      start_time4 = peak_periods["intermediate_take_start"].split[1]
      end_time4 = peak_periods["intermediate_take_end"].split[1]
      start_time5 = peak_periods["winter_take_start"].split[1]
      end_time5 = peak_periods["winter_take_end"].split[1]
      start_date1 = '01-01'
      end_date1 = '03-31'
      start_date2 = '04-01'
      end_date2 = '05-31'
      start_date3 = '06-01'
      end_date3 = '09-30'
      start_date4 = '10-01'
      end_date4 = '11-30'
      start_date5 = '12-01'
      end_date5 = '12-31'
    end

    def validate_time_format(star_time, end_time, runner)
      time1 = /(\d\d):(\d\d):(\d\d)/.match(star_time)
      time2 = /(\d\d):(\d\d):(\d\d)/.match(end_time)
      if time1 and time2
        os_starttime = OpenStudio::Time.new(star_time)
        os_endtime = OpenStudio::Time.new(end_time)
        if star_time >= end_time
          runner.registerError('The start time needs to be earlier than the end time.')
          return false
        else
          return os_starttime, os_endtime
        end
      else
        runner.registerError('The provided time is not in HH-MM-SS format.')
        return false
      end
    end

    def validate_date_format(start_date1, end_date1, runner, model)
      smd = /(\d\d)-(\d\d)/.match(start_date1)
      emd = /(\d\d)-(\d\d)/.match(end_date1)
      if smd.nil? or emd.nil?
        runner.registerError('The provided date is not in MM-DD format.')
        return false
      else
        start_month = smd[1].to_i
        start_day = smd[2].to_i
        end_month = emd[1].to_i
        end_day = emd[2].to_i
        if start_date1 > end_date1
          runner.registerError('The start date cannot be later date the end time.')
          return false
        else
          # os_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month), start_day)
          # os_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month), end_day)
          os_start_date = model.getYearDescription.makeDate(start_month, start_day)
          os_end_date = model.getYearDescription.makeDate(end_month, end_day)
          return os_start_date, os_end_date
        end
      end
    end

    # First time period
    time_result1 = validate_time_format(start_time1, end_time1, runner)
    if time_result1
      shift_time_start1, shift_time_end1 = time_result1
    else
      runner.registerError('The required time period for the reduction is not in correct format!')
      return false
    end
    # The other optional time periods
    shift_time_start2,shift_time_end2,shift_time_start3,shift_time_end3,shift_time_start4,shift_time_end4,shift_time_start5,shift_time_end5 = [nil]*8
    if (not start_time2.empty?) and (not end_time2.empty?)
      time_result2 = validate_time_format(start_time2, end_time2, runner)
      if time_result2
        shift_time_start2, shift_time_end2 = time_result2
      end
    end
    if (not start_time3.empty?) and (not end_time3.empty?)
      time_result3 = validate_time_format(start_time3, end_time3, runner)
      if time_result3
        shift_time_start3, shift_time_end3 = time_result3
      end
    end
    if (not start_time4.empty?) and (not end_time4.empty?)
      time_result4 = validate_time_format(start_time4, end_time4, runner)
      if time_result4
        shift_time_start4, shift_time_end4 = time_result4
      end
    end
    if (not start_time5.empty?) and (not end_time5.empty?)
      time_result5 = validate_time_format(start_time5, end_time5, runner)
      if time_result5
        shift_time_start5, shift_time_end5 = time_result5
      end
    end

    # First date period
    date_result1 = validate_date_format(start_date1, end_date1, runner, model)
    if date_result1
      os_start_date1, os_end_date1 = date_result1
    else
      runner.registerError('The required date period for the reduction is not in correct format!')
      return false
    end
    # Other optional date period
    os_start_date2, os_end_date2, os_start_date3, os_end_date3, os_start_date4, os_end_date4, os_start_date5, os_end_date5 = [nil]*8
    if (not start_date2.empty?) and (not end_date2.empty?)
      date_result2 = validate_date_format(start_date2, end_date2, runner, model)
      if date_result2
        os_start_date2, os_end_date2 = date_result2
      end
    end

    if (not start_date3.empty?) and (not end_date3.empty?)
      date_result3 = validate_date_format(start_date3, end_date3, runner, model)
      if date_result3
        os_start_date3, os_end_date3 = date_result3
      end
    end

    if (not start_date4.empty?) and (not end_date4.empty?)
      date_result4 = validate_date_format(start_date4, end_date4, runner, model)
      if date_result4
        os_start_date4, os_end_date4 = date_result4
      end
    end

    if (not start_date5.empty?) and (not end_date5.empty?)
      date_result5 = validate_date_format(start_date5, end_date5, runner, model)
      if date_result5
        os_start_date5, os_end_date5 = date_result5
      end
    end


    if heating_adjustment < 0
      runner.registerWarning('Lowering heating setpoint will not do pre-heating.')
    elsif heating_adjustment.abs > 500
      runner.registerError("Adjustment #{heating_adjustment} is too large to be correct. Please double check your input")
      return false
    elsif heating_adjustment.abs > 50
      runner.registerWarning("Adjustment #{heating_adjustment} is larger than typical setpoint adjustment. Please double check your input")
    end

    # setup OpenStudio units that we will need
    # temperature_ip_unit = OpenStudio.createUnit('F').get
    # temperature_si_unit = OpenStudio.createUnit('C').get
    # define starting units
    # heating_adjustment_ip = OpenStudio::Quantity.new(heating_adjustment, temperature_ip_unit)
    heating_adjustment_si = heating_adjustment*5/9

    # update the availability schedule
    # air_loop_avail_schs = {}
    # air_loops = model.getAirLoopHVACs
    # air_loops.each do |air_loop|
    #   avail_sch = air_loop.availabilitySchedule
    #
    #   if air_loop_avail_schs.key?(avail_sch.name.to_s)
    #     new_avail_sch = air_loop_avail_schs[avail_sch.name.to_s]
    #   else
    #     new_avail_sch = avail_sch.clone(model).to_Schedule.get
    #     new_avail_sch.setName("#{avail_sch.name.to_s} adjusted")
    #     # add to the hash
    #     air_loop_avail_schs[avail_sch.name.to_s] = new_avail_sch
    #   end
    #   air_loop.setAvailabilitySchedule(new_avail_sch)
    #
    # end
    #
    # air_loop_avail_schs.each do |sch_name, air_loop_sch|
    #   runner.registerInfo("Air Loop Schedule #{sch_name}:")
    #   if air_loop_sch.to_ScheduleRuleset.empty?
    #     runner.registerWarning("Schedule #{sch_name} isn't a ScheduleRuleset object and won't be altered by this measure.")
    #     air_loop_sch.remove # remove un-used clone
    #   else
    #     schedule = air_loop_sch.to_ScheduleRuleset.get
    #     default_rule = schedule.defaultDaySchedule
    #     rules = schedule.scheduleRules
    #     days_covered = Array.new(7, false)
    #
    #     rules.each do |rule|
    #       winter_avail_rule1 = copy_sch_rule_for_period(model, rule, rule.daySchedule, winterStartDate1, winterEndDate1)
    #       winter_avail_rule2 = copy_sch_rule_for_period(model, rule, rule.daySchedule, winterStartDate2, winterEndDate2)
    #       runner.registerInfo("    ------------ time: #{rule.daySchedule.times.map {|os_time| os_time.toString}}")
    #       runner.registerInfo("    ------------ values: #{rule.daySchedule.values}")
    #       summer_avail_rule = rule.clone(model).to_ScheduleRule.get
    #       summer_avail_rule.setStartDate(summerStartDate)
    #       summer_avail_rule.setEndDate(summerEndDate)
    #
    #       checkDaysCovered(summer_avail_rule, days_covered)
    #
    #       summer_avail_day = summer_avail_rule.daySchedule
    #       day_time_vector = summer_avail_day.times
    #       day_value_vector = summer_avail_day.values
    #       summer_avail_day.clearValues
    #
    #       summer_avail_day = updateAvailDaySchedule(summer_avail_day, day_time_vector, day_value_vector, shift_time1, shift_time2)
    #       runner.registerInfo("    ------------ updated time: #{summer_avail_day.times.map {|os_time| os_time.toString}}")
    #       runner.registerInfo("    ------------ uodated values: #{summer_avail_day.values}")
    #
    #     end
    #
    #     if days_covered.include?(false)
    #
    #       winter_rule1 = create_sch_rule_from_default(model, schedule, default_rule, winterStartDate1, winterEndDate1)
    #       winter_rule2 = create_sch_rule_from_default(model, schedule, default_rule, winterStartDate2, winterEndDate2)
    #
    #       coverMissingDays(winter_rule1, days_covered)
    #       checkDaysCovered(winter_rule1, days_covered)
    #
    #       summer_rule = copy_sch_rule_for_period(model, winter_rule1, default_rule, summerStartDate, summerEndDate)
    #
    #       summer_day = summer_rule.daySchedule
    #       day_time_vector = summer_day.times
    #       day_value_vector = summer_day.values
    #       summer_day.clearValues
    #
    #       summer_day = updateAvailDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time1, shift_time2)
    #
    #     end
    #   end
    # end


    exclude_space_types = ["ER_Exam", "ER_NurseStn", "ER_Trauma", "ER_Triage", "ICU_NurseStn", "ICU_Open", "ICU_PatRm", "Lab",
                           "OR", "Anesthesia", "BioHazard", "Exam", "MedGas", "OR", "PACU", "PreOp", "ProcedureRoom", "Lab with fume hood",
                           'HspSurgOutptLab', "RefWalkInCool", "RefWalkInFreeze", "HspSurgOutptLab", "RefStorFreezer", "RefStorCooler"]

    ## push schedules to hash to avoid making unnecessary duplicates
    ## one heating schedule set can correspond to multiple different cooling schedule set
    ## each unique pair would be cloned into a new heating schedule set because of the potential deadband conflict
    sch_set_mapping = {}
    ## sch_set_mapping = {old_heat_sch_name: {corresponding_cool_sch_handle1: [cloned_heat_sch1, corresponding_cool_sch1],
    ##                                       corresponding_cool_sch_handle2: [cloned_heat_sch2, corresponding_cool_sch2]} }
    thermostats = model.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      thermal_zone = thermostat.to_Thermostat.get.thermalZone
      if thermal_zone.is_initialized
        thermal_zone = thermal_zone.get
        zone_applicable = true
        thermal_zone.spaces.each do |space|
          if space.spaceType.is_initialized and space.spaceType.get.standardsSpaceType.is_initialized
            space_type = space.spaceType.get.standardsSpaceType.get
            if exclude_space_types.include?space_type
              runner.registerInfo("The thermal zone #{thermal_zone.name.to_s} for thermostat #{thermostat.name.to_s} contains a space type #{space_type} that's not applicable")
              zone_applicable = false
              break
            end
          end
        end
        next unless zone_applicable
      else
        runner.registerInfo("Thermostat #{thermostat.name.to_s} does not have a thermal zone")
        next
      end

      htg_fuels = thermal_zone.heatingFuelTypes.map(&:valueName).uniq
      unless htg_fuels.include?"Electricity"
        runner.registerInfo("The heating for thermostat #{thermostat.name.to_s} in thermal zone #{thermal_zone.name.to_s} does not use electricity, so it won't be altered.")
        next
      end
      ## setup new cooling setpoint schedule
      htg_set_sch = thermostat.heatingSetpointTemperatureSchedule
      clg_set_sch = thermostat.coolingSetpointTemperatureSchedule
      if htg_set_sch.empty?
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a heating setpoint schedule")
      else
        old_htg_schedule = htg_set_sch.get
        old_schedule_name = old_htg_schedule.name.to_s
        if old_htg_schedule.to_ScheduleRuleset.is_initialized
          if sch_set_mapping.key?(old_schedule_name)
            if clg_set_sch.empty? || clg_set_sch.get.to_ScheduleRuleset.empty?
              if sch_set_mapping[old_schedule_name].key?"nil"
                new_htg_set_sch = sch_set_mapping[old_schedule_name]["nil"][0]
              else
                new_htg_set_sch = old_htg_schedule.clone(model).to_Schedule.get
                n_new_heat_sch = sch_set_mapping[old_schedule_name].size
                new_htg_set_sch.setName("#{old_schedule_name} adjusted by #{heating_adjustment}F_#{n_new_heat_sch}")
                sch_set_mapping[old_schedule_name]["nil"] = [new_htg_set_sch, nil]
              end
            else
              clg_sch_handle = clg_set_sch.get.handle.to_s
              if sch_set_mapping[old_schedule_name].key?clg_sch_handle
                new_htg_set_sch = sch_set_mapping[old_schedule_name][clg_sch_handle][0]
              else
                new_htg_set_sch = old_htg_schedule.clone(model).to_Schedule.get
                n_new_heat_sch = sch_set_mapping[old_schedule_name].size
                new_htg_set_sch.setName("#{old_schedule_name} adjusted by #{heating_adjustment}F_#{n_new_heat_sch}")
                sch_set_mapping[old_schedule_name][clg_sch_handle] = [new_htg_set_sch, clg_set_sch.get]
              end
            end
          else
            new_htg_set_sch = old_htg_schedule.clone(model).to_Schedule.get
            new_htg_set_sch.setName("#{old_schedule_name} adjusted by #{heating_adjustment}F")
            if clg_set_sch.is_initialized
              sch_set_mapping[old_schedule_name] = {clg_set_sch.get.handle.to_s => [new_htg_set_sch, clg_set_sch.get]}
            else
              sch_set_mapping[old_schedule_name] = {"nil" => [new_htg_set_sch, nil]}
            end
          end
          ## hook up clone to thermostat
          thermostat.setHeatingSetpointTemperatureSchedule(new_htg_set_sch)
        else
          runner.registerWarning("Schedule '#{old_schedule_name}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        end
      end
    end
    sch_set_mapping.each do |old_sch_name, new_sch_hash|
      runner.registerInfo("The original heating schedule ruleset #{old_sch_name} is paired with #{new_sch_hash.size} unique cooling schedules, so it will be cloned as #{new_sch_hash.size} new schedules")
    end

    ## consider issuing a warning if the model has un-conditioned thermal zones (no ideal air loads or hvac)
    zones = model.getThermalZones
    zones.each do |zone|
      ## if you have a thermostat but don't have ideal air loads or zone equipment then issue a warning
      if !zone.thermostatSetpointDualSetpoint.empty? && !zone.useIdealAirLoads && (zone.equipment.size <= 0)
        runner.registerWarning("Thermal zone '#{zone.name}' has a thermostat but does not appear to be conditioned.")
      end
    end

    heating_adjust_period_inputs = { "period1" => {"date_start"=>os_start_date1, "date_end"=>os_end_date1,
                                                   "time_start"=>shift_time_start1, "time_end"=>shift_time_end1},
                                     "period2" => {"date_start"=>os_start_date2, "date_end"=>os_end_date2,
                                                   "time_start"=>shift_time_start2, "time_end"=>shift_time_end2},
                                     "period3" => {"date_start"=>os_start_date3, "date_end"=>os_end_date3,
                                                   "time_start"=>shift_time_start3, "time_end"=>shift_time_end3},
                                     "period4" => {"date_start"=>os_start_date4, "date_end"=>os_end_date4,
                                                   "time_start"=>shift_time_start4, "time_end"=>shift_time_end4},
                                     "period5" => {"date_start"=>os_start_date5, "date_end"=>os_end_date5,
                                                   "time_start"=>shift_time_start5, "time_end"=>shift_time_end5} }

    applicable =  false

    sch_set_mapping.each do |old_sch_name, new_sch_hash|
      new_sch_hash.each do |paired_cool_sch_handle, os_schs|
        cooling_set = os_schs[0].to_ScheduleRuleset.get
        schedule = os_schs[1].to_ScheduleRuleset.get
        rules = schedule.scheduleRules
        days_covered = Array.new(7, false)
        current_index = 0
        if rules.length <= 0
          runner.registerWarning("Heating setpoint schedule '#{old_sch_name}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
        else
          runner.registerInfo("Heating schedule ruleset #{schedule.name.to_s} cloned from #{old_sch_name} has #{rules.length} rules.")
          rules.each do |rule|
            runner.registerInfo("---- Rule No.#{rule.ruleIndex}: #{rule.name.to_s}")
            if rule.dateSpecificationType == "SpecificDates"
              ## if the rule applies to SpecificDates, collect the dates that fall into each adjustment date period,
              ## and create a new rule for each date period with covered specific dates
              runner.registerInfo("-------- The rule #{rule.name.to_s} only covers specific dates.")
              ## the specificDates cannot be modified in place because it's a frozen array
              all_specific_dates = []
              rule.specificDates.each { |date| all_specific_dates << date }
              heating_adjust_period_inputs.each do |period, period_inputs|
                period_inputs["specific_dates"] = []
                os_start_date = period_inputs["date_start"]
                os_end_date = period_inputs["date_end"]
                shift_time_start = period_inputs["time_start"]
                shift_time_end = period_inputs["time_end"]
                if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
                  rule.specificDates.each do |covered_date|
                    if covered_date >= os_start_date and covered_date <= os_end_date
                      period_inputs["specific_dates"] << covered_date
                      all_specific_dates.delete(covered_date)
                    end
                  end
                  runner.registerInfo("-------- Specific dates within date range #{os_start_date.to_s} to #{os_end_date.to_s}: #{period_inputs["specific_dates"].map(&:to_s)}")
                  # runner.registerInfo("!!! Specific dates haven't been covered: #{all_specific_dates.map(&:to_s)}")
                  next if period_inputs["specific_dates"].empty?
                  cool_day_mapping = {}
                  period_inputs["specific_dates"].each do |date|
                    corresponding_cool_day = cooling_set.getDaySchedules(date, date)[0]
                    if cool_day_mapping.key?(corresponding_cool_day.name.to_s)
                      cool_day_mapping[corresponding_cool_day.name.to_s]["dates"] << date
                    else
                      cool_day_mapping[corresponding_cool_day.name.to_s] = {"cool_day_schedule" => corresponding_cool_day, "dates" => [date]}
                    end
                  end
                  runner.registerInfo("#{period} has #{cool_day_mapping.size} cooling setpoint days. ")
                  cool_day_mapping.each do |schedule_day_name, day_info|
                    runner.registerInfo("Cooling sch #{schedule_day_name} applies to #{day_info["dates"].size} days")
                    cool_day = day_info["cool_day_schedule"]
                    runner.registerInfo("---- Before, cooling schedule: #{cool_day.times.map(&:to_s)}, #{cool_day.values}")
                    runner.registerInfo("             heating schedule: #{rule.daySchedule.times.map(&:to_s)}, #{rule.daySchedule.values}")
                    rule_period = modify_rule_for_specific_dates(rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                                                 heating_adjustment_si, day_info["dates"], compared_day_sch=cool_day)
                    runner.registerInfo("---- After, adjusted schedule: #{rule_period.daySchedule.times.map(&:to_s)}, #{rule_period.daySchedule.values}")
                    if rule_period
                      applicable = true
                      schedule.setScheduleRuleIndex(rule_period, current_index)
                      current_index += 1
                      runner.registerInfo("-------- The rule #{rule_period.name.to_s} for #{rule_period.dateSpecificationType} is added as priority #{current_index}")
                    end
                  end



                end
              end
              if all_specific_dates.empty?
                ## if all specific dates have been covered by new rules for each adjustment date period, remove the original rule
                runner.registerInfo("The original rule is removed since no specific date left")
              else
                ## if there's still dates left to be covered, modify the original rule to only cover these dates
                ## (this is just in case that the rule order was not set correctly, and the original rule is still applied to all specific dates;
                ##  also to make the logic in OSM more clearer)
                ## the specificDates cannot be modified in place, so create a new rule with the left dates to replace the original rule
                original_rule_update = clone_rule_with_new_dayschedule(rule, rule.name.to_s + " - dates left")
                schedule.setScheduleRuleIndex(original_rule_update, current_index)
                current_index += 1
                all_specific_dates.each do |date|
                  original_rule_update.addSpecificDate(date)
                end
                runner.registerInfo("-------- The original rule #{rule.name.to_s} is modified to only cover the rest of the dates: #{all_specific_dates.map(&:to_s)}")
                runner.registerInfo("-------- and is shifted to priority #{current_index}")
              end
              rule.remove


            else
              ## If the rule applies to a DateRange, check if the DateRange overlaps with each adjustment date period
              ## if so, create a new rule for that adjustment date period
              runner.registerInfo("******* The rule #{rule.name.to_s} covers date range #{rule.startDate.get} - #{rule.endDate.get}.")
              heating_adjust_period_inputs.each do |period, period_inputs|
                os_start_date = period_inputs["date_start"]
                os_end_date = period_inputs["date_end"]
                shift_time_start = period_inputs["time_start"]
                shift_time_end = period_inputs["time_end"]
                if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
                  ## check if the original rule applied DateRange overlaps with the adjustment date period
                  overlapped, new_start_dates, new_end_dates = check_date_ranges_overlap(rule, os_start_date, os_end_date)
                  next unless overlapped
                  #############################################################
                  heat_sch_applied_dates = get_applied_dates_in_range(os_start_date, os_end_date, rule)
                  cool_day_mapping = {}
                  day_of_week_mapping = {}
                  heat_sch_applied_dates.each do |date|
                    corresponding_cool_day = cooling_set.getDaySchedules(date, date)[0]
                    if cool_day_mapping.key?(corresponding_cool_day.name.to_s)
                      cool_day_mapping[corresponding_cool_day.name.to_s]["dates"] << date
                    else
                      cool_day_mapping[corresponding_cool_day.name.to_s] = {"cool_day_schedule" => corresponding_cool_day, "dates" => [date]}
                    end
                    if day_of_week_mapping.key?date.dayOfWeek.valueName
                      day_of_week_mapping[date.dayOfWeek.valueName] << date
                    else
                      day_of_week_mapping[date.dayOfWeek.valueName] = [date]
                    end
                  end
                  runner.registerInfo("#{period} has #{cool_day_mapping.size} cooling setpoint days.")
                  cool_day_mapping.each do |schedule_day_name, day_info|
                    runner.registerInfo("Cooling sch #{schedule_day_name} applies to #{day_info["dates"].size} days")
                    if cool_day_mapping.size == 1
                      applied_day_of_week = nil
                      cool_sch_dates = []
                    else
                      cool_sch_dates = day_info["dates"].map(&:to_s)
                      applied_day_of_week = []
                      day_of_week_mapping.each do |day_of_week, dates|
                        week_day_dates = dates.map(&:to_s)
                        if (week_day_dates - cool_sch_dates).empty?
                          applied_day_of_week << day_of_week
                          cool_sch_dates -= week_day_dates
                          runner.registerInfo("Cooling sch #{schedule_day_name} applies to #{day_of_week}")
                          if cool_sch_dates.empty?
                            break
                          end
                        end
                      end
                    end

                    cool_day = day_info["cool_day_schedule"]
                    runner.registerInfo("**** Before, cooling schedule: #{cool_day.times.map(&:to_s)}, #{cool_day.values}")
                    runner.registerInfo("             heating schedule: #{rule.daySchedule.times.map(&:to_s)}, #{rule.daySchedule.values}")
                    new_start_dates.each_with_index do |start_date, i|
                      unless applied_day_of_week&.empty?
                        rule_period = modify_rule_for_date_period(rule, start_date, new_end_dates[i], shift_time_start, shift_time_end, heating_adjustment_si,
                                                                  applied_dow=applied_day_of_week, compared_day_sch=cool_day)
                        runner.registerInfo("A new rule is created for #{applied_day_of_week}:")
                        runner.registerInfo("#{rule_period.daySchedule.times.map(&:to_s)}, #{rule_period.daySchedule.values}")
                        if rule_period
                          applicable = true
                          if period == "period1"
                            checkDaysCovered(rule_period, days_covered)
                          end
                          schedule.setScheduleRuleIndex(rule_period, current_index)
                          current_index += 1
                          runner.registerInfo("******* The rule #{rule_period.name.to_s} is added as priority #{current_index}")
                        end
                      end

                      unless cool_sch_dates.empty?
                        left_os_dates = cool_sch_dates.map {|str_date| OpenStudio::Date.new(str_date)}
                        runner.registerInfo("Cooling sch #{schedule_day_name} still covers other days. These days will be added as a rule for specific dates.")
                        rule_for_left_dates = modify_rule_for_specific_dates(rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                                                             heating_adjustment_si, left_os_dates, compared_day_sch=cool_day)
                        schedule.setScheduleRuleIndex(rule_for_left_dates, current_index)
                        current_index += 1
                        runner.registerInfo("******* The rule #{rule_for_left_dates.name.to_s} is added as priority #{current_index}")
                      end
                    end
                  end

                end
              end
              ## The original rule will be shifted to the currently lowest priority
              ## Setting the rule to an existing index will automatically push all other rules after it down
              schedule.setScheduleRuleIndex(rule, current_index)
              runner.registerInfo("========== The original rule #{rule.name.to_s} is shifted to priority #{current_index}")
              current_index += 1
            end

          end
        end

        default_day = schedule.defaultDaySchedule
        if days_covered.include?(false)
          runner.registerInfo("Some days use default day. Adding new scheduleRule from defaultDaySchedule for applicable date period.")
          heating_adjust_period_inputs.each do |period, period_inputs|
            os_start_date = period_inputs["date_start"]
            os_end_date = period_inputs["date_end"]
            shift_time_start = period_inputs["time_start"]
            shift_time_end = period_inputs["time_end"]
            if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
              modify_default_day_for_date_period(schedule, default_day, days_covered, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                                 heating_adjustment_si, current_index, cooling_set, runner)
              # schedule.setScheduleRuleIndex(new_default_rule_period, current_index)
              applicable = true
            end
          end

        end
      end

    end

    # affected_actuators = {original_affected actuator_handle: [added_actuator_for_original_sch_copy1, added_actuator_for_original_sch_copy2]}
    affected_actuators = {}
    model.getEnergyManagementSystemActuators.each do |ems_actuator|
      next unless ems_actuator.actuatedComponent.is_initialized
      actuated_comp_name = ems_actuator.actuatedComponent.get.name.to_s
      if sch_set_mapping.key?actuated_comp_name
        ## If the actuator works on a heating schedule that has been modified, the actuator needs to be hooked up with the modified (cloned) schedule
        ## Also, if there's extra cloned copies of the original schedule, each of them needs an actuator (as well as a corresponding EMS program as well)
        new_sch_hash = sch_set_mapping[actuated_comp_name]
        new_sch_hash.each_with_index do |(key, schs), index|
          if index == 0
            ems_actuator.setActuatedComponent(schs[0])
            runner.registerInfo("The actuator component for EMS actuator #{ems_actuator.name.to_s} has been changed from #{actuated_comp_name} to #{schs[0].name.to_s}")
            affected_actuators[ems_actuator.handle.to_s] = []
          else
            ## Clone a new actuator for each extra copy of the original schedule and hook them up
            new_actuator = ems_actuator.clone(model).to_EnergyManagementSystemActuator.get
            new_actuator.setActuatedComponent(schs[0])
            runner.registerInfo("A new actuator #{new_actuator.name.to_s} has been added for the newly added schedule #{schs[0].name.to_s}")
            affected_actuators[ems_actuator.handle.to_s] << new_actuator.handle.to_s
          end
        end
      end
    end

    model.getEnergyManagementSystemPrograms.each do |ems_program|
      next unless ems_program.name.to_s.include?"OptimumStart"
      referenced_obj_names = (ems_program.referencedObjects.map {|obj| obj.handle.to_s}).uniq
      common_actuator = referenced_obj_names & affected_actuators
      next if common_actuator.empty?
      runner.registerInfo("EMS program #{ems_program.name.to_s} is associated with affected EMS actuators")
      # runner.registerInfo("#{ems_program.lines}")
      common_actuator.each do |actuator_handle|
        heating_adjust_period_inputs.each do |period, period_inputs|
          os_start_date = period_inputs["date_start"]
          os_end_date = period_inputs["date_end"]
          shift_time_start = period_inputs["time_start"]
          shift_time_end = period_inputs["time_end"]
          if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
            ## The OptimumStartProg EMS is applied to hour 5 and 7 during non-daylight saving time, and hour 4 and 6 during daylight saving time
            ## It's because the Hour function doesn't take daylight saving time into consideration, while the schedule objects do
            ## So the actual time EMS functions is 5:00 and 7:00 (if you output the thermostat setpoint variable to check)
            if shift_time_start.totalHours <= 7 and shift_time_end.totalHours > 5
              ## If the EMS program conflicts with the precooling adjustment, disable the program by setting the actuator to null
              ems_program.addLine("IF DayOfYear >= #{os_start_date.dayOfYear} && DayOfYear <= #{os_end_date.dayOfYear}")
              ems_program.addLine("SET #{actuator_handle} = NULL")
              ems_program.addLine("ENDIF")
            end
          end
        end
        ## For each extra copy of cloned heating schedule (actuator), clone an EMS program for it, and modify the corresponding handle in the program
        affected_actuators[actuator_handle].each do |new_actuator_handle|
          new_program = ems_program.clone(model).to_EnergyManagementSystemProgram.get
          new_program_body = new_program.body.gsub(actuator_handle, new_actuator_handle)
          new_program.setBody(new_program_body)
          runner.registerInfo("A new EMS program #{new_program.name.to_s} has been created for the newly added actuator #{new_actuator_handle}")
        end
      end
    end

    # not applicable if no schedules can be altered
    unless applicable
      runner.registerAsNotApplicable('No thermostat schedules in the models could be altered.')
    end

    return true
  end


  def get_applied_dates_in_range(os_start_date, os_end_date, rule)
    total_dates = (os_end_date - os_start_date).totalDays.to_i
    dates_vector = (0..total_dates).map{|delta| os_start_date + OpenStudio::Time.new(delta)}
    apply_flag = rule.containsDates(dates_vector)
    rule_applied_dates = dates_vector.select.with_index { |value, index| apply_flag[index] }
    return rule_applied_dates
  end

  def merge_day_sch_with_min(day_schedule_left, day_schedule_right)

    def value_at_time(target_time, times, values)
      times.each_with_index do |until_time, index|
        if target_time <= until_time
          return values[index] # Return the corresponding value for the interval
        end
      end
    end
    combined_times = (day_schedule_left.times+day_schedule_right.times).map(&:toString).uniq.sort.map {|str_time| OpenStudio::Time.new(str_time)}
    original_day_times = day_schedule_left.times
    original_day_values = day_schedule_left.values
    # new_day_schedule = OpenStudio::Model::ScheduleDay.new(model)

    day_schedule_left.clearValues
    updated_times, updated_values = [], []
    combined_times.each do |time|
      # Get the current value from each series
      value_left = value_at_time(time, original_day_times, original_day_values)
      value_right = value_at_time(time, day_schedule_right.times, day_schedule_right.values)

      # Calculate the maximum value at this time
      max_value = [value_left, value_right].min
      updated_times << time
      updated_values << max_value
    end
    # Add to result only if the value changes to avoid redundant values
    updated_values.each_with_index do |entry, index|
      if index == updated_values.size || entry != updated_values[index + 1]
        day_schedule_left.addValue(updated_times[index], entry)
      end
    end
    return day_schedule_left
  end

  def check_date_ranges_overlap(rule, adjust_start_date, adjust_end_date)
    ## check if the original rule applied DateRange overlaps with the adjustment date period
    overlapped = false
    new_start_dates = []
    new_end_dates = []
    if rule.endDate.get >= rule.startDate.get and rule.startDate.get <= adjust_end_date and rule.endDate.get >= adjust_start_date
      overlapped = true
      new_start_dates << [adjust_start_date, rule.startDate.get].max
      new_end_dates << [adjust_end_date, rule.endDate.get].min
    elsif rule.endDate.get < rule.startDate.get
      ## If the DateRange has a endDate < startDate, the range wraps around the year.
      if rule.endDate.get >= adjust_start_date
        overlapped = true
        new_start_dates << adjust_start_date
        new_end_dates << rule.endDate.get
      end
      if rule.startDate.get <= adjust_end_date
        overlapped = true
        new_start_dates << rule.startDate.get
        new_end_dates << adjust_end_date
      end
    end
    return overlapped, new_start_dates, new_end_dates
  end

  def clone_rule_with_new_dayschedule(original_rule, new_rule_name)
    ## Cloning a scheduleRule will automatically clone the daySchedule associated with it, but it's a shallow copy,
    ## because the daySchedule is a resource that can be used by many scheduleRule
    ## Therefore, once the daySchedule is modified for the cloned scheduleRule, the original daySchedule is also changed
    ## Also, there's no function to assign a new daySchedule to the existing scheduleRule,
    ## so the only way to clone the scheduleRule but change the daySchedule is to construct a new scheduleRule with a daySchedule passed in
    ## and copy all other settings from the original scheduleRule
    rule_period = OpenStudio::Model::ScheduleRule.new(original_rule.scheduleRuleset, original_rule.daySchedule)
    rule_period.setName(new_rule_name)
    rule_period.setApplySunday(original_rule.applySunday)
    rule_period.setApplyMonday(original_rule.applyMonday)
    rule_period.setApplyTuesday(original_rule.applyTuesday)
    rule_period.setApplyWednesday(original_rule.applyWednesday)
    rule_period.setApplyThursday(original_rule.applyThursday)
    rule_period.setApplyFriday(original_rule.applyFriday)
    rule_period.setApplySaturday(original_rule.applySaturday)
    return rule_period
  end

  def modify_rule_for_date_period(original_rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                  adjustment, applied_dow=nil, compared_day_sch=nil)
    # The cloned scheduleRule will automatically belongs to the originally scheduleRuleSet
    # rule_period = original_rule.clone(model).to_ScheduleRule.get
    # rule_period.daySchedule = original_rule.daySchedule.clone(model)
    new_rule_name = "#{original_rule.name.to_s} with DF for #{os_start_date.to_s} to #{os_end_date.to_s}"
    rule_period = clone_rule_with_new_dayschedule(original_rule, new_rule_name)
    unless applied_dow.nil?
      rule_period.setApplySunday(applied_dow.include?"Sunday")
      rule_period.setApplyMonday(applied_dow.include?"Monday")
      rule_period.setApplyTuesday(applied_dow.include?"Tuesday")
      rule_period.setApplyWednesday(applied_dow.include?"Wednesday")
      rule_period.setApplyThursday(applied_dow.include?"Monday")
      rule_period.setApplyFriday(applied_dow.include?"Friday")
      rule_period.setApplySaturday(applied_dow.include?"Saturday")
    end
    day_rule_period = rule_period.daySchedule
    day_time_vector = day_rule_period.times
    day_value_vector = day_rule_period.values
    if day_time_vector.empty?
      return false
    end
    day_rule_period.clearValues
    updateDaySchedule(day_rule_period, day_time_vector, day_value_vector, shift_time_start, shift_time_end, adjustment)
    unless compared_day_sch.nil?
      merge_day_sch_with_min(day_rule_period, compared_day_sch)
    end
    if rule_period
      rule_period.setStartDate(os_start_date)
      rule_period.setEndDate(os_end_date)
    end
    return rule_period
  end

  def modify_rule_for_specific_dates(original_rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                     adjustment, applied_dates, compared_day_sch = nil)
    new_rule_name = "#{original_rule.name.to_s} with DF for #{os_start_date.to_s} to #{os_end_date.to_s}"
    rule_period = clone_rule_with_new_dayschedule(original_rule, new_rule_name)
    day_rule_period = rule_period.daySchedule
    day_time_vector = day_rule_period.times
    day_value_vector = day_rule_period.values
    if day_time_vector.empty?
      return false
    end
    day_rule_period.clearValues
    updateDaySchedule(day_rule_period, day_time_vector, day_value_vector, shift_time_start, shift_time_end, adjustment)
    unless compared_day_sch.nil?
      merge_day_sch_with_min(day_rule_period, compared_day_sch)
    end
    if rule_period
      applied_dates.each do |date|
        rule_period.addSpecificDate(date)
      end
    end
    return rule_period
  end

  def modify_default_day_for_date_period(schedule_set, default_day, days_covered, os_start_date, os_end_date,
                                         shift_time_start, shift_time_end, adjustment, current_index, corresponding_cool_set, runner)
    # the new rule created for the ScheduleRuleSet by default has the highest priority (ruleIndex=0)
    new_default_rule = OpenStudio::Model::ScheduleRule.new(schedule_set, default_day)
    new_default_rule.setName("#{schedule_set.name.to_s} default day with DF for #{os_start_date.to_s} to #{os_end_date.to_s}")
    new_default_rule.setStartDate(os_start_date)
    new_default_rule.setEndDate(os_end_date)
    coverMissingDays(new_default_rule, days_covered)
    # days_of_week = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    # days_of_week.select.with_index { |value, index| !days_covered[index] }
    heat_sch_applied_dates = get_applied_dates_in_range(os_start_date, os_end_date, new_default_rule)
    cool_day_mapping = {}
    day_of_week_mapping = {}
    heat_sch_applied_dates.each do |date|
      corresponding_cool_day = corresponding_cool_set.getDaySchedules(date, date)[0]
      if cool_day_mapping.key?(corresponding_cool_day.name.to_s)
        cool_day_mapping[corresponding_cool_day.name.to_s]["dates"] << date
      else
        cool_day_mapping[corresponding_cool_day.name.to_s] = {"cool_day_schedule" => corresponding_cool_day, "dates" => [date]}
      end
      if day_of_week_mapping.key?date.dayOfWeek.valueName
        day_of_week_mapping[date.dayOfWeek.valueName] << date
      else
        day_of_week_mapping[date.dayOfWeek.valueName] = [date]
      end
    end
    if cool_day_mapping.size == 1
      cool_day = cool_day_mapping.values.first["cool_day_schedule"]
      runner.registerInfo("==== Before, cooling schedule: #{cool_day.times.map(&:to_s)}, #{cool_day.values}")
      runner.registerInfo("             heating schedule: #{default_day.times.map(&:to_s)}, #{default_day.values}")
      new_default_day = new_default_rule.daySchedule
      day_time_vector = new_default_day.times
      day_value_vector = new_default_day.values
      new_default_day.clearValues
      updateDaySchedule(new_default_day, day_time_vector, day_value_vector, shift_time_start, shift_time_end, adjustment)
      merge_day_sch_with_min(new_default_day, cool_day)
      runner.registerInfo("The default rule is created:")
      runner.registerInfo("#{new_default_day.times.map(&:to_s)}, #{new_default_day.values}")
    else
      cool_day_mapping.each do |schedule_day_name, day_info|
        cool_day = day_info["cool_day_schedule"]
        runner.registerInfo("==== Before, heating schedule: #{cool_day.times.map(&:to_s)}, #{cool_day.values}")
        runner.registerInfo("             cooling schedule: #{default_day.times.map(&:to_s)}, #{default_day.values}")
        applied_day_of_week = []
        cool_sch_dates = day_info["dates"].map(&:to_s)
        day_of_week_mapping.each do |day_of_week, dates|
          week_day_dates = dates.map(&:to_s)
          if (week_day_dates - cool_sch_dates).empty?
            applied_day_of_week << day_of_week
            cool_sch_dates -= week_day_dates
            if cool_sch_dates.empty?
              break
            end
          end
        end
        unless applied_day_of_week.empty?
          new_default_rule_dow = modify_rule_for_date_period(new_default_rule, os_start_date, os_end_date, shift_time_start, shift_time_end, adjustment,
                                                             applied_dow=applied_day_of_week, compared_day_sch=cool_day)
          runner.registerInfo("A new rule is created for #{applied_day_of_week}:")
          runner.registerInfo("#{new_default_rule_dow.daySchedule.times.map(&:to_s)}, #{new_default_rule_dow.daySchedule.values}")
          schedule_set.setScheduleRuleIndex(new_default_rule_dow, current_index)
          current_index += 1
          runner.registerInfo("======== The rule #{new_default_rule_dow.name.to_s} is added as priority #{current_index}")

        end

        unless cool_sch_dates.empty?
          left_os_dates = cool_sch_dates.map {|str_date| OpenStudio::Date.new(str_date)}
          runner.registerInfo("Cooling sch #{schedule_day_name} still covers other days. These days will be added as a rule for specific dates.")
          new_default_rule_specific_dates = modify_rule_for_specific_dates(new_default_rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                                                           adjustment, left_os_dates, compared_day_sch=cool_day)
          runner.registerInfo("A new rule is created for specific dates:")
          runner.registerInfo("#{new_default_rule_specific_dates.daySchedule.times.map(&:to_s)}, #{new_default_rule_specific_dates.daySchedule.values}")
          schedule_set.setScheduleRuleIndex(new_default_rule_specific_dates, current_index)
          current_index += 1
          runner.registerInfo("======== The rule #{new_default_rule_specific_dates.name.to_s} is added as priority #{current_index}")
        end
      end
      new_default_rule.remove
    end


    # TODO: if the scheduleRuleSet has holidaySchedule (which is a ScheduleDay), it cannot be altered
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
