# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'json'

class AddElectricVehicleChargingLoadTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_AddElectricVehicleChargingLoad
    # create an instance of the measure
    measure = AddElectricVehicleChargingLoad.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments(model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    # for workplace
    # args_hash['bldg_use_type'] = 'workplace'
    # args_hash['num_ev_chargers'] = 3
    # args_hash['num_evs'] = 10
    # args_hash['charger_level'] = 'Level 2'
    # args_hash['avg_arrival_time'] = '9:00'
    # args_hash['arrival_time_variation_in_mins'] = 60
    # args_hash['avg_charge_hours'] = 2.5
    # args_hash['charge_time_variation_in_mins'] = 60

    # for commercial station
    args_hash['bldg_use_type'] = 'commercial station'
    args_hash['num_ev_chargers'] = 7
    args_hash['num_evs'] = 28
    args_hash['charger_level'] = 'DC charger'
    args_hash['avg_arrival_time'] = '14:00'
    args_hash['arrival_time_variation_in_mins'] = 300
    args_hash['avg_charge_hours'] = 2
    args_hash['charge_time_variation_in_mins'] = 30

    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    measure.run(model, runner, argument_map)
    result = runner.result
    puts "errors: #{result.errors.inspect}"
    puts "warnings: "
    result.warnings.each{|warning| puts warning.logMessage}
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.errors.empty?)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_output.osm"
    model.save(output_file_path, true)

    # test run the modified model
    osw = {}
    osw["weather_file"] = File.join(File.dirname(__FILE__ ), "CZ06RV2.epw")
    osw["seed_file"] = output_file_path
    osw_path = "#{File.dirname(__FILE__)}//output/test_output.osw"
    File.open(osw_path, 'w') do |f|
      f << JSON.pretty_generate(osw)
    end
    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
    puts cmd
    system(cmd)
  end

end
