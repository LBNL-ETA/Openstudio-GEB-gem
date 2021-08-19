

###### (Automatically generated documentation)

# Reduce LPD by Percentage for Peak Hours

## Description
This measure reduces lighting loads by a user-specified percentage for a user-specified time period (usually the peak hours). The reduction can be applied to at most three periods throughout out the year specified by the user. This is applied throughout the entire building.

## Modeler Description
The original schedules for lights in the building will be found and copied. The copies will be modified to have the percentage reduction during the specified hours, and be applied to the specified date periods through out the year. The rest of the year will keep using the original schedules. 

## Measure Type
ModelMeasure

## Taxonomy
Electric Lighting

## Arguments


### New space name
This name will be used as the name of the new space.
**Name:** space_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




