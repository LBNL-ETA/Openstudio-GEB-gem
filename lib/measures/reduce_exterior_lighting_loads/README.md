

###### (Automatically generated documentation)

# Reduce Exterior Lighting Loads

## Description
This measure reduces exterior lighting loads by two ways: (1) upgrading the lighting fixtures to be more efficient, which reduces the design level value, (2) reducing operational durationand/or strength by adjusting control option and schedule based on daylight, occupancy, and/or user designated period.

## Modeler Description
This measure can (1) reduce design level by percentage if given by the user, (2) update the control option to AstronomicalClock, (3) adjust the schedule by replacing with occupancy schedule of the majority space/spacetype, and/or turn off or dim during user designated period.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Percentage Reduction of Exterior Lighting Design Power (%)
Enter a value between 0 and 100
**Name:** design_val_reduce_percent,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Use daylight control
If exterior lights will be turned off during the day
**Name:** use_daylight_control,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Use occupancy sensing
If enabled, this will turn off exterior lights when unoccupied, and dim with partial occupancy
**Name:** use_occupancy_sensing,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Schedule value representing light on fraction to turn off (0) or dim (<1) during user designated event period
Enter a value >=0 and <1
**Name:** on_frac_in_defined_period,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### User Designated Event Start Time for the off/dimming
In HH:MM:SS format
**Name:** user_defined_start_time,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### User Designated Event End Time for the off/dimming
In HH:MM:SS format
**Name:** user_defined_end_time,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false






