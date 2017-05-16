#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
 
#include <mach/mach_port.h>
#include <mach/mach_interface.h>
#include <mach/mach_init.h>
 
#include <IOKit/IOMessage.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/ps/IOPowerSources.h>

#include <queue>
 
// node headers
#include <v8.h>
#include <node.h>
#include <unistd.h>
#include <string.h>

using namespace node;
using namespace v8;

Persistent<Function> * callback = 0;
v8::Isolate* isolate;
 
io_connect_t root_port; // a reference to the Root Power Domain IOService
IONotificationPortRef  notifyPortRef;
io_object_t            notifierObject;
void*                  refCon = 0;
 
// callback that runs the javascript in main thread
static void Callback(int number)
{
    if (!callback) {
	return;
    }

    TryCatch try_catch(isolate);
 
    // prepare arguments for the callback
    Local<Value> argv[1];
    argv[0] = Integer::New(isolate, number);
 
    // call the callback and handle possible exception
    callback->Get(isolate)->Call(v8::Object::New(isolate), 1, argv);
 
    if (try_catch.HasCaught()) {
        FatalException(isolate, try_catch);
    }
}

// callback that runs the javascript in main thread
static bool CallbackRvBool(int number)
{
    if (!callback) {
	return true; // PERMIT power change
    }

    TryCatch try_catch(isolate);
 
    // prepare arguments for the callback
    Local<Value> argv[1];
    argv[0] = Integer::New(isolate, number);
 
    // call the callback and handle possible exception
    Handle<Value> rv = callback->Get(isolate)->Call(v8::Object::New(isolate), 1, argv);
 
    if (try_catch.HasCaught()) {
        FatalException(isolate, try_catch);
	return true;
    } else {
	return rv->BooleanValue();	
    }
}

void
GetPowerSource(const v8::FunctionCallbackInfo<v8::Value>& args) {

    const CFTypeRef ref = IOPSCopyPowerSourcesInfo();

    const CFStringRef source = IOPSGetProvidingPowerSourceType(ref);
    CFRelease(ref);

    int src = -1;

    if (source == CFSTR(kIOPMACPowerKey) == 0) {
	src = 0;
    }
    else
    if (source == CFSTR(kIOPMBatteryPowerKey) == 0) {
	src = 1;
    }
    else
    if (source == CFSTR(kIOPMUPSPowerKey) == 0) {
	src = 2;
    }

    CFRelease(source);	
    args.GetReturnValue().Set(Integer::New(isolate, src));
}

void
MySleepCallBack( void * refCon, io_service_t service, natural_t messageType, void * messageArgument )
{
    printf( "messageType %08lx, arg %08lx\n",
        (long unsigned int)messageType,
        (long unsigned int)messageArgument );
 
    switch ( messageType )
    {
 
        case kIOMessageCanSystemSleep:
            /* Idle sleep is about to kick in. This message will not be sent for forced sleep.
                Applications have a chance to prevent sleep by calling IOCancelPowerChange.
                Most applications should not prevent idle sleep.
 
                Power Management waits up to 30 seconds for you to either allow or deny idle
                sleep. If you don't acknowledge this power change by calling either
                IOAllowPowerChange or IOCancelPowerChange, the system will wait 30
                seconds then go to sleep.
            */

	    if (CallbackRvBool(3)) {
		IOAllowPowerChange( root_port, (long)messageArgument );
	    } else {
		IOCancelPowerChange( root_port, (long)messageArgument );
	    }
 
            break;
 
        case kIOMessageSystemWillSleep:
            /* The system WILL go to sleep. If you do not call IOAllowPowerChange or
                IOCancelPowerChange to acknowledge this message, sleep will be
                delayed by 30 seconds.
 
                NOTE: If you call IOCancelPowerChange to deny sleep it returns
                kIOReturnSuccess, however the system WILL still go to sleep.
            */

	    Callback(0);
 
            IOAllowPowerChange( root_port, (long)messageArgument );
            break;
 
        case kIOMessageSystemWillPowerOn:
            //System has started the wake up process...
	    Callback(1);
            break;
 
        case kIOMessageSystemHasPoweredOn:
            //System has finished waking up...
	    Callback(2);
        break;
 
        default:
            break;
 
    }
}

void Stop(const v8::FunctionCallbackInfo<v8::Value>& args) {

    if (!callback || !refCon) {
	return;
    } 

    // remove the sleep notification port from the application runloop
    CFRunLoopRemoveSource( CFRunLoopGetCurrent(),
                           IONotificationPortGetRunLoopSource(notifyPortRef),
                           kCFRunLoopCommonModes );
 
    // deregister for system sleep notifications
    IODeregisterForSystemPower( &notifierObject );
 
    // IORegisterForSystemPower implicitly opens the Root Power Domain IOService
    // so we close it here
    IOServiceClose( root_port );
 
    // destroy the notification port allocated by IORegisterForSystemPower
    IONotificationPortDestroy( notifyPortRef );
}

void Start(const v8::FunctionCallbackInfo<v8::Value>& args) {

    if (refCon) {
	Stop(args);
    }

    isolate = args.GetIsolate();

    Local<Function> cb = Local<Function>::Cast(args[0]);
    callback = new Persistent<Function>(isolate, cb);


    // register to receive system sleep notifications
 
    root_port = IORegisterForSystemPower( refCon, &notifyPortRef, MySleepCallBack, &notifierObject );
    if ( root_port == 0 )
    {
        printf("IORegisterForSystemPower failed\n");
        return;
    }
 
    // add the notification port to the application runloop
    CFRunLoopAddSource( CFRunLoopGetCurrent(),
            IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes );
} 

Handle<Value> Initialize(Handle<Object> target)
{
    target->Set(String::NewFromUtf8(Isolate::GetCurrent(), "start"),
        FunctionTemplate::New(Isolate::GetCurrent(), Start)->GetFunction());

    target->Set(String::NewFromUtf8(Isolate::GetCurrent(), "stop"),
        FunctionTemplate::New(Isolate::GetCurrent(), Stop)->GetFunction());

    target->Set(String::NewFromUtf8(Isolate::GetCurrent(), "getPowerSource"),
        FunctionTemplate::New(Isolate::GetCurrent(), GetPowerSource)->GetFunction());

    return True(Isolate::GetCurrent());
}

NODE_MODULE(osxsleep, Initialize);
