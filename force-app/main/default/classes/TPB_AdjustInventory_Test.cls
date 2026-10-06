/**
 * @author Mi Li
 * @date 6/5/2023
 * @description CON0001729-1249  Inventory Adjustment Screen Flow   TPB_AdjustInventory test class
 */
@isTest
public with sharing class TPB_AdjustInventory_Test {
  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;

  @testSetup
  static void setup() {
    //create profile data
    profile profileOne = [
      SELECT id
      FROM Profile
      WHERE Name = 'CG Cloud Mobile - TSM'
    ];
    //query user data.
    String orgId = UserInfo.getOrganizationId();
    //create User  test.
    User userOne = new User(
      Firstname = 'testUser1',
      Username = 'test' + '@test' + orgId + '.org',
      LastName = 'testUser1L',
      //Set Email
      Email = 'test' + '@test' + orgId + '.org',
      Alias = 'tsmone',
      TimeZoneSidKey = 'Asia/Shanghai',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'ISO-8859-1',
      //Set Profile
      ProfileId = profileOne.Id,
      TPB_Territory__c = '208A01T',
      LanguageLocaleKey = 'en_US',
      TPB_Inventory_Adjustment_Amount__c = 1
    );
    //insert userOne
    insert userOne;
    //createProductData
    createProductData(userOne.Id);
  }

  /**
   * @description create Product Data description
   * @param  strUserId  String
   */
  @future
  public static void createProductData(String strUserId) {
    //create Product Group
    cgcloud__Product_Template__c proTemplate = new cgcloud__Product_Template__c(
      cgcloud__Active__c = true,
      cgcloud__Description_Language_1__c = 'Product Group',
      cgcloud__Price_Required__c = false,
      //set sales org on product template.
      cgcloud__Sales_Org__c = '0001',
      Name = 'Product Group'
    );
    //insert proTemplate
    insert proTemplate;

    //create Criterion_5_Product
    Product2 proObj = new Product2();
    proObj.cgcloud__State__c = '4';
    proObj.Name = 'NICOTINE CHEW - TPR 2';
    proObj.cgcloud__Description_1_Language_1__c = 'NICOTINE CHEW - TPR 2';
    proObj.cgcloud__Product_Template__c = proTemplate.Id;
    proObj.cgcloud__Product_Level__c = 'Package';
    proObj.TPB_Exclude_From_Base_Pricing__c = false;
    //insert proObj
    insert proObj;

    //create Product2 data
    Product2 prod = TPB_TestFactory.createProduct();
    prod.cgcloud__Criterion_5_Product__c = proObj.Id;
    //update prod
    update prod;

    // create Inventory Control Template test data.
    TPB_TestFactory.createInventoryControlTemplate();
    // create Inventory Transaction Template test data.
    TPB_TestFactory.createInventoryTransactionTemplate();
    //create Unit of Measure for test.
    cgcloud__Unit_of_Measure__c objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
    objUnitOfMeasure.cgcloud__GTIN__c = '09291934';
    objUnitOfMeasure.cgcloud__Product__c = prod.Id;
    //insert objUnitOfMeasure
    insert objUnitOfMeasure;

    //create Inventory
    User userOne = [SELECT id FROM User WHERE Firstname = 'testUser1'];
    System.runAs(userOne) {
      //createInventory
      TPB_TestFactory.createInventory(strUserId, prod.Id);
    }
  }

  @isTest
  static void testSearchDataResult() {
    // get Product2
    Product2 prod = [
      SELECT Id
      FROM Product2
      WHERE Name = 'NICOTINE CHEW - TPR'
      LIMIT 1
    ];
    System.Test.startTest();

    //scannedProduct  Incoming parameters
    Map<String, Object> mapScannedProductCode = TPB_AdjustInventory.scannedProduct(
      '09291934',
      'NY',
      null
    );
    //scannedProduct  Incoming parameters
    Map<String, Object> mapScannedProductId = TPB_AdjustInventory.scannedProduct(
      '09291934',
      'NY',
      prod.Id
    );

    //query cgcloud__Inventory__c data
    cgcloud__Inventory__c objInventory = [
      SELECT Id, TPB_StateClassId__c
      FROM cgcloud__Inventory__c
      WHERE Id != NULL
      LIMIT 1
    ];
    objInventory.TPB_AvgPrice__c = 2;
    update objInventory;
    //update parameters

    //Creating parameters to pass values
    Map<String, String> item = new Map<String, String>();
    item.put(
      'productId',
      String.valueOf(mapScannedProductCode.get('productId'))
    );
    item.put('inventoryId', '');
    item.put('inventoryBalance', '3');
    item.put('inventoryOldBalance', '5');
    item.put('state', 'NY');

    //upsertInventory Method
    User userOne = [SELECT id FROM User WHERE Firstname = 'testUser1'];
    Map<String, Object> mapUpsertInventory = new Map<String, Object>();
    System.runAs(userOne) {
      mapUpsertInventory = TPB_AdjustInventory.upsertInventory(item);
    }

    item.put('inventoryOldBalance', '1');
    item.put('inventoryId', objInventory.Id);
    Map<String, Object> mapUpsertInventory2 = new Map<String, Object>();
    System.runAs(userOne) {
      mapUpsertInventory2 = TPB_AdjustInventory.upsertInventory(item);
    }
    //upsertInventory Method
    System.Test.stopTest();

    //assert map result.
    System.assertNotEquals(
      null,
      mapScannedProductCode.get(RTN_KEY_RESULT),
      RTN_KEY_NG
    );
    //assert Equals
    System.assertNotEquals(
      null,
      mapScannedProductId.get(RTN_KEY_RESULT),
      RTN_KEY_NG
    );
    //assert Equals
    System.assertNotEquals(
      null,
      mapUpsertInventory.get(RTN_KEY_RESULT),
      RTN_KEY_NG
    );
    //assert Equals
    System.assertNotEquals(
      null,
      mapUpsertInventory2.get(RTN_KEY_RESULT),
      RTN_KEY_NG
    );
  }
}