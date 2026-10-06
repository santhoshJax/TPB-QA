@IsTest
private class TPB_MobileAppLogPurgeBatchTest {

  private static Integer logCounter = 0;

  @IsTest
  static void supportsAllRequestedSyncObjects() {
    System.assertEquals(
      4,
      TPB_MobileAppLogPurgeBatch.TARGET_OBJECT_API_NAMES.size()
    );
    System.assert(
      TPB_MobileAppLogPurgeBatch.TARGET_OBJECT_API_NAMES.contains(
        'cgc_sync__Sync_Mobile_App_Log__c'
      )
    );
    System.assert(
      TPB_MobileAppLogPurgeBatch.TARGET_OBJECT_API_NAMES.contains(
        'cgc_sync__Sync_History__c'
      )
    );
    System.assert(
      TPB_MobileAppLogPurgeBatch.TARGET_OBJECT_API_NAMES.contains(
        'cgc_sync__Sync_API_Log__c'
      )
    );
    System.assert(
      TPB_MobileAppLogPurgeBatch.TARGET_OBJECT_API_NAMES.contains(
        'cgc_sync__Sync_ID_Mapping__c'
      )
    );
  }

  private static cgc_sync__Sync_Mobile_App_Log__c createLogRecord() {
    logCounter++;
    cgc_sync__Sync_Mobile_App_Log__c logRecord = new cgc_sync__Sync_Mobile_App_Log__c(
      cgc_sync__DeviceId__c = 'device-' + logCounter,
      cgc_sync__Generated_At__c = System.now(),
      cgc_sync__Message__c = 'Test log'
    );
    insert logRecord;
    return logRecord;
  }

  @IsTest
  static void deletesLogsInsideExplicitWindow() {
    Datetime nowValue = System.now();
    cgc_sync__Sync_Mobile_App_Log__c oldLog = createLogRecord();
    cgc_sync__Sync_Mobile_App_Log__c secondOldLog = createLogRecord();
    cgc_sync__Sync_Mobile_App_Log__c recentLog = createLogRecord();

    Test.setCreatedDate(oldLog.Id, nowValue.addDays(-12));
    Test.setCreatedDate(secondOldLog.Id, nowValue.addDays(-9));
    Test.setCreatedDate(recentLog.Id, nowValue.addDays(-2));

    Test.startTest();
    Database.executeBatch(
      new TPB_MobileAppLogPurgeBatch(nowValue.addDays(-13), nowValue.addDays(-8)),
      50
    );
    Test.stopTest();

    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgc_sync__Sync_Mobile_App_Log__c
        WHERE Id = :oldLog.Id
      ]
    );
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgc_sync__Sync_Mobile_App_Log__c
        WHERE Id = :secondOldLog.Id
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgc_sync__Sync_Mobile_App_Log__c
        WHERE Id = :recentLog.Id
      ]
    );
  }

  @IsTest
  static void scheduledRunPurgesAllLogsOlderThanRetention() {
    Datetime cutoff = TPB_MobileAppLogPurgeBatch.buildRetentionCutoff(
      8,
      Date.today()
    );

    cgc_sync__Sync_Mobile_App_Log__c oldestLog = createLogRecord();
    cgc_sync__Sync_Mobile_App_Log__c purgeCandidate = createLogRecord();
    cgc_sync__Sync_Mobile_App_Log__c retainedLog = createLogRecord();

    Test.setCreatedDate(oldestLog.Id, cutoff.addDays(-4));
    Test.setCreatedDate(purgeCandidate.Id, cutoff.addMinutes(-1));
    Test.setCreatedDate(retainedLog.Id, cutoff.addHours(12));

    Test.startTest();
    new TPB_MobileAppLogPurgeBatch(8).execute((SchedulableContext) null);
    Test.stopTest();

    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgc_sync__Sync_Mobile_App_Log__c
        WHERE Id = :oldestLog.Id
      ]
    );
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgc_sync__Sync_Mobile_App_Log__c
        WHERE Id = :purgeCandidate.Id
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgc_sync__Sync_Mobile_App_Log__c
        WHERE Id = :retainedLog.Id
      ]
    );
  }
}