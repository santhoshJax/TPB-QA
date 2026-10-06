/**
 * @author Mi Li
 * @date 9/14/2023
 * @description CON0001729-1812 Trigger to Update Customer Anchor Set in Real Time
 */
@isTest
private class TPB_AccountCustomerSetHandler_Test {
  @testSetup
  static void setup() {
    TestDataFactory.ensureDistributionVisitTemplate();

    cgcloud__Account_Template__c accTemplate = new cgcloud__Account_Template__c(
      //set account template as active.
      cgcloud__Active__c = true,
      cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
      cgcloud__Description_Language_1__c = 'Customer',
      cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store',
      cgcloud__Sales_Org__c = '0001',
      Name = 'Customer'
    );
    insert accTemplate;

    //create  HQ Account for test.
    Account retailer = new Account(
      ShippingCountry = 'US',
      ShippingLatitude = 38.90996,
      ShippingLongitude = -77.01893,
      cgcloud__Account_Template__c = accTemplate.Id,
      ShippingPostalCode = '20001',
      ShippingState = 'DC',
      ShippingStreet = 'U.S. Route 66 ',
      ShippingCity = 'Baltimore'
    );
    retailer.Name = 'Test retailer1';
    retailer.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Retailer')
      .getRecordTypeId();
    //insert retailer
    insert retailer;

    //create cgcloud__Account_Set__c list data
    List<cgcloud__Account_Set__c> lstAccSet = new List<cgcloud__Account_Set__c>();
    cgcloud__Account_Set__c objAccSet = new cgcloud__Account_Set__c();
    objAccSet.TPB_CustomerSetCriteria__c = 'Name != \'Test retailer1\'';
    objAccSet.cgcloud__Sales_Org__c = '0001';
    lstAccSet.add(objAccSet);

    //create cgcloud__Account_Set__c  data
    cgcloud__Account_Set__c objAccSet2 = new cgcloud__Account_Set__c();
    objAccSet2.TPB_CustomerSetCriteria__c = 'Name != null';
    objAccSet2.cgcloud__Sales_Org__c = '0001';
    lstAccSet.add(objAccSet2);

    //insert lstAccSet
    insert lstAccSet;

    //create cgcloud__Account_Set_Account__c  data
    cgcloud__Account_Set_Account__c objAccSetAcc = new cgcloud__Account_Set_Account__c();
    objAccSetAcc.cgcloud__Account_Set_Account__c = retailer.Id;
    objAccSetAcc.cgcloud__Account_Set__c = objAccSet.Id;
    //insert objAccSetAcc
    insert objAccSetAcc;
  }

  @isTest
  static void testInitDataResult() {
    System.Test.startTest();
    cgcloud__Account_Template__c accTemplate = [
      SELECT Id
      FROM cgcloud__Account_Template__c
      WHERE cgcloud__Sales_Org__c = '0001'
      LIMIT 1
    ];
    //create  HQ Account for test.
    Account retailer = new Account(
      ShippingCountry = 'US',
      ShippingLatitude = 38.90996,
      cgcloud__Account_Template__c = accTemplate.Id,
      ShippingLongitude = -77.01893,
      ShippingPostalCode = '20001',
      ShippingState = 'DC',
      ShippingStreet = 'U.S. Route 66 ',
      ShippingCity = 'Baltimore'
    );
    retailer.Name = 'Test retailer';
    retailer.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Retailer')
      .getRecordTypeId();
    //insert HQ retailer
    insert retailer;

    //Call batch test
    TPB_AccountCustomerSetBatch batchJob = new TPB_AccountCustomerSetBatch();
    Database.executeBatch(batchJob);

    //Call batch test
    TPB_AccountCustomerSetBatch batchJob2 = new TPB_AccountCustomerSetBatch(
      new Set<Id>{ retailer.Id }
    );
    Database.executeBatch(batchJob2);

    //query insert cgcloud__Account_Set_Account__c data
    List<cgcloud__Account_Set_Account__c> lstAccountSetAcc = [
      SELECT Id
      FROM cgcloud__Account_Set_Account__c
      WHERE cgcloud__Account_Set_Account__c = :retailer.Id
      LIMIT 10
    ];
    System.assertEquals(true, lstAccountSetAcc.size() > 0, false);
    System.Test.stopTest();
  }
}