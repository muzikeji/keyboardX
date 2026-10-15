//
//  KayokoHistoryRepository.m
//  Kayoko
//

#import "KayokoHistoryRepository.h"
#import "KayokoHistoryMigrator.h"
#import "KayokoHistoryStore.h"

#import <HBLog.h>
#import <mach/mach_time.h>

static void *kayokoHistoryQueueSpecificKey = &kayokoHistoryQueueSpecificKey;
static NSInteger const kKayokoCoreHistoryStoreBusyTimeoutMilliseconds = 250;

@implementation KayokoHistoryRepository {
    NSString *_databasePath;
    NSString *_imagesPath;
    KayokoHistoryLimitProvider _limitProvider;

    dispatch_queue_t _historyQueue;
    BOOL _didPrepareHistoryStore;
    NSError *_prepareHistoryStoreError;
    KayokoHistoryStore *_historyStore;
}

#pragma mark - Paths

+ (NSString *)defaultDatabasePath {
    return [KayokoHistoryStore defaultDatabasePath];
}

#pragma mark - Lifecycle

- (instancetype)initWithDatabasePath:(NSString *)databasePath
                          imagesPath:(NSString *)imagesPath
                       limitProvider:(KayokoHistoryLimitProvider)limitProvider {
    self = [super init];
    if (self) {
        _databasePath = [databasePath copy];
        _imagesPath = [imagesPath copy];
        _limitProvider = [limitProvider copy];
        _historyQueue = dispatch_queue_create("com.muzi.kayoko.queue.history", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_historyQueue, kayokoHistoryQueueSpecificKey, kayokoHistoryQueueSpecificKey, NULL);
    }
    return self;
}

#pragma mark - Preparation

- (void)prepareStore {
    [self performAsync:^{
      NSError *error = nil;
      if (![self ensureStorePreparedOnQueueWithError:&error]) {
          HBLogDebug(@"Kayoko: Failed to prepare v4 history store: %@", error);
      }
    }];
}

- (void)ensureStorePrepared {
    NSError *error = nil;
    if (![self ensureStorePreparedWithError:&error]) {
        HBLogDebug(@"Kayoko: Failed to prepare v4 history store: %@", error);
    }
}

- (BOOL)ensureStorePreparedWithError:(NSError **)error {
    __block BOOL success = NO;
    __block NSError *blockError = nil;
    [self performSync:^{
      success = [self ensureStorePreparedOnQueueWithError:&blockError];
    }];
    if (error) {
        *error = blockError;
    }
    return success;
}

- (void)closeStore {
    // 关闭只是"释放数据库句柄"，调用方（维护模式）在此之前已置位维护标记，
    // 因此不需要同步语义。
    //
    // 【必须容忍主线程调用】历史队列此刻可能正在做首次建库 / 历史迁移 /
    // 搜索索引升级，耗时可达数十秒。原实现无条件 dispatch_sync，一旦由
    // 主线程触发（Darwin 通知回调就是在主线程执行的，例如安装时 postinst
    // 发来的 prepare-maintenance），就会把主线程整段堵死：
    //   SpringBoard 主线程被堵 → 看门狗 60s 未收到 ping → 强杀 SpringBoard
    //   表现为"安装后一段时间系统卡死，随后自行恢复"。
    // 主线程改为异步执行：立即返回，队列空闲时尽快释放数据库。
    dispatch_block_t closeBlock = ^{
      [_historyStore closeDatabase];
      _historyStore = nil;
      _didPrepareHistoryStore = NO;
      _prepareHistoryStoreError = nil;
    };
    if ([NSThread isMainThread]) {
        [self performAsync:closeBlock];
    } else {
        [self performSync:closeBlock];
    }
}

#pragma mark - Maintenance

- (void)checkpointWriteAheadLog {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      BOOL success = historyStore && [historyStore checkpointWriteAheadLogWithError:&error];
      if (!success) {
          HBLogDebug(@"Kayoko: Failed to checkpoint history database: %@", error);
      }
    }];
}

#pragma mark - Search Index

- (BOOL)upgradeSearchIndexWithError:(NSError **)error {
    __block BOOL success = NO;
    __block NSError *blockError = nil;
    [self performSync:^{
      KayokoHistoryStore *historyStore = [self historyStoreOnQueue];
      success = [historyStore upgradeSearchIndexWithError:&blockError];
      if (success) {
          _didPrepareHistoryStore = YES;
          _prepareHistoryStoreError = nil;
      } else {
          _didPrepareHistoryStore = NO;
          _prepareHistoryStoreError = blockError;
      }
    }];
    if (error) {
        *error = blockError;
    }
    return success;
}

