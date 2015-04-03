#import "DBsSQL.h"



@implementation DBsSQL
- (id) init {
	if (self = [super init]) {
		theLock = [[NSLock alloc] init];
	}
	return self;
}

- (BOOL) CreateListDisplayFields:(NSString **) errMsg
{
	char *st, *errorMsg;
	*errMsg = nil;
	
	st = sqlite3_mprintf("CREATE TABLE tablename (EventId INTEGER NOT NULL , MapFieldName TEXT, Sequence INTEGER NOT NULL, DBTableColumnName TEXT)");
	int ret = sqlite3_exec(dbsDB, st, NULL, NULL, &errorMsg);
	
	if (ret != SQLITE_OK)
	{
		if (ret == SQLITE_ERROR){
			if (strstr(errorMsg, "table tablename already exists") != nil){
				ret = SQLITE_OK;
				sqlite3_free(errorMsg);
				sqlite3_free(st);
				return YES;
			}
		}
		*errMsg = [[NSString alloc] initWithString:[NSString stringWithUTF8String:errorMsg]];
		sqlite3_free(errorMsg);
		sqlite3_free(st);
		return NO;
	}
	sqlite3_free(st);
	return YES;
}

- (BOOL) RenameTableNameToTableNameOld:(NSString **) errMsg
{
	char *st, *errorMsg;
	*errMsg = nil;
	
	st = sqlite3_mprintf("ALTER TABLE tablename RENAME TO tablenameOld");
	
	int ret = sqlite3_exec(dbsDB, st, NULL, NULL, &errorMsg);
	
	if (ret != SQLITE_OK)
	{

		if (ret == SQLITE_ERROR){
			if ((strstr(errorMsg, "there is already another table or index with this name: tablenameOld") != nil)
            ||  (strstr(errorMsg, "no such table: tablename") != nil)){
				ret = SQLITE_OK;
				sqlite3_free(errorMsg);
				sqlite3_free(st);
				return YES;
			}
		}
		*errMsg = [[NSString alloc] initWithString:[NSString stringWithUTF8String:errorMsg]];
		sqlite3_free(errorMsg);
		sqlite3_free(st);
		return NO;
	}
	sqlite3_free(st);
	return YES;	
	
}

- (BOOL) CopyDataFromTableNameOldToTableName:(NSString **) errMsg
{
	char *st, *errorMsg;
	*errMsg = nil;
	BOOL result = NO;
    
	int ret = sqlite3_exec(dbsDB, "BEGIN TRANSACTION", NULL, NULL, &errorMsg);
	
	if (ret != SQLITE_OK) {
		*errMsg = [[NSString alloc] initWithString:[NSString stringWithUTF8String:errorMsg]];
        sqlite3_free(errorMsg);
		sqlite3_exec(leadsDb, "COMMIT TRANSACTION", NULL, NULL, &errorMsg);
		return result;
	}
	
	st = sqlite3_mprintf("INSERT INTO TableName ('Additional', 'SeqNo', 'DBID', 'EventId', 'field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15', 'field16', 'field17', 'field18', 'field19', 'field20') SELECT Additional, SeqNo, LeadId, EventId, field1, field2, field3, field4, field5, field6, field7, field8, field9, field10, field11, field12, field13, field14, field15, field16, field17, field18, field19, field20 FROM TableNameOld");
	
	ret = sqlite3_exec(leadsDb, st, NULL, NULL, &errorMsg);
	
	if (ret != SQLITE_OK) {
        *errMsg = [[NSString alloc] initWithString:[NSString stringWithUTF8String:errorMsg]];
		sqlite3_free(errorMsg);
		result = NO;
	}
	else {
		result = YES;
	}
    
	sqlite3_exec(leadsDb, "COMMIT TRANSACTION", NULL, NULL, &errorMsg);
	sqlite3_free(st);
	return result;	
	
}

- (BOOL) DropTableNameOld:(NSString **) errMsg  //Same in Update
{
	char *st, *errorMsg;
	*errMsg = nil;
	
	st = sqlite3_mprintf("DROP TABLE TableNameOld");
	
    int ret = sqlite3_exec(dbsDB, st, NULL, NULL, &errorMsg);
	
	if (ret != SQLITE_OK)
	{
        *errMsg = [[NSString alloc] initWithString:[NSString stringWithUTF8String:errorMsg]];
        sqlite3_free(errorMsg);
		sqlite3_free(st);
		return NO;
	}
	sqlite3_free(st);
	return YES;	
	
}

