@isTest
private class TPB_ArchiveVisitJobsBatchTest {

    @isTest
    static void testArchiveVisitJobsBatch_LessThan2000Jobs() {
        // Create test Account
       
        cgcloud__Account_Template__c accTemplate = new cgcloud__Account_Template__c(
    Name = 'Test Template',
    cgcloud__Sales_Org__c = '0001'
);
insert accTemplate;


        
        Account testAccount = new Account(Name = 'Test Account', Status__c = 'Closed Permanently', Closure_Reason__c = 'Closed Permanently - Out of Business', cgcloud__Account_Template__c = accTemplate.Id);
        insert testAccount;
        cgcloud__Visit_Template__c vTOne = new cgcloud__Visit_Template__c(
            Name = 'Distribution Visit Template',
              cgcloud__Active__c = true,
              cgcloud__Description_Language_1__c='Distribution Visit Template',
            cgcloud__Sales_Org__c = '0001'
          );
          insert vTOne;
        // Retail store for placeid
        RetailStore RTStore = new RetailStore(Name = 'test retail store', accountid = testAccount.Id );
        insert RTStore;
        system.debug('RTStore'+ RTStore.id );
        // Create two visits with different dates
        Visit visit1 = new Visit(cgcloud__Visit_Template__c=vTOne.id,PlaceId = RTStore.id, AccountId = testAccount.Id,   ActualVisitEndTime = Date.today().addMonths(-7).addDays(5),
            PlannedVisitStartTime = Date.today().addMonths(-7).addDays(5));
        insert visit1 ;
        system.debug('visit1'+ visit1.id );
        Visit visit2 = new Visit(cgcloud__Visit_Template__c=vTOne.id,PlaceId = RTStore.id, AccountId = testAccount.Id, 
           ActualVisitEndTime = Date.today().addMonths(-6), 
            PlannedVisitStartTime = Date.today().addMonths(-6)); // Latest
           insert visit2 ;
        //insert new List<Visit>{ visit1, visit2 };

        // Create Visit Jobs linked to each visit
        List<cgcloud__Visit_Job__c> jobs = new List<cgcloud__Visit_Job__c>{
            new cgcloud__Visit_Job__c(cgcloud__Visit__c = visit1.Id),
            new cgcloud__Visit_Job__c( cgcloud__Visit__c = visit2.Id) // Latest
        };
        insert jobs;

        Test.startTest();
        Database.executeBatch(new TPB_ArchiveVisitJobsBatch(), 1000);
        Test.stopTest();

        // Query updated jobs
        List<cgcloud__Visit_Job__c> updatedJobs = [
            SELECT Id, cgcloud__Visit__c, ToBeArchived__c 
            FROM cgcloud__Visit_Job__c 
            WHERE Id IN :jobs
        ];

        // Assert only the job on the older visit was archived
        for (cgcloud__Visit_Job__c job : updatedJobs) {
            if (job.cgcloud__Visit__c == visit1.Id) {
                System.assertEquals(true, job.ToBeArchived__c, 'Old visit job should be archived');
            } else {
                System.assertEquals(false, job.ToBeArchived__c, 'Latest visit job should NOT be archived');
            }
        }
    }

    @isTest
    static void testArchiveVisitJobsBatch_MoreThan2000Jobs() {
        // Create Account and single Visit (older)
                cgcloud__Account_Template__c accTemplate2 = new cgcloud__Account_Template__c(
    Name = 'Test Template',
    cgcloud__Sales_Org__c = '0001'
);
insert accTemplate2;
        Account acc = new Account(Name = 'Test Account2', Status__c = 'Closed Permanently', Closure_Reason__c = 'Closed Permanently - Out of Business', cgcloud__Account_Template__c = accTemplate2.Id);
        insert acc;
        cgcloud__Visit_Template__c vTOne = new cgcloud__Visit_Template__c(
            Name = 'Distribution Visit Template',
              cgcloud__Active__c = true,
              cgcloud__Description_Language_1__c='Distribution Visit Template',
            cgcloud__Sales_Org__c = '0001'
          );
        // Retail store for placeid
        RetailStore RTStore2 = new RetailStore(Name = 'test retail store', accountid = acc.Id );
        insert RTStore2;
          insert vTOne;
        Visit visit1 = new Visit(cgcloud__Visit_Template__c=vTOne.id,AccountId = acc.Id,placeid = RTStore2.id, 
                ActualVisitEndTime = Date.today().addMonths(-7).addDays(5), 
            PlannedVisitStartTime = Date.today().addMonths(-7).addDays(5));
        Visit visit2 = new Visit(cgcloud__Visit_Template__c=vTOne.id, AccountId = acc.Id,placeid = RTStore2.id,
         ActualVisitEndTime = Date.today().addMonths(-6), 
            PlannedVisitStartTime = Date.today().addMonths(-6));
        insert new List<Visit>{ visit1, visit2 };

        // Create 2100 jobs, all linked to the old visit
        List<cgcloud__Visit_Job__c> manyJobs = new List<cgcloud__Visit_Job__c>();
        for (Integer i = 0; i < 2001; i++) {
            manyJobs.add(new cgcloud__Visit_Job__c(cgcloud__Visit__c = visit1.Id));
        }
        insert manyJobs;

        Test.startTest();
VisitJobBulkUpdaterQueueable.doChainJob = false; // ← Add this line
Database.executeBatch(new TPB_ArchiveVisitJobsBatch(), 200);
Test.stopTest();

        // Validate some jobs were marked for archiving (those not latest)
        List<cgcloud__Visit_Job__c> sampleJobs = [
            SELECT Id, ToBeArchived__c 
            FROM cgcloud__Visit_Job__c 
            WHERE cgcloud__Visit__c = :visit1.Id 
            LIMIT 10
        ];
        for (cgcloud__Visit_Job__c job : sampleJobs) {
            System.assertEquals(true, job.ToBeArchived__c, 'Old visit jobs should be archived');
        }

        // Optionally check that the Queueable was enqueued
        // Note: You can't assert inside a queue job here but you know it's enqueued if no exceptions occurred
    }
}