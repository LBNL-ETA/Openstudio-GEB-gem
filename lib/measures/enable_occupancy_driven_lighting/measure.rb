# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class EnableOccupancyDrivenLighting < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Enable occupancy-driven lighting'
  end

  # human readable description
  def description
    return 'This measure applies occupancy-driven lighting.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Replace this text with an explanation for the energy modeler specifically.  It should explain how the measure is modeled, including any requirements about how the baseline model must be set up, major assumptions, citations of references to applicable modeling resources, etc.  The energy modeler should be able to read this description and understand what changes the measure is making to the model and why these changes are being made.  Because the Modeler Description is written for an expert audience, using common abbreviations for brevity is good practice.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    minutes_delay = OpenStudio::Measure::OSArgument.makeIntegerArgument('minutes_delay', false)
    minutes_delay.setDisplayName('Number of minutes of delay for turning off lights')
    minutes_delay.setDefaultValue(15)
    args << minutes_delay

    run_output_path = OpenStudio::Measure::OSArgument.makeStringArgument('run_output_path', false)
    run_output_path.setDisplayName('Alternative output path for pre-run')
    run_output_path.setDescription("If not specified, write to the ./generated_files directory")
    run_output_path.setDefaultValue("")
    args << run_output_path

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    def run_osw(osw_path)
      cli_path = OpenStudio.getOpenStudioCLI
      cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
      puts cmd
      system(cmd)
    end

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    run_output_path = runner.getStringArgumentValue('run_output_path', user_arguments).to_s
    if run_output_path.empty?
      run_output_path = runner.workflow.filePaths[0].to_s
    end
    runner.registerInfo("Pre-run output path: #{run_output_path}")

    Dir.mkdir(run_output_path) unless File.exist?(run_output_path)
    prerun_dir = File.join(run_output_path, 'pre-run')
    Dir.mkdir(prerun_dir) unless File.exist?(prerun_dir)
    prerun_osw_path = File.join(prerun_dir, 'sizing.osm')
    model.save(prerun_osw_path, true)  # true is overwrite

    outputVariable = OpenStudio::Model::OutputVariable.new("People Occupant Count", model)
    outputVariable.setReportingFrequency("timestep")
    outputVariable.setKeyValue("*")
    runner.registerInfo("Adding output variable for #{outputVariable.variableName} reporting at each timestep.")



    if File.exist?(model.weatherFile.get.path.get.to_s)
      epw_path = model.weatherFile.get.path.get
    else
      epw_path = File.join(File.dirname(__FILE__), 'USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw')
    end
    osw = {}
    osw["weather_file"] = epw_path
    osw["seed_file"] = prerun_osw_path


    # output_measure_input = {
    #     "measure_dir_name": "Add Output Variable",
    #     "arguments": {"variable_name": "People Occupant Count", "reporting_frequency": "timestep", "key_value": "*"}
    # }
    # osw["steps"] = [output_measure_input]
    osw_path = File.join(prerun_dir, "pre-run.osw")
    File.open(osw_path, 'w') do |f|
      f << JSON.pretty_generate(osw)
    end
    run_osw(osw_path)
    sleep(1)
    if File.exist?(File.join(prerun_dir, "run", "eplusout.csv"))
      runner.registerInfo("Occupant schedules generated!")
    end


    return true
  end
end

# register the measure to be used by the application
EnableOccupancyDrivenLighting.new.registerWithApplication
