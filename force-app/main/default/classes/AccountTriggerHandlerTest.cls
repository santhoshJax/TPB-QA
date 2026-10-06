@isTest
public inherited sharing class AccountTriggerHandlerTest {

    public static testMethod void testParent() {
        TPB_TestFactory.createVisitTemplate();
        Account headquarter  = TestDataFactory.createHeadquarterAccount();
        Account retailerOne  = TPB_TestFactory.createAccount();
        retailerOne.ParentId = headquarter.Id;
        retailerOne.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retailer').getRecordTypeId();
		cgcloud__Account_Template__c objAccTemplate = [SELECT Id FROM cgcloud__Account_Template__c LIMIT 1];
        
        test.startTest();
        headquarter.cgcloud__Account_Template__c = objAccTemplate.Id;
        update headquarter;
        
        update retailerOne;
        
        retailerOne.ParentId = null;
        update retailerOne;
        
        retailerOne.ParentId = headquarter.Id;
        update retailerOne;
        
        test.stopTest();

        Account parent = [SELECT Number_of_Linked_Stores__c FROM Account WHERE Id = :headquarter.Id];
        system.assertEquals(1, parent.Number_of_Linked_Stores__c);

        delete retailerOne;

        Account parentAgain = [SELECT Number_of_Linked_Stores__c FROM Account WHERE Id = :headquarter.Id];
        system.assertEquals(1, parentAgain.Number_of_Linked_Stores__c);
    }

}