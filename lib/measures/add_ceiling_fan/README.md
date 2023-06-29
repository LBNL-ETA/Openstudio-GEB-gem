

###### (Automatically generated documentation)

# Add Ceiling Fan

## Description
Install ceiling fans in buildings to increase air circulation. Ceiling fans effectively cool by introducing slow movement to induce evaporative cooling, rather than directly conditioning the air. A diversity factor is added to consider the simultaneous usage among the household.

## Modeler Description
Ceiling fan is modeled by increasing air velocity in the People objects and adding electric equipment to consider extra fan energy use. Cooling setpoint is increased by certain degrees in the presence of ceiling fans. A schedule is also introduced to simulate ceiling fan operation. A diversity factor (different in commercial and residential buildings) is added to consider the simultaneous usage among the building/household.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Select building type:
Building type (residential or commercial)
**Name:** bldg_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["residential", "commercial"]


### Cooling setpoint increase - C
Cooling setpoint increase in degree C
**Name:** cool_stp_increase_C,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Select ceiling fan motor type:
Ceiling fan motor type
**Name:** motor_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["DC", "AC"]


### Ceiling fan EUI in watts per floor area
Ceiling fan watts per m2
**Name:** watts_per_m2,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### First start date for the Reduction
In MM-DD format
**Name:** start_date,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### First end date for the Reduction
In MM-DD format
**Name:** end_date,
**Type:** String,
**Units:** ,
**Required:** false,
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


### Diversity factor
Diversity factor
**Name:** diversity_factor,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### People air velocity
Air velocity surrounding people (m/s)
**Name:** people_air_velocity,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false






