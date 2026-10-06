@IsTest
private class TPB_VisitJobArchivePurgeBatchTest {

  private static Integer accountCounter = 0;

  private class VisitJobTestData {
    Id accountId;
    Id visitId;
    Id visitJobId;
  }

  private static VisitJobTestData createVisitJob(Datetime actualVisitEndTime) {
    accountCounter++;

    cgcloud__Account_Template__c accountTemplate =
      new cgcloud__Account_Template__c(
        Name = 'Archive Template ' + accountCounter,
        cgcloud__Sales_Org__c = '0001'
      );
    insert accountTemplate;

    Account accountRecord = new Account(
      Name = 'Archive Account ' + accountCounter,
      Status__c = 'Closed Permanently',
      Closure_Reason__c = 'Closed Permanently - Out of Business',
      cgcloud__Account_Template__c = accountTemplate.Id
    );
    insert accountRecord;

    cgcloud__Visit_Template__c visitTemplate = new cgcloud__Visit_Template__c(
      Name = 'Distribution Visit Template ' + accountCounter,
      cgcloud__Active__c = true,
      cgcloud__Description_Language_1__c = 'Distribution Visit Template',
      cgcloud__Sales_Org__c = '0001'
    );
    insert visitTemplate;

    RetailStore retailStore = new RetailStore(
      Name = 'Archive Retail Store ' + accountCounter,
      AccountId = accountRecord.Id
    );
    insert retailStore;

    Visit visitRecord = new Visit(
      cgcloud__Visit_Template__c = visitTemplate.Id,
      PlaceId = retailStore.Id,
      AccountId = accountRecord.Id,
      ActualVisitEndTime = actualVisitEndTime,
      PlannedVisitStartTime = actualVisitEndTime
    );
    insert visitRecord;

    cgcloud__Visit_Job__c visitJob = new cgcloud__Visit_Job__c(
      cgcloud__Visit__c = visitRecord.Id
    );
    insert visitJob;

    VisitJobTestData testData = new VisitJobTestData();
    testData.accountId = accountRecord.Id;
    testData.visitId = visitRecord.Id;
    testData.visitJobId = visitJob.Id;

    return testData;
  }

  private static void markVisitAsLastCompletedCall(VisitJobTestData testData) {
    update new Account(
      Id = testData.accountId,
      Last_Completed_Call__c = testData.visitId
    );
  }

  @IsTest
  static void explicitWindowPreservesLastCallAndRecentVisitJobs() {
    Datetime nowValue = System.now();
    VisitJobTestData oldCandidate = createVisitJob(nowValue.addMonths(-8));
    VisitJobTestData lastCallCandidate = createVisitJob(nowValue.addMonths(-8));
    VisitJobTestData recentCandidate = createVisitJob(nowValue.addMonths(-5));

    markVisitAsLastCompletedCall(lastCallCandidate);

    Test.startTest();
    Database.executeBatch(
      new TPB_VisitJobArchivePurgeBatch(
        nowValue.addMonths(-9),
        nowValue
      ),
      50
    );
    Test.stopTest();

    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Id = :oldCandidate.visitJobId
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Id = :lastCallCandidate.visitJobId
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Id = :recentCandidate.visitJobId
      ]
    );
  }

  @IsTest
  static void scheduledRunPurgesOnlyOldNonLastCallVisitJobs() {
    Datetime cutoff = TPB_VisitJobArchivePurgeBatch.buildDefaultPreservationCutoff(
      Date.today()
    );

    VisitJobTestData oldestJob = createVisitJob(cutoff.addDays(-10));
    VisitJobTestData purgeCandidate = createVisitJob(
      cutoff.addMinutes(-1)
    );
    VisitJobTestData protectedLastCallJob = createVisitJob(
      cutoff.addDays(-5)
    );
    VisitJobTestData retainedJob = createVisitJob(cutoff.addHours(12));

    markVisitAsLastCompletedCall(protectedLastCallJob);

    Test.startTest();
    new TPB_VisitJobArchivePurgeBatch().execute((SchedulableContext) null);
    Test.stopTest();

    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Id = :oldestJob.visitJobId
      ]
    );
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Id = :purgeCandidate.visitJobId
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Id = :protectedLastCallJob.visitJobId
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Visit_Job__c
        WHERE Id = :retainedJob.visitJobId
      ]
    );
  }
}