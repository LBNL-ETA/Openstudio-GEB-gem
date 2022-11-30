# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
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

require_relative 'logging'
require_relative 'utilities'

module OpenStudio
  module Geb
    class Runner
      def initialize(baseline_dir_str, measure_dict, run_output_path, weather_file_path)
        @baseline_dir_str = baseline_dir_str
        @measure_dict = measure_dict
        @run_output_path = run_output_path
        @weather_file_path = weather_file_path
      end

      def run
        # load baseline model
        @baseline_osm = safe_load_osm(@baseline_dir_str)

        # run baseline first. This is mainly for reporting GEB metrics purpose
        # remove old osw_file
        baseline_osw_result_folder = File.join(@run_output_path, "baseline")
        rm_old_folder_and_create_new(baseline_osw_result_folder)

        # add facility net purchased electricity rate as output variable to the baseline
        demand_var = OpenStudio::Model::OutputVariable.new('Facility Net Purchased Electricity Rate', @baseline_osm)
        demand_var.setReportingFrequency('timestep')
        @baseline_osm.getTimestep.setNumberOfTimestepsPerHour(4)  # change to 15min timestep
        @baseline_dir_str = File.join(baseline_osw_result_folder, "baseline.osm")  # update baseline model
        @baseline_osm.save(@baseline_dir_str, true)

        # create baseline osw
        baseline_osw_path = File.join(baseline_osw_result_folder, "baseline.osw")
        baseline_osw = {}
        baseline_osw["weather_file"] = @weather_file_path
        baseline_osw["seed_file"] = @baseline_dir_str

        # TODO: remove
        # baseline_osw["root"] = "/Users/sky/Sites/Openstudio-GEB-gem/"

        File.open(baseline_osw_path, 'w') do |f|
          f << JSON.pretty_generate(baseline_osw)
        end

        # run baseline osw
        return false unless run_osw(baseline_osw_path, baseline_osw_result_folder)

        # remove old osw_file
        geb_osw_result_folder = File.join(@run_output_path, "run_geb_measures")
        rm_old_folder_and_create_new(geb_osw_result_folder)

        # apply measures and create osw file
        geb_osw_path = apply_measures(geb_osw_result_folder)

        # run geb measure osw
        return false unless run_osw(geb_osw_path, geb_osw_result_folder)
        # runner = OpenStudio::Extension::Runner.new(@run_output_path)
        # failures = runner.run_osws([baseline_osw_path, geb_osw_path], num_parallel = 2)
        # puts "failures: #{failures.inspect}"

        # if failures.empty?
        #   return true
        # else
        #   return false
        # end

        return true
      end

      # measure_dict: hash of measures and their arguments => {measure_name: arguments}
      def apply_measures(osw_result_folder)
        # create osw_file
        osw_path = File.join(osw_result_folder, "geb.osw")

        steps = []
        # measure_dict: hash of measures and their arguments => {measure_name: arguments}
        @measure_dict.each_pair do |m_name, para_dict|
          measure = {}
          measure['measure_dir_name'] = para_dict['measure_dir_name']
          measure['arguments'] = para_dict['arguments']
          steps << measure
        end

        osw = {}
        osw["weather_file"] = @weather_file_path
        osw["seed_file"] = @baseline_dir_str
        osw["steps"] = steps

        File.open(osw_path, 'w') do |f|
          f << JSON.pretty_generate(osw)
        end

        return osw_path
      end

      def run_osw(osw_path, osw_result_folder)
        cli_path = OpenStudio.getOpenStudioCLI
        cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
        puts cmd
        system(cmd)

        result_osw = postprocess_out_osw(osw_result_folder)
        if result_osw[:completed_status] == 'Success'
          return true
        else
          return false
        end

        # Open3.capture3 can't capture error in this case
        # stdout_str, stderr_str, status = Open3.capture3(get_run_env, cmd)
        # if status.success? && status.success? != nil
        #   OpenStudio.logFree(OpenStudio::Debug, 'openstudio.standards.command', "Successfully ran command: '#{cmd}'")
        #   return true
        # else
        #   OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "Error running command: '#{cmd}'")
        #   OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "stdout: #{stdout_str}")
        #   OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "stderr: #{stderr_str}")
        #   return false
        # end
      end

      def report_and_save_errors
        # Report out Info, Warning, and Errors
        log_file_path = "#{@run_output_path}/openstudio-standards.log"
        log_messages_to_file(log_file_path, false)
        errors = get_logs(OpenStudio::Error)
        return errors
      end


      # baseline OpenStudio model
      # Type: OpenStudio::Model::Model
      attr_accessor :baseline_osm

      # dictionary of GEB measures
      # Type: hash
      attr_accessor :measure_dict

      # run test output path
      # Type: string
      attr_accessor :run_output_path
      
    end
  end
end

