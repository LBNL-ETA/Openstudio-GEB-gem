

###### (Automatically generated documentation)

# Add Chilled Water Storage Tank

## Description
This measure adds a chilled water storage tank to a chilled water loop for the purpose of thermal energy storage.

## Modeler Description
This measure adds a chilled water storage tank and links it to an existing chilled water loop.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Thermal storage chilled water tank volume in m3

**Name:** tank_vol,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Select Energy Storage Objective:

**Name:** objective,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select Primary Loop:
Error: No Cooling Loop Found
**Name:** selected_primary_loop_name,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Primary Loop (charging) Setpoint Temperature degree C:

**Name:** primary_loop_sp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Secondary Loop (discharging) Setpoint Temperature degree C:

**Name:** secondary_loop_sp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Chilled Water Tank Setpoint Temperature degree C:

**Name:** tank_charge_sp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Loop Design Temperature Difference degree C:
Enter numeric value to adjust selected loop settings.
**Name:** primary_delta_t,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Secondary Loop Design Temperature Difference degree C

**Name:** secondary_delta_t,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Start Date for thermal storage
In MM-DD format
**Name:** thermal_storage_startdate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### End Date for thermal storage
In MM-DD format
**Name:** thermal_storage_enddate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Enter Starting Time for Chilled Water Tank Discharge:
Use 24 hour format (HR:MM)
**Name:** discharge_start,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enter End Time for Chilled Water Tank Discharge:
Use 24 hour format (HR:MM)
**Name:** discharge_end,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enter Starting Time for Chilled Water Tank charge:
Use 24 hour format (HR:MM)
**Name:** charge_start,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enter End Time for Chilled Water Tank charge:
Use 24 hour format (HR:MM)
**Name:** charge_end,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Allow Chilled Water Tank Work on Weekends

**Name:** wknds,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Output path for tank sizing run (if tank volume is not provided)

**Name:** run_output_path,
**Type:** Path,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### epw file path for tank sizing run (if tank volume is not provided)

**Name:** epw_path,
**Type:** Path,
**Units:** ,
**Required:** false,
**Model Dependent:** false




