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

class AddFanAssistNightVentilationWithHybridControlTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_good_argument_values
    # create an instance of the measure
    measure = AddFanAssistNightVentilationWithHybridControl.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    # path = "#{File.dirname(__FILE__)}/MediumOffice-90.1-2010-ASHRAE 169-2013-5A.osm"
    path = "#{File.dirname(__FILE__)}/medium_office_with_internal_windows.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['design_night_vent_ach'] = 3
    args_hash['min_outdoor_temp'] = 18
    args_hash['max_outdoor_temp'] = 26
    args_hash['night_vent_starttime'] = "20:00"
    args_hash['night_vent_endtime'] = "08:00"
    args_hash['night_vent_startdate'] = "03-01"
    args_hash['night_vent_enddate'] = "10-31"
    args_hash['wknds'] = true
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    assert(result.info.size >= 4)
    # assert(result.warnings.empty?)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_output.osm"
    model.save(output_file_path, true)

    # test run the modified model
    osw = {}
    osw["weather_file"] = File.join(File.dirname(__FILE__ ), "USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw")  # epw for medium office
    # osw["weather_file"] = File.join(File.dirname(__FILE__ ), "USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw")  # epw for small hotel
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
