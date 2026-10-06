public without sharing class TPB_MobileAppLogPurgeBatch
  implements Database.Batchable<SObject>, Schedulable {

  @TestVisible
  private static final Integer DEFAULT_RETENTION_DAYS = 8;

  @TestVisible
  private static final Integer DEFAULT_BATCH_SIZE = 200;

  @TestVisible
  private static final List<String> TARGET_OBJECT_API_NAMES = new List<String>{
    'cgc_sync__Sync_Mobile_App_Log__c',
    'cgc_sync__Sync_History__c',
    'cgc_sync__Sync_API_Log__c',
    'cgc_sync__Sync_ID_Mapping__c'
  };

  private final Datetime startDateTime;
  private final Datetime endDateTime;
  private final Integer retentionDays;
  private final Integer objectIndex;
  private final String objectApiName;

  public TPB_MobileAppLogPurgeBatch() {
    this(DEFAULT_RETENTION_DAYS);
  }

  public TPB_MobileAppLogPurgeBatch(Integer retentionDays) {
    this(retentionDays, null, null, 0);
  }

  public TPB_MobileAppLogPurgeBatch(
    Datetime startDateTime,
    Datetime endDateTime
  ) {
    this(DEFAULT_RETENTION_DAYS, startDateTime, endDateTime, 0);
  }

  private TPB_MobileAppLogPurgeBatch(
    Integer retentionDays,
    Datetime startDateTime,
    Datetime endDateTime,
    Integer objectIndex
  ) {
    this.retentionDays = normalizeRetentionDays(retentionDays);
    this.objectIndex = normalizeObjectIndex(objectIndex);
    this.objectApiName = TARGET_OBJECT_API_NAMES[this.objectIndex];

    if (startDateTime == null && endDateTime == null) {
      this.startDateTime = null;
      this.endDateTime = buildRetentionCutoff(this.retentionDays, Date.today());
      return;
    }

    this.startDateTime = startDateTime;
    this.endDateTime = endDateTime;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    if (endDateTime == null || (startDateTime != null && startDateTime >= endDateTime)) {
      return Database.getQueryLocator([
        SELECT Id
        FROM cgc_sync__Sync_Mobile_App_Log__c
        WHERE Id = null
      ]);
    }

    String query =
      'SELECT Id FROM ' +
      objectApiName +
      ' WHERE CreatedDate < :endDateTime';

    if (startDateTime != null) {
      query += ' AND CreatedDate >= :startDateTime';
    }

    query += ' ORDER BY CreatedDate ASC';

    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    if (scope.isEmpty()) {
      return;
    }

    Database.DeleteResult[] deleteResults = Database.delete(scope, false);
    List<SObject> deletedRecords = new List<SObject>();

    for (Integer i = 0; i < deleteResults.size(); i++) {
      if (deleteResults[i].isSuccess()) {
        deletedRecords.add(scope[i]);
      }
    }

    if (!deletedRecords.isEmpty()) {
      Database.emptyRecycleBin(deletedRecords);
    }
  }

  public void finish(Database.BatchableContext bc) {
    if (!hasNextObject()) {
      return;
    }

    Database.executeBatch(
      new TPB_MobileAppLogPurgeBatch(
        retentionDays,
        startDateTime,
        endDateTime,
        objectIndex + 1
      ),
      DEFAULT_BATCH_SIZE
    );
  }

  public void execute(SchedulableContext sc) {
    Database.executeBatch(
      new TPB_MobileAppLogPurgeBatch(retentionDays),
      DEFAULT_BATCH_SIZE
    );
  }

  @TestVisible
  private static Datetime buildRetentionCutoff(
    Integer retentionDays,
    Date anchorDate
  ) {
    Integer safeRetentionDays = normalizeRetentionDays(retentionDays);
    Date cutoffDate = anchorDate.addDays(-safeRetentionDays);
    return Datetime.newInstance(
      cutoffDate,
      Time.newInstance(0, 0, 0, 0)
    );
  }

  private static Integer normalizeRetentionDays(Integer retentionDays) {
    return retentionDays == null || retentionDays < 0
      ? DEFAULT_RETENTION_DAYS
      : retentionDays;
  }

  private static Integer normalizeObjectIndex(Integer objectIndex) {
    return objectIndex == null ||
        objectIndex < 0 ||
        objectIndex >= TARGET_OBJECT_API_NAMES.size()
      ? 0
      : objectIndex;
  }

  private Boolean hasNextObject() {
    return objectIndex + 1 < TARGET_OBJECT_API_NAMES.size();
  }
}