# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ReduceExteriorLightingLoads < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Reduce Exterior Lighting Loads'
  end

  # human readable description
  def description
    return 'This measure reduces exterior lighting loads by two ways: (1) upgrading the lighting fixtures '\
           'to be more efficient, which reduces the design level value, (2) reducing operational duration'\
           'and/or strength by adjusting control option and schedule based on daylight, occupancy, and/or user designated period.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure can (1) reduce design level by percentage if given by the user, (2) update the control option '\
           'to AstronomicalClock, (3) adjust the schedule by replacing with occupancy schedule of '\
           'the majority space/spacetype, and/or turn off or dim during user designated period.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # design level value reduction percentage specified by user, default is 0
    design_val_reduce_percent = OpenStudio::Measure::OSArgument.makeDoubleArgument('design_val_reduce_percent', false)
    design_val_reduce_percent.setDisplayName('Percentage Reduction of Exterior Lighting Design Power (%)')
    design_val_reduce_percent.setDescription('Enter a value between 0 and 100')
    args << design_val_reduce_percent

    # Use daylight control, i.e., AstronomicalClock as control option.
    # This makes sure that the exterior lights are turned off during the day
    use_daylight_control = OpenStudio::Measure::OSArgument.makeBoolArgument('use_daylight_control', true)
    use_daylight_control.setDisplayName('Use daylight control')
    use_daylight_control.setDescription('If exterior lights will be turned off during the day')
    use_daylight_control.setDefaultValue(false)
    args << use_daylight_control

    # Use occupancy sensing. This will turn off exterior lights when unoccupied, and dim with partial occupancy
    use_occupancy_sensing = OpenStudio::Measure::OSArgument.makeBoolArgument('use_occupancy_sensing', true)
    use_occupancy_sensing.setDisplayName('Use occupancy sensing')
    use_occupancy_sensing.setDescription('If enabled, this will turn off exterior lights when unoccupied, and dim with partial occupancy')
    use_occupancy_sensing.setDefaultValue(false)
    args << use_occupancy_sensing
    
    # schedule on fraction during user designated period
    on_frac_in_defined_period = OpenStudio::Measure::OSArgument.makeDoubleArgument('on_frac_in_defined_period', false)
    on_frac_in_defined_period.setDisplayName('Schedule value representing light on fraction to turn off (0) or dim (<1) during user designated event period')
    on_frac_in_defined_period.setDescription('Enter a value >=0 and <1')
    args << on_frac_in_defined_period

    # user designated period start time
    user_defined_start_time = OpenStudio::Measure::OSArgument.makeStringArgument('user_defined_start_time', false)
    user_defined_start_time.setDisplayName('User Designated Event Start Time for the off/dimming')
    user_defined_start_time.setDescription('In HH:MM:SS format')
    user_defined_start_time.setDefaultValue('01:00:00')
    args << user_defined_start_time

    # user designated period end time
    user_defined_end_time = OpenStudio::Measure::OSArgument.makeStringArgument('user_defined_end_time', false)
    user_defined_end_time.setDisplayName('User Designated Event End Time for the off/dimming')
    user_defined_end_time.setDescription('In HH:MM:SS format')
    user_defined_end_time.setDefaultValue('04:00:00')
    args << user_defined_end_time
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # if no exterior lights in the building, measure not applicable
    if model.getExteriorLightss.size == 0
      runner.registerAsNotApplicable("No exterior lights in the building, measure not applicable.")
      return true
    end

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    design_val_reduce_percent = runner.getOptionalDoubleArgumentValue('design_val_reduce_percent', user_arguments)
    use_daylight_control = runner.getBoolArgumentValue('use_daylight_control', user_arguments)
    use_occupancy_sensing = runner.getBoolArgumentValue('use_occupancy_sensing', user_arguments)
    on_frac_in_defined_period = runner.getOptionalDoubleArgumentValue('on_frac_in_defined_period', user_arguments)
    user_defined_start_time = runner.getOptionalStringArgumentValue('user_defined_start_time', user_arguments)
    user_defined_end_time = runner.getOptionalStringArgumentValue('user_defined_end_time', user_arguments)

    # ****** validate parameters *******
    # validate design_val_reduce_percent
    if design_val_reduce_percent.empty?
      design_val_reduce_percent = 0
    elsif design_val_reduce_percent.to_f <= 0 || design_val_reduce_percent.to_f > 100
      runner.registerError("Invalid Percentage Reduction of Exterior Lighting Design Power (%) #{design_val_reduce_percent} entered. Value must be >0 and <=100.")
      return false
    else
      design_val_reduce_percent = design_val_reduce_percent.to_f
    end

    # validate on_frac_in_defined_period
    if on_frac_in_defined_period.empty?
      has_user_defined_event = false
    elsif on_frac_in_defined_period.to_f < 0 || on_frac_in_defined_period.to_f >= 1
      runner.registerError("Invalid schedule fraction value #{on_frac_in_defined_period} entered. Value must be >=0 and <1.")
      return false
    else
      on_frac_in_defined_period = on_frac_in_defined_period.to_f
      has_user_defined_event = true
    end

    # if has user defined event, validate the start and end time, otherwise skip
    if has_user_defined_event
      if user_defined_start_time.empty?
        runner.registerError('User defined event lacks start time, please provide input.')
        return false
      end

      if user_defined_end_time.empty?
        runner.registerError('User defined event lacks end time, please provide input.')
        return false
      end

      if /(\d\d):(\d\d):(\d\d)/.match(user_defined_start_time.to_s)
        os_start_time = OpenStudio::Time.new(user_defined_start_time.to_s)
      else
        runner.registerError('Start time must be in HH-MM-SS format.')
        return false
      end

      if /(\d\d):(\d\d):(\d\d)/.match(user_defined_end_time.to_s)
        os_end_time = OpenStudio::Time.new(user_defined_end_time.to_s)
      else
        runner.registerError('End time must be in HH-MM-SS format.')
        return false
      end

      if os_start_time == os_end_time
        runner.registerError('Start and end time can not be the same.')
        return false
      end
    end

    # report initial condition of model
    runner.registerInitialCondition("There are #{model.getExteriorLightss.size} exterior lights objects in the building.")

    # reduce design level by percentage
    if design_val_reduce_percent > 0
      model.getExteriorLightsDefinitions.each do |ext_light_def|
        origin_design_level = ext_light_def.designLevel
        ext_light_def.setDesignLevel(origin_design_level * (100-design_val_reduce_percent)/100.0)
      end
      runner.registerInfo("Exterior light load is reduced by #{design_val_reduce_percent}%.")
    end

    # update control option to AstronomicalClock if true
    if use_daylight_control
      model.getExteriorLightss.each do |ext_light|
        ext_light.setControlOption('AstronomicalClock')
      end
      runner.registerInfo("Exterior light is using daylight control.")
    end

    # occupancy sensing
    major_occ_sch = nil   #initial
    if use_occupancy_sensing
      # get the occupancy schedule of the majority space/spacetype
      # first try building level schedule set
      if (not model.building.empty?) && (not model.building.get.defaultScheduleSet.empty?)
        occ_sch = model.building.get.defaultScheduleSet.get.numberofPeopleSchedule
        unless occ_sch.empty?
          major_occ_sch = occ_sch.get
        end
      else
        # then try spacetype
        spc_type_max_area = 0  # initial
        major_spc_stype = nil  # initial
        model.getSpaceTypes.each do |spc_type|
          if spc_type_max_area == 0
            spc_type_max_area = spc_type.floorArea
            major_spc_stype = spc_type
          elsif spc_type_max_area < spc_type.floorArea
            spc_type_max_area = spc_type.floorArea
            major_spc_stype = spc_type
          end
        end
        major_spc_type_default_sch_set = major_spc_stype.defaultScheduleSet
        if not major_spc_type_default_sch_set.empty?
          occ_sch = major_spc_type_default_sch_set.get.numberofPeopleSchedule
          unless occ_sch.empty?
            major_occ_sch = occ_sch.get
          end
        end

        # if no major occupancy schedule found from space type, then try space
        if major_occ_sch.nil?
          spc_max_area = 0   #initial
          major_spc = nil   #initial
          model.getSpaces.each do |spc|
            if spc_max_area == 0
              spc_max_area = spc.floorArea
              major_spc = spc
            elsif spc_max_area < spc.floorArea
              spc_max_area = spc.floorArea
              major_spc = spc
            end
          end
          major_spc_default_sch_set = major_spc.defaultScheduleSet
          if not major_spc_default_sch_set.empty?
            occ_sch = major_spc_default_sch_set.get.numberofPeopleSchedule
            unless occ_sch.empty?
              major_occ_sch = occ_sch.get
            end
          else
            if major_spc.people.size > 0
              occ_sch = major_spc.people[0].numberofPeopleSchedule
              unless occ_sch.empty?
                major_occ_sch = occ_sch.get
              else
                runner.registerWarning("No schedule defined for the people object of the major space #{major_spc.name.to_s}.")
              end
            else
              runner.registerWarning("No people object found for the major space #{major_spc.name.to_s}.")
            end
          end
        end
      end

      # check if a major_occ_sch is found
      if major_occ_sch.nil?
        runner.registerError("Occupancy sensing control is enabled, but no major occupancy schedule can be found.")
        return false
      else
        model.getExteriorLightss.each do |ext_light|
          ext_light.setSchedule(major_occ_sch)
        end
        runner.registerInfo("Exterior light is using occupancy sensing control.")
      end
    end

    def add_event_to_sch(model, runner, sch, on_frac_in_defined_period, start_time, end_time)
      new_sch = sch.get.clone(model)
      new_sch = new_sch.to_Schedule.get
      new_sch.setName("#{sch.get.name.to_s} add user defined event")

      # make cooling schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
      if !new_sch.to_ScheduleRuleset.empty?
        schedule = new_sch.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules

        # update default day schedule
        default_day_time_vector = default_rule.times
        default_day_value_vector = default_rule.values
        default_rule.clearValues
        updateDaySchedule(default_rule, default_day_time_vector, default_day_value_vector, start_time, end_time, on_frac_in_defined_period)

        # update all schedule rules
        if rules.length > 0
          rules.each do |rule|
            day_sch = rule.daySchedule
            day_time_vector = day_sch.times
            day_value_vector = day_sch.values
            day_sch.clearValues
            updateDaySchedule(day_sch, day_time_vector, day_value_vector, start_time, end_time, on_frac_in_defined_period)
          end
        else
          runner.registerWarning("Exterior light schedule '#{sch.get.name.to_s}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
        end
      else
        runner.registerWarning("Schedule '#{sch.get.name.to_s}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        new_sch.remove # remove un-used clone
      end

      return new_sch
    end

    def updateDaySchedule(sch_day, vec_time, vec_value, time_begin, time_end, new_value)
      count = 0
      if time_end > time_begin
        vec_time.each_with_index do |exist_timestamp, i|
          if exist_timestamp > time_begin && exist_timestamp < time_end && count == 0
            sch_day.addValue(time_begin, vec_value[i])
            sch_day.addValue(exist_timestamp, new_value)
            count = 1
          elsif exist_timestamp == time_end && count == 0
            sch_day.addValue(time_begin, vec_value[i])
            sch_day.addValue(exist_timestamp, new_value)
            count = 2
          elsif exist_timestamp == time_begin && count == 0
            sch_day.addValue(exist_timestamp, vec_value[i])
            count = 1
          elsif exist_timestamp > time_end && count == 0
            sch_day.addValue(time_begin, vec_value[i])
            sch_day.addValue(time_end, new_value)
            sch_day.addValue(exist_timestamp,  vec_value[i])
            count = 2
          elsif exist_timestamp > time_begin && exist_timestamp < time_end && count==1
            sch_day.addValue(exist_timestamp, new_value)
          elsif exist_timestamp == time_end && count==1
            sch_day.addValue(exist_timestamp, new_value)
            count = 2
          elsif exist_timestamp > time_end && count == 1
            sch_day.addValue(time_end, new_value)
            sch_day.addValue(exist_timestamp, vec_value[i])
            count = 2
          else
            sch_day.addValue(exist_timestamp, vec_value[i])
          end
        end
      else
        # time_end < time_begin, event goes overnight
        vec_time.each_with_index do |exist_timestamp, i|
          if exist_timestamp < time_end
            sch_day.addValue(exist_timestamp, new_value)
          elsif exist_timestamp == time_end && count == 0
            sch_day.addValue(exist_timestamp, new_value)
            count = 1  # 1 represents time_end has been filled
          elsif exist_timestamp > time_end && exist_timestamp < time_begin && count == 0
            sch_day.addValue(time_end, new_value)
            sch_day.addValue(exist_timestamp, vec_value[i])
            count = 1
          elsif exist_timestamp > time_end && exist_timestamp < time_begin && count == 1
            sch_day.addValue(exist_timestamp, vec_value[i])
          elsif exist_timestamp == time_begin && count == 0
            sch_day.addValue(time_end, new_value)
            sch_day.addValue(exist_timestamp, vec_value[i])
            count = 2
          elsif exist_timestamp == time_begin && count == 1
            sch_day.addValue(exist_timestamp, vec_value[i])
            count = 2  # 2 represents time_begin has been filled
          elsif exist_timestamp > time_begin && count == 0
            sch_day.addValue(time_end, new_value)
            sch_day.addValue(time_begin, vec_value[i])
            sch_day.addValue(exist_timestamp, new_value)
            count = 2
          elsif exist_timestamp > time_begin && count == 1
            sch_day.addValue(time_begin, vec_value[i])
            sch_day.addValue(exist_timestamp, new_value)
            count = 2
          elsif exist_timestamp > time_begin && count == 2
            sch_day.addValue(exist_timestamp, new_value)
          end
        end
      end

      return sch_day
    end

    # user defined schedule update
    # refer to add ceiling fan change thermostat setpoint
    if has_user_defined_event
      model.getExteriorLightss.each do |ext_light|
        if ext_light.schedule.empty?
          runner.registerError("Has user defined event, but lack existing schedule for exterior light #{ext_light.name.to_s}.")
          return false
        else
          new_sch = add_event_to_sch(model, runner, ext_light.schedule, on_frac_in_defined_period, os_start_time, os_end_time)
          ext_light.setSchedule(new_sch)
        end
      end
      runner.registerInfo("Exterior light schedule is modified by adding user defined event.")
    end

    # report final condition of model
    runner.registerFinalCondition("The exterior lighting load is reduced.")

    return true
  end
end

# register the measure to be used by the application
ReduceExteriorLightingLoads.new.registerWithApplication
