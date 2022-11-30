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
class ReduceDomesticHotWaterUseForPeakHours < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Reduce domestic hot water use for peak hours'
  end

  # human readable description
  def description
    return 'This measure reduces the domestic hot water usage by a user-specified percentage for a user-specified time period (usually the peak hours). This is applied to the whole building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will clone the flow rate fraction schedules of all the WaterUseEquipment. Then the schedules are adjusted by the specified percentage during the specified time period. '
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    water_use_reduce_percent = OpenStudio::Measure::OSArgument.makeDoubleArgument('water_use_reduce_percent', true)
    water_use_reduce_percent.setDisplayName('Percentage Reduction of Domestic Hot Water Use (%)')
    water_use_reduce_percent.setDescription('Enter a value between 0 and 100')
    water_use_reduce_percent.setDefaultValue(50.0)
    args << water_use_reduce_percent

    # make an argument for the start time of the reduction
    start_time = OpenStudio::Measure::OSArgument.makeStringArgument('start_time', false)
    start_time.setDisplayName('Start Time for the Reduction')
    start_time.setDescription('In HH:MM:SS format')
    start_time.setDefaultValue('16:00:00')
    args << start_time

    # make an argument for the end time of the reduction
    end_time = OpenStudio::Measure::OSArgument.makeStringArgument('end_time', false)
    end_time.setDisplayName('End Time for the Reduction')
    end_time.setDescription('In HH:MM:SS format')
    end_time.setDefaultValue('21:00:00')
    args << end_time

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
    water_use_reduce_percent = runner.getDoubleArgumentValue('water_use_reduce_percent', user_arguments)
    start_time = runner.getStringArgumentValue('start_time', user_arguments)
    end_time = runner.getStringArgumentValue('end_time', user_arguments)

    # validate the percentage
    if water_use_reduce_percent > 100
      runner.registerError('The percentage reduction of domestic hot water use cannot be larger than 100.')
      return false
    elsif water_use_reduce_percent < 0
      runner.registerWarning('The percentage reduction of domestic hot water use is negative. This will increase the domestic hot water use.')
    end

    if start_time.to_f > end_time.to_f
      runner.registerError('For domestic hot water use adjustment, the end time should be larger than the start time.')
      return false
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

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getWaterUseEquipments.size} WaterUseEquipment and #{(model.getWaterHeaterMixeds + model.getWaterHeaterStratifieds).size} WaterHeaterMixed.")

    def update_new_sch(sch_day, start_time, end_time, reduce_pct)
      # grab time-value pairs for modification
      old_times = sch_day.times
      old_values = sch_day.values

      count = 0
      old_times.each_with_index do |exist_timestamp, i|
        adjusted_value = old_values[i] * (100 - reduce_pct) * 0.01
        if exist_timestamp > start_time && exist_timestamp < end_time && count == 0
          sch_day.addValue(start_time, old_values[i])
          sch_day.addValue(exist_timestamp, adjusted_value)
          count = 1
        elsif exist_timestamp == end_time && count == 0
          sch_day.addValue(start_time, old_values[i])
          sch_day.addValue(exist_timestamp, adjusted_value)
          count = 2
        elsif exist_timestamp == start_time && count == 0
          sch_day.addValue(exist_timestamp, old_values[i])
          count = 1
        elsif exist_timestamp > end_time && count == 0
          sch_day.addValue(start_time, old_values[i])
          sch_day.addValue(end_time, adjusted_value)
          sch_day.addValue(exist_timestamp,  old_values[i])
          count = 2
        elsif exist_timestamp > start_time && exist_timestamp < end_time && count==1
          sch_day.addValue(exist_timestamp, adjusted_value)
        elsif exist_timestamp == end_time && count==1
          sch_day.addValue(exist_timestamp, adjusted_value)
          count = 2
        elsif exist_timestamp > end_time && count == 1
          sch_day.addValue(end_time, adjusted_value)
          sch_day.addValue(exist_timestamp, old_values[i])
          count = 2
        else
          sch_day.addValue(exist_timestamp, old_values[i])
        end
      end

      return sch_day
    end

    yd = model.getYearDescription
    start_date = yd.makeDate(1, 1)
    end_date = yd.makeDate(12, 31)

    changed_water_equip_count = 0
    # modify the flow rate fraction schedule for all the water use equipment
    model.getWaterUseEquipments.each do |water_equip|
      if water_equip.flowRateFractionSchedule.is_initialized
        if water_equip.flowRateFractionSchedule.get.to_ScheduleRuleset.is_initialized
          new_sch = water_equip.flowRateFractionSchedule.get.clone.to_ScheduleRuleset.get
          sch_name = water_equip.flowRateFractionSchedule.get.name.to_s

          # rename and duplicate for later modification
          new_sch.setName(sch_name + ' adjusted')
          new_sch.defaultDaySchedule.setName(sch_name + ' adjusted Default')
          update_new_sch(new_sch.defaultDaySchedule, shift_time1, shift_time2, water_use_reduce_percent)
          new_sch.scheduleRules.each do |rule|
            update_new_sch(rule.daySchedule, shift_time1, shift_time2, water_use_reduce_percent)
          end

          water_equip.setFlowRateFractionSchedule(new_sch)
          changed_water_equip_count += 1
        else
          runner.registerWarning("The flow rate schedule of water use equipment #{water_equip.name.to_s} is not a ScheduleRuleset, cannot modify with this measure.")
        end
      else
        # when no flow rate fraction assigned, by default it is assuming 1 all the time.
        new_sch = OpenStudio::Model::ScheduleRuleset.new(model)
        new_sch.setName("Hot water flow rate fraction sch adjusted")
        new_sch.defaultDaySchedule.setName('Hot water flow rate fraction sch adjusted Default')
        new_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)
        update_new_sch(new_sch.defaultDaySchedule, shift_time1, shift_time2, water_use_reduce_percent)

        water_equip.setFlowRateFractionSchedule(new_sch)
        changed_water_equip_count += 1
      end
    end

    changed_water_heater_count = 0
    # modify the flow rate fraction schedule of the water heaters
    all_water_heaters = model.getWaterHeaterMixeds + model.getWaterHeaterStratifieds
    all_water_heaters.each do |water_heater|
      if water_heater.useFlowRateFractionSchedule.is_initialized
        if water_heater.useFlowRateFractionSchedule.get.to_ScheduleRuleset.is_initialized
          new_sch = water_heater.useFlowRateFractionSchedule.get.clone.to_ScheduleRuleset.get

          # rename and duplicate for later modification
          new_sch.setName('Water heater flow rate fraction sch adjusted')
          new_sch.defaultDaySchedule.setName('Water heater flow rate fraction sch adjusted Default')
          update_new_sch(new_sch.defaultDaySchedule, shift_time1, shift_time2, water_use_reduce_percent)
          new_sch.scheduleRules.each do |rule|
            update_new_sch(rule.daySchedule, shift_time1, shift_time2, water_use_reduce_percent)
          end

          water_heater.setUseFlowRateFractionSchedule(new_sch)
          changed_water_heater_count += 1
        else
          runner.registerWarning("The flow rate schedule of water heater #{water_heater.name.to_s} is not a ScheduleRuleset, cannot modify with this measure.")
        end
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with hot water use reduced for #{changed_water_equip_count} water use equipments and #{changed_water_heater_count} water heaters.")

    return true
  end
end

# register the measure to be used by the application
ReduceDomesticHotWaterUseForPeakHours.new.registerWithApplication
