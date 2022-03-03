

###### (Automatically generated documentation)

# Precooling

## Description
This measure adjusts cooling schedules by a user specified number of degrees for the specified time period of a day. User can also specify the start and end date for the adjustment. This is applied throughout the entire building.

## Modeler Description
This measure will clone all of the schedules that are used as  cooling setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values. HVAC operation schedule will also be changed. There is a checkbox to determine if the thermostat for design days should be altered.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Degrees Fahrenheit to Adjust Cooling Setpoint By

**Name:** cooling_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Time for Pre-cooling
In HH:MM:SS format
**Name:** starttime_cooling,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Time for Pre-cooling
In HH:MM:SS format
**Name:** endtime_cooling,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Date for Pre-cooling
In MM-DD format
**Name:** cooling_startdate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Date for Pre-cooling
In MM-DD format
**Name:** cooling_enddate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Enable Climate-specific Periods Setting ?

**Name:** auto_date,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Alternate Peak and Take Periods ?

**Name:** alt_periods,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




