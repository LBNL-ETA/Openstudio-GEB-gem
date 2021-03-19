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

        # apply measures and create osw file
        osw_path = apply_measures

        # run osw
        return false unless run_osw(osw_path)

        # get results


        return true

      end

      # measure_dict: hash of measures and their arguments => {measure_name: arguments}
      def apply_measures
        # remove old osw_file
        # create osw_file
        # TODO update
        osw_path = File.join(@run_output_path, "run_geb_measures/geb.osw")
        unless File.directory?(File.dirname(osw_path))
          FileUtils.mkdir_p(File.dirname(osw_path))
        end

        create_workflow(osw_path)

        return osw_path
      end


      # measure_dict: hash of measures and their arguments => {measure_name: arguments}
      def create_workflow(osw_path)
        steps = []
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
      end

      def run_osw(osw_path)
        cli_path = OpenStudio.getOpenStudioCLI
        cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""

        stdout_str, stderr_str, status = Open3.capture3(get_run_env(), cmd)
        if status.success?
          OpenStudio.logFree(OpenStudio::Debug, 'openstudio.standards.command', "Successfully ran command: '#{cmd}'")
          return true
        else
          OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "Error running command: '#{cmd}'")
          OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "stdout: #{stdout_str}")
          OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "stderr: #{stderr_str}")
          return false
        end
      end

      def report_and_save_errors
        # Report out errors
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

