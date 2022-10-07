# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_schedules'
class AddExteriorBlindsAndControl < OpenStudio::Measure::ModelMeasure
  include OsLib_HelperMethods
  include OsLib_Schedules
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'add_exterior_blinds_and_control'
  end

  # human readable description
  def description
    return 'This measure add shading control with exterior blinds to all exterior windows of the building. '
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The measure will create a new exterior blinds shading control object and loop through all exterior windows add the shading control with blinds.'
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
    start_date.setDefaultValue('06-01')
    args << start_date

    # make an argument for the end date of the reduction
    end_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date', false)
    end_date.setDisplayName('End date for Shading')
    end_date.setDescription('In MM-DD format')
    end_date.setDefaultValue('09-30')
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

    if /(\d\d):(\d\d):(\d\d)/.match(start_time)
      shift_time1 = OpenStudio::Time.new(start_time)
    else
      runner.registerError('Start time must be in HH-MM-SS format.')
      return false
    end

    if /(\d\d):(\d\d):(\d\d)/.match(end_time)
      shift_time2 = OpenStudio::Time.new(end_time)
    else
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

    shading_material = OpenStudio::Model::Blind.new(model)
    # create shading control object
    shading_control = OpenStudio::Model::ShadingControl.new(shading_material)
    shading_control.setShadingType("ExteriorBlind")
    shading_control.setName("Exterior blinds shading control")
    shading_control.setShadingControlType('OnIfScheduleAllows')
    # create a new shading schedule
    normal_day_data_pairs = [[24, 0]]
    h, m, s  = start_time.split(':')
    start_hour = h.to_i +  m.to_i/60
    h, m, s  = end_time.split(':')
    end_hour = h.to_i +  m.to_i/60
    adjusted_day_data_pairs = [[start_hour, 0], [end_hour, 1], [24, 0]]
    options = { 'name' => "Exterior blinds schedule",
                'winter_design_day' => normal_day_data_pairs,
                'summer_design_day' => normal_day_data_pairs,
                'default_day' => ["default day"] + normal_day_data_pairs,
                'rules' => [['Adjusted days', "#{start_month}/#{start_day}-#{end_month}/#{end_day}",
                             'Sun/Mon/Tue/Wed/Thu/Fri/Sat'] + adjusted_day_data_pairs] }
    new_shading_sch = OsLib_Schedules.createComplexSchedule(model, options)
    shading_control.setSchedule(new_shading_sch)
    runner.registerInfo("New schedule 'Exterior blinds schedule' has been created for shading control object #{shading_control.name}")

    # apply shading control to all exterior windows
    windows_applied = 0
    model.getSubSurfaces.each do |sub_surface|
      if (sub_surface.outsideBoundaryCondition == 'Outdoors') && (sub_surface.subSurfaceType.include?'Window')
        sub_surface.setShadingControl(shading_control)
        windows_applied += 1
      end
    end
    runner.registerInfo("#{windows_applied} exterior windows have been applied with exterior blinds shading")
    return true
  end
end

# register the measure to be used by the application
AddExteriorBlindsAndControl.new.registerWithApplication