#pragma mark - History Writes

- (BOOL)addItemDictionary:(NSDictionary<NSString *, id> *)dictionary
             toHistoryKey:(NSString *)historyKey
                    error:(NSError **)error {
    __block BOOL success = NO;
    __block NSError *blockError = nil;
    [self performSync:^{
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&blockError];
      success = historyStore && [historyStore addItemDictionary:dictionary
                                                   toHistoryKey:historyKey
                                                          limit:[self limitForHistoryKey:historyKey]
                                                          error:&blockError];
    }];
    if (error) {
        *error = blockError;
    }
    return success;
}

- (void)addItemDictionaries:(NSArray<NSDictionary<NSString *, id> *> *)dictionaries
               toHistoryKey:(NSString *)historyKey
                 completion:(void (^)(NSArray<NSDictionary<NSString *, id> *> *savedDictionaries))completion {
    [self performAsync:^{
      NSMutableArray<NSDictionary<NSString *, id> *> *savedDictionaries =
          [[NSMutableArray alloc] initWithCapacity:[dictionaries count]];
      for (NSDictionary<NSString *, id> *dictionary in dictionaries) {
          NSError *error = nil;
          KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
          BOOL success = historyStore && [historyStore addItemDictionary:dictionary
                                                            toHistoryKey:historyKey
                                                                   limit:[self limitForHistoryKey:historyKey]
                                                                   error:&error];
          if (!success) {
              HBLogDebug(@"Kayoko: Failed to add history item: %@", error);
              continue;
          }
          NSError *latestError = nil;
          NSDictionary<NSString *, id> *savedDictionary =
              [historyStore latestItemForHistoryKey:historyKey error:&latestError] ?: dictionary;
          if (latestError) {
              HBLogDebug(@"Kayoko: Failed to load saved history item: %@", latestError);
          }
          [savedDictionaries addObject:savedDictionary];
      }

      if (!completion) {
          return;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(savedDictionaries);
      });
    }];
}

- (BOOL)moveItemDictionaryToTop:(NSDictionary<NSString *, id> *)dictionary
                   inHistoryKey:(NSString *)historyKey
                          error:(NSError **)error {
    __block BOOL success = NO;
    __block NSError *blockError = nil;
    [self performSync:^{
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&blockError];
      success = historyStore && [historyStore moveItemDictionaryToTop:dictionary
                                                         inHistoryKey:historyKey
                                                                limit:[self limitForHistoryKey:historyKey]
                                                                error:&blockError];
    }];
    if (error) {
        *error = blockError;
    }
    return success;
}

- (BOOL)removeItemDictionary:(NSDictionary<NSString *, id> *)dictionary
              fromHistoryKey:(NSString *)historyKey
           shouldRemoveImage:(BOOL)shouldRemoveImage
                       error:(NSError **)error {
    __block BOOL success = NO;
    __block NSError *blockError = nil;
    [self performSync:^{
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&blockError];
      success = historyStore && [historyStore removeItemDictionary:dictionary
                                                    fromHistoryKey:historyKey
                                                 shouldRemoveImage:shouldRemoveImage
                                                             error:&blockError];
    }];
    if (error) {
        *error = blockError;
    }
    return success;
}

- (void)removeItemDictionary:(NSDictionary<NSString *, id> *)dictionary
              fromHistoryKey:(NSString *)historyKey
           shouldRemoveImage:(BOOL)shouldRemoveImage
                  completion:(void (^)(BOOL success))completion {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      BOOL success = historyStore && [historyStore removeItemDictionary:dictionary
                                                         fromHistoryKey:historyKey
                                                      shouldRemoveImage:shouldRemoveImage
                                                                  error:&error];
      if (!success) {
          HBLogDebug(@"Kayoko: Failed to remove history item: %@", error);
      }
      [self dispatchCompletion:completion success:success];
    }];
}

- (void)moveItemDictionary:(NSDictionary<NSString *, id> *)dictionary
            fromHistoryKey:(NSString *)sourceHistoryKey
              toHistoryKey:(NSString *)destinationHistoryKey
                completion:(void (^)(BOOL success))completion {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      BOOL success = historyStore && [historyStore moveItemDictionary:dictionary
                                                       fromHistoryKey:sourceHistoryKey
                                                         toHistoryKey:destinationHistoryKey
                                                     destinationLimit:[self limitForHistoryKey:destinationHistoryKey]
                                                                error:&error];
      if (!success) {
          HBLogDebug(@"Kayoko: Failed to move history item: %@", error);
      }
      [self dispatchCompletion:completion success:success];
    }];
}

