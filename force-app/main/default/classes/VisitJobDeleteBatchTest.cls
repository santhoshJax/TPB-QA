@istest
public class VisitJobDeleteBatchTest {

    @istest
    static void  testVisitJobDeleteBatch(){
        
        // create visit job
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
        Visit visit1 = new Visit(cgcloud__Visit_Template__c=vTOne.id,PlaceId = RTStore.id, AccountId = testAccount.Id, cgcloud__Completed_Date__c = Date.today().addDays(-10),PlannedVisitStartTime = system.today().addDays(-10));
        insert visit1 ;
        
cgcloud__Visit_Job__c visitjob = new cgcloud__Visit_Job__c(
            cgcloud__Visit__c = visit1.Id,
            ToBeArchived__c = true
        );
        insert visitjob;

        // Set the CreatedDate to a specific date (e.g., feb 2, 2022)
        Datetime myCreatedDate = Datetime.newInstance(2022, 2, 2);
        Test.setCreatedDate(visitjob.Id, myCreatedDate);

        test.starttest();
        Database.executeBatch(new VisitJobDeleteBatch(), 200);
        test.stoptest();
     
    }
}