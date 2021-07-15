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
    baseline_dir_str = File.join(File.dirname(__FILE__ ), "../seed_models/LargeHotel-90.1-2010-ASHRAE 169-2013-5A.osm")
    all_measures = list_all_geb_measures
    run_output_path = File.join(File.dirname(__FILE__ ), "../output")
    # provide weather file path
    weather_file_path = File.join(File.dirname(__FILE__ ), "../seed_models/USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw")
    measure_dict = {
      "Add Chilled Water Storage Tank" => {
        "measure_dir_name" => all_measures["Add Chilled Water Storage Tank"]["measure_dir_name"],
        "arguments" => {
          "objective" => "Partial Storage",
          "primary_loop_sp" => 6.7,
          "secondary_loop_sp" => 8.5,
          "tank_charge_sp" => 7.5,
          "secondary_delta_t" => 4.5,
          "thermal_storage_season" => "01/01-12/31",
          "discharge_start" => "08:00",
          "discharge_end" => "21:00",
          "charge_start" => "23:00",
          "charge_end" => "07:00",
          "run_output_path" => run_output_path,
          "epw_path" => weather_file_path,
          "wknds" => true
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

    puts "*"*150
    puts "all_measures: #{all_measures.inspect}"

    measure_dict = {
      "Adjust thermostat setpoint by degrees for peak hours" => {
        "measure_dir_name" => all_measures["Adjust thermostat setpoint by degrees for peak hours"]["measure_dir_name"],
        "arguments" => {
          "cooling_adjustment" => 4,
          "cooling_daily_starttime" => '13:00:00',
          "cooling_daily_endtime" => '15:00:00',
          "cooling_startdate" => '2009-Jun-01',
          "cooling_enddate" => '2009-Sep-30',
          "heating_daily_starttime" => '13:00:00',
          "heating_daily_endtime" => '15:00:00',
          "heating_startdate_1" => '2009-Jan-01',
          "heating_enddate_1" => '2009-May-31',
          "heating_startdate_2" => '2009-Oct-01',
          "heating_enddate_2" => '2009-Dec-31',
          "heating_adjustment" => -5,
          "auto_date" => true
        }
      },
      "DR Electric Equipment (Large Office Detailed)" => {
        "measure_dir_name" => all_measures["DR Electric Equipment (Large Office Detailed)"]["measure_dir_name"],
        "arguments" => {
          "space_type" => '*Entire Building*',
          "occupied_space_type" => 20,
          "unoccupied_space_type" => 20,
          "single_space_type" => 20,
          "starttime_winter2" => '17:00:00',
          "endtime_winter2" => '21:00:00',
          "starttime_winter1" => '17:00:00',
          "endtime_winter1" => '21:00:00',
          "starttime_summer" => '16:00:00',
          "endtime_summer" => '20:00:00',
          "auto_date" => true,
          "alt_periods" => true
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
      }
    }
    run_output_path = File.join(File.dirname(__FILE__ ), "../output")
    # provide weather file path
    weather_file_path = File.join(File.dirname(__FILE__ ), "../seed_models/USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw")
    runner = OpenStudio::Geb::Runner.new(baseline_dir_str, measure_dict, run_output_path, weather_file_path)
    expect(runner.run).to be true

    # report and save openstudio errors
    errors = runner.report_and_save_errors
    expect(errors.size).to be 0
  end

end
