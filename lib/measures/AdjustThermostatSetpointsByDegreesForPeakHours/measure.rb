# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
require 'json'
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

    # make an argument for adjustment to heating setpoint
    heating_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_adjustment', true)
    heating_adjustment.setDisplayName('Degrees Fahrenheit to Adjust heating Setpoint By')
    heating_adjustment.setDefaultValue(-2.0)
    args << heating_adjustment

    heating_start_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_start_date1', true)
    heating_start_date1.setDisplayName('First start date for heating setpoint adjustment')
    heating_start_date1.setDescription('In MM-DD format')
    heating_start_date1.setDefaultValue('01-01')
    args << heating_start_date1
    heating_end_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_end_date1', true)
    heating_end_date1.setDisplayName('First end date for heating setpoint adjustment')
    heating_end_date1.setDescription('In MM-DD format')
    heating_end_date1.setDefaultValue('03-31')
    args << heating_end_date1

    heating_start_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_start_date2', false)
    heating_start_date2.setDisplayName('Second start date for heating setpoint adjustment (optional)')
    heating_start_date2.setDescription('Specify a date in MM-DD format if you want a second season of heating setpoint adjustment; leave blank if not needed.')
    heating_start_date2.setDefaultValue('')
    args << heating_start_date2
    heating_end_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_end_date2', false)
    heating_end_date2.setDisplayName('Second end date for heating setpoint adjustment')
    heating_end_date2.setDescription('Specify a date in MM-DD format if you want a second season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    heating_end_date2.setDefaultValue('')
    args << heating_end_date2

    heating_start_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_start_date3', false)
    heating_start_date3.setDisplayName('Third start date for heating setpoint adjustment (optional)')
    heating_start_date3.setDescription('Specify a date in MM-DD format if you want a third season of heating setpoint adjustment; leave blank if not needed.')
    heating_start_date3.setDefaultValue('')
    args << heating_start_date3
    heating_end_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_end_date3', false)
    heating_end_date3.setDisplayName('Third end date for heating setpoint adjustment')
    heating_end_date3.setDescription('Specify a date in MM-DD format if you want a third season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    heating_end_date3.setDefaultValue('')
    args << heating_end_date3

    heating_start_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_start_date4', false)
    heating_start_date4.setDisplayName('Fourth start date for heating setpoint adjustment (optional)')
    heating_start_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of heating setpoint adjustment; leave blank if not needed.')
    heating_start_date4.setDefaultValue('')
    args << heating_start_date4
    heating_end_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_end_date4', false)
    heating_end_date4.setDisplayName('Fourth end date for heating setpoint adjustment')
    heating_end_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    heating_end_date4.setDefaultValue('')
    args << heating_end_date4

    heating_start_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_start_date5', false)
    heating_start_date5.setDisplayName('Fifth start date for heating setpoint adjustment (optional)')
    heating_start_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of heating setpoint adjustment; leave blank if not needed.')
    heating_start_date5.setDefaultValue('')
    args << heating_start_date5
    heating_end_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('heating_end_date5', false)
    heating_end_date5.setDisplayName('Fifth end date for heating setpoint adjustment')
    heating_end_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    heating_end_date5.setDefaultValue('')
    args << heating_end_date5

    heating_start_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_start_time1', true)
    heating_start_time1.setDisplayName('Start time of heating setpoint adjustment for the first season')
    heating_start_time1.setDescription('In HH:MM:SS format')
    heating_start_time1.setDefaultValue('17:00:00')
    args << heating_start_time1
    heating_end_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_end_time1', true)
    heating_end_time1.setDisplayName('End time of heating setpoint adjustment for the first season')
    heating_end_time1.setDescription('In HH:MM:SS format')
    heating_end_time1.setDefaultValue('21:00:00')
    args << heating_end_time1

    heating_start_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_start_time2', false)
    heating_start_time2.setDisplayName('Start time of heating setpoint adjustment for the second season (optional)')
    heating_start_time2.setDescription('In HH:MM:SS format')
    heating_start_time2.setDefaultValue('')
    args << heating_start_time2
    heating_end_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_end_time2', false)
    heating_end_time2.setDisplayName('End time of heating setpoint adjustment for the second season (optional)')
    heating_end_time2.setDescription('In HH:MM:SS format')
    heating_end_time2.setDefaultValue('')
    args << heating_end_time2

    heating_start_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_start_time3', false)
    heating_start_time3.setDisplayName('Start time of heating setpoint adjustment for the third season (optional)')
    heating_start_time3.setDescription('In HH:MM:SS format')
    heating_start_time3.setDefaultValue('')
    args << heating_start_time3
    heating_end_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_end_time3', false)
    heating_end_time3.setDisplayName('End time of heating setpoint adjustment for the third season (optional)')
    heating_end_time3.setDescription('In HH:MM:SS format')
    heating_end_time3.setDefaultValue('')
    args << heating_end_time3

    heating_start_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_start_time4', false)
    heating_start_time4.setDisplayName('Start time of heating setpoint adjustment for the fourth season (optional)')
    heating_start_time4.setDescription('In HH:MM:SS format')
    heating_start_time4.setDefaultValue('')
    args << heating_start_time4
    heating_end_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_end_time4', false)
    heating_end_time4.setDisplayName('End time of heating setpoint adjustment for the fourth season (optional)')
    heating_end_time4.setDescription('In HH:MM:SS format')
    heating_end_time4.setDefaultValue('')
    args << heating_end_time4

    heating_start_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_start_time5', false)
    heating_start_time5.setDisplayName('Start time of heating setpoint adjustment for the fifth season (optional)')
    heating_start_time5.setDescription('In HH:MM:SS format')
    heating_start_time5.setDefaultValue('')
    args << heating_start_time5
    heating_end_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('heating_end_time5', false)
    heating_end_time5.setDisplayName('End time of heating setpoint adjustment for the fifth season (optional)')
    heating_end_time5.setDescription('In HH:MM:SS format')
    heating_end_time5.setDefaultValue('')
    args << heating_end_time5


    # make an argument for adjustment to cooling setpoint
    cooling_adjustment = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_adjustment', true)
    cooling_adjustment.setDisplayName('Degrees Fahrenheit to Adjust Cooling Setpoint By')
    cooling_adjustment.setDefaultValue(5.0)
    args << cooling_adjustment

    cooling_start_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_start_date1', true)
    cooling_start_date1.setDisplayName('First start date for cooling setpoint adjustment')
    cooling_start_date1.setDescription('In MM-DD format')
    cooling_start_date1.setDefaultValue('06-01')
    args << cooling_start_date1
    cooling_end_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_end_date1', true)
    cooling_end_date1.setDisplayName('First end date for cooling setpoint adjustment')
    cooling_end_date1.setDescription('In MM-DD format')
    cooling_end_date1.setDefaultValue('09-30')
    args << cooling_end_date1

    cooling_start_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_start_date2', false)
    cooling_start_date2.setDisplayName('Second start date for cooling setpoint adjustment (optional)')
    cooling_start_date2.setDescription('Specify a date in MM-DD format if you want a second season of cooling setpoint adjustment; leave blank if not needed.')
    cooling_start_date2.setDefaultValue('')
    args << cooling_start_date2
    cooling_end_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_end_date2', false)
    cooling_end_date2.setDisplayName('Second end date for cooling setpoint adjustment')
    cooling_end_date2.setDescription('Specify a date in MM-DD format if you want a second season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    cooling_end_date2.setDefaultValue('')
    args << cooling_end_date2

    cooling_start_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_start_date3', false)
    cooling_start_date3.setDisplayName('Third start date for cooling setpoint adjustment (optional)')
    cooling_start_date3.setDescription('Specify a date in MM-DD format if you want a third season of cooling setpoint adjustment; leave blank if not needed.')
    cooling_start_date3.setDefaultValue('')
    args << cooling_start_date3
    cooling_end_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_end_date3', false)
    cooling_end_date3.setDisplayName('Third end date for cooling setpoint adjustment')
    cooling_end_date3.setDescription('Specify a date in MM-DD format if you want a third season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    cooling_end_date3.setDefaultValue('')
    args << cooling_end_date3

    cooling_start_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_start_date4', false)
    cooling_start_date4.setDisplayName('Fourth start date for cooling setpoint adjustment (optional)')
    cooling_start_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of cooling setpoint adjustment; leave blank if not needed.')
    cooling_start_date4.setDefaultValue('')
    args << cooling_start_date4
    cooling_end_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_end_date4', false)
    cooling_end_date4.setDisplayName('Fourth end date for cooling setpoint adjustment')
    cooling_end_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    cooling_end_date4.setDefaultValue('')
    args << cooling_end_date4

    cooling_start_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_start_date5', false)
    cooling_start_date5.setDisplayName('Fifth start date for cooling setpoint adjustment (optional)')
    cooling_start_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of cooling setpoint adjustment; leave blank if not needed.')
    cooling_start_date5.setDefaultValue('')
    args << cooling_start_date5
    cooling_end_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('cooling_end_date5', false)
    cooling_end_date5.setDisplayName('Fifth end date for cooling setpoint adjustment')
    cooling_end_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    cooling_end_date5.setDefaultValue('')
    args << cooling_end_date5

    cooling_start_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_start_time1', true)
    cooling_start_time1.setDisplayName('Start time of cooling setpoint adjustment for the first season')
    cooling_start_time1.setDescription('In HH:MM:SS format')
    cooling_start_time1.setDefaultValue('17:00:00')
    args << cooling_start_time1
    cooling_end_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_end_time1', true)
    cooling_end_time1.setDisplayName('End time of cooling setpoint adjustment for the first season')
    cooling_end_time1.setDescription('In HH:MM:SS format')
    cooling_end_time1.setDefaultValue('21:00:00')
    args << cooling_end_time1

    cooling_start_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_start_time2', false)
    cooling_start_time2.setDisplayName('Start time of cooling setpoint adjustment for the second season (optional)')
    cooling_start_time2.setDescription('In HH:MM:SS format')
    cooling_start_time2.setDefaultValue('')
    args << cooling_start_time2
    cooling_end_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_end_time2', false)
    cooling_end_time2.setDisplayName('End time of cooling setpoint adjustment for the second season (optional)')
    cooling_end_time2.setDescription('In HH:MM:SS format')
    cooling_end_time2.setDefaultValue('')
    args << cooling_end_time2

    cooling_start_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_start_time3', false)
    cooling_start_time3.setDisplayName('Start time of cooling setpoint adjustment for the third season (optional)')
    cooling_start_time3.setDescription('In HH:MM:SS format')
    cooling_start_time3.setDefaultValue('')
    args << cooling_start_time3
    cooling_end_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_end_time3', false)
    cooling_end_time3.setDisplayName('End time of cooling setpoint adjustment for the third season (optional)')
    cooling_end_time3.setDescription('In HH:MM:SS format')
    cooling_end_time3.setDefaultValue('')
    args << cooling_end_time3

    cooling_start_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_start_time4', false)
    cooling_start_time4.setDisplayName('Start time of cooling setpoint adjustment for the fourth season (optional)')
    cooling_start_time4.setDescription('In HH:MM:SS format')
    cooling_start_time4.setDefaultValue('')
    args << cooling_start_time4
    cooling_end_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_end_time4', false)
    cooling_end_time4.setDisplayName('End time of cooling setpoint adjustment for the fourth season (optional)')
    cooling_end_time4.setDescription('In HH:MM:SS format')
    cooling_end_time4.setDefaultValue('')
    args << cooling_end_time4

    cooling_start_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_start_time5', false)
    cooling_start_time5.setDisplayName('Start time of cooling setpoint adjustment for the fifth season (optional)')
    cooling_start_time5.setDescription('In HH:MM:SS format')
    cooling_start_time5.setDefaultValue('')
    args << cooling_start_time5
    cooling_end_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('cooling_end_time5', false)
    cooling_end_time5.setDisplayName('End time of cooling setpoint adjustment for the fifth season (optional)')
    cooling_end_time5.setDescription('In HH:MM:SS format')
    cooling_end_time5.setDefaultValue('')
    args << cooling_end_time5


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
    cooling_adjustment = runner.getDoubleArgumentValue('cooling_adjustment', user_arguments)
    heating_start_time1 = runner.getStringArgumentValue('heating_start_time1', user_arguments)
    heating_end_time1 = runner.getStringArgumentValue('heating_end_time1', user_arguments)
    heating_start_time2 = runner.getStringArgumentValue('heating_start_time2', user_arguments)
    heating_end_time2 = runner.getStringArgumentValue('heating_end_time2', user_arguments)
    heating_start_time3 = runner.getStringArgumentValue('heating_start_time3', user_arguments)
    heating_end_time3 = runner.getStringArgumentValue('heating_end_time3', user_arguments)
    heating_start_time4 = runner.getStringArgumentValue('heating_start_time4', user_arguments)
    heating_end_time4 = runner.getStringArgumentValue('heating_end_time4', user_arguments)
    heating_start_time5 = runner.getStringArgumentValue('heating_start_time5', user_arguments)
    heating_end_time5 = runner.getStringArgumentValue('heating_end_time5', user_arguments)
    heating_start_date1 = runner.getStringArgumentValue('heating_start_date1', user_arguments)
    heating_end_date1 = runner.getStringArgumentValue('heating_end_date1', user_arguments)
    heating_start_date2 = runner.getStringArgumentValue('heating_start_date2', user_arguments)
    heating_end_date2 = runner.getStringArgumentValue('heating_end_date2', user_arguments)
    heating_start_date3 = runner.getStringArgumentValue('heating_start_date3', user_arguments)
    heating_end_date3 = runner.getStringArgumentValue('heating_end_date3', user_arguments)
    heating_start_date4 = runner.getStringArgumentValue('heating_start_date4', user_arguments)
    heating_end_date4 = runner.getStringArgumentValue('heating_end_date4', user_arguments)
    heating_start_date5 = runner.getStringArgumentValue('heating_start_date5', user_arguments)
    heating_end_date5 = runner.getStringArgumentValue('heating_end_date5', user_arguments)
    cooling_start_time1 = runner.getStringArgumentValue('cooling_start_time1', user_arguments)
    cooling_end_time1 = runner.getStringArgumentValue('cooling_end_time1', user_arguments)
    cooling_start_time2 = runner.getStringArgumentValue('cooling_start_time2', user_arguments)
    cooling_end_time2 = runner.getStringArgumentValue('cooling_end_time2', user_arguments)
    cooling_start_time3 = runner.getStringArgumentValue('cooling_start_time3', user_arguments)
    cooling_end_time3 = runner.getStringArgumentValue('cooling_end_time3', user_arguments)
    cooling_start_time4 = runner.getStringArgumentValue('cooling_start_time4', user_arguments)
    cooling_end_time4 = runner.getStringArgumentValue('cooling_end_time4', user_arguments)
    cooling_start_time5 = runner.getStringArgumentValue('cooling_start_time5', user_arguments)
    cooling_end_time5 = runner.getStringArgumentValue('cooling_end_time5', user_arguments)
    cooling_start_date1 = runner.getStringArgumentValue('cooling_start_date1', user_arguments)
    cooling_end_date1 = runner.getStringArgumentValue('cooling_end_date1', user_arguments)
    cooling_start_date2 = runner.getStringArgumentValue('cooling_start_date2', user_arguments)
    cooling_end_date2 = runner.getStringArgumentValue('cooling_end_date2', user_arguments)
    cooling_start_date3 = runner.getStringArgumentValue('cooling_start_date3', user_arguments)
    cooling_end_date3 = runner.getStringArgumentValue('cooling_end_date3', user_arguments)
    cooling_start_date4 = runner.getStringArgumentValue('cooling_start_date4', user_arguments)
    cooling_end_date4 = runner.getStringArgumentValue('cooling_end_date4', user_arguments)
    cooling_start_date5 = runner.getStringArgumentValue('cooling_start_date5', user_arguments)
    cooling_end_date5 = runner.getStringArgumentValue('cooling_end_date5', user_arguments)
    alt_periods = runner.getBoolArgumentValue('alt_periods', user_arguments)


    # set the default start and end time based on state
    if alt_periods
      state = model.getWeatherFile.stateProvinceRegion
      file = File.open(File.join(File.dirname(__FILE__), "../../../files/seasonal_shedding_peak_hours.json"))
      default_peak_periods = JSON.load(file)
      file.close
      peak_periods = default_peak_periods[state]
      cooling_start_time1 = heating_start_time1 = peak_periods["winter_peak_start"].split[1]
      cooling_end_time1 = heating_end_time1 = peak_periods["winter_peak_end"].split[1]
      cooling_start_time2 = heating_start_time2 = peak_periods["intermediate_peak_start"].split[1]
      cooling_end_time2 = heating_end_time2 = peak_periods["intermediate_peak_end"].split[1]
      cooling_start_time3 = heating_start_time3 = peak_periods["summer_peak_start"].split[1]
      cooling_end_time3 = heating_end_time3 = peak_periods["summer_peak_end"].split[1]
      cooling_start_time4 = heating_start_time4 = peak_periods["intermediate_peak_start"].split[1]
      cooling_end_time4 = heating_end_time4 = peak_periods["intermediate_peak_end"].split[1]
      cooling_start_time5 = heating_start_time5 = peak_periods["winter_peak_start"].split[1]
      cooling_end_time5 = heating_end_time5 = peak_periods["winter_peak_end"].split[1]
      cooling_start_date1 = heating_start_date1 = '01-01'
      cooling_end_date1 = heating_end_date1 = '03-31'
      cooling_start_date2 = heating_start_date2 = '04-01'
      cooling_end_date2 = heating_end_date2 = '05-31'
      cooling_start_date3 = heating_start_date3 = '06-01'
      cooling_end_date3 = heating_end_date3 = '09-30'
      cooling_start_date4 = heating_start_date4 = '10-01'
      cooling_end_date4 = heating_end_date4 = '11-30'
      cooling_start_date5 = heating_start_date5 = '12-01'
      cooling_end_date5 = heating_end_date5 = '12-31'
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
          os_start_date = model.getYearDescription.makeDate(start_month, start_day)
          os_end_date = model.getYearDescription.makeDate(end_month, end_day)
          return os_start_date, os_end_date
        end
      end
    end

    # First time period for heating
    heating_time_result1 = validate_time_format(heating_start_time1, heating_end_time1, runner)
    if heating_time_result1
      heating_shift_time_start1, heating_shift_time_end1 = heating_time_result1
    else
      runner.registerError('The required time period for the adjustment is not in correct format!')
      return false
    end
    # The other optional time periods
    heating_shift_time_start2,heating_shift_time_end2,heating_shift_time_start3,heating_shift_time_end3,heating_shift_time_start4,heating_shift_time_end4,heating_shift_time_start5,heating_shift_time_end5 = [nil]*8
    if (not heating_start_time2.empty?) and (not heating_end_time2.empty?)
      heating_time_result2 = validate_time_format(heating_start_time2, heating_end_time2, runner)
      if heating_time_result2
        heating_shift_time_start2, heating_shift_time_end2 = heating_time_result2
      end
    end
    if (not heating_start_time3.empty?) and (not heating_end_time3.empty?)
      heating_time_result3 = validate_time_format(heating_start_time3, heating_end_time3, runner)
      if heating_time_result3
        heating_shift_time_start3, heating_shift_time_end3 = heating_time_result3
      end
    end
    if (not heating_start_time4.empty?) and (not heating_end_time4.empty?)
      heating_time_result4 = validate_time_format(heating_start_time4, heating_end_time4, runner)
      if heating_time_result4
        heating_shift_time_start4, heating_shift_time_end4 = heating_time_result4
      end
    end
    if (not heating_start_time5.empty?) and (not heating_end_time5.empty?)
      heating_time_result5 = validate_time_format(heating_start_time5, heating_end_time5, runner)
      if heating_time_result5
        heating_shift_time_start5, heating_shift_time_end5 = heating_time_result5
      end
    end

    # First time period for cooling
    cooling_time_result1 = validate_time_format(cooling_start_time1, cooling_end_time1, runner)
    if cooling_time_result1
      cooling_shift_time_start1, cooling_shift_time_end1 = cooling_time_result1
    else
      runner.registerError('The required time period for the adjustment is not in correct format!')
      return false
    end
    # The other optional time periods
    cooling_shift_time_start2,cooling_shift_time_end2,cooling_shift_time_start3,cooling_shift_time_end3,cooling_shift_time_start4,cooling_shift_time_end4,cooling_shift_time_start5,cooling_shift_time_end5 = [nil]*8
    if (not cooling_start_time2.empty?) and (not cooling_end_time2.empty?)
      cooling_time_result2 = validate_time_format(cooling_start_time2, cooling_end_time2, runner)
      if cooling_time_result2
        cooling_shift_time_start2, cooling_shift_time_end2 = cooling_time_result2
      end
    end
    if (not cooling_start_time3.empty?) and (not cooling_end_time3.empty?)
      cooling_time_result3 = validate_time_format(cooling_start_time3, cooling_end_time3, runner)
      if cooling_time_result3
        cooling_shift_time_start3, cooling_shift_time_end3 = cooling_time_result3
      end
    end
    if (not cooling_start_time4.empty?) and (not cooling_end_time4.empty?)
      cooling_time_result4 = validate_time_format(cooling_start_time4, cooling_end_time4, runner)
      if cooling_time_result4
        cooling_shift_time_start4, cooling_shift_time_end4 = cooling_time_result4
      end
    end
    if (not cooling_start_time5.empty?) and (not cooling_end_time5.empty?)
      cooling_time_result5 = validate_time_format(cooling_start_time5, cooling_end_time5, runner)
      if cooling_time_result5
        cooling_shift_time_start5, cooling_shift_time_end5 = cooling_time_result5
      end
    end

    # First date period
    heating_date_result1 = validate_date_format(heating_start_date1, heating_end_date1, runner, model)
    if heating_date_result1
      os_heating_start_date1, os_heating_end_date1 = heating_date_result1
    else
      runner.registerError('The required date period for the heating setpoint adjustment is not in correct format!')
      return false
    end
    # Other optional date period
    os_heating_start_date2, os_heating_end_date2, os_heating_start_date3, os_heating_end_date3, os_heating_start_date4, os_heating_end_date4, os_heating_start_date5, os_heating_end_date5 = [nil]*8
    if (not heating_start_date2.empty?) and (not heating_end_date2.empty?)
      heating_date_result2 = validate_date_format(heating_start_date2, heating_end_date2, runner, model)
      if heating_date_result2
        os_heating_start_date2, os_heating_end_date2 = heating_date_result2
      end
    end

    if (not heating_start_date3.empty?) and (not heating_end_date3.empty?)
      heating_date_result3 = validate_date_format(heating_start_date3, heating_end_date3, runner, model)
      if heating_date_result3
        os_heating_start_date3, os_heating_end_date3 = heating_date_result3
      end
    end

    if (not heating_start_date4.empty?) and (not heating_end_date4.empty?)
      heating_date_result4 = validate_date_format(heating_start_date4, heating_end_date4, runner, model)
      if heating_date_result4
        os_heating_start_date4, os_heating_end_date4 = heating_date_result4
      end
    end

    if (not heating_start_date5.empty?) and (not heating_end_date5.empty?)
      heating_date_result5 = validate_date_format(heating_start_date5, heating_end_date5, runner, model)
      if heating_date_result5
        os_heating_start_date5, os_heating_end_date5 = heating_date_result5
      end
    end

    # First date period
    cooling_date_result1 = validate_date_format(cooling_start_date1, cooling_end_date1, runner, model)
    if cooling_date_result1
      os_cooling_start_date1, os_cooling_end_date1 = cooling_date_result1
    else
      runner.registerError('The required date period for the cooling setpoint adjustment is not in correct format!')
      return false
    end
    # Other optional date period
    os_cooling_start_date2, os_cooling_end_date2, os_cooling_start_date3, os_cooling_end_date3, os_cooling_start_date4, os_cooling_end_date4, os_cooling_start_date5, os_cooling_end_date5 = [nil]*8
    if (not cooling_start_date2.empty?) and (not cooling_end_date2.empty?)
      cooling_date_result2 = validate_date_format(cooling_start_date2, cooling_end_date2, runner, model)
      if cooling_date_result2
        os_cooling_start_date2, os_cooling_end_date2 = cooling_date_result2
      end
    end

    if (not cooling_start_date3.empty?) and (not cooling_end_date3.empty?)
      cooling_date_result3 = validate_date_format(cooling_start_date3, cooling_end_date3, runner, model)
      if cooling_date_result3
        os_cooling_start_date3, os_cooling_end_date3 = cooling_date_result3
      end
    end

    if (not cooling_start_date4.empty?) and (not cooling_end_date4.empty?)
      cooling_date_result4 = validate_date_format(cooling_start_date4, cooling_end_date4, runner, model)
      if cooling_date_result4
        os_cooling_start_date4, os_cooling_end_date4 = cooling_date_result4
      end
    end

    if (not cooling_start_date5.empty?) and (not cooling_end_date5.empty?)
      cooling_date_result5 = validate_date_format(cooling_start_date5, cooling_end_date5, runner, model)
      if cooling_date_result5
        os_cooling_start_date5, os_cooling_end_date5 = cooling_date_result5
      end
    end

    # ruby test to see if first charter of string is uppercase letter
    if cooling_adjustment < 0
      runner.registerWarning('Lowering the cooling setpoint will increase energy use. Please double check your input.')
    elsif cooling_adjustment.abs > 500
      runner.registerError("#{cooling_adjustment} is larger than typical setpoint adjustment. Please double check your input.")
      return false
    elsif cooling_adjustment.abs > 50
      runner.registerWarning("#{cooling_adjustment} is larger than typical setpoint adjustment. Please double check your input.")
    end
    if heating_adjustment > 0
      runner.registerWarning('Raising the heating setpoint will increase energy use. Please double check your input.')
    elsif heating_adjustment.abs > 500
      runner.registerError("#{heating_adjustment} is larger than typical setpoint adjustment. Please double check your input.")
      return false
    elsif heating_adjustment.abs > 50
      runner.registerWarning("#{heating_adjustment} is larger than typical setpoint adjustment. Please double check your input.")
    end

    # define starting units
    cooling_adjustment_ip = OpenStudio::Quantity.new(cooling_adjustment, TEMP_IP_UNIT)
    cooling_adjustment_si = cooling_adjustment * 5 / 9.0
    heating_adjustment_ip = OpenStudio::Quantity.new(heating_adjustment, TEMP_IP_UNIT)
    heating_adjustment_si = heating_adjustment * 5 / 9.0

    exclude_space_types = ["ER_Exam", "ER_NurseStn", "ER_Trauma", "ER_Triage", "ICU_NurseStn", "ICU_Open", "ICU_PatRm", "Lab",
                           "OR", "Anesthesia", "BioHazard", "Exam", "MedGas", "OR", "PACU", "PreOp", "ProcedureRoom", "Lab with fume hood",
                           'HspSurgOutptLab', "RefWalkInCool", "RefWalkInFreeze", "HspSurgOutptLab", "RefStorFreezer", "RefStorCooler"]
    # push schedules to hash to avoid making unnecessary duplicates
    clg_set_schs = {}
    htg_set_schs = {}
    # get spaces
    thermostats = model.getThermostatSetpointDualSetpoints
    thermostats.each do |thermostat|
      thermal_zone = thermostat.to_Thermostat.get.thermalZone.get
      if thermal_zone.is_initialized
        zone_applicable = true
        thermal_zone.get.spaces.each do |space|
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
      clg_fuels = thermal_zone.coolingFuelTypes.map(&:valueName).uniq
      htg_fuels = thermal_zone.get.heatingFuelTypes.map(&:valueName).uniq
      unless clg_fuels.include?"Electricity" or htg_fuels.include?"Electricity"
        runner.registerInfo("The space conditioning for thermostat #{thermostat.name.to_s} in thermal zone #{thermal_zone.get.name.to_s} does not use electricity, so it won't be altered.")
        next
      end
      # setup new cooling setpoint schedule
      clg_set_sch = thermostat.coolingSetpointTemperatureSchedule

      if clg_set_sch.empty?
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a cooling setpoint schedule")
      else
        old_clg_schedule = clg_set_sch.get
        old_schedule_name = old_clg_schedule.name.to_s
        # clone if not already in hash
        if old_clg_schedule.to_ScheduleRuleset.is_initialized
          if clg_set_schs.key?(old_schedule_name)
            new_clg_set_sch = clg_set_schs[old_schedule_name]
          else
            # active_indices = old_clg_schedule.to_ScheduleRuleset.get.getActiveRuleIndices(os_cooling_start_date5, os_cooling_end_date5)
            # active_indices.each do |i|
            #   runner.registerInfo("Rule applied to the fifth cooling period: #{old_clg_schedule.to_ScheduleRuleset.get.scheduleRules[i].name.to_s}")
            # end
            new_clg_set_sch = old_clg_schedule.clone(model)
            new_clg_set_sch = new_clg_set_sch.to_Schedule.get
            new_clg_set_sch.setName("#{old_schedule_name} adjusted by #{cooling_adjustment_ip}")
            runner.registerInfo("Cooling schedule #{old_schedule_name} is cloned to #{new_clg_set_sch.name.to_s}")
            # add to the hash
            clg_set_schs[old_schedule_name] = new_clg_set_sch
          end
          # hook up cloned schedule to thermostat
          thermostat.setCoolingSetpointTemperatureSchedule(new_clg_set_sch)
        else
            runner.registerWarning("Schedule '#{old_schedule_name}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        end
      end

      # setup new heating setpoint schedule
      htg_set_sch = thermostat.heatingSetpointTemperatureSchedule
      if htg_set_sch.empty?
        runner.registerWarning("Thermostat '#{thermostat.name}' doesn't have a heating setpoint schedule.")
      else
        old_htg_schedule = htg_set_sch.get
        old_schedule_name = old_htg_schedule.name.to_s
        if old_htg_schedule.to_ScheduleRuleset.is_initialized
          if htg_set_schs.key?(old_schedule_name)
            new_htg_set_sch = htg_set_schs[old_schedule_name]
          else
            new_htg_set_sch = old_htg_schedule.clone(model)
            new_htg_set_sch = new_htg_set_sch.to_Schedule.get
            new_htg_set_sch.setName("#{old_schedule_name} adjusted by #{heating_adjustment_ip}")
            runner.registerInfo("Cooling schedule #{old_schedule_name} is cloned to #{new_htg_set_sch.name.to_s}")
            # add to the hash
            htg_set_schs[old_schedule_name] = new_htg_set_sch
          end
          # hook up clone to thermostat
          thermostat.setHeatingSetpointTemperatureSchedule(new_htg_set_sch)
        else
          runner.registerWarning("Schedule '#{old_schedule_name}' isn't a ScheduleRuleset object and won't be altered by this measure.")
        end

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
      if !zone.thermostatSetpointDualSetpoint.empty? && !zone.useIdealAirLoads && (zone.equipment.size == 0)
        runner.registerWarning("Thermal zone '#{zone.name}' has a thermostat but does not appear to be conditioned.")
      end
    end

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

    applicable_flag = false
    cooling_adjust_period_inputs = { "period1" => {"date_start"=>os_cooling_start_date1, "date_end"=>os_cooling_end_date1,
                                                     "time_start"=>cooling_shift_time_start1, "time_end"=>cooling_shift_time_end1},
                                       "period2" => {"date_start"=>os_cooling_start_date2, "date_end"=>os_cooling_end_date2,
                                             "time_start"=>cooling_shift_time_start2, "time_end"=>cooling_shift_time_end2},
                               "period3" => {"date_start"=>os_cooling_start_date3, "date_end"=>os_cooling_end_date3,
                                             "time_start"=>cooling_shift_time_start3, "time_end"=>cooling_shift_time_end3},
                               "period4" => {"date_start"=>os_cooling_start_date4, "date_end"=>os_cooling_end_date4,
                                             "time_start"=>cooling_shift_time_start4, "time_end"=>cooling_shift_time_end4},
                               "period5" => {"date_start"=>os_cooling_start_date5, "date_end"=>os_cooling_end_date5,
                                             "time_start"=>cooling_shift_time_start5, "time_end"=>cooling_shift_time_end5} }
    # make cooling schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
    clg_set_schs.each do |old_sch_name, os_sch| # old name and new object for schedule
      schedule = os_sch.to_ScheduleRuleset.get
      rules = schedule.scheduleRules
      days_covered = Array.new(7, false)
      current_index = 0
      # TODO: when ruleset has multiple rules for each month or couple of months instead of a full year, should first see if the period overlaps with summer/winter
      if rules.length <= 0
        runner.registerWarning("Cooling setpoint schedule '#{old_sch_name}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
      else
        runner.registerInfo("schedule rule set #{old_sch_name} has #{rules.length} rules.")
        rules.each do |rule|
          runner.registerInfo("---- Rule No.#{rule.ruleIndex}: #{rule.name.to_s}")
          if rule.dateSpecificationType == "SpecificDates"
            ## if the rule applies to SpecificDates, collect the dates that fall into each adjustment date period,
            ## and create a new rule for each date period with covered specific dates
            runner.registerInfo("======= The rule #{rule.name.to_s} only covers specific dates.")
            ## the specificDates cannot be modified in place because it's a frozen array
            all_specific_dates = []
            rule.specificDates.each { |date| all_specific_dates << date }
            cooling_adjust_period_inputs.each do |period, period_inputs|
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
                runner.registerInfo("========= Specific dates within date range #{os_start_date.to_s} to #{os_end_date.to_s}: #{period_inputs["specific_dates"].map(&:to_s)}")
                runner.registerInfo("!!! Specific dates haven't been covered: #{all_specific_dates.map(&:to_s)}")
                next if period_inputs["specific_dates"].empty?
                rule_period = modify_rule_for_specific_dates(rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                                             cooling_adjustment_si, period_inputs["specific_dates"])
                if rule_period
                  applicable_flag = true
                  if period == "period1"
                    final_clg_sch_set_values << rule_period.daySchedule.values
                  end
                  if schedule.setScheduleRuleIndex(rule_period, current_index)
                    current_index += 1
                    runner.registerInfo("-------- The rule #{rule_period.name.to_s} for #{rule_period.dateSpecificationType} is added as priority #{current_index}")
                  else
                    runner.registerError("Fail to set rule index for #{rule_period.name.to_s}.")
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
            cooling_adjust_period_inputs.each do |period, period_inputs|
              os_start_date = period_inputs["date_start"]
              os_end_date = period_inputs["date_end"]
              shift_time_start = period_inputs["time_start"]
              shift_time_end = period_inputs["time_end"]
              if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
                ## check if the original rule applied DateRange overlaps with the adjustment date period
                overlapped, new_start_dates, new_end_dates = check_date_ranges_overlap(rule, os_start_date, os_end_date)
                if overlapped
                  new_start_dates.each_with_index do |start_date, i|
                    rule_period = modify_rule_for_date_period(rule, start_date, new_end_dates[i], shift_time_start,
                                                              shift_time_end, cooling_adjustment_si)
                    if rule_period
                      applicable_flag = true
                      if period == "period1"
                        checkDaysCovered(rule_period, days_covered)
                        final_clg_sch_set_values << rule_period.daySchedule.values
                      end
                      if schedule.setScheduleRuleIndex(rule_period, current_index)
                        current_index += 1
                        runner.registerInfo("-------- The rule #{rule_period.name.to_s} is added as priority #{current_index}")
                      else
                        runner.registerError("Fail to set rule index for #{rule_period.name.to_s}.")
                      end
                    end
                  end
                end

              end
            end
            ## The original rule will be shifted to the currently lowest priority
            ## Setting the rule to an existing index will automatically push all other rules after it down
            if schedule.setScheduleRuleIndex(rule, current_index)
              runner.registerInfo("-------- The original rule #{rule.name.to_s} is shifted to priority #{current_index}")
              current_index += 1
            else
              runner.registerError("Fail to set rule index for #{rule.name.to_s}.")
            end
          end

        end
      end

      default_day = schedule.defaultDaySchedule
      if days_covered.include?(false)
        runner.registerInfo("Some days use default day. Adding new scheduleRule from defaultDaySchedule for applicable date period.")
        cooling_adjust_period_inputs.each do |period, period_inputs|
          os_start_date = period_inputs["date_start"]
          os_end_date = period_inputs["date_end"]
          shift_time_start = period_inputs["time_start"]
          shift_time_end = period_inputs["time_end"]
          if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
            new_default_rule_period = modify_default_day_for_date_period(schedule, default_day, days_covered, os_start_date, os_end_date,
                                               shift_time_start, shift_time_end, cooling_adjustment_si)
            schedule.setScheduleRuleIndex(new_default_rule_period, current_index)
            applicable_flag = true
            if period == 'period1'
              final_clg_sch_set_values << new_default_rule_period.daySchedule.values
            end
          end
        end

      end

    end


    ######################################################################
    heating_adjust_period_inputs = { "period1" => {"date_start"=>os_heating_start_date1, "date_end"=>os_heating_end_date1,
                                                     "time_start"=>heating_shift_time_start1, "time_end"=>heating_shift_time_end1},
                                       "period2" => {"date_start"=>os_heating_start_date2, "date_end"=>os_heating_end_date2,
                                                     "time_start"=>heating_shift_time_start2, "time_end"=>heating_shift_time_end2},
                                       "period3" => {"date_start"=>os_heating_start_date3, "date_end"=>os_heating_end_date3,
                                                     "time_start"=>heating_shift_time_start3, "time_end"=>heating_shift_time_end3},
                                       "period4" => {"date_start"=>os_heating_start_date4, "date_end"=>os_heating_end_date4,
                                                     "time_start"=>heating_shift_time_start4, "time_end"=>heating_shift_time_end4},
                                       "period5" => {"date_start"=>os_heating_start_date5, "date_end"=>os_heating_end_date5,
                                                     "time_start"=>heating_shift_time_start5, "time_end"=>heating_shift_time_end5} }
    # make heating schedule adjustments and rename. Put in check to skip and warn if schedule not ruleset
    htg_set_schs.each do |old_sch_name, os_sch| # old name and new object for schedule
      schedule = os_sch.to_ScheduleRuleset.get
      rules = schedule.scheduleRules
      days_covered = Array.new(7, false)
      current_index = 0
      if rules.length <= 0
        runner.registerWarning("Heating setpoint schedule '#{old_sch_name}' is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
      else
        runner.registerInfo("schedule rule set #{old_sch_name} has #{rules.length} rules.")
        rules.each do |rule|
          runner.registerInfo("---- Rule No.#{rule.ruleIndex}: #{rule.name.to_s}")
          if rule.dateSpecificationType == "SpecificDates"
            ## if the rule applies to SpecificDates, collect the dates that fall into each adjustment date period,
            ## and create a new rule for each date period with covered specific dates
            runner.registerInfo("======= The rule #{rule.name.to_s} only covers specific dates.")
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
                runner.registerInfo("========= Specific dates within date range #{os_start_date.to_s} to #{os_end_date.to_s}: #{period_inputs["specific_dates"].map(&:to_s)}")
                rule_period = modify_rule_for_specific_dates(rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                                             heating_adjustment_si, period_inputs["specific_dates"])
                if rule_period
                  applicable_flag = true
                  if period == "period1"
                    final_htg_sch_set_values << rule_period.daySchedule.values
                  end
                  if schedule.setScheduleRuleIndex(rule_period, current_index)
                    current_index += 1
                    runner.registerInfo("-------- The rule #{rule_period.name.to_s} for #{rule_period.dateSpecificationType} is added as priority #{current_index}")
                  else
                    runner.registerError("Fail to set rule index for #{rule_period.name.to_s}.")
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
            heating_adjust_period_inputs.each do |period, period_inputs|
              os_start_date = period_inputs["date_start"]
              os_end_date = period_inputs["date_end"]
              shift_time_start = period_inputs["time_start"]
              shift_time_end = period_inputs["time_end"]
              if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
                overlapped, new_start_dates, new_end_dates = check_date_ranges_overlap(rule, os_start_date, os_end_date)
                if overlapped
                  new_start_dates.each_with_index do |start_date, i|
                    rule_period = modify_rule_for_date_period(rule, start_date, new_end_dates[i], shift_time_start,
                                                              shift_time_end, heating_adjustment_si)
                    if rule_period
                      applicable_flag = true
                      if period == "period1"
                        checkDaysCovered(rule_period, days_covered)
                        final_htg_sch_set_values << rule_period.daySchedule.values
                      end
                      if schedule.setScheduleRuleIndex(rule_period, current_index)
                        current_index += 1
                        runner.registerInfo("-------- The rule #{rule_period.name.to_s} is added as priority #{current_index}")
                      else
                        runner.registerError("Fail to set rule index for #{rule_period.name.to_s}.")
                      end
                    end
                  end
                end
              end
            end
            # The original rule will be shifted to the currently lowest priority
            # Setting the rule to an existing index will automatically push all other rules after it down
            if schedule.setScheduleRuleIndex(rule, current_index)
              runner.registerInfo("-------- The original rule #{rule.name.to_s} is shifted to priority #{current_index}")
              current_index += 1
            else
              runner.registerError("Fail to set rule index for #{rule.name.to_s}.")
            end
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
            new_default_rule_period = modify_default_day_for_date_period(schedule, default_day, days_covered, os_start_date, os_end_date,
                                               shift_time_start, shift_time_end, heating_adjustment_si)
            schedule.setScheduleRuleIndex(new_default_rule_period, current_index)
            applicable_flag = true
            if period == 'period1'
              final_htg_sch_set_values << new_default_rule_period.daySchedule.values
            end
          end
        end
      end
    end


    model.getEnergyManagementSystemActuators.each do |ems_actuator|
      if ems_actuator.actuatedComponent.is_initialized
        old_sch_name = ems_actuator.actuatedComponent.get.name.to_s
        if clg_set_schs.key?old_sch_name
          replaced_sch = clg_set_schs[old_sch_name]
          ems_actuator.setActuatedComponent(replaced_sch)
          runner.registerInfo("The actuator component for EMS actuator #{ems_actuator.name.to_s} has been changed from #{old_sch_name} to #{replaced_sch.name.to_s}")
        elsif htg_set_schs.key?old_sch_name
          replaced_sch = htg_set_schs[old_sch_name]
          ems_actuator.setActuatedComponent(replaced_sch)
          runner.registerInfo("The actuator component for EMS actuator #{ems_actuator.name.to_s} has been changed from #{old_sch_name} to #{replaced_sch.name.to_s}")
        end
      end
    end


    # not applicable if no schedules can be altered
    if applicable_flag == false
      runner.registerAsNotApplicable('No thermostat schedules in the models could be altered.')
    end

    # get min and max heating and cooling and convert to IP for final
    final_clg_sch_set_values = final_clg_sch_set_values.flatten
    final_htg_sch_set_values = final_htg_sch_set_values.flatten


    if !final_clg_sch_set_values.empty?
      final_min_clg_si = OpenStudio::Quantity.new(final_clg_sch_set_values.min, TEMP_SI_UNIT)
      final_max_clg_si = OpenStudio::Quantity.new(final_clg_sch_set_values.max, TEMP_SI_UNIT)
      final_min_clg_ip = OpenStudio.convert(final_min_clg_si, TEMP_IP_UNIT).get
      final_max_clg_ip = OpenStudio.convert(final_max_clg_si, TEMP_IP_UNIT).get
    else
      final_min_clg_ip = 'NA'
      final_max_clg_ip = 'NA'
    end

    # get min and max if values exist
    if !final_htg_sch_set_values.empty?
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
    runner.registerFinalCondition("Final cooling setpoints used in the model range from #{final_min_clg_ip} to #{final_max_clg_ip}. Final heating setpoints used in the model range from #{final_min_htg_ip} to #{final_max_htg_ip}.")

    return true
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

  def modify_rule_for_date_period(original_rule, os_start_date, os_end_date, shift_time_start, shift_time_end, adjustment)
    # The cloned scheduleRule will automatically belongs to the originally scheduleRuleSet
    # rule_period = original_rule.clone(model).to_ScheduleRule.get
    # rule_period.daySchedule = original_rule.daySchedule.clone(model)
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
    if rule_period
      rule_period.setStartDate(os_start_date)
      rule_period.setEndDate(os_end_date)
    end
    return rule_period
  end

  def modify_rule_for_specific_dates(original_rule, os_start_date, os_end_date, shift_time_start, shift_time_end,
                                     adjustment, applied_dates)
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
    if rule_period
      applied_dates.each do |date|
        rule_period.addSpecificDate(date)
      end
    end
    return rule_period
  end

  def modify_default_day_for_date_period(schedule_set, default_day, days_covered, os_start_date, os_end_date,
                                         shift_time_start, shift_time_end, adjustment)
    # the new rule created for the ScheduleRuleSet by default has the highest priority (ruleIndex=0)
    new_default_rule = OpenStudio::Model::ScheduleRule.new(schedule_set, default_day)
    new_default_rule.setName("#{schedule_set.name.to_s} default day with DF for #{os_start_date.to_s} to #{os_end_date.to_s}")
    new_default_rule.setStartDate(os_start_date)
    new_default_rule.setEndDate(os_end_date)
    coverMissingDays(new_default_rule, days_covered)
    new_default_day = new_default_rule.daySchedule
    day_time_vector = new_default_day.times
    day_value_vector = new_default_day.values
    new_default_day.clearValues
    new_default_day = updateDaySchedule(new_default_day, day_time_vector, day_value_vector, shift_time_start, shift_time_end, adjustment)
    # schedule_set.setScheduleRuleIndex(new_default_rule, 0)
    return new_default_rule
    # TODO: if the scheduleRuleSet has holidaySchedule (which is a ScheduleDay), it cannot be altered
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

  # TODO check if this function works
  def updateDaySchedule_old(sch_day, vec_time, vec_value, time_begin, time_end, adjustment)
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

end



# this allows the measure to be used by the application
AdjustThermostatSetpointsByDegreesForPeakHours.new.registerWithApplication
