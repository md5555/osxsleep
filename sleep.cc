#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
 
#include <mach/mach_port.h>
#include <mach/mach_interface.h>
#include <mach/mach_init.h>
 
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

#include <queue>
 
// node headers
#include <v8.h>
#include <node.h>
#include <unistd.h>
#include <string.h>

using namespace node;
using namespace v8;

Persistent<Function> * callback;
v8::Isolate* isolate;
 
io_connect_t root_port; // a reference to the Root Power Domain IOService

// callback that runs the javascript in main thread
static void Callback(int number)
{
    TryCatch try_catch;
 
    // prepare arguments for the callback
    Local<Value> argv[1];
    argv[0] = Integer::New(isolate, number);
 
    // call the callback and handle possible exception
    callback->Get(isolate)->Call(v8::Object::New(isolate), 1, argv);
 
    if (try_catch.HasCaught()) {
        FatalException(try_catch);
    }
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
 
            IOAllowPowerChange( root_port, (long)messageArgument );
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

void Start(const v8::FunctionCallbackInfo<v8::Value>& args) {

    isolate = args.GetIsolate();

    Local<Function> cb = Local<Function>::Cast(args[0]);
    callback = new Persistent<Function>(isolate, cb);

    // notification port allocated by IORegisterForSystemPower
    IONotificationPortRef  notifyPortRef;
 
    // notifier object, used to deregister later
    io_object_t            notifierObject;
   // this parameter is passed to the callback
    void*                  refCon;
 
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

    return True(Isolate::GetCurrent());
}

NODE_MODULE(osxsleep, Initialize);
