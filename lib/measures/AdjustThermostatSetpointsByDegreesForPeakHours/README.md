

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


### Degrees Fahrenheit to Adjust heating Setpoint By

**Name:** heating_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First start date for heating setpoint adjustment
In MM-DD format
**Name:** heating_start_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First end date for heating setpoint adjustment
In MM-DD format
**Name:** heating_end_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Second start date for heating setpoint adjustment (optional)
Specify a date in MM-DD format if you want a second season of heating setpoint adjustment; leave blank if not needed.
**Name:** heating_start_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second end date for heating setpoint adjustment
Specify a date in MM-DD format if you want a second season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** heating_end_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third start date for heating setpoint adjustment (optional)
Specify a date in MM-DD format if you want a third season of heating setpoint adjustment; leave blank if not needed.
**Name:** heating_start_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third end date for heating setpoint adjustment
Specify a date in MM-DD format if you want a third season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** heating_end_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth start date for heating setpoint adjustment (optional)
Specify a date in MM-DD format if you want a fourth season of heating setpoint adjustment; leave blank if not needed.
**Name:** heating_start_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth end date for heating setpoint adjustment
Specify a date in MM-DD format if you want a fourth season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** heating_end_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth start date for heating setpoint adjustment (optional)
Specify a date in MM-DD format if you want a fifth season of heating setpoint adjustment; leave blank if not needed.
**Name:** heating_start_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth end date for heating setpoint adjustment
Specify a date in MM-DD format if you want a fifth season of heating setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** heating_end_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of heating setpoint adjustment for the first season
In HH:MM:SS format
**Name:** heating_start_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End time of heating setpoint adjustment for the first season
In HH:MM:SS format
**Name:** heating_end_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start time of heating setpoint adjustment for the second season (optional)
In HH:MM:SS format
**Name:** heating_start_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of heating setpoint adjustment for the second season (optional)
In HH:MM:SS format
**Name:** heating_end_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of heating setpoint adjustment for the third season (optional)
In HH:MM:SS format
**Name:** heating_start_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of heating setpoint adjustment for the third season (optional)
In HH:MM:SS format
**Name:** heating_end_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of heating setpoint adjustment for the fourth season (optional)
In HH:MM:SS format
**Name:** heating_start_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of heating setpoint adjustment for the fourth season (optional)
In HH:MM:SS format
**Name:** heating_end_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of heating setpoint adjustment for the fifth season (optional)
In HH:MM:SS format
**Name:** heating_start_time5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of heating setpoint adjustment for the fifth season (optional)
In HH:MM:SS format
**Name:** heating_end_time5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Degrees Fahrenheit to Adjust Cooling Setpoint By

**Name:** cooling_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First start date for cooling setpoint adjustment
In MM-DD format
**Name:** cooling_start_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First end date for cooling setpoint adjustment
In MM-DD format
**Name:** cooling_end_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Second start date for cooling setpoint adjustment (optional)
Specify a date in MM-DD format if you want a second season of cooling setpoint adjustment; leave blank if not needed.
**Name:** cooling_start_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second end date for cooling setpoint adjustment
Specify a date in MM-DD format if you want a second season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** cooling_end_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third start date for cooling setpoint adjustment (optional)
Specify a date in MM-DD format if you want a third season of cooling setpoint adjustment; leave blank if not needed.
**Name:** cooling_start_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third end date for cooling setpoint adjustment
Specify a date in MM-DD format if you want a third season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** cooling_end_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth start date for cooling setpoint adjustment (optional)
Specify a date in MM-DD format if you want a fourth season of cooling setpoint adjustment; leave blank if not needed.
**Name:** cooling_start_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth end date for cooling setpoint adjustment
Specify a date in MM-DD format if you want a fourth season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** cooling_end_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth start date for cooling setpoint adjustment (optional)
Specify a date in MM-DD format if you want a fifth season of cooling setpoint adjustment; leave blank if not needed.
**Name:** cooling_start_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth end date for cooling setpoint adjustment
Specify a date in MM-DD format if you want a fifth season of cooling setpoint adjustment; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** cooling_end_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of cooling setpoint adjustment for the first season
In HH:MM:SS format
**Name:** cooling_start_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End time of cooling setpoint adjustment for the first season
In HH:MM:SS format
**Name:** cooling_end_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start time of cooling setpoint adjustment for the second season (optional)
In HH:MM:SS format
**Name:** cooling_start_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of cooling setpoint adjustment for the second season (optional)
In HH:MM:SS format
**Name:** cooling_end_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of cooling setpoint adjustment for the third season (optional)
In HH:MM:SS format
**Name:** cooling_start_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of cooling setpoint adjustment for the third season (optional)
In HH:MM:SS format
**Name:** cooling_end_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of cooling setpoint adjustment for the fourth season (optional)
In HH:MM:SS format
**Name:** cooling_start_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of cooling setpoint adjustment for the fourth season (optional)
In HH:MM:SS format
**Name:** cooling_end_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of cooling setpoint adjustment for the fifth season (optional)
In HH:MM:SS format
**Name:** cooling_start_time5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of cooling setpoint adjustment for the fifth season (optional)
In HH:MM:SS format
**Name:** cooling_end_time5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Use alternative default start and end time based on the state of the model from the Cambium load profile peak period?
This will overwrite the start and end time and date provided by the user
**Name:** alt_periods,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




