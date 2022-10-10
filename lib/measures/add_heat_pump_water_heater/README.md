

###### (Automatically generated documentation)

# Add HPWH for Domestic Hot Water

## Description
This measure adds or replaces existing domestic hot water heater with air source heat pump system and allows for the addition of multiple daily flexible control time windows. The heater/tank system may charge at maximum capacity up to an elevated temperature, or float without any heat addition for a specified timeframe down to a minimum tank temperature.

## Modeler Description
This measure allows selection between three heat pump water heater modeling approaches in EnergyPlus.The user may select between the pumped-condenser or wrapped-condenser objects. They may also elect to use a simplified calculation which does not use the heat pump objects, but instead used an electric resistance heater and approximates the equivalent electrical input that would be required from a heat pump. This expedites simulation at the expense of accuracy. 
The flexibility of the system is based on user-defined temperatures and times, which are converted into schedule objects. There are four flexibility options. (1) None: normal operation of the DHW system at a fixed tank temperature setpoint. (2) Charge - Heat Pump: the tank is charged to a maximum temperature using only the heat pump. (3) Charge - Electric: the tank is charged using internal electric resistance heaters to a maximum temperature. (4) Float: all heating elements are turned-off for a user-defined time period unless the tank temperature falls below a minimum value. The heat pump will be prioritized in a low tank temperature event, with the electric resistance heaters serving as back-up. 
Due to the heat pump interaction with zone conditioning as well as tank heating, users may experience simulation errors if the heat pump is too large and placed in an already conditioned zoned. Try using multiple smaller units, modifying the heat pump location within the model, or adjusting the zone thermostat constraints. Use mulitiple instances of the measure to add multiple heat pump water heaters. 

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Remove existing water heater?

**Name:** remove_wh,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select 40+ gallon water heater to replace or augment
All can only be used with the 'Simplified' model
**Name:** wh,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set hot water tank volume [gal]
Enter 0 to use existing tank volume(s). Values less than 5 are treated as sizing multipliers.
**Name:** vol,
**Type:** Double,
**Units:** gal,
**Required:** false,
**Model Dependent:** false

### Select heat pump water heater type

**Name:** type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select thermal zone for HP evaporator
Does not apply to 'Simplified' cases
**Name:** zone_name,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set heat pump heating capacity
[kW]
**Name:** cap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set heat pump rated COP (heating)

**Name:** cop,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set electric backup heating capacity
[kW]
**Name:** bu_cap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set maximum tank temperature
[F]
**Name:** max_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set minimum tank temperature during float
[F]
**Name:** min_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set deadband temperature difference between heat pump and electric backup
[F]
**Name:** db_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select reference tank setpoint temperature schedule

**Name:** sched,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Daily Flex Period 1:
Applies every day in the full run period.
**Name:** flex0,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use 24-Hour Format

**Name:** flex_hrs0,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily Flex Period 2:
Applies every day in the full run period.
**Name:** flex1,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use 24-Hour Format

**Name:** flex_hrs1,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily Flex Period 3:
Applies every day in the full run period.
**Name:** flex2,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use 24-Hour Format

**Name:** flex_hrs2,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Daily Flex Period 4:
Applies every day in the full run period.
**Name:** flex3,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use 24-Hour Format

**Name:** flex_hrs3,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false




