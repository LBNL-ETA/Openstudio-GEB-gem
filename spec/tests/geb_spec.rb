# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'

RSpec.describe OpenStudio::Geb do
  it 'has a version number' do
    expect(OpenStudio::Geb::VERSION).not_to be nil
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
    baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/370_medium_office_doas_fan_coil_acc_boiler_3A_modified.osm")   # commercial
    # baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/Outpatient_VAV_economizer_test.osm")   # commercial
    # baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/SFD_1story_UB_UA_ASHP2_HPWH.osm")  # residential
    all_measures = list_all_geb_measures
    # puts JSON.pretty_generate(all_measures)
    run_output_path = File.join(File.dirname(__FILE__ ), "../gta")
    if File.exist? run_output_path
      FileUtils.rm_rf(run_output_path)
      sleep(0.1)
    end
    unless File.directory?(run_output_path)
      FileUtils.mkdir_p(run_output_path)
    end

    # provide weather file path
    weather_file_path = File.join(File.dirname(__FILE__ ), "../seed_models/G1200110.epw")
    measure_dict = {
      "AdjustThermostatSetpointsByDegreesForPeakHours" => {
        "measure_dir_name" => all_measures["AdjustThermostatSetpointsByDegreesForPeakHours"]["measure_dir_name"],
        "arguments" => {
          "cooling_adjustment" => 5,
          "heating_adjustment" => -2,
          "alt_periods" => true,
          "cooling_start_date1" => "01-01",
          "cooling_end_date1" => "03-31",
          "cooling_start_time1" => "00:00:00",
          "cooling_end_time1" => "24:00:00",
          "cooling_start_date2" => "04-01",
          "cooling_end_date2" => "05-31",
          "cooling_start_time2" => "00:00:00",
          "cooling_end_time2" => "24:00:00",
          "cooling_start_date3" => "06-01",
          "cooling_end_date3" => "09-30",
          "cooling_start_time3" => "00:00:00",
          "cooling_end_time3" => "24:00:00",
          "cooling_start_date4" => "10-01",
          "cooling_end_date4" => "11-30",
          "cooling_start_time4" => "00:00:00",
          "cooling_end_time4" => "24:00:00",
          "heating_start_date1" => "01-01",
          "heating_end_date1" => "03-31",
          "heating_start_time1" => "00:00:00",
          "heating_end_time1" => "24:00:00",
          "heating_start_date2" => "04-01",
          "heating_end_date2" => "05-31",
          "heating_start_time2" => "00:00:00",
          "heating_end_time2" => "24:00:00",
          "heating_start_date3" => "06-01",
          "heating_end_date3" => "09-30",
          "heating_start_time3" => "00:00:00",
          "heating_end_time3" => "24:00:00",
          "heating_start_date4" => "12-01",
          "heating_end_date4" => "12-31",
          "heating_start_time4" => "00:00:00",
          "heating_end_time4" => "24:00:00"
        }
      },
      # "reduce_lpd_by_percentage_for_peak_hours" => {
      #   "measure_dir_name" => all_measures["reduce_lpd_by_percentage_for_peak_hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "alt_periods" => true,
      #     "start_date1" => "01-01",
      #     "end_date1" => "03-31",
      #     "start_time1" => "00:00:00",
      #     "end_time1" => "24:00:00",
      #     "start_date2" => "04-01",
      #     "end_date2" => "05-31",
      #     "start_time2" => "00:00:00",
      #     "end_time2" => "24:00:00",
      #     "start_date3" => "06-01",
      #     "end_date3" => "09-30",
      #     "start_time3" => "00:00:00",
      #     "end_time3" => "24:00:00",
      #     "start_date4" => "10-01",
      #     "end_date4" => "11-30",
      #     "start_time4" => "00:00:00",
      #     "end_time4" => "24:00:00",
      #     "start_date5" => "12-01",
      #     "end_date5" => "12-31",
      #     "start_time5" => "00:00:00",
      #     "end_time5" => "24:00:00"
      #   }
      # },
      # "reduce_epd_by_percentage_for_peak_hours" => {
      #   "measure_dir_name" => all_measures["reduce_epd_by_percentage_for_peak_hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "alt_periods" => true,
      #     "epd_reduce_percent" => 30,
      #     "start_date1" => "01-01",
      #     "end_date1" => "03-31",
      #     "start_time1" => "00:00:00",
      #     "end_time1" => "24:00:00",
      #     "start_date2" => "04-01",
      #     "end_date2" => "05-31",
      #     "start_time2" => "00:00:00",
      #     "end_time2" => "24:00:00",
      #     "start_date3" => "06-01",
      #     "end_date3" => "09-30",
      #     "start_time3" => "00:00:00",
      #     "end_time3" => "24:00:00",
      #     "start_date4" => "10-01",
      #     "end_date4" => "11-30",
      #     "start_time4" => "00:00:00",
      #     "end_time4" => "24:00:00",
      #     "start_date5" => "12-01",
      #     "end_date5" => "12-31",
      #     "start_time5" => "00:00:00",
      #     "end_time5" => "24:00:00"
      #   }
      # },
      # "precooling" => {
      #   "measure_dir_name" => all_measures["precooling"]["measure_dir_name"],
      #   "arguments" => {
      #     "cooling_adjustment" => -4,
      #     "alt_periods" => true,
      #     "start_date1" => "01-01",
      #     "end_date1" => "03-31",
      #     "start_time1" => "00:00:00",
      #     "end_time1" => "24:00:00",
      #     "start_date2" => "04-01",
      #     "end_date2" => "05-31",
      #     "start_time2" => "00:00:00",
      #     "end_time2" => "24:00:00",
      #     "start_date3" => "06-01",
      #     "end_date3" => "09-30",
      #     "start_time3" => "00:00:00",
      #     "end_time3" => "24:00:00",
      #     "start_date4" => "10-01",
      #     "end_date4" => "11-30",
      #     "start_time4" => "00:00:00",
      #     "end_time4" => "24:00:00",
      #     "start_date5" => "12-01",
      #     "end_date5" => "12-31",
      #     "start_time5" => "00:00:00",
      #     "end_time5" => "24:00:00"
      #   }
      # },
      # "preheating" => {
      #     "measure_dir_name" => all_measures["preheating"]["measure_dir_name"],
      #     "arguments" => {
      #         "heating_adjustment" => 4,
      #         "alt_periods" => true,
      #         "start_date1" => "01-01",
      #         "end_date1" => "03-31",
      #         "start_time1" => "00:00:00",
      #         "end_time1" => "24:00:00",
      #         "start_date2" => "04-01",
      #         "end_date2" => "05-31",
      #         "start_time2" => "00:00:00",
      #         "end_time2" => "24:00:00",
      #         "start_date3" => "06-01",
      #         "end_date3" => "09-30",
      #         "start_time3" => "00:00:00",
      #         "end_time3" => "24:00:00",
      #         "start_date4" => "10-01",
      #         "end_date4" => "11-30",
      #         "start_time4" => "00:00:00",
      #         "end_time4" => "24:00:00"
      #     }
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
      #       "measure_dir_name" => all_measures["adjust_dhw_setpoint"]["measure_dir_name"],
      #       "arguments" => {
      #           "stp_adj_method" => 'By Absolute Temperature',   # 'By Setback Degree'
      #           # "flex_hrs_2" => '00:00-14:00',
      #           # "flex_stp_2" => '170',
      #           "flex_hrs_3" => '14:00-18:00',
      #           "flex_stp_3" => '120'
      #       }
      #   },
      # "AddElectricVehicleChargingLoad" => {
      #   "measure_dir_name" => all_measures["AddElectricVehicleChargingLoad"]["measure_dir_name"],
      #   "arguments" => {
      #     "bldg_use_type" => "commercial station",
      #     "num_ev_chargers" => 7,
      #     "num_evs" => 28,
      #     "charger_level" => "Level 2",
      #     "avg_arrival_time" => "14:00",
      #     "arrival_time_variation_in_mins" => 300,
      #     # "avg_leave_time" => "17:30",
      #     "avg_charge_hours" => 2,
      #     "charge_time_variation_in_mins" => 30,
      #     "charge_on_sat" => true,
      #     "charge_on_sun" => true
      #   }
      # },
      # "AddElectricVehicleChargingLoad" => {
      #     "measure_dir_name" => all_measures["AddElectricVehicleChargingLoad"]["measure_dir_name"],
      #     "arguments" => {
      #         "bldg_use_type" => "home",
      #         "num_ev_chargers" => 1,
      #         "num_evs" => 1,
      #         "charger_level" => "Level 2",
      #         "start_charge_time" => "21:00",
      #         "charge_on_sat" => true,
      #         "charge_on_sun" => true
      #     }
      # },
      # "reduce_domestic_hot_water_use_for_peak_hours" => {
      #   "measure_dir_name" => all_measures["reduce_domestic_hot_water_use_for_peak_hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "water_use_reduce_percent" => 50,
      #     "start_time" => '19:00:00',
      #     "end_time" => '23:00:00'
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
      #     "start_date1" => '07-20',
      #     "end_date1" => '07-25'
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
      #     "bldg_type" => 'residential',
      #     "motor_type" => 'DC',
      #     "start_time" => '08:00:00',
      #     "end_time" => '18:00:00',
      #     "start_date" => '07-21',
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
      # # suggested event_date: 06-02
      # "add_natural_ventilation_with_hybrid_control" => {
      #   "measure_dir_name" => all_measures["add_natural_ventilation_with_hybrid_control"]["measure_dir_name"],
      #   "arguments" => {
      #     "open_area_fraction" => 0.6,
      #     "min_indoor_temp" => 21,
      #     "max_indoor_temp" => 28,
      #     "min_outdoor_temp" => 20,
      #     "max_outdoor_temp" => 24,
      #     "delta_temp" => 2,
      #     "nv_starttime" => "07:00",
      #     "nv_endtime" => "21:00",
      #     "nv_startdate" => "03-01",
      #     "nv_enddate" => "10-31",
      #     "wknds" => true
      #   }
      # },
      # "add_fan_assist_night_ventilation_with_hybrid_control" => {
      #   "measure_dir_name" => all_measures["add_fan_assist_night_ventilation_with_hybrid_control"]["measure_dir_name"],
      #   "arguments" => {
      #     "design_night_vent_ach" => 3,
      #     "min_outdoor_temp" => 20,
      #     "max_outdoor_temp" => 26,
      #     "night_vent_starttime" => "20:00",
      #     "night_vent_endtime" => "08:00",
      #     "night_vent_startdate" => "03-01",
      #     "night_vent_enddate" => "10-31",
      #     "wknds" => true
      #   }
      # },
      # "apply_dynamic_coating_to_roof_wall" => {
      #   "measure_dir_name" => all_measures["apply_dynamic_coating_to_roof_wall"]["measure_dir_name"],
      #   "arguments" => {
      #     "apply_where" => 'Both',
      #     "apply_type" => 'Both',
      #     "temp_lo" => 19,
      #     "temp_hi" => 27,
      #     "solar_abs_at_temp_lo" => 0.8,
      #     "solar_abs_at_temp_hi" => 0.2
      #   }
      # },
      # TODO: test overnight take period
      # TODO: test no shed period and take period
      # TODO: test shed period only
      "GEB Metrics Report" => {
        "measure_dir_name" => all_measures["GEB Metrics Report"]["measure_dir_name"],
        "arguments" => {
          "event_date" => "01-01",
          "baseline_run_output_path" => run_output_path,
          "take_start" => '12:00:00',
          "take_end" => '16:00:00',
          "shed_start" => '16:00:00',
          "shed_end" => '20:00:00'
        }
      }
    }
    puts measure_dict.inspect
    runner = OpenStudio::Geb::Runner.new(baseline_dir_str, measure_dict, run_output_path, weather_file_path)
    expect(runner.run).to be true

    # report and save openstudio errors
    errors = runner.report_and_save_errors
    expect(errors.size).to be 0
  end

  it "can apply and run multiple measures" do
    # provide baseline path
    baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/LargeOffice-90.1-2013-ASHRAE 169-2013-5A.osm")
    all_measures = list_all_geb_measures
    run_output_path = File.join(File.dirname(__FILE__ ), "../multiple")
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
      "AdjustThermostatSetpointsByDegreesForPeakHours" => {
        "measure_dir_name" => all_measures["AdjustThermostatSetpointsByDegreesForPeakHours"]["measure_dir_name"],
        "arguments" => {
            "cooling_adjustment" => 5,
            "heating_adjustment" => -4,
            "alt_periods" => true
        }
      },
      "reduce_lpd_by_percentage_for_peak_hours" => {
        "measure_dir_name" => all_measures["reduce_lpd_by_percentage_for_peak_hours"]["measure_dir_name"],
        "arguments" => {
          "lpd_reduce_percent" => 30,
          "alt_periods" => true
        }
      },
      "reduce_epd_by_percentage_for_peak_hours" => {
        "measure_dir_name" => all_measures["reduce_epd_by_percentage_for_peak_hours"]["measure_dir_name"],
        "arguments" => {
          "epd_reduce_percent" => 30,
          "alt_periods" => true
        }
      },
      # "add_chilled_water_storage_tank" => {
      #   "measure_dir_name" => all_measures["add_chilled_water_storage_tank"]["measure_dir_name"],
      #   "arguments" => {
      #     "objective" => "Partial Storage",
      #     "run_output_path" => run_output_path,
      #     "epw_path" => weather_file_path,
      #     "discharge_start" => '12:00:00',
      #     "discharge_end" => '18:00:00',
      #     "charge_start" => '23:00:00',
      #     "charge_end" => '07:00:00'
      #   }
      # },
      "precooling" => {
          "measure_dir_name" => all_measures["precooling"]["measure_dir_name"],
          "arguments" => {
              "cooling_adjustment" => -4,
              "alt_periods" => true
          }
      },
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
      #     "flex_hrs_2" => '10:00-14:00',
      #     "flex_stp_2" => '160',
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
