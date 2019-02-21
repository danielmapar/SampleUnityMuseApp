//  Copyright © 2016 choosemuse. All rights reserved.

#import "LibmuseUnityIos.h"
#import <Muse/Muse.h>
#import "UnityInterface.h"

//---------------------------------------------------------------
// Private properties

@interface LibmuseUnityIos ()
    // Muse manager will manage discovery of muses.
    @property IXNMuseManagerIos * manager;

    // A reference of a muse to connect to or already connected.
    @property (weak, nonatomic) IXNMuse * muse;

    // Arrays of listeners from c# side. When you register a listener for a
    // particular data, the C# object and method name will be stored in these array.
    // Each element in the array will be another array of size 2.
    // 1st elem in sub-arry is the obj and 2nd is the method to call.
    @property NSMutableArray * unityDataListeners;
    @property NSMutableArray * unityMuseListeners;
    @property NSMutableArray * unityConnectionListeners;
    @property NSMutableArray * unityArtifactsListeners;

    // Array of data packet types to forward to unity
    @property NSMutableArray * dataPacketToListen;

    // Dictionary of Muse name to Muse objects.
    // Used to find the headband to connect to.
    @property NSMutableDictionary * nameToMuse;
@end




@implementation LibmuseUnityIos

//---------------------------------------------------------------
// extern C functions called by LibmuseBridgeIos from Unity side.
// These func in turn calls the methods in LibmuseUnityIos class below.
// Many of these functions need to convert const char * to NSString *.

extern "C" {
    void _startListening() {
        [[LibmuseUnityIos getInstance] startScan];
    }

    void _stopListening() {
        [[LibmuseUnityIos getInstance] stopScan];
    }

    void _connect(const char * headbandName) {
        // Convert const char * to NSString before calling connect.
        [[LibmuseUnityIos getInstance] connect:
         [NSString stringWithCString:headbandName encoding:NSUTF8StringEncoding]];
    }

    void _disconnect() {
        [[LibmuseUnityIos getInstance] disconnect];
    }

    void _registerMuseListener(const char * obj, const char * method) {
        [[LibmuseUnityIos getInstance]
         registerUnityMuseListener:[NSString stringWithCString:obj encoding:NSUTF8StringEncoding]
         toMethod:[NSString stringWithCString:method encoding:NSUTF8StringEncoding]];
    }

    void _registerConnectionListener(const char * obj, const char * method) {
        [[LibmuseUnityIos getInstance]
         registerUnityConnectionListener:[NSString stringWithCString:obj encoding:NSUTF8StringEncoding]
         toMethod:[NSString stringWithCString:method encoding:NSUTF8StringEncoding]];
    }

    void _registerDataListener(const char * obj, const char* method) {
        [[LibmuseUnityIos getInstance]
         registerUnityDataListener:[NSString stringWithCString:obj encoding:NSUTF8StringEncoding]
         toMethod:[NSString stringWithCString:method encoding:NSUTF8StringEncoding]];
    }

    void _registerArtifactListener(const char * obj, const char* method) {
        [[LibmuseUnityIos getInstance]
         registerUnityArtifactListener:[NSString stringWithCString:obj encoding:NSUTF8StringEncoding]
         toMethod:[NSString stringWithCString:method encoding:NSUTF8StringEncoding]];
    }

    void _listenForDataPacket(const char * packetType) {
        [[LibmuseUnityIos getInstance]
         listenForDataPacket:[NSString stringWithCString:packetType encoding:NSUTF8StringEncoding]];
    }

    const char * _getLibmuseVersion() {
        return [[[IXNLibmuseVersion instance] getString] cStringUsingEncoding:NSUTF8StringEncoding];
    }
}

//---------------------------------------------------------------
// Initializers of static singleton

static LibmuseUnityIos *instance = nil;

+(id) alloc {
    @synchronized(self) {
        NSAssert(instance == nil, @"< Attempted to allocate a second instance of a singleton. >");
        instance = [super alloc];
        return instance;
    }
    return nil;
}

-(id) init {
    if (self = [super init]) {
        // Create muse manager and register this class to listen for muses
        self.manager = [IXNMuseManagerIos sharedManager];
        [self.manager setMuseListener:self];

        self.unityDataListeners = [NSMutableArray array];
        self.unityMuseListeners = [NSMutableArray array];
        self.unityConnectionListeners = [NSMutableArray array];
        self.unityArtifactsListeners = [NSMutableArray array];
        self.dataPacketToListen = [NSMutableArray array];
        self.nameToMuse = [NSMutableDictionary dictionary];
    }
    return self;
}


