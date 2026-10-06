@isTest
public with sharing class AccountHierarchyTest {

    @testSetup
    public static void setup() {
        Id retailerAccountTemplateId = TestDataFactory.ensureRetailerAutomationPrereqs();

        Account wholesaler = new Account();
        wholesaler.Name = 'Test Wholesaler';
        wholesaler.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Wholesaler').getRecordTypeId();
        insert wholesaler;

        Account headquarter = new Account();
        headquarter.Name = 'Test Headquarter';
        headquarter.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Headquarter').getRecordTypeId();
        insert headquarter;

        Account retailer = new Account();
        retailer.Name = 'Test Retailer';
        retailer.cgcloud__Account_Template__c = retailerAccountTemplateId;
        retailer.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Retailer').getRecordTypeId();
        retailer.ParentId = headquarter.Id;
        insert retailer;

        Related_Account__c related = new Related_Account__c();
        related.Type__c = 'Primary';
        related.Wholesaler__c = wholesaler.Id;
        related.Retailer__c = headquarter.Id;
        insert related;
    }

    public static testMethod void testHeadquarter() {
        List<Account> accounts = [SELECT Id, Name, Owner.Alias, BillingCity, BillingState, Cash_Sales__c, RecordTypeId, RecordType.Name
                                  FROM Account ORDER BY RecordType.Name ASC];
        List<Related_Account__c> related = [SELECT Wholesaler__c, Wholesaler__r.Name, Wholesaler__r.RecordType.Name, Wholesaler__r.Owner.Alias,
                                            Wholesaler__r.BillingCity, Wholesaler__r.BillingState, Wholesaler__r.Cash_Sales__c,
                                            Retailer__c, Retailer__r.Name, Retailer__r.RecordType.Name, Retailer__r.Owner.Alias,
                                            Retailer__r.BillingCity, Retailer__r.BillingState, Retailer__r.Cash_Sales__c, Type__c
                                            FROM Related_Account__c];

        test.startTest();
        String wrapperString = AccountHierarchyController.getAccounts(accounts[0].Id, 'Headquarter', null);
        AccountHierarchyController.updateAccounts(accounts);
        test.stopTest();
        
        List<AccountHierarchyWrapper> wrapperObj = (List<AccountHierarchyWrapper>)JSON.deserialize(wrapperString, List<AccountHierarchyWrapper>.class);
        system.assertEquals('Headquarter', wrapperObj[0].recordType);
    }
    
    public static testMethod void testRetailer() {
        List<Account> accounts = [SELECT Id, Name, Owner.Alias, BillingCity, BillingState, Cash_Sales__c, RecordTypeId, RecordType.Name, ParentId
                                  FROM Account ORDER BY RecordType.Name ASC];
        
        test.startTest();
        String wrapperString = AccountHierarchyController.getAccounts(accounts[1].Id, 'Retailer', accounts[1].ParentId);
        test.stopTest();
        
        List<AccountHierarchyWrapper> wrapperObj = (List<AccountHierarchyWrapper>)JSON.deserialize(wrapperString, List<AccountHierarchyWrapper>.class);
        system.assertEquals('Headquarter', wrapperObj[0].recordType);
    }
    
    public static testMethod void testWholesaler() {
        List<Account> accounts = [SELECT Id, Name, Owner.Alias, BillingCity, BillingState, Cash_Sales__c, RecordTypeId, RecordType.Name, ParentId
                                  FROM Account ORDER BY RecordType.Name ASC];
        List<Related_Account__c> related = [SELECT Wholesaler__c, Wholesaler__r.Name, Wholesaler__r.RecordType.Name, Wholesaler__r.Owner.Alias,
                                            Wholesaler__r.BillingCity, Wholesaler__r.BillingState, Wholesaler__r.Cash_Sales__c,
                                            Retailer__c, Retailer__r.Name, Retailer__r.RecordType.Name, Retailer__r.Owner.Alias,
                                            Retailer__r.BillingCity, Retailer__r.BillingState, Retailer__r.Cash_Sales__c, Type__c
                                            FROM Related_Account__c];
        
        test.startTest();
        String wrapperString = AccountHierarchyController.getAccounts(accounts[2].Id, 'Wholesaler', null);
        test.stopTest();
        
        List<AccountHierarchyWrapper> wrapperObj = (List<AccountHierarchyWrapper>)JSON.deserialize(wrapperString, List<AccountHierarchyWrapper>.class);
        system.assertEquals('Wholesaler', wrapperObj[0].recordType);
    }

}