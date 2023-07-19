# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'

RSpec.describe OpenStudio::Geb do
  it 'has a version number' do
    expect(OpenStudio::Geb::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = OpenStudio::Geb::Geb.new
    expect(File.exist?(instance.measures_dir)).to be true
  end

  # First get all available GEB measures
  it "list all geb measures" do
    all_measures = list_all_geb_measures
    expect(all_measures).to be_kind_of Hash
    expect(all_measures.size).to be >= 1
    puts JSON.pretty_generate(all_measures)
  end

  it "can apply and run single measure" do
    # provide baseline path
    baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/MediumOffice-90.1-2010-ASHRAE 169-2013-5A.osm")   # commercial
    # baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/SFD_1story_UB_UA_ASHP2_HPWH.osm")  # residential
    all_measures = list_all_geb_measures
    # puts JSON.pretty_generate(all_measures)
    run_output_path = File.join(File.dirname(__FILE__ ), "../output")
    if File.exist? run_output_path
      FileUtils.rm_rf(run_output_path)
      sleep(0.1)
    end
    unless File.directory?(run_output_path)
      FileUtils.mkdir_p(run_output_path)
    end

    # provide weather file path
    weather_file_path = File.join(File.dirname(__FILE__ ), "../seed_models/USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw")
    measure_dict = {
      # "AdjustThermostatSetpointsByDegreesForPeakHours" => {
      #   "measure_dir_name" => all_measures["AdjustThermostatSetpointsByDegreesForPeakHours"]["measure_dir_name"],
      #   "arguments" => {
      #     "cooling_adjustment" => 4,
      #     "cooling_daily_starttime" => '13:00:00',
      #     "cooling_daily_endtime" => '17:00:00',
      #     "cooling_startdate" => '06-01',
      #     "cooling_enddate" => '09-30',
      #     "heating_daily_starttime" => '13:00:00',
      #     "heating_daily_endtime" => '15:00:00',
      #     "heating_startdate_1" => '01-01',
      #     "heating_enddate_1" => '05-31',
      #     "heating_startdate_2" => '10-01',
      #     "heating_enddate_2" => '12-31',
      #     "heating_adjustment" => -5,
      #     "auto_date" => false
      #   }
      # },
      # "reduce_lpd_by_percentage_for_peak_hours" => {
      #   "measure_dir_name" => all_measures["reduce_lpd_by_percentage_for_peak_hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "lpd_reduce_percent" => 25,
      #     "start_time" => "14:00:00",
      #     "end_time" => "18:00:00",
      #     "start_date1" => '06-01',
      #     "end_date1" => '09-30'
      #   }
      # },
      # "reduce_epd_by_percentage_for_peak_hours" => {
      #   "measure_dir_name" => all_measures["reduce_epd_by_percentage_for_peak_hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "epd_reduce_percent" => 30,
      #     "start_time" => "14:00:00",
      #     "end_time" => "18:00:00",
      #     "start_date1" => '06-01',
      #     "end_date1" => '09-30'
      #   }
      # },
      # "precooling" => {
      #   "measure_dir_name" => all_measures["precooling"]["measure_dir_name"],
      #   "arguments" => {
      #     "cooling_adjustment" => -4,
      #     "starttime_cooling" => '09:00:00',
      #     "endtime_cooling" => '12:00:00',
      #     "cooling_startdate" => '06-01',
      #     "cooling_enddate" => '09-01'
      #   }
      # },
      # "add_chilled_water_storage_tank" => {
      #   "measure_dir_name" => all_measures["add_chilled_water_storage_tank"]["measure_dir_name"],
      #   "arguments" => {
      #     "objective" => "Partial Storage",
      #     "run_output_path" => run_output_path,
      #     "epw_path" => weather_file_path,
      #     "discharge_start" => '13:00:00',
      #     "discharge_end" => '17:00:00',
      #     "charge_start" => '23:00:00',
      #     "charge_end" => '07:00:00'
      #   }
      # },
      # "add_heat_pump_water_heater" => {
      #   "measure_dir_name" => all_measures["add_heat_pump_water_heater"]["measure_dir_name"],
      #   "arguments" => {
      #     "type" => "PumpedCondenser"
      #   }
      # },
      # "adjust_dhw_setpoint" => {
      #   "measure_dir_name" => all_measures["adjust_dhw_setpoint"]["measure_dir_name"],
      #   "arguments" => {
      #     "stp_adj_method" => 'By Absolute Temperature',   # 'By Setback Degree'
      #     # "flex_hrs_2" => '00:00-14:00',
      #     # "flex_stp_2" => '170',
      #     "flex_hrs_3" => '14:00-18:00',
      #     "flex_stp_3" => '120'
      #   }
      # },
      # "AddElectricVehicleChargingLoad" => {
      #   "measure_dir_name" => all_measures["AddElectricVehicleChargingLoad"]["measure_dir_name"],
      #   "arguments" => {
      #     "bldg_use_type" => "workplace",
      #     "num_ev_chargers" => 3,
      #     "num_evs" => 10,
      #     "charger_level" => "Level 1",
      #     "avg_arrival_time" => "8:30",
      #     "avg_leave_time" => "17:30",
      #     "avg_charge_hours" => 4,
      #     "charge_on_sat" => true,
      #     "charge_on_sun" => false
      #   }
      # },
      # "reduce_domestic_hot_water_use_for_peak_hours" => {
      #   "measure_dir_name" => all_measures["reduce_domestic_hot_water_use_for_peak_hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "water_use_reduce_percent" => 50,
      #     "start_time" => '16:00:00',
      #     "end_time" => '21:00:00'
      #   }
      # },
      # "add_electrochromic_window" => {
      #   "measure_dir_name" => all_measures["add_electrochromic_window"]["measure_dir_name"],
      #   "arguments" => {
      #     "ctrl_type" => 'MeetDaylightIlluminanceSetpoint'
      #   }
      # },
      # "add_rooftop_pv_simple" => {
      #   "measure_dir_name" => all_measures["add_rooftop_pv_simple"]["measure_dir_name"],
      #   "arguments" => {
      #     "fraction_of_surface" => 0.35
      #   }
      # },
      # "average_ventilation_for_peak_hours" => {
      #   "measure_dir_name" => all_measures["average_ventilation_for_peak_hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "start_time" => '13:00:00',
      #     "end_time" => '17:00:00',
      #     "start_date1" => '07-21',
      #     "end_date1" => '07-21'
      #   }
      # },
      # "add_exterior_blinds_and_control" => {
      #   "measure_dir_name" => all_measures["add_exterior_blinds_and_control"]["measure_dir_name"],
      #   "arguments" => {
      #     "start_time" => '13:00:00',
      #     "end_time" => '17:00:00',
      #     "start_date" => '07-21',
      #     "end_date" => '07-21'
      #   }
      # },
      # "add_interior_blinds_and_control" => {
      #   "measure_dir_name" => all_measures["add_interior_blinds_and_control"]["measure_dir_name"],
      #   "arguments" => {
      #     "start_time" => '13:00:00',
      #     "end_time" => '17:00:00',
      #     "start_date" => '07-21',
      #     "end_date" => '07-21'
      #   }
      # },
      # "add_ceiling_fan" => {
      #   "measure_dir_name" => all_measures["add_ceiling_fan"]["measure_dir_name"],
      #   "arguments" => {
      #     "bldg_type" => 'commercial',
      #     "motor_type" => 'DC',
      #     "start_time" => '08:00:00',
      #     "end_time" => '18:00:00',
      #     "start_date" => '05-01',
      #     "end_date" => '09-30'
      #   }
      # },
      # "reduce_exterior_lighting_loads" => {
      #   "measure_dir_name" => all_measures["reduce_exterior_lighting_loads"]["measure_dir_name"],
      #   "arguments" => {
      #     # "use_daylight_control" => true,
      #     # "use_occupancy_sensing" => true,
      #     "on_frac_in_defined_period" => 0,
      #     "user_defined_start_time" => '22:00:00',
      #     "user_defined_end_time" => '04:00:00'
      #   }
      # },
      "add_natural_ventilation_with_hybrid_control" => {
        "measure_dir_name" => all_measures["add_natural_ventilation_with_hybrid_control"]["measure_dir_name"],
        "arguments" => {
          "open_area_fraction" => 0.6,
          "min_indoor_temp" => 21,
          "max_indoor_temp" => 24,
          "min_outdoor_temp" => 20,
          "max_outdoor_temp" => 24,
          "delta_temp" => 2,
          "nv_starttime" => "07:00",
          "nv_endtime" => "21:00",
          "nv_startdate" => "03-01",
          "nv_enddate" => "10-31",
          "wknds" => true
        }
      },
      # TODO: test overnight take period
      # TODO: test no shed period and take period
      # TODO: test shed period only
      "GEB Metrics Report" => {
        "measure_dir_name" => all_measures["GEB Metrics Report"]["measure_dir_name"],
        "arguments" => {
          "event_date" => "06-16",
          "baseline_run_output_path" => run_output_path
          # "shed_start" => '08:00:00',
          # "shed_end" => '18:00:00'
          # "take_start" => '17:00:00',
          # "take_end" => '21:00:00'
        }
      }
    }
    runner = OpenStudio::Geb::Runner.new(baseline_dir_str, measure_dict, run_output_path, weather_file_path)
    expect(runner.run).to be true

    # report and save openstudio errors
    errors = runner.report_and_save_errors
    expect(errors.size).to be 0
  end

  it "can apply and run multiple measures" do
    # provide baseline path
    baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/MediumOffice-90.1-2010-ASHRAE 169-2013-5A.osm")
    all_measures = list_all_geb_measures
    run_output_path = File.join(File.dirname(__FILE__ ), "../output")
    if File.exist? run_output_path
      FileUtils.rm_rf(run_output_path)
      sleep(0.1)
    end
    unless File.directory?(run_output_path)
      FileUtils.mkdir_p(run_output_path)
    end

    # provide weather file path
    weather_file_path = File.join(File.dirname(__FILE__ ), "../seed_models/USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw")

    measure_dict = {
      "Adjust therAdjustThermostatSetpointsByDegreesForPeakHours" => {
        "measure_dir_name" => all_measures["AdjustThermostatSetpointsByDegreesForPeakHours"]["measure_dir_name"],
        "arguments" => {
          "cooling_adjustment" => 4,
          "cooling_daily_starttime" => '14:00:00',
          "cooling_daily_endtime" => '18:00:00',
          "cooling_startdate" => '06-01',
          "cooling_enddate" => '09-30',
          "heating_daily_starttime" => '13:00:00',
          "heating_daily_endtime" => '15:00:00',
          "heating_startdate_1" => '01-01',
          "heating_enddate_1" => '05-31',
          "heating_startdate_2" => '10-01',
          "heating_enddate_2" => '12-31',
          "heating_adjustment" => -5,
          "auto_date" => false
        }
      },
      "reduce_lpd_by_percentage_for_peak_hours" => {
        "measure_dir_name" => all_measures["reduce_lpd_by_percentage_for_peak_hours"]["measure_dir_name"],
        "arguments" => {
          "lpd_reduce_percent" => 25,
          "start_time" => "14:00:00",
          "end_time" => "18:00:00",
          "start_date1" => '06-01',
          "end_date1" => '09-30'
        }
      },
      "reduce_epd_by_percentage_for_peak_hours" => {
        "measure_dir_name" => all_measures["reduce_epd_by_percentage_for_peak_hours"]["measure_dir_name"],
        "arguments" => {
          "epd_reduce_percent" => 30,
          "start_time" => "14:00:00",
          "end_time" => "18:00:00",
          "start_date1" => '06-01',
          "end_date1" => '09-30'
        }
      },
      "precooling" => {
        "measure_dir_name" => all_measures["precooling"]["measure_dir_name"],
        "arguments" => {
          "cooling_adjustment" => -4,
          "starttime_cooling" => '09:00:00',
          "endtime_cooling" => '12:00:00',
          "cooling_startdate" => '06-01',
          "cooling_enddate" => '09-01'
        }
      },
      "add_chilled_water_storage_tank" => {
        "measure_dir_name" => all_measures["add_chilled_water_storage_tank"]["measure_dir_name"],
        "arguments" => {
          "objective" => "Partial Storage",
          "run_output_path" => run_output_path,
          "epw_path" => weather_file_path,
          "discharge_start" => '12:00:00',
          "discharge_end" => '18:00:00',
          "charge_start" => '23:00:00',
          "charge_end" => '07:00:00'
        }
      },
      "add_heat_pump_water_heater" => {
        "measure_dir_name" => all_measures["add_heat_pump_water_heater"]["measure_dir_name"],
        "arguments" => {
          "type" => "PumpedCondenser"
        }
      },
      "adjust_dhw_setpoint" => {
        "measure_dir_name" => all_measures["adjust_dhw_setpoint"]["measure_dir_name"],
        "arguments" => {
          "stp_adj_method" => 'By Absolute Temperature',   # 'By Setback Degree'
          "flex_hrs_2" => '10:00-14:00',
          "flex_stp_2" => '160',
          "flex_hrs_3" => '14:00-18:00',
          "flex_stp_3" => '120'
        }
      },
      "AddElectricVehicleChargingLoad" => {
        "measure_dir_name" => all_measures["AddElectricVehicleChargingLoad"]["measure_dir_name"],
        "arguments" => {
          "bldg_use_type" => "workplace",
          "num_ev_chargers" => 3,
          "num_evs" => 10,
          "charger_level" => "Level 1",
          "avg_arrival_time" => "8:30",
          "avg_leave_time" => "17:30",
          "avg_charge_hours" => 4,
          "charge_on_sat" => true,
          "charge_on_sun" => false
        }
      },
      "GEB Metrics Report" => {
        "measure_dir_name" => all_measures["GEB Metrics Report"]["measure_dir_name"],
        "arguments" => {
          "event_date" => "07-21",
          "baseline_run_output_path" => run_output_path,
          "shed_start" => '14:00:00',
          "shed_end" => '18:00:00',
          "take_start" => '10:00:00',
          "take_end" => '14:00:00'
        }
      }
    }

    runner = OpenStudio::Geb::Runner.new(baseline_dir_str, measure_dict, run_output_path, weather_file_path)
    expect(runner.run).to be true

    # report and save openstudio errors
    errors = runner.report_and_save_errors
    expect(errors.size).to be 0
  end

end
