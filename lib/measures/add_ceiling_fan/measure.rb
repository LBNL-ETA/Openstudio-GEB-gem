# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddCeilingFan < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add Ceiling Fan'
  end

  # human readable description
  def description
    return 'Install ceiling fans in buildings to increase air circulation. Ceiling fans effectively cool by introducing slow movement to induce evaporative cooling, rather than directly conditioning the air. A diversity factor is added to consider the simultaneous usage among the household.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Ceiling fan is modeled by increasing air velocity in the People objects and adding electric equipment to consider extra fan energy use. Cooling setpoint is increased by certain degrees in the presence of ceiling fans. A schedule is also introduced to simulate ceiling fan operation. A diversity factor (different in commercial and residential buildings) is added to consider the simultaneous usage among the building/household.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # building type: residential or commercial
    # this determines inputs like watts per floor area and diversity factor
    bldg_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('bldg_type', ['residential', 'commercial'], true)
    bldg_type.setDisplayName('Select building type:')
    bldg_type.setDescription('Building type (residential or commercial)')
    bldg_type.setDefaultValue('commercial')
    args << bldg_type

    # cooling setpoint increase
    # default value comes from https://www.sciencedirect.com/science/article/abs/pii/S0360132321004133
    cool_stp_increase_C = OpenStudio::Measure::OSArgument.makeDoubleArgument('cool_stp_increase_C', true)
    cool_stp_increase_C.setDisplayName('Cooling setpoint increase - C')
    cool_stp_increase_C.setDescription('Cooling setpoint increase in degree C')
    cool_stp_increase_C.setDefaultValue(3)
    args << cool_stp_increase_C

    # ceiling fan motor type: AC or DC
    motor_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('motor_type', ['DC', 'AC'], true)
    motor_type.setDisplayName('Select ceiling fan motor type:')
    motor_type.setDescription('Ceiling fan motor type')
    motor_type.setDefaultValue('DC')
    args << motor_type

    # ceiling fan EUI in watts per floor area (optional)
    # if not user assigned, use default values in run function below, which comes from discussion with Center for Built Environment based on their research
    watts_per_m2 = OpenStudio::Measure::OSArgument.makeDoubleArgument('watts_per_m2', false)
    watts_per_m2.setDisplayName('Ceiling fan EUI in watts per floor area')
    watts_per_m2.setDescription('Ceiling fan watts per m2')
    args << watts_per_m2

    # make an argument for the start date of the reduction
    start_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date', false)
    start_date.setDisplayName('First start date for the Reduction')
    start_date.setDescription('In MM-DD format')
    start_date.setDefaultValue('05-01')
    args << start_date

    # make an argument for the end date of the reduction
    end_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date', false)
    end_date.setDisplayName('First end date for the Reduction')
    end_date.setDescription('In MM-DD format')
    end_date.setDefaultValue('09-30')
    args << end_date

    # make an argument for the start time of the reduction
    start_time = OpenStudio::Measure::OSArgument.makeStringArgument('start_time', false)
    start_time.setDisplayName('Start Time for the Reduction')
    start_time.setDescription('In HH:MM:SS format')
    start_time.setDefaultValue('08:00:00')
    args << start_time

    # make an argument for the end time of the reduction
    end_time = OpenStudio::Measure::OSArgument.makeStringArgument('end_time', false)
    end_time.setDisplayName('End Time for the Reduction')
    end_time.setDescription('In HH:MM:SS format')
    end_time.setDefaultValue('18:00:00')
    args << end_time

    # diversity factor
    diversity_factor = OpenStudio::Measure::OSArgument.makeDoubleArgument('diversity_factor', false)
    diversity_factor.setDisplayName('Diversity factor')
    diversity_factor.setDescription('Diversity factor')
    args << diversity_factor

    # people air velocity
    people_air_velocity = OpenStudio::Measure::OSArgument.makeDoubleArgument('people_air_velocity', false)
    people_air_velocity.setDisplayName('People air velocity')
    people_air_velocity.setDescription('Air velocity surrounding people (m/s)')
    people_air_velocity.setDefaultValue(0.8)
    args << people_air_velocity

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
    bldg_type = runner.getStringArgumentValue('bldg_type', user_arguments)
    motor_type = runner.getStringArgumentValue('motor_type', user_arguments)
    cool_stp_increase_C = runner.getDoubleArgumentValue('cool_stp_increase_C', user_arguments)
    start_date = runner.getStringArgumentValue('start_date', user_arguments)
    end_date = runner.getStringArgumentValue('end_date', user_arguments)
    start_time = runner.getStringArgumentValue('start_time', user_arguments)
    end_time = runner.getStringArgumentValue('end_time', user_arguments)
    watts_per_m2 = runner.getOptionalDoubleArgumentValue('watts_per_m2', user_arguments)
    diversity_factor = runner.getOptionalDoubleArgumentValue('diversity_factor', user_arguments)
    people_air_velocity = runner.getOptionalDoubleArgumentValue('people_air_velocity', user_arguments)

    if bldg_type != 'commercial' && bldg_type != 'residential'
      runner.registerError("Wrong building type #{bldg_type} entered. Value must be either 'commercial' or 'residential'.")
      return false
    end

    if motor_type != 'AC' && motor_type != 'DC'
      runner.registerError("Wrong ceiling fan motor type #{motor_type} entered. Value must be either 'AC' or 'DC'.")
      return false
    end

    # validate the cooling setpoint increase
    if cool_stp_increase_C <= 0
      runner.registerError('The cooling setpoint increase should be positive.')
      return false
    elsif cool_stp_increase_C > 10
      runner.registerWarning('The cooling setpoint increase is abnormally large, normally it is between 2-5C.')
    end

    if watts_per_m2.empty?
      # use default value based on building type and motor type
      case bldg_type
      when 'commercial'
        if motor_type == 'DC'
          watts_per_m2 = 0.16146   #0.015W/ft2
        else # 'AC'
          watts_per_m2 = 0.48   # 0.015W/ft2 * 3 (double/triple of DC per CBE Paul Raftery)
        end
      when 'residential'
        if motor_type == 'DC'
          watts_per_m2 = 0.35   # 0.13W/ft2 * 25% (The average power when the fan was running was between 20-25% of max)
        else # 'AC'
          watts_per_m2 = 1.05   # 0.13W/ft2 * 3 (double/triple of DC per CBE Paul Raftery)
        end
      end
    elsif watts_per_m2.to_f <= 0
      runner.registerError("Invalid ceiling fan watts per m2 #{watts_per_m2} entered. Value must be >0.")
      return false
    else
      watts_per_m2 = watts_per_m2.to_f
    end

    # default value references: https://electricalnotes.wordpress.com/2018/04/01/thumb-rules-14-quick-reference-demand-diversity-factor/
    # https://www.electricallicenserenewal.com/Electrical-Continuing-Education-Courses/NEC-Content.php?sectionID=836.0
    if diversity_factor.empty?
      case bldg_type
      when 'commercial'
        diversity_factor = 0.9
      when 'residential'
        diversity_factor = 0.66
      end
    elsif diversity_factor.to_f <= 0 or diversity_factor.to_f > 1
      runner.registerError("Invalid diversity factor #{diversity_factor} entered. Value must be >0 and <=1.")
      return false
    else
      diversity_factor = diversity_factor.to_f
    end

    if people_air_velocity.empty?
      people_air_velocity = 0.8  # default 0.8m/s for ceiling fan operation
    elsif people_air_velocity.to_f <= 0
      runner.registerError("Invalid people air velocity #{people_air_velocity} entered. Value must be positive.")
      return false
    elsif people_air_velocity.to_f > 2
      runner.registerWarning('The people air velocity is abnormally high, normally it is between 0.2-2m/s.')
      people_air_velocity = people_air_velocity.to_f
    elsif people_air_velocity.to_f < 0.2
      runner.registerWarning('The people air velocity is abnormally low, normally it is between 0.2-2m/s.')
      people_air_velocity = people_air_velocity.to_f
    else
      people_air_velocity = people_air_velocity.to_f
    end

    # validate and assign operational period date and time
    if /(\d\d):(\d\d):(\d\d)/.match(start_time)
      os_start_time = OpenStudio::Time.new(start_time)
    else
      runner.registerError('Start time must be in HH-MM-SS format.')
      return false
    end

    if /(\d\d):(\d\d):(\d\d)/.match(end_time)
      os_end_time = OpenStudio::Time.new(end_time)
    else
      runner.registerError('End time must be in HH-MM-SS format.')
      return false
    end

    if start_time.to_f > end_time.to_f
      runner.registerError('The start time cannot be later than the end time.')
      return false
    end

    start_month = nil
    start_day = nil
    md = /(\d\d)-(\d\d)/.match(start_date)
    if md
      start_month = md[1].to_i
      start_day = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    end_month = nil
    end_day = nil
    md = /(\d\d)-(\d\d)/.match(end_date)
    if md
      end_month = md[1].to_i
      end_day = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end

    # create cooling setpoint schedule and fan operation schedule for ceiling or portable fans
    def create_cooling_and_fan_schedule(model, start_date, end_date, start_time, end_time, diversity_factor)
      year_start = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, model.assumedYear)
      year_end = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(12), 31, model.assumedYear)

      fan_sch_week = OpenStudio::Model::ScheduleWeek.new(model)
      fan_sch_week.setName("Ceiling fan operation sch week")

      ## Check for Schedule Type Limits and Create if Needed
      if !model.getModelObjectByName('OnOff').empty?
        sched_limits_onoff = model.getModelObjectByName('OnOff').get.to_ScheduleTypeLimits.get
      else
        sched_limits_onoff = OpenStudio::Model::ScheduleTypeLimits.new(model)
        sched_limits_onoff.setName('OnOff')
        sched_limits_onoff.setNumericType('Discrete')
        sched_limits_onoff.setUnitType('Availability')
        sched_limits_onoff.setLowerLimitValue(0.0)
        sched_limits_onoff.setUpperLimitValue(1.0)
      end

      fan_sch_day = OpenStudio::Model::ScheduleDay.new(model)
      fan_sch_day.setName("Ceiling fan operation sch default")
      fan_sch_day.setScheduleTypeLimits(sched_limits_onoff)
      fan_sch_day.addValue(start_time, 0)
      if end_time < OpenStudio::Time.new('24:00:00')
        fan_sch_day.addValue(end_time, 1.0 * diversity_factor)
        fan_sch_day.addValue(OpenStudio::Time.new('24:00:00'), 0)
      else
        fan_sch_day.addValue(OpenStudio::Time.new('24:00:00'), 1.0 * diversity_factor)
      end
      fan_sch_week.setAllSchedules(fan_sch_day)

      fan_off_day = OpenStudio::Model::ScheduleDay.new(model)
      fan_off_day.setName("Ceiling fan off sch day")
      fan_off_day.setScheduleTypeLimits(sched_limits_onoff)
      fan_off_day.addValue(OpenStudio::Time.new(0,24,0,0), 0)
      fan_off_week = OpenStudio::Model::ScheduleWeek.new(model)
      fan_off_week.setName("Ceiling fan off sch week")
      fan_off_week.setAllSchedules(fan_off_day)

      fan_sch = OpenStudio::Model::ScheduleYear.new(model)
      fan_sch.setName("Ceiling fan sch")
      fan_sch.setScheduleTypeLimits(sched_limits_onoff)

      # if ceiling fan only operates during a specific period
      unless start_date == year_start
        fan_sch.addScheduleWeek(start_date, fan_off_week)
      end

      if end_date == year_end
        fan_sch.addScheduleWeek(year_end, fan_sch_week)
      else
        fan_sch.addScheduleWeek(end_date, fan_sch_week)
        fan_sch.addScheduleWeek(year_end, fan_off_week)
      end

      puts "fan_sch: #{fan_sch}"

      return fan_sch
    end

    def updateDaySchedule(sch_day, vec_time, vec_value, time_begin, time_end, add_value)
      count = 0
      vec_time.each_with_index do |exist_timestamp, i|
        new_value = vec_value[i] + add_value
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

      return sch_day
    end

    # copy ScheduleRule sch_rule, copy ScheduleDay sch_day and assign to new schedule rule
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

    def adjust_cool_sch(model, sch, cool_stp_inc, start_date, end_date, start_time, end_time)
      new_sch = sch.get.clone(model)
      new_sch = new_sch.to_Schedule.get
      new_sch.setName("#{sch.get.name.to_s} increased by #{cool_stp_inc}C due to ceiling fan")
      year_start = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, model.assumedYear)
      year_end = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(12), 31, model.assumedYear)

      # make cooling schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
      if !new_sch.to_ScheduleRuleset.empty?
        schedule = new_sch.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules
        days_covered = Array.new(7, false)

        # TODO: when ruleset has multiple rules for each month or couple of months instead of a full year, should first see if the period overlaps with summer/winter
        if rules.length > 0
          rules.each do |rule|
            unless start_date == year_start
              unchanged_rule1 = copy_sch_rule_for_period(model, rule, rule.daySchedule, year_start, start_date)
            end

            unless end_date == year_end
              unchanged_rule2 = copy_sch_rule_for_period(model, rule, rule.daySchedule, end_date, year_end)
            end

            change_rule = rule
            checkDaysCovered(change_rule, days_covered)
            change_rule.setStartDate(start_date)
            change_rule.setEndDate(end_date)

            change_day = change_rule.daySchedule
            day_time_vector = change_day.times
            day_value_vector = change_day.values
            change_day.clearValues

            change_day = updateDaySchedule(change_day, day_time_vector, day_value_vector, start_time, end_time, cool_stp_inc)
          end
        else
          runner.registerWarning("Cooling setpoint schedule '#{sch.get.name.to_s}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
        end

        # for days not covered (not defined specifically), modify default schedule
        if days_covered.include?(false)
          unless start_date == year_start
            unchanged_rule1 = create_sch_rule_from_default(model, schedule, default_rule, year_start, start_date)
          end

          unless end_date == year_end
            unchanged_rule2 = create_sch_rule_from_default(model, schedule, default_rule, end_date, year_end)
          end

          coverMissingDays(unchanged_rule1, days_covered)
          checkDaysCovered(unchanged_rule1, days_covered)

          change_rule = copy_sch_rule_for_period(model, unchanged_rule1, default_rule, start_date, end_date)

          change_day = change_rule.daySchedule
          day_time_vector = change_day.times
          day_value_vector = change_day.values
          change_day.clearValues

          change_day = updateDaySchedule(change_day, day_time_vector, day_value_vector, start_time, end_time, cool_stp_inc)
        end

        ######################################################################
      else
        runner.registerWarning("Schedule '#{sch.get.name.to_s}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        new_sch.remove # remove un-used clone
      end

      return new_sch
    end

    # add model's assumed year to make sure addScheduleWeek to scheduleYear can go through
    os_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(start_month), start_day, model.assumedYear)
    os_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(end_month), end_day, model.assumedYear)

    # generate fan on and off week schedule
    ceiling_fan_sch = create_cooling_and_fan_schedule(model, os_start_date, os_end_date, os_start_time, os_end_time, diversity_factor)

    # add ceiling fan electric equipment object
    ceiling_fan_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    ceiling_fan_def.setName("Ceiling fan def")
    ceiling_fan_def.setWattsperSpaceFloorArea(watts_per_m2)
    ceiling_fan_def.setFractionLatent(0.0)
    ceiling_fan_def.setFractionRadiant(0.0)
    ceiling_fan_def.setFractionLost(0.0)  # all convective heat gain

    # create people air velocity schedule
    air_velo_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    air_velo_sch.setName('Air Velocity Schedule')
    air_velo_sch.defaultDaySchedule.setName('Air Velocity Schedule Default')
    air_velo_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), people_air_velocity)

    ceiling_fan_count = 0 # init

    # add ceiling fan to occupied spaces
    # don't need to loop through space types as thermostat is attached to thermalZone only, which is connected to space
    model.getSpaces.each do |space|
      # only add to occupied zones
      unless space.numberOfPeople > 0
        runner.registerWarning("Skip adding ceiling fan to #{space.name.to_s} because it is not occupied.")
        next
      end

      # only add to space => thermal zone that has cooling setpoint assigned
      if space.thermalZone.empty?
        runner.registerWarning("Skip adding ceiling fan to #{space.name.to_s} because it is not associated with a thermal zone.")
        next
      end

      thermal_zone = space.thermalZone.get
      if thermal_zone.thermostatSetpointDualSetpoint.empty?
        runner.registerWarning("Skip adding ceiling fan to #{space.name.to_s} because it doesn't have thermostat assigned.")
        next
      end

      thermostat = thermal_zone.thermostatSetpointDualSetpoint.get
      # setup new cooling setpoint schedule
      clg_set_sch = thermostat.coolingSetpointTemperatureSchedule
      if clg_set_sch.empty?
        runner.registerWarning("Skip adding ceiling fan to #{space.name.to_s} because its thermostat doesn't have cooling setpoint schedule assigned.")
        next
      end

      runner.registerInfo("adjusting schedule #{clg_set_sch.get.name.to_s}")
      new_sch = adjust_cool_sch(model, clg_set_sch, cool_stp_increase_C, os_start_date, os_end_date, os_start_time, os_end_time)

      # hook up clone to thermostat
      thermostat.setCoolingSetpointTemperatureSchedule(new_sch)

      # add ceiling fan electric equipment
      ceiling_fan = OpenStudio::Model::ElectricEquipment.new(ceiling_fan_def)
      ceiling_fan.setName("#{space.name.to_s} ceiling fan")
      ceiling_fan.setSchedule(ceiling_fan_sch)
      ceiling_fan.setSpace(space)

      # assign people air velocity schedule
      space.people.each do |people_inst|
        people_inst.setAirVelocitySchedule(air_velo_sch)
      end

      ceiling_fan_count += 1
    end

    # echo the new space's name back to the user
    runner.registerInfo("#{ceiling_fan_count} ceiling fans were added to occupied conditioned spaces with #{watts_per_m2}w/m2.")

    # report final condition of model
    runner.registerFinalCondition("Ceiling fans were added to the building.")

    return true
  end
end

# register the measure to be used by the application
AddCeilingFan.new.registerWithApplication
