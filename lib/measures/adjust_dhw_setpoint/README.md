

###### (Automatically generated documentation)

# Adjust DHW setpoint

## Description
This measure adjusts the water heating setpoint for the domestic hot water system during up to four periods. For heat pump water heater, this measure will also monitor and adjust the water tank setpoint as needed to make sure the tank setpoint is no higher than the HPWH cut-in temperature .

## Modeler Description
This measure adds flexibility to the DHW system by allowing users to input up to four flexible control periods. The setpoint can be input by setback degrees or absolute temperature values. For all types of water heaters, the water heating setpoint can be adjusted. For heat pump water heater, the water tank setpoint will also be monitored and adjusted to make sure the tank setpoint is no higher than the HPWH cut-in temperature.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Select Setpoint Adjust Input Method

**Name:** stp_adj_method,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daily Flex Period 1:
Use 24-Hour Format
**Name:** flex_hrs_1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily Flex Period 1 setpoint (or setback degree) in Degrees Fahrenheit:
Applies every day in the full run period.
**Name:** flex_stp_1,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daily Flex Period 2:
Use 24-Hour Format
**Name:** flex_hrs_2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily Flex Period 2 setpoint (or setback degree) in Degrees Fahrenheit:
Applies every day in the full run period.
**Name:** flex_stp_2,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daily Flex Period 3:
Use 24-Hour Format
**Name:** flex_hrs_3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily Flex Period 3 setpoint (or setback degree) in Degrees Fahrenheit:
Applies every day in the full run period.
**Name:** flex_stp_3,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daily Flex Period 4:
Use 24-Hour Format
**Name:** flex_hrs_4,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily Flex Period 4 setpoint (or setback degree) in Degrees Fahrenheit:
Applies every day in the full run period.
**Name:** flex_stp_4,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




