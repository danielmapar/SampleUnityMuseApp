//  Copyright © 2016 choosemuse. All rights reserved.

#import <Foundation/Foundation.h>
#import <Muse/Muse.h>

/*
 * This class interacts with the libmuse API and handles
 * getting the data to unity. These methods are called by
 * the extern C functions defined in the .mm file.
 */

@interface LibmuseUnityIos : NSObject
< IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener>

+(LibmuseUnityIos *) getInstance;
-(void) startScan;
-(void) stopScan;
-(void) connect: (NSString*) headband;
-(void) disconnect;
-(void) listenForDataPacket: (NSString *) packetType;
-(void) registerUnityDataListener: (NSString *) objectName toMethod:(NSString*) methodName;
-(void) registerUnityMuseListener: (NSString *) objectName toMethod:(NSString*) methodName;
-(void) registerUnityConnectionListener: (NSString*) objectName toMethod:(NSString*) methodName;
-(void) registerUnityArtifactListener: (NSString*) objectName toMethod:(NSString*) methodName;
@end
