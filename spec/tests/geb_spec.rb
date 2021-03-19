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

  it "can apply single measure" do
    # provide baseline path
    baseline_dir_str = "../seed_models/MediumOffice-90.1-2010-ASHRAE 169-2013-5A.osm"
    baseline_dir_str = File.expand_path(baseline_dir_str)
    all_measures = list_all_geb_measures
    measure_dict = {
      "DR HVAC (Large Office Detailed)" => {
        "measure_dir_name" => all_measures["DR HVAC (Large Office Detailed)"]["measure_dir_name"],
        "arguments" => {
          "cooling_adjustment" => 4,
          "starttime_cooling" => '13:00:00',
          "endtime_cooling" => '15:00:00',
          "starttime_heating1" => '13:00:00',
          "endtime_heating1" => '15:00:00',
          "heating_adjustment" => 5,
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
      }
    }
    run_output_path = "../output"
    # provide weather file path
    weather_file_path = "../seed_models/USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw"
    weather_file_path = File.expand_path(weather_file_path)
    runner = OpenStudio::Geb::Runner.new(baseline_dir_str, measure_dict, run_output_path, weather_file_path)
    expect(runner.run).to be true

    # report and save openstudio errors
    errors = runner.report_and_save_errors
    expect(errors.size).to be 0
  end



  it "can apply and run single measure" do
  end

  it "can apply and run multiple measures" do
  end

end
