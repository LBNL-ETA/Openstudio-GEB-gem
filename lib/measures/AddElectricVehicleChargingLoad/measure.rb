# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

class AddElectricVehicleChargingLoad < OpenStudio::Measure::ModelMeasure
  require 'time'

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'AddElectricVehicleChargingLoad'
  end

  # human readable description
  def description
    return 'This measure adds electric vehicle charging load to the building. The user can specify the level of charger, number of chargers, number of EVs charging daily, start time, average number of hours to fully charge. '
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure will add electric vehicle charging load as exterior electric equipment. The user inputs of level of chargers, number of chargers, and number of EVs charging daily will be used to determine the load level, and the inputs of start time and average number of hours to fully charge will be used to determine load schedule.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # building use type, choice argument, 'home' or 'workplace'
    bldg_use_type_chs = OpenStudio::StringVector.new
    bldg_use_type_chs << 'home'
    bldg_use_type_chs << 'workplace'
    bldg_use_type_chs << 'commercial station'

    bldg_use_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('bldg_use_type', bldg_use_type_chs, true)
    bldg_use_type.setDisplayName('Building Use Type')
    bldg_use_type.setDefaultValue('home')
    args << bldg_use_type

    # Number of EV chargers
    num_ev_chargers = OpenStudio::Measure::OSArgument.makeIntegerArgument('num_ev_chargers', true)
    num_ev_chargers.setDisplayName('Number of EV Chargers')
    num_ev_chargers.setDefaultValue(1)
    args << num_ev_chargers

    # Number of Electric Vehicles
    num_evs = OpenStudio::Measure::OSArgument.makeIntegerArgument('num_evs', true)
    num_evs.setDisplayName('Number of Electric Vehicles')
    num_evs.setDefaultValue(1)
    args << num_evs

    # EV charger level, choice argument
    charger_level_chs = OpenStudio::StringVector.new
    charger_level_chs << 'Level 1'
    charger_level_chs << 'Level 2'
    charger_level_chs << 'DC charger'
    charger_level_chs << 'Supercharger'

    charger_level = OpenStudio::Measure::OSArgument.makeChoiceArgument('charger_level', charger_level_chs, true)
    charger_level.setDisplayName('EV Charger Level')
    charger_level.setDefaultValue('Level 2')
    args << charger_level

    # average arrival time, applicable for workplace only
    avg_arrival_time = OpenStudio::Measure::OSArgument.makeStringArgument('avg_arrival_time', false)
    avg_arrival_time.setDisplayName('Average arrival time, applicable for workplace only')
    avg_arrival_time.setDefaultValue('08:30')
    args << avg_arrival_time

    # average arrival time, applicable for workplace only
    avg_leave_time = OpenStudio::Measure::OSArgument.makeStringArgument('avg_leave_time', false)
    avg_leave_time.setDisplayName('Average leave time, applicable for workplace only')
    avg_leave_time.setDefaultValue('17:30')
    args << avg_leave_time

    # start charging time, required for home
    start_charge_time = OpenStudio::Measure::OSArgument.makeStringArgument('start_charge_time', false)
    start_charge_time.setDisplayName('Start charging time, required for home only')
    start_charge_time.setDefaultValue('21:00')
    args << start_charge_time

    # average needed hours to charge to full. This should vary with the charger level.
    avg_charge_hours = OpenStudio::Measure::OSArgument.makeDoubleArgument('avg_charge_hours', true)
    avg_charge_hours.setDisplayName('Average needed hours to charge to full (should vary with charger level)')
    avg_charge_hours.setDefaultValue(4)
    args << avg_charge_hours

    # variation of arrival time in minutes
    arrival_time_variation_in_mins = OpenStudio::Measure::OSArgument.makeDoubleArgument('arrival_time_variation_in_mins', false)
    arrival_time_variation_in_mins.setDescription('Actual arrival time can vary a certain period before and after the average arrival time. '\
                                                    'This parameter describes this absolute time delta. '\
                                                    'In other words, average arrival time plus/minus this parameter constitutes the arrival time range. ')
    arrival_time_variation_in_mins.setDisplayName('Variation of arrival time in minutes')
    arrival_time_variation_in_mins.setDefaultValue(30)
    args << arrival_time_variation_in_mins

    # variation of charge time in minutes
    charge_time_variation_in_mins = OpenStudio::Measure::OSArgument.makeDoubleArgument('charge_time_variation_in_mins', false)
    charge_time_variation_in_mins.setDescription('Actual charge time can vary a certain period around the average charge hours. '\
                                                    'This parameter describes this absolute time delta. '\
                                                    'In other words, average charge hours plus/minus this parameter constitutes the charge time range. ')
    charge_time_variation_in_mins.setDisplayName('Variation of charge time in minutes')
    charge_time_variation_in_mins.setDefaultValue(60)
    args << charge_time_variation_in_mins

    # if EVs are charged on Saturday
    charge_on_sat = OpenStudio::Measure::OSArgument.makeBoolArgument('charge_on_sat', false)
    charge_on_sat.setDisplayName('EVs are charged on Saturday')
    charge_on_sat.setDefaultValue(true)
    args << charge_on_sat

    # if EVs are charged on Sunday
    charge_on_sun = OpenStudio::Measure::OSArgument.makeBoolArgument('charge_on_sun', false)
    charge_on_sun.setDisplayName('EVs are charged on Sunday')
    charge_on_sun.setDefaultValue(true)
    args << charge_on_sun

    return args
  end

  class EVcharger
    def initialize(name)
      @name = name
      @occupied = false  # vacant: 0, occupied: 1
      @level = 1  # Level1: 1, Level2: 2, DC charger: 3
      @charging_power = nil
      @connected_ev = nil
      @occupied_until_time = nil
      #TODO for workplace need to use the list instead of single time too, same as commercial station
      @occupied_until_time_list = Array.new  # for commercial station use this
      @occupied_start_time = nil
      @occupied_start_time_list = Array.new  # for commercial station use this
      @charged_ev_list = Array.new
    end

    attr_accessor :name  # Type: string. Name.
    attr_accessor :occupied  # Type: boolean
    attr_accessor :level
    attr_accessor :charging_power  # Type: float, unit: kW
    attr_accessor :connected_ev   # Type: ElectricVehicle
    attr_accessor :occupied_until_time   # Type: Time. Daily end charging time
    attr_accessor :occupied_until_time_list   # Type: Array of Time. List of daily end charging time
    attr_accessor :occupied_start_time   # Type: Time. Daily start charging time
    attr_accessor :occupied_start_time_list   # Type: Array of Time. List of daily start charging time
    attr_accessor :charged_ev_list   # Type: Array
  end

  class ElectricVehicle
    def initialize(name)
      @name = name
      @has_been_charged = false
      @connected_to_charger = false
      @arrival_time = nil
      @leave_time = nil
      @start_charge_time = nil
      @end_charge_time = nil
      @needed_charge_hours = nil
    end

    attr_accessor :name  # Type: string. Name.
    attr_accessor :has_been_charged  # Type: boolean. if this EV has been charged
    attr_accessor :connected_to_charger  # Type: boolean. if this EV is currently connected to a charger
    attr_accessor :arrival_time   # time this EV arrives at the building
    attr_accessor :leave_time   # time this EV arrives at the building
    attr_accessor :start_charge_time   # time this EV starts charging
    attr_accessor :end_charge_time   # time this EV ends charging
    attr_accessor :needed_charge_hours   # needed number of hours to charge to full
  end


  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    bldg_use_type = runner.getStringArgumentValue('bldg_use_type', user_arguments)
    num_ev_chargers = runner.getIntegerArgumentValue('num_ev_chargers', user_arguments)
    num_evs = runner.getIntegerArgumentValue('num_evs', user_arguments)
    charger_level = runner.getStringArgumentValue('charger_level', user_arguments)
    avg_arrival_time = runner.getStringArgumentValue('avg_arrival_time', user_arguments)
    avg_leave_time = runner.getStringArgumentValue('avg_leave_time', user_arguments)
    start_charge_time = runner.getStringArgumentValue('start_charge_time', user_arguments)
    avg_charge_hours = runner.getDoubleArgumentValue('avg_charge_hours', user_arguments)
    arrival_time_variation_in_mins = runner.getDoubleArgumentValue('arrival_time_variation_in_mins', user_arguments)
    charge_time_variation_in_mins = runner.getDoubleArgumentValue('charge_time_variation_in_mins', user_arguments)
    charge_on_sat = runner.getBoolArgumentValue('charge_on_sat', user_arguments)
    charge_on_sun = runner.getBoolArgumentValue('charge_on_sun', user_arguments)

    puts "num_ev_chargers: #{num_ev_chargers.inspect}"
    puts "avg_arrival_time: #{avg_arrival_time.inspect}"
    puts "avg_charge_hours: #{avg_charge_hours.inspect}"
    puts "charge_on_sat: #{charge_on_sat.inspect}"
    puts "charge_on_sun: #{charge_on_sun.inspect}"

    if bldg_use_type == 'workplace'
      # check avg_arrival_time and avg_leave_time should be in correct Time format
      begin
        avg_arrival_time = Time.strptime(avg_arrival_time, '%H:%M')
        avg_leave_time = Time.strptime(avg_leave_time, '%H:%M')
      rescue ArgumentError
        runner.registerError('For workplaces, average arrival and leave time are required, and should be in format of %H:%M, e.g., 16:00.')
        return false
      end
      # check avg_leave_time should be later than avg_arrival_time
      if avg_leave_time <= avg_arrival_time
        runner.registerError('For workplaces, average arrival time should be earlier than average leave time.')
        return false
      end
    elsif bldg_use_type == 'home'
      # check start_charge_time should be in correct Time format
      begin
        start_charge_time = Time.strptime(start_charge_time, '%H:%M')
      rescue ArgumentError
        runner.registerError('For homes, start charging time is required, and should be in format of %H:%M, e.g., 16:00.')
        return false
      end
    elsif bldg_use_type == 'commercial station'
      # check avg_arrival_time should be in correct Time format
      begin
        avg_arrival_time = Time.strptime(avg_arrival_time, '%H:%M')
      rescue ArgumentError
        runner.registerError('For commercial station, average arrival time is required, and should be in format of %H:%M, e.g., 10:00.')
        return false
      end
    else
      runner.registerError("Wrong building use type, available options: 'workplace' and 'home'.")
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("Starting to add electric vehicle to the building.")

    # Initialize the EV chargers
    ev_chargers = []
    max_charging_power = 0  # initial
    for i in 1..num_ev_chargers
      charger = EVcharger.new("EVcharger_#{i.to_s}")
      charger.level = charger_level
      # charging power references:
      # https://calevip.org/electric-vehicle-charging-101
      # https://rmi.org/electric-vehicle-charging-for-dummies/
      # https://freewiretech.com/difference-between-ev-charging-levels/#:~:text=Level%201%20Charging&text=L1%20chargers%20plug%20directly%20into,is%20sufficient%20for%20many%20commuters.
      case charger_level
      when 'Level 1'
        charger.charging_power = 1.5
      when 'Level 2'
        # charger.charging_power = 7.0
        charger.charging_power = 9.6   # C2C expert match input
      when 'DC charger'
        # charger.charging_power = 50.0
        charger.charging_power = 54.0  # C2C expert match input
      when 'Supercharger'
        charger.charging_power = 185
      else
        runner.registerError("Wrong EV charging level, available options: 'Level 1', 'Level 2', 'DC charger', 'Supercharger'.")
        return false
      end
      max_charging_power += charger.charging_power
      ev_chargers << charger
    end

    def create_ev_sch(model, ev_chargers, max_charging_power, charge_on_sat, charge_on_sun)
      # create the schedule
      # Creating a schedule:ruleset
      ev_sch = OpenStudio::Model::ScheduleRuleset.new(model)
      ev_sch.setName('EV Charging Power Draw')
      ev_sch.defaultDaySchedule.setName('EV Charging Default')
      day_start_time = Time.strptime("00:00", '%H:%M')
      # initial EV load depends on if each charger charges overnight
      ev_load = 0   # kW
      ev_chargers.each do |ev_charger|
        puts "#{ev_charger.name}"
        puts "ev_charger.occupied_until_time - day_start_time - 24*60*60)/60: #{(ev_charger.occupied_until_time - day_start_time - 24*60*60)/60}"
        puts "ev_charger.occupied_start_time - day_start_time)/60: #{(ev_charger.occupied_start_time - day_start_time)/60}"
        puts "ev_charger.occupied_start_time: #{ev_charger.occupied_start_time}"
        puts "ev_charger.occupied_until_time: #{ev_charger.occupied_until_time}"
        puts "ev_charger.occupied_start_time.day: #{ev_charger.occupied_start_time.day}"
        puts "ev_charger.occupied_until_time.day: #{ev_charger.occupied_until_time.day}"
        ev_load += ev_charger.charging_power if ev_charger.occupied_start_time.day != ev_charger.occupied_until_time.day
      end
      ev_load_new = ev_load # kW
      puts "******Initial******"
      puts "ev_load: #{ev_load}"
      puts "ev_load_new: #{ev_load_new}"

      # iterate through 1440 minutes in one day
      for min in 1..24*60
        ev_chargers.each do |ev_charger|
          # charging on the same day
          if ev_charger.occupied_start_time.day == ev_charger.occupied_until_time.day
            if ((ev_charger.occupied_start_time - day_start_time)/60).to_i == min
              if ev_load_new == ev_load
                ev_load_new = ev_load + ev_charger.charging_power
              else  # if more than one chargers change status at this time point
                ev_load_new += ev_charger.charging_power
              end
            elsif ((ev_charger.occupied_until_time - day_start_time)/60).to_i == min
              if ev_load_new == ev_load
                ev_load_new = ev_load - ev_charger.charging_power
              else  # if more than one chargers change status at this time point
                ev_load_new -= ev_charger.charging_power
              end
            end
          else   # charging overnight
          if ((ev_charger.occupied_until_time - day_start_time - 24*60*60)/60).to_i == min
            if ev_load_new == ev_load
              ev_load_new = ev_load - ev_charger.charging_power
            else  # if more than one chargers change status at this time point
            ev_load_new -= ev_charger.charging_power
            end
          elsif ((ev_charger.occupied_start_time - day_start_time)/60).to_i == min
            if ev_load_new == ev_load
              ev_load_new = ev_load + ev_charger.charging_power
            else  # if more than one chargers change status at this time point
            ev_load_new += ev_charger.charging_power
            end
          end
          end
        end
        # if any change, add to schedule
        if ev_load_new != ev_load || min == 24*60
          puts "****after****"
          puts "ev_load_new: #{ev_load_new}"
          puts "ev_load: #{ev_load}"
          time = OpenStudio::Time.new(0, 0, min) # OpenStudio::Time.new(day,hr of day, minute of hr, seconds of hr?)
          ev_sch.defaultDaySchedule.addValue(time, (ev_load/max_charging_power).round(2))
          ev_load = ev_load_new
        end
      end

      if charge_on_sat
        ev_sch_sat = OpenStudio::Model::ScheduleRule.new(ev_sch, ev_sch.defaultDaySchedule)
        ev_sch_sat.setName('EV Charging Power Saturday')
        ev_sch_sat.setApplySaturday(true)
      else
        ev_sch_sat_rule = OpenStudio::Model::ScheduleRule.new(ev_sch)
        ev_sch_sat_rule.setName('EV Charging Power Saturday')
        ev_sch_sat_rule.setApplySaturday(true)
        ev_sch_sat = ev_sch_sat_rule.daySchedule
        ev_sch_sat.setName('EV Charging Saturday')
        ev_sch_sat.addValue(OpenStudio::Time.new(0,24,0), 0)
      end

      if charge_on_sun
        ev_sch_sun = OpenStudio::Model::ScheduleRule.new(ev_sch, ev_sch.defaultDaySchedule)
        ev_sch_sun.setName('EV Charging Power Sunday')
        ev_sch_sun.setApplySunday(true)
      else
        ev_sch_sun_rule = OpenStudio::Model::ScheduleRule.new(ev_sch)
        ev_sch_sun_rule.setName('EV Charging Power Sunday')
        ev_sch_sun_rule.setApplySunday(true)
        ev_sch_sun = ev_sch_sun_rule.daySchedule
        ev_sch_sun.setName('EV Charging Sunday')
        ev_sch_sun.addValue(OpenStudio::Time.new(0,24,0), 0)
      end

      return ev_sch
    end

    def create_ev_sch_single(model, ev_charger, charge_on_sat, charge_on_sun)
      # create the schedule
      # Creating a schedule:ruleset
      ev_sch = OpenStudio::Model::ScheduleRuleset.new(model)
      ev_sch.setName("EV Charging Power Draw for charger #{ev_charger.name.to_s}")
      ev_sch.defaultDaySchedule.setName("EV Charging Default for charger #{ev_charger.name.to_s}")
      day_start_time = Time.strptime("00:00", '%H:%M')

      puts "ev_charger.occupied_start_time_list: #{ev_charger.occupied_start_time_list}"
      puts "ev_charger.occupied_until_time_list: #{ev_charger.occupied_until_time_list}"
      occupied_start_time_list = ev_charger.occupied_start_time_list
      occupied_until_time_list = ev_charger.occupied_until_time_list

      occupied_start_time_list.each_with_index do |occupied_start_time, idx|
        occupied_until_time = occupied_until_time_list[idx]
        if occupied_start_time.day == occupied_until_time.day
          # charging on the same day
          if idx > 0 && occupied_start_time == occupied_until_time_list[idx-1]
            # car charging are continuous without vacancy period
            end_time = OpenStudio::Time.new(0, 0, ((occupied_until_time - day_start_time)/60).to_i) # OpenStudio::Time.new(day,hr of day, minute of hr, seconds of hr?)
            ev_sch.defaultDaySchedule.addValue(end_time, 1)
          else
            # there are vacancy period between cars
            start_time = OpenStudio::Time.new(0, 0, ((occupied_start_time - day_start_time)/60).to_i) # OpenStudio::Time.new(day,hr of day, minute of hr, seconds of hr?)
            ev_sch.defaultDaySchedule.addValue(start_time, 0)
            end_time = OpenStudio::Time.new(0, 0, ((occupied_until_time - day_start_time)/60).to_i) # OpenStudio::Time.new(day,hr of day, minute of hr, seconds of hr?)
            ev_sch.defaultDaySchedule.addValue(end_time, 1)
          end
        else   # charging overnight
          if idx > 0 && occupied_start_time == occupied_until_time_list[idx-1]
            # car charging are continuous without vacancy period
            end_time_1 = OpenStudio::Time.new(0, 24, 0, 0)  # first till the end of the day
            end_time_2 = OpenStudio::Time.new(0, 0, ((occupied_until_time - day_start_time)/60).to_i) # OpenStudio::Time.new(day,hr of day, minute of hr, seconds of hr?)
            ev_sch.defaultDaySchedule.addValue(end_time_1, 1)
            ev_sch.defaultDaySchedule.addValue(end_time_2, 1)
          else
            # there are vacancy period between cars
            start_time = OpenStudio::Time.new(0, 0, ((occupied_start_time - day_start_time)/60).to_i) # OpenStudio::Time.new(day,hr of day, minute of hr, seconds of hr?)
            ev_sch.defaultDaySchedule.addValue(start_time, 0)
            end_time_1 = OpenStudio::Time.new(0, 24, 0, 0)  # first till the end of the day
            end_time_2 = OpenStudio::Time.new(0, 0, ((occupied_until_time - day_start_time)/60).to_i) # OpenStudio::Time.new(day,hr of day, minute of hr, seconds of hr?)
            ev_sch.defaultDaySchedule.addValue(end_time_1, 1)
            ev_sch.defaultDaySchedule.addValue(end_time_2, 1)
          end
        end
      end

      if charge_on_sat
        ev_sch_sat = OpenStudio::Model::ScheduleRule.new(ev_sch, ev_sch.defaultDaySchedule)
        ev_sch_sat.setName('EV Charging Power Saturday')
        ev_sch_sat.setApplySaturday(true)
      else
        ev_sch_sat_rule = OpenStudio::Model::ScheduleRule.new(ev_sch)
        ev_sch_sat_rule.setName('EV Charging Power Saturday')
        ev_sch_sat_rule.setApplySaturday(true)
        ev_sch_sat = ev_sch_sat_rule.daySchedule
        ev_sch_sat.setName('EV Charging Saturday')
        ev_sch_sat.addValue(OpenStudio::Time.new(0,24,0), 0)
      end

      if charge_on_sun
        ev_sch_sun = OpenStudio::Model::ScheduleRule.new(ev_sch, ev_sch.defaultDaySchedule)
        ev_sch_sun.setName('EV Charging Power Sunday')
        ev_sch_sun.setApplySunday(true)
      else
        ev_sch_sun_rule = OpenStudio::Model::ScheduleRule.new(ev_sch)
        ev_sch_sun_rule.setName('EV Charging Power Sunday')
        ev_sch_sun_rule.setApplySunday(true)
        ev_sch_sun = ev_sch_sun_rule.daySchedule
        ev_sch_sun.setName('EV Charging Sunday')
        ev_sch_sun.addValue(OpenStudio::Time.new(0,24,0), 0)
      end

      return ev_sch
    end

    # *********************************************
    # for workplace
    # waitlist is only applicable to workplace. For homes, charging is scheduled with start_charge_time
    # create all EV chargers
    def create_ev_sch_for_workplace(model, ev_chargers, max_charging_power, num_evs, avg_arrival_time, arrival_time_variation_in_mins, avg_leave_time, avg_charge_hours, charge_time_variation_in_mins, charge_on_sat, charge_on_sun)
      ev_list = []
      for j in 1..num_evs
        ev = ElectricVehicle.new("ev_#{j.to_s}")
        ev.arrival_time = avg_arrival_time + rand(-arrival_time_variation_in_mins...arrival_time_variation_in_mins) * 60  # TODO make sure time format is working correctly, Ruby Times "+" adopts seconds
        ev.leave_time = avg_leave_time + rand(-30...30) * 60  # TODO make sure time format is working correctly, Ruby Times "+" adopts seconds
        ev.leave_time = Time.strptime("23:00", '%H:%M') + 3600 if ev.leave_time > Time.strptime("23:00", '%H:%M') + 3600  # fix leave time at 24:00 if later than 24:00
        ev.needed_charge_hours = avg_charge_hours + rand(-charge_time_variation_in_mins...charge_time_variation_in_mins) / 60.0   # +- variation charge time
        ev_list << ev
      end

      # find the earliest arrival time
      arrival_time_earliest = Time.strptime("23:00", '%H:%M') + 3600  # initial: 24:00
      ev_list.each do |this_ev|
        if this_ev.arrival_time < arrival_time_earliest
          arrival_time_earliest = this_ev.arrival_time
        end
      end

      # For workplace: iterate through time, check status of each charger, if vacant, find the EV that has the earliest arrival time within uncharged EVs.
      # if this EV's leaving time is later than the current time, start charging until fully charged or leaving time, whichever comes first
      # when no EV is found any more, charging on this day ends, conclude the charging profile
      # 23 represent 23:00-24:00, corresponding to E+ schedule Until: 24:00
      for hour in 0..23
        current_time = Time.strptime("#{hour}:00", '%H:%M') + 3600   # %H: 00..23, 23 should represent the period 23:00-24:00, so add 1 hour to be the check point
        next if arrival_time_earliest > current_time
        ev_chargers.each do |ev_charger|
          if ev_charger.occupied
            if ev_charger.connected_ev.class.to_s != 'AddElectricVehicleChargingLoad::ElectricVehicle'
              runner.registerError("EV charger #{ev_charger.name.to_s} shows occupied, but no EV is connected.")
              return false
            end
            # disconnect EV if charged to full or till leave time. Only check if expected end time or leave is earlier than current time, otherwise check in next iteration.
            # Time addition uses seconds, so needs to multiple 3600
            if ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600 <= current_time || ev_charger.connected_ev.leave_time <= current_time
              if ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600 > ev_charger.connected_ev.leave_time
                ev_charger.occupied_until_time = ev_charger.connected_ev.leave_time
                ev_charger.connected_ev.end_charge_time = ev_charger.connected_ev.leave_time
              else
                ev_charger.occupied_until_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
                ev_charger.connected_ev.end_charge_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              end
              ev_charger.occupied = false
              ev_charger.connected_ev.has_been_charged = true
              ev_charger.connected_ev.connected_to_charger = false
              ev_charger.connected_ev = nil
            end
          end
          # continue to check if charger not occupied, then connect to an EV
          unless ev_charger.occupied
            next_ev_to_charge = nil
            wait_list_time_earliest = Time.strptime("23:00", '%H:%M') + 3600  # initial: 24:00
            ev_list.each do |this_ev|
              # skip this EV if it is being charged or is being charged or already left
              next if this_ev.has_been_charged
              next if this_ev.connected_to_charger
              next if this_ev.leave_time <= current_time
              # get the uncharged, earliest arrival EV (so front in wait list)
              if this_ev.arrival_time < wait_list_time_earliest
                wait_list_time_earliest = this_ev.arrival_time
                next_ev_to_charge = this_ev
              end
            end
            # skip if no EV is on the wait list
            next if next_ev_to_charge.nil?
            if ev_charger.charged_ev_list.empty?
              ev_charger.occupied_start_time = wait_list_time_earliest
              next_ev_to_charge.start_charge_time = wait_list_time_earliest
            else
              next_ev_to_charge.start_charge_time = ev_charger.occupied_until_time
            end
            ev_charger.occupied = true
            next_ev_to_charge.connected_to_charger = true
            ev_charger.connected_ev = next_ev_to_charge
            ev_charger.charged_ev_list << next_ev_to_charge
          end
        end
      end

      ev_sch = create_ev_sch(model, ev_chargers, max_charging_power, charge_on_sat, charge_on_sun)
      return ev_sch
    end

    def create_ev_sch_for_commercial_charge_station(model, ev_chargers, max_charging_power, num_evs, avg_arrival_time, arrival_time_variation_in_mins, avg_charge_hours, charge_time_variation_in_mins, charge_on_sat, charge_on_sun)
      ev_list = []
      for j in 1..num_evs
        ev = ElectricVehicle.new("ev_#{j.to_s}")
        ev.arrival_time = avg_arrival_time + rand(-arrival_time_variation_in_mins...arrival_time_variation_in_mins) * 60  # TODO make sure time format is working correctly, Ruby Times "+" adopts seconds
        ev.needed_charge_hours = avg_charge_hours + rand(-charge_time_variation_in_mins...charge_time_variation_in_mins) / 60.0   # +- variation minutes
        ev_list << ev
      end

      # find the earliest arrival time
      arrival_time_earliest = Time.strptime("23:00", '%H:%M') + 3600  # initial: 24:00
      ev_list.each do |this_ev|
        if this_ev.arrival_time < arrival_time_earliest
          arrival_time_earliest = this_ev.arrival_time
        end
      end

      # For workplace: iterate through time, check status of each charger, if vacant, find the EV that has the earliest arrival time within uncharged EVs.
      # if this EV's leaving time is later than the current time, start charging until fully charged or leaving time, whichever comes first
      # when no EV is found any more, charging on this day ends, conclude the charging profile
      # 23 represent 23:00-24:00, corresponding to E+ schedule Until: 24:00
      ev_sch_list = []
      for hour in 0..23
        current_time = Time.strptime("#{hour}:00", '%H:%M') + 3600   # %H: 00..23, 23 should represent the period 23:00-24:00, so add 1 hour to be the check point
        next if arrival_time_earliest > current_time
        ev_chargers.each do |ev_charger|
          if ev_charger.occupied
            if ev_charger.connected_ev.class.to_s != 'AddElectricVehicleChargingLoad::ElectricVehicle'
              runner.registerError("EV charger #{ev_charger.name.to_s} shows occupied, but no EV is connected.")
              return false
            end
            # disconnect EV if charged to full. Only check if expected end time is earlier than current time, otherwise check in next iteration.
            # Time addition uses seconds, so needs to multiple 3600
            if ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600 <= current_time
              ev_charger.occupied_until_time_list << ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              ev_charger.connected_ev.end_charge_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              ev_charger.occupied = false
              ev_charger.connected_ev.has_been_charged = true
              ev_charger.connected_ev.connected_to_charger = false
              ev_charger.connected_ev = nil
            end
          end
          # continue to check if charger not occupied, then connect to an EV
          unless ev_charger.occupied
            next_ev_to_charge = nil
            wait_list_time_earliest = Time.strptime("23:00", '%H:%M') + 3600  # initial: 24:00
            ev_list.each do |this_ev|
              # skip this EV if it is being charged or is being charged or already left
              next if this_ev.has_been_charged
              next if this_ev.connected_to_charger
              # get the uncharged, earliest arrival EV (so front in wait list)
              if this_ev.arrival_time < wait_list_time_earliest
                wait_list_time_earliest = this_ev.arrival_time
                next_ev_to_charge = this_ev
              end
            end
            # skip if no EV is on the wait list
            next if next_ev_to_charge.nil?
            if ev_charger.charged_ev_list.empty?
              ev_charger.occupied_start_time_list << wait_list_time_earliest
              next_ev_to_charge.start_charge_time = wait_list_time_earliest
            else
              if next_ev_to_charge.arrival_time < ev_charger.occupied_until_time_list[-1]
                next_ev_to_charge.start_charge_time = ev_charger.occupied_until_time_list[-1]
                ev_charger.occupied_start_time_list << ev_charger.occupied_until_time_list[-1]
              else
                next_ev_to_charge.start_charge_time = next_ev_to_charge.arrival_time
                ev_charger.occupied_start_time_list << next_ev_to_charge.arrival_time
              end
            end
            ev_charger.occupied = true
            next_ev_to_charge.connected_to_charger = true
            ev_charger.connected_ev = next_ev_to_charge
            ev_charger.charged_ev_list << next_ev_to_charge
          end
        end
      end

      ev_chargers.each do |ev_charger|
        # create schedule for each ev_charger
        # charger.charging_power
        ev_sch = create_ev_sch_single(model, ev_charger, charge_on_sat, charge_on_sun)
        ev_sch_list << ev_sch
      end

      # ev_sch = create_ev_sch(model, ev_chargers, max_charging_power, charge_on_sat, charge_on_sun)
      return ev_sch_list
    end


    def create_ev_sch_for_home(model, ev_chargers, max_charging_power, num_evs, start_charge_time, avg_charge_hours, charge_on_sat, charge_on_sun)
      ev_list = []
      for j in 1..num_evs
        ev = ElectricVehicle.new("ev_#{j.to_s}")
        ev.needed_charge_hours = avg_charge_hours + rand(-60...60) / 60.0   # +- 1 hour
        ev_list << ev
      end

      # for homes, EV charging could go overnight, so iterate 48 hours
      for hour in 0..47
        if hour <= 23
          current_time = Time.strptime("#{hour}:00", '%H:%M') + 3600   # %H: 00..23, 23 should represent the period 23:00-24:00, so add 1 hour to be the check point
        else
          current_time = Time.strptime("#{hour-24}:00", '%H:%M') + 24*60*60 + 3600   # %H: the second day (for overnight). still 00..23, 23 should represent the period 23:00-24:00, so add 1 hour to be the check point
        end
        next if start_charge_time > current_time
        ev_chargers.each do |ev_charger|
          if ev_charger.occupied
            if ev_charger.connected_ev.class.to_s != 'AddElectricVehicleChargingLoad::ElectricVehicle'
              runner.registerError("EV charger #{ev_charger.name.to_s} shows occupied, but no EV is connected.")
              return false
            end
            # Time addition uses seconds, so needs to multiple 3600
            if ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600 <= current_time
              ev_charger.connected_ev.end_charge_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              ev_charger.occupied_until_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              ev_charger.occupied = false
              ev_charger.connected_ev.has_been_charged = true
              ev_charger.connected_ev.connected_to_charger = false
              ev_charger.connected_ev = nil
            end
          end
          # continue to check if charger not occupied, then connect to an EV
          unless ev_charger.occupied
            # no need of waitlist, just connect to whichever EV that hasn't been charged
            next_ev_to_charge = nil
            ev_list.each do |this_ev|
              # skip this EV if it is being charged or is being charged
              next if this_ev.has_been_charged
              next if this_ev.connected_to_charger
              next_ev_to_charge = this_ev
              break
            end
            # skip if no EV is on the wait list
            next if next_ev_to_charge.nil?
            if ev_charger.charged_ev_list.empty?
              ev_charger.occupied_start_time = start_charge_time
              next_ev_to_charge.start_charge_time = start_charge_time
            else
              next_ev_to_charge.start_charge_time = ev_charger.occupied_until_time
            end
            ev_charger.occupied = true
            next_ev_to_charge.connected_to_charger = true
            ev_charger.connected_ev = next_ev_to_charge
            ev_charger.charged_ev_list << next_ev_to_charge
          end
        end
      end

      ev_sch = create_ev_sch(model, ev_chargers, max_charging_power, charge_on_sat, charge_on_sun)
      return ev_sch
    end

    # create EV load schedule (normalized)
    case bldg_use_type
    when 'workplace'
      ev_sch = create_ev_sch_for_workplace(model, ev_chargers, max_charging_power, num_evs, avg_arrival_time, arrival_time_variation_in_mins, avg_leave_time, avg_charge_hours, charge_time_variation_in_mins, charge_on_sat, charge_on_sun)
    when 'home'
      ev_sch = create_ev_sch_for_home(model, ev_chargers, max_charging_power, num_evs, start_charge_time, avg_charge_hours, charge_on_sat, charge_on_sun)
    when 'commercial station'
      ev_sch_list = create_ev_sch_for_commercial_charge_station(model, ev_chargers, max_charging_power, num_evs, avg_arrival_time, arrival_time_variation_in_mins, avg_charge_hours, charge_time_variation_in_mins, charge_on_sat, charge_on_sun)
    end

    case bldg_use_type
    when 'workplace', 'home'
      # Adding an EV charger definition and instance for the regular EV charging.
      ev_charger_def = OpenStudio::Model::ExteriorFuelEquipmentDefinition.new(model)
      ev_charger_level = (max_charging_power * 1000).round(0) # Converting from kW to watts
      ev_charger_def.setName("#{ev_charger_level}w EV Charging Definition")
      ev_charger_def.setDesignLevel(ev_charger_level)

      # creating EV charger object for the regular EV charging.
      ev_charger = OpenStudio::Model::ExteriorFuelEquipment.new(ev_charger_def, ev_sch)
      ev_charger.setName("#{ev_charger_level}w EV Charger")
      ev_charger.setFuelType('Electricity')
      ev_charger.setEndUseSubcategory('Electric Vehicles')
    when 'commercial station'
      ev_chargers.each_with_index do |ev_charger, idx|
        # Adding an EV charger definition and instance for the regular EV charging.
        ev_charger_def = OpenStudio::Model::ExteriorFuelEquipmentDefinition.new(model)
        ev_charger_level = (ev_charger.charging_power * 1000).round(0)  # Converting from kW to watts
        ev_charger_def.setName("#{ev_charger_level}w EV Charging Definition")
        ev_charger_def.setDesignLevel(ev_charger_level)

        # creating EV charger object for the regular EV charging.
        ev_charger = OpenStudio::Model::ExteriorFuelEquipment.new(ev_charger_def, ev_sch_list[idx])
        ev_charger.setName("#{ev_charger_level}w EV Charger")
        ev_charger.setFuelType('Electricity')
        ev_charger.setEndUseSubcategory('Electric Vehicles')
      end

    end


    runner.registerInfo("multiplier (kW) = #{max_charging_power}}")

    # echo the new space's name back to the user
    runner.registerInfo("EV load with #{num_ev_chargers} EV chargers and #{num_evs} EVs was added.")

    # report final condition of model
    runner.registerFinalCondition("The building completed adding EV load.")

    return true
  end
end

# register the measure to be used by the application
AddElectricVehicleChargingLoad.new.registerWithApplication
