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

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'json'

require "#{File.dirname(__FILE__)}/resources/os_lib_reporting"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

# start the measure
class GEBMetricsReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'GEB Metrics Report'
  end

  # human readable description
  def description
    return 'This measure calculates GEB-related (mainly DF) metrics and reports them.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'GEB metrics compare between baseline and GEB measures. To enable the GEB metrics calculation, please make sure the output variable -Facility Net Purchased Electricity Rate- is added to both baseline and retrofit models.'
  end


  def possible_sections
    result = []

    # methods for sections in order that they will appear in report
    ############################################################################
    result << 'geb_metrics_section'
    # TODO: will incorporate tables and figures later

    result
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    # populate arguments
    possible_sections.each do |method_name|
      begin
        # get display name
        arg = OpenStudio::Measure::OSArgument.makeBoolArgument(method_name, true)
        display_name = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,nil,nil,true,nil)[:title]")
        arg.setDescription("Choose whether or not to report #{method_name}")
        arg.setDisplayName(display_name)
        arg.setDefaultValue(true)
        args << arg
      rescue
        next
      end
    end

    # make an argument for the start date of the reduction
    event_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('event_date', true)
    event_date.setDisplayName('The event date for GEB metrics reporting purpose')
    event_date.setDescription('In MM-DD format')
    args << event_date

    # Make string arguments for shed period start time. Optional for some GEB measures like EV and DCV (DCV is EE focused)
    shed_start = OpenStudio::Measure::OSArgument.makeStringArgument('shed_start', false)
    shed_start.setDisplayName('Enter Starting Time for Shed Period:')
    shed_start.setDescription('Use 24 hour format HH:MM:SS')
    # shed_start.setDefaultValue('14:00')
    args << shed_start

    # Make string arguments for shed period end time. Optional for some GEB measures like EV and DCV (DCV is EE focused)
    shed_end = OpenStudio::Measure::OSArgument.makeStringArgument('shed_end', false)
    shed_end.setDisplayName('Enter End Time for Shed Period:')
    shed_end.setDescription('Use 24 hour format HH:MM:SS')
    # shed_end.setDefaultValue('18:00')
    args << shed_end

    # Make string arguments for take period start time. Optional for some GEB measures like EV and DCV (DCV is EE focused)
    take_start = OpenStudio::Measure::OSArgument.makeStringArgument('take_start', false)
    take_start.setDisplayName('Enter Starting Time for Take Period:')
    take_start.setDescription('Use 24 hour format HH:MM:SS')
    # take_start.setDefaultValue('10:00')
    args << take_start

    # Make string arguments for take period end time. Optional for some GEB measures like EV and DCV (DCV is EE focused)
    take_end = OpenStudio::Measure::OSArgument.makeStringArgument('take_end', false)
    take_end.setDisplayName('Enter End Time for Take Period:')
    take_end.setDescription('Use 24 hour format HH:MM:SS')
    # take_end.setDefaultValue('14:00')
    args << take_end

    # Output path, for sizing run
    baseline_run_output_path = OpenStudio::Measure::OSArgument.makePathArgument('baseline_run_output_path', true, "")
    baseline_run_output_path.setDisplayName('Output path')
    args << baseline_run_output_path

    args
  end

  # define the outputs that the measure will create
  def outputs
    outs = OpenStudio::Measure::OSOutputVector.new

    # this measure does not produce machine readable outputs with registerValue, return an empty list

    return outs
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  # Warning: Do not change the name of this method to be snake_case. The method must be lowerCamelCase.
  # def energyPlusOutputRequests(runner, user_arguments)
  #   puts '---> In energyPlusOutputRequests now...'
  #   super(runner, user_arguments)
  #
  #   result = OpenStudio::IdfObjectVector.new
  #   # use the built-in error checking
  #   if !runner.validateUserArguments(arguments, user_arguments)
  #     return result
  #   end
  #   # Add output variables needed from EnergyPlus
  #   result << OpenStudio::IdfObject.load('Output:Variable,,Site Outdoor Air Drybulb Temperature,timestep;').get
  #   result << OpenStudio::IdfObject.load('Output:Variable,*,Zone Thermal Comfort Fanger Model PMV,timestep;').get

  #   result
  # end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # get sql, model, and web assets
    setup = OsLib_Reporting.setup(runner)
    unless setup
      return false
    end
    model = setup[:model]
    # workspace = setup[:workspace]
    sql_file = setup[:sqlFile]
    web_asset_path = setup[:web_asset_path]
    puts "Got measure sql file"

    # get all args except the section args
    event_date = runner.getStringArgumentValue('event_date', user_arguments)
    baseline_run_output_path = runner.getPathArgumentValue('baseline_run_output_path', user_arguments)

    # shed_start and shed_end must be a pair
    # report shed period missing if only take period is given
    # following scenarios are reasonable: (1) has shed, has take; (2) has shed, no take; (3) no shed, no take
    if user_arguments['shed_start'].hasValue && user_arguments['shed_end'].hasValue
      shed_start = runner.getStringArgumentValue('shed_start', user_arguments)
      shed_end = runner.getStringArgumentValue('shed_end', user_arguments)
      # check time format
      begin
        shed_start = Time.strptime(shed_start, '%H:%M')
        shed_end = Time.strptime(shed_end, '%H:%M')
      rescue ArgumentError
        runner.registerError('Shed period start and end times should be in format of %H:%M, e.g., 16:00.')
        return false
      end
      # Check if shed start and end are the same (Wrong inputs)
      if shed_start == shed_end
        runner.registerError('The start and end times of the shed period are the same.')
        return false
      end
      if user_arguments['take_start'].hasValue && user_arguments['take_end'].hasValue
        take_start = runner.getStringArgumentValue('take_start', user_arguments)
        take_end = runner.getStringArgumentValue('take_end', user_arguments)
        # check time format
        begin
          take_start = Time.strptime(take_start, '%H:%M')
          take_end = Time.strptime(take_end, '%H:%M')
        rescue ArgumentError
          runner.registerError('Take period start and end times should be in format of %H:%M, e.g., 16:00.')
          return false
        end
        # Check if shed and take periods have overlap (Assuming typically shed doesn't go overnight as midnight is not peak hours)
        if take_start.between?(shed_start+1, shed_end-1) || take_end.between?(shed_start+1, shed_end-1)   # +- 1 second in case boundaries join
          runner.registerError('The take and shed periods overlap.')
          return false
        end
        # Check if take start and end are the same (Wrong inputs)
        if take_start == take_end
          runner.registerError('The start and end times of the take period are the same.')
          return false
        end
      else
        take_start = nil
        take_end = nil
      end
    else
      shed_start = nil
      shed_end = nil
      take_start = nil
      take_end = nil
    end

    # get baseline model and sql
    base_sql_file_path = OpenStudio::Path.new(File.join(baseline_run_output_path.to_s, 'baseline', 'run', "eplusout.sql"))
    unless File.exist?(base_sql_file_path.to_s)
      runner.registerError('No baseline result sql file was found.')
      return false
    end
    base_sql_file = OpenStudio::SqlFile.new(base_sql_file_path)
    puts "Got baseline sql file"

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments)
    puts "args: #{args}"
    unless args
      return false
    end

    # reporting final condition
    runner.registerInitialCondition('Gathering data from EnergyPlus SQL file and OSM model.')

    # pass measure display name to erb
    @name = name

    # create a array of sections to loop through in erb file
    @sections = []

    # generate data for requested sections
    sections_made = 0
    puts "possible_sections: #{possible_sections.inspect}"
    possible_sections.each do |method_name|
      puts "method_name: #{method_name}"
      next unless args[method_name]
      section = false
      eval("section = OsLib_Reporting.#{method_name}(model,sql_file,base_sql_file,event_date,runner,false,args,nil,shed_start, shed_end, take_start, take_end)")
      display_name = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,nil,nil,true)[:title]")
      if section
        @sections << section
        sections_made += 1
        # look for emtpy tables and warn if skipped because returned empty
        section[:tables].each do |table|
          if !table
            runner.registerWarning("A table in #{display_name} section returned false and was skipped.")
            section[:messages] = ["One or more tables in #{display_name} section returned false and was skipped."]
          end
        end
      else
        runner.registerWarning("#{display_name} section returned false and was skipped.")
        section = {}
        section[:title] = display_name.to_s
        section[:tables] = []
        section[:messages] = []
        section[:messages] << "#{display_name} section returned false and was skipped."
        @sections << section
      end
      # rescue StandardError => e
      #   display_name = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,true)[:title]")
      #   if display_name.nil? then display_name == method_name end
      #   runner.registerWarning("#{display_name} section failed and was skipped because: #{e}. Detail on error follows.")
      #   runner.registerWarning(e.backtrace.join("\n").to_s)

      #   # add in section heading with message if section fails
      #   section = eval("OsLib_Reporting.#{method_name}(nil,nil,nil,true)")
      #   section[:title] = display_name.to_s
      #   section[:tables] = []
      #   section[:messages] = []
      #   section[:messages] << "#{display_name} section failed and was skipped because: #{e}. Detail on error follows."
      #   section[:messages] << [e.backtrace.join("\n").to_s]
      #   @sections << section
    end

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.erb"
    if File.exist?(html_in_path)
      html_in_path = html_in_path
    else
      html_in_path = "#{File.dirname(__FILE__)}/report.html.erb"
    end
    html_in = ''
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # write html file
    html_out_path = File.join(baseline_run_output_path.to_s, 'report.html')
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue StandardError
        file.flush
      end
    end

    # closing the sql file
    base_sql_file.close
    sql_file.close

    # reporting final condition
    runner.registerFinalCondition("Generated report with #{sections_made} sections to #{html_out_path}.")

    true
  end
end

# register the measure to be used by the application
GEBMetricsReport.new.registerWithApplication
