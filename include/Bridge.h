#import <Foundation/Foundation.h>
#import <sys/ioctl.h>
#import <sys/mount.h>
#import <sys/snapshot.h>

struct hfs_mount_args {
    char    *fspec;            /* block special device to mount */
    uid_t    hfs_uid;        /* uid that owns hfs files (standard HFS only) */
    gid_t    hfs_gid;        /* gid that owns hfs files (standard HFS only) */
    mode_t    hfs_mask;        /* mask to be applied for hfs perms  (standard HFS only) */
    u_int32_t hfs_encoding;    /* encoding for this volume (standard HFS only) */
    struct    timezone hfs_timezone;    /* user time zone info (standard HFS only) */
    int        flags;            /* mounting flags, see below */
    int     journal_tbuffer_size;   /* size in bytes of the journal transaction buffer */
    int        journal_flags;          /* flags to pass to journal_open/create */
    int        journal_disable;        /* don't use journaling (potentially dangerous) */
};
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

@interface DIBaseParams : NSObject <NSSecureCoding, NSCoding>
-(id)initWithCoder:(id)arg1 ;
-(NSURL *)inputURL;
-(void)encodeWithCoder:(id)arg1 ;
-(id)description;
-(id)initWithURL:(id)arg1 fileOpenMode:(unsigned short)arg2 error:(id)arg3 ;
@end


@interface DIAttachParams : DIBaseParams {

    BOOL _autoMount;
    BOOL _handleRefCount;
    long long _fileMode;
}
@property (assign) BOOL autoMount;                                         //@synthesize autoMount=_autoMount - In the implementation block
@property (assign,nonatomic) long long fileMode;                           //@synthesize fileMode=_fileMode - In the implementation block
-(id)initWithURL:(id)arg1 error:(id)arg2 ;
-(id)initWithCoder:(id)arg1 ;
-(BOOL)autoMount;
-(long long)fileMode;
-(void)setFileMode:(long long)arg1 ;
-(void)setAutoMount:(BOOL)arg1 ;
@end

@interface DIDeviceHandle : NSObject
-(NSString *)BSDName;
-(unsigned long long)regEntryID;
@end

@interface DiskImages2 : NSObject

+(void)attachWithParams:(DIAttachParams *)param handle:(DIDeviceHandle **)h error:(id)err;
@end