//---------------------------------------------------------------
// Public method called by extern C functions.
// Some methods will call back to Unity through UnitySendMessage.

+(LibmuseUnityIos *) getInstance {
    @synchronized(self) {
        if (!instance)
            [[LibmuseUnityIos alloc] init];
        return instance;
    }
    return nil;
}

-(void) startScan {
    if([self.unityMuseListeners count]) {
        [self.manager startListening];
    } else {
        NSLog(@"ERROR: Please register a muse listener before start listening for headbands");
    }
}

-(void) stopScan {
    [self.manager stopListening];
}

- (void) connect: (NSString*) headband {
    IXNMuse * muse = [self.nameToMuse valueForKey:headband];
    if (muse != nil) {
        // Listening is an expensive, so stop it now we know what headband to connect to.
        [self.manager stopListening];

        self.muse = muse;
        [self.muse registerConnectionListener:self];

        // Register all the packet type unity requested
        [self registerDataPacketTypes];

        // This call will connect to the headband and start sending data.
        [self.muse runAsynchronously];

    } else {
        NSLog(@"ERROR: Could not connect to chosen headband %@, make sure headband is found by the scan.", headband);
    }

}

- (void) disconnect {
    if(self.muse) {
        [self.muse disconnect];
    }
}

-(void) listenForDataPacket:(NSString *)packetType {
    [self.dataPacketToListen addObject:packetType];
}

-(void) registerUnityDataListener: (NSString *) objectName toMethod:(NSString*) methodName {
    // Store an array of size 2 in the member array.
    NSArray * listener = [NSArray arrayWithObjects:objectName, methodName, nil];
    [self.unityDataListeners addObject:listener];
}

-(void) registerUnityMuseListener:(NSString *)objectName toMethod:(NSString *)methodName {
    // Store an array of size 2 in the member array.
    NSArray * listener = [NSArray arrayWithObjects:objectName, methodName, nil];
    [self.unityMuseListeners addObject:listener];
}

-(void) registerUnityConnectionListener:(NSString *)objectName toMethod:(NSString *)methodName {
    // Store an array of size 2 in the member array.
    NSArray * listener = [NSArray arrayWithObjects:objectName, methodName, nil];
    [self.unityConnectionListeners addObject:listener];
}

-(void) registerUnityArtifactListener:(NSString *)objectName toMethod:(NSString *)methodName {
    // Store an array of size 2 in the member array.
    NSArray * listener = [NSArray arrayWithObjects:objectName, methodName, nil];
    [self.unityArtifactsListeners addObject:listener];
}


//---------------------------------------------------------------
// Private methods, not called by extern C functions.
// Listener translators, these methods forwards data to unity.

- (void)museListChanged {
    // Get the list of muses and create a space-delimited list of muses as a string
    // and send that back to unityMuseListeners. Also store a dict of muse name to muses.
    NSArray * muses = [self.manager getMuses];
    NSMutableString * result = [NSMutableString string];

    for( IXNMuse * muse in muses ) {
        NSString * name = [muse getName];
        [result appendString:name];
        [result appendString:@" "];
        [self.nameToMuse setObject:muse forKey:name];
    }

    // Send back a list of muses to unity muse listeners.
    // Must convert NSString back to const char *.
    for(NSArray * listener in self.unityMuseListeners) {
        UnitySendMessage([listener[0] cStringUsingEncoding:NSUTF8StringEncoding],
                         [listener[1] cStringUsingEncoding:NSUTF8StringEncoding],
                         [result cStringUsingEncoding:NSUTF8StringEncoding]);
    }

}

- (void)receiveMuseConnectionPacket:(IXNMuseConnectionPacket *)packet
                               muse:(IXNMuse *)muse {
    NSString *currState = [self createStateString:packet.currentConnectionState];
    NSString *prevState = [self createStateString:packet.previousConnectionState];
    NSString *state = [NSString stringWithFormat:
                        @"{\"PreviousConnectionState\":\"%@\", \"CurrentConnectionState\":\"%@\"}",
                        prevState, currState];

    for(NSArray * listener in self.unityConnectionListeners) {
        UnitySendMessage([listener[0] cStringUsingEncoding:NSUTF8StringEncoding],
                         [listener[1] cStringUsingEncoding:NSUTF8StringEncoding],
                         [state cStringUsingEncoding:NSUTF8StringEncoding]);
    }

}

