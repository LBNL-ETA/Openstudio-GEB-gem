# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_schedules'
class AverageVentilationForPeakHours < OpenStudio::Measure::ModelMeasure
  include OsLib_HelperMethods
  include OsLib_Schedules
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
    return "The outdoor air flow rate will be reduced by the percentage specified by the user during the peak hours specified by the user. Then the decreased air flow rate will be added to the same number of hours before the peak time."
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
    start_time.setDefaultValue('12:00:00')
    args << start_time

    # make an argument for the end time of the reduction
    end_time = OpenStudio::Measure::OSArgument.makeStringArgument('end_time', false)
    end_time.setDisplayName('End Time for the Reduction')
    end_time.setDescription('In HH:MM:SS format')
    end_time.setDefaultValue('14:00:00')
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
    end_date1.setDefaultValue('08-31')
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
      runner.registerError('Start time must be in HH:MM:SS format.')
      return false
    end

    if /(\d\d):(\d\d):(\d\d)/.match(end_time)
      shift_time2 = OpenStudio::Time.new(end_time)
    else
      runner.registerError('End time must be in HH:MM:SS format.')
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


    design_spec_outdoor_air_objects = model.getDesignSpecificationOutdoorAirs
    if !design_spec_outdoor_air_objects.empty?
      runner.registerInitialCondition("The original model contained #{design_spec_outdoor_air_objects.size} design specification outdoor air objects.")
    else
      runner.registerInitialCondition('The original model did not contain any design specification outdoor air.')
      return true
    end

    schedules = {}
    vent_factor = 1 - (vent_reduce_percent * 0.01)
    design_spec_outdoor_air_objects.each do |outdoor_air_object|
      oa_sch = outdoor_air_object.outdoorAirFlowRateFractionSchedule
      if oa_sch.empty?
        new_oa_sch_name = "#{outdoor_air_object.name} fraction schedule"
        runner.registerInfo("#{outdoor_air_object.name} doesn't have a schedule. A new schedule '#{new_oa_sch_name}' will be added.")
        # The fraction schedule cannot have value > 1,
        # so in order to increase the ventilation rate before peak hours, the original base value need to be increased
        outdoor_air_object.setOutdoorAirFlowperPerson(outdoor_air_object.outdoorAirFlowperPerson * (1+vent_reduce_percent*0.01))
        outdoor_air_object.setOutdoorAirFlowperFloorArea(outdoor_air_object.outdoorAirFlowperFloorArea * (1+vent_reduce_percent*0.01))
        outdoor_air_object.setOutdoorAirFlowAirChangesperHour(outdoor_air_object.outdoorAirFlowAirChangesperHour * (1+vent_reduce_percent*0.01))
        outdoor_air_object.setOutdoorAirFlowRate(outdoor_air_object.outdoorAirFlowRate * (1+vent_reduce_percent*0.01))
        percent_back = 1/(1+vent_reduce_percent*0.01)
        percent_reduce = percent_back * vent_factor
        h, m, s  = start_time.split(':')
        start_hour = h.to_i +  m.to_i/60
        h, m, s  = end_time.split(':')
        end_hour = h.to_i +  m.to_i/60
        time_span = end_hour - start_hour
        increase_start_hour = start_hour - time_span
        if increase_start_hour < 0
          increase_start_hour += 24
        end
        if increase_start_hour < start_hour
          adjusted_day_data_pairs = [[increase_start_hour, percent_back], [start_hour, 1], [end_hour, percent_reduce], [24, percent_back]]
        else
          adjusted_day_data_pairs = [[start_hour, 1], [end_hour, percent_reduce], [increase_start_hour, percent_back], [24, 1]]
        end
        # end_hour_2 = end_hour + time_span
        # if end_hour_2 > 24.0
        #   end_hour_2 -= 24.0
        # end
        # if end_hour_2 < start_hour
        #   adjusted_day_data_pairs = [[end_hour_2, 1], [start_hour, percent_back], [end_hour, percent_reduce], [24, 1]]
        # else
        #   adjusted_day_data_pairs = [[start_hour, percent_back], [end_hour, percent_reduce], [end_hour_2, 1], [24, percent_back]]
        # end

        normal_day_data_pairs = [[24, percent_back]]
        options = { 'name' => new_oa_sch_name,
                    'winter_design_day' => normal_day_data_pairs,
                    'summer_design_day' => normal_day_data_pairs,
                    'default_day' => ["default day"] + normal_day_data_pairs,
                    'rules' => [['Adjusted days', "#{start_month1}/#{start_day1}-#{end_month1}/#{end_day1}",
                                 'Sun/Mon/Tue/Wed/Thu/Fri/Sat'] + adjusted_day_data_pairs] }
        new_oa_sch = OsLib_Schedules.createComplexSchedule(model, options)
        outdoor_air_object.setOutdoorAirFlowRateFractionSchedule(new_oa_sch)
      else
        if schedules.key?(oa_sch.get.name.to_s)
          new_oa_sch = schedules[oa_sch.get.name.to_s]
        else
          new_oa_sch = oa_sch.get.clone(model)
          new_oa_sch = new_oa_sch.to_Schedule.get
          new_oa_sch.setName("#{oa_sch.get.name.to_s} averaged ventilation")
          # add to the hash
          schedules[oa_sch.get.name.to_s] = new_oa_sch
        end
        outdoor_air_object.setOutdoorAirFlowRateFractionSchedule(new_oa_sch)
      end
    end
    # create a new outdoor air schedule based on the input

    schedules.each do |old_sch_name, oa_schedule|
      if oa_schedule.to_ScheduleRuleset.empty?
        runner.registerWarning("Schedule #{old_sch_name} isn't a ScheduleRuleset object and won't be altered by this measure.")
      else
        schedule_set = oa_schedule.to_ScheduleRuleset.get
        default_rule = schedule_set.defaultDaySchedule
        rules = schedule_set.scheduleRules
        days_covered = Array.new(7, false)
        original_rule_number = rules.length
        if original_rule_number > 0
          runner.registerInfo("------------ schedule rule set #{old_sch_name} has #{original_rule_number} rules.")
          current_index = 0
          # rules are in order of priority
          rules.each do |rule|
            runner.registerInfo("------------ Rule #{rule.ruleIndex}: #{rule.daySchedule.name.to_s}")
            rule_period1 = rule.clone(model).to_ScheduleRule.get # OpenStudio::Model::ScheduleRule.new(schedule_set, rule.daySchedule)
            rule_period1.setStartDate(os_start_date1)
            rule_period1.setEndDate(os_end_date1)
            checkDaysCovered(rule_period1, days_covered)
            runner.registerInfo("--------------- current days of week coverage: #{days_covered}")

            day_rule_period1 = rule_period1.daySchedule
            day_time_vector1 = day_rule_period1.times
            day_value_vector1 = day_rule_period1.values
            runner.registerInfo("    ------------ time: #{day_time_vector1.map {|os_time| os_time.toString}}")
            runner.registerInfo("    ------------ values: #{day_value_vector1}")
            day_rule_period1.clearValues
            day_rule_period1 = updateDaySchedule(day_rule_period1, day_time_vector1, day_value_vector1, shift_time1, shift_time2, vent_factor)
            # set the order of the new cloned schedule rule, to make sure the modified rule has a higher priority than the original one
            # and different copies keep the same priority as their original orders
            unless schedule_set.setScheduleRuleIndex(rule_period1, current_index)
              runner.registerError("Fail to set rule index for #{day_rule_period1.name.to_s}.")
            end
            current_index += 1
            runner.registerInfo("    ------------ updated time: #{day_rule_period1.times.map {|os_time| os_time.toString}}")
            runner.registerInfo("    ------------ updated values: #{day_rule_period1.values}")
            runner.registerInfo("    ------------ schedule updated for #{rule_period1.startDate.get} to #{rule_period1.endDate.get}")

            # The original rule will be shifted to have the currently lowest priority
            unless schedule_set.setScheduleRuleIndex(rule, original_rule_number + current_index - 1)
              runner.registerError("Fail to set rule index for #{rule.daySchedule.name.to_s}.")
            end
            # runner.registerInfo("--------------- Current sule index of the original rule: #{rule.ruleIndex}")
          end
        else
          runner.registerWarning("outdoorAirFlowRateFractionSchedule #{old_sch_name} is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
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
          new_default_day = updateDaySchedule(new_default_day, day_time_vector, day_value_vector, shift_time1, shift_time2, vent_factor)

        end
      end
    end

    # model.getAirLoopHVACs.each do |air_system|
    #   oa_system = air_system.airLoopHVACOutdoorAirSystem
    #   unless oa_system.empty?
    #     oa_system.get.getControllerOutdoorAir.setMaximumFractionofOutdoorAirSchedule(vent_schedule)
    #   end
    # end


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
