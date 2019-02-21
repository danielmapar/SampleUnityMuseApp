// Copyright 2017 InteraXon, Inc.

#import <Foundation/Foundation.h>
#import "Muse/api/IXNComputingDeviceConfiguration.h"

/**
 * Provides access to the IXNComputingDeviceConfiguration object containing
 * information about the computing device.
 */
@interface IXNComputingDeviceConfigurationFactory : NSObject

/**
 * Static constructor for the singleton object.
 *
 * \return An instance of the IXNComputingDeviceConfigurationFactory object.
 */
+ (nonnull IXNComputingDeviceConfigurationFactory *)getInstance;

/**
 * The IXNComputingDeviceConfiguration structure for the current computing device.
 */
@property (nonatomic, readwrite, nonnull) IXNComputingDeviceConfiguration * computingDeviceConfiguration;

@end
