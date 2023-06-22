# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

    # for workplace
    # waitlist is only applicable to workplace. For homes, charging is scheduled with start_charge_time
    # create all EV chargers
    def create_ev_sch_for_workplace(model, ev_chargers, max_charging_power, num_evs, avg_arrival_time, avg_leave_time, avg_charge_hours, charge_on_sat, charge_on_sun)
      ev_list = []
      for j in 1..num_evs
        ev = ElectricVehicle.new("ev_#{j.to_s}")
        ev.arrival_time = avg_arrival_time + rand(-30...30) * 60  # TODO make sure time format is working correctly, Ruby Times "+" adopts seconds
        ev.leave_time = avg_leave_time + rand(-30...30) * 60  # TODO make sure time format is working correctly, Ruby Times "+" adopts seconds
        ev.leave_time = Time.strptime("23:00", '%H:%M') + 3600 if ev.leave_time > Time.strptime("23:00", '%H:%M') + 3600  # fix leave time at 24:00 if later than 24:00
        ev.needed_charge_hours = avg_charge_hours + rand(-60...60) / 60.0   # +- 1 hour
        ev_list << ev
      end

      # find the earliest arrival time
      arrival_time_earliest = Time.strptime("23:00", '%H:%M') + 3600  # initial: 24:00
      ev_list.each do |this_ev|
        if this_ev.arrival_time < arrival_time_earliest
          arrival_time_earliest = this_ev.arrival_time
        end
      end

      # For workplace: iterate through time, check status of each charger, if vacant, find the EV that has the earliest arrival time within uncharged EVs.
      # if this EV's leaving time is later than the current time, start charging until fully charged or leaving time, whichever comes first
      # when no EV is found any more, charging on this day ends, conclude the charging profile
      # 23 represent 23:00-24:00, corresponding to E+ schedule Until: 24:00
      for hour in 0..23
        current_time = Time.strptime("#{hour}:00", '%H:%M') + 3600   # %H: 00..23, 23 should represent the period 23:00-24:00, so add 1 hour to be the check point
        next if arrival_time_earliest > current_time
        ev_chargers.each do |ev_charger|
          if ev_charger.occupied
            if ev_charger.connected_ev.class.to_s != 'AddElectricVehicleChargingLoad::ElectricVehicle'
              runner.registerError("EV charger #{ev_charger.name.to_s} shows occupied, but no EV is connected.")
              return false
            end
            # disconnect EV if charged to full or till leave time. Only check if expected end time or leave is earlier than current time, otherwise check in next iteration.
            # Time addition uses seconds, so needs to multiple 3600
            if ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600 <= current_time || ev_charger.connected_ev.leave_time <= current_time
              if ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600 > ev_charger.connected_ev.leave_time
                ev_charger.occupied_until_time = ev_charger.connected_ev.leave_time
                ev_charger.connected_ev.end_charge_time = ev_charger.connected_ev.leave_time
              else
                ev_charger.occupied_until_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
                ev_charger.connected_ev.end_charge_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              end
              ev_charger.occupied = false
              ev_charger.connected_ev.has_been_charged = true
              ev_charger.connected_ev.connected_to_charger = false
              ev_charger.connected_ev = nil
            end
          end
          # continue to check if charger not occupied, then connect to an EV
          unless ev_charger.occupied
            next_ev_to_charge = nil
            wait_list_time_earliest = Time.strptime("23:00", '%H:%M') + 3600  # initial: 24:00
            ev_list.each do |this_ev|
              # skip this EV if it is being charged or is being charged or already left
              next if this_ev.has_been_charged
              next if this_ev.connected_to_charger
              next if this_ev.leave_time <= current_time
              # get the uncharged, earliest arrival EV (so front in wait list)
              if this_ev.arrival_time < wait_list_time_earliest
                wait_list_time_earliest = this_ev.arrival_time
                next_ev_to_charge = this_ev
              end
            end
            # skip if no EV is on the wait list
            next if next_ev_to_charge.nil?
            if ev_charger.charged_ev_list.empty?
              ev_charger.occupied_start_time = wait_list_time_earliest
              next_ev_to_charge.start_charge_time = wait_list_time_earliest
            else
              next_ev_to_charge.start_charge_time = ev_charger.occupied_until_time
            end
            ev_charger.occupied = true
            next_ev_to_charge.connected_to_charger = true
            ev_charger.connected_ev = next_ev_to_charge
            ev_charger.charged_ev_list << next_ev_to_charge
          end
        end
      end

      ev_sch = create_ev_sch(model, ev_chargers, max_charging_power, charge_on_sat, charge_on_sun)
      return ev_sch
    end

    def create_ev_sch_for_home(model, ev_chargers, max_charging_power, num_evs, start_charge_time, avg_charge_hours, charge_on_sat, charge_on_sun)
      ev_list = []
      for j in 1..num_evs
        ev = ElectricVehicle.new("ev_#{j.to_s}")
        ev.needed_charge_hours = avg_charge_hours + rand(-60...60) / 60.0   # +- 1 hour
        ev_list << ev
      end

      # for homes, EV charging could go overnight, so iterate 48 hours
      for hour in 0..47
        if hour <= 23
          current_time = Time.strptime("#{hour}:00", '%H:%M') + 3600   # %H: 00..23, 23 should represent the period 23:00-24:00, so add 1 hour to be the check point
        else
          current_time = Time.strptime("#{hour-24}:00", '%H:%M') + 24*60*60 + 3600   # %H: the second day (for overnight). still 00..23, 23 should represent the period 23:00-24:00, so add 1 hour to be the check point
        end
        next if start_charge_time > current_time
        ev_chargers.each do |ev_charger|
          if ev_charger.occupied
            if ev_charger.connected_ev.class.to_s != 'AddElectricVehicleChargingLoad::ElectricVehicle'
              runner.registerError("EV charger #{ev_charger.name.to_s} shows occupied, but no EV is connected.")
              return false
            end
            # Time addition uses seconds, so needs to multiple 3600
            if ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600 <= current_time
              ev_charger.connected_ev.end_charge_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              ev_charger.occupied_until_time = ev_charger.connected_ev.start_charge_time + ev_charger.connected_ev.needed_charge_hours * 3600
              ev_charger.occupied = false
              ev_charger.connected_ev.has_been_charged = true
              ev_charger.connected_ev.connected_to_charger = false
              ev_charger.connected_ev = nil
            end
          end
          # continue to check if charger not occupied, then connect to an EV
          unless ev_charger.occupied
            # no need of waitlist, just connect to whichever EV that hasn't been charged
            next_ev_to_charge = nil
            ev_list.each do |this_ev|
              # skip this EV if it is being charged or is being charged
              next if this_ev.has_been_charged
              next if this_ev.connected_to_charger
              next_ev_to_charge = this_ev
              break
            end
            # skip if no EV is on the wait list
            next if next_ev_to_charge.nil?
            if ev_charger.charged_ev_list.empty?
              ev_charger.occupied_start_time = start_charge_time
              next_ev_to_charge.start_charge_time = start_charge_time
            else
              next_ev_to_charge.start_charge_time = ev_charger.occupied_until_time
            end
            ev_charger.occupied = true
            next_ev_to_charge.connected_to_charger = true
            ev_charger.connected_ev = next_ev_to_charge
            ev_charger.charged_ev_list << next_ev_to_charge
          end
        end
      end

      ev_sch = create_ev_sch(model, ev_chargers, max_charging_power, charge_on_sat, charge_on_sun)
      return ev_sch
    end

    # create EV load schedule (normalized)
    case bldg_use_type
    when 'workplace'
      ev_sch = create_ev_sch_for_workplace(model, ev_chargers, max_charging_power, num_evs, avg_arrival_time, avg_leave_time, avg_charge_hours, charge_on_sat, charge_on_sun)
    when 'home'
      ev_sch = create_ev_sch_for_home(model, ev_chargers, max_charging_power, num_evs, start_charge_time, avg_charge_hours, charge_on_sat, charge_on_sun)
    end

    # Adding an EV charger definition and instance for the regular EV charging.
    ev_charger_def = OpenStudio::Model::ExteriorFuelEquipmentDefinition.new(model)
    ev_charger_level = max_charging_power * 1000 # Converting from kW to watts
    ev_charger_def.setName("#{ev_charger_level} w EV Charging Definition")
    ev_charger_def.setDesignLevel(ev_charger_level)

    # creating EV charger object for the regular EV charging.
    ev_charger = OpenStudio::Model::ExteriorFuelEquipment.new(ev_charger_def, ev_sch)
    ev_charger.setName("#{ev_charger_level} w EV Charger")
    ev_charger.setFuelType('Electricity')
    ev_charger.setEndUseSubcategory('Electric Vehicles')

    runner.registerInfo("multiplier (kW) = #{max_charging_power}}")

    # echo the new space's name back to the user
    runner.registerInfo("EV load with #{num_ev_chargers} EV chargers and #{num_evs} EVs was added.")

    # report final condition of model
    runner.registerFinalCondition("The building completed adding EV load.")

    return true
  end
end

# register the measure to be used by the application
AddElectricVehicleChargingLoad.new.registerWithApplication
