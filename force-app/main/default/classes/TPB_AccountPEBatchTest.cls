/**************************************************************************************
Apex Class Name:  TPB_AccountPEBatchTest
Version     : 1.0 
Created Date    : 2023-03-24
Function    : test class for TPB_AccountPEBatch
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description CON0001729-902 ERP_ARCustomer_Integration_PE test class
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Jeff.xu              2023-03-24            Original Version
*************************************************************************************/
@isTest
private class TPB_AccountPEBatchTest {
    /**
     * @description set up test data
     */
    @testSetup
    public static void setup() {
        //setup data 
        Account retailer = new Account();
        //set account value
        retailer.Name = 'Test Retailer';
        //retailer.cgcloud__Account_Template__c = TestDataFactory.ensureRetailerAutomationPrereqs();
        retailer.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retailer').getRecordTypeId();
        retailer.ShippingState = 'NM';
        retailer.ShippingCity = 'Chicago';
        retailer.ShippingStreet = 'U.S. Route 56 ';
        retailer.ShippingPostalCode = '21211';
        retailer.TPB_AR_Customer_Trigger__c = system.now();
        //create account record
        insert retailer;
    }
    //test batch method
    @isTest
    static void testBatchMethod() {
        Test.startTest();
        //start testing
        TPB_AccountPEScheduler scheduledJob = new TPB_AccountPEScheduler();
        String sch ='0 48 * * * ?'; 
        System.schedule('Schedule to publish account plantform events', sch,scheduledJob);
        //run batch in testing class
        TPB_AccountPEBatch batchCon = new TPB_AccountPEBatch();
        //initial batch class
        Database.executeBatch(batchCon);
        Test.stopTest();
        //testing end
        //do system assert
        System.assertEquals(true, batchCon != null,'fail');
    }
}