// This file is generated and will be overwritten automatically.

#import <Foundation/Foundation.h>

@class MBXLocation;

NS_SWIFT_NAME(OpenLRPointLocationInfo)
__attribute__((visibility ("default")))
@interface MBXOpenLRPointLocationInfo : NSObject

- (nonnull instancetype)initWithLocation:(nonnull MBXLocation *)location
                                distance:(double)distance;

/** point location on road graph */
@property (nonatomic, readonly, nonnull) MBXLocation *location;

/** distance from reference point in meters */
@property (nonatomic, readonly) double distance;


@end
