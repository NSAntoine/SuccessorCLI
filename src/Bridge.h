#import <Foundation/Foundation.h>

@interface NSTask : NSObject

- (instancetype __nonnull)init;
- (void)launch;
- (void)setArguments:(NSArray<NSString *> * __nullable)arg1;
- (void)setLaunchPath:(NSString * __nullable)arg1;
- (void)setStandardError:(id __nullable)arg1;
- (void)setStandardOutput:(id __nullable)arg1;
- (void)waitUntilExit;
- (long long)terminationReason;
 @property(readonly) int terminationStatus;
 @property (readonly) long long terminationReason;
@end

extern mach_port_t SBSSpringBoardServerPort(void);
extern int SBDataReset(mach_port_t, int);

