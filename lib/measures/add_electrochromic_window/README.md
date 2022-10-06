

###### (Automatically generated documentation)

# Add Electrochromic Window

## Description
This measure replaces existing window construction to electrochromic window, and allows a few control strategies such as by glare, solar radiation, schedule, and illuminance. This measure models two states of the electrochromic window, the light and dark states.

## Modeler Description
This measure implements the electrochromic window as a three-layer construction, which includes a typical 3mm glass layer, an air gap, and an electrochromic layer. The control strategies are implemented via WindowShadingControl object. For the electrochromic window layer performance, the user could either use default values,  which we got from View manufacturer data, or enter their own product performance.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Thickness of the electrochromic glass layer in mm

**Name:** thickness_electro_glass,
**Type:** Double,
**Units:** m,
**Required:** true,
**Model Dependent:** false

### Thickness of the air gap between electrochromic glass layer and inside clear glass layer in meter

**Name:** thickness_air_gap,
**Type:** Double,
**Units:** m,
**Required:** true,
**Model Dependent:** false

### Thickness of the inside clear glass layer in meter

**Name:** thickness_clear_glass,
**Type:** Double,
**Units:** m,
**Required:** true,
**Model Dependent:** false

### Thermal conductivity of the electrochromic glass layer in W/m.K

**Name:** tc_electro_glass,
**Type:** Double,
**Units:** W/m.K,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass solar transmittance - light state

**Name:** solar_trans_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass solar reflectance - front side - light state

**Name:** solar_ref_f_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass solar reflectance - back side - light state

**Name:** solar_ref_b_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass visible transmittance - light state

**Name:** vis_trans_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass visible reflectance - front side - light state

**Name:** vis_ref_f_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass visible reflectance - back side - light state

**Name:** vis_ref_b_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass infrared transmittance - light state

**Name:** ir_trans_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass infrared emissivity - front side - light state

**Name:** ir_emis_f_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass infrared emissivity - back side - light state

**Name:** ir_emis_b_light,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass solar transmittance - dark state

**Name:** solar_trans_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass solar reflectance - front side - dark state

**Name:** solar_ref_f_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass solar reflectance - back side - dark state

**Name:** solar_ref_b_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass visible transmittance - dark state

**Name:** vis_trans_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass visible reflectance - front side - dark state

**Name:** vis_ref_f_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass visible reflectance - back side - dark state

**Name:** vis_ref_b_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass infrared transmittance - dark state

**Name:** ir_trans_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass infrared emissivity - front side - dark state

**Name:** ir_emis_f_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electrochromic glass infrared emissivity - back side - dark state

**Name:** ir_emis_b_dark,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select the type of air gap for the electrochromic window

**Name:** gas_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Select control strategy for electrochromic window
Setpoint of glare, radiation, or illuminance should also be set based on selected control strategy
**Name:** ctrl_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Maximum allowable discomfort glare index
Electrochromic window will turn to dark state when glare index is above this value.
**Name:** glare_stp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Total (beam plus diffuse) solar radiation setpoint
Electrochromic window will turn to dark state when total solar radiation is above this value.
**Name:** solar_rad_stp,
**Type:** Double,
**Units:** W/m2,
**Required:** false,
**Model Dependent:** false

### Illuminance setpoint
The transmittance of the electrochromic window will be adjusted to just meet the daylight illuminance setpoint.
**Name:** illum_stp,
**Type:** Double,
**Units:** lux,
**Required:** false,
**Model Dependent:** false




