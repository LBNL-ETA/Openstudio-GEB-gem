

###### (Automatically generated documentation)

# Preheating

## Description
This measure adjusts heating schedules by a user specified number of degrees for the specified time period of a day. User can also specify the start and end date for the adjustment. This is applied throughout the entire building.

## Modeler Description
This measure will clone all of the schedules that are used as heating setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values. HVAC operation schedule will also be changed. 

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Degrees Fahrenheit to Adjust Heating Setpoint By

**Name:** heating_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First Start Date for Pre-heating
In MM-DD format
**Name:** heating_startdate1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### First End Date for Pre-heating
In MM-DD format
**Name:** heating_enddate1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second Start Date for Pre-heating
In MM-DD format
**Name:** heating_startdate2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### First End Date for Pre-heating
In MM-DD format
**Name:** heating_enddate2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start Time for Pre-heating
In HH:MM:SS format
**Name:** starttime_heating,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End Time for Pre-heating
In HH:MM:SS format
**Name:** endtime_heating,
**Type:** String,
**Units:** ,
**Required:** true,
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