#pragma mark - Note and Tag Persistence

- (void)setNote:(NSString *)note
         tagUUID:(NSString *)tagUUID
forItemDictionary:(NSDictionary<NSString *, id> *)dictionary
     inHistoryKey:(NSString *)historyKey
       completion:(void (^)(BOOL success))completion {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      BOOL success = historyStore && [historyStore setNote:note
                                                   tagUUID:tagUUID
                                          forItemDictionary:dictionary
                                               inHistoryKey:historyKey
                                                      error:&error];
      if (!success) {
          HBLogDebug(@"Kayoko: Failed to set history item note and tag: %@", error);
      }
      [self dispatchCompletion:completion success:success];
    }];
}

#pragma mark - Bulk Removal

- (void)removeItemsFromHistoryKey:(NSString *)historyKey
               shouldRemoveImages:(BOOL)shouldRemoveImages
                       completion:(void (^)(BOOL success))completion {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      BOOL success = historyStore && [historyStore removeItemsFromHistoryKey:historyKey
                                                          shouldRemoveImages:shouldRemoveImages
                                                                       error:&error];
      if (!success) {
          HBLogDebug(@"Kayoko: Failed to remove history items: %@", error);
      }
      [self dispatchCompletion:completion success:success];
    }];
}

- (void)removeImageItemsFromHistoryKey:(NSString *)historyKey
                            completion:(void (^)(BOOL success))completion {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      BOOL success = historyStore && [historyStore removeImageItemsFromHistoryKey:historyKey error:&error];
      if (!success) {
          HBLogDebug(@"Kayoko: Failed to remove image history items: %@", error);
      }
      [self dispatchCompletion:completion success:success];
    }];
}

#pragma mark - History Reads

- (NSMutableArray<NSDictionary<NSString *, id> *> *)itemsForHistoryKey:(NSString *)historyKey error:(NSError **)error {
    __block NSMutableArray<NSDictionary<NSString *, id> *> *history = nil;
    __block NSError *blockError = nil;
    [self performSync:^{
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&blockError];
      history = historyStore ? [historyStore itemsForHistoryKey:historyKey error:&blockError] : nil;
    }];
    if (error) {
        *error = blockError;
    }
    return history ?: [[NSMutableArray alloc] init];
}

- (void)itemsForHistoryKey:(NSString *)historyKey completion:(KayokoHistoryItemsCompletion)completion {
    [self itemsForHistoryKey:historyKey searchCriteria:nil completion:completion];
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)itemsForHistoryKey:(NSString *)historyKey
                                                        searchCriteria:(KayokoSearchCriteria *)searchCriteria
                                                                 error:(NSError **)error {
    __block NSMutableArray<NSDictionary<NSString *, id> *> *history = nil;
    __block NSError *blockError = nil;
    [self performSync:^{
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&blockError];
      history = historyStore
                    ? [historyStore itemsForHistoryKey:historyKey searchCriteria:searchCriteria error:&blockError]
                    : nil;
    }];
    if (error) {
        *error = blockError;
    }
    return history ?: [[NSMutableArray alloc] init];
}

- (void)itemsForHistoryKey:(NSString *)historyKey
            searchCriteria:(KayokoSearchCriteria *)searchCriteria
                completion:(KayokoHistoryItemsCompletion)completion {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      NSMutableArray<NSDictionary<NSString *, id> *> *history =
          historyStore ? [historyStore itemsForHistoryKey:historyKey searchCriteria:searchCriteria error:&error] : nil;
      if (error) {
          HBLogDebug(@"Kayoko: Failed to load history items: %@", error);
      }
      NSMutableArray<NSDictionary<NSString *, id> *> *items = history ?: [[NSMutableArray alloc] init];
      if (!completion) {
          return;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(items, error);
      });
    }];
}

- (NSDictionary<NSString *, id> *)latestItemForHistoryKey:(NSString *)historyKey error:(NSError **)error {
    __block NSDictionary<NSString *, id> *dictionary = nil;
    __block NSError *blockError = nil;
    [self performSync:^{
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&blockError];
      dictionary = historyStore ? [historyStore latestItemForHistoryKey:historyKey error:&blockError] : nil;
    }];
    if (error) {
        *error = blockError;
    }
    return dictionary;
}

#pragma mark - Search Metadata

