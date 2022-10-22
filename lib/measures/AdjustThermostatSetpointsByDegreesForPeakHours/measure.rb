# start the measure
class AdjustThermostatSetpointsByDegreesForPeakHours < OpenStudio::Measure::ModelMeasure
  # setup OpenStudio units that we will need
  TEMP_IP_UNIT = OpenStudio.createUnit('F').get
  TEMP_SI_UNIT = OpenStudio.createUnit('C').get
  
  # define the name that a user will see
  def name
    return 'Adjust thermostat setpoint by degrees for peak hours'
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
    cooling_adjustment.setDefaultValue(2.0)
    args << cooling_adjustment

    # make an argument for the start time of cooling adjustment
    cooling_daily_starttime = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_daily_starttime', false)
    cooling_daily_starttime.setDisplayName('Daily Start Time for Cooling Adjustment')
    cooling_daily_starttime.setDescription('Use 24 hour format HH:MM:SS')
    cooling_daily_starttime.setDefaultValue('16:01:00')
    args << cooling_daily_starttime

    # make an argument for the end time of cooling adjustment
    cooling_daily_endtime = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_daily_endtime', false)
    cooling_daily_endtime.setDisplayName('Daily End Time for Cooling Adjustment')
    cooling_daily_endtime.setDescription('Use 24 hour format HH:MM:SS')
    cooling_daily_endtime.setDefaultValue('20:00:00')
    args << cooling_daily_endtime

    # make an argument for the start date of cooling adjustment
    cooling_startdate = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_startdate', false)
    cooling_startdate.setDisplayName('Start Date for Cooling Adjustment')
    cooling_startdate.setDescription('In MM-DD format')
    cooling_startdate.setDefaultValue('06-01')
    args << cooling_startdate

    # make an argument for the end date of cooling adjustment
    cooling_enddate = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_enddate', false)
    cooling_enddate.setDisplayName('End Date for Cooling Adjustment')
    cooling_enddate.setDescription('In MM-DD format')
    cooling_enddate.setDefaultValue('09-30')
    args << cooling_enddate

    # make an argument for adjustment to heating setpoint
    heating_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_adjustment', true)
    heating_adjustment.setDisplayName('Degrees Fahrenheit to Adjust heating Setpoint By')
    heating_adjustment.setDefaultValue(-2.0)
    args << heating_adjustment

    # make an argument for the start time of heating adjustment
    heating_daily_starttime = OpenStudio::Measure::OSArgument.makeStringArgument('heating_daily_starttime', false)
    heating_daily_starttime.setDisplayName('Start Time for Heating Adjustment')
    heating_daily_starttime.setDescription('Use 24 hour format HH:MM:SS')
    heating_daily_starttime.setDefaultValue('18:01:00')
    args << heating_daily_starttime

    # make an argument for the end time of heating adjustment
    heating_daily_endtime = OpenStudio::Measure::OSArgument.makeStringArgument('heating_daily_endtime', false)
    heating_daily_endtime.setDisplayName('End Time for Heating Adjustment')
    heating_daily_endtime.setDescription('Use 24 hour format HH:MM:SS')
    heating_daily_endtime.setDefaultValue('22:00:00')
    args << heating_daily_endtime

    # make an argument for the first start date of heating adjustment
    heating_startdate_1 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_startdate_1', false)
    heating_startdate_1.setDisplayName('Start Date for Heating Adjustment Period 1')
    heating_startdate_1.setDescription('In MM-DD format')
    heating_startdate_1.setDefaultValue('01-01')
    args << heating_startdate_1

    # make an argument for the first end date of heating adjustment
    heating_enddate_1 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_enddate_1', false)
    heating_enddate_1.setDisplayName('End Date for Heating Adjustment Period 1')
    heating_enddate_1.setDescription('In MM-DD format')
    heating_enddate_1.setDefaultValue('05-31')
    args << heating_enddate_1

    # make an argument for the second start date of heating adjustment
    heating_startdate_2 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_startdate_2', false)
    heating_startdate_2.setDisplayName('Start Date for Heating Adjustment Period 2')
    heating_startdate_2.setDescription('In MM-DD format')
    heating_startdate_2.setDefaultValue('10-01')
    args << heating_startdate_2

    # make an argument for the second end date of heating adjustment
    heating_enddate_2 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_enddate_2', false)
    heating_enddate_2.setDisplayName('End Date for Heating Adjustment Period 2')
    heating_enddate_2.setDescription('In MM-DD format')
    heating_enddate_2.setDefaultValue('12-31')
    args << heating_enddate_2

    # make an argument if the thermostat for design days should be altered
    alter_design_days = OpenStudio::Measure::OSArgument.makeBoolArgument('alter_design_days', false)
    alter_design_days.setDisplayName('Alter Design Day Thermostats')
    alter_design_days.setDefaultValue(false)
    args << alter_design_days

    auto_date = OpenStudio::Measure::OSArgument.makeBoolArgument('auto_date', false)
    auto_date.setDisplayName('Enable Climate-specific Periods Setting?')
    auto_date.setDefaultValue(false)
    args << auto_date

    alt_periods = OpenStudio::Measure::OSArgument.makeBoolArgument('alt_periods', false)
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
    cooling_daily_starttime = runner.getStringArgumentValue('cooling_daily_starttime', user_arguments)
    cooling_daily_endtime = runner.getStringArgumentValue('cooling_daily_endtime', user_arguments)
    cooling_startdate = runner.getStringArgumentValue('cooling_startdate', user_arguments)
    cooling_enddate = runner.getStringArgumentValue('cooling_enddate', user_arguments)
    heating_daily_starttime = runner.getStringArgumentValue('heating_daily_starttime', user_arguments)
    heating_daily_endtime = runner.getStringArgumentValue('heating_daily_endtime', user_arguments)
    heating_startdate_1 = runner.getStringArgumentValue('heating_startdate_1', user_arguments)
    heating_enddate_1 = runner.getStringArgumentValue('heating_enddate_1', user_arguments)
    heating_startdate_2 = runner.getStringArgumentValue('heating_startdate_2', user_arguments)
    heating_enddate_2 = runner.getStringArgumentValue('heating_enddate_2', user_arguments)
    alter_design_days = runner.getBoolArgumentValue('alter_design_days', user_arguments)   # not used yet
    auto_date = runner.getBoolArgumentValue('auto_date', user_arguments)
    alt_periods = runner.getBoolArgumentValue('alt_periods', user_arguments)

    cooling_start_month = nil
    cooling_start_day = nil
    md = /(\d\d)-(\d\d)/.match(cooling_startdate)
    if md
      cooling_start_month = md[1].to_i
      cooling_start_day = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    cooling_end_month = nil
    cooling_end_day = nil
    md = /(\d\d)-(\d\d)/.match(cooling_enddate)
    if md
      cooling_end_month = md[1].to_i
      cooling_end_day = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end
    heating_start_month_1 = nil
    heating_start_day_1 = nil
    md = /(\d\d)-(\d\d)/.match(heating_startdate_1)
    if md
      heating_start_month_1 = md[1].to_i
      heating_start_day_1 = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    heating_end_month_1 = nil
    heating_end_day_1 = nil
    md = /(\d\d)-(\d\d)/.match(heating_enddate_1)
    if md
      heating_end_month_1 = md[1].to_i
      heating_end_day_1 = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    heating_start_month_2 = nil
    heating_start_day_2 = nil
    md = /(\d\d)-(\d\d)/.match(heating_startdate_2)
    if md
      heating_start_month_2 = md[1].to_i
      heating_start_day_2 = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    heating_end_month_2 = nil
    heating_end_day_2 = nil
    md = /(\d\d)-(\d\d)/.match(heating_enddate_1)
    if md
      heating_end_month_2 = md[1].to_i
      heating_end_day_2 = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end

    summerStartDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(cooling_start_month), cooling_start_day)
    summerEndDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(cooling_end_month), cooling_end_day)
    winterStartDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_start_month_1), heating_end_day_1)
    winterEndDate1 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_end_month_1), heating_end_day_1)
    winterStartDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_start_month_2), heating_end_day_2)
    winterEndDate2 = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(heating_end_month_2), heating_end_day_2)

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
          cooling_daily_starttime = '18:01:00'
          cooling_daily_endtime = '21:59:00'
          heating_daily_starttime = '17:01:00'
          heating_daily_endtime = '20:59:00'
        when '5A'
          cooling_daily_starttime = '14:01:00'
          cooling_daily_endtime = '17:59:00'
          heating_daily_starttime = '18:01:00'
          heating_daily_endtime = '21:59:00'
        when '6A'
          cooling_daily_starttime = '13:01:00'
          cooling_daily_endtime = '16:59:00'
          heating_daily_starttime = '17:01:00'
          heating_daily_endtime = '20:59:00'
        end
      else
        case ashraeClimateZone
        when '2A', '2B', '4B', '4C', '5B', '5C', '6B'
          cooling_daily_starttime = '17:01:00'
          cooling_daily_endtime = '20:59:00'
          heating_daily_starttime = '17:01:00'
          heating_daily_endtime = '20:59:00'
        when '3A', '3C'
          cooling_daily_starttime = '19:01:00'
          cooling_daily_endtime = '22:59:00'
          heating_daily_starttime = '17:01:00'
          heating_daily_endtime = '20:59:00'
        when '3B'
          cooling_daily_starttime = '18:01:00'
          cooling_daily_endtime = '21:59:00'
          heating_daily_starttime = '19:01:00'
          heating_daily_endtime = '22:59:00'
        when '4A'
          cooling_daily_starttime = '12:01:00'
          cooling_daily_endtime = '15:59:00'
          heating_daily_starttime = '16:01:00'
          heating_daily_endtime = '19:59:00'
        when '5A'
          cooling_daily_starttime = '20:01:00'
          cooling_daily_endtime = '23:59:00'
          heating_daily_starttime = '17:01:00'
          heating_daily_endtime = '20:59:00'
        when '6A', '7A'
          cooling_daily_starttime = '16:01:00'
          cooling_daily_endtime = '19:59:00'
          heating_daily_starttime = '18:01:00'
          heating_daily_endtime = '21:59:00'
        end
      end
    end

    if cooling_daily_starttime.to_f > cooling_daily_endtime.to_f
      runner.registerError('For cooling adjustment, the end time should be larger than the start time.')
      return false
    end
    if heating_daily_starttime.to_f > heating_daily_endtime.to_f
      runner.registerError('For heating adjustment, the end time should be larger than the start time.')
      return false
    end

    # ruby test to see if first charter of string is uppercase letter
    if cooling_adjustment < 0
      runner.registerError('Lowering the cooling setpoint will increase energy use. Please double check your input.')
    elsif cooling_adjustment.abs > 500
      runner.registerError("#{cooling_adjustment} is a larger than typical setpoint adjustment. Please double check your input.")
      return false
    elsif cooling_adjustment.abs > 50
      runner.registerWarning("#{cooling_adjustment} is a larger than typical setpoint adjustment. Please double check your input.")
    end
    if heating_adjustment > 0
      runner.registerError('Raising the heating setpoint will increase energy use. Please double check your input.')
    elsif heating_adjustment.abs > 500
      runner.registerError("#{heating_adjustment} is a larger than typical setpoint adjustment. Please double check your input.")
      return false
    elsif heating_adjustment.abs > 50
      runner.registerWarning("#{heating_adjustment} is a larger than typical setpoint adjustment. Please double check your input.")
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
        # clone of not already in hash
        if clg_set_schs.key?(clg_set_sch.get.name.to_s)
          new_clg_set_sch = clg_set_schs[clg_set_sch.get.name.to_s]
        else
          new_clg_set_sch = clg_set_sch.get.clone(model)
          new_clg_set_sch = new_clg_set_sch.to_Schedule.get
          new_clg_set_sch.setName("#{clg_set_sch.get.name.to_s} adjusted by #{cooling_adjustment_ip}F")

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
          new_htg_set_sch.setName("#{htg_set_sch.get.name.to_s} adjusted by #{heating_adjustment_ip}")

          # add to the hash
          htg_set_schs[htg_set_sch.get.name.to_s] = new_htg_set_sch
        end
        # hook up clone to thermostat
        thermostat.setHeatingSetpointTemperatureSchedule(new_htg_set_sch)
      else
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a heating setpoint schedule.")
      end
    end

    puts "clg_set_schs: #{clg_set_schs.inspect}"
    puts "htg_set_schs: #{htg_set_schs.inspect}"

    # setting up variables to use for initial and final condition
    clg_sch_set_values = [] # may need to flatten this
    htg_sch_set_values = [] # may need to flatten this
    final_clg_sch_set_values = []
    final_htg_sch_set_values = []

    # consider issuing a warning if the model has un-conditioned thermal zones (no ideal air loads or hvac)
    zones = model.getThermalZones
    zones.each do |zone|
      # if you have a thermostat but don't have ideal air loads or zone equipment then issue a warning
      if !zone.thermostatSetpointDualSetpoint.empty? && !zone.useIdealAirLoads && (zone.equipment.size == 0)
        runner.registerWarning("Thermal zone '#{zone.name}' has a thermostat but does not appear to be conditioned.")
      end
    end
    shift_time_cooling_start = OpenStudio::Time.new(cooling_daily_starttime)
    shift_time_cooling_end = OpenStudio::Time.new(cooling_daily_endtime)
    shift_time3 = OpenStudio::Time.new(0, 24, 0, 0)    # not used
    shift_time_heating_start = OpenStudio::Time.new(heating_daily_starttime)
    shift_time_heating_end = OpenStudio::Time.new(heating_daily_endtime)

    # daylightsaving adjustment added in visualization, so deprecated here
    # # Check model's daylight saving period, if cooling period is within daylight saving period, shift the cooling start time and end time by one hour later
    # if model.getObjectsByType('OS:RunPeriodControl:DaylightSavingTime'.to_IddObjectType).size >= 1
    #   runperiodctrl_daylgtsaving = model.getRunPeriodControlDaylightSavingTime
    #   daylight_saving_startdate = runperiodctrl_daylgtsaving.startDate
    #   daylight_saving_enddate = runperiodctrl_daylgtsaving.endDate
    #   if summerStartDate >= OpenStudio::Date.new(daylight_saving_startdate.monthOfYear, daylight_saving_startdate.dayOfMonth, summerStartDate.year) && summerEndDate <= OpenStudio::Date.new(daylight_saving_enddate.monthOfYear, daylight_saving_enddate.dayOfMonth, summerStartDate.year)
    #     shift_time_cooling_start += OpenStudio::Time.new(0,1,0,0)
    #     shift_time_cooling_end += OpenStudio::Time.new(0,1,0,0)
    #   end
    # end

    # make cooling schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
    clg_set_schs.each do |sch_name, os_sch| # old name and new object for schedule
      if !os_sch.to_ScheduleRuleset.empty?
        schedule = os_sch.to_ScheduleRuleset.get
        default_rule = schedule.defaultDaySchedule
        rules = schedule.scheduleRules
        days_covered = Array.new(7, false)

        # TODO: when ruleset has multiple rules for each month or couple of months instead of a full year, should first see if the period overlaps with summer/winter
        if rules.length > 0
          rules.each do |rule|
            winter_rule1 = copy_sch_rule_for_period(model, rule, rule.daySchedule, winterStartDate1, winterEndDate1)
            winter_rule2 = copy_sch_rule_for_period(model, rule, rule.daySchedule, winterStartDate2, winterEndDate2)

            summer_rule = rule
            checkDaysCovered(summer_rule, days_covered)
            summer_rule.setStartDate(summerStartDate)
            summer_rule.setEndDate(summerEndDate)

            summer_day = summer_rule.daySchedule
            day_time_vector = summer_day.times
            day_value_vector = summer_day.values
            clg_sch_set_values << summer_day.values   # original
            summer_day.clearValues

            summer_day = updateDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time_cooling_start, shift_time_cooling_end, cooling_adjustment_ip)
            final_clg_sch_set_values << summer_day.values   # new
          end
        else
          runner.registerWarning("Cooling setpoint schedule '#{sch_name}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
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

          summer_day = updateDaySchedule(summer_day, day_time_vector, day_value_vector, shift_time_cooling_start, shift_time_cooling_end, cooling_adjustment_ip)
          clg_sch_set_values << default_rule.values   # original
          final_clg_sch_set_values << summer_day.values  # new
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
            summer_rule = copy_sch_rule_for_period(model, rule, rule.daySchedule, summerStartDate, summerEndDate)

            checkDaysCovered(summer_rule, days_covered)

            winter_rule1 = rule
            winter_rule1.setStartDate(winterStartDate1)
            winter_rule1.setEndDate(winterEndDate1)
            htg_sch_set_values << rule.daySchedule.values   # original

            winter_day1 = winter_rule1.daySchedule
            day_time_vector = winter_day1.times
            day_value_vector = winter_day1.values
            winter_day1.clearValues

            winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time_heating_start, shift_time_heating_end, heating_adjustment_ip)
            final_htg_sch_set_values << winter_day1.values   # new

            winter_rule2 = copy_sch_rule_for_period(model, winter_rule1, winter_rule1.daySchedule, winterStartDate2, winterEndDate2)
          end
        else
          runner.registerWarning("Cooling setpoint schedule '#{sch_name}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
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

          winter_day1 = updateDaySchedule(winter_day1, day_time_vector, day_value_vector, shift_time_heating_start, shift_time_heating_end, heating_adjustment_ip)

          htg_sch_set_values << default_rule.values   # original
          final_htg_sch_set_values << winter_day1.values   # new

          winter_rule2 = copy_sch_rule_for_period(model, winter_rule1, winter_rule1.daySchedule, winterStartDate2, winterEndDate2)
        end

      else
        runner.registerWarning("Schedule '#{sch_name}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        os_sch.remove # remove un-used clone
      end
    end

    # get min and max heating and cooling and convert to IP
    clg_sch_set_values = clg_sch_set_values.flatten
    htg_sch_set_values = htg_sch_set_values.flatten

    puts "clg_sch_set_values: #{clg_sch_set_values.inspect}"
    puts "htg_sch_set_values: #{htg_sch_set_values.inspect}"

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

    puts "final_clg_sch_set_values: #{final_clg_sch_set_values.inspect}"
    puts "final_htg_sch_set_values: #{final_htg_sch_set_values.inspect}"

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
    runner.registerFinalCondition("Final cooling setpoints used in the model range from #{final_min_clg_ip} to #{final_max_clg_ip}. Final heating setpoints used in the model range from #{final_min_htg_ip} to #{final_max_htg_ip}.\n The cooling setpoints are increased by #{cooling_adjustment}F，from #{cooling_daily_starttime} to #{cooling_daily_endtime}. \n The heating setpoints are decreased by #{0-heating_adjustment}F，from #{heating_daily_starttime} to #{heating_daily_endtime}.")

    return true
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


  # TODO check if this function works
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
        sch_day.addValue(time_end, target_temp_si.value)
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
end



# this allows the measure to be used by the application
AdjustThermostatSetpointsByDegreesForPeakHours.new.registerWithApplication
