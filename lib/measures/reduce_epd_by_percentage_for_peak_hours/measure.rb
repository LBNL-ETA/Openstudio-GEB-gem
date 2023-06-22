# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ReduceEPDByPercentageForPeakHours < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "Reduce EPD by Percentage for Peak Hours"
  end
  # human readable description
  def description
    return "This measure reduces electric equipment loads by a user-specified percentage for a user-specified time period (usually the peak hours). The reduction can be applied to at most three periods throughout out the year specified by the user. This is applied throughout the entire building."
  end
  # human readable description of modeling approach
  def modeler_description
    return "The original schedules for equipment in the building will be found and copied. The copies will be modified to have the percentage reduction during the specified hours, and be applied to the specified date periods through out the year. The rest of the year will keep using the original schedules."
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    epd_reduce_percent = OpenStudio::Measure::OSArgument.makeDoubleArgument('epd_reduce_percent', true)
    epd_reduce_percent.setDisplayName('Percentage Reduction of Electric Equipment Power (%)')
    epd_reduce_percent.setDescription('Enter a value between 0 and 100')
    epd_reduce_percent.setDefaultValue(50.0)
    args << epd_reduce_percent

    # make an argument for the start time of the reduction
    start_time = OpenStudio::Measure::OSArgument.makeStringArgument('start_time', false)
    start_time.setDisplayName('Start Time for the Reduction')
    start_time.setDescription('In HH:MM:SS format')
    start_time.setDefaultValue('17:00:00')
    args << start_time

    # make an argument for the end time of the reduction
    end_time = OpenStudio::Measure::OSArgument.makeStringArgument('end_time', false)
    end_time.setDisplayName('End Time for the Reduction')
    end_time.setDescription('In HH:MM:SS format')
    end_time.setDefaultValue('21:00:00')
    args << end_time

    # Use alternative default start and end time for different climate zone
    alt_periods = OpenStudio::Measure::OSArgument.makeBoolArgument('alt_periods', false)
    alt_periods.setDisplayName('Use alternative default start and end time based on the climate zone of the model?')
    alt_periods.setDescription('This will overwrite the star and end time you input')
    alt_periods.setDefaultValue(false)
    args << alt_periods

    # make an argument for the start date of the reduction
    start_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date1', false)
    start_date1.setDisplayName('First start date for the Reduction')
    start_date1.setDescription('In MM-DD format')
    start_date1.setDefaultValue('07-01')
    args << start_date1

    # make an argument for the end date of the reduction
    end_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date1', false)
    end_date1.setDisplayName('First end date for the Reduction')
    end_date1.setDescription('In MM-DD format')
    end_date1.setDefaultValue('08-31')
    args << end_date1


    # make an argument for the second start date of the reduction
    start_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date2', false)
    start_date2.setDisplayName('Second start date for the Reduction (optional)')
    start_date2.setDescription('Specify a date in MM-DD format if you want a second period of reduction; leave blank if not needed.')
    start_date2.setDefaultValue('')
    args << start_date2

    # make an argument for the second end date of the reduction
    end_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date2', false)
    end_date2.setDisplayName('Second end date for the Reduction (optional)')
    end_date2.setDescription('Specify a date in MM-DD format if you want a second period of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date2.setDefaultValue('')
    args << end_date2

    # make an argument for the third start date of the reduction
    start_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date3', false)
    start_date3.setDisplayName('Third start date for the Reduction (optional)')
    start_date3.setDescription('Specify a date in MM-DD format if you want a third period of reduction; leave blank if not needed.')
    start_date3.setDefaultValue('')
    args << start_date3

    # make an argument for the third end date of the reduction
    end_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date3', false)
    end_date3.setDisplayName('Third end date for the Reduction')
    end_date3.setDescription('Specify a date in MM-DD format if you want a third period of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date3.setDefaultValue('')
    args << end_date3


    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    epd_reduce_percent = runner.getDoubleArgumentValue('epd_reduce_percent', user_arguments)
    start_time = runner.getStringArgumentValue('start_time', user_arguments)
    end_time = runner.getStringArgumentValue('end_time', user_arguments)
    start_date1 = runner.getStringArgumentValue('start_date1', user_arguments)
    end_date1 = runner.getStringArgumentValue('end_date1', user_arguments)
    start_date2 = runner.getStringArgumentValue('start_date2', user_arguments)
    end_date2 = runner.getStringArgumentValue('end_date2', user_arguments)
    start_date3 = runner.getStringArgumentValue('start_date3', user_arguments)
    end_date3 = runner.getStringArgumentValue('end_date3', user_arguments)
    alt_periods = runner.getBoolArgumentValue('alt_periods', user_arguments)

    # validate the percentage
    if epd_reduce_percent > 100
      runner.registerError('The percentage reduction of electric equipment power cannot be larger than 100.')
      return false
    elsif epd_reduce_percent < 0
      runner.registerWarning('The percentage reduction of electric equipment power is negative. This will increase the electric equipment power.')
    end

    # set the default start and end time based on climate zone
    if alt_periods
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

      case ashraeClimateZone
      when '3A'
        start_time = '18:01:00'
        end_time = '21:59:00'
      when '4A'
        start_time = '18:01:00'
        end_time = '21:59:00'
      when '5A'
        start_time = '14:01:00'
        end_time = '17:59:00'
      when '6A'
        start_time = '13:01:00'
        end_time = '16:59:00'
      when '2A'
        start_time = '17:01:00'
        end_time = '20:59:00'
      when '2B'
        start_time = '17:01:00'
        end_time = '20:59:00'
      when '3A'
        start_time = '19:01:00'
        end_time = '22:59:00'
      when '3B'
        start_time = '18:01:00'
        end_time = '21:59:00'
      when '3C'
        start_time = '19:01:00'
        end_time = '22:59:00'
      when '4A'
        start_time = '12:01:00'
        end_time = '15:59:00'
      when '4B'
        start_time = '17:01:00'
        end_time = '20:59:00'
      when '4C'
        start_time = '17:01:00'
        end_time = '20:59:00'
      when '5A'
        start_time = '20:01:00'
        end_time = '23:59:00'
      when '5B'
        start_time = '17:01:00'
        end_time = '20:59:00'
      when '5C'
        start_time = '17:01:00'
        end_time = '20:59:00'
      when '6A'
        start_time = '16:01:00'
        end_time = '19:59:00'
      when '6B'
        start_time = '17:01:00'
        end_time = '20:59:00'
      when '7A'
        start_time = '16:01:00'
        end_time = '19:59:00'
      else
        runner.registerError('Invalid ASHRAE climate zone.')
        return false
      end
    end

    if /(\d\d):(\d\d):(\d\d)/.match(start_time)
      shift_time1 = OpenStudio::Time.new(start_time)
    else
      runner.registerError('Start time must be in HH-MM-SS format.')
      return false
    end

    if /(\d\d):(\d\d):(\d\d)/.match(end_time)
      shift_time2 = OpenStudio::Time.new(end_time)
    else
      runner.registerError('End time must be in HH-MM-SS format.')
      return false
    end

    if start_time.to_f > end_time.to_f
      runner.registerError('The start time cannot be later than the end time.')
      return false
    end

    start_month1 = nil
    start_day1 = nil
    md = /(\d\d)-(\d\d)/.match(start_date1)
    if md
      start_month1 = md[1].to_i
      start_day1 = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    end_month1 = nil
    end_day1 = nil
    md = /(\d\d)-(\d\d)/.match(end_date1)
    if md
      end_month1 = md[1].to_i
      end_day1 = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end

    start_month2 = nil
    start_day2 = nil
    end_month2 = nil
    end_day2 = nil
    if (start_date2.empty? and not end_date2.empty?) or (end_date2.empty? and not start_date2.empty?)
      runner.registerWarning("Either start date or end date for the second period of reduction is not specified, so the second period of reduction will not be used.")
    elsif not start_date2.empty? and (not end_date2.empty?)
      smd = /(\d\d)-(\d\d)/.match(start_date2)
      if smd
        start_month2 = smd[1].to_i
        start_day2 = smd[2].to_i
      else
        runner.registerError('Start date must be in MM-DD format. If you do not want a second period, leave both the start and end date blank.')
        return false
      end
      emd = /(\d\d)-(\d\d)/.match(end_date2)
      if emd
        end_month2 = emd[1].to_i
        end_day2 = emd[2].to_i
      else
        runner.registerError('End date must be in MM-DD format. If you do not want a second period, leave both the start and end date blank.')
        return false
      end
    else

    end


    start_month3 = nil
    start_day3 = nil
    end_month3 = nil
    end_day3 = nil
    if (start_date3.empty? and not end_date3.empty?) or (end_date3.empty? and not start_date3.empty?)
      runner.registerWarning("Either start date or end date for the third period of reduction is not specified, so the second period of reduction will not be used.")
    elsif not start_date3.empty? and (not end_date3.empty?)
      smd = /(\d\d)-(\d\d)/.match(start_date3)
      if smd
        start_month3 = smd[1].to_i
        start_day3 = smd[2].to_i
      else
        runner.registerError('Start date must be in MM-DD format. If you do not want a third period, leave both the start and end date blank.')
        return false
      end
      emd = /(\d\d)-(\d\d)/.match(end_date3)
      if emd
        end_month3 = emd[1].to_i
        end_day3 = emd[2].to_i
      else
        runner.registerError('End date must be in MM-DD format. If you do not want a third period, leave both the start and end date blank.')
        return false
      end
    end

    os_start_date1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month1), start_day1)
    os_end_date1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month1), end_day1)
    os_start_date2 = nil
    os_end_date2 = nil
    if [start_month2, start_day2, end_month2, end_day2].all?
      os_start_date2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month2), start_day2)
      os_end_date2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month2), end_day2)
    end
    os_start_date3 = nil
    os_end_date3 = nil
    if [start_month3, start_day3, end_month3, end_day3].all?
      os_start_date3 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month3), start_day3)
      os_end_date3 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month3), end_day3)
    end

    # daylightsaving adjustment added in visualization, so deprecated here
    # # Check model's daylight saving period, if cooling period is within daylight saving period, shift the cooling start time and end time by one hour later
    # # only check the first period now, assuming majority will only modify for a single period
    # if model.getObjectsByType('OS:RunPeriodControl:DaylightSavingTime'.to_IddObjectType).size >= 1
    #   runperiodctrl_daylgtsaving = model.getRunPeriodControlDaylightSavingTime
    #   daylight_saving_startdate = runperiodctrl_daylgtsaving.startDate
    #   daylight_saving_enddate = runperiodctrl_daylgtsaving.endDate
    #   if os_start_date1 >= OpenStudio::Date.new(daylight_saving_startdate.monthOfYear, daylight_saving_startdate.dayOfMonth, os_start_date1.year) && os_end_date1 <= OpenStudio::Date.new(daylight_saving_enddate.monthOfYear, daylight_saving_enddate.dayOfMonth, os_start_date1.year)
    #     shift_time1 += OpenStudio::Time.new(0,1,0,0)
    #     shift_time2 += OpenStudio::Time.new(0,1,0,0)
    #   end
    # end

    epd_factor = 1 - (epd_reduce_percent/100)
    applicable =  false
    equipments = model.getElectricEquipments
    # create a hash to map the old schedule name to the new schedule
    equip_schedules = {}
    equipments.each do |equip|
      equip_sch = equip.schedule
      if equip_sch.empty?
        runner.registerWarning("#{equip.name} doesn't have a schedule.")
      else
        if equip_schedules.key?(equip_sch.get.name.to_s)
          new_equip_sch = equip_schedules[equip_sch.get.name.to_s]
        else
          if equip_sch.get.to_ScheduleRuleset.empty?
            runner.registerWarning("Schedule #{equip_sch.get.name} isn't a ScheduleRuleset object and won't be altered by this measure.")
            next
          else
            new_equip_sch = equip_sch.get.clone(model)
            new_equip_sch = new_equip_sch.to_Schedule.get
            new_equip_sch.setName("#{equip_sch.get.name.to_s} adjusted #{epd_factor}")
            # add to the hash
            equip_schedules[equip_sch.get.name.to_s] = new_equip_sch
          end
        end
        equip.setSchedule(new_equip_sch)
        runner.registerInfo("Schedule #{equip_sch.get.name} of electric equipment #{equip.name} will be altered by this measure.")
      end
    end

    equip_schedules.each do |old_name, equip_sch|
      schedule_set = equip_sch.to_ScheduleRuleset.get
      default_rule = schedule_set.defaultDaySchedule
      rules = schedule_set.scheduleRules
      days_covered = Array.new(7, false)
      original_rule_number = rules.length
      if original_rule_number > 0
        runner.registerInfo("------------ schedule rule set #{old_name} has #{original_rule_number} rules.")
        current_index = 0
        # rules are in order of priority
        rules.each do |rule|
          runner.registerInfo("------------ Rule #{rule.ruleIndex}: #{rule.daySchedule.name.to_s}")
          rule_period1 = rule.clone(model).to_ScheduleRule.get # OpenStudio::Model::ScheduleRule.new(schedule_set, rule.daySchedule)
          rule_period1.setStartDate(os_start_date1)
          rule_period1.setEndDate(os_end_date1)
          checkDaysCovered(rule_period1, days_covered)
          runner.registerInfo("--------------- current days of week coverage: #{days_covered}")

          # set the order of the new cloned schedule rule, to make sure the modified rule has a higher priority than the original one
          # and different copies keep the same priority as their original orders
          unless schedule_set.setScheduleRuleIndex(rule_period1, current_index)
            runner.registerError("Fail to set rule index for #{day_rule_period1.name.to_s}.")
          end
          current_index += 1

          day_rule_period1 = rule_period1.daySchedule
          day_time_vector1 = day_rule_period1.times
          day_value_vector1 = day_rule_period1.values
          runner.registerInfo("    ------------ time: #{day_time_vector1.map {|os_time| os_time.toString}}")
          runner.registerInfo("    ------------ values: #{day_value_vector1}")
          unless day_value_vector1.empty?
            applicable = true
          end
          day_rule_period1.clearValues
          day_rule_period1 = updateDaySchedule(day_rule_period1, day_time_vector1, day_value_vector1, shift_time1, shift_time2, epd_factor)
          runner.registerInfo("    ------------ updated time: #{day_rule_period1.times.map {|os_time| os_time.toString}}")
          runner.registerInfo("    ------------ updated values: #{day_rule_period1.values}")
          runner.registerInfo("--------------- schedule updated for #{rule_period1.startDate.get} to #{rule_period1.endDate.get}")

          if os_start_date2 and os_end_date2
            rule_period2 = copy_sch_rule_for_period(model, rule_period1, rule_period1.daySchedule, os_start_date2, os_end_date2)
            unless schedule_set.setScheduleRuleIndex(rule_period2, 0)
              runner.registerError("Fail to set rule index for #{rule_period2.daySchedule.name.to_s}.")
            end
            current_index += 1
            runner.registerInfo("--------------- schedule updated for #{rule_period2.startDate.get} to #{rule_period2.endDate.get}")
          end

          if os_start_date3 and os_end_date3
            rule_period3 = copy_sch_rule_for_period(model, rule_period1, rule_period1.daySchedule, os_start_date3, os_end_date3)
            unless schedule_set.setScheduleRuleIndex(rule_period3, 0)
              runner.registerError("Fail to set rule index for #{rule_period3.daySchedule.name.to_s}.")
            end
            current_index += 1
            runner.registerInfo("--------------- schedule updated for #{rule_period3.startDate.get} to #{rule_period3.endDate.get}")
          end

          # The original rule will be shifted to have the currently lowest priority
          unless schedule_set.setScheduleRuleIndex(rule, original_rule_number + current_index - 1)
            runner.registerError("Fail to set rule index for #{rule.daySchedule.name.to_s}.")
          end

        end
      else
        runner.registerWarning("Electric equipment schedule #{old_name} is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
      end
      if days_covered.include?(false)
        new_default_rule = OpenStudio::Model::ScheduleRule.new(schedule_set)
        new_default_rule.setStartDate(os_start_date1)
        new_default_rule.setEndDate(os_end_date1)
        coverMissingDays(new_default_rule, days_covered)
        checkDaysCovered(new_default_rule, days_covered)

        cloned_default_day = default_rule.clone(model)
        cloned_default_day.setParent(new_default_rule)

        new_default_day = new_default_rule.daySchedule
        day_time_vector = new_default_day.times
        day_value_vector = new_default_day.values
        new_default_day.clearValues
        new_default_day = updateDaySchedule(new_default_day, day_time_vector, day_value_vector, shift_time1, shift_time2, epd_factor)
        if os_start_date2 and os_end_date2
          copy_sch_rule_for_period(model, new_default_rule, new_default_day, os_start_date2, os_end_date2)
        end
        if os_start_date3 and os_end_date3
          copy_sch_rule_for_period(model, new_default_rule, new_default_day, os_start_date3, os_end_date3)
        end
      end

    end

      # doesn't work for models without scheduleRules
      # runner.registerInfo("------------------------FINAL--------------------")
      # space_type.electricEquipment.each do |equip|
      #   lgt_schedule_set = equip.schedule
      #   unless lgt_schedule_set.empty?
      #     runner.registerInfo("Schedule #{lgt_schedule_set.get.name.to_s}:")
      #     sch_set = lgt_schedule_set.get.to_Schedule.get
      #     sch_set.to_ScheduleRuleset.get.scheduleRules.each do |rule|
      #       runner.registerInfo("  rule #{rule.ruleIndex}: #{rule.daySchedule.name.to_s} from #{rule.startDate.get} to #{rule.endDate.get}")
      #     end
      #   end
      # end

    unless applicable
      runner.registerAsNotApplicable('No electric equipment schedule in the model could be altered.')
    end

    return true
  end

  def copy_sch_rule_for_period(model, sch_rule, sch_day, start_date, end_date)
    new_rule = sch_rule.clone(model).to_ScheduleRule.get
    new_rule.setStartDate(start_date)
    new_rule.setEndDate(end_date)

    new_day_sch = sch_day.clone(model)
    new_day_sch.setParent(new_rule)

    return new_rule
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

  def updateDaySchedule(sch_day, vec_time, vec_value, time_begin, time_end, percentage)
    count = 0
    vec_time.each_with_index do |exist_timestamp, i|
      adjusted_value = vec_value[i] * percentage
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


end

# register the measure to be used by the application
ReduceEPDByPercentageForPeakHours.new.registerWithApplication
