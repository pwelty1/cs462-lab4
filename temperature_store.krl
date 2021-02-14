ruleset store.temperature {
    meta {
      name "temperature"
      provides temperatures, threshold_violations, inrange_temperatures
      shares temperatures, threshold_violations, inrange_temperatures
    }
    global {
        temperatures = function() {
            {}.put(ent:temperatures)
        }
        threshold_violations  = function() {
            {}.put(ent:violations)
        }
        inrange_temperatures = function() {
            {}.put(ent:normal_temps)
        }
        threshold = 72
    }

    rule collect_temperatures {
        select when wovyn new_temperature_reading
        pre {
            temp = event:attrs{"temperature"}.defaultsTo("temperature")
            time = event:attrs{"Timestamp"}.defaultsTo("timestamp")
            entry = {"temperature": temp, "timestamp": time}
        }
        send_directive(event:attrs.klog("attrs"))
        fired{
            ent:temperatures := ent:temperatures.defaultsTo([]).append(entry)
            ent:normal_temps := ent:normal_temps.defaultsTo([]).append(entry) if event:attrs{"temperature"}{"temperatureF"} <= threshold
        }
    }

    rule collect_threshold_violations {
        select when wovyn threshold_violation 
        pre {
            temp = event:attrs{"temperature"}.defaultsTo("temperature")
            time = event:attrs{"Timestamp"}.defaultsTo("timestamp")
            entry = {"temperature": temp, "timestamp": time}
        }
        send_directive(event:attrs.klog("attrs"))
        always{
            ent:violations := ent:violations.defaultsTo([]).append(entry)
        }
    }

    rule clear_temerature {
        select when sensor reading_reset
        send_directive("cleared!")
        always{
            clear ent:temperatures
            clear ent:violations
            clear ent:normal_temps
        }
    }
  }