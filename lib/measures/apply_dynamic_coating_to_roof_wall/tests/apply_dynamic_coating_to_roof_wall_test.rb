# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'json'

class ApplyDynamicCoatingToRoofWallTest < Minitest::Test
  # def setup
  # end

  # def teardown

  def test_good_argument_values_dynamic_coating
    # create an instance of the measure
    measure = ApplyDynamicCoatingToRoofWall.new

    # create runner with empty OSW
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    # path = OpenStudio::Path.new(File.dirname(__FILE__) + '/MediumOffice-90.1-2010-ASHRAE 169-2013-5A.osm')
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/SF-CACZ6-HPWH-pre1978.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['temp_lo'] = 19
    args_hash['temp_hi'] = 27
    args_hash['apply_where'] = 'Both'
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
    measure.run(workspace, runner, argument_map)
    result = runner.result
    assert_equal('Success', result.value.valueName)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    workspace.save(output_file_path, true)

    # test run the modified model
    epw_file_path = File.join(File.dirname(__FILE__ ), "USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw")
    cmd = "#{OpenStudio.getEnergyPlusDirectory.to_s}/energyplus -d #{File.join(File.dirname(__FILE__), 'output')} -w \"#{epw_file_path}\" #{output_file_path}"
    puts cmd
    system(cmd)

    # stdout_str, stderr_str, status = Open3.capture3(get_run_env(), cmd)
    # if status.success?
    #   OpenStudio.logFree(OpenStudio::Debug, 'openstudio.standards.command', "Successfully ran command: '#{cmd}'")
    # else
    #   OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "Error running command: '#{cmd}'")
    #   OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "stdout: #{stdout_str}")
    #   OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.command', "stderr: #{stderr_str}")
    # end

  end
end
