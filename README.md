## osxsleep

osxsleep allows to monitor macOS device's sleep state from Node.

Example usage:

```sh

  const osxsleep = require('osxsleep');
   
  ...

  var source = osxsleep.OSXSleep.getCurrentPowerSource();

  switch(source) {
	case osxsleep.POWER_SOURCE_AC:
		break;
	case osxsleep.POWER_SOURCE_BATTERY:
		break;
	case osxsleep.POWER_SOURCE_UPS:
		break;
  }

  ...
 
  osxsleep.OSXSleep.start(function(sleepstate){

	switch(sleepstate) {
		case osxsleep.CAN_SLEEP:
			if (/* can sleep*/) {
			    return true;
			} else {
			    return false;
			}
			break;
		case osxsleep.WILL_SLEEP:
			break;
		case osxsleep.WILL_POWER_ON:
			break;
		case osxsleep.HAS_POWERED_ON:
			break;
	}
  });

  ...
  
  osxsleep.OSXSleep.stop();
 
```

It is *important* to call stop() in order to unregister the native IOKit sleep state monitor & resources!
