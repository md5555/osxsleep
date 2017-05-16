
exports.OSXSleep = require('./bindings')('osxsleep');

exports.WILL_SLEEP = 0;
exports.WILL_POWER_ON = 1;
exports.HAS_POWERED_ON = 2;
exports.CAN_SLEEP = 3;

exports.POWER_SOURCE_AC = 0;
exports.POWER_SOURCE_BATTERY = 1;
exports.POWER_SOURCE_UPS = 2;
