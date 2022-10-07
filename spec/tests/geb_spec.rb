# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
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
    baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/SFD_1story_UB_UA_ASHP2_HPWH.osm")
    all_measures = list_all_geb_measures
    # puts JSON.pretty_generate(all_measures)
    run_output_path = File.join(File.dirname(__FILE__ ), "../output")
    # provide weather file path
    weather_file_path = File.join(File.dirname(__FILE__ ), "../seed_models/USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw")
    measure_dict = {
      # "Adjust thermostat setpoint by degrees for peak hours" => {
      #   "measure_dir_name" => all_measures["Adjust thermostat setpoint by degrees for peak hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "cooling_adjustment" => 4,
      #     "cooling_daily_starttime" => '14:00:00',
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
      # "Reduce LPD by Percentage for Peak Hours" => {
      #   "measure_dir_name" => all_measures["Reduce LPD by Percentage for Peak Hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "lpd_reduce_percent" => 25,
      #     "start_time" => "14:00:00",
      #     "end_time" => "18:00:00",
      #     "start_date1" => '06-01',
      #     "end_date1" => '09-30'
      #   }
      # },
      # "Reduce EPD by Percentage for Peak Hours" => {
      #   "measure_dir_name" => all_measures["Reduce EPD by Percentage for Peak Hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "epd_reduce_percent" => 30,
      #     "start_time" => "14:00:00",
      #     "end_time" => "18:00:00",
      #     "start_date1" => '06-01',
      #     "end_date1" => '09-30'
      #   }
      # },
      # "Precooling" => {
      #   "measure_dir_name" => all_measures["Precooling"]["measure_dir_name"],
      #   "arguments" => {
      #     "cooling_adjustment" => -4,
      #     "starttime_cooling" => '09:00:00',
      #     "endtime_cooling" => '12:00:00',
      #     "cooling_startdate" => '06-01',
      #     "cooling_enddate" => '09-01'
      #   }
      # },
      # "Add Chilled Water Storage Tank" => {
      #   "measure_dir_name" => all_measures["Add Chilled Water Storage Tank"]["measure_dir_name"],
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
      # "Add HPWH for Domestic Hot Water" => {
      #   "measure_dir_name" => all_measures["Add HPWH for Domestic Hot Water"]["measure_dir_name"],
      #   "arguments" => {
      #     "type" => "PumpedCondenser"
      #   }
      # },
      # "Adjust DHW setpoint" => {
      #   "measure_dir_name" => all_measures["Adjust DHW setpoint"]["measure_dir_name"],
      #   "arguments" => {
      #     "stp_adj_method" => 'By Absolute Temperature',   # 'By Setback Degree'
      #     # "flex_hrs_2" => '00:00-14:00',
      #     # "flex_stp_2" => '170',
      #     "flex_hrs_3" => '14:00-18:00',
      #     "flex_stp_3" => '120'
      #   }
      # },
      # "Reduce domestic hot water use for peak hours" => {
      #   "measure_dir_name" => all_measures["Reduce domestic hot water use for peak hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "water_use_reduce_percent" => 50,
      #     "start_time" => '16:00:00',
      #     "end_time" => '21:00:00'
      #   }
      # },
      # "Add Electrochromic Window" => {
      #   "measure_dir_name" => all_measures["Add Electrochromic Window"]["measure_dir_name"],
      #   "arguments" => {
      #     "ctrl_type" => 'MeetDaylightIlluminanceSetpoint'
      #   }
      # },
      # "Add Rooftop PV" => {
      #   "measure_dir_name" => all_measures["Add Rooftop PV"]["measure_dir_name"],
      #   "arguments" => {
      #     "fraction_of_surface" => 0.35
      #   }
      # },
      "Average Ventilation for Peak Hours" => {
        "measure_dir_name" => all_measures["Average Ventilation for Peak Hours"]["measure_dir_name"],
        "arguments" => {
          "start_time" => '13:00:00',
          "end_time" => '17:00:00',
          "start_date1" => '07-21',
          "end_date1" => '07-21'
        }
      },
      # TODO: test overnight take period
      # TODO: test no shed period and take period
      # TODO: test shed period only
      "GEB Metrics Report" => {
        "measure_dir_name" => all_measures["GEB Metrics Report"]["measure_dir_name"],
        "arguments" => {
          "event_date" => "07-21",
          "baseline_run_output_path" => run_output_path,
          "shed_start" => '13:00:00',
          "shed_end" => '17:00:00',
          "take_start" => '09:00:00',
          "take_end" => '13:00:00'
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
      # "Adjust thermostat setpoint by degrees for peak hours" => {
      #   "measure_dir_name" => all_measures["Adjust thermostat setpoint by degrees for peak hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "cooling_adjustment" => 4,
      #     "cooling_daily_starttime" => '14:00:00',
      #     "cooling_daily_endtime" => '18:00:00',
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
      # "Reduce LPD by Percentage for Peak Hours" => {
      #   "measure_dir_name" => all_measures["Reduce LPD by Percentage for Peak Hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "lpd_reduce_percent" => 25,
      #     "start_time" => "14:00:00",
      #     "end_time" => "18:00:00",
      #     "start_date1" => '06-01',
      #     "end_date1" => '09-30'
      #   }
      # },
      # "Reduce EPD by Percentage for Peak Hours" => {
      #   "measure_dir_name" => all_measures["Reduce EPD by Percentage for Peak Hours"]["measure_dir_name"],
      #   "arguments" => {
      #     "epd_reduce_percent" => 30,
      #     "start_time" => "14:00:00",
      #     "end_time" => "18:00:00",
      #     "start_date1" => '06-01',
      #     "end_date1" => '09-30'
      #   }
      # },
      # "Precooling" => {
      #   "measure_dir_name" => all_measures["Precooling"]["measure_dir_name"],
      #   "arguments" => {
      #     "cooling_adjustment" => -4,
      #     "starttime_cooling" => '09:00:00',
      #     "endtime_cooling" => '12:00:00',
      #     "cooling_startdate" => '06-01',
      #     "cooling_enddate" => '09-01'
      #   }
      # },
      # "Add Chilled Water Storage Tank" => {
      #   "measure_dir_name" => all_measures["Add Chilled Water Storage Tank"]["measure_dir_name"],
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
      "Add HPWH for Domestic Hot Water" => {
        "measure_dir_name" => all_measures["Add HPWH for Domestic Hot Water"]["measure_dir_name"],
        "arguments" => {
          "type" => "PumpedCondenser"
        }
      },
      "Adjust DHW setpoint" => {
        "measure_dir_name" => all_measures["Adjust DHW setpoint"]["measure_dir_name"],
        "arguments" => {
          "stp_adj_method" => 'By Absolute Temperature',   # 'By Setback Degree'
          "flex_hrs_2" => '10:00-14:00',
          "flex_stp_2" => '160',
          "flex_hrs_3" => '14:00-18:00',
          "flex_stp_3" => '120'
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
      # }
    }

    runner = OpenStudio::Geb::Runner.new(baseline_dir_str, measure_dict, run_output_path, weather_file_path)
    expect(runner.run).to be true

    # report and save openstudio errors
    errors = runner.report_and_save_errors
    expect(errors.size).to be 0
  end

end
