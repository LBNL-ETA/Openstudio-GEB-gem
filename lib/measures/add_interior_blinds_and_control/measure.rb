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

# start the measure
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_schedules'
class AddInteriorBlindsAndControl < OpenStudio::Measure::ModelMeasure
  include OsLib_HelperMethods
  include OsLib_Schedules
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'add_interior_blinds_and_control'
  end

  # human readable description
  def description
    return 'This measure add shading control with interior blinds to all exterior windows of the building. '
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure will create a new shading control object with interior blinds for each space, and apply that shading control object to all exterior windows within that space. A new shading schedule will be created and applied to all shading control objects based on the active time provided in user inputs.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    start_time = OpenStudio::Measure::OSArgument.makeStringArgument('start_time', false)
    start_time.setDisplayName('Start Time for Shading')
    start_time.setDescription('In HH:MM:SS format')
    start_time.setDefaultValue('12:00:00')
    args << start_time

    # make an argument for the end time of the reduction
    end_time = OpenStudio::Measure::OSArgument.makeStringArgument('end_time', false)
    end_time.setDisplayName('End Time for Shading')
    end_time.setDescription('In HH:MM:SS format')
    end_time.setDefaultValue('15:00:00')
    args << end_time

    # make an argument for the start date of the reduction
    start_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('start_date', false)
    start_date.setDisplayName('Start date for Shading')
    start_date.setDescription('In MM-DD format')
    start_date.setDefaultValue('07-01')
    args << start_date

    # make an argument for the end date of the reduction
    end_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date', false)
    end_date.setDisplayName('End date for Shading')
    end_date.setDescription('In MM-DD format')
    end_date.setDefaultValue('08-30')
    args << end_date

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    start_time = runner.getStringArgumentValue('start_time', user_arguments)
    end_time = runner.getStringArgumentValue('end_time', user_arguments)
    start_date = runner.getStringArgumentValue('start_date', user_arguments)
    end_date = runner.getStringArgumentValue('end_date', user_arguments)

    unless /(\d\d):(\d\d):(\d\d)/.match(start_time)
      runner.registerError('Start time must be in HH-MM-SS format.')
      return false
    end

    unless /(\d\d):(\d\d):(\d\d)/.match(end_time)
      runner.registerError('End time must be in HH-MM-SS format.')
      return false
    end

    if start_time.to_f > end_time.to_f
      runner.registerError('The start time cannot be later than the end time.')
      return false
    end


    start_month = nil
    start_day = nil
    md = /(\d\d)-(\d\d)/.match(start_date)
    if md
      start_month = md[1].to_i
      start_day = md[2].to_i
    else
      runner.registerError('Start date must be in MM-DD format.')
      return false
    end
    end_month = nil
    end_day = nil
    md = /(\d\d)-(\d\d)/.match(end_date)
    if md
      end_month = md[1].to_i
      end_day = md[2].to_i
    else
      runner.registerError('End date must be in MM-DD format.')
      return false
    end



    # create a shading control for each space
    # All windows using one shading control object will cause duplicated objects (with the same zone name) when translated into idf,
    # which may crash EP
    windows_applied = 0
    # All shading control objects share one schedule
    global_shading_schedule = nil
    model.getSpaces.each do |space|
      # One shading control object for each space if it has any exterior windows
      space_shading_control = nil
      space.surfaces.each do |surface|
        surface.subSurfaces.each do |sub_surface|
          if (sub_surface.outsideBoundaryCondition == 'Outdoors') && (sub_surface.subSurfaceType.include?'Window')
            # create schedule and shading control object only if an exterior window is found
            # (avoid any modifications if no exterior window exists in the model)
            unless global_shading_schedule
              # create a new shading schedule
              normal_day_data_pairs = [[24, 0]]
              h, m, s  = start_time.split(':')
              start_hour = h.to_i +  m.to_i/60
              h, m, s  = end_time.split(':')
              end_hour = h.to_i +  m.to_i/60
              adjusted_day_data_pairs = [[start_hour, 0], [end_hour, 1], [24, 0]]
              options = { 'name' => "Interior blinds schedule",
                          'winter_design_day' => normal_day_data_pairs,
                          'summer_design_day' => normal_day_data_pairs,
                          'default_day' => ["default day"] + normal_day_data_pairs,
                          'rules' => [['Adjusted days', "#{start_month}/#{start_day}-#{end_month}/#{end_day}",
                                       'Sun/Mon/Tue/Wed/Thu/Fri/Sat'] + adjusted_day_data_pairs] }
              global_shading_schedule = OsLib_Schedules.createComplexSchedule(model, options)
              runner.registerInfo("A new schedule 'Interior blinds schedule' has been created for new shading control objects.")
            end
            unless space_shading_control
              shading_material = OpenStudio::Model::Blind.new(model)
              # create shading control object
              space_shading_control = OpenStudio::Model::ShadingControl.new(shading_material)
              space_shading_control.setShadingType("InteriorBlind")
              space_shading_control.setName("#{space.name} interior blinds shading control")
              space_shading_control.setShadingControlType('OnIfScheduleAllows')
              space_shading_control.setSchedule(global_shading_schedule)
            end

            sub_surface.setShadingControl(space_shading_control)
            runner.registerInfo("Interior blinds shading '#{space_shading_control.name}' has been added to window #{sub_surface.name}.")
            windows_applied += 1
          end
        end
      end
    end

    if windows_applied == 0
      runner.registerAsNotApplicable("There's no exterior window in the model, so the measure didn't make any change.")
    else
      runner.registerFinalCondition("In total #{windows_applied} exterior windows have been applied with interior blinds shading.")
    end

    return true
  end
end

# register the measure to be used by the application
AddInteriorBlindsAndControl.new.registerWithApplication
