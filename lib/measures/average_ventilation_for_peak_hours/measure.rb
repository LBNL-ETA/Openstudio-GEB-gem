# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AverageVentilationForPeakHours < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "Average Ventilation for Peak Hours"
  end
  # human readable description
  def description
    return "This measure implement average ventialtion for the use-specified time period to reduce the peak load."
  end
  # human readable description of modeling approach
  def modeler_description
    return "The outdoor air flow rate will be reduced by the percentage specified by the user during the peak hours specified by the user. Then the decreased air flow rate will be added to the hours before the peak time."
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    vent_reduce_percent = OpenStudio::Measure::OSArgument.makeDoubleArgument('vent_reduce_percent', true)
    vent_reduce_percent.setDisplayName('Percentage Reduction of Ventilation Rate (%)')
    vent_reduce_percent.setDescription('Enter a value between 0 and 100')
    vent_reduce_percent.setDefaultValue(50.0)
    args << vent_reduce_percent

    # make an argument for the start time of the reduction
    start_time = OpenStudio::Measure::OSArgument.makeStringArgument('start_time', false)
    start_time.setDisplayName('Start Time for the Reduction')
    start_time.setDescription('In HH:MM:SS format')
    start_time.setDefaultValue('11:00:00')
    args << start_time

    # make an argument for the end time of the reduction
    end_time = OpenStudio::Measure::OSArgument.makeStringArgument('end_time', false)
    end_time.setDisplayName('End Time for the Reduction')
    end_time.setDescription('In HH:MM:SS format')
    end_time.setDefaultValue('13:00:00')
    args << end_time

    # make an argument for the start date of the reduction
    start_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date1', false)
    start_date1.setDisplayName('Start Date for Average Ventilation')
    start_date1.setDescription('In MM-DD format')
    start_date1.setDefaultValue('07-01')
    args << start_date1

    # make an argument for the end date of the reduction
    end_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date1', false)
    end_date1.setDisplayName('End Date for Average Ventilation')
    end_date1.setDescription('In MM-DD format')
    end_date1.setDefaultValue('08-01')
    args << end_date1


    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    vent_reduce_percent = runner.getDoubleArgumentValue('vent_reduce_percent', user_arguments)
    start_time = runner.getStringArgumentValue('start_time', user_arguments)
    end_time = runner.getStringArgumentValue('end_time', user_arguments)
    start_date1 = runner.getStringArgumentValue('start_date1', user_arguments)
    end_date1 = runner.getStringArgumentValue('end_date1', user_arguments)

    # validate the percentage
    if vent_reduce_percent > 100
      runner.registerError('The percentage reduction of ventilation rate cannot be larger than 100.')
      return false
    elsif vent_reduce_percent < 0
      runner.registerWarning('The percentage reduction of ventilation rate is negative. This will increase the ventilation rate.')
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

    os_start_date1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month1), start_day1)
    os_end_date1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month1), end_day1)


    vent_factor = 1 - (vent_reduce_percent/100)
    # create a new outdoor air schedule based on the input
    model.getAirLoopHVACs.each do |air_system|
      oa_system = air_system.airLoopHVACOutdoorAirSystem
      unless oa_system.empty?
        oa_system.get.getControllerOutdoorAir.setMaximumFractionofOutdoorAirSchedule(vent_schedule)
      end
    end


    applicable =  false
    space_types = model.getSpaceTypes
    space_types.each do |space_type|
      runner.registerInfo("-- For space #{space_type.name.get}:")
      # for each space, create a hash to map the old schedule name to the new schedule
      light_set_schedules = {}
      space_type_lights = space_type.lights
      space_type_lights.each do |space_type_light|
        light_set_sch = space_type_light.schedule
        if light_set_sch.empty?
          runner.registerWarning("#{space_type_light.name} doesn't have a schedule.")
        else
          if light_set_schedules.key?(light_set_sch.get.name.to_s)
            new_light_set_sch = light_set_schedules[light_set_sch.get.name.to_s]
          else
            new_light_set_sch = light_set_sch.get.clone(model)
            new_light_set_sch = new_light_set_sch.to_Schedule.get
            new_light_set_sch.setName("#{light_set_sch.get.name.to_s} adjusted #{lpd_factor}")
            # add to the hash
            light_set_schedules[light_set_sch.get.name.to_s] = new_light_set_sch
          end
          space_type_light.setSchedule(new_light_set_sch)
        end
      end

      light_set_schedules.each do |old_name, light_sch|
        if light_sch.to_ScheduleRuleset.empty?
          runner.registerWarning("Schedule '#{old_name}' isn't a ScheduleRuleset object and won't be altered by this measure.")
          light_sch.remove # remove un-used cloned schedule
        else
          schedule_set = light_sch.to_ScheduleRuleset.get
          default_rule = schedule_set.defaultDaySchedule
          rules = schedule_set.scheduleRules
          days_covered = Array.new(7, false)
          original_rule_number = rules.length
          if original_rule_number > 0
            runner.registerInfo("------------ schedule rule set old_name has #{original_rule_number} rules.")
            current_index = 0
            rules.each_with_index do |rule, index|
              runner.registerInfo("------------ Rule #{rule.ruleIndex}: #{rule.daySchedule.name.to_s}")
              rule_period1 = rule.clone(model).to_ScheduleRule.get # OpenStudio::Model::ScheduleRule.new(schedule_set, rule.daySchedule)
              rule_period1.setStartDate(os_start_date1)
              rule_period1.setEndDate(os_end_date1)
              checkDaysCovered(rule_period1, days_covered)
              runner.registerInfo("--------------- rule applies to weekdays? #{rule_period1.applyWeekdays}")
              runner.registerInfo("--------------- rule applies to saturday? #{rule_period1.applySaturday}")
              runner.registerInfo("--------------- rule applies to sunday? #{rule_period1.applySunday}")
              runner.registerInfo("--------------- days of week covered now: #{days_covered}")

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
              day_rule_period1 = updateDaySchedule(day_rule_period1, day_time_vector1, day_value_vector1, shift_time1, shift_time2, lpd_factor)
              runner.registerInfo("    ------------ updated time: #{day_rule_period1.times.map {|os_time| os_time.toString}}")
              runner.registerInfo("    ------------ updated values: #{day_rule_period1.values}")
              runner.registerInfo("--------------- Schedule updated for #{rule_period1.startDate.get} to #{rule_period1.endDate.get}")

              if os_start_date2 and os_end_date2
                rule_period2 = copy_sch_rule_for_period(model, rule_period1, rule_period1.daySchedule, os_start_date2, os_end_date2)
                unless schedule_set.setScheduleRuleIndex(rule_period2, 0)
                  runner.registerError("Fail to set rule index for #{rule_period2.daySchedule.name.to_s}.")
                end
                current_index += 1
                runner.registerInfo("--------------- Schedule updated for #{rule_period2.startDate.get} to #{rule_period2.endDate.get}")
              end

              if os_start_date3 and os_end_date3
                rule_period3 = copy_sch_rule_for_period(model, rule_period1, rule_period1.daySchedule, os_start_date3, os_end_date3)
                unless schedule_set.setScheduleRuleIndex(rule_period3, 0)
                  runner.registerError("Fail to set rule index for #{rule_period3.daySchedule.name.to_s}.")
                end
                current_index += 1
                runner.registerInfo("--------------- Schedule updated for #{rule_period3.startDate.get} to #{rule_period3.endDate.get}")
              end

              unless schedule_set.setScheduleRuleIndex(rule, original_rule_number + current_index - 1)
                runner.registerError("Fail to set rule index for #{rule.daySchedule.name.to_s}.")
              end
              runner.registerInfo("--------------- Current sule index of the original rule: #{rule.ruleIndex}")
            end
          else
            runner.registerWarning("Lighting schedule '#{old_name}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
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
            new_default_day = updateDaySchedule(new_default_day, day_time_vector, day_value_vector, shift_time1, shift_time2, lpd_factor)
            if os_start_date2 and os_end_date2
              copy_sch_rule_for_period(model, new_default_rule, new_default_day, os_start_date2, os_end_date2)
            end
            if os_start_date3 and os_end_date3
              copy_sch_rule_for_period(model, new_default_rule, new_default_day, os_start_date3, os_end_date3)
            end

          end

        end

      end

      runner.registerInfo("------------------------FINAL--------------------")
      space_type.lights.each do |light|
        lgt_schedule_set = light.schedule
        unless lgt_schedule_set.empty?
          runner.registerInfo("Schedule #{lgt_schedule_set.get.name.to_s}:")
          sch_set = lgt_schedule_set.get.to_Schedule.get
          sch_set.to_ScheduleRuleset.get.scheduleRules.each do |rule|
            runner.registerInfo("  rule #{rule.ruleIndex}: #{rule.daySchedule.name.to_s} from #{rule.startDate.get} to #{rule.endDate.get}")
          end
        end
      end
    end
    unless applicable
      runner.registerAsNotApplicable('No lighting schedule in the model could be altered.')
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
AverageVentilationForPeakHours.new.registerWithApplication
