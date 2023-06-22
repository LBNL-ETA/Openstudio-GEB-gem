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

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)
    assert_equal('bldg_use_type', arguments[0].name)
    assert_equal('home', arguments[0].printValue)


    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    bldg_use_type = arguments[0].clone
    assert(bldg_use_type.setValue('workplace'))
    argument_map['bldg_use_type'] = bldg_use_type

    num_ev_chargers = arguments[1].clone
    assert(num_ev_chargers.setValue(3))
    argument_map['num_ev_chargers'] = num_ev_chargers

    num_evs = arguments[2].clone
    assert(num_evs.setValue(10))
    argument_map['num_evs'] = num_evs

    # avg_arrival_time = arguments[4].clone
    # assert(avg_arrival_time.setValue('9:00'))
    # argument_map['avg_arrival_time'] = avg_arrival_time
    #
    avg_leave_time = arguments[5].clone
    assert(avg_leave_time.setValue('23:30'))
    argument_map['avg_leave_time'] = avg_leave_time

    start_charge_time = arguments[6].clone
    assert(start_charge_time.setValue('17:00'))
    argument_map['start_charge_time'] = start_charge_time

    avg_charge_hours = arguments[7].clone
    assert(avg_charge_hours.setValue(4))
    argument_map['avg_charge_hours'] = avg_charge_hours

    # charge_on_sat = arguments[8].clone
    # assert(charge_on_sat.setValue(false))
    # argument_map['charge_on_sat'] = charge_on_sat
    #
    # charge_on_sun = arguments[9].clone
    # assert(charge_on_sun.setValue(false))
    # argument_map['charge_on_sun'] = charge_on_sun


    measure.run(model, runner, argument_map)
    result = runner.result
    puts "errors: #{result.errors.inspect}"
    puts "warnings: "
    result.warnings.each{|warning| puts warning.logMessage}
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.errors.empty?)

    # save the model
    # output_file_path = OpenStudio::Path.new('tests/test.osm')
    output_file_path = File.join(File.dirname(__FILE__), 'test.osm')
    model.save(output_file_path,true)
  end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = AddElectricVehicleChargingLoad.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal('space_name', arguments[0].name)
  end

  def test_bad_argument_values
    # create an instance of the measure
    measure = AddElectricVehicleChargingLoad.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['space_name'] = ''

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
    assert_equal('Fail', result.value.valueName)
  end

  def test_good_argument_values
    # create an instance of the measure
    measure = AddElectricVehicleChargingLoad.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/example_model.osm"
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['space_name'] = 'New Space'
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
    assert(result.info.size == 1)
    assert(result.warnings.empty?)

    # check that there is now 1 space
    assert_equal(1, model.getSpaces.size - num_spaces_seed)

    # save the model to test output directory
    output_file_path = "#{File.dirname(__FILE__)}//output/test_output.osm"
    model.save(output_file_path, true)
  end
end
