public without sharing class TPB_VisitJobArchivePurgeBatch
  implements Database.Batchable<SObject>, Schedulable {

  @TestVisible
  private static final Integer DEFAULT_RETENTION_MONTHS = 6;

  @TestVisible
  private static final Integer DEFAULT_BATCH_SIZE = 200;

  private final Datetime startVisitEndTime;
  private final Datetime endVisitEndTime;
  private final Integer customRetentionDays;

  public TPB_VisitJobArchivePurgeBatch() {
    this(null);
  }

  public TPB_VisitJobArchivePurgeBatch(Integer retentionDays) {
    this(retentionDays, null, null);
  }

  public TPB_VisitJobArchivePurgeBatch(
    Datetime startVisitEndTime,
    Datetime endVisitEndTime
  ) {
    this(null, startVisitEndTime, endVisitEndTime);
  }

  private TPB_VisitJobArchivePurgeBatch(
    Integer retentionDays,
    Datetime startVisitEndTime,
    Datetime endVisitEndTime
  ) {
    this.customRetentionDays = normalizeRetentionDays(retentionDays);
    Datetime preservationCutoff = buildPreservationCutoff(
      this.customRetentionDays,
      Date.today()
    );

    if (startVisitEndTime == null && endVisitEndTime == null) {
      this.startVisitEndTime = null;
      this.endVisitEndTime = preservationCutoff;
      return;
    }

    this.startVisitEndTime = startVisitEndTime;
    this.endVisitEndTime =
      endVisitEndTime == null || endVisitEndTime > preservationCutoff
        ? preservationCutoff
        : endVisitEndTime;
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    if (
      endVisitEndTime == null ||
      (startVisitEndTime != null && startVisitEndTime >= endVisitEndTime)
    ) {
      return Database.getQueryLocator([
        SELECT Id
        FROM cgcloud__Visit_Job__c
        WHERE Id = null
      ]);
    }

    String query =
      'SELECT Id FROM cgcloud__Visit_Job__c' +
      ' WHERE cgcloud__Visit__r.ActualVisitEndTime != null' +
      ' AND cgcloud__Visit__r.ActualVisitEndTime < :endVisitEndTime' +
      ' AND cgcloud__Visit__r.Last_Call__c = FALSE';

    if (startVisitEndTime != null) {
      query +=
        ' AND cgcloud__Visit__r.ActualVisitEndTime >= :startVisitEndTime';
    }

    query += ' ORDER BY cgcloud__Visit__r.ActualVisitEndTime ASC';

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
  }

  public void execute(SchedulableContext sc) {
    Database.executeBatch(
      customRetentionDays == null
        ? new TPB_VisitJobArchivePurgeBatch()
        : new TPB_VisitJobArchivePurgeBatch(customRetentionDays),
      DEFAULT_BATCH_SIZE
    );
  }

  @TestVisible
  private static Datetime buildDefaultPreservationCutoff(Date anchorDate) {
    Date cutoffDate = anchorDate.addMonths(-DEFAULT_RETENTION_MONTHS);
    return Datetime.newInstance(
      cutoffDate,
      Time.newInstance(0, 0, 0, 0)
    );
  }

  @TestVisible
  private static Datetime buildPreservationCutoff(
    Integer retentionDays,
    Date anchorDate
  ) {
    return retentionDays == null
      ? buildDefaultPreservationCutoff(anchorDate)
      : buildRetentionCutoff(retentionDays, anchorDate);
  }

  @TestVisible
  private static Datetime buildRetentionCutoff(
    Integer retentionDays,
    Date anchorDate
  ) {
    Integer safeRetentionDays = retentionDays == null || retentionDays < 0
      ? 0
      : retentionDays;
    Date cutoffDate = anchorDate.addDays(-safeRetentionDays);
    return Datetime.newInstance(
      cutoffDate,
      Time.newInstance(0, 0, 0, 0)
    );
  }

  private static Integer normalizeRetentionDays(Integer retentionDays) {
    return retentionDays == null || retentionDays < 0 ? null : retentionDays;
  }
}