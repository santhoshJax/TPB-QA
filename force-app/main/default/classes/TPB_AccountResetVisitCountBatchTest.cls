/**
 * @author Feng Lian
 * @date 10/5/2023
 * @description TPB_AccountResetVisitCountBatch test class
 */
@isTest
public class TPB_AccountResetVisitCountBatchTest {
    @testSetup
    static void setup() {
        //create Account for test.
        Account accObj = TPB_TestFactory.createAccount();
        accObj.Planned_Visit_Count__c = 0;
        accObj.Completed_Visit_Count__c = 5;
        update accObj;
        
        //create retail store for visit creating.
        RetailStore rsObject = new RetailStore(
            Street = 'U.S. Route 66 ',
            City = 'Baltimore',
            State = 'DC',
            PostalCode = '20001',
            Country = 'US',
            Name = 'Test',
            //create retail store base on account test data.
            AccountId = accObj.Id
        );
        //insert rsObject
        insert rsObject;

        //create visit test data.
        Visit visitObj = new Visit(
            //set account relationship.
            AccountId = accObj.Id,
            Status = 'Planned',
            Account_Name__c = accObj.Name,
            //set actual visit start time as now.
            ActualVisitStartTime = system.now(),
            cgcloud__Accountable__c = UserInfo.getUserId(),
            cgcloud__Creation_Date_and_Time__c = System.now(),
            cgcloud__Creation_Mode__c = 'Manually',
            cgcloud__Responsible__c = UserInfo.getUserId(),
            //set planned start time as now.
            PlannedVisitStartTime = Datetime.newInstance(
                //year
                Integer.valueOf(Date.today().year()),
                //month
                Integer.valueOf(Date.today().month()),
                //day
                Integer.valueOf(Date.today().day()),
                9,
                0,
                0
            ),
            //set planned end time as now.
            PlannedVisitEndTime = Datetime.newInstance(
                //year
                Integer.valueOf(Date.today().year()),
                //month
                Integer.valueOf(Date.today().month()),
                //day
                Integer.valueOf(Date.today().day()),
                9,
                40,
                0
            ),
            //PlaceId = rsObject.Id
            PlaceId = rsObject.Id
        );
        
        //insert visitObj
        insert visitObj;
    }
    
    @isTest
    static void testBatch() {
        System.Test.startTest();
        TPB_AccountResetVisitCountBatch batchJob = new TPB_AccountResetVisitCountBatch();
        Database.executeBatch(batchJob);
        System.Test.stopTest();
        
        List<Account> accs = [
            SELECT Planned_Visit_Count__c, Completed_Visit_Count__c
            FROM Account
            WHERE Name = 'Test Acc'
        ];
        System.assertEquals(1, accs[0].Planned_Visit_Count__c, false);
        System.assertEquals(0, accs[0].Completed_Visit_Count__c, false);
    }
    
    @isTest
    static void testScheduler() {
        System.Test.startTest();
        TPB_AccountResetVisitCountBatch batchJob = new TPB_AccountResetVisitCountBatch();
        batchJob.execute(null);
        System.Test.stopTest();
        
        List<Account> accs = [
            SELECT Planned_Visit_Count__c, Completed_Visit_Count__c
            FROM Account
            WHERE Name = 'Test Acc'
        ];
        System.assertEquals(1, accs[0].Planned_Visit_Count__c, false);
        System.assertEquals(0, accs[0].Completed_Visit_Count__c, false);
    }
}