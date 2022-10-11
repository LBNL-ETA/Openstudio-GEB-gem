# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
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

require 'json'
require 'openstudio-standards'
require 'yaml'
require 'date'
require 'matrix'
require 'time'

$J_to_KWH = OpenStudio.convert(1, 'J', 'kWh').get
$WH_to_KWH = OpenStudio.convert(1, 'Wh', 'kWh').get
$W_to_KW = OpenStudio.convert(1, 'W', 'kW').get
$M3S_to_CFM = OpenStudio.convert(1, 'm^3/s', 'cfm').get
$M3S_to_GPM = 15850.32314 # US Liquid volume flow rate conversion
$M3_to_GALLON = 264.172 # US Liquid volume flow rate conversion

module OsLib_Reporting
  # setup - get model, sql, and setup web assets path
  def self.setup(runner)
    results = {}

    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # get the last idf
    workspace = runner.lastEnergyPlusWorkspace
    if workspace.empty?
      runner.registerError('Cannot find last idf file.')
      return false
    end
    workspace = workspace.get

    # get the last sql file
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # populate hash to pass to measure
    results[:model] = model
    # results[:workspace] = workspace
    results[:sqlFile] = sqlFile

    return results
  end

  def self.ann_env_pd(sqlFile)
    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          ann_env_pd = env_pd
        end
      end
    end

    return ann_env_pd
  end

  def self.create_xls
    require 'rubyXL'
    book = ::RubyXL::Workbook.new

    # delete initial worksheet

    return book
  end

  def self.save_xls(book)
    file = book.write 'excel-file.xlsx'

    return file
  end

  # write an Excel file from table data
  # the Excel Functions are not currently being used, left in as example
  # Requires ruby Gem which isn't currently supported in OpenStudio GUIs.
  # Current setup is simple, creates new workbook for each table
  # Could be updated to have one section per workbook
  def self.write_xls(table_data, book)
    worksheet = book.add_worksheet table_data[:title]

    row_cnt = 0
    # write the header row
    header = table_data[:header]
    header.each_with_index do |h, i|
      worksheet.add_cell(row_cnt, i, h)
    end
    worksheet.change_row_fill(row_cnt, '0ba53d')

    # loop over data rows
    data = table_data[:data]
    data.each do |d|
      row_cnt += 1
      d.each_with_index do |c, i|
        worksheet.add_cell(row_cnt, i, c)
      end
    end

    return book
  end

  # cleanup - prep html and close sql
  def self.cleanup(html_in_path)
    # TODO: - would like to move code here, but couldn't get it working. May look at it again later on.

    return html_out_path
  end

  # clean up unkown strings used for runner.registerValue names
  def self.reg_val_string_prep(string)
    # replace non alpha-numberic characters with an underscore
    string = string.gsub(/[^0-9a-z]/i, '_')

    # snake case string
    string = OpenStudio.toUnderscoreCase(string)

    return string
  end

  ###########################################################
  # Utility functions
  ###########################################################
  def self.get_ts_by_var_key(runner, sqlFile, var_k_name, freq = 'Zone Timestep', get_datetime = false)
    hash_result = {}
    v_datetimes = []
    ann_env_pd = OsLib_Reporting.ann_env_pd(sqlFile)
    runner.registerInfo("= = =>Getting #{var_k_name} timeseries at #{freq} frequency from #{ann_env_pd}")
    if ann_env_pd
      keys = sqlFile.availableKeyValues(ann_env_pd, freq, var_k_name)
      # runner.registerInfo("Key length is #{keys.length}")
      keys.each do |key|
        # runner.registerInfo("SWH key = #{key}")
        output_timeseries = sqlFile.timeSeries(ann_env_pd, freq, var_k_name, key)
        if output_timeseries.is_initialized
          v_datetimes = output_timeseries.get.dateTimes
          output_timeseries = output_timeseries.get.values
        else
          runner.registerWarning("Didn't find data for #{var_k_name}")
        end
        v_temp = []
        for i in 0..(output_timeseries.size - 1)
          v_temp << output_timeseries[i]
        end
        hash_result[key] = v_temp
      end
    end
    if get_datetime
      return [hash_result, v_datetimes]
    else
      return hash_result
    end
  end

  def self.get_ts_by_var(runner, sqlFile, var_k_name, freq = 'Zone Timestep', get_datetime = false)
    # OsLib_Reporting.get_ts_by_var(runner, base_sqlFile, 'Facility Net Purchased Electricity Rate', 'Timestep')
    hash_result = {}
    v_datetimes = []
    ann_env_pd = OsLib_Reporting.ann_env_pd(sqlFile)
    puts "ann_env_pd: #{ann_env_pd.inspect}"
    puts "availableReportingFrequencies: #{sqlFile.availableReportingFrequencies(ann_env_pd)}"
    puts "availableTimeSeries: #{sqlFile.availableTimeSeries}"
    # puts "availableVariableNames: #{sqlFile.availableVariableNames(ann_env_pd, )}"
    runner.registerInfo("= = =>Getting #{var_k_name} timeseries at #{freq} frequency from #{ann_env_pd}")
    if ann_env_pd
      output_timeseries = sqlFile.timeSeries(ann_env_pd, freq, var_k_name)
      puts "output_timeseries: #{output_timeseries.inspect}"
      if output_timeseries.is_initialized
        v_datetimes = output_timeseries.get.dateTimes
        output_timeseries = output_timeseries.get.values
      else
        runner.registerWarning("Didn't find data for #{var_k_name}")
      end
      v_temp = []
      for i in 0..(output_timeseries.size - 1)
        v_temp << output_timeseries[i]
      end
      hash_result['key'] = v_temp
    end
    if get_datetime
      return [hash_result, v_datetimes]
    else
      return hash_result
    end
  end

  def self.get_zone_area(model, runner)
    source_units_area = "m^2"
    target_units_area = "ft^2"
    target_units_area = "m^2"

    # Space area
    hash_zone_area = {}
    spaces = model.getSpaces
    spaces.each do |space|
      area = OpenStudio.convert(space.floorArea, source_units_area, target_units_area).get
      key = space.thermalZone.get.name.to_s.upcase
      hash_zone_area[key] = area
      # runner.registerInfo("Space = #{space.thermalZone.get.name}, Area = #{hash_zone_area[key]}")
    end
    hash_zone_area
  end

  def self.arr_mean(v_val)
    v_val.inject { |sum, ele| sum + ele }.to_f / v_val.size
  end

  def self.arr_sum(v_val)
    v_val.inject(0) { |sum, ele| sum + ele.to_f }
  end

  def self.arr_conditional_mean(v_val, v_cond, positive = true)
    sum = 0
    length = 0
    v_val.each_with_index do |val, index|
      if positive
        if v_cond[index] > 0 && val > 0
          sum += val
          length += 1
        end
      else
        if v_cond[index] > 0 && val < 0
          sum += val
          length += 1
        end
      end
    end
    sum / length
  end

  def self.thermal_unsatisfied_occ_hour_by_month(v_val, v_weight, v_datetimes, step_per_h, threshold = [0, 20], pct_weight = true)
    v_results = []
    current_month_number = 1
    current_month_sum = 0
    v_val.each_with_index do |val, index|
      if pct_weight
        # If weight is percentage
        current_month_sum += val * (v_weight[index] / 100) / step_per_h
      else
        current_month_sum += val * v_weight[index] / step_per_h
      end

      if DateTime.parse(v_datetimes[index]).strftime('%m').to_i > current_month_number
        # puts "Month #{current_month_number}'s sum is done..."
        v_results << current_month_sum
        current_month_sum = 0
        current_month_number += 1
      end
    end
    v_results << current_month_sum # last month's sum
    v_results
  end

  def self.arr_conditional_sum(v_val, v_cond)
    sum = 0
    v_val.each_with_index do |val, index|
      v_cond[index] > 0 ? (sum += val) : (sum = sum)
    end
    sum
  end

  def self.exceedance_hour_count(v_val, v_cond, step_per_h, threshold = [0, 20])
    sum = 0
    v_val.each_with_index do |val, index|
      (val < threshold[0] || val > threshold[1]) && (v_cond[index] > 0) ? (sum += 1) : (sum = sum)
    end
    sum / step_per_h
  end

  def self.arr_mean_diffs(v_val, v_cond, val_ref)
    sum_diff = 0
    time_steps_count = 0
    v_val.each_with_index do |val, index|
      if v_cond[index] > 0
        # Count only when occupied
        sum_diff += val - val_ref
        time_steps_count += 1
      end
    end
    sum_diff / time_steps_count
  end


  def self.hash_sum(hash_k_arr)
    # This method sum all the array values for a hash of key:array
    OsLib_Reporting.arr_sum(hash_k_arr.map { |k, v| OsLib_Reporting.arr_sum(v) })
  end

  def self.get_true_key(zone_name, hash_ts)
    true_key = zone_name
    hash_ts.each do |hash_key, ts|
      if (hash_key.include? zone_name) || (hash_key.split(' ')[0] == zone_name.split(' ')[0])
        true_key = hash_key
      end
    end
    return true_key
  end

  def self.get_degree_days(model, hdd_base = 18, cdd_base = 10)
    weather_file = model.getWeatherFile.file
    weather_file = weather_file.get
    data = weather_file.data
    cdd = 0.0 # degreeDays
    hdd = 0.0 # degreeDays
    data.each do |epw_data_point|
      temperature = epw_data_point.dryBulbTemperature.get # degreeCelsius
      cdd += [temperature - cdd_base, 0].max / 24 # degreeDays
      hdd += [hdd_base - temperature, 0].max / 24 # degreeDays
    end
    return [hdd, cdd]
  end

  def self.get_non_zero_avg_2ts(arr_ts_1, arr_ts_2, conversion_ts_1 = 1, conversion_ts_2 = 1)
    # two arrays should have the same length
    val_sum = 0
    count = 0
    arr_ts_1.each_with_index do |val, i|
      unless val == 0
        count += 1
        val_sum += (val * conversion_ts_1).to_f / (arr_ts_2[i] * conversion_ts_2)
      end
    end
    val_sum / count
  end


  def self.co2_exceedance_by_month(v_co2_ppm, v_occ, v_datetimes, s_per_h, co2_threshold_1 = 800, co2_threshold_2 = 5000, risk_weight = 5)
    v_results = []
    current_month_number = 1
    current_month_sum = 0
    v_co2_ppm.each_with_index do |val, index|
      n_occ = v_occ[index]
      if n_occ > 0
        if val >= co2_threshold_1 && val < co2_threshold_2
          current_month_sum += (val - co2_threshold_1) / co2_threshold_1 * n_occ / s_per_h
        elsif val >= co2_threshold_2
          current_month_sum += (val - co2_threshold_2) / co2_threshold_2 * n_occ * risk_weight / s_per_h # can change this weight
        end
      end
      if DateTime.parse(v_datetimes[index]).strftime('%m').to_i > current_month_number
        # puts "Month #{current_month_number}'s sum is done..."
        v_results << current_month_sum
        current_month_sum = 0
        current_month_number += 1
      end
    end
    v_results << current_month_sum # last month's sum
    v_results
  end


  def self.get_hourly_average(v_val, v_datetimes, s_per_h)
    hash_hour_sums = {}
    hash_hour_counts = {}
    v_val.each_with_index do |val, index|
      hour = DateTime.parse(v_datetimes[index].to_s).strftime('%H').to_i
      # Sum each "hour of day" values
      if hash_hour_sums.has_key? "#{hour}"
        hash_hour_sums["#{hour}"] += val
      else
        hash_hour_sums["#{hour}"] = 0
      end

      # Count the "hour of day" appearance
      if hash_hour_counts.has_key? "#{hour}"
        hash_hour_counts["#{hour}"] += 1
      else
        hash_hour_counts["#{hour}"] = 0
      end

    end

    # Calculate the average value for each hour
    v_results = []
    (0..23).each do |key|
      v_results << (hash_hour_sums[key.to_s] / (hash_hour_counts[key.to_s] * s_per_h)).round(0)
    end
    v_results
  end

  def self.get_lux_setpoint(model, space_name)
    v_setpoints = []
    d_lgth_ctrls = model.getDaylightingControls
    d_lgth_ctrls.each do |d_lgth_ctrl|
      if d_lgth_ctrl.space.get.name.to_s == space_name
        v_setpoints << d_lgth_ctrl.illuminanceSetpoint
      end
    end
    arr_mean(v_setpoints)
  end

  def self.get_overall_lux(v_lux, v_lght_w, lux_sp)
    v_overall_lux = []
    v_lux.each_with_index do |lux, index|
      if v_lght_w[index] > 0 && lux < lux_sp
        # When the light is on and daylighting lux is smaller than the setpoint
        v_overall_lux << lux_sp.round(1)
      else
        v_overall_lux << lux.round(1)
      end
    end
    v_overall_lux
  end

  def self.geb_metrics_section(model, sqlFile, base_sqlFile, event_date, runner, name_only = false, args = nil, is_ip_units = true, shed_start=nil, shed_end=nil, take_start=nil, take_end=nil)
    # Initial setup
    @geb_metrics_section = {}
    @geb_metrics_section[:title] = 'GEB metrics'
    @geb_metrics_section[:tables] = []
    @geb_metrics_section[:bldg_demand_charts] = []
    @geb_metrics_section[:bldg_demand_chg_chart] = []

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only
      return @geb_metrics_section
    end
    base_results = OsLib_Reporting.get_ts_by_var_key(runner, base_sqlFile, 'Facility Net Purchased Electricity Rate', 'Zone Timestep', true)
    base_demand_ts_annual = base_results[0].values[0]
    datetimes = base_results[1].map { |date| Time.parse(date.to_s) }
    geb_results = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, 'Facility Net Purchased Electricity Rate', 'Zone Timestep', false)
    geb_demand_ts_annual = geb_results.values[0]

    # initialize the result vars
    event_month = event_date.split('-')[0].to_i
    event_day = event_date.split('-')[1].to_i
    event_day_times = []
    event_day_base_values = []
    event_day_geb_values = []
    summer_month_start = 6
    summer_month_end = 9
    summer_demand_base_values = []
    summer_demand_geb_values = []
    winter_demand_base_values = []
    winter_demand_geb_values = []
    step_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f
    floor_area_ft2 = OpenStudio.convert(model.building.get.floorArea.to_f, 'm^2', 'ft^2').get
    puts "*************step 1*************"

    datetimes.each_with_index do |time, idx|
      # get results for the event day
      if time.month == event_month && time.day == event_day
        event_day_times << time.strftime("%H:%M")
        event_day_base_values << base_demand_ts_annual[idx]
        event_day_geb_values << geb_demand_ts_annual[idx]
      end
      # gather summer and winter demand values
      if time.month >= summer_month_start && time.month <= summer_month_end
        summer_demand_base_values << base_demand_ts_annual[idx]
        summer_demand_geb_values << geb_demand_ts_annual[idx]
      else
        winter_demand_base_values << base_demand_ts_annual[idx]
        winter_demand_geb_values << geb_demand_ts_annual[idx]
      end
    end

    # Check model's daylight saving period, if event date is within daylight saving period,
    # for visualization purpose, shift the profile one hour later
    eventDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(event_month), event_day)
    if model.getObjectsByType('OS:RunPeriodControl:DaylightSavingTime'.to_IddObjectType).size >= 1
      runperiodctrl_daylgtsaving = model.getRunPeriodControlDaylightSavingTime
      daylight_saving_startdate = runperiodctrl_daylgtsaving.startDate
      daylight_saving_enddate = runperiodctrl_daylgtsaving.endDate
      if eventDate >= OpenStudio::Date.new(daylight_saving_startdate.monthOfYear, daylight_saving_startdate.dayOfMonth, eventDate.year) && eventDate <= OpenStudio::Date.new(daylight_saving_enddate.monthOfYear, daylight_saving_enddate.dayOfMonth, eventDate.year)
        event_day_base_values = event_day_base_values.rotate(-4)  # shift the load profile one hour later, 15min output so rotate the last four to the front
        event_day_geb_values = event_day_geb_values.rotate(-4)
      end
    end

    puts "event_day_times: #{event_day_times.inspect}"
    puts "event_day_base_values: #{event_day_base_values.inspect}"
    puts "event_day_geb_values: #{event_day_geb_values.inspect}"
    puts "summer_demand_base_values.size: #{summer_demand_base_values.size}"
    puts "summer_demand_geb_values.size: #{summer_demand_geb_values.size}"
    puts "winter_demand_base_values.size: #{winter_demand_base_values.size}"
    puts "winter_demand_geb_values.size: #{winter_demand_geb_values.size}"

    if (shed_start.is_a?Time) && (shed_end.is_a?Time)
      shed_range = [shed_start.strftime("%H:%M"), shed_end.strftime("%H:%M")]
      demand_decrease_shed_period = []
      demand_base_shed_period = []
      event_day_times.each_with_index do |time, idx|
        if time >= shed_range[0] && time <= shed_range[1]
          demand_decrease_shed_period << event_day_base_values[idx] - event_day_geb_values[idx]
          demand_base_shed_period << event_day_base_values[idx]
        end
      end
      # take period only exists with shed period
      if (take_start.is_a?Time) && (take_end.is_a?Time)
        take_range = [take_start.strftime("%H:%M"), take_end.strftime("%H:%M")]
        demand_increase_take_period = []
        demand_base_take_period = []
        event_day_times.each_with_index do |time, idx|
          if (take_range[0] < take_range[1]) && (time >= take_range[0] && time <= take_range[1])
            demand_increase_take_period << event_day_geb_values[idx] - event_day_base_values[idx]
            demand_base_take_period << event_day_base_values[idx]
          elsif (take_range[0] > take_range[1]) && ((time >= take_range[1] && time <= "23:59") || (time >= "00:00" && time <= take_range[1]))
            demand_increase_take_period << event_day_geb_values[idx] - event_day_base_values[idx]
            demand_base_take_period << event_day_base_values[idx]
          end
        end
      end
    end

    puts "demand_base_shed_period: #{demand_base_shed_period.inspect}"
    puts "demand_decrease_shed_period: #{demand_decrease_shed_period.inspect}"
    puts "demand_base_take_period: #{demand_base_take_period.inspect}"
    puts "demand_increase_take_period: #{demand_increase_take_period.inspect}"

    # table: list all the primary DF metrics
    demand_decrease_primary_metrics_table = {}
    demand_decrease_primary_metrics_table[:title] = 'Demand Decrease (Shed) Primary Metrics'
    demand_decrease_primary_metrics_table[:header] = ['P1-Base: Summer Peak Demand Intensity - baseline',
                                                      'P1-GEB: Summer Peak Demand Intensity - GEB measures',
                                                      'P2-Base: Winter Peak Demand Intensity - baseline',
                                                      'P2-GEB: Winter Peak Demand Intensity - GEB measures',
                                                      'E1: Net Building Consumption Change Percentage (24 hours)']
    demand_decrease_primary_metrics_table[:units] = ['W/ft2',
                                                     'W/ft2',
                                                     'W/ft2',
                                                     'W/ft2',
                                                     '%']
    demand_decrease_primary_metrics_table[:data] = []
    demand_decrease_primary_metrics_table[:Metric_descriptions] = [
      '* Test description.'
    ]
    demand_decrease_primary_metrics_table[:data] << [
      (summer_demand_base_values.max/floor_area_ft2).round(2),
      (summer_demand_geb_values.max/floor_area_ft2).round(2),
      (winter_demand_base_values.max/floor_area_ft2).round(2),
      (winter_demand_geb_values.max/floor_area_ft2).round(2),
      ((event_day_geb_values.sum - event_day_base_values.sum)/event_day_base_values.sum * 100).round(2)   # %
    ]

    if (shed_start.is_a?Time) && (shed_end.is_a?Time)
      demand_decrease_primary_metrics_table[:header].concat(['D1: Demand Decrease During Shed Period',
                                                             'D2: Demand Decrease Intensity During Shed Period',
                                                             'D3: Demand Decrease Percentage During Shed Period'])
      demand_decrease_primary_metrics_table[:units].concat(['kW',
                                                            'W/ft2',
                                                            '%'])
      demand_decrease_shed = demand_decrease_shed_period.sum/demand_decrease_shed_period.size/1000.0  # kW
      demand_decrease_primary_metrics_table[:data][0].concat([demand_decrease_shed.round(2),  # kW
                                                              (demand_decrease_shed*1000/floor_area_ft2).round(2),
                                                              ((demand_decrease_shed_period.sum/demand_base_shed_period.sum) * 100).round(2)])  # %
      if (take_start.is_a?Time) && (take_end.is_a?Time)
        demand_decrease_primary_metrics_table[:header].concat(['I1: Demand Increase During Take Period',
                                                               'I2: Demand Increase Intensity During Take Period',
                                                               'I3: Demand Increase Percentage During Take Period'])
        demand_decrease_primary_metrics_table[:units].concat(['kW',
                                                              'W/ft2',
                                                              '%'])
        demand_increase_take = demand_increase_take_period.sum/demand_increase_take_period.size/1000.0  # kW
        demand_decrease_primary_metrics_table[:data][0].concat([demand_increase_take.round(2),  # kW
                                                                (demand_increase_take*1000/floor_area_ft2).round(2),
                                                                ((demand_increase_take_period.sum/demand_base_take_period.sum) * 100).round(2)])  # %
      end
    end

    puts "demand_decrease_primary_metrics_table[:data]: #{demand_decrease_primary_metrics_table[:data].inspect}"

    # plot: event day timestep demand profiles of baseline and GEB measures
    bldg_demand_chart = {}
    bldg_demand_chart[:title] = 'Whole Building Net Electricity Consumption on selected day (W)'
    bldg_demand_chart[:chart_div] = 'bldg_demand_chart'
    bldg_demand_chart[:xaxis_label] = 'Time'
    bldg_demand_chart[:yaxis_label] = 'W'
    bldg_demand_chart[:chart_data] = []
    bldg_demand_chart[:date_range] = [event_day_times[0], event_day_times[-1]]
    if (shed_start.is_a?Time) && (shed_end.is_a?Time)
      bldg_demand_chart[:shed_range] = [shed_start.strftime("%H:%M"), shed_end.strftime("%H:%M")]
      # take period only exists with shed period
      if (take_start.is_a?Time) && (take_end.is_a?Time)
        bldg_demand_chart[:take_range] = [take_start.strftime("%H:%M"), take_end.strftime("%H:%M")]
      end
    end

    bldg_demand_chart[:chart_data] << JSON.generate(
      type: "scatter",
      mode: "lines",
      name: 'Baseline',
      x: event_day_times,
      y: event_day_base_values
    )
    bldg_demand_chart[:chart_data] << JSON.generate(
      type: "scatter",
      mode: "lines",
      name: 'GEB measures',
      x: event_day_times,
      y: event_day_geb_values
    )

    puts "demand_decrease_primary_metrics_table: #{demand_decrease_primary_metrics_table.inspect}"
    puts "bldg_demand_chart: #{bldg_demand_chart.inspect}"

    @geb_metrics_section[:tables] << demand_decrease_primary_metrics_table
    @geb_metrics_section[:bldg_demand_charts] << bldg_demand_chart
    # @geb_metrics_section[:tables] << demand_increase_primary_metrics_table

    return @geb_metrics_section
  end


  ##############################################################################
  # create visual_kpi_section
  def self.visual_kpi_section(model, sqlFile, runner, name_only = false, args = nil, is_ip_units = true)
    # Initial setup
    @visual_kpi_section = {}
    @visual_kpi_section[:title] = 'Visual KPIs'
    @visual_kpi_section[:tables] = []
    @visual_kpi_section[:hash_KPI_ts_charts] = []
    @visual_kpi_section[:hash_KPI_heatmaps] = []

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only
      return @visual_kpi_section
    end

    # Average lux heatmap
    hash_hourly_mean_lux_heatmap = {}
    hash_hourly_mean_lux_heatmap[:title] = 'Hourly Average Daylighting Illuminance Level (lux)'
    hash_hourly_mean_lux_heatmap[:chart_div] = 'visual_KPI_2'
    hash_hourly_mean_lux_heatmap[:chart_data] = []
    hash_hourly_mean_lux_heatmap[:xaxis_label] = 'Hour'
    ############################################################################
    # Get raw space information and timeseries results
    freq = 'Zone Timestep'
    s_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f

    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    var_k_name = 'Zone Lights Electric Energy'
    hash_elec_j_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone Lights Electric Power'
    hash_elec_w_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone People Occupant Count'
    hash_occ_v_ts, v_datetimes = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq, true)
    v_datetimes = v_datetimes.map { |date| DateTime.parse(date.to_s).strftime('%Y-%m-%d %H:%M:%S') }

    var_k_name = 'Daylighting Reference Point 1 Illuminance'
    hash_lux_1_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Daylighting Reference Point 2 Illuminance'
    hash_lux_2_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)


    # Time-series overall lux (daylighting + artificial lighting)
    hash_ts_lux_chart = {}
    hash_ts_lux_chart[:title] = 'Illuminance Level at Zone Centers (lux)'
    hash_ts_lux_chart[:chart_div] = 'visual_KPI_1'
    hash_ts_lux_chart[:chart_data] = []
    hash_ts_lux_chart[:date_range] = [v_datetimes[0], v_datetimes[-1]]


    ############################################################################
    runner.registerInfo("---> Calculating non-occupant-related lighting system KPIs.")
    visual_kpi_table_01 = {}
    visual_kpi_table_01[:title] = 'Lighting System & Visual KPIs'
    visual_kpi_table_01[:header] = ['Zone',
                                    'Annual Electricity Consumption',
                                    'Annual Electricity Use Intensity',
                                    'Peak Power Density',
                                    'Useful Daylight Illuminance*'
    ]
    visual_kpi_table_01[:units] = ['',
                                   'kWh',
                                   'kWh/m^2',
                                   'W/m^2',
                                   '%'
    ]
    visual_kpi_table_01[:data] = []
    visual_kpi_table_01[:KPI_descriptions] = [
        '* The percent of time when the zone has comfortable illuminance level (between 300 and 3000 lux) without any artificial lighting or shading device.'
    ]


    v_zone_names = []
    v_zone_mean_lux = []

    hash_zone_area.each do |zone_name, area|
      begin
        lght_j_key = OsLib_Reporting.get_true_key(zone_name, hash_elec_j_ts)
        lght_w_key = OsLib_Reporting.get_true_key(zone_name, hash_elec_w_ts)
        lght_lux_key = OsLib_Reporting.get_true_key(zone_name, hash_lux_1_ts)
        occ_key_name = OsLib_Reporting.get_true_key(zone_name, hash_occ_v_ts)

        visual_kpi_table_01[:data] << [
            zone_name,
            (OsLib_Reporting.arr_sum(hash_elec_j_ts[lght_j_key]) * $J_to_KWH).to_i,
            (OsLib_Reporting.arr_sum(hash_elec_j_ts[lght_j_key]) * $J_to_KWH / area).to_i,
            (hash_elec_w_ts[lght_w_key].max / area).round(1),
            OsLib_Reporting.get_annual_useful_daylight(hash_lux_1_ts[lght_lux_key]).round(1),
        ]

        thermal_zone = model.getThermalZoneByName(zone_name).get
        space_name = thermal_zone.spaces[0].name.to_s
        lux_setpoint = OsLib_Reporting.get_lux_setpoint(model, space_name)

        v_overall_lux = OsLib_Reporting.get_overall_lux(hash_lux_1_ts[lght_lux_key], hash_elec_w_ts[lght_w_key], lux_setpoint)
        v_overall_lux[0]
        v_datetimes[0]

        v_datetimes[0]
        hash_occ_v_ts[occ_key_name][0]
        hash_ts_lux_chart[:chart_data] << JSON.generate(
            type: "scatter",
            mode: "lines",
            name: zone_name,
            x: v_datetimes,
            y: v_overall_lux
        )

        v_zone_mean_lux << OsLib_Reporting.get_hourly_average(hash_lux_1_ts[lght_lux_key], v_datetimes, s_per_h)
        v_zone_names << zone_name
      rescue
        runner.registerInfo("No lighting & visual time series data found for #{zone_name}.")
      end
    end

    hash_hourly_mean_lux_heatmap[:chart_data] << JSON.generate(
        x: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23],
        y: v_zone_names,
        z: v_zone_mean_lux,
        type: 'heatmap',
        hoverongaps: false
    )


    ############################################################################
    # add table to array of tables
    @visual_kpi_section[:tables] << visual_kpi_table_01
    @visual_kpi_section[:hash_KPI_ts_charts] << hash_ts_lux_chart
    @visual_kpi_section[:hash_KPI_heatmaps] << hash_hourly_mean_lux_heatmap

    return @visual_kpi_section
  end

  def self.get_annual_useful_daylight(v_lux, lower_lux=300, upper_lux=3000)
    total_useful_timestamps = 0
    v_lux.each_with_index do |lux, index|
      if lux >= lower_lux && lux <=upper_lux
        total_useful_timestamps += 1
      end
    end
    return total_useful_timestamps.to_f/v_lux.length*100
  end


  # create thermal_kpi section
  def self.thermal_kpi_section(model, sqlFile, runner, name_only = false, args = nil, is_ip_units = true)
    # array to hold tables
    thermal_kpi_tables = []

    # gather data for section
    @thermal_kpi_section = {}
    @thermal_kpi_section[:title] = 'Thermal KPIs'
    @thermal_kpi_section[:tables] = thermal_kpi_tables
    @thermal_kpi_section[:hash_KPI_ts_charts] = []
    @thermal_kpi_section[:hash_KPI_stacked_bar_charts] = []

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @thermal_kpi_section
    end

    ###########################################################################
    # Get the total end uses for each fuel type
    bldg_area = model.getBuilding.floorArea
    runner.registerInfo("Building area = #{bldg_area}")
    ###########################################################################
    freq = 'Zone Timestep'
    step_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f
    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    v_outdoor_t = get_ts_by_var_key(runner, sqlFile, 'Site Outdoor Air Drybulb Temperature', freq)['Environment']

    # create table
    thermal_kpi_table_01 = {}
    thermal_kpi_table_01[:title] = 'Fanger Comfort Model'
    thermal_kpi_table_01[:header] = [
        'Zone',
        'Area',
        'Average Negative PMV (when occupied)',
        'Average Positive PMV (when occupied)',
        'Annual Average PPD (when occupied)',
        'Annual Exceedance hours (when occupied and PPD>20%)',
        'Annual Overcooling Degree-hours*',
        'Annual Overheating Degree-hours*',
    ]
    thermal_kpi_table_01[:units] = ['', 'm^2', '', '', '%', 'hours', '°C*hour', '°C*hour']
    thermal_kpi_table_01[:data] = []

    thermal_kpi_table_01[:KPI_descriptions] = [
        "* When the space is too cool (warm) when it's under cooling (heating) condition which indicate uncomfortable thermal condition and energy waste, reference: 10.1016/j.enbuild.2019.109539.",
    ]

    var_k_name = 'Zone Air Temperature'
    hash_zone_t_v_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Zone Thermal Comfort Fanger Model PMV'
    hash_zone_pmv_v_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Zone Thermal Comfort Fanger Model PPD'
    hash_zone_ppd_v_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Zone People Occupant Count'
    hash_occ_v_ts, v_datetimes = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq, true)
    v_datetimes = v_datetimes.map { |date| DateTime.parse(date.to_s).strftime('%Y-%m-%d %H:%M:%S') }


    # File.write('C:/Users/hlee9/Documents/GitHub/OS-measures/occupant_centric_kpi_report/tests/hash_zone_pmv_v_ts.yml', hash_zone_pmv_v_ts.to_yaml)
    # File.write('C:/Users/hlee9/Documents/GitHub/OS-measures/occupant_centric_kpi_report/tests/hash_occ_v_ts.yml', hash_occ_v_ts.to_yaml)

    # Time-series occupant count
    hash_ts_occ_count_chart = {}
    hash_ts_occ_count_chart[:title] = 'Zone People Count'
    hash_ts_occ_count_chart[:chart_div] = 'thermal_KPI_1'
    hash_ts_occ_count_chart[:chart_data] = []
    hash_ts_occ_count_chart[:date_range] = [v_datetimes[0], v_datetimes[-1]]

    # Time-series PMV
    hash_ts_pmv_chart = {}
    hash_ts_pmv_chart[:title] = 'Zone PMV'
    hash_ts_pmv_chart[:chart_div] = 'thermal_KPI_2'
    hash_ts_pmv_chart[:chart_data] = []
    hash_ts_pmv_chart[:date_range] = [v_datetimes[0], v_datetimes[-1]]

    # Time-series PPD
    hash_ts_ppd_chart = {}
    hash_ts_ppd_chart[:title] = 'Zone PPD'
    hash_ts_ppd_chart[:chart_div] = 'thermal_KPI_3'
    hash_ts_ppd_chart[:chart_data] = []
    hash_ts_ppd_chart[:yaxis_label] = '%'
    hash_ts_ppd_chart[:date_range] = [v_datetimes[0], v_datetimes[-1]]


    # Stacked bar plots
    hash_unsatisfied_occ_hour_chart = {}
    hash_unsatisfied_occ_hour_chart[:title] = 'Unsatisfied Occupant-hours by Month'
    hash_unsatisfied_occ_hour_chart[:chart_div] = 'unsatisfied_occ_hour'
    hash_unsatisfied_occ_hour_chart[:chart_data] = []
    hash_unsatisfied_occ_hour_chart[:yaxis_label] = 'Occupant * Hour'
    hash_unsatisfied_occ_hour_chart[:KPI_description] = '* The unsatisfied hours are the sums of total number of occupants multiplied by percent of people unsatisfied for each timestep.'


    # Get daily adaptive comfort temperature ranges
    hash_past_n_daily_average = OsLib_Reporting.get_hash_past_n_daily_average(v_outdoor_t, v_datetimes, step_per_h, previous_n_days = 7)
    hash_daily_adaptive_comfort_t_ranges = OsLib_Reporting.get_hash_daily_adaptive_comfort_t_ranges(hash_past_n_daily_average)
    # hash_daily_adaptive_comfort_t_lower = hash_daily_adaptive_comfort_t_ranges[0]
    # hash_daily_adaptive_comfort_t_upper = hash_daily_adaptive_comfort_t_ranges[1]


    hash_zone_area.each do |zone_name, area|
      begin
        t_key_name = OsLib_Reporting.get_true_key(zone_name, hash_zone_t_v_ts)
        pmv_key_name = OsLib_Reporting.get_true_key(zone_name, hash_zone_pmv_v_ts)
        ppd_key_name = OsLib_Reporting.get_true_key(zone_name, hash_zone_ppd_v_ts)
        occ_key_name = OsLib_Reporting.get_true_key(zone_name, hash_occ_v_ts)

        overcondition_results = OsLib_Reporting.get_daily_overcondition_degree_hours(hash_daily_adaptive_comfort_t_ranges, hash_zone_t_v_ts[t_key_name], v_outdoor_t, v_datetimes, step_per_h)
        v_overcooling_degree_hrs = overcondition_results[0]
        v_overheating_degree_hrs = overcondition_results[1]

        # KPIs in table
        thermal_kpi_table_01[:data] << [
            zone_name,
            area.round(1),
            OsLib_Reporting.arr_conditional_mean(hash_zone_pmv_v_ts[pmv_key_name], hash_occ_v_ts[occ_key_name], false).round(2),
            OsLib_Reporting.arr_conditional_mean(hash_zone_pmv_v_ts[pmv_key_name], hash_occ_v_ts[occ_key_name], true).round(2),
            OsLib_Reporting.arr_conditional_mean(hash_zone_ppd_v_ts[ppd_key_name], hash_occ_v_ts[occ_key_name], true).round(1),
            OsLib_Reporting.exceedance_hour_count(hash_zone_ppd_v_ts[ppd_key_name], hash_occ_v_ts[occ_key_name], step_per_h, [0, 20]).round(1),
            OsLib_Reporting.arr_sum(v_overcooling_degree_hrs).round(1),
            OsLib_Reporting.arr_sum(v_overheating_degree_hrs).round(1),
        ]

        # KPIs in plots
        # Time-series
        hash_occ_v_ts[occ_key_name][0]
        hash_zone_pmv_v_ts[pmv_key_name][0]
        hash_zone_ppd_v_ts[ppd_key_name][0]
        hash_ts_occ_count_chart[:chart_data] << JSON.generate(
            type: "scatter",
            mode: "lines",
            name: zone_name,
            x: v_datetimes,
            y: hash_occ_v_ts[occ_key_name]
        )
        hash_ts_pmv_chart[:chart_data] << JSON.generate(
            type: "scatter",
            mode: "lines",
            name: zone_name,
            x: v_datetimes,
            y: hash_zone_pmv_v_ts[pmv_key_name]
        )
        hash_ts_ppd_chart[:chart_data] << JSON.generate(
            type: "scatter",
            mode: "lines",
            name: zone_name,
            x: v_datetimes,
            y: hash_zone_ppd_v_ts[ppd_key_name]
        )

        # Stacked-bar
        hash_unsatisfied_occ_hour_chart[:chart_data] << JSON.generate(
            x: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
            y: OsLib_Reporting.thermal_unsatisfied_occ_hour_by_month(hash_zone_ppd_v_ts[ppd_key_name], hash_occ_v_ts[occ_key_name], v_datetimes, step_per_h, [0, 20]),
            name: zone_name,
            type: 'bar'
        )
      rescue
        runner.registerInfo("No Fanger thermal comfort time series data found for #{zone_name}.")
      end
    end
    # puts hash_ts_occ_count_chart
    @thermal_kpi_section[:hash_KPI_ts_charts] << hash_ts_occ_count_chart
    @thermal_kpi_section[:hash_KPI_ts_charts] << hash_ts_pmv_chart
    @thermal_kpi_section[:hash_KPI_ts_charts] << hash_ts_ppd_chart
    @thermal_kpi_section[:hash_KPI_stacked_bar_charts] << hash_unsatisfied_occ_hour_chart


    # add table to array of tables
    thermal_kpi_tables << thermal_kpi_table_01

    # using helper method that generates table for second example
    return @thermal_kpi_section
  end


  def self.get_daily_overcondition_degree_hours(hash_daily_adaptive_comfort_t_ranges, v_indoor_t, v_outdoor_t, v_datetimes, s_per_h)
    hash_daily_adaptive_t_lower = hash_daily_adaptive_comfort_t_ranges[0]
    hash_daily_adaptive_t_upper = hash_daily_adaptive_comfort_t_ranges[1]
    v_overheating_degree_hrs = []
    v_overcooling_degree_hrs = []

    v_indoor_t.each_with_index do |indoor_t, index|
      str_date = DateTime.parse(v_datetimes[index]).strftime('%Y-%m-%d')
      outdoor_t = v_outdoor_t[index]
      comfort_adaptive_t_lower = hash_daily_adaptive_t_lower[str_date]
      comfort_adaptive_t_upper = hash_daily_adaptive_t_upper[str_date]
      # puts "Date is #{str_date}, comfort_adaptive_t_lower is #{comfort_adaptive_t_lower}, comfort_adaptive_t_upper is #{comfort_adaptive_t_upper}, outdoor_t is #{outdoor_t} "
      begin
        # Overcooling degree hours
        if indoor_t < comfort_adaptive_t_lower && outdoor_t > comfort_adaptive_t_upper
          v_overcooling_degree_hrs << (comfort_adaptive_t_lower - indoor_t) / s_per_h
        else
          v_overcooling_degree_hrs << 0
        end
        # Overheating degree hours
        if indoor_t > comfort_adaptive_t_upper && outdoor_t < comfort_adaptive_t_lower
          v_overheating_degree_hrs << (indoor_t - comfort_adaptive_t_upper) / s_per_h
        else
          v_overheating_degree_hrs << 0
        end
      rescue
        v_overcooling_degree_hrs << 0
        v_overheating_degree_hrs << 0
      end
    end
    return [v_overcooling_degree_hrs, v_overheating_degree_hrs]
  end

  def self.get_hash_daily_adaptive_comfort_t_ranges(hash_past_n_daily_average)
    hash_adpative_comfort_lower = {}
    hash_adpative_comfort_upper = {}
    hash_past_n_daily_average.each do |str_date, val|
      margins = OsLib_Reporting.adaptive_comfort_t_range(val)
      hash_adpative_comfort_lower[str_date] = margins[0]
      hash_adpative_comfort_upper[str_date] = margins[1]
    end
    return [hash_adpative_comfort_lower, hash_adpative_comfort_upper]
  end


  def self.geo_sequence(a, r, n)
    # Create a geometric sequence
    (n - 1).times.inject([a]) { |a| a << a.last * r }
  end

  def self.adaptive_comfort_t_range(arr_daily_t_out)
    # This method calculate the lower and upper margin of the comfort adaptive temperature
    # Ref: 10.1016/j.enbuild.2019.109539
    alpha = 0.8
    v_constant = Vector.elements(OsLib_Reporting.geo_sequence(1, alpha, 7))
    # arr_daily_t_out is an array of average daily outdoor temperature of the past seven days.
    v_daily_t_out = Vector.elements(arr_daily_t_out)
    t_rm = (1 - alpha) * v_constant.inner_product(v_daily_t_out) # t_rm: running mean temperature of previous seven days
    upper_margin = 0.09 * t_rm + 24.6
    lower_margin = 0.09 * t_rm + 20.6
    return [lower_margin, upper_margin]
  end

  def self.get_hash_daily_means(v_val, v_datetimes, s_per_h)
    str_current_date = 'init'
    current_day_sum = 0
    v_daily_mean = []
    hash_daily_mean = {}
    v_val.each_with_index do |val, index|
      if DateTime.parse(v_datetimes[index]).strftime('%Y-%m-%d') != str_current_date
        v_daily_mean << current_day_sum / (24 * s_per_h)
        hash_daily_mean[str_current_date] = current_day_sum / (24 * s_per_h)
        current_day_sum = 0
        str_current_date = DateTime.parse(v_datetimes[index]).strftime('%Y-%m-%d')
      else
        current_day_sum += val
      end
    end
    # Remove the empty first value
    hash_daily_mean.delete('init')
    hash_daily_mean
  end

  def self.get_hash_past_n_daily_average(v_val, v_datetimes, step_per_h = 6, previous_n_days = 7)
    # This method calculate the daily average of the past n days, v_val and v_datetimes should have the same length
    hash_daily_means = self.get_hash_daily_means(v_val, v_datetimes, step_per_h)
    hash_past_n_daily_averages = {}
    hash_daily_means.each do |str_date, val|
      arr_vals_of_previous_n_days = []
      (1..previous_n_days).each do |n|
        nth_previous_daily_mean = hash_daily_means[(DateTime.parse(str_date) - n).strftime('%Y-%m-%d')]
        if nth_previous_daily_mean.nil?
          # Append the current day value if the previous nth day's value is unavailable
          arr_vals_of_previous_n_days << hash_daily_means[str_date].to_f
        else
          # Append the previous nth day's value
          arr_vals_of_previous_n_days << nth_previous_daily_mean.to_f
        end
      end
      hash_past_n_daily_averages[str_date] = arr_vals_of_previous_n_days
    end
    hash_past_n_daily_averages
  end

  def self.get_hash_moving_daily_average(v_val, v_datetimes, step_per_h = 6, previous_n_days = 7)
    # This method calculate the moving daily average of the past n days, v_val and v_datetimes should have the same length
    hash_daily_means = self.get_hash_daily_means(v_val, v_datetimes, step_per_h)
    hash_moving_daily_averages = {}
    hash_daily_means.each do |str_date, val|
      arr_vals_of_previous_n_days = []
      (1..previous_n_days).each do |n|
        begin
          # Append the previous nth day's value
          arr_vals_of_previous_n_days << hash_daily_means[(DateTime.parse(str_date) - n).strftime('%Y-%m-%d')].to_f
        rescue
          # Append the current day value if the previous nth day's value is unavailable
          arr_vals_of_previous_n_days << hash_daily_means[str_date].to_f
        end
      end
      hash_moving_daily_averages[str_date] = OsLib_Reporting.arr_mean(arr_vals_of_previous_n_days)
    end
    hash_moving_daily_averages
  end


  def self.air_quality_kpi_section(model, sqlFile, runner, name_only = false, args = nil, is_ip_units = true)
    # Prepare tables and chart hashes
    @air_quality_kpi_section = {}
    @air_quality_kpi_section[:title] = 'Air Quality KPIs'
    @air_quality_kpi_section[:tables] = []
    @air_quality_kpi_section[:hash_KPI_ts_charts] = []
    @air_quality_kpi_section[:hash_KPI_stacked_bar_charts] = []


    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @air_quality_kpi_section
    end

    # gather data for section
    freq = 'Zone Timestep'
    s_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f
    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)

    var_k_name = 'Zone People Occupant Count'
    hash_occ_v_ts, v_datetimes = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq, true)
    v_datetimes = v_datetimes.map { |date| DateTime.parse(date.to_s).strftime('%Y-%m-%d %H:%M:%S') }

    var_k_name = 'Zone Air CO2 Concentration'
    hash_zone_co2_v_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Zone Mechanical Ventilation Standard Density Volume'
    hash_zone_ventilation_v_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Zone Mechanical Ventilation Standard Density Volume Flow Rate'
    hash_zone_ventilation_m3s_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    var_k_name = 'Fan Electric Power'
    hash_fan_electric_w_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    ref_co2_ppm = 400


    # File.write('C:/Users/hlee9/Documents/GitHub/OS-measures/occupant_centric_kpi_report/tests/hash_zone_ventilation_v_ts.yml', hash_zone_ventilation_v_ts.to_yaml)
    # File.write('C:/Users/hlee9/Documents/GitHub/OS-measures/occupant_centric_kpi_report/tests/hash_fan_electric_w_ts.yml', hash_fan_electric_w_ts.to_yaml)
    # File.write('C:/Users/hlee9/Documents/GitHub/OS-measures/occupant_centric_kpi_report/tests/hash_zone_ventilation_m3s_ts.yml', hash_zone_ventilation_m3s_ts.to_yaml)
    # File.write('C:/Users/hlee9/Documents/GitHub/OS-measures/occupant_centric_kpi_report/tests/hash_zone_co2_v_ts.yml', hash_zone_co2_v_ts.to_yaml)


    # Create tables
    aq_kpi_table_01 = {}
    aq_kpi_table_01[:title] = 'Air Quality KPIs'
    aq_kpi_table_01[:header] = [
        'Zone',
        'Annual ventilation volume per area',
        'Average ventilation volume per person hour',
        'Average electric power to ventilation rate ratio*',
        'Average indoor and outdoor CO2 concentration difference during occupant hours**'
    ]
    aq_kpi_table_01[:units] = ['', 'm^3/m^2', 'm^3/(occupant hour)', 'W/cfm', 'ppm']
    aq_kpi_table_01[:data] = []
    aq_kpi_table_01[:KPI_descriptions] = [
        '* Fan energy electricity consumption is considered.',
        '** Default outdoor CO2 concentration is 400ppm.'
    ]

    # Time-series CO2 concentration
    hash_ts_co2_chart = {}
    hash_ts_co2_chart[:title] = 'Zone CO2 concentration'
    hash_ts_co2_chart[:chart_div] = 'aq_KPI_1'
    hash_ts_co2_chart[:chart_data] = []
    hash_ts_co2_chart[:date_range] = [v_datetimes[0], v_datetimes[-1]]

    # Stacked bar plots
    hash_co2_exceedance_occ_hour_chart = {}
    hash_co2_exceedance_occ_hour_chart[:title] = 'Weighted CO2 Exceedance Occupant-hours by Month'
    hash_co2_exceedance_occ_hour_chart[:chart_div] = 'co2_exceedance_occ_hour'
    hash_co2_exceedance_occ_hour_chart[:chart_data] = []
    hash_co2_exceedance_occ_hour_chart[:yaxis_label] = 'Occupant * Hour'
    hash_co2_exceedance_occ_hour_chart[:KPI_description] = %q(
        * The exceedance occupant hour is the sum of weighted occupant*hours. The weight is zero when the indoor CO2
        concentration is below 1000ppm, the weight is 1 when the indoor CO2 concentration is between 1000ppm and 5000ppm,
        The weight is 5 when the indoor CO2 concentration is above 5000ppm.
    )


    hash_zone_area.each do |zone_name, area|
      begin
        ventilation_zone_name = OsLib_Reporting.get_true_key(zone_name, hash_zone_ventilation_v_ts)
        fan_zone_name = OsLib_Reporting.get_true_key(zone_name, hash_fan_electric_w_ts)
        occ_zone_name = OsLib_Reporting.get_true_key(zone_name, hash_occ_v_ts)
        co2_zone_name = OsLib_Reporting.get_true_key(zone_name, hash_zone_co2_v_ts)

        # KPIs in table
        row_data = [
            zone_name,
            (hash_zone_ventilation_v_ts.length > 0 ? (OsLib_Reporting.arr_sum(hash_zone_ventilation_v_ts[ventilation_zone_name]) / area).round(1) : 'N.A.'),
            (hash_zone_ventilation_v_ts.length > 0 ? (OsLib_Reporting.arr_sum(hash_zone_ventilation_v_ts[ventilation_zone_name]) / (OsLib_Reporting.arr_sum(hash_occ_v_ts[occ_zone_name]) / s_per_h)).round(1) : 'N.A.'),
            (hash_fan_electric_w_ts.length > 0 ? (OsLib_Reporting.get_non_zero_avg_2ts(hash_fan_electric_w_ts[fan_zone_name], hash_zone_ventilation_m3s_ts[ventilation_zone_name], 1, $M3S_to_CFM)).round(1) : 'N.A.'),
            (hash_zone_co2_v_ts.length > 0 ? OsLib_Reporting.arr_mean_diffs(hash_zone_co2_v_ts[co2_zone_name], hash_occ_v_ts[occ_zone_name], ref_co2_ppm).round(1) : 'N.A.') #TODO: calculate average CO2 concentration difference
        ]
        aq_kpi_table_01[:data] << row_data

        # KPIs in plots
        # Time-series

        hash_ts_co2_chart[:chart_data] << JSON.generate(
            type: "scatter",
            mode: "lines",
            name: zone_name,
            x: v_datetimes,
            y: hash_zone_co2_v_ts[occ_zone_name]
        )

        # Stacked-bar
        y_stack = OsLib_Reporting.co2_exceedance_by_month(hash_zone_co2_v_ts[co2_zone_name], hash_occ_v_ts[occ_zone_name], v_datetimes, s_per_h)
        hash_co2_exceedance_occ_hour_chart[:chart_data] << JSON.generate(
            x: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
            y: y_stack,
            name: zone_name,
            type: 'bar'
        )

      rescue
        runner.registerInfo("No air quality time series data found for #{zone_name}.")
      end
    end

    @air_quality_kpi_section[:tables] << aq_kpi_table_01
    @air_quality_kpi_section[:hash_KPI_ts_charts] << hash_ts_co2_chart
    @air_quality_kpi_section[:hash_KPI_stacked_bar_charts] << hash_co2_exceedance_occ_hour_chart

    return @air_quality_kpi_section
  end


  ##############################################################################
  # create other_kpi_section
  def self.other_kpi_section(model, sqlFile, runner, name_only = false, args = nil, is_ip_units = true)
    # Initial setup
    other_kpi_tables = []
    @other_system_kpi_section = {}
    @other_system_kpi_section[:title] = 'Other KPIs'
    @other_system_kpi_section[:tables] = other_kpi_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only
      return @other_system_kpi_section
    end

    ############################################################################
    # Get raw space information and timeseries results
    freq = 'Zone Timestep'
    s_per_h = model.getTimestep.numberOfTimestepsPerHour.to_f
    hash_zone_area = OsLib_Reporting.get_zone_area(model, runner)
    var_k_name = 'Electric Equipment Electric Energy'
    hash_elec_j_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Electric Equipment Electric Power'
    hash_elec_w_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)
    var_k_name = 'Zone People Occupant Count'
    hash_occ_ts = OsLib_Reporting.get_ts_by_var_key(runner, sqlFile, var_k_name, freq)

    ############################################################################
    # Occupant related KPIs
    runner.registerInfo("-" * 50)
    runner.registerInfo("---> Calculating occupant-related mels system KPIs.")
    other_kpi_table_02 = {}
    other_kpi_table_02[:title] = 'Occupant-related mels System KPIs'
    other_kpi_table_02[:header] = ['Zone',
                                   'Annual MELs Electricity Consumption Per Max Occupants',
                                   'Annual MELs Electricity Consumption Per Occupant Hour',
                                   'Peak Electric Power Per Max Occupants']
    other_kpi_table_02[:units] = ['',
                                  'kWh/(max occupants)',
                                  'kWh/(occupant hour)',
                                  'W/(max occupants)']
    other_kpi_table_02[:data] = []

    hash_zone_area.each do |key, area|
      begin
        j_key = OsLib_Reporting.get_true_key(key, hash_elec_j_ts)
        w_key = OsLib_Reporting.get_true_key(key, hash_elec_w_ts)
        o_key = OsLib_Reporting.get_true_key(key, hash_occ_ts)
        v_temp = [key,
                  (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / hash_occ_ts[o_key].max).to_i,
                  (OsLib_Reporting.arr_sum(hash_elec_j_ts[j_key]) * $J_to_KWH / OsLib_Reporting.arr_sum(hash_occ_ts[o_key]) / s_per_h).round(3),
                  (hash_elec_w_ts[w_key].max / hash_occ_ts[o_key].max).round(1)]
        other_kpi_table_02[:data] << v_temp
      rescue
        runner.registerInfo("No mels electricity consumption time series data found for #{key}.")
      end
    end

    ############################################################################
    # add table to array of tables
    other_kpi_tables << other_kpi_table_02


    return @other_system_kpi_section
  end


  ##############################################################################
  # create template section
  def self.template_section(model, sqlFile, runner, name_only = false, args = nil, is_ip_units = true)
    # array to hold tables
    template_tables = []

    # gather data for section
    @template_section = {}
    @template_section[:title] = 'Tasty Treats'
    @template_section[:tables] = template_tables

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      return @template_section
    end

    # notes:
    # The data below would typically come from the model or simulation results
    # You can loop through objects to make a table for each item of that type, such as air loops
    # If a section will only have one table you can leave the table title blank and just rely on the section title
    # these will be updated later to support graphs

    # create table
    template_table_01 = {}
    template_table_01[:title] = 'Fruit'
    template_table_01[:header] = ['Definition', 'Value']
    template_table_01[:units] = ['', '$/pound']
    template_table_01[:data] = []

    # add rows to table
    template_table_01[:data] << ['Banana', 0.23]
    template_table_01[:data] << ['Apple', 0.75]
    template_table_01[:data] << ['Orange', 0.50]

    # add table to array of tables
    template_tables << template_table_01

    # using helper method that generates table for second example
    template_tables << OsLib_Reporting.template_table(model, sqlFile, runner, is_ip_units = true)

    return @template_section
  end

  # create template section
  def self.template_table(model, sqlFile, runner, is_ip_units = true)
    # create a second table
    template_table = {}
    template_table[:title] = 'Ice Cream'
    template_table[:header] = ['Definition', 'Base Flavor', 'Toppings', 'Value']
    template_table[:units] = ['', '', '', 'scoop']
    template_table[:data] = []

    # add rows to table
    template_table[:data] << ['Vanilla', 'Vanilla', 'NA', 1.5]
    template_table[:data] << ['Rocky Road', 'Chocolate', 'Nuts', 1.5]
    template_table[:data] << ['Mint Chip', 'Mint', 'Chocolate Chips', 1.5]

    return template_table
  end


end
