

###### (Automatically generated documentation)

# Apply dynamic coating to roof wall

## Description
This measure applies dynamic coating on the outside of opaque exterior walls and/or roofs. The thermal and/or solar absorptance of the outer layer material will vary with the selected control signal. This measure is meant to reduce the radiative and solar heat gain via roofs and/or walls.

## Modeler Description
This measure modifies the thermal and/or solar absorptance of the outer surface of an existing material so that they can vary with the selected control signal. The related object is available in EnergyPlus version 23.1, but not yet implemented in OpenStudio, so this measure is implemented as an EnergyPlus measure.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Select where to apply the dynamic coating:

**Name:** apply_where,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Roof Only", "Wall Only", "Both"]


### Select the type of properties that the dynamic coating modifies:

**Name:** apply_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Thermal Only", "Solar Only", "Both"]


### We use two specific points to describe the linear relationship between surface temperature and absorptance, this is the surface temperature of the left point in Degree Celcius.

**Name:** temp_lo,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### We use two specific points to describe the linear relationship between surface temperature and absorptance, this is the surface temperature of the right point in Degree Celcius.

**Name:** temp_hi,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal absorptance at low temperature point.

**Name:** therm_abs_at_temp_lo,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Thermal absorptance at high temperature point.

**Name:** therm_abs_at_temp_hi,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Solar absorptance at low temperature point.

**Name:** solar_abs_at_temp_lo,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Solar absorptance at high temperature point.

**Name:** solar_abs_at_temp_hi,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false






