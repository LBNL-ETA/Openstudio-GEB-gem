

###### (Automatically generated documentation)

# Adjust thermostat setpoint by degrees for peak hours

## Description
This measure adjusts heating and cooling setpoints by a user-specified number of degrees and a user-specified time period. This is applied throughout the entire building.

## Modeler Description
This measure will clone all of the schedules that are used as heating and cooling setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values during a specified time period. There is a checkbox to determine if the thermostat for design days should be altered.

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

### Daily Start Time for Cooling Adjustment
Use 24 hour format HH:MM:SS
**Name:** cooling_daily_starttime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily End Time for Cooling Adjustment
Use 24 hour format HH:MM:SS
**Name:** cooling_daily_endtime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start Date for Cooling Adjustment
In MM-DD format
**Name:** cooling_startdate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Date for Cooling Adjustment
In MM-DD format
**Name:** cooling_enddate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Degrees Fahrenheit to Adjust heating Setpoint By

**Name:** heating_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Time for Heating Adjustment
Use 24 hour format HH:MM:SS
**Name:** heating_daily_starttime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Time for Heating Adjustment
Use 24 hour format HH:MM:SS
**Name:** heating_daily_endtime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start Date for Heating Adjustment Period 1
In MM-DD format
**Name:** heating_startdate_1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Date for Heating Adjustment Period 1
In MM-DD format
**Name:** heating_enddate_1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start Date for Heating Adjustment Period 2
In MM-DD format
**Name:** heating_startdate_2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Date for Heating Adjustment Period 2
In MM-DD format
**Name:** heating_enddate_2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Alter Design Day Thermostats

**Name:** alter_design_days,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Enable Climate-specific Periods Setting?

**Name:** auto_date,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Alternate Peak and Take Periods

**Name:** alt_periods,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false




