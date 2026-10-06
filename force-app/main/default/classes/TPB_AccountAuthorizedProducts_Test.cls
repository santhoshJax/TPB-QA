/**
 * @author Mi Li
 * @date 5/8/2023
 * @description CON0001729-330:Add Inventory Purchased from Wholesaler   TPB_AccountAuthorizedProducts test class
 */
@isTest
public with sharing class TPB_AccountAuthorizedProducts_Test {
  @testSetup
  static void setup() {
    //create User data
    Account objAccount = TPB_TestFactory.createWholesaleAccount();
    //create Product2 data
    Product2 prod = new Product2();
    prod.Name = 'Test Product2';
    prod.IsActive = true;
    prod.NTC_Item_Classification__c = 'Straight Stock';
    prod.cgcloud__Product_Level__c = 'Flavor';
    insert prod;

    //create cgcloud__Criterion_4_Product__c ='Flavor' product  data
    Product2 prod1 = new Product2();
    prod1.Name = 'Test Product2';
    prod1.IsActive = true;
    prod1.cgcloud__Criterion_4_Product__c = prod.Id;
    prod1.NTC_Item_Classification__c = 'Straight Stock';
    insert prod1;

    //create Account_Product__c data
    TPB_TestFactory.createAccountProduct(objAccount.Id, prod1.Id);
  }

  @isTest
  static void testAccountProd() {
    //query Account_Product__c  Account  Product2 data
    Account objAccount = [
      SELECT Id, Name
      FROM Account
      WHERE Name = 'Test Wholesale Account'
      LIMIT 1
    ];
    Product2 prod = [
      SELECT
        Id,
        Name,
        cgcloud__Product_Level__c,
        Item_ID__c,
        Product2.cgcloud__Criterion_4_Product__c,
        Product2.cgcloud__Criterion_4_Product__r.Name
      FROM Product2
      WHERE Name = 'Test Product2'
      LIMIT 1
    ];
    Account_Product__c accProd2 = null;

    //create User data
    TPB_AccountAuthorizedProductsWrapper wrapper = new TPB_AccountAuthorizedProductsWrapper(
      prod,
      accProd2,
      objAccount.Id,
      'Wholesaler'
    );

    Test.startTest();
    //Calling searchProducts Methods
    TPB_AccountAuthorizedProducts.searchProducts(objAccount.Id, 'Wholesaler');
    //Calling upsertProducts Methods
    String strResult = TPB_AccountAuthorizedProducts.upsertProducts(
      JSON.serialize(new List<TPB_AccountAuthorizedProductsWrapper>{ wrapper }),
      objAccount.Id
    );
    System.assertEquals('SUCCESS', strResult, 'ERROR');
    Test.stopTest();
  }
}