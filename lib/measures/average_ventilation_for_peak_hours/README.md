

###### (Automatically generated documentation)

# Average Ventilation for Peak Hours

## Description
This measure implement average ventialtion for the use-specified time period to reduce the peak load.

## Modeler Description
The outdoor air flow rate will be reduced by the percentage specified by the user during the peak hours specified by the user. Then the decreased air flow rate will be added to the hours before the peak time.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Percentage Reduction of Lighting Power (%)
Enter a value between 0 and 100
**Name:** lpd_reduce_percent,
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

### Second end date for the Reduction
Specify a date in MM-DD format if you want a second period of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second start date for the Reduction (optional)
Specify a date in MM-DD format if you want a third period of reduction; leave blank if not needed.
**Name:** start_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Second end date for the Reduction
Specify a date in MM-DD format if you want a third period of reduction; leave blank if not needed. If either the start or end date is blank, the period is considered not used.
**Name:** end_date3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false




