# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AdjustDHWSetpoint < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Adjust DHW setpoint'
  end

  # human readable description
  def description
    return 'This measure adjusts the water heating setpoint for the domestic hot water system during up to four periods.'\
            ' For heat pump water heater, this measure will also monitor and adjust the water tank setpoint as needed to make sure '\
            'the tank setpoint is no higher than the HPWH cut-in temperature .'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure adds flexibility to the DHW system by allowing users to input up to four flexible control periods.'\
            ' The setpoint can be input by setback degrees or absolute temperature values. For all types of water heaters, '\
            'the water heating setpoint can be adjusted. For heat pump water heater, the water tank setpoint will also be '\
            'monitored and adjusted to make sure the tank setpoint is no higher than the HPWH cut-in temperature.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # create argument for setpoint adjust input method
    stp_adj_method = OpenStudio::Measure::OSArgument.makeChoiceArgument('stp_adj_method', ['By Setback Degree', 'By Absolute Temperature'], true)
    stp_adj_method.setDisplayName('Select Setpoint Adjust Input Method')
    stp_adj_method.setDefaultValue('By Absolute Temperature')
    args << stp_adj_method

    # create choice and string arguments for flex periods
    4.times do |n|
      flex_hrs = OpenStudio::Measure::OSArgument.makeStringArgument("flex_hrs_#{n+1}", false)
      flex_hrs.setDisplayName("Daily Flex Period #{n + 1}:")
      flex_hrs.setDescription('Use 24-Hour Format')
      flex_hrs.setDefaultValue('HH:MM - HH:MM')
      args << flex_hrs

      flex_stp = OpenStudio::Measure::OSArgument.makeDoubleArgument("flex_stp_#{n+1}", true)
      flex_stp.setDisplayName("Daily Flex Period #{n + 1} setpoint (or setback degree) in Degrees Fahrenheit:")
      flex_stp.setDescription('Applies every day in the full run period.')
      flex_stp.setDefaultValue(0)
      args << flex_stp
    end

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    flex_stps_orin = []
    flex_stps = []
    flex_hrs = []
    hours = []
    minutes = []
    flex_times = []

    # assign the user inputs to variables
    stp_adj_method = runner.getStringArgumentValue('stp_adj_method', user_arguments)
    4.times do |n|
      flex_stps_orin << runner.getDoubleArgumentValue("flex_stp_#{n+1}", user_arguments)
      flex_hrs << runner.getStringArgumentValue("flex_hrs_#{n+1}", user_arguments)
    end

    # parse flex_hrs into hours and minuts arrays ('HH:MM - HH:MM')
    flex_hrs.each_with_index do |fh, idx|
      if flex_stps_orin[idx] != 0
        data = fh.split(/[-:]/)
        data.each { |e| e.delete!(' ') }
        puts "data: #{data}"
        if data[2].to_f > data[0].to_f
          flex_stps << flex_stps_orin[idx]
          hours << data[0]
          hours << data[2]
          minutes << data[1]
          minutes << data[3]
        else
          flex_stps << flex_stps_orin[idx]
          flex_stps << flex_stps_orin[idx]
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
    end

    # convert hours and minutes into OS:Time objects
    hours.each_with_index do |h, idx|
      flex_times << OpenStudio::Time.new(0, h.to_i, minutes[idx].to_i, 0)
    end

    # get setpoint adjust method
    stp_adj_setback_flag = nil
    if stp_adj_method == 'By Setback Degree'
      runner.registerInfo('Use setback degree to adjust water heating setpoint.' )
      stp_adj_setback_flag = true
    elsif stp_adj_method == 'By Absolute Temperature'
      runner.registerInfo('Use absolute temperature to adjust water heating setpoint.' )
      stp_adj_setback_flag = false
    else
      runner.registerError("Wrong input. Setpoint adjust method can only be 'By Setback Degree' or 'By Absolute Temperature'.")
    end

    if stp_adj_setback_flag
      flex_stps.each do |flex_stp|
        if flex_stp < 0
          runner.registerWarning('At least one setpoint setback degree is input as negative value, the setpoint will actually be increased.')
        end
      end
    else
      flex_stps.each_with_index do |flex_stp, idx|
        if flex_stp > 185
          runner.registerWarning("Setpoint #{flex_stp}F exceeded practical limits; reset to 185F. "\
                                  "For HPWH, 185F is above or near the limit of the HP performance curves. If the " \
                                  "simulation fails with cooling capacity less than 0, you have exceeded performance " \
                                  "limits. Consider setting max temp to less than 170F.")
          flex_stps[idx] = 185.0
        elsif flex_stp > 170
          runner.registerWarning("#{flex_stp}F is above or near the limit of the HP performance curves. If the " \
                            'simulation fails with cooling capacity less than 0, you have exceeded performance ' \
                            'limits. Consider setting max temp to less than 170F.')
        end
      end
    end

    def update_new_sch(new_sch, flex_times, flex_stps, stp_adj_setback_flag)
      # grab default day and time-value pairs for modification
      d_day = new_sch.defaultDaySchedule
      old_times = d_day.times
      old_values = d_day.values
      old_times_to_del = []
      new_values = Array.new(flex_times.size, 2)

      # find existing values in reference schedule and grab for use in new-rule creation
      flex_times.size.times do |i|
        if i.even?
          # get the sch value for start time in the flex time period, from old schedule.
          old_times.each_with_index do |ot, j|
            if flex_times[i] <= ot
              new_values[i] = old_values[j]
              break
            end
          end
          # if the flex time period spans any existing time point, remove them from old schedule.
          old_times.each_with_index do |ot, j|
            if flex_times[i] <= ot && flex_times[i+1] > ot
              old_times_to_del << ot
            end
          end
        else
          if stp_adj_setback_flag
            new_values[i] = new_values[i-1] - flex_stps[(i/2).floor]/1.8
          else
            new_values[i] = OpenStudio.convert(flex_stps[(i/2).floor], 'F', 'C').get
          end
        end
      end

      # clean up: if the start of each time pair overlaps with the end of other time pair, remove this pair
      ft_with_new_value = []
      idx_to_del = []
      flex_times.each_with_index do |ft, idx|
        ft_with_new_value << ft if idx.odd?
      end
      flex_times.each_with_index do |ft, idx|
        if idx.even? && (ft_with_new_value.include?ft)
          idx_to_del << idx
        end
      end
      flex_times_clean = flex_times.reject.with_index {|x,i| idx_to_del.include?i}
      new_values_clean = new_values.reject.with_index {|x,i| idx_to_del.include?i}

      # create new rules and add to default day based on flex period options above
      idx = 0
      flex_times_clean.each do |ft|
        d_day.addValue(ft, new_values_clean[idx])
        idx += 1
      end
      old_times_to_del.each do |ot|
        d_day.removeValue(ot)
      end

      return new_sch
    end

    def update_new_sch_offset(new_sch, offset)
      # grab default day and time-value pairs for modification
      d_day = new_sch.defaultDaySchedule
      old_times = d_day.times
      old_values = d_day.values

      old_times.each_with_index do |ot, idx|
        d_day.addValue(ot, old_values[idx] - offset)
      end

      return new_sch
    end

    # report initial condition of model
    tanks_ic = model.getWaterHeaterMixeds.size + model.getWaterHeaterStratifieds.size
    hpwh_ic = model.getWaterHeaterHeatPumps.size + model.getWaterHeaterHeatPumpWrappedCondensers.size
    runner.registerInitialCondition("The building started with #{tanks_ic} water heater tank(s) and " \
                                    "#{hpwh_ic} heat pump water heater(s).")

    # search for heat pump water heater first, if no HPWH, change the setpoint of WaterHeater:Mixed
    hpwhs = model.getWaterHeaterHeatPumps + model.getWaterHeaterHeatPumpWrappedCondensers
    if hpwhs.empty?  # no HPWH in the model
      model.getWaterHeaterMixeds.each do |wh_mix|
        new_sch = wh_mix.setpointTemperatureSchedule.get.clone.to_ScheduleRuleset.get

        # rename and duplicate for later modification
        new_sch.setName('Water Heater Heating Temperature Setpoint adjusted')
        new_sch.defaultDaySchedule.setName('Water Heater Heating Temperature Setpoint adjusted Default')
        new_sch = update_new_sch(new_sch, flex_times, flex_stps, stp_adj_setback_flag)

        wh_mix.setSetpointTemperatureSchedule(new_sch)
      end
    else
      hpwhs.each do |hpwh|
        # first update the setpoint of the HPWH itself
        new_sch = hpwh.compressorSetpointTemperatureSchedule.clone.to_ScheduleRuleset.get
        puts "new_sch: #{new_sch}"
        # new_sch = hpwh.compressorSetpointTemperatureSchedule.clone.to_ScheduleRuleset.get

        # rename and duplicate for later modification
        new_sch.setName('Heat Pump Water Heater Heating Temperature Setpoint adjusted')
        new_sch.defaultDaySchedule.setName('Heat Pump Water Heater Heating Temperature Setpoint adjusted Default')
        new_sch = update_new_sch(new_sch, flex_times, flex_stps, stp_adj_setback_flag)
        hpwh.setCompressorSetpointTemperatureSchedule(new_sch)

        # second update the setpoint of the associated tank
        tank_new_sch = new_sch.clone.to_ScheduleRuleset.get
        tank_new_sch.setName('Heat Pump Water Heater tank setpoint adjusted')
        tank_new_sch.defaultDaySchedule.setName('Heat Pump Water Heater tank setpoint adjusted Default')
        tank_new_sch = update_new_sch_offset(tank_new_sch, hpwh.deadBandTemperatureDifference)

        if !hpwh.tank.to_WaterHeaterMixed.empty?
          tank = hpwh.tank.to_WaterHeaterMixed.get
          tank.setSetpointTemperatureSchedule(tank_new_sch)
        elsif !hpwh.tank.to_WaterHeaterStratified.empty?
          tank = hpwh.tank.to_WaterHeaterStratified.get
          tank.setHeater1SetpointTemperatureSchedule(tank_new_sch)
          tank.setHeater2SetpointTemperatureSchedule(tank_new_sch)
        end

      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with updated setpoint schedule for #{tanks_ic} water heater tank(s) and " \
                                  "#{hpwh_ic} heat pump water heater(s).")

    return true
  end
end

# register the measure to be used by the application
AdjustDHWSetpoint.new.registerWithApplication
