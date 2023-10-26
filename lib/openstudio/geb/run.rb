# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
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
        # first adjust the measure sequence to be OpenStudio measure => EnergyPlus measure => Reporting measure
        energyplus_measures = {}
        report_measures = {}
        @measure_dict.each_pair do |m_name, para_dict|
          # get all EnergyPlus and Reporting measures out and remove original ones
          File.open("#{para_dict['measure_dir_name']}/measure.rb", 'r') do |file|
            file.each_line do |line|
              if line =~ /class.+EnergyPlusMeasure/
                energyplus_measures[m_name] = @measure_dict[m_name]
                @measure_dict.delete(m_name)
                break
              elsif line =~ /class.+ReportingMeasure/
                report_measures[m_name] = @measure_dict[m_name]
                @measure_dict.delete(m_name)
                break
              end
            end
          end
        end

        # add back the EnergyPlusMeasures to the end of the measure list
        unless energyplus_measures.empty?
          energyplus_measures.each_key do |m_name|
            @measure_dict[m_name] = energyplus_measures[m_name]
          end
        end
        # add back the ReportingMeasures to the very end of the measure list
        unless report_measures.empty?
          report_measures.each_key do |m_name|
            @measure_dict[m_name] = report_measures[m_name]
          end
        end

        # add the final meausres to the osw steps in order
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

