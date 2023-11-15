# Openstudio Geb Gem

The OpenStudio GEB measure gem is an open source OpenStudio library that can be plug-and-play into existing 
OpenStudio-based platforms. It now has 22 GEB measures implemented, spanning various building systems like 
lighting, plug load, envelope, hvac, domestic hot water, electric vehicle, and PV. 

Three of the GEB measures in this gem were integrated into NREL's [URBANopt](https://docs.urbanopt.net/) platform to support load 
flexibility analysis. They are "Reduce EPD by Percentage for Peak Hours", "Adjust thermostat setpoint 
by degrees for peak hours", and "Add Chilled Water Storage Tank".

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openstudio-geb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install 'openstudio-geb'

## Available GEB measures list
* Reduce EPD by percentage for peak hours
* Reduce LPD by percentage for peak hours
* Adjust thermostat setpoint by degrees for peak hours
* Reduce domestic hot water use for peak hours
* Average ventilation for peak hours
* Add chilled water storage tank
* Add electrochromic windows
* add_exterior_blinds_and_control
* add_interior_blinds_and_control
* Add fan assist night ventilation with hybrid control
* Add natural ventilation with hybrid control
* Add heat pump water heater
* Adjust domestic hot water setpoint
* Add rooftop PV
* Add electric vehicle charging load
* Add ceiling fan
* Apply dynamic coating to roof wall
* Enable demand controlled ventilation
* Enable occupancy-driven lighting
* Precooling
* Preheating
* Reduce exterior lighting loads
