

###### (Automatically generated documentation)

# Reduce domestic hot water use for peak hours

## Description
This measure reduces the domestic hot water usage by a user-specified percentage for a user-specified time period (usually the peak hours). This is applied to the whole building.

## Modeler Description
This measure will clone the flow rate fraction schedules of all the WaterUseEquipment. Then the schedules are adjusted by the specified percentage during the specified time period. 

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Percentage Reduction of Domestic Hot Water Use (%)
Enter a value between 0 and 100
**Name:** water_use_reduce_percent,
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




