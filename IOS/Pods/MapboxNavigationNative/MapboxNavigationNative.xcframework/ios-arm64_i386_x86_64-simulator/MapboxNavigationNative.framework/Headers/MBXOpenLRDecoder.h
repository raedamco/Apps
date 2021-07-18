// This file is generated and will be overwritten automatically.

#import <Foundation/Foundation.h>
#import "MBXDecodeCallback.h"
#import "MBXDecodePointsCallback.h"
#import "MBXStandard.h"
#import <CoreLocation/CoreLocation.h>

@class MBXCacheHandle;

NS_SWIFT_NAME(OpenLRDecoder)
__attribute__((visibility ("default")))
@interface MBXOpenLRDecoder : NSObject

- (nonnull instancetype)initWithCache:(nonnull MBXCacheHandle *)cache;
/**
 * Decodes given base64-encoded reference and returns result in callback.
 * In case of error(if there is no tiles in cache, decoding failed etc) returns it's description.
 */
- (void)decodeForBase64Encoded:(nonnull NSArray<NSString *> *)base64Encoded
                      standard:(MBXStandard)standard
                      callback:(nonnull MBXDecodeCallback)callback;
/**
 * Decodes given points via doing projection to road graph.
 * Projection points sorted via distance to original point in ascending order are returned as result.
 * @param points
 * @param radius in meters in which we try to find projections
 * @param callback
 */
- (void)decodePointsForPoints:(nonnull NSArray<CLLocation *> *)points
                       radius:(double)radius
                     callback:(nonnull MBXDecodePointsCallback)callback;

@end
