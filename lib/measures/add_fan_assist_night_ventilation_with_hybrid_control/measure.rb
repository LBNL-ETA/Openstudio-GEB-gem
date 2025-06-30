# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

    # setup hash to hold path objects and exhaust zones
    path_objects = {}
    exhaust_zones = {}
    zones_w_ext_windows = []
    nv_zone_list = {}  # save zones with exterior windows and their zone ventilation object info

    model.getSpaces.each do |space|
      next if space.thermalZone.empty?
      thermal_zone = space.thermalZone.get

      # store airflow paths for future use
      path_objects[thermal_zone] = inspect_airflow_surfaces(thermal_zone)

      # get the list of zones with exterior windows
      space.surfaces.sort.each do |surface|
        surface.subSurfaces.sort.each do |subsurface|
          if (subsurface.subSurfaceType == 'OperableWindow' || subsurface.subSurfaceType == 'FixedWindow') && subsurface.outsideBoundaryCondition == 'Outdoors'
            zones_w_ext_windows << thermal_zone unless zones_w_ext_windows.include?(thermal_zone)
          end
        end
      end
    end

    #################### STEP 2: add zone ventilation objects and zone mixing objects ################
    # setup has to store paths
    flow_paths = {}
    # setup night ventilation schedule
    night_vent_sch = create_sch(model, "night ventilation sch", night_vent_starttime, night_vent_endtime, night_vent_startdate_os, night_vent_enddate_os, wknds)

    # return as NA if no exterior operable windows
    if zones_w_ext_windows.empty?
      runner.registerAsNotApplicable('No zones with exterior operable windows were found. The model will not be altered')
      return true
    end

    # Loop through zones in hash and make natural ventilation objects so the sum equals the user specified target
    zones_w_ext_windows.each do |zone|
      zone_ventilation = OpenStudio::Model::ZoneVentilationDesignFlowRate.new(model)
      zone_ventilation.setName("PathStart_#{zone.name}")
      zone_ventilation.addToThermalZone(zone)
      zone_ventilation.setVentilationType('Exhaust') # switched from Natural to use power. Need to set fan properties. Used exhaust so no heat from fan in stream
      zone_ventilation.setAirChangesperHour(design_night_vent_ach)

      # inputs used for fan power
      zone_ventilation.setFanPressureRise(fan_pressure_rise)
      zone_ventilation.setFanTotalEfficiency(efficiency)

      # set schedule from user arg
      zone_ventilation.setSchedule(night_vent_sch)

      # set ventilation control thresholds
      zone_ventilation.setMinimumIndoorTemperature(min_indoor_temp)
      zone_ventilation.setMaximumIndoorTemperature(max_indoor_temp)
      zone_ventilation.setMinimumOutdoorTemperature(min_outdoor_temp)
      zone_ventilation.setMaximumOutdoorTemperature(max_outdoor_temp)
      zone_ventilation.setDeltaTemperature(delta_temp)
      zone_ventilation.setMaximumWindSpeed(max_wind_speed)
      nv_zone_list[zone.name.to_s] = zone_ventilation
      runner.registerInfo("Added natural ventilation object to #{zone.name} of #{design_night_vent_ach} air change rate per hour.")

      # start trace of path adding air mixing objects
      found_path_end = false
      flow_paths[zone] = []
      current_zone = zone
      zones_used_for_this_path = [current_zone]
      until found_path_end
        found_ceiling = false
        found_wall = false
        path_objects[current_zone].each do |object|
          next if zones_used_for_this_path.include?(object[0])
          next if object[1].to_s != 'RoofCeiling'
          next if zones_w_ext_windows.include?(object[0])
          if found_ceiling
            runner.registerWarning("Found more than one possible airflow path for #{current_zone.name}")
          else
            flow_paths[zone] << object[0]
            current_zone = object[0]
            zones_used_for_this_path << object[0]
            found_ceiling = true
          end
        end
        unless found_ceiling
          path_objects[current_zone].each do |object|
            next if zones_used_for_this_path.include?(object[0])
            next if object[1].to_s != 'Wall'
            next if zones_w_ext_windows.include?(object[0])
            if found_wall
              runner.registerWarning("Found more than one possible airflow path for #{current_zone.name}")
            else
              flow_paths[zone] << object[0]
              current_zone = object[0]
              zones_used_for_this_path << object[0]
              found_wall = true
            end
          end
        end
        if !found_ceiling && !found_wall
          found_path_end = true
        end
      end

      # add one way air mixing objects along path zones
      zone_path_string_array = [zone.name]
      vent_zone = zone
      source_zone = zone
      flow_paths[zone].each do |zone|
        zone_mixing = OpenStudio::Model::ZoneMixing.new(zone)
        zone_mixing.setName("PathStart_#{vent_zone.name}_#{source_zone.name}")
        zone_mixing.setSourceZone(source_zone)
        zone_mixing.setAirChangesperHour(design_night_vent_ach)

        # set min outdoor temp schedule
        min_outdoor_sch = OpenStudio::Model::ScheduleConstant.new(model)
        min_outdoor_sch.setValue(min_outdoor_temp)
        zone_mixing.setMinimumOutdoorTemperatureSchedule(min_outdoor_sch)

        # set schedule from user arg
        zone_mixing.setSchedule(night_vent_sch)

        # change source zone to what was just target zone
        zone_path_string_array << zone.name
        source_zone = zone
      end
      runner.registerInfo("Added Zone Mixing Path: #{zone_path_string_array.join(' > ')}")

      # add ach to exhaust zones
      if !flow_paths[zone].empty?
        if exhaust_zones.include? flow_paths[zone].last
          exhaust_zones[flow_paths[zone].last] += design_night_vent_ach
        else
          exhaust_zones[flow_paths[zone].last] = design_night_vent_ach
        end
      else
        # extra code if there is no path from entry zone
        if exhaust_zones.include? zone
          exhaust_zones[zone] += design_night_vent_ach
        else
          exhaust_zones[zone] = design_night_vent_ach
          runner.registerWarning("#{zone.name} doesn't have path to other zones. Exhaust assumed to be with the same zone as air enters.")
        end
      end
    end

    # report how much air (by ach) exhausts to each exhaust zone
    # when I add an exhaust fan to the top floor I want it to use energy but I don't want to move any additional air.
    # The air is already being brought into the zone by the zone mixing objects
    exhaust_zones.each do |zone, ach|
      runner.registerInfo("Zone Mixing flow rate into #{zone.name} is #{ach} air change per hour. Fan Consumption included with zone ventilation zones.")

      # check for exterior surface area
      if zone.exteriorSurfaceArea == 0
        runner.registerWarning("Exhaust Zone #{zone.name} doesn't appear to have any exterior exposure. Review the paths to see that this is the expected result.")
      end
    end

    # warn if zone multiplier are used
    non_default_multiplier = []
    model.getThermalZones.each do |zone|
      if zone.multiplier > 1
        non_default_multiplier << zone
      end
    end
    if !non_default_multiplier.empty?
      runner.registerWarning("This measure is not intended to be use when thermal zones have a non 1 multiplier. #{non_default_multiplier.size} zones in this model have multipliers greater than one. Results are likley invalid.")
    end


    #################### STEP 3: add hybrid ventilation control objects ################

    # TODO: Simple Airflow Control Type Schedule Name set as 1 denote group control
    # if a zone has more than one windows, group control allows them to be operated simultaneously
    # if an airloopHVAC controls more than one zone, only one AvailabilityManagerHybridVentilation is allowed for an airloop, group control will
    # decides the zones controlled by this airloop based on the selected ZoneVentilation object input
    vent_control_sch = create_sch(model, "ventilation control sch", night_vent_starttime, night_vent_endtime, night_vent_startdate_os, night_vent_enddate_os, wknds, 1, 0)
    simple_airflow_control_type_sch = OpenStudio::Model::ScheduleConstant.new(model)
    simple_airflow_control_type_sch.setName("simple airflow control type sch - group control")
    simple_airflow_control_type_sch.setValue(1)

    # part1: loop through all the airloopHVAC and add hybrid ventilation control
    model.getAirLoopHVACs.sort.each do |air_loop|
      max_zone_area = 0
      nv_zone_with_max_area = nil
      air_loop.thermalZones.each do |thermal_zone|
        if max_zone_area < thermal_zone.floorArea && nv_zone_list.key?(thermal_zone.name.to_s)
          max_zone_area = thermal_zone.floorArea
          nv_zone_with_max_area = thermal_zone.name.to_s
        end
      end
      next if nv_zone_with_max_area.nil? # if there is no NV zone in this airloop, skip
      has_hybrid_avail_manager = false
      air_loop.availabilityManagers.sort.each do |avail_mgr|
        next if avail_mgr.to_AvailabilityManagerHybridVentilation.empty?
        if avail_mgr.to_AvailabilityManagerHybridVentilation.is_initialized
          has_hybrid_avail_manager = true
          avail_mgr_hybr_vent = avail_mgr.to_AvailabilityManagerHybridVentilation.get
          avail_mgr_hybr_vent.setVentilationControlModeSchedule(vent_control_sch)
          avail_mgr_hybr_vent.setControlledZone(model.getThermalZoneByName(nv_zone_with_max_area).get)
          avail_mgr_hybr_vent.setMinimumOutdoorTemperature(min_outdoor_temp)
          avail_mgr_hybr_vent.setMaximumOutdoorTemperature(max_outdoor_temp)
          avail_mgr_hybr_vent.setMaximumWindSpeed(max_wind_speed)
          avail_mgr_hybr_vent.setSimpleAirflowControlTypeSchedule(simple_airflow_control_type_sch)
          avail_mgr_hybr_vent.setZoneVentilationObject(nv_zone_list[nv_zone_with_max_area])
        end
      end

      unless has_hybrid_avail_manager
        avail_mgr_hybr_vent = OpenStudio::Model::AvailabilityManagerHybridVentilation.new(model)
        avail_mgr_hybr_vent.setName(air_loop.name.to_s + " HybridVentilation AvailabilityManager")
        avail_mgr_hybr_vent.setVentilationControlModeSchedule(vent_control_sch)
        avail_mgr_hybr_vent.setControlledZone(model.getThermalZoneByName(nv_zone_with_max_area).get)
        avail_mgr_hybr_vent.setMinimumOutdoorTemperature(min_outdoor_temp)
        avail_mgr_hybr_vent.setMaximumOutdoorTemperature(max_outdoor_temp)
        avail_mgr_hybr_vent.setMaximumWindSpeed(max_wind_speed)
        avail_mgr_hybr_vent.setSimpleAirflowControlTypeSchedule(simple_airflow_control_type_sch)
        avail_mgr_hybr_vent.setZoneVentilationObject(nv_zone_list[nv_zone_with_max_area])
        air_loop.addAvailabilityManager(avail_mgr_hybr_vent)
      end

      # remove thermal zones in this airloop from the nv_zone_list hash
      air_loop.thermalZones.each do |thermal_zone|
        if nv_zone_list.key?(thermal_zone.name.to_s)
          nv_zone_list.delete(thermal_zone.name.to_s)
        end
      end
    end

    # part2: loop through all spaces, add hybrid vent control to zones that are not connected to airloopHVAC but uses zonal equipment
    nv_zone_list.each do |zone_name, nv_obj|
      avail_mgr_hybr_vent = OpenStudio::Model::AvailabilityManagerHybridVentilation.new(model)
      avail_mgr_hybr_vent.setName(zone_name + " HybridVentilation AvailabilityManager")
      avail_mgr_hybr_vent.setVentilationControlModeSchedule(vent_control_sch)
      avail_mgr_hybr_vent.setControlledZone(model.getThermalZoneByName(zone_name).get)
      avail_mgr_hybr_vent.setMinimumOutdoorTemperature(min_outdoor_temp)
      avail_mgr_hybr_vent.setMaximumOutdoorTemperature(max_outdoor_temp)
      avail_mgr_hybr_vent.setMaximumWindSpeed(max_wind_speed)
      avail_mgr_hybr_vent.setSimpleAirflowControlTypeSchedule(simple_airflow_control_type_sch)
      avail_mgr_hybr_vent.setZoneVentilationObject(nv_obj)
    end

    # echo added AvailabilityManagerHybridVentilation object number to the user
    runner.registerInfo("A total of #{model.getAvailabilityManagerHybridVentilations.size} AvailabilityManagerHybridVentilations were added.")

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getZoneVentilationDesignFlowRates.size} zone ventilation design flow rate objects and #{model.getZoneMixings.size} zone mixing objects.")

    # adding useful output variables for diagnostics
    OpenStudio::Model::OutputVariable.new('Zone Mixing Current Density Air Volume Flow Rate', model)
    OpenStudio::Model::OutputVariable.new('Zone Ventilation Current Density Volume Flow Rate', model)
    OpenStudio::Model::OutputVariable.new('Zone Ventilation Fan Electric Energy', model)
    OpenStudio::Model::OutputVariable.new('Zone Outdoor Air Drybulb Temperature', model)

    return true
  end
end

# register the measure to be used by the application
AddFanAssistNightVentilationWithHybridControl.new.registerWithApplication
