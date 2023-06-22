# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddElectrochromicWindow < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add Electrochromic Window'
  end

  # human readable description
  def description
    return 'This measure replaces existing window construction to electrochromic window, and allows a few control '\
           'strategies such as by glare, solar radiation, schedule, and illuminance. This measure models two states '\
           'of the electrochromic window, the light and dark states.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure implements the electrochromic window as a three-layer construction, which includes a typical '\
           '3mm glass layer, an air gap, and an electrochromic layer. The control strategies are implemented via '\
           'WindowShadingControl object. For the electrochromic window layer performance, the user could either use default values, '\
           ' which we got from View manufacturer data, or enter their own product performance.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Performance of electrochromic window layer (Default from View product https://windows.lbl.gov/tools/knowledge-base/articles/view-electrochromic)
    # thickness of the electrochromic glass layer
    thickness_electro_glass = OpenStudio::Measure::OSArgument.makeDoubleArgument('thickness_electro_glass', true)
    thickness_electro_glass.setDisplayName('Thickness of the electrochromic glass layer in mm')
    thickness_electro_glass.setUnits('m')
    thickness_electro_glass.setDefaultValue(0.0058)
    args << thickness_electro_glass

    # thickness of the air gap between electrochromic window layer and inside clear glass layer
    thickness_air_gap = OpenStudio::Measure::OSArgument.makeDoubleArgument('thickness_air_gap', true)
    thickness_air_gap.setDisplayName('Thickness of the air gap between electrochromic glass layer and inside clear glass layer in meter')
    thickness_air_gap.setUnits('m')
    thickness_air_gap.setDefaultValue(0.0125)  # 0.5 inch
    args << thickness_air_gap

    # thickness of the inside clear glass layer
    thickness_clear_glass = OpenStudio::Measure::OSArgument.makeDoubleArgument('thickness_clear_glass', true)
    thickness_clear_glass.setDisplayName('Thickness of the inside clear glass layer in meter')
    thickness_clear_glass.setUnits('m')
    thickness_clear_glass.setDefaultValue(0.003)
    args << thickness_clear_glass

    # thermal conductivity of the electrochromic glass layer
    tc_electro_glass = OpenStudio::Measure::OSArgument.makeDoubleArgument('tc_electro_glass', true)
    tc_electro_glass.setDisplayName('Thermal conductivity of the electrochromic glass layer in W/m.K')
    tc_electro_glass.setUnits('W/m.K')
    tc_electro_glass.setDefaultValue(0.9)
    args << tc_electro_glass

    # solar transmittance - light state
    solar_trans_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_trans_light', true)
    solar_trans_light.setDisplayName('Electrochromic glass solar transmittance - light state')
    solar_trans_light.setDefaultValue(0.444)
    args << solar_trans_light

    # solar reflectance - front side - light state
    solar_ref_f_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_ref_f_light', true)
    solar_ref_f_light.setDisplayName('Electrochromic glass solar reflectance - front side - light state')
    solar_ref_f_light.setDefaultValue(0.134)
    args << solar_ref_f_light

    # solar reflectance - back side - light state
    solar_ref_b_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_ref_b_light', true)
    solar_ref_b_light.setDisplayName('Electrochromic glass solar reflectance - back side - light state')
    solar_ref_b_light.setDefaultValue(0.196)
    args << solar_ref_b_light

    # visible transmittance - light state
    vis_trans_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('vis_trans_light', true)
    vis_trans_light.setDisplayName('Electrochromic glass visible transmittance - light state')
    vis_trans_light.setDefaultValue(0.696)
    args << vis_trans_light

    # visible reflectance - front side - light state
    vis_ref_f_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('vis_ref_f_light', true)
    vis_ref_f_light.setDisplayName('Electrochromic glass visible reflectance - front side - light state')
    vis_ref_f_light.setDefaultValue(0.119)
    args << vis_ref_f_light

    # visible reflectance - back side - light state
    vis_ref_b_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('vis_ref_b_light', true)
    vis_ref_b_light.setDisplayName('Electrochromic glass visible reflectance - back side - light state')
    vis_ref_b_light.setDefaultValue(0.133)
    args << vis_ref_b_light

    # infrared transmittance - light state
    ir_trans_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('ir_trans_light', true)
    ir_trans_light.setDisplayName('Electrochromic glass infrared transmittance - light state')
    ir_trans_light.setDefaultValue(0)
    args << ir_trans_light

    # infrared emissivity - front side - light state
    ir_emis_f_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('ir_emis_f_light', true)
    ir_emis_f_light.setDisplayName('Electrochromic glass infrared emissivity - front side - light state')
    ir_emis_f_light.setDefaultValue(0.84)
    args << ir_emis_f_light

    # infrared emissivity - back side - light state
    ir_emis_b_light = OpenStudio::Measure::OSArgument.makeDoubleArgument('ir_emis_b_light', true)
    ir_emis_b_light.setDisplayName('Electrochromic glass infrared emissivity - back side - light state')
    ir_emis_b_light.setDefaultValue(0.159)
    args << ir_emis_b_light

    # solar transmittance - dark state
    solar_trans_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_trans_dark', true)
    solar_trans_dark.setDisplayName('Electrochromic glass solar transmittance - dark state')
    solar_trans_dark.setDefaultValue(0.006)
    args << solar_trans_dark

    # solar reflectance - front side - dark state
    solar_ref_f_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_ref_f_dark', true)
    solar_ref_f_dark.setDisplayName('Electrochromic glass solar reflectance - front side - dark state')
    solar_ref_f_dark.setDefaultValue(0.121)
    args << solar_ref_f_dark

    # solar reflectance - back side - dark state
    solar_ref_b_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_ref_b_dark', true)
    solar_ref_b_dark.setDisplayName('Electrochromic glass solar reflectance - back side - dark state')
    solar_ref_b_dark.setDefaultValue(0.194)
    args << solar_ref_b_dark

    # visible transmittance - dark state
    vis_trans_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('vis_trans_dark', true)
    vis_trans_dark.setDisplayName('Electrochromic glass visible transmittance - dark state')
    vis_trans_dark.setDefaultValue(0.012)
    args << vis_trans_dark

    # visible reflectance - front side - dark state
    vis_ref_f_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('vis_ref_f_dark', true)
    vis_ref_f_dark.setDisplayName('Electrochromic glass visible reflectance - front side - dark state')
    vis_ref_f_dark.setDefaultValue(0.098)
    args << vis_ref_f_dark

    # visible reflectance - back side - dark state
    vis_ref_b_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('vis_ref_b_dark', true)
    vis_ref_b_dark.setDisplayName('Electrochromic glass visible reflectance - back side - dark state')
    vis_ref_b_dark.setDefaultValue(0.114)
    args << vis_ref_b_dark

    # infrared transmittance - dark state
    ir_trans_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('ir_trans_dark', true)
    ir_trans_dark.setDisplayName('Electrochromic glass infrared transmittance - dark state')
    ir_trans_dark.setDefaultValue(0)
    args << ir_trans_dark

    # infrared emissivity - front side - dark state
    ir_emis_f_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('ir_emis_f_dark', true)
    ir_emis_f_dark.setDisplayName('Electrochromic glass infrared emissivity - front side - dark state')
    ir_emis_f_dark.setDefaultValue(0.84)
    args << ir_emis_f_dark

    # infrared emissivity - back side - dark state
    ir_emis_b_dark = OpenStudio::Measure::OSArgument.makeDoubleArgument('ir_emis_b_dark', true)
    ir_emis_b_dark.setDisplayName('Electrochromic glass infrared emissivity - back side - dark state')
    ir_emis_b_dark.setDefaultValue(0.16)
    args << ir_emis_b_dark

    # type of the air gap between electrochromic window layer and inside clear glass layer
    gas_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('gas_type', ['Air', 'Argon', 'Krypton', 'Xenon'], true)
    gas_type.setDisplayName('Select the type of air gap for the electrochromic window')
    gas_type.setDefaultValue('Air')
    args << gas_type

    # control strategies - choice
    ctrl_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('ctrl_type', ['OnIfHighGlare', 'OnIfHighSolarOnWindow', 'MeetDaylightIlluminanceSetpoint'], true)
    ctrl_type.setDisplayName('Select control strategy for electrochromic window')
    ctrl_type.setDescription("Setpoint of glare, radiation, or illuminance should also be set based on selected control strategy")
    ctrl_type.setDefaultValue('OnIfHighGlare')
    args << ctrl_type

    # glare setpoint for electrochromic window control
    glare_stp = OpenStudio::Measure::OSArgument.makeDoubleArgument('glare_stp', false)
    glare_stp.setDisplayName('Maximum allowable discomfort glare index')
    glare_stp.setDescription('Electrochromic window will turn to dark state when glare index is above this value.')
    glare_stp.setDefaultValue(22)
    args << glare_stp

    # solar radiation setpoint for electrochromic window control
    solar_rad_stp = OpenStudio::Measure::OSArgument.makeDoubleArgument('solar_rad_stp', false)
    solar_rad_stp.setDisplayName('Total (beam plus diffuse) solar radiation setpoint')
    solar_rad_stp.setDescription('Electrochromic window will turn to dark state when total solar radiation is above this value.')
    solar_rad_stp.setUnits('W/m2')
    solar_rad_stp.setDefaultValue(800)
    args << solar_rad_stp

    # illuminance setpoint for electrochromic window control
    illum_stp = OpenStudio::Measure::OSArgument.makeDoubleArgument('illum_stp', false)
    illum_stp.setDisplayName('Illuminance setpoint')
    illum_stp.setDescription('The transmittance of the electrochromic window will be adjusted to just meet the daylight illuminance setpoint.')
    illum_stp.setUnits('lux')
    illum_stp.setDefaultValue(300)
    args << illum_stp

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    thickness_electro_glass = runner.getDoubleArgumentValue('thickness_electro_glass', user_arguments)
    thickness_air_gap = runner.getDoubleArgumentValue('thickness_air_gap', user_arguments)
    thickness_clear_glass = runner.getDoubleArgumentValue('thickness_clear_glass', user_arguments)
    tc_electro_glass = runner.getDoubleArgumentValue('tc_electro_glass', user_arguments)
    solar_trans_light = runner.getDoubleArgumentValue('solar_trans_light', user_arguments)
    solar_ref_f_light = runner.getDoubleArgumentValue('solar_ref_f_light', user_arguments)
    solar_ref_b_light = runner.getDoubleArgumentValue('solar_ref_b_light', user_arguments)
    vis_trans_light = runner.getDoubleArgumentValue('vis_trans_light', user_arguments)
    vis_ref_f_light = runner.getDoubleArgumentValue('vis_ref_f_light', user_arguments)
    vis_ref_b_light = runner.getDoubleArgumentValue('vis_ref_b_light', user_arguments)
    ir_trans_light = runner.getDoubleArgumentValue('ir_trans_light', user_arguments)
    ir_emis_f_light = runner.getDoubleArgumentValue('ir_emis_f_light', user_arguments)
    ir_emis_b_light = runner.getDoubleArgumentValue('ir_emis_b_light', user_arguments)
    solar_trans_dark = runner.getDoubleArgumentValue('solar_trans_dark', user_arguments)
    solar_ref_f_dark = runner.getDoubleArgumentValue('solar_ref_f_dark', user_arguments)
    solar_ref_b_dark = runner.getDoubleArgumentValue('solar_ref_b_dark', user_arguments)
    vis_trans_dark = runner.getDoubleArgumentValue('vis_trans_dark', user_arguments)
    vis_ref_f_dark = runner.getDoubleArgumentValue('vis_ref_f_dark', user_arguments)
    vis_ref_b_dark = runner.getDoubleArgumentValue('vis_ref_b_dark', user_arguments)
    ir_trans_dark = runner.getDoubleArgumentValue('ir_trans_dark', user_arguments)
    ir_emis_f_dark = runner.getDoubleArgumentValue('ir_emis_f_dark', user_arguments)
    ir_emis_b_dark = runner.getDoubleArgumentValue('ir_emis_b_dark', user_arguments)
    gas_type = runner.getStringArgumentValue('gas_type', user_arguments)
    ctrl_type = runner.getStringArgumentValue('ctrl_type', user_arguments)
    glare_stp = runner.getDoubleArgumentValue('glare_stp', user_arguments)
    solar_rad_stp = runner.getDoubleArgumentValue('solar_rad_stp', user_arguments)
    illum_stp = runner.getDoubleArgumentValue('illum_stp', user_arguments)

    # validate inputs rationality
    if thickness_electro_glass > 0.02 # 20mm
      runner.registerError("Electrochromic glass layer is thicker than 20mm, which is abnormally high.")
      return false
    elsif thickness_electro_glass >= 0.01
      runner.registerWarning("Electrochromic glass layer is thicker than 10mm, which is higher than normal.")
    elsif thickness_electro_glass <= 0
      runner.registerError("Electrochromic glass layer thickness should be positive.")
      return false
    end

    if thickness_air_gap > 0.1 # 100mm
      runner.registerError("Air gap layer is thicker than 100mm, which is abnormally high.")
      return false
    elsif thickness_air_gap >= 0.03
      runner.registerWarning("Air gap layer is thicker than 30mm, which is higher than normal.")
    elsif thickness_air_gap <= 0
      runner.registerError("Air gap layer thickness should be positive.")
      return false
    end

    if thickness_clear_glass > 0.02 # 20mm
      runner.registerError("Clear glass layer is thicker than 20mm, which is abnormally high.")
      return false
    elsif thickness_clear_glass >= 0.01
      runner.registerWarning("Clear glass layer is thicker than 10mm, which is higher than normal.")
    elsif thickness_clear_glass <= 0
      runner.registerError("Clear glass layer thickness should be positive.")
      return false
    end

    if tc_electro_glass <= 0
      runner.registerError("Thermal conductivity should be positive.")
      return false
    end

    if glare_stp <= 0
      runner.registerError("Glare setpoint should be positive.")
      return false
    elsif glare_stp > 50
      runner.registerWarning("Glare setpoint is greater than 50, which is higher than normal.")
    end

    if solar_rad_stp <= 0
      runner.registerError("Solar radiation setpoint should be positive.")
      return false
    elsif solar_rad_stp > 2000
      runner.registerWarning("Solar radiation setpoint is greater than 2000, which is higher than normal.")
    end

    if illum_stp <= 0
      runner.registerError("Illuminance setpoint should be positive.")
      return false
    elsif illum_stp > 800
      runner.registerWarning("Illuminance setpoint is greater than 800W/m2, which is higher than normal.")
    end

    glazing_param_names = [
      'solar_trans_light',
      'solar_ref_f_light',
      'solar_ref_b_light',
      'vis_trans_light',
      'vis_ref_f_light',
      'vis_ref_b_light',
      'ir_trans_light',
      'ir_emis_f_light',
      'ir_emis_b_light',
      'solar_trans_dark',
      'solar_ref_f_dark',
      'solar_ref_b_dark',
      'vis_trans_dark',
      'vis_ref_f_dark',
      'vis_ref_b_dark',
      'ir_trans_dark',
      'ir_emis_f_dark',
      'ir_emis_b_dark'
    ]

    # validate the property inputs of glazing material
    glazing_param_names.each do |param_name|
      param_val = eval(param_name)
      if param_val > 1
        runner.registerError("Glazing parameter #{param_name} should be no greater than 1.")
        return false
      elsif param_val < 0
        runner.registerError("Glazing parameter #{param_name} should be non-negative.")
        return false
      end
    end

    # ------------------------------------------------------------------------------------
    # Replace existing window construction with electrochromic window
    new_elec_win_light_cons = OpenStudio::Model::Construction.new(model)
    new_elec_win_light_cons.setName('Electrochromic window construction light state')
    new_elec_win_dark_cons = OpenStudio::Model::Construction.new(model)
    new_elec_win_dark_cons.setName('Electrochromic window construction dark state')
    # clear glass layer
    clear_glazing = OpenStudio::Model::StandardGlazing.new(model)
    clear_glazing.setName("CLEAR #{thickness_clear_glass*1000}mm glass")
    clear_glazing.setThickness(thickness_clear_glass)
    clear_glazing.setSolarTransmittanceatNormalIncidence(0.834)
    clear_glazing.setFrontSideSolarReflectanceatNormalIncidence(0.075)
    clear_glazing.setBackSideSolarReflectanceatNormalIncidence(0.075)
    clear_glazing.setVisibleTransmittance(0.899)
    clear_glazing.setFrontSideVisibleReflectanceatNormalIncidence(0.083)
    clear_glazing.setBackSideVisibleReflectanceatNormalIncidence(0.083)
    clear_glazing.setInfraredTransmittanceatNormalIncidence(0.0)
    clear_glazing.setFrontSideInfraredHemisphericalEmissivity(0.84)
    clear_glazing.setBackSideInfraredHemisphericalEmissivity(0.84)
    clear_glazing.setThermalConductivity(1.0)
    # electrochromic layer
    # light state
    elec_glazing_light = OpenStudio::Model::StandardGlazing.new(model)
    elec_glazing_light.setName('Electrochromic glass light state')
    elec_glazing_light.setThickness(thickness_electro_glass)
    elec_glazing_light.setSolarTransmittanceatNormalIncidence(solar_trans_light)
    elec_glazing_light.setFrontSideSolarReflectanceatNormalIncidence(solar_ref_f_light)
    elec_glazing_light.setBackSideSolarReflectanceatNormalIncidence(solar_ref_b_light)
    elec_glazing_light.setVisibleTransmittance(vis_trans_light)
    elec_glazing_light.setFrontSideVisibleReflectanceatNormalIncidence(vis_ref_f_light)
    elec_glazing_light.setBackSideVisibleReflectanceatNormalIncidence(vis_ref_b_light)
    elec_glazing_light.setInfraredTransmittanceatNormalIncidence(ir_trans_light)
    elec_glazing_light.setFrontSideInfraredHemisphericalEmissivity(ir_emis_f_light)
    elec_glazing_light.setBackSideInfraredHemisphericalEmissivity(ir_emis_b_light)
    elec_glazing_light.setThermalConductivity(tc_electro_glass)
    # dark state
    elec_glazing_dark = OpenStudio::Model::StandardGlazing.new(model)
    elec_glazing_dark.setName('Electrochromic glass dark state')
    elec_glazing_dark.setThickness(thickness_electro_glass)
    elec_glazing_dark.setSolarTransmittanceatNormalIncidence(solar_trans_dark)
    elec_glazing_dark.setFrontSideSolarReflectanceatNormalIncidence(solar_ref_f_dark)
    elec_glazing_dark.setBackSideSolarReflectanceatNormalIncidence(solar_ref_b_dark)
    elec_glazing_dark.setVisibleTransmittance(vis_trans_dark)
    elec_glazing_dark.setFrontSideVisibleReflectanceatNormalIncidence(vis_ref_f_dark)
    elec_glazing_dark.setBackSideVisibleReflectanceatNormalIncidence(vis_ref_b_dark)
    elec_glazing_dark.setInfraredTransmittanceatNormalIncidence(ir_trans_dark)
    elec_glazing_dark.setFrontSideInfraredHemisphericalEmissivity(ir_emis_f_dark)
    elec_glazing_dark.setBackSideInfraredHemisphericalEmissivity(ir_emis_b_dark)
    elec_glazing_dark.setThermalConductivity(tc_electro_glass)
    # air gap layer
    gas_layer = OpenStudio::Model::Gas.new(model)
    gas_layer.setName("WinAirGap")
    gas_layer.setGasType(gas_type)
    gas_layer.setThickness(thickness_air_gap)

    # TODO: make sure the clear glazing is inside and electrochromic is outside facing
    win_layers_light = OpenStudio::Model::MaterialVector.new
    win_layers_dark = OpenStudio::Model::MaterialVector.new
    win_layers_light << clear_glazing
    win_layers_light << gas_layer
    win_layers_light << elec_glazing_light
    win_layers_dark << clear_glazing
    win_layers_dark << gas_layer
    win_layers_dark << elec_glazing_dark
    new_elec_win_light_cons.setLayers(win_layers_light)
    new_elec_win_dark_cons.setLayers(win_layers_dark)

    count_changed_win = 0
    model.getSubSurfaces.each do |sub_surface|
      # puts "sub_surface #{sub_surface} type: #{sub_surface.subSurfaceType}"
      # skip subsurfaces that are not exterior windows, i.e., only change exterior window to electrochromic windows
      next unless (sub_surface.outsideBoundaryCondition == 'Outdoors' && sub_surface.subSurfaceType.downcase.include?('window'))
      sub_surface.setConstruction(new_elec_win_light_cons)
      count_changed_win += 1
    end

    model.getSpaces.each do |space|
      # ext_win_list = []
      ext_win_list = OpenStudio::Model::SubSurfaceVector.new
      space.surfaces.each do |surf|
        surf.subSurfaces.each do |sub_surface|
          ext_win_list << sub_surface if (sub_surface.outsideBoundaryCondition == 'Outdoors' && sub_surface.subSurfaceType.downcase.include?('window'))
        end
      end

      # add WindowShadingControl if there is exterior window in the space
      unless ext_win_list.empty?
        shade_control = OpenStudio::Model::ShadingControl.new(new_elec_win_dark_cons)
        shade_control.setShadingType('SwitchableGlazing')
        shade_control.setShadingControlType(ctrl_type)
        shade_control.setSubSurfaces(ext_win_list)
        case ctrl_type
        when 'OnIfHighGlare'
          shade_control.setGlareControlIsActive(true)
        when 'OnIfHighSolarOnWindow'
          shade_control.setSetpoint(solar_rad_stp)
        end

        if space.daylightingControls.empty?
          # create daylighting control if no existing
          daylight_ctrl = OpenStudio::Model::DaylightingControl.new(model)
          daylight_ctrl.setName(space.name.to_s + " daylighting control")
          daylight_ctrl.setSpace(space)
          # get space center point position
          x,y = 0,0
          space.floorPrint.each do |pt|
            x += pt.x
            y += pt.y
          end
          num_pt = space.floorPrint.length
          x /= (num_pt*1.0)
          y /= (num_pt*1.0)
          z = 0.8  # working plane
          daylight_ctrl.setPosition(OpenStudio::Point3d.new(x,y,z))

          # Set the rest of parameters
          daylight_ctrl.setMaximumAllowableDiscomfortGlareIndex(glare_stp)
          daylight_ctrl.setIlluminanceSetpoint(illum_stp)
        else
          # modify existing daylighting control if any
          space.daylightingControls.each do |daylight_ctrl|
            case ctrl_type
            when 'OnIfHighGlare'
              daylight_ctrl.setMaximumAllowableDiscomfortGlareIndex(glare_stp)
            when 'MeetDaylightIlluminanceSetpoint'
              daylight_ctrl.setIlluminanceSetpoint(illum_stp)
            end
          end
        end

        zone = space.thermalZone
        if zone.is_initialized
          zone = zone.get
          # set primary daylighting control
          unless zone.primaryDaylightingControl.is_initialized
            if space.daylightingControls.length == 1
              zone.setPrimaryDaylightingControl(space.daylightingControls[0])
              zone.setFractionofZoneControlledbyPrimaryDaylightingControl(1.0)
            else
              zone.setPrimaryDaylightingControl(space.daylightingControls[0])
              zone.setFractionofZoneControlledbyPrimaryDaylightingControl(0.5)
              zone.setSecondaryDaylightingControl(space.daylightingControls[1])
              zone.setFractionofZoneControlledbySecondaryDaylightingControl(0.5)
            end

          end
        else
          runner.registerWarning("No thermal zone defined for space #{space.name}, can't assign daylighting control.")
        end
      end
    end

    # report final condition of model
    runner.registerFinalCondition("#{count_changed_win} exterior windows are replaced with electrochromic window.")

    return true
  end
end

# register the measure to be used by the application
AddElectrochromicWindow.new.registerWithApplication
