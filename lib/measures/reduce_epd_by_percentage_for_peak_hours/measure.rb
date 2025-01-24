# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
require 'json'
class ReduceEPDByPercentageForPeakHours < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "Reduce EPD by Percentage for Peak Hours"
  end
  # human readable description
  def description
    return "This measure reduces electric equipment loads for office space types by a user-specified percentage for a user-specified time period (usually the peak hours). The reduction can be applied to at most five periods throughout out the year specified by the user."
  end
  # human readable description of modeling approach
  def modeler_description
    return "The original schedules for equipment in the building will be found and copied. The copies will be modified to have the percentage reduction during the specified hours, and be applied to the specified date periods through out the year. The rest of the year will keep using the original schedules. Only schedules defined in scheduleRuleSet format and for office standardsSpaceType will be modified."
  end
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    epd_reduce_percent = OpenStudio::Measure::OSArgument.makeDoubleArgument('epd_reduce_percent', true)
    epd_reduce_percent.setDisplayName('Percentage Reduction of Electric Equipment Power (%)')
    epd_reduce_percent.setDescription('Enter a value between 0 and 100')
    epd_reduce_percent.setDefaultValue(20.0)
    args << epd_reduce_percent

    start_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date1', true)
    start_date1.setDisplayName('First start date for the reduction')
    start_date1.setDescription('In MM-DD format')
    start_date1.setDefaultValue('06-01')
    args << start_date1
    end_date1 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date1', true)
    end_date1.setDisplayName('First end date for the reduction')
    end_date1.setDescription('In MM-DD format')
    end_date1.setDefaultValue('09-30')
    args << end_date1

    start_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date2', false)
    start_date2.setDisplayName('Second start date for the reduction (optional)')
    start_date2.setDescription('Specify a date in MM-DD format if you want a second season of reduction; leave blank if not needed.')
    start_date2.setDefaultValue('')
    args << start_date2
    end_date2 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date2', false)
    end_date2.setDisplayName('Second end date for the reduction')
    end_date2.setDescription('Specify a date in MM-DD format if you want a second season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date2.setDefaultValue('')
    args << end_date2


    start_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date3', false)
    start_date3.setDisplayName('Third start date for the reduction (optional)')
    start_date3.setDescription('Specify a date in MM-DD format if you want a third season of reduction; leave blank if not needed.')
    start_date3.setDefaultValue('')
    args << start_date3
    end_date3 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date3', false)
    end_date3.setDisplayName('Third end date for the reduction')
    end_date3.setDisplayName('Third end date for the reduction')
    end_date3.setDescription('Specify a date in MM-DD format if you want a third season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date3.setDefaultValue('')
    args << end_date3

    start_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date4', false)
    start_date4.setDisplayName('Fourth start date for the reduction (optional)')
    start_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of reduction; leave blank if not needed.')
    start_date4.setDefaultValue('')
    args << start_date4
    end_date4 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date4', false)
    end_date4.setDisplayName('Fourth end date for the reduction')
    end_date4.setDescription('Specify a date in MM-DD format if you want a fourth season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date4.setDefaultValue('')
    args << end_date4


    start_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date5', false)
    start_date5.setDisplayName('Fifth start date for the reduction (optional)')
    start_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of reduction; leave blank if not needed.')
    start_date5.setDefaultValue('')
    args << start_date5
    end_date5 = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date5', false)
    end_date5.setDisplayName('Fifth end date for the reduction')
    end_date5.setDescription('Specify a date in MM-DD format if you want a fifth season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.')
    end_date5.setDefaultValue('')
    args << end_date5

    # make an argument for the start time of the reduction
    start_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time1', true)
    start_time1.setDisplayName('Start time of the reduction for the first season')
    start_time1.setDescription('In HH:MM:SS format')
    start_time1.setDefaultValue('17:00:00')
    args << start_time1
    end_time1 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time1', true)
    end_time1.setDisplayName('End time of the reduction for the first season')
    end_time1.setDescription('In HH:MM:SS format')
    end_time1.setDefaultValue('21:00:00')
    args << end_time1


    start_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time2', false)
    start_time2.setDisplayName('Start time of the reduction for the second season (optional)')
    start_time2.setDescription('In HH:MM:SS format')
    start_time2.setDefaultValue('')
    args << start_time2
    end_time2 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time2', false)
    end_time2.setDisplayName('End time of the reduction for the second season (optional)')
    end_time2.setDescription('In HH:MM:SS format')
    end_time2.setDefaultValue('')
    args << end_time2


    start_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time3', false)
    start_time3.setDisplayName('Start time of the reduction for the third season (optional)')
    start_time3.setDescription('In HH:MM:SS format')
    start_time3.setDefaultValue('')
    args << start_time3
    end_time3 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time3', false)
    end_time3.setDisplayName('End time of the reduction for the third season (optional)')
    end_time3.setDescription('In HH:MM:SS format')
    end_time3.setDefaultValue('')
    args << end_time3


    start_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time4', false)
    start_time4.setDisplayName('Start time of the reduction for the fourth season (optional)')
    start_time4.setDescription('In HH:MM:SS format')
    start_time4.setDefaultValue('')
    args << start_time4
    end_time4 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time4', false)
    end_time4.setDisplayName('End time of the reduction for the fourth season (optional)')
    end_time4.setDescription('In HH:MM:SS format')
    end_time4.setDefaultValue('')
    args << end_time4


    start_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('start_time5', false)
    start_time5.setDisplayName('Start time of the reduction for the fifth season (optional)')
    start_time5.setDescription('In HH:MM:SS format')
    start_time5.setDefaultValue('')
    args << start_time5
    end_time5 = OpenStudio::Measure::OSArgument.makeStringArgument('end_time5', false)
    end_time5.setDisplayName('End time of the reduction for the fifth season (optional)')
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
    epd_reduce_percent = runner.getDoubleArgumentValue('epd_reduce_percent', user_arguments)
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

    # validate the percentage
    if epd_reduce_percent > 100
      runner.registerError('The percentage reduction of electric equipment power cannot be larger than 100.')
      return false
    elsif epd_reduce_percent < 0
      runner.registerWarning('The percentage reduction of electric equipment power is negative. This will increase the electric equipment power.')
    end

    # set the default start and end time based on state
    if alt_periods
      state = model.getWeatherFile.stateProvinceRegion
      if state == ''
        runner.registerError('Unable to find state in model WeatherFile. The measure cannot be applied.')
        return false
      end
      runner.registerInfo("Using weather file for #{state} state.")
      file = File.open(File.join(File.dirname(__FILE__), "../../../files/seasonal_shedding_peak_hours.json"))
      default_peak_periods = JSON.load(file)
      file.close
      unless default_peak_periods.key?state
        runner.registerAsNotApplicable("No default inputs for the state of the WeatherFile #{state}")
        return false
      end
      peak_periods = default_peak_periods[state]
      start_time1 = peak_periods["winter_peak_start"].split[1]
      end_time1 = peak_periods["winter_peak_end"].split[1]
      start_time2 = peak_periods["intermediate_peak_start"].split[1]
      end_time2 = peak_periods["intermediate_peak_end"].split[1]
      start_time3 = peak_periods["summer_peak_start"].split[1]
      end_time3 = peak_periods["summer_peak_end"].split[1]
      start_time4 = peak_periods["intermediate_peak_start"].split[1]
      end_time4 = peak_periods["intermediate_peak_end"].split[1]
      start_time5 = peak_periods["winter_peak_start"].split[1]
      end_time5 = peak_periods["winter_peak_end"].split[1]
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
          runner.registerError("The start time needs to be earlier than the end time (currently #{star_time}-#{end_time}).")
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

    applicable_space_types = ["SecondarySchool - Office",
                              "PrimarySchool - Office",
                              "SmallOffice - ClosedOffice",
                              "SmallOffice - Conference",
                              "SmallOffice - OpenOffice",
                              "MediumOffice - Classroom",
                              "MediumOffice - ClosedOffice",
                              "MediumOffice - Conference",
                              "MediumOffice - OpenOffice",
                              "LargeOffice - BreakRoom",
                              "LargeOffice - Classroom",
                              "LargeOffice - ClosedOffice",
                              "LargeOffice - Conference",
                              "LargeOffice - OpenOffice",
                              "SmallHotel - Meeting",
                              "SmallHotel - Office",
                              "Storage - Office",
                              "Hospital - Office",
                              "Outpatient - Conference",
                              "Outpatient - Office",
                              "Warehouse - Office",
                              "WholeBuilding - Sm Office",
                              "WholeBuilding - Md Office",
                              "WholeBuilding - Lg Office",
                              "OfficeGeneral",
                              "OfficeOpen",
                              "Conference",
                              "OfficeSmall"]

    adjust_period_inputs = { "period1" => {"date_start"=>os_start_date1, "date_end"=>os_end_date1,
                                             "time_start"=>shift_time_start1, "time_end"=>shift_time_end1},
                               "period2" => {"date_start"=>os_start_date2, "date_end"=>os_end_date2,
                                             "time_start"=>shift_time_start2, "time_end"=>shift_time_end2},
                               "period3" => {"date_start"=>os_start_date3, "date_end"=>os_end_date3,
                                             "time_start"=>shift_time_start3, "time_end"=>shift_time_end3},
                               "period4" => {"date_start"=>os_start_date4, "date_end"=>os_end_date4,
                                             "time_start"=>shift_time_start4, "time_end"=>shift_time_end4},
                               "period5" => {"date_start"=>os_start_date5, "date_end"=>os_end_date5,
                                             "time_start"=>shift_time_start5, "time_end"=>shift_time_end5} }

    epd_factor = 1 - (epd_reduce_percent/100)
    applicable =  false
    equipments = model.getElectricEquipments
    # create a hash to map the old schedule name to the new schedule
    equip_schedules = {}
    equipments.each do |equip|
      equip_sch = equip.schedule
      if equip_sch.empty?
        runner.registerWarning("#{equip.name} doesn't have a schedule, so it won't be altered.")
        next
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

    equip_schedules.each do |old_name, cloned_equip_sch|
      schedule_set = cloned_equip_sch.to_ScheduleRuleset.get
      rules = schedule_set.scheduleRules
      days_covered = Array.new(7, false)
      original_rule_number = rules.length
      current_index = 0
      if original_rule_number > 0
        runner.registerInfo("schedule rule set #{old_name} has #{original_rule_number} rules.")
        # rules are in order of priority
        rules.each do |rule|
          runner.registerInfo("---- Rule No.#{rule.ruleIndex}: #{rule.name.to_s}")
          if rule.dateSpecificationType == "SpecificDates"
            ## if the rule applies to SpecificDates, collect the dates that fall into each adjustment date period,
            ## and create a new rule for each date period with covered specific dates
            runner.registerInfo("======= The rule #{rule.name.to_s} only covers specific dates.")
            ## the specificDates cannot be modified in place because it's a frozen array
            all_specific_dates = []
            rule.specificDates.each { |date| all_specific_dates << date }
            adjust_period_inputs.each do |period, period_inputs|
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
                                                             epd_factor, period_inputs["specific_dates"])
                if rule_period
                  applicable = true
                  if schedule_set.setScheduleRuleIndex(rule_period, current_index)
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
              schedule_set.setScheduleRuleIndex(original_rule_update, current_index)
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
            # runner.registerInfo("Before adjustment, the rule #{rule.name.to_s} is #{rule.daySchedule.values}")

            adjust_period_inputs.each do |period, period_inputs|
              os_start_date = period_inputs["date_start"]
              os_end_date = period_inputs["date_end"]
              shift_time_start = period_inputs["time_start"]
              shift_time_end = period_inputs["time_end"]
              if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
                overlapped, new_start_dates, new_end_dates = check_date_ranges_overlap(rule, os_start_date, os_end_date)
                if overlapped
                  new_start_dates.each_with_index do |start_date, i|
                    rule_period = modify_rule_for_date_period(rule, start_date, new_end_dates[i], shift_time_start, shift_time_end, epd_factor)
                    if rule_period
                      applicable = true
                      if period == "period1"
                        # check the days covered only once
                        checkDaysCovered(rule_period, days_covered)
                      end
                      if schedule_set.setScheduleRuleIndex(rule_period, current_index)
                        runner.registerInfo("-------- The rule #{rule_period.name.to_s} is added as priority #{current_index}")
                        current_index += 1
                      else
                        runner.registerError("-------- Fail to set rule index for #{rule_period.name.to_s}.")
                      end
                    end
                  end
                end
              end
            end
            # The original rule will be shifted to the currently lowest priority
            # Setting the rule to an existing index will automatically push all other rules after it down
            if schedule_set.setScheduleRuleIndex(rule, current_index)
              runner.registerInfo("-------- The original rule #{rule.name.to_s} is shifted to priority #{current_index}")
              current_index += 1
            else
              runner.registerError("-------- Fail to set rule index for #{rule.name.to_s}")
            end
          end

        end
      else
        runner.registerWarning("Electric equipment schedule #{old_name} is a ScheduleRuleSet, but has no ScheduleRules associated. It won't be altered by this measure.")
      end

      # if all rules not covered all days in a week, then the rest of days use defaultDaySchedule
      # defaultDaySchedule cannot specify date range, so clone it to a new rule to set date range and cover the rest of days
      default_day = schedule_set.defaultDaySchedule
      if days_covered.include?(false)
        runner.registerInfo("Some days use default day. Adding new scheduleRule from defaultDaySchedule for applicable date period.")
        adjust_period_inputs.each do |period, period_inputs|
          runner.registerInfo("******** current covered days: #{days_covered}")
          os_start_date = period_inputs["date_start"]
          os_end_date = period_inputs["date_end"]
          shift_time_start = period_inputs["time_start"]
          shift_time_end = period_inputs["time_end"]
          if [os_start_date, os_end_date, shift_time_start, shift_time_end].all?
            new_default_rule_period = modify_default_day_for_date_period(schedule_set, default_day, days_covered, os_start_date, os_end_date,
                                               shift_time_start, shift_time_end, epd_factor)
            schedule_set.setScheduleRuleIndex(new_default_rule_period, current_index)
          end
        end
      end
      # schedule_set.scheduleRules.each do |final_rule|
      #   runner.registerInfo("Finally rules： #{final_rule.name.to_s} is in priority #{final_rule.ruleIndex}")
      # end
    end

    unless applicable
      runner.registerAsNotApplicable('No electric equipment schedule in the model could be altered.')
    end

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
                                         shift_time_start, shift_time_end, epd_factor)
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
    new_default_day = updateDaySchedule(new_default_day, day_time_vector, day_value_vector, shift_time_start, shift_time_end, epd_factor)
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
