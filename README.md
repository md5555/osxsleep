## osxsleep

osxsleep allows to monitor macOS device's sleep state from Node.

Example usage:

```sh

  const osxsleep = require('osxsleep');
   
  ...

  osxsleep.OSXSleep.start(function(sleepstate){

	switch(sleepstate) {
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
