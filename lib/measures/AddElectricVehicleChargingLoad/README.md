

###### (Automatically generated documentation)

# AddElectricVehicleChargingLoad

## Description
This measure adds electric vehicle charging load to the building. The user can specify the level of charger, number of chargers, number of EVs charging daily, start time, average number of hours to fully charge. 

## Modeler Description
This measure will add electric vehicle charging load as exterior electric equipment. The user inputs of level of chargers, number of chargers, and number of EVs charging daily will be used to determine the load level, and the inputs of start time and average number of hours to fully charge will be used to determine load schedule.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Building Use Type

**Name:** bldg_use_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Number of EV Chargers

**Name:** num_ev_chargers,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Number of Electric Vehicles

**Name:** num_evs,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### EV Charger Level

**Name:** charger_level,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Average arrival time, applicable for workplace only

**Name:** avg_arrival_time,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Average leave time, applicable for workplace only

**Name:** avg_leave_time,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Start charging time, required for home only

**Name:** start_charge_time,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Average needed hours to charge to full (should vary with charger level)

**Name:** avg_charge_hours,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Variation of arrival time in minutes
Actual arrival time can vary a certain period before and after the average arrival time. This parameter describes this absolute time delta. In other words, average arrival time plus/minus this parameter constitutes the arrival time range. 
**Name:** arrival_time_variation_in_mins,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Variation of charge time in minutes
Actual charge time can vary a certain period around the average charge hours. This parameter describes this absolute time delta. In other words, average charge hours plus/minus this parameter constitutes the charge time range. 
**Name:** charge_time_variation_in_mins,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### EVs are charged on Saturday

**Name:** charge_on_sat,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### EVs are charged on Sunday

**Name:** charge_on_sun,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false




