

###### (Automatically generated documentation)

# GEB Metrics Report

## Description
This measure calculates GEB-related (mainly DF) metrics and reports them.

## Modeler Description
GEB metrics compare between baseline and GEB measures. To enable the GEB metrics calculation, please make sure the output variable -Facility Net Purchased Electricity Rate- is added to both baseline and retrofit models.

## Measure Type
ReportingMeasure

## Taxonomy


## Arguments


### GEB metrics
Choose whether or not to report geb_metrics_section
**Name:** geb_metrics_section,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### The event date for GEB metrics reporting purpose
In MM-DD format
**Name:** event_date,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enter Starting Time for Shed Period:
Use 24 hour format HH:MM:SS
**Name:** shed_start,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Enter End Time for Shed Period:
Use 24 hour format HH:MM:SS
**Name:** shed_end,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Enter Starting Time for Take Period:
Use 24 hour format HH:MM:SS
**Name:** take_start,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Enter End Time for Take Period:
Use 24 hour format HH:MM:SS
**Name:** take_end,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Output path

**Name:** baseline_run_output_path,
**Type:** Path,
**Units:** ,
**Required:** true,
**Model Dependent:** false