- (void)availableSearchAppBundleIdentifiersWithCompletion:(KayokoHistoryAppBundleIdentifiersCompletion)completion {
    [self performAsync:^{
      NSError *error = nil;
      KayokoHistoryStore *historyStore = [self preparedHistoryStoreOnQueueWithError:&error];
      NSArray<NSString *> *bundleIdentifiers =
          historyStore ? [historyStore availableSearchAppBundleIdentifiersWithError:&error] : @[];
      if (error) {
          HBLogDebug(@"Kayoko: Failed to load search app tokens: %@", error);
      }
      if (!completion) {
          return;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(bundleIdentifiers ?: @[], error);
      });
    }];
}

#pragma mark - Queue

- (BOOL)isOnHistoryQueue {
    return dispatch_get_specific(kayokoHistoryQueueSpecificKey) == kayokoHistoryQueueSpecificKey;
}

- (void)performAsync:(dispatch_block_t)block {
    if (!block) {
        return;
    }

    if ([self isOnHistoryQueue]) {
        block();
        return;
    }

    dispatch_async(_historyQueue, block);
}

- (void)performSync:(dispatch_block_t)block {
    if (!block) {
        return;
    }

    if ([self isOnHistoryQueue]) {
        block();
        return;
    }

    // 主线程上做同步等待是危险的：历史队列可能正在跑首次建库 / 迁移 / 搜索索引
    // 升级，耗时足以触发系统看门狗把 SpringBoard 强杀。这里加耗时探测，超过
    // 1 秒即落日志，便于下次直接从设备日志定位是哪个调用堵住了主线程。
    if ([NSThread isMainThread]) {
        uint64_t start = mach_absolute_time();
        dispatch_sync(_historyQueue, block);
        static mach_timebase_info_data_t timebase;
        if (timebase.denom == 0) mach_timebase_info(&timebase);
        double ms = (double)(mach_absolute_time() - start) * timebase.numer / timebase.denom / 1e6;
        if (ms > 1000.0) {
            // 必须用 NSLog：HBLogDebug 在 release 构建里会被编译掉，日志不可见。
            NSLog(@"Kayoko: [MAIN-THREAD BLOCK] history performSync blocked the main thread for %.0f ms", ms);
        }
        return;
    }

    dispatch_sync(_historyQueue, block);
}

- (void)dispatchCompletion:(void (^)(BOOL success))completion success:(BOOL)success {
    if (!completion) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      completion(success);
    });
}

#pragma mark - Store

- (KayokoHistoryStore *)historyStoreOnQueue {
    if (!_historyStore) {
        _historyStore =
            [[KayokoHistoryStore alloc] initWithDatabasePath:_databasePath
                                                  imagesPath:_imagesPath
                                                 lockingMode:KayokoHistoryStoreLockingModeExclusiveWhileOpen
                                     busyTimeoutMilliseconds:kKayokoCoreHistoryStoreBusyTimeoutMilliseconds];
    }
    return _historyStore;
}

- (KayokoHistoryStore *)preparedHistoryStoreOnQueueWithError:(NSError **)error {
    KayokoHistoryStore *historyStore = [self historyStoreOnQueue];
    if (![self ensureStorePreparedOnQueueWithError:error]) {
        return nil;
    }
    return historyStore;
}

- (BOOL)ensureStorePreparedOnQueueWithError:(NSError **)error {
    if (_didPrepareHistoryStore) {
        return YES;
    }

    KayokoHistoryStore *historyStore = [self historyStoreOnQueue];
    NSError *prepareError = nil;
    KayokoHistoryMigrator *migrator =
        [[KayokoHistoryMigrator alloc] initWithHistoryStore:historyStore
                                           migrationSources:[KayokoHistoryMigrator defaultMigrationSources]];
    if (![migrator migrateIfNeededWithError:&prepareError]) {
        _prepareHistoryStoreError = prepareError;
        _didPrepareHistoryStore = NO;
        if (error) {
            *error = prepareError;
        }
        return NO;
    }
    if (![historyStore validateSearchIndexWithError:&prepareError]) {
        _prepareHistoryStoreError = prepareError;
        _didPrepareHistoryStore = NO;
        if (error) {
            *error = prepareError;
        }
        return NO;
    }

    _prepareHistoryStoreError = nil;
    _didPrepareHistoryStore = YES;
    return YES;
}

- (NSUInteger)limitForHistoryKey:(NSString *)historyKey {
    if (_limitProvider) {
        return _limitProvider(historyKey);
    }
    return NSUIntegerMax;
}

@end
