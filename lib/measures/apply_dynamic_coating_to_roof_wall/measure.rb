# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ApplyDynamicCoatingToRoofWall < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Apply dynamic coating to roof wall'
  end

  # human readable description
  def description
    return 'This measure applies dynamic coating on the outside of opaque exterior walls and/or roofs. The thermal ' \
           'and/or solar absorptance of the outer layer material will vary with the selected control signal. ' \
           'This measure is meant to reduce the radiative and solar heat gain via roofs and/or walls.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure modifies the thermal and/or solar absorptance of the outer surface of an existing material so that ' \
           'they can vary with the selected control signal. The related object is available in EnergyPlus version 23.1, ' \
           'but not yet implemented in OpenStudio, so this measure is implemented as an EnergyPlus measure.'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make choice argument for roof and wall application
    apply_where = OpenStudio::Measure::OSArgument::makeChoiceArgument('apply_where', ['Roof Only', 'Wall Only', 'Both'], true)
    apply_where.setDisplayName('Select where to apply the dynamic coating:')
    apply_where.setDefaultValue('Roof Only')
    args << apply_where

    # Make choice argument for modification types
    apply_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('apply_type', ['Thermal Only', 'Solar Only', 'Both'], true)
    apply_type.setDisplayName('Select the type of properties that the dynamic coating modifies:')
    apply_type.setDefaultValue('Both')
    args << apply_type

    # assuming linear relationship between control signal (SurfaceTemperature) and thermal/solar absorptance
    # the thermal absorptance (i.e., emittance for opaque) increases from 0.2 at 19°C to 0.9 at 27°C
    # ref: K Tang et al., Temperature-adaptive radiative coating for all-season household thermal regulation.
    # (http://nano.eecs.berkeley.edu/publications/Science_2021_TARC.pdf) page SM-7 (supplemental material)
    # For solar absorptance, the temperature range is the same 19-27C, solar absorptance varies from 0.9 to 0.1
    # ref: K. Dong et al., 2022. Reducing temperature swing of space objects with temperature-adaptive solar or radiative coating. Cell Reports Physical Science.
    # (https://www.sciencedirect.com/science/article/pii/S2666386422003605) page 3

    # We use two specific points to describe the linear relationship between surface temperature and absorptance
    # This is the surface temperature of the left point
    temp_lo = OpenStudio::Measure::OSArgument.makeDoubleArgument('temp_lo', true)
    temp_lo.setDisplayName('We use two specific points to describe the linear relationship between surface temperature and absorptance, this is the surface temperature of the left point in Degree Celcius.')
    temp_lo.setDefaultValue(19)
    args << temp_lo

    # We use two specific points to describe the linear relationship between surface temperature and absorptance
    # This is the surface temperature of the right point
    temp_hi = OpenStudio::Measure::OSArgument.makeDoubleArgument('temp_hi', true)
    temp_hi.setDisplayName('We use two specific points to describe the linear relationship between surface temperature and absorptance, this is the surface temperature of the right point in Degree Celcius.')
    temp_hi.setDefaultValue(27)
    args << temp_hi

    # thermal absorptance at low temperature point
    therm_abs_at_temp_lo = OpenStudio::Measure::OSArgument.makeDoubleArgument('therm_abs_at_temp_lo', false)
    therm_abs_at_temp_lo.setDisplayName('Thermal absorptance at low temperature point.')
    therm_abs_at_temp_lo.setDefaultValue(0.2)
    args << therm_abs_at_temp_lo

    # thermal absorptance at high temperature point
    therm_abs_at_temp_hi = OpenStudio::Measure::OSArgument.makeDoubleArgument('therm_abs_at_temp_hi', false)
    therm_abs_at_temp_hi.setDisplayName('Thermal absorptance at high temperature point.')
    therm_abs_at_temp_hi.setDefaultValue(0.9)
    args << therm_abs_at_temp_hi

    # solar absorptance at low temperature point
    solar_abs_at_temp_lo = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_abs_at_temp_lo', false)
    solar_abs_at_temp_lo.setDisplayName('Solar absorptance at low temperature point.')
    solar_abs_at_temp_lo.setDefaultValue(0.9)
    args << solar_abs_at_temp_lo

    # solar absorptance at high temperature point
    solar_abs_at_temp_hi = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_abs_at_temp_hi', false)
    solar_abs_at_temp_hi.setDisplayName('Solar absorptance at high temperature point.')
    solar_abs_at_temp_hi.setDefaultValue(0.1)
    args << solar_abs_at_temp_hi


    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    apply_where = runner.getStringArgumentValue('apply_where', user_arguments)
    apply_type = runner.getStringArgumentValue('apply_type', user_arguments)
    temp_lo = runner.getDoubleArgumentValue('temp_lo', user_arguments)
    temp_hi = runner.getDoubleArgumentValue('temp_hi', user_arguments)
    therm_abs_at_temp_lo = runner.getOptionalDoubleArgumentValue('therm_abs_at_temp_lo', user_arguments)
    therm_abs_at_temp_hi = runner.getOptionalDoubleArgumentValue('therm_abs_at_temp_hi', user_arguments)
    solar_abs_at_temp_lo = runner.getOptionalDoubleArgumentValue('solar_abs_at_temp_lo', user_arguments)
    solar_abs_at_temp_hi = runner.getOptionalDoubleArgumentValue('solar_abs_at_temp_hi', user_arguments)

    # temp_hi should be higher than temp_lo
    if temp_hi <= temp_lo
      runner.registerError("temp_hi should be higher than temp_lo, current: temp_hi #{temp_hi} temp_lo #{temp_lo}. User can use default value 27C and 19C.")
      return false
    end

    # check temp_hi and temp_lo for rationality
    if temp_hi > 100
      runner.registerError("Current temp_hi #{temp_hi}C is higher than 100C, which is abnormal. Default value is 27C")
      return false
    elsif temp_hi < -50
      runner.registerError("Current temp_hi #{temp_hi}C is lower than -50C, which is abnormal. Default value is 27C")
      return false
    end
    if temp_lo > 100
      runner.registerError("Current temp_lo #{temp_lo}C is higher than 100C, which is abnormal. Default value is 19C")
      return false
    elsif temp_lo < -50
      runner.registerError("Current temp_lo #{temp_lo}C is lower than -50C, which is abnormal. Default value is 19C")
      return false
    end

    def check_input(input_var, input_name, default, min, max)
      # check for rationality
      if input_var.empty?
        runner.registerError("#{input_name} needs input, can use default value #{default}.")
        return false
      elsif input_var.to_f <= min || input_var.to_f >= max
        runner.registerError("Invalid #{input_name} of #{input_var.to_f} entered. Value must be >#{min} and <#{max}.")
        return false
      else
        return true
      end
    end

    # based on changed property type, check inputs for rationality
    case apply_type
    when 'Both'
      check_input(therm_abs_at_temp_lo, 'therm_abs_at_temp_lo', 0.2, 0, 1)
      check_input(therm_abs_at_temp_hi, 'therm_abs_at_temp_hi', 0.9, 0, 1)
      check_input(solar_abs_at_temp_lo, 'solar_abs_at_temp_lo', 0.9, 0, 1)
      check_input(solar_abs_at_temp_hi, 'solar_abs_at_temp_hi', 0.2, 0, 1)
    when 'Thermal Only'
      check_input(therm_abs_at_temp_lo, 'therm_abs_at_temp_lo', 0.2, 0, 1)
      check_input(therm_abs_at_temp_hi, 'therm_abs_at_temp_hi', 0.9, 0, 1)
    when 'Solar Only'
      check_input(solar_abs_at_temp_lo, 'solar_abs_at_temp_lo', 0.9, 0, 1)
      check_input(solar_abs_at_temp_hi, 'solar_abs_at_temp_hi', 0.2, 0, 1)
    else
      runner.registerError("Invalid applied changed property type #{apply_type}, should be 'Thermal Only', 'Solar Only', or 'Both'")
      return false
    end

    # loop through "BuildingSurface" to find all constructions for exterior walls and roofs, extract the unique materials used in outer layer
    all_surfaces = workspace.getObjectsByType('BuildingSurface:Detailed'.to_IddObjectType)
    ext_walls = []
    ext_roofs = []
    ext_wall_const_names = []  # unique set of exterior wall construction names
    ext_roof_const_names = []  # unique set of exterior roof construction names
    ext_wall_outer_layer_mats = []  # unique set of wall outer layer materials
    ext_roof_outer_layer_mats = []  # unique set of roof outer layer materials

    # find all exterior walls and roofs
    all_surfaces.each do |surface|
      next if surface.getString(5).to_s.downcase != 'outdoors'
      if surface.getString(1).to_s.downcase == 'wall'   # String(1) is "Surface Type"; String(5) is "Outside Boundary Condition"
        ext_walls.push(surface)
      elsif surface.getString(1).to_s.downcase == 'roof'
        ext_roofs.push(surface)
      end
    end

    # extract the unique material set used in exterior walls and roofs' outer layer
    ext_walls.each do |wall_surf|
      const_name = wall_surf.getString(2).to_s  # String(2) is "Construction Name"
      next if ext_wall_const_names.include?const_name
      ext_wall_const_names.push const_name
      const_obj = workspace.getObjectsByName(const_name)[0]  # get the construction object
      outer_layer_name = const_obj.getString(1).get   # String(1) is the outside layer
      outer_layer_name1 = const_obj.getField(1).get   # String(1) is the outside layer
      puts "const_obj:#{const_obj}"
      puts "const_name:#{const_name}"
      puts "outer_layer_name:#{outer_layer_name}; #{outer_layer_name1}"
      outer_layer_mat_obj = workspace.getObjectsByName(outer_layer_name)[0]  # get the outside layer material object
      puts "outer_layer_mat_obj: #{outer_layer_mat_obj}"
      puts "outer_layer_mat_obj.name = #{outer_layer_mat_obj.name}"
      ext_wall_outer_layer_mats.push outer_layer_mat_obj unless ext_wall_outer_layer_mats.include?outer_layer_mat_obj
    end
    ext_roofs.each do |roof_surf|
      const_name = roof_surf.getString(2).to_s  # String(2) is "Construction Name"
      next if ext_roof_const_names.include?const_name
      ext_roof_const_names.push const_name
      const_obj = workspace.getObjectsByName(const_name)[0]  # get the construction object
      outer_layer_name = const_obj.getString(1).to_s   # String(1) is the outside layer
      puts "const_name:#{const_name}"
      puts "outer_layer_name:#{outer_layer_name}"
      outer_layer_mat_obj = workspace.getObjectsByName(outer_layer_name)[0]  # get the outside layer material object
      ext_roof_outer_layer_mats.push outer_layer_mat_obj unless ext_roof_outer_layer_mats.include?outer_layer_mat_obj
    end

    # initial condition: get the original thermal and solar absorptance of the roof and wall outer layer material
    ini_wall_therm_abs_list = []
    ini_wall_solar_abs_list = []
    ini_roof_therm_abs_list = []
    ini_roof_solar_abs_list = []
    ext_wall_outer_layer_mats.each do |mat|
      # get the material object type
      mat_type = mat.idfObject().iddObject().name.to_s
      if mat_type == "Material"
        ini_wall_therm_abs_list << mat.getString(6).get.to_f if mat.getString(6).get.to_f > 0
        ini_wall_solar_abs_list << mat.getString(7).get.to_f if mat.getString(7).get.to_f > 0
      elsif mat_type == "Material:NoMass"
        ini_wall_therm_abs_list << mat.getString(3).get.to_f if mat.getString(3).get.to_f > 0
        ini_wall_solar_abs_list << mat.getString(4).get.to_f if mat.getString(4).get.to_f > 0
      end
    end
    ext_roof_outer_layer_mats.each do |mat|
      # get the material object type
      mat_type = mat.idfObject().iddObject().name.to_s
      if mat_type == "Material"
        ini_roof_therm_abs_list << mat.getString(6).get.to_f if mat.getString(6).get.to_f > 0
        ini_roof_solar_abs_list << mat.getString(7).get.to_f if mat.getString(7).get.to_f > 0
      elsif mat_type == "Material:NoMass"
        ini_roof_therm_abs_list << mat.getString(3).get.to_f if mat.getString(3).get.to_f > 0
        ini_roof_solar_abs_list << mat.getString(4).get.to_f if mat.getString(4).get.to_f > 0
      end
    end

    runner.registerInitialCondition("The initial exterior wall thermal absorptance is #{ini_wall_therm_abs_list},  exterior wall solar absorptance is #{ini_wall_solar_abs_list}, "\
                                      "exterior roof thermal absorptance is #{ini_roof_therm_abs_list}, exterior roof solar absorptance is #{ini_roof_solar_abs_list}. ")

    # By default control signal is "SurfaceTemperature" as the other modes haven't been tested thoroughly in E+
    # loop through "BuildingSurface" to find all constructions for exterior walls and roofs, extract the unique materials used in outer layer
    # add variableabsorptance properties to these materials
    # pre-populate the object strings for thermal and solar variableabsorptance related objects
    thermal_abs_objs_strs = ["
        Table:IndependentVariable,
          ThermalAbsorptanceTemperatureTable_IndependentVariable1,  !- Name
          Linear,                  !- Interpolation Method
          Constant,                !- Extrapolation Method
          -40.0,                   !- Minimum Value
          60.0,                    !- Maximum Value
          ,                        !- Normalization Reference Value
          Temperature,             !- Unit Type
          ,                        !- External File Name
          ,                        !- External File Column Number
          ,                        !- External File Starting Row Number
          0.0,                     !- Value 1
          #{temp_lo},                    !- Value 2
          #{temp_hi},                !- <none>
          40.00000;                !- <none>
        ",
        "
        Table:IndependentVariableList,
          ThermalAbsorptanceTemperatureTable_IndependentVariableList,  !- Name
          ThermalAbsorptanceTemperatureTable_IndependentVariable1;     !- Independent Variable 1 Name
        ",
        "
        Table:Lookup,
          ThermalAbsorptanceTemperatureTable,  !- Name
          ThermalAbsorptanceTemperatureTable_IndependentVariableList,  !- Independent Variable List Name
          ,                        !- Normalization Method
          ,                        !- Normalization Divisor
          #{therm_abs_at_temp_lo},                     !- Minimum Output
          #{therm_abs_at_temp_hi},                        !- Maximum Output
          Dimensionless,           !- Output Unit Type
          ,                        !- External File Name
          ,                        !- External File Column Number
          ,                        !- External File Starting Row Number
          #{therm_abs_at_temp_lo},                    !- Output Value 1
          #{therm_abs_at_temp_lo},                    !- Output Value 2
          #{therm_abs_at_temp_hi},                    !- <none>
          #{therm_abs_at_temp_hi};                    !- <none>
        "
    ]

    solar_abs_objs_strs = ["
        Table:IndependentVariable,
          SolarAbsorptanceTemperatureTable_IndependentVariable1,  !- Name
          Linear,                  !- Interpolation Method
          Constant,                !- Extrapolation Method
          -40.0,                   !- Minimum Value
          60.0,                    !- Maximum Value
          ,                        !- Normalization Reference Value
          Temperature,             !- Unit Type
          ,                        !- External File Name
          ,                        !- External File Column Number
          ,                        !- External File Starting Row Number
          0.0,                     !- Value 1
          #{temp_lo},                    !- Value 2
          #{temp_hi},                !- <none>
          40.00000;                !- <none>
        ",
        "
        Table:IndependentVariableList,
          SolarAbsorptanceTemperatureTable_IndependentVariableList,  !- Name
          SolarAbsorptanceTemperatureTable_IndependentVariable1;     !- Independent Variable 1 Name
        ",
        "
        Table:Lookup,
          SolarAbsorptanceTemperatureTable,  !- Name
          SolarAbsorptanceTemperatureTable_IndependentVariableList,  !- Independent Variable List Name
          ,                        !- Normalization Method
          ,                        !- Normalization Divisor
          #{solar_abs_at_temp_hi},                     !- Minimum Output
          #{solar_abs_at_temp_lo},                        !- Maximum Output
          Dimensionless,           !- Output Unit Type
          ,                        !- External File Name
          ,                        !- External File Column Number
          ,                        !- External File Starting Row Number
          #{solar_abs_at_temp_lo},                    !- Output Value 1
          #{solar_abs_at_temp_lo},                    !- Output Value 2
          #{solar_abs_at_temp_hi},                    !- <none>
          #{solar_abs_at_temp_hi};                    !- <none>
        "
    ]

    def add_dynamic_coating_mat_str(mat_list, apply_type, workspace)
      # array to hold new IDF objects needed for dynamic coating materials
      string_objects = []

      mat_list.each do |mat|
        mat_name = mat.getString(0)  # name
        # no need to clone the material object (in case it is also used in other constructions) because thermal and solar absorptances only matter when the material is on the outside layer
        puts mat_name.to_s.split(',')
        puts "mat_name: #{mat_name}"

        # based on applied surfaces type, add material objects
        case apply_type
        when 'Both'
          matprops_obj_str = "
            MaterialProperty:VariableAbsorptance,
              variable_#{mat_name}, !- Name
              #{mat_name},           !- Reference Material Name
              SurfaceTemperature,      !- Control Signal
              ThermalAbsorptanceTemperatureTable,   !- Trigger Solar Absorptance Function Name
              ,                        !- Thermal Absorptance Schedule Name
              SolarAbsorptanceTemperatureTable,   !- Trigger Solar Absorptance Function Name
              ;                        !- Solar Absorptance Schedule Name
            "
          string_objects << matprops_obj_str
        when 'Thermal Only'
          matprops_obj_str = "
            MaterialProperty:VariableAbsorptance,
              variable_#{mat_name}, !- Name
              #{mat_name},           !- Reference Material Name
              SurfaceTemperature,      !- Control Signal
              ThermalAbsorptanceTemperatureTable,   !- Trigger Solar Absorptance Function Name
              ,                        !- Thermal Absorptance Schedule Name
              ,                        !- Trigger Solar Absorptance Function Name
              ;                        !- Solar Absorptance Schedule Name
            "
          string_objects << matprops_obj_str
        when 'Solar Only'
          matprops_obj_str = "
            MaterialProperty:VariableAbsorptance,
              variable_#{mat_name}, !- Name
              #{mat_name},           !- Reference Material Name
              SurfaceTemperature,      !- Control Signal
              ,                        !- Trigger Solar Absorptance Function Name
              ,                        !- Thermal Absorptance Schedule Name
              SolarAbsorptanceTemperatureTable,   !- Trigger Solar Absorptance Function Name
              ;                        !- Solar Absorptance Schedule Name
            "
          string_objects << matprops_obj_str
        else
          runner.registerError("Invalid applied changed property type #{apply_type}, should be 'Thermal Only', 'Solar Only', or 'Both'")
          return false
        end
      end

      return string_objects
    end

    # loop through each targeted outer layer material and add variableabsorptance properties to these materials
    altered_mats = []  # for final condition output
    case apply_where
    when 'Roof Only'
      string_objects = add_dynamic_coating_mat_str(ext_roof_outer_layer_mats, apply_type, workspace)
      altered_mats = ext_roof_outer_layer_mats
    when 'Wall Only'
      string_objects = add_dynamic_coating_mat_str(ext_wall_outer_layer_mats, apply_type, workspace)
      altered_mats = ext_wall_outer_layer_mats
    when 'Both'
      string_objects = add_dynamic_coating_mat_str(ext_roof_outer_layer_mats+ext_wall_outer_layer_mats, apply_type, workspace)
      altered_mats = ext_roof_outer_layer_mats+ext_wall_outer_layer_mats
    else
      runner.registerError("Invalid selection on where to apply the dynamic coating, current: #{apply_where}, should be 'Roof Only', 'Wall Only', or 'Both'.")
      return false
    end
    # add the commonly used properties objects
    string_objects = string_objects + thermal_abs_objs_strs + solar_abs_objs_strs

    # add all of the strings to workspace
    string_objects.each do |string_object|
      idfObject = OpenStudio::IdfObject.load(string_object)
      object = idfObject.get
      workspace.addObject(object)
    end

    # report final condition of model
    runner.registerFinalCondition("The dynamic coating is applied to the following materials: #{altered_mats.map{|mat| mat.getString(0).to_s}}. ")

    return true
  end
end

# register the measure to be used by the application
ApplyDynamicCoatingToRoofWall.new.registerWithApplication
