

###### (Automatically generated documentation)

# Add fan assist night ventilation with hybrid control

## Description
This measure is modified based on the OS measure "fan_assist_night_ventilation" from "openstudio-ee-gem".  It adds night ventilation that is enabled by opening windows assisted by exhaust fans. Hybrid ventilation  control is added to avoid simultaneous operation of windows and HVAC.

## Modeler Description
This measure adds a zone ventilation object to each zone with operable windwos. The measure will first  look for a celing opening to find a connection for zone a zone mixing object. If a ceiling isn't found,  then it looks for a wall. The end result is zone ventilation object followed by a path of zone mixing objects.  The exhaust fan consumption is modeled in the zone ventilation object, but no heat is brought in from the fan. 
 Different from the original 'fan_assist_night_ventilation' measure, this measure can be applied to models  with mechenical systems. HybridVentilationAvailabilityManager is added to airloops and zonal systems to avoid  simultaneous operation of windows and HVAC. The zone ventilation is controlled by a combination of schedule,  indoor and outdoor temperature, and wind speed.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Design night ventilation air change rate defined by ACH-air changes per hour

**Name:** design_night_vent_ach,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Fan Pressure Rise

**Name:** fan_pressure_rise,
**Type:** Double,
**Units:** Pa,
**Required:** true,
**Model Dependent:** false


### Fan Total Efficiency

**Name:** efficiency,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Minimum Indoor Temperature (degC)
The indoor temperature below which ventilation is shutoff.
**Name:** min_indoor_temp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Maximum Indoor Temperature (degC)
The indoor temperature above which ventilation is shutoff.
**Name:** max_indoor_temp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Minimum Indoor-Outdoor Temperature Difference (degC)
This is the temperature difference between the indoor and outdoor air dry-bulb temperatures below which ventilation is shutoff.  For example, a delta temperature of 2 degC means ventilation is available if the outside air temperature is at least 2 degC cooler than the zone air temperature. Values can be negative.
**Name:** delta_temp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Minimum Outdoor Temperature (degC)
The outdoor temperature below which ventilation is shut off.
**Name:** min_outdoor_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Maximum Outdoor Temperature (degC)
The outdoor temperature above which ventilation is shut off.
**Name:** max_outdoor_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Maximum Wind Speed (m/s)
This is the wind speed above which ventilation is shut off.  The default values assume windows are closed when wind is above a gentle breeze to avoid blowing around papers in the space.
**Name:** max_wind_speed,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Daily Start Time for natural ventilation
Use 24 hour format (HR:MM)
**Name:** night_vent_starttime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Daily End Time for natural ventilation
Use 24 hour format (HR:MM)
**Name:** night_vent_endtime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Start Date for natural ventilation
In MM-DD format
**Name:** night_vent_startdate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### End Date for natural ventilation
In MM-DD format
**Name:** night_vent_enddate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Allow night time ventilation on weekends

**Name:** wknds,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false