- (int) RetrieveData:(int) DBID
{
	char *st;
	
	st = sqlite3_mprintf("SELECT FieldName FROM TableName WHERE DBID = %d", DBID);
	
	int next = 0;
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare_v2(dbsDB, st, -1, &statement, NULL) == SQLITE_OK)
	{
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			next = sqlite3_column_int(statement, 0);			
		}
		
		sqlite3_finalize(statement);
	} 
	sqlite3_free(st);
	return next;	
}

+ (void)createEditableCopyOfDatabaseIfNeeded  
{
    BOOL success; 
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    NSError *error; 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:DBNAME]; 
    success = [fileManager fileExistsAtPath:writableDBPath]; 
    if (success) return;
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DBNAME]; 
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error]; 
    if (!success)  
    { 
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]); 
    } 
}  

+ (void)copyDBOut
{
    BOOL success; 
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    NSError *error; 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:DBNAME]; 
    success = [fileManager fileExistsAtPath:writableDBPath]; 
    if (success) return;
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DBNAME]; 
	
    success = [fileManager copyItemAtPath:writableDBPath toPath:defaultDBPath error:&error]; 
    if (!success)  
    { 
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]); 
    } 
	
}

+ (DBsSQL *)sharedSQLObj
{
	static DBsSQL *_sharedSQLObj;
	
	@synchronized(self) {
		if(!_sharedSQLObj) {
			_sharedSQLObj = [[DBsSQL alloc] init];
		}		
	}
	
	return _sharedSQLObj;
	
}

- (BOOL)OpenDatabase:(NSString *)dbName
{
	while (![theLock tryLock]) [NSThread sleepForTimeInterval:0.1f];
	dbsDB = nil;
	NSString *dbPath = [DOCUMENTS_FOLDER stringByAppendingPathComponent:dbName];
	if (sqlite3_open([dbPath UTF8String], &dbsDB) != SQLITE_OK)
	{
		return NO;
	}
	
	return YES;
}

- (BOOL)OpenDatabaseForOnce:(NSString *)dbName
{
	if (![theLock tryLock]) return NO;
	else {
		while (![theLock tryLock]) [NSThread sleepForTimeInterval:0.1f];
	}
	
	dbsDB = nil;
	NSString *dbPath = [DOCUMENTS_FOLDER stringByAppendingPathComponent:dbName];
		
	if (sqlite3_open([dbPath UTF8String], &dbsDB) != SQLITE_OK)
	{
		return NO;
	}
	
	return YES;
	
}

- (void) CloseDatabase
{
	if (dbsDB != nil)
		sqlite3_close(dbsDB);
	[theLock unlock];
}

- (BOOL) InsertData: (Entity *)e
{
	char *st, *errorMsg;
	
	st = sqlite3_mprintf("INSERT INTO TableName (F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14) VALUES"
						 " (%d, '%s','%s', '%s', '%s', '%s','%s', '%s', '%s', '%s', %d, '%s', %d, %d) ", f13,
						 [[self formatDataStringForInsertion:e.F1] UTF8String],
						 [[self formatDataStringForInsertion:e.F2] UTF8String], [[self formatDataStringForInsertion:e.F3] UTF8String],
						 [[self formatDataStringForInsertion:e.F4] UTF8String], [[self formatDataStringForInsertion:e.F5] UTF8String],
						 [[self formatDataStringForInsertion:e.F6] UTF8String], [[self formatDataStringForInsertion:e.F7] UTF8String],
						 [[self formatDataStringForInsertion:e.F8] UTF8String], [[self formatDataStringForInsertion:e.F9] UTF8String], 0,
						 [[self formatDataStringForInsertion:e.F10] UTF8String], 0, e.F11?1:0);
	
	
	int ret = sqlite3_exec(dbsDB, st, NULL, NULL, &errorMsg);
	
	if (ret != SQLITE_OK)
	{
		sqlite3_free(errorMsg);
		sqlite3_free(st);
		return NO;
	}
	sqlite3_free(st);
	return YES;
}

@end
