// Copyright 2015 InteraXon, Inc.

#import <ExternalAccessory/ExternalAccessory.h>
#import <Foundation/Foundation.h>
#import "Muse/api/IXNMuseManager.h"

/**
 * Provides access to all IXNMuse devices paired to this device.
 */
@interface IXNMuseManagerIos : NSObject<IXNMuseManager>

/**
 * Returns the shared IXNMuseManager.
 */
+ (IXNMuseManagerIos *)sharedManager;

/**
 * Displays an alert that allows the user to pair the device with a Muse.
 *
 * This just calls showBluetoothAccessoryPickerWithNameFilter:completion: with
 * a filter that passes devices starting with "Muse".
 *
 * \deprecated This will only display Muse 2014 (
 * \link ::IXNMuseModel::IXNMuseModelMu01 MU_01\endlink
 * ) headsets.  Instead set a IXNMuseListener with IXNMuseManager::setMuseListener:
 * to receive callbacks when either model of headband is detected.
 * See the sample application for an example of how to update the UI and connect
 * to the headset.
 */
- (void)showMusePickerWithCompletion:
    (EABluetoothAccessoryPickerCompletion)completion;

/**
 * Listener called on changes to the list of available muses.
 *
 * Redefined readwrite here (the IXNMuseManager protocol only provides a setter.)
 */
@property (nonatomic, readwrite) id<IXNMuseListener> museListener;

@end
