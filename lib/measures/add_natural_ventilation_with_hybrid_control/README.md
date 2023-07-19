

###### (Automatically generated documentation)

# Add natural ventilation with hybrid control

## Description
This measure adds natural ventilation to all the zones with operable windows, and controls natural  ventilation together with HVAC in a hybrid manner. More specifically, HVAC will be disabled  when windows are open,  and HVAC will be available when windows are closed.

## Modeler Description
This measures adds ZoneVentilation:WindandStackOpenArea objects to zones with operable windwos to model natural ventilation, then adds AvailabilityManager:HybridVentilation to each zone with natural ventilation and control HVAC and natural ventilation in a hybrid manner. When windows are open, HVAC will be disabled; when windows are closed, HVAC will be available. HVAC can be an airloop system or a zonal system. 

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Window Open Area Fraction (0-1)
A typical operable window does not open fully. The actual opening area in a zone is the product of the area of operable windows and the open area fraction schedule. Default 50% open.
**Name:** open_area_fraction,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Minimum Indoor Temperature (degC)
The indoor temperature below which ventilation is shutoff.
**Name:** min_indoor_temp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Maximum Indoor Temperature (degC)
The indoor temperature above which ventilation is shutoff.
**Name:** max_indoor_temp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Minimum Indoor-Outdoor Temperature Difference (degC)
This is the temperature difference between the indoor and outdoor air dry-bulb temperatures below which ventilation is shutoff.  For example, a delta temperature of 2 degC means ventilation is available if the outside air temperature is at least 2 degC cooler than the zone air temperature. Values can be negative.
**Name:** delta_temp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Minimum Outdoor Temperature (degC)
The outdoor temperature below which ventilation is shut off.
**Name:** min_outdoor_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Maximum Outdoor Temperature (degC)
The outdoor temperature above which ventilation is shut off.
**Name:** max_outdoor_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Maximum Wind Speed (m/s)
This is the wind speed above which ventilation is shut off.  The default values assume windows are closed when wind is above a gentle breeze to avoid blowing around papers in the space.
**Name:** max_wind_speed,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Daily Start Time for natural ventilation
Use 24 hour format (HR:MM)
**Name:** nv_starttime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Daily End Time for natural ventilation
Use 24 hour format (HR:MM)
**Name:** nv_endtime,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Start Date for natural ventilation
In MM-DD format
**Name:** nv_startdate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### End Date for natural ventilation
In MM-DD format
**Name:** nv_enddate,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Allow Natural Ventilation on Weekends

**Name:** wknds,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false






