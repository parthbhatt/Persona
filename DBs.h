#import <Foundation/Foundation.h>
#import <sqlite3.h>
//#import "/usr/include/sqlite3.h"


#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define DBNAME @"dbname.db"

@interface DBsSQL : NSObject {
	sqlite3 *dbsDB;
	pthread_mutex_t mutex;
	NSLock	*theLock;
}

+ (void)createEditableCopyOfDatabaseIfNeeded ;
+ (void)copyDBOut;
+ (DBsSQL *)sharedSQLObj;


@end
