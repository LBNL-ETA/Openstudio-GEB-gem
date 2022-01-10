# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'json'

class AdjustDHWSetpointTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_good_argument_values
    # create an instance of the measure
    measure = AdjustDHWSetpoint.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/SmallHotel-2A.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['stp_adj_method'] = 'By Absolute Temperature'   # 'By Setback Degree'
    args_hash['flex_stp_1'] = '140'
    args_hash['flex_hrs_1'] = '9:00-11:00'
    args_hash['flex_stp_2'] = '170'
    args_hash['flex_hrs_2'] = '00:00-9:00'
    args_hash['flex_stp_3'] = '120'
    args_hash['flex_hrs_3'] = '11:00-13:00'
    args_hash['flex_stp_4'] = '170'
    args_hash['flex_hrs_4'] = '13:00-24:00'
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end
    puts argument_map.values.inspect
    # flex1
    # flex_hrs1

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    # show the output
    show_output(result)

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

  def test_adjust_dhw_setpoint_hpwh
    # create an instance of the measure
    measure = AdjustDHWSetpoint.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/LargeOffice-90.1-2013-ASHRAE 169-2013-5A-HPWH.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['stp_adj_method'] = 'By Absolute Temperature'   # 'By Setback Degree'
    args_hash['flex_stp_1'] = '170'
    args_hash['flex_hrs_1'] = '10:00-14:00'
    # args_hash['flex_stp_2'] = '170'
    # args_hash['flex_hrs_2'] = '00:00-9:00'
    args_hash['flex_stp_3'] = '120'
    args_hash['flex_hrs_3'] = '14:00-18:00'
    # args_hash['flex_stp_4'] = '170'
    # args_hash['flex_hrs_4'] = '13:00-24:00'
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end
    puts argument_map.values.inspect
    # flex1
    # flex_hrs1

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    # show the output
    show_output(result)

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
