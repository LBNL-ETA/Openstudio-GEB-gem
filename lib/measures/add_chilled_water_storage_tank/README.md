

###### (Automatically generated documentation)

# Add Chilled Water Storage Tank

## Description
This measure adds a chilled water storage tank to a chilled water loop for the purpose of thermal energy storage.

## Modeler Description
This measure adds a chilled water storage tank and links it to an existing chilled water loop. User can specify the operating season, charge period, discharge period, setpoint temperature and volume of the chilled water tank. If the volume is not provided, a sizing simulation will be run to autosize the tank.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments

### Tank volume
Thermal storage chilled water tank volume in m3
**Name:** tank_vol,
**Type:** Double,
**Units:** m3,
**Required:** false,
**Model Dependent:** false

### Energy storage objective
Select from 'Full Storage' and 'Partial Storage'
**Name:** objective,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Chilled water loop
Select a chilled water loop in the model to connect the tank
**Name:** selected_primary_loop_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** true

### Setpoint temperature
Chilled water tank setpoint temperature in degree C
**Name:** tank_charge_sp,
**Type:** Double,
**Units:** degree C,
**Required:** true,
**Model Dependent:** false

### Loop design delta T
Loop design temperature difference in degree C; Use 'Use Existing Loop Value' to use the current loop setting
**Name:** primary_delta_t,
**Type:** String,
**Units:** degree C,
**Required:** true,
**Model Dependent:** false

### Secondary loop design delta T
Secondary loop design temperature difference in degree C
**Name:** secondary_delta_t,
**Type:** Double,
**Units:** degree C,
**Required:** true,
**Model Dependent:** false

### Available season
Seasonal Availability of Chilled Water Storage in MM/DD-MM/DD format
**Name:** thermal_storage_season,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Discharge start time
Starting Time for Chilled Water Tank Discharge in HR:mm (24 hour format)
**Name:** discharge_start,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Discharge end time
Ending Time for Chilled Water Tank Discharge in HR:mm (24 hour format)
**Name:** discharge_end,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Charge start time
Starting Time for Chilled Water Tank Charge in HR:mm (24 hour format)
**Name:** charge_start,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Charge end time
Ending Time for Chilled Water Tank Charge in HR:mm (24 hour format)
**Name:** charge_end,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Work on weekends?
Allow Chilled Water Tank Work on Weekends?
**Name:** wknds,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




