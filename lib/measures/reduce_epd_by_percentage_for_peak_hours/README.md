

###### (Automatically generated documentation)

# Reduce EPD by Percentage for Peak Hours

## Description
This measure reduces electric equipment loads by a user-specified percentage for a user-specified time period (usually the peak hours). The reduction can be applied to at most three periods throughout out the year specified by the user. This is applied throughout the entire building.

## Modeler Description
The original schedules for equipment in the building will be found and copied. The copies will be modified to have the percentage reduction during the specified hours, and be applied to the specified date periods through out the year. The rest of the year will keep using the original schedules.

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

### Start Time for the Reduction
In HH:MM:SS format
**Name:** start_time,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Time for the Reduction
In HH:MM:SS format
**Name:** end_time,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Use alternative default start and end time based on the climate zone of the model?
This will overwrite the star and end time you input
**Name:** alt_periods,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### First start date for the Reduction
In MM-DD format
**Name:** start_date1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### First end date for the Reduction
In MM-DD format
**Name:** end_date1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second start date for the Reduction (optional)
Specify a date in MM-DD format if you want a second period of reduction; leave blank if not needed.
**Name:** start_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second end date for the Reduction (optional)
Specify a date in MM-DD format if you want a second period of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third start date for the Reduction (optional)
Specify a date in MM-DD format if you want a third period of reduction; leave blank if not needed.
**Name:** start_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Third end date for the Reduction
Specify a date in MM-DD format if you want a third period of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false




