# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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

# Measure distributed under NREL Copyright terms, see LICENSE.md file.

# Author: Karl Heine
# Date: December 2019 - March 2020

# References:
# EnergyPlus InputOutput Reference, Sections:
# EnergyPlus Engineering Reference, Sections:

# start the measure
class AddHpwh < OpenStudio::Measure::ModelMeasure
  # require 'openstudio-standards'
  require '/Users/sky/.rvm/gems/ruby-2.7.2/gems/openstudio-standards-0.2.15/lib/openstudio-standards'
  puts "*"*250
  puts "in AddHpwh"
  puts $:

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    'Add HPWH for Domestic Hot Water'
  end

  # human readable description
  def description
    'This measure adds or replaces existing domestic hot water heater with air source heat pump system and ' \
           'allows for the addition of multiple daily flexible control time windows. The heater/tank system may ' \
           'charge at maximum capacity up to an elevated temperature, or float without any heat addition for a ' \
           'specified timeframe down to a minimum tank temperature.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure allows selection between three heat pump water heater modeling approaches in EnergyPlus.' \
           'The user may select between the pumped-condenser or wrapped-condenser objects. They may also elect to ' \
           'use a simplified calculation which does not use the heat pump objects, but instead used an electric ' \
           'resistance heater and approximates the equivalent electrical input that would be required from a heat ' \
           "pump. This expedites simulation at the expense of accuracy. \n" \
           'The flexibility of the system is based on user-defined temperatures and times, which are converted into ' \
           'schedule objects. There are four flexibility options. (1) None: normal operation of the DHW system at ' \
           'a fixed tank temperature setpoint. (2) Charge - Heat Pump: the tank is charged to a maximum temperature ' \
           'using only the heat pump. (3) Charge - Electric: the tank is charged using internal electric resistance ' \
           'heaters to a maximum temperature. (4) Float: all heating elements are turned-off for a user-defined time ' \
           'period unless the tank temperature falls below a minimum value. The heat pump will be prioritized in a ' \
           "low tank temperature event, with the electric resistance heaters serving as back-up. \n" \
          'Due to the heat pump interaction with zone conditioning as well as tank heating, users may experience ' \
          'simulation errors if the heat pump is too large and placed in an already conditioned zoned. Try using ' \
          'multiple smaller units, modifying the heat pump location within the model, or adjusting the zone thermo' \
          'stat constraints. Use mulitiple instances of the measure to add multiple heat pump water heaters. '
  end

  ## USER ARGS ---------------------------------------------------------------------------------------------------------
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # create argument for removal of existing water heater tanks on selected loop
    remove_wh = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_wh', true)
    remove_wh.setDisplayName('Remove existing water heater?')
    remove_wh.setDescription('')
    remove_wh.setDefaultValue(true)
    args << remove_wh

    # find available water heaters and get default volume
    default_vol = 80.0 # gallons
    wh_names = ['All Water Heaters (Simplified Only)']
    if !model.getWaterHeaterMixeds.empty?
      wheaters = model.getWaterHeaterMixeds
      wheaters.each do |w|
        if w.tankVolume.to_f > OpenStudio.convert(39, 'gal', 'm^3').to_f
          wh_names << w.name.to_s
          default_vol = [default_vol, (w.tankVolume.to_f / 0.0037854118).round(1)].max
        end
      end
    end

    wh = OpenStudio::Measure::OSArgument.makeChoiceArgument('wh', wh_names, true)
    wh.setDisplayName('Select 40+ gallon water heater to replace or augment')
    wh.setDescription("All can only be used with the 'Simplified' model")
    wh.setDefaultValue(wh_names[0])
    args << wh

    # create argument for hot water tank volume
    vol = OpenStudio::Measure::OSArgument.makeDoubleArgument('vol', false)
    vol.setDisplayName('Set hot water tank volume [gal]')
    vol.setDescription('Enter 0 to use existing tank volume(s). Values less than 5 are treated as sizing multipliers.')
    vol.setUnits('gal')
    vol.setDefaultValue(0)
    args << vol

    # create argument for water heater type
    type = OpenStudio::Measure::OSArgument.makeChoiceArgument('type',
                                                              ['Simplified', 'PumpedCondenser', 'WrappedCondenser'], true)
    type.setDisplayName('Select heat pump water heater type')
    type.setDescription('')
    type.setDefaultValue('PumpedCondenser')
    args << type

    # find available spaces for heater location
    zone_names = []
    unless model.getThermalZones.empty?
      zones = model.getThermalZones
      zones.each do |zn|
        zone_names << zn.name.to_s
      end
      zone_names.sort!
    end

    zone_names << 'Error: No Thermal Zones Found' if zone_names.empty?
    zone_names = ['N/A - Simplified'] + zone_names

    # create argument for thermal zone selection (location of water heater)
    zone_name = OpenStudio::Measure::OSArgument.makeChoiceArgument('zone_name', zone_names, true)
    zone_name.setDisplayName('Select thermal zone for HP evaporator')
    zone_name.setDescription("Does not apply to 'Simplified' cases")
    zone_name.setDefaultValue(zone_names[0])
    args << zone_name

    # create argument for heat pump capacity
    # The default heating capacity per gallon should come from the DOE prototype models,
    # smalloffice 40gal+11723, mediumoffice 100gal+29307 => 23446W/80gal
    cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('cap', true)
    cap.setDisplayName('Set heat pump heating capacity')
    cap.setDescription('[kW]')
    cap.setDefaultValue((23.446 * (default_vol / 80.0)).round(1))
    args << cap

    # create argument for heat pump rated cop
    cop = OpenStudio::Measure::OSArgument.makeDoubleArgument('cop', true)
    cop.setDisplayName('Set heat pump rated COP (heating)')
    cop.setDefaultValue(3.2)
    args << cop

    # create argument for electric backup capacity
    bu_cap = OpenStudio::Measure::OSArgument.makeDoubleArgument('bu_cap', true)
    bu_cap.setDisplayName('Set electric backup heating capacity')
    bu_cap.setDescription('[kW]')
    bu_cap.setDefaultValue((23.446 * (default_vol / 80.0)).round(1))
    args << bu_cap

    # create argument for maximum tank temperature
    max_temp = OpenStudio::Measure::OSArgument.makeDoubleArgument('max_temp', true)
    max_temp.setDisplayName('Set maximum tank temperature')
    max_temp.setDescription('[F]')
    max_temp.setDefaultValue(160)
    args << max_temp

    # create argument for minimum float temperature
    min_temp = OpenStudio::Measure::OSArgument.makeDoubleArgument('min_temp', true)
    min_temp.setDisplayName('Set minimum tank temperature during float')
    min_temp.setDescription('[F]')
    min_temp.setDefaultValue(120)
    args << min_temp

    # create argument for deadband temperature difference between heat pump setpoint and electric backup
    db_temp = OpenStudio::Measure::OSArgument.makeDoubleArgument('db_temp', true)
    db_temp.setDisplayName('Set deadband temperature difference between heat pump and electric backup')
    db_temp.setDescription('[F]')
    db_temp.setDefaultValue(5)
    args << db_temp

    # find existing temperature setpoint schedules for water heater
    all_scheds = model.getSchedules
    temp_sched_names = []
    default_sched = '--Create New @ 140F--'
    default_ambient = ''
    all_scheds.each do |sch|
      next if sch.scheduleTypeLimits.empty?
      next unless sch.scheduleTypeLimits.get.unitType.to_s == 'Temperature'

      temp_sched_names << sch.name.to_s
      if !wheaters.empty? && (sch.name.to_s == wheaters[0].setpointTemperatureSchedule.get.name.to_s)
        default_sched = sch.name.to_s
      end
    end
    temp_sched_names = [default_sched] + temp_sched_names.sort

    # create argument for predefined schedule
    sched = OpenStudio::Measure::OSArgument.makeChoiceArgument('sched', ['Use Existing Setpoint Schedule', '--Create New @ 140F--'], true)
    sched.setDisplayName('Select reference tank setpoint temperature schedule')
    sched.setDescription('')
    sched.setDefaultValue('Use Existing Setpoint Schedule')
    args << sched

    # this is usually not used in this measure in the GEB gem, there is a separate measure called "Adjust_DHW_setpoint" to set flexible schedules
    # TODO for "Adjust_DHW_setpoint":
    # if heat pump water heater, make sure to not use the supplemental heating method in the tank (set the HPWH cut-in:setpoint-deadband always higher than tank setpoint)

    # define possible flex options
    flex_options = ['None', 'Charge - Heat Pump', 'Charge - Electric', 'Float']

    # create choice and string arguments for flex periods
    4.times do |n|
      flex = OpenStudio::Measure::OSArgument.makeChoiceArgument("flex#{n}", flex_options, true)
      flex.setDisplayName("Daily Flex Period #{n + 1}:")
      flex.setDescription('Applies every day in the full run period.')
      flex.setDefaultValue('None')
      args << flex

      flex_hrs = OpenStudio::Measure::OSArgument.makeStringArgument("flex_hrs#{n}", false)
      flex_hrs.setDisplayName('Use 24-Hour Format')
      flex_hrs.setDefaultValue('HH:MM - HH:MM')
      args << flex_hrs
    end

    args
  end
  ## END USER ARGS -----------------------------------------------------------------------------------------------------

  ## MEASURE RUN -------------------------------------------------------------------------------------------------------
  # Index:
  # => Argument Validation
  # => Controls: Heat Pump Heating Shedule
  # => Controls: Tank Electric Backup Heating Schedule
  # => Hardware
  # => Controls Modifications for Tank
  # => Report Output Variables

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    ## ARGUMENT VALIDATION ---------------------------------------------------------------------------------------------
    # Measure does not immedately return false upon error detection. Errors are accumulated throughout this selection
    # before exiting gracefully prior to measure execution.

    # use the built-in error checking
    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # report initial condition of model
    tanks_ic = model.getWaterHeaterMixeds.size + model.getWaterHeaterStratifieds.size
    hpwh_ic = model.getWaterHeaterHeatPumps.size + model.getWaterHeaterHeatPumpWrappedCondensers.size
    runner.registerInitialCondition("The building started with #{tanks_ic} water heater tank(s) and " \
                                    "#{hpwh_ic} heat pump water heater(s).")

    # create empty arrays and initialize variables for future use
    flex = []
    flex_type = []
    flex_hrs = []
    time_check = []
    hours = []
    minutes = []
    flex_times = []

    # assign the user inputs to variables
    remove_wh = runner.getBoolArgumentValue('remove_wh', user_arguments)
    wh = runner.getStringArgumentValue('wh', user_arguments)
    vol = runner.getDoubleArgumentValue('vol', user_arguments)
    type = runner.getStringArgumentValue('type', user_arguments)
    zone_name = runner.getStringArgumentValue('zone_name', user_arguments)
    cap = runner.getDoubleArgumentValue('cap', user_arguments)
    cop = runner.getDoubleArgumentValue('cop', user_arguments)
    bu_cap = runner.getDoubleArgumentValue('bu_cap', user_arguments)
    max_temp = runner.getDoubleArgumentValue('max_temp', user_arguments)
    min_temp = runner.getDoubleArgumentValue('min_temp', user_arguments)
    db_temp = runner.getDoubleArgumentValue('db_temp', user_arguments)
    sched = runner.getStringArgumentValue('sched', user_arguments)

    4.times do |n|
      flex << runner.getStringArgumentValue("flex#{n}", user_arguments)
      flex_hrs << runner.getStringArgumentValue("flex_hrs#{n}", user_arguments)
    end

    # check for existence of water heaters (if "all" is selected)
    if model.getWaterHeaterMixeds.empty?
      runner.registerError('No water heaters found in the model')
      return false
    end

    # Alert user to "simplified" selection
    if type == 'Simplified'
      runner.registerInfo('NOTE: The simplified model is used, so heat pump objects are not employed.')
    end

    # check capacity, volume, and temps for reasonableness
    if cap < 5
      runner.registerWarning('HPWH heating capacity is less than 5kW ( 17kBtu/hr)')
    end

    if bu_cap < 5
      runner.registerWarning('Backup heating capaicty is less than 5kW ( 17kBtu/hr).')
    end

    if vol == 0
      runner.registerInfo('Tank volume was not specified, using existing tank capacity.')
    elsif vol < 40
      runner.registerWarning('Tank has less than 40 gallon capacity; check heat pump sizing if model fails.')
    end

    if min_temp < 120
      runner.registerWarning('Minimum tank temperature is very low; consider increasing to at least 120F.')
      runner.registerWarning('Do not store water for long periods at temperatures below 135-140F as those ' \
                            'conditions facilitate the growth of Legionella.')
    end

    if max_temp > 185
      runner.registerWarning('Maximum charging temperature exceeded practical limits; reset to 185F.')
      max_temp = 185.0
    end

    if max_temp > 170
      runner.registerWarning("#{max_temp}F is above or near the limit of the HP performance curves. If the " \
                            'simulation fails with cooling capacity less than 0, you have exceeded performance ' \
                            'limits. Consider setting max temp to less than 170F.')
    end

    # check selected schedule and set flag for later use
    sched_flag = false # flag for either creating new (false) or modifying existing (true) schedule
    if sched == '--Create New @ 140F--'
      runner.registerInfo('No reference water heater temperature setpoint schedule was selected; a new one ' \
                          'will be created.')
    else
      sched_flag = true
      runner.registerInfo("#{sched} will be used as the water heater temperature setpoint schedule.")
    end

    # parse flex_hrs into hours and minuts arrays ('HH:MM - HH:MM')
    idx = 0
    flex_hrs.each do |fh|
      if flex[idx] != 'None'
        data = fh.split(/[-:]/)
        data.each { |e| e.delete!(' ') }
        if data[2] > data[0]
          flex_type << flex[idx]
          hours << data[0]
          hours << data[2]
          minutes << data[1]
          minutes << data[3]
        else
          flex_type << flex[idx]
          flex_type << flex[idx]
          hours << 0
          hours << data[2]
          hours << data[0]
          hours << 24
          minutes << 0
          minutes << data[3]
          minutes << data[1]
          minutes << 0
        end
      end
      idx += 1
    end

    # convert hours and minutes into OS:Time objects
    idx = 0
    hours.each do |h|
      flex_times << OpenStudio::Time.new(0, h.to_i, minutes[idx].to_i, 0)
      idx += 1
    end

    # flex.delete('None')

    runner.registerInfo("A total of #{idx / 2} flex periods will be added to the selected water heater setpoint schedule.")

    # exit gracefully if errors registered above
    return false unless runner.result.errors.empty?

    puts "*"*150
    puts "add_hpwh before adding"
    puts "water heater mixed: "
    model.getWaterHeaterMixeds.each do |wh|
      puts wh.name.to_s
    end

    ## END ARGUMENT VALIDATION -----------------------------------------------------------------------------------------

    ## CONTROLS: HEAT PUMP HEATING TEMPERATURE SETPOINT SCHEDULE -------------------------------------------------------
    # This section creates the heat pump heating temperature setpoint schedule with flex periods
    # The tank schedule is created here, Tank schedule could be universally new

    # tank_sched = sched.clone.to_ScheduleRuleset.get
    tank_sched = OpenStudio::Model::ScheduleRuleset.new(model, 60 - (db_temp / 1.8 + 2))
    tank_sched.setName('Tank Electric Heater Setpoint')
    tank_sched.defaultDaySchedule.setName('Tank Electric Heater Setpoint Default')

    ## CONTROLS: TANK TEMPERATURE SETPOINT SCHEDULE (ELECTRIC BACKUP) --------------------------------------------------
    # This section creates the setpoint temperature schedule for the electric backup heating coils in the water tank

    # grab default day and time-value pairs for modification
    d_day = tank_sched.defaultDaySchedule
    old_times = d_day.times
    old_values = d_day.values
    new_values = Array.new(flex_times.size, 2)

    # find existing values in reference schedule and grab for use in new-rule creation
    flex_times.size.times do |i|
      if i.even?
        n = 0
        old_times.each do |ot|
          # this line (below) is not right, will only get the last value all the time because flex_times will always be no greater than the last time
          # new_values[i] = old_values[n] if flex_times[i] <= ot
          if flex_times[i] <= ot
            new_values[i] = old_values[n]
            break
          end
          n += 1
        end
      elsif flex_type[(i / 2).floor] == 'Charge - Electric'
        new_values[i] = OpenStudio.convert(max_temp, 'F', 'C').get
      elsif flex_type[(i / 2).floor] == 'Float' || flex_type[(i/2).floor] == 'Charge - Heat Pump'  # this make sure tank supplemental heating is not used
        new_values[i] = OpenStudio.convert(min_temp - db_temp, 'F', 'C').get
      # elsif flex_type[(i / 2).floor] == 'Charge - Heat Pump'
      #   new_values[i] = 60 - (db_temp / 1.8)
      end
    end

    # create new rules and add to default day based on flex period options above
    idx = 0
    flex_times.each do |ft|
      d_day.addValue(ft, new_values[idx])
      idx += 1
    end

    ## END CONTROLS: TANK TEMPERATURE SETPOINT SCHEDULE (ELECTRIC BACKUP) ----------------------------------------------

    ## HARDWARE --------------------------------------------------------------------------------------------------------
    # This section adds the selected type of heat pump water heater to the supply side of the selected loop. If
    # selected, measure will remove any existing water heaters on the supply side of the loop. If old heater(s) are left
    # in place, the new HPWH tank will be placed in front (to the left) of them.

    # use OS standards build - arbitrary selection, but NZE Ready seems appropriate
    std = Standard.build('NREL ZNE Ready 2017')

    #####
    # get the selected water heaters
    whtrs = []
    model.getWaterHeaterMixeds.each do |w|
      case wh
      when 'All Water Heaters (Simplified Only)'
        # exclude booster tanks (<10gal):
        if w.tankVolume.to_f < 0.037854
          next
        else
          whtrs << w
        end
      when w.name.to_s
        whtrs << w
      end
    end

    whtrs.each do |whtr|
      # create empty arrays and initialize variables for later use
      old_heater = []
      count = 0

      # get the appropriate plant loop
      loop = ''
      loops = model.getPlantLoops
      loops.each do |l|
        l.supplyComponents.each do |c|
          if c.name.to_s == whtr.name.to_s
            loop = l
          end
        end
      end

      # use existing tank volume unless otherwise specified
      # values between 0.0 and 5.0 are considered tank sizing multipliers
      if vol == 0
        v = whtr.tankVolume.get
      elsif (vol > 0.0) && (vol < 5.0)
        v = whtr.tankVolume.to_f * vol
      else
        v = OpenStudio.convert(vol, 'gal', 'm^3').get
      end
      # update the cap based on volume (v * 264.172: m3 => gal)
      # The default heating capacity per gallon should come from the DOE prototype models,
      # smalloffice 40gal+11723, mediumoffice 100gal+29307 => 23446W/80gal
      cap = (23.446 * (v * 264.172 / 80.0)).round(1)
      bu_cap = cap

      # grab existing water heater setpoint schedule if needed
      # find or create new reference temperature schedule based on sched_flag value
      if sched_flag # schedule already exists and must be modified
        sched = whtr.setpointTemperatureSchedule.get.clone.to_ScheduleRuleset.get
      else
        # must create new water heater setpoint temperature schedule at 140F
        sched = OpenStudio::Model::ScheduleRuleset.new(model, 60)
      end

      # rename and duplicate for later modification
      sched.setName('Heat Pump Heating Temperature Setpoint')
      sched.defaultDaySchedule.setName('Heat Pump Heating Temperature Setpoint Default')

      # grab default day and time-value pairs for modification
      d_day = sched.defaultDaySchedule

      # Fix the original setpoint schedule first, make sure the HPWH setpoint doesn't exceed 170C
      d_day.times.each_with_index do |time, idx|
        if d_day.values[idx] > OpenStudio.convert(max_temp, 'F', 'C').get
          d_day.addValue(time, OpenStudio.convert(max_temp, 'F', 'C').get)
        end
      end

      old_times = d_day.times
      old_values = d_day.values
      new_values = Array.new(flex_times.size, 2)

      puts "old_values: #{old_values}"

      # find existing values in reference schedule and grab for use in new-rule creation
      flex_times.size.times do |i|
        if i.even?
          n = 0
          old_times.each do |ot|
            # this line (below) is not right, will only get the last value all the time because flex_times will always be no greater than the last time
            # new_values[i] = old_values[n] if flex_times[i] <= ot
            if flex_times[i] <= ot
              new_values[i] = old_values[n]
              break
            end
            n += 1
          end
        elsif flex_type[(i / 2).floor] == 'Charge - Heat Pump'
          new_values[i] = OpenStudio.convert(max_temp, 'F', 'C').get
        elsif flex_type[(i / 2).floor] == 'Float' || flex_type[(i / 2).floor] == 'Charge - Electric'
          new_values[i] = OpenStudio.convert(min_temp, 'F', 'C').get
        end
      end

      puts "new_values: #{new_values.inspect}"

      # create new rules and add to default day based on flex period options above
      idx = 0
      flex_times.each do |ft|
        d_day.addValue(ft, new_values[idx])
        idx += 1
      end

      inlet = whtr.supplyInletModelObject.get.to_Node.get
      outlet = whtr.supplyOutletModelObject.get.to_Node.get

      puts "*"*150
      puts "water heater mixed: "
      model.getWaterHeaterMixeds.each do |wh|
        puts wh.name.to_s
      end

      # Add heat pump water heater and attach to selected loop
      # Reference: https://github.com/NREL/openstudio-standards/blob/master/lib/
      # => openstudio-standards/prototypes/common/objects/Prototype.ServiceWaterHeating.rb
      if type != 'Simplified'
        # convert zone name from STRING into OS model OBJECT
        if zone_name == 'N/A - Simplified'
          if whtr.ambientTemperatureThermalZone.empty?
            zone = model.getThermalZones[0]
          else
            zone = whtr.ambientTemperatureThermalZone.get
          end
        else
          zone = model.getThermalZoneByName(zone_name).get
        end

        hpwh = std.model_add_heatpump_water_heater(model, # model
                                                   type: type,                                                           # type
                                                   water_heater_capacity: (cap * 1000 / cop),                            # water_heater_capacity
                                                   electric_backup_capacity: (bu_cap * 1000),                            # electric_backup_capacity
                                                   water_heater_volume: v,                                               # water_heater_volume
                                                   service_water_temperature: OpenStudio.convert(140.0, 'F', 'C').get,   # service_water_temperature
                                                   parasitic_fuel_consumption_rate: 3.0,                                 # parasitic_fuel_consumption_rate
                                                   swh_temp_sch: sched,                                                  # swh_temp_sch
                                                   cop: cop,                                                             # cop
                                                   shr: 0.88,                                                            # shr
                                                   tank_ua: 3.9,                                                         # tank_ua
                                                   set_peak_use_flowrate: false,                                         # set_peak_use_flowrate
                                                   peak_flowrate: 0.0,                                                   # peak_flowrate
                                                   flowrate_schedule: nil,                                               # flowrate_schedule
                                                   water_heater_thermal_zone: zone)                                      # water_heater_thermal_zone
      else
        # zone = whtr.ambientTemperatureThermalZone.get
        hpwh = std.model_add_water_heater(model, # model
                                          (cap * 1000),                                                         # water_heater_capacity
                                          v.to_f,                                                               # water_heater_volume
                                          'HeatPump',                                                           # water_heater_fuel
                                          OpenStudio.convert(140.0, 'F', 'C').to_f,                             # service_water_temperature
                                          3.0,                                                                  # parasitic_fuel_consumption_rate
                                          sched,                                                                # swh_temp_sch
                                          false,                                                                # set_peak_use_flowrate
                                          0.0,                                                                  # peak_flowrate
                                          nil,                                                                  # flowrate_schedule
                                          model.getThermalZones[0], # water_heater_thermal_zone
                                          1) # number_water_heaters
        # set COP in PLF curve
        cop_curve = hpwh.partLoadFactorCurve.get
        cop_curve.setName(cop_curve.name.get.gsub('2.8', cop.to_s))
        cop_curve.setCoefficient1Constant(cop)
      end

      puts "*"*150
      puts "water heater mixed: "
      model.getWaterHeaterMixeds.each do |wh|
        puts wh.name.to_s
      end

      # add tank to appropriate branch and node (will be placed first in series if old tanks not removed)
      # modify objects as ncessary
      if type != 'Simplified'
        hpwh.tank.addToNode(inlet)
        hpwh.setDeadBandTemperatureDifference(db_temp / 1.8)
        runner.registerInfo("#{hpwh.tank.name} was added to the model on #{loop.name}")
      else
        hpwh.addToNode(inlet)
        hpwh.setMaximumTemperatureLimit(OpenStudio.convert(max_temp, 'F', 'C').get)
        runner.registerInfo("#{hpwh.name} was added to the model on #{loop.name}")
      end

      # remove old tank objects if necessary
      if remove_wh
        runner.registerInfo("#{whtr.name} was removed from the model.")
        whtr.remove
      end

      # CONTROLS MODIFICATIONS FOR TANK ---------------------------------------------------------------------------------
      # apply schedule to tank
      case type
      when 'PumpedCondenser'
        hpwh.tank.to_WaterHeaterMixed.get.setSetpointTemperatureSchedule(tank_sched)
      when 'WrappedCondenser'
        hpwh.tank.to_WaterHeaterStratified.get.setHeater1SetpointTemperatureSchedule(tank_sched)
        hpwh.tank.to_WaterHeaterStratified.get.setHeater2SetpointTemperatureSchedule(tank_sched)
      end
      # END CONTROLS MODIFICATIONS FOR TANK -----------------------------------------------------------------------------
    end
    ## END HARDWARE ----------------------------------------------------------------------------------------------------

    ## ADD REPORTED VARIABLES ------------------------------------------------------------------------------------------

    ovar_names = ['Cooling Coil Total Cooling Rate',
                  'Cooling Coil Total Water Heating Rate',
                  'Cooling Coil Water Heating Electric Power',
                  'Cooling Coil Crankcase Heater Electric Power',
                  'Water Heater Tank Temperature',
                  'Water Heater Heat Loss Rate',
                  'Water Heater Heating Rate',
                  'Water Heater Use Side Heat Transfer Rate',
                  'Water Heater Source Side Heat Transfer Rate',
                  'Water Heater Unmet Demand Heat Transfer Rate',
                  'Water Heater Electricity Rate',
                  'Water Heater Water Volume Flow Rate',
                  'Water Use Connections Hot Water Temperature']

    # Create new output variable objects
    ovars = []
    ovar_names.each do |nm|
      ovars << OpenStudio::Model::OutputVariable.new(nm, model)
    end

    # add temperate schedule outputs - clean up and put names into array, then loop over setting key values
    v = OpenStudio::Model::OutputVariable.new('Schedule Value', model)
    v.setKeyValue(sched.name.to_s)
    ovars << v

    v = OpenStudio::Model::OutputVariable.new('Schedule Value', model)
    v.setKeyValue(tank_sched.name.to_s)
    ovars << v

    # if type != 'Simplified'
    #   v = OpenStudio::Model::OutputVariable.new('Schedule Value', model)
    #   v.setKeyValue(tank_sched.name.to_s)
    #   ovars << v
    # end

    # Set variable reporting frequency for newly created output variables
    ovars.each do |var|
      var.setReportingFrequency('TimeStep')
    end

    # Register info re: output variables:
    runner.registerInfo("#{ovars.size} output variables were added to the model.")
    ## END ADD REPORTED VARIABLES --------------------------------------------------------------------------------------

    # Register final condition
    hpwh_fc = model.getWaterHeaterHeatPumps.size + model.getWaterHeaterHeatPumpWrappedCondensers.size
    tanks_fc = model.getWaterHeaterMixeds.size + model.getWaterHeaterStratifieds.size
    if type != 'Simplified'
      runner.registerFinalCondition("The building finshed with #{tanks_fc} water heater tank(s) and " \
                                  "#{hpwh_fc} heat pump water heater(s).")
    else
      runner.registerFinalCondition("The building finished with #{tanks_fc - whtrs.size} water heater tank(s) " \
                                  "and #{whtrs.size} heat pump water heater(s).")
    end

    true
  end
end

# register the measure to be used by the application
AddHpwh.new.registerWithApplication
