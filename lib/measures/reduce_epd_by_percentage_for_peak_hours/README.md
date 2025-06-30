

###### (Automatically generated documentation)

# Reduce EPD by Percentage for Peak Hours

## Description
This measure reduces electric equipment loads for office space types by a user-specified percentage for a user-specified time period (usually the peak hours). The reduction can be applied to at most five periods throughout out the year specified by the user.

## Modeler Description
The original schedules for equipment in the building will be found and copied. The copies will be modified to have the percentage reduction during the specified hours, and be applied to the specified date periods through out the year. The rest of the year will keep using the original schedules. Only schedules defined in scheduleRuleSet format and for office standardsSpaceType will be modified.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Percentage Reduction of Electric Equipment Power (%)
Enter a value between 0 and 100
**Name:** epd_reduce_percent,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First start date for the reduction
In MM-DD format
**Name:** start_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### First end date for the reduction
In MM-DD format
**Name:** end_date1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Second start date for the reduction (optional)
Specify a date in MM-DD format if you want a second season of reduction; leave blank if not needed.
**Name:** start_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second end date for the reduction
Specify a date in MM-DD format if you want a second season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third start date for the reduction (optional)
Specify a date in MM-DD format if you want a third season of reduction; leave blank if not needed.
**Name:** start_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third end date for the reduction
Specify a date in MM-DD format if you want a third season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth start date for the reduction (optional)
Specify a date in MM-DD format if you want a fourth season of reduction; leave blank if not needed.
**Name:** start_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fourth end date for the reduction
Specify a date in MM-DD format if you want a fourth season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth start date for the reduction (optional)
Specify a date in MM-DD format if you want a fifth season of reduction; leave blank if not needed.
**Name:** start_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Fifth end date for the reduction
Specify a date in MM-DD format if you want a fifth season of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of the reduction for the first season
In HH:MM:SS format
**Name:** start_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### End time of the reduction for the first season
In HH:MM:SS format
**Name:** end_time1,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start time of the reduction for the second season (optional)
In HH:MM:SS format
**Name:** start_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of the reduction for the second season (optional)
In HH:MM:SS format
**Name:** end_time2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of the reduction for the third season (optional)
In HH:MM:SS format
**Name:** start_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of the reduction for the third season (optional)
In HH:MM:SS format
**Name:** end_time3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of the reduction for the fourth season (optional)
In HH:MM:SS format
**Name:** start_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of the reduction for the fourth season (optional)
In HH:MM:SS format
**Name:** end_time4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start time of the reduction for the fifth season (optional)
In HH:MM:SS format
**Name:** start_time5,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End time of the reduction for the fifth season (optional)
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




