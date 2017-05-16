## osxsleep

osxsleep allows to monitor macOS device's sleep state from Node.

Example usage:

```sh

  const osxsleep = require('osxsleep');
   
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
