/**
 * TPB_CreateActivityBatchTest
 * @author Guanshu Wang
 * @date 2023-03-17
 * @description Create Activity Base on Org_Unit_Account(Test Class)
 */
@IsTest
public with sharing class TPB_CreateActivityBatchTest {
  @TestSetup
  static void setupData() {
    TestDataFactory.ensureVisitTemplate('0001');
    // Org Unit
    cgcloud__Org_Unit__c orgUnitOne = new cgcloud__Org_Unit__c(
      cgcloud__Sales_Org__c = '0001',
      Name = 'test1'
    );
    insert orgUnitOne;
    orgUnitOne = [
      SELECT Id
      FROM cgcloud__Org_Unit__c
      WHERE Name = 'test1'
      LIMIT 1
    ][0];
    // Account Template
    cgcloud__Account_Template__c accountTemplateOne = new cgcloud__Account_Template__c(
      cgcloud__Sales_Org__c = '0001',
      cgcloud__Active__c = true,
      cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
      cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store'
    );
    insert accountTemplateOne;
    // Account
    Account accountOne = new Account(
      cgcloud__Account_Template__c = accountTemplateOne.Id,
      ShippingCity = 'Danville',
      ShippingCountry = 'US',
      ShippingCountryCode = 'US',
      ShippingPostalCode = '24540',
      ShippingState = 'VA',
      ShippingStateCode = 'VA',
      ShippingStreet = '1234 Mount Cross Road',
      Name = 'Sally Walkers Store #1'
    );
    insert accountOne;
    accountOne = [
      SELECT Id
      FROM Account
      WHERE Name = 'Sally Walkers Store #1'
      LIMIT 1
    ][0];
    // cgcloud__Account_Org_Unit__c
    cgcloud__Account_Org_Unit__c accountOrgUntOne = new cgcloud__Account_Org_Unit__c(
      cgcloud__Account__c = accountOne.Id,
      cgcloud__Active__c = true,
      cgcloud__Org_Unit__c = orgUnitOne.Id,
      cgcloud__Valid_From__c = system.today().addDays(-1),
      cgcloud__Valid_Thru__c = system.today().addDays(1)
    );
    insert accountOrgUntOne;
    // cgcloud__Job_Definition_List_Template__c
    cgcloud__Job_Definition_List_Template__c jDLTOne = new cgcloud__Job_Definition_List_Template__c(
      Name = 'Distribution Activity Template',
      cgcloud__Consider_Account__c = true,
      cgcloud__Consider_Products__c = true,
      cgcloud__Sales_Org__c = '0001'
    );
    insert jDLTOne;
    // cgcloud__Visit_Template__c
    cgcloud__Visit_Template__c vTOne = new cgcloud__Visit_Template__c(
      Name = 'Distribution Visit Template',
      cgcloud__Sales_Org__c = '0001'
    );
    insert vTOne;
  }
  @isTest
  /**
   * @description test Insert Activity And Activity Account Batch
   * @author Guanshu Wang
   */
  static void testInsertActivityAndAcountBatch() {
    Test.startTest();
    TPB_CreateActivityBatch batch = new TPB_CreateActivityBatch();
    Database.executeBatch(batch);
    TPB_CreateActivityBatch batchParamOne = new TPB_CreateActivityBatch(
      'SELECT ID,cgcloud__Account__c,cgcloud__Account__r.Name FROM cgcloud__Account_Org_Unit__c WHERE cgcloud__Active__c = true'
    );
    Database.executeBatch(batchParamOne);
    TPB_CreateActivityBatch batchParamTwo = new TPB_CreateActivityBatch(
      'SELECT ID,cgcloud__Account__c,cgcloud__Account__r.Name FROM cgcloud__Account_Org_Unit__c WHERE cgcloud__Active__c = true',
      'Distribution Activity Template',
      'Distribution Visit Template'
    );
    Database.executeBatch(batchParamTwo);
    Test.stopTest();
    System.assertEquals(
      2,
      [
        SELECT COUNT()
        FROM cgcloud__Job_Definition_List__c
        WHERE CreatedDate = Today
      ],
      0
    );
    System.assertEquals(
      2,
      [
        SELECT COUNT()
        FROM cgcloud__Job_Definition_List_Account__c
        WHERE CreatedDate = Today
      ],
      0
    );
  }
}