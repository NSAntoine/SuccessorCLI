#import <Foundation/Foundation.h>
#import <sys/ioctl.h>
#define DKIOCEJECT                            _IO('d', 21)
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
NSUInteger IOEJECT = DKIOCEJECT;

@interface DIBaseParams : NSObject <NSSecureCoding, NSCoding>
-(id)initWithCoder:(id)arg1 ;
-(NSURL *)inputURL;
-(void)encodeWithCoder:(id)arg1 ;
-(id)description;
-(id)initWithURL:(id)arg1 fileOpenMode:(unsigned short)arg2 error:(id*)arg3 ;
@end


@interface DIAttachParams : DIBaseParams {

    BOOL _autoMount;
    BOOL _handleRefCount;
    long long _fileMode;
}
@property (assign) BOOL autoMount;                                         //@synthesize autoMount=_autoMount - In the implementation block
@property (assign,nonatomic) long long fileMode;                           //@synthesize fileMode=_fileMode - In the implementation block
-(id)initWithURL:(id)arg1 error:(id*)arg2 ;
-(id)initWithCoder:(id)arg1 ;
-(BOOL)autoMount;
-(long long)fileMode;
-(void)setFileMode:(long long)arg1 ;
-(void)setAutoMount:(BOOL)arg1 ;
@end

@interface DIDeviceHandle : NSObject
-(NSString *)BSDName;
@end

@interface DiskImages2 : NSObject

+(void)attachWithParams:(DIAttachParams *)param handle:(DIDeviceHandle **)h error:(NSError **)err;

@end
