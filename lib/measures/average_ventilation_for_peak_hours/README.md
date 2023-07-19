

###### (Automatically generated documentation)

# Average Ventilation for Peak Hours

## Description
This measure implement average ventialtion for the use-specified time period to reduce the peak load.

## Modeler Description
The outdoor air flow rate will be reduced by the percentage specified by the user during the peak hours specified by the user. Then the decreased air flow rate will be added to the same number of hours before the peak time.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Percentage Reduction of Ventilation Rate (%)
Enter a value between 0 and 100
**Name:** vent_reduce_percent,
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

### Start Date for Average Ventilation
In MM-DD format
**Name:** start_date1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Date for Average Ventilation
In MM-DD format
**Name:** end_date1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false




