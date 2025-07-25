

###### (Automatically generated documentation)

# Precooling

## Description
This measure adjusts cooling schedules by a user specified number of degrees for the specified time period of a day. User can also specify the start and end date for the adjustment. This is applied throughout the entire building.

## Modeler Description
This measure will clone all of the schedules that are used for cooling setpoints for thermal zones. The clones are hooked up to the thermostat in place of the original schedules. Then the schedules are adjusted by the specified values. HVAC operation schedule will also be changed. There is a checkbox to determine if the thermostat for design days should be altered.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Degrees Fahrenheit to Adjust Cooling Setpoint By
Use negative value for reducing cooling setpoint during precooling period
**Name:** cooling_adjustment,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First start date for precooling
In MM-DD format
**Name:** start_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First end date for precooling
In MM-DD format
**Name:** end_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Second start date for precooling (optional)
Specify a date in MM-DD format if you want a second season of precooling; leave blank if not needed.
**Name:** start_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second end date for precooling
Specify a date in MM-DD format if you want a second season of precooling; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third start date for precooling (optional)
Specify a date in MM-DD format if you want a third season of precooling; leave blank if not needed.
**Name:** start_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third end date for precooling
Specify a date in MM-DD format if you want a third season of precooling; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth start date for precooling (optional)
Specify a date in MM-DD format if you want a fourth season of precooling; leave blank if not needed.
**Name:** start_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth end date for precooling
Specify a date in MM-DD format if you want a fourth season of precooling; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth start date for precooling (optional)
Specify a date in MM-DD format if you want a fifth season of precooling; leave blank if not needed.
**Name:** start_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth end date for precooling
Specify a date in MM-DD format if you want a fifth season of precooling; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of precooling for the first season
In HH:MM:SS format
**Name:** start_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End time of precooling for the first season
In HH:MM:SS format
**Name:** end_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start time of precooling for the second season (optional)
In HH:MM:SS format
**Name:** start_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of precooling for the second season (optional)
In HH:MM:SS format
**Name:** end_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of precooling for the third season (optional)
In HH:MM:SS format
**Name:** start_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of precooling for the third season (optional)
In HH:MM:SS format
**Name:** end_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of precooling for the fourth season (optional)
In HH:MM:SS format
**Name:** start_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of precooling for the fourth season (optional)
In HH:MM:SS format
**Name:** end_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of precooling for the fifth season (optional)
In HH:MM:SS format
**Name:** start_time5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of precooling for the fifth season (optional)
In HH:MM:SS format
**Name:** end_time5,
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