- (void)receiveMuseDataPacket:(IXNMuseDataPacket *)packet
                         muse:(IXNMuse *)muse {
    // Create JSON string for data packet type and value
    NSString * packetType = [self createPacketString:packet.packetType];
    NSString * dataValue = [self createDataString:packet];
    NSString * data = [NSString stringWithFormat:
                    @"{\"DataPacketType\":\"%@\",\"DataPacketValue\":%@,\"Timestamp\":%lld}",
                       packetType, dataValue, [packet timestamp]];

    for(NSArray * listener in self.unityDataListeners) {
        UnitySendMessage([listener[0] cStringUsingEncoding:NSUTF8StringEncoding],
                         [listener[1] cStringUsingEncoding:NSUTF8StringEncoding],
                         [data cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (void)receiveMuseArtifactPacket:(IXNMuseArtifactPacket *)packet
                             muse:(IXNMuse *)muse {
    NSString * headbandOn = [NSString stringWithFormat:@"\"%d\"", [packet headbandOn]];
    NSString * blink = [NSString stringWithFormat:@"\"%d\"", [packet blink]];
    NSString * jawClench = [NSString stringWithFormat:@"\"%d\"", [packet jawClench]];
    NSString * data = [NSString stringWithFormat:@"{\"HeadbandOn\":%@, \"Blink\":%@, \"JawClench\":%@}", headbandOn, blink, jawClench];

    for(NSArray * listener in self.unityArtifactsListeners) {
        UnitySendMessage([listener[0] cStringUsingEncoding:NSUTF8StringEncoding],
                         [listener[1] cStringUsingEncoding:NSUTF8StringEncoding],
                         [data cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}



//---------------------------------------------------------------
// Private helper methods

- (void) registerDataPacketTypes {
    for(NSString * type in self.dataPacketToListen) {
        if ([type isEqualToString:@"ACCELEROMETER"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeAccelerometer];
        } else if ([type isEqualToString:@"GYRO"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeGyro];
        } else if ([type isEqualToString:@"EEG"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeEeg];
        } else if ([type isEqualToString:@"QUANTIZATION"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeQuantization];
        } else if ([type isEqualToString:@"BATTERY"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeBattery];
        } else if ([type isEqualToString:@"DRL_REF"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeDrlRef];
        } else if ([type isEqualToString:@"ALPHA_ABSOLUTE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeAlphaAbsolute];
        } else if ([type isEqualToString:@"BETA_ABSOLUTE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeBetaAbsolute];
        } else if ([type isEqualToString:@"DELTA_ABSOLUTE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeDeltaAbsolute];
        } else if ([type isEqualToString:@"THETA_ABSOLUTE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeThetaAbsolute];
        } else if ([type isEqualToString:@"GAMMA_ABSOLUTE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeGammaAbsolute];
        } else if ([type isEqualToString:@"ALPHA_RELATIVE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeAlphaRelative];
        } else if ([type isEqualToString:@"BETA_RELATIVE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeBetaRelative];
        } else if ([type isEqualToString:@"DELTA_RELATIVE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeDeltaRelative];
        } else if ([type isEqualToString:@"THETA_RELATIVE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeThetaRelative];
        } else if ([type isEqualToString:@"GAMMA_RELATIVE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeGammaRelative];
        } else if ([type isEqualToString:@"ALPHA_SCORE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeAlphaScore];
        } else if ([type isEqualToString:@"BETA_SCORE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeBetaScore];
        } else if ([type isEqualToString:@"DELTA_SCORE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeDeltaScore];
        } else if ([type isEqualToString:@"THETA_SCORE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeThetaScore];
        } else if ([type isEqualToString:@"GAMMA_SCORE"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeGammaScore];
        } else if ([type isEqualToString:@"HSI_PRECISION"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeHsiPrecision];
        } else if ([type isEqualToString:@"ARTIFACTS"]) {
            [self.muse registerDataListener:self type:IXNMuseDataPacketTypeArtifacts];
        } else {
            NSLog(@"Invalid input string data packet type");
        }
    }

}

- (NSString*) createStateString:(IXNConnectionState) status {
    NSString * state;
    switch (status) {
        case IXNConnectionStateDisconnected:
            state = @"DISCONNECTED";
            break;
        case IXNConnectionStateConnected:
            state = @"CONNECTED";
            break;
        case IXNConnectionStateConnecting:
            state = @"CONNECTING";
            break;
        case IXNConnectionStateNeedsUpdate:
            state = @"NEEDS_UPDATE";
            break;
        case IXNConnectionStateUnknown:
            state = @"UNKNOWN";
            break;
        default: NSAssert(NO, @"impossible connection state received");
    }
    return state;
}

- (NSString*) createPacketString:(IXNMuseDataPacketType) type {
    NSString * packet;
    switch (type) {
        case IXNMuseDataPacketTypeAccelerometer:
            packet = @"ACCELEROMETER";
            break;
        case IXNMuseDataPacketTypeGyro:
            packet = @"GYRO";
            break;
        case IXNMuseDataPacketTypeEeg:
            packet = @"EEG";
            break;
        case IXNMuseDataPacketTypeQuantization:
            packet = @"QUANTIZATION";
            break;
        case IXNMuseDataPacketTypeBattery:
            packet = @"BATTERY";
            break;
        case IXNMuseDataPacketTypeDrlRef:
            packet = @"DRL_REF";
            break;
        case IXNMuseDataPacketTypeAlphaAbsolute:
            packet = @"ALPHA_ABSOLUTE";
            break;
        case IXNMuseDataPacketTypeBetaAbsolute:
            packet = @"BETA_ABSOLUTE";
            break;
        case IXNMuseDataPacketTypeDeltaAbsolute:
            packet = @"DELTA_ABSOLUTE";
            break;
        case IXNMuseDataPacketTypeThetaAbsolute:
            packet = @"THETA_ABSOLUTE";
            break;
        case IXNMuseDataPacketTypeGammaAbsolute:
            packet = @"GAMMA_ABSOLUTE";
            break;
        case IXNMuseDataPacketTypeAlphaRelative:
            packet = @"ALPHA_RELATIVE";
            break;
        case IXNMuseDataPacketTypeBetaRelative:
            packet = @"BETA_RELATIVE";
            break;
        case IXNMuseDataPacketTypeDeltaRelative:
            packet = @"DELTA_RELATIVE";
            break;
        case IXNMuseDataPacketTypeThetaRelative:
            packet = @"THETA_RELATIVE";
            break;
        case IXNMuseDataPacketTypeGammaRelative:
            packet = @"GAMMA_RELATIVE";
            break;
        case IXNMuseDataPacketTypeAlphaScore:
            packet = @"ALPHA_SCORE";
            break;
        case IXNMuseDataPacketTypeBetaScore:
            packet = @"BETA_SCORE";
            break;
        case IXNMuseDataPacketTypeDeltaScore:
            packet = @"DELTA_SCORE";
            break;
        case IXNMuseDataPacketTypeThetaScore:
            packet = @"THETA_SCORE";
            break;
        case IXNMuseDataPacketTypeGammaScore:
            packet = @"GAMMA_SCORE";
            break;
        case IXNMuseDataPacketTypeHsiPrecision:
            packet = @"HSI_PRECISION";
            break;
        case IXNMuseDataPacketTypeArtifacts:
            packet = @"ARTIFACTS";
            break;
        default:
            break;
    }
    return packet;
}

- (NSString*) createDataString:(IXNMuseDataPacket*) packet {
    // The size of each data packet value for the different type is
    // taken from the comments in IXNMuseDataPacketType
    NSString * data;
    switch (packet.packetType) {
        case IXNMuseDataPacketTypeAccelerometer:
            data = [NSString stringWithFormat:@"[%f, %f, %f]",
                    [packet getAccelerometerValue:IXNAccelerometerForwardBackward],
                    [packet getAccelerometerValue:IXNAccelerometerUpDown],
                    [packet getAccelerometerValue:IXNAccelerometerLeftRight]];
            break;
        case IXNMuseDataPacketTypeBattery:
            data = [NSString stringWithFormat:@"[%f, %f, %f]",
                    [packet getBatteryValue:IXNBatteryChargePercentageRemaining],
                    [packet getBatteryValue:IXNBatteryMillivolts],
                    [packet getBatteryValue:IXNBatteryTemperatureCelsius]];
            break;
        case IXNMuseDataPacketTypeDrlRef:
            data = [NSString stringWithFormat:@"[%f, %f]",
                    [packet getDrlRefValue:IXNDrlRefDrl],
                    [packet getDrlRefValue:IXNDrlRefRef]];
            break;
        case IXNMuseDataPacketTypeGyro:
            data = [NSString stringWithFormat:@"[%f, %f, %f]",
                    [packet getGyroValue:IXNGyroForwardBackward],
                    [packet getGyroValue:IXNGyroUpDown],
                    [packet getGyroValue:IXNGyroLeftRight]];
            break;
        // Everything else is EEG and EEG derived values
        default:
            data = [NSString stringWithFormat:@"[%f, %f, %f, %f, %f, %f]",
                    [packet getEegChannelValue:IXNEegEEG1],
                    [packet getEegChannelValue:IXNEegEEG2],
                    [packet getEegChannelValue:IXNEegEEG3],
                    [packet getEegChannelValue:IXNEegEEG4],
                    [packet getEegChannelValue:IXNEegAUXLEFT],
                    [packet getEegChannelValue:IXNEegAUXRIGHT]];
            break;
    }
    return data;
}

@end
