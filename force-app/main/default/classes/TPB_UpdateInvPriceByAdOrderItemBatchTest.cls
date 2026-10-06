/**
 * @author Qiyuan Dou
 * @date 6/3/2023
 * @description update inventory avg price by advanced order items
 */
@IsTest
public with sharing class TPB_UpdateInvPriceByAdOrderItemBatchTest {
  public static String strUserName =
    'test' +
    '@test' +
    UserInfo.getOrganizationId() +
    '.org';

  @TestSetup
  static void setup() {
    // User
    User userOne = new User(
      Firstname = 'testUser1',
      Username = strUserName,
      LastName = 'testUser1L',
      //Set Email
      Email = strUserName,
      Alias = 'tsmone',
      TimeZoneSidKey = 'Asia/Shanghai',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'ISO-8859-1',
      //Set Profile
      ProfileId = UserInfo.getProfileId(),
      LanguageLocaleKey = 'en_US',
      Need_CG_Cloud_Setup__c = false
    );
    insert userOne;
    //create Account for test.
    Account accObj = TPB_TestFactory.createAccount();
    accObj.ShippingState = 'NY';
    update accObj;

    //create Visit for test.
    Visit objVisit = TPB_TestFactory.createVisit(accObj);

    //create product for test
    Product2 objProduct = TPB_TestFactory.createProduct();

    //create Inventory
    TPB_TestFactory.createInventory(userOne.Id, objProduct.Id);

    //create Order for test.
    cgcloud__Order__c objOrder = TPB_TestFactory.createAdOrder(objVisit);
    objOrder.cgcloud__Phase__c = 'Released';
    objOrder.cgcloud__Release_Time__c = Datetime.now().addDays(-1);
    objOrder.cgcloud__Order_Account__c = accObj.id;
    objOrder.cgcloud__Delivery_Recipient__c = accObj.id;
    objOrder.cgcloud__Accountable__c = userOne.Id;
    update objOrder;

    //create Order Item for test
    cgcloud__Order_Item__c objOrderItem = TPB_TestFactory.createAdOrderItem(
      objOrder,
      objProduct
    );

    cgcloud__Order_Item_Template__c orderItemTemplate = new cgcloud__Order_Item_Template__c();
    //set template as active.
    orderItemTemplate.cgcloud__Active__c = true;
    orderItemTemplate.Name = 'Return';
    insert orderItemTemplate;

    //set date yesterday
    Test.setCreatedDate(objOrderItem.Id, Datetime.now().addDays(-1));
    objOrderItem.cgcloud__Order_Item_Template__c = orderItemTemplate.Id;
    objOrderItem.cgcloud__Base_Price__c = 0;
    objOrderItem.cgcloud__Special_Price__c = 10.99;
    update objOrderItem;

    //create CP_Pricing_Condition_Template data
    cgcloud__CP_Pricing_Condition_Template__c objCPPricing = new cgcloud__CP_Pricing_Condition_Template__c();
    objCPPricing.Name = TPB_PricingUtility.PRICING_CONDITION_TEMPLATES;
    objCPPricing.cgcloud__Active__c = true;
    objCPPricing.cgcloud__Sales_Org__c = '0001';
    objCPPricing.cgcloud__Manual__c = true;
    objCPPricing.cgcloud__Subtotal__c = true;
    objCPPricing.cgcloud__Meta_Type__c = 'Price';
    insert objCPPricing;

    List<cgcloud__Unit_of_Measure__c> uoms = new List<cgcloud__Unit_of_Measure__c>();
    //create Unit of Measure for test.
    cgcloud__Unit_of_Measure__c objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
    objUnitOfMeasure.cgcloud__GTIN__c = '09291934';
    objUnitOfMeasure.cgcloud__Unit_Type__c = 'ConsumerUnit';
    objUnitOfMeasure.cgcloud__Pieces_per_Smallest_Unit__c = 1;
    objUnitOfMeasure.cgcloud__Product__c = objProduct.Id;
    objUnitOfMeasure.cgcloud__Order_Ability__c = true;
    objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = true;
    objUnitOfMeasure.cgcloud__Sort__c = 1;
    uoms.add(objUnitOfMeasure);

    objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
    objUnitOfMeasure.cgcloud__Unit_Type__c = 'SalesUnit';
    objUnitOfMeasure.cgcloud__Pieces_per_Smallest_Unit__c = 10;
    objUnitOfMeasure.cgcloud__Product__c = objProduct.Id;
    objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = false;
    objUnitOfMeasure.cgcloud__Order_Ability__c = true;
    objUnitOfMeasure.cgcloud__Is_Order_Unit__c = true;
    objUnitOfMeasure.cgcloud__Sort__c = 2;
    uoms.add(objUnitOfMeasure);

    insert uoms;
  }

  @isTest
  static void testUpdateInvPriceByAdOrderItemBatch() {
    User userOne = [
      SELECT Id
      FROM User
      WHERE Username = :strUserName AND IsActive = TRUE
      ORDER BY Username
      LIMIT 1
    ];
    System.Test.startTest();
    TPB_UpdateInvPriceByAdOrderItemBatch batchJob = new TPB_UpdateInvPriceByAdOrderItemBatch(
      new Map<String, Double>(),
      true,
      'YESTERDAY',
      new Set<Id>()
    );
    Database.executeBatch(batchJob);
    System.Test.stopTest();
    //assert batch job result.
    cgcloud__Inventory__c inv = [
      SELECT TPB_AvgPrice__c
      FROM cgcloud__Inventory__c
      WHERE cgcloud__User__c = :userOne.Id
    ];
    System.assertEquals(10.99, inv.TPB_AvgPrice__c, false);
  }

  @isTest
  static void testUpdateInvPriceByAdOrderItemBatchTwo() {
    User userOne = [
      SELECT Id
      FROM User
      WHERE Username = :strUserName AND IsActive = TRUE
      ORDER BY Username
      LIMIT 1
    ];
    String query = 'SELECT Id, cgcloud__Order_Item_Template__r.Name, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c, TPB_StateClassId__c, cgcloud__Order__r.cgcloud__Order_Account__r.ShippingState, cgcloud__Product__r.cgcloud__Criterion_5_Product__c, TPB_MaxPrice__c FROM cgcloud__Order_Item__c WHERE CreatedDate= YESTERDAY AND cgcloud__Order__r.cgcloud__Phase__c = :RELEASEDADORDER AND (cgcloud__Order_Item_Template__r.Name = :RETAILERRETURN)';
    System.Test.startTest();
    TPB_UpdateInvPriceByAdOrderItemBatch batchJob = new TPB_UpdateInvPriceByAdOrderItemBatch(
      query,
      new Map<String, Double>(),
      true
    );
    Database.executeBatch(batchJob);
    System.Test.stopTest();
    //assert batch job result.
    cgcloud__Inventory__c inv = [
      SELECT TPB_AvgPrice__c
      FROM cgcloud__Inventory__c
      WHERE cgcloud__User__c = :userOne.Id
    ];
    System.assertEquals(10.99, inv.TPB_AvgPrice__c, false);
  }

  @isTest
  static void testUpdateInvPriceByAdOrderItemBatchThree() {
    User userOne = [
      SELECT Id
      FROM User
      WHERE Username = :strUserName AND IsActive = TRUE
      ORDER BY Username
      LIMIT 1
    ];
    cgcloud__Order__c objOrder = [
      SELECT Id
      FROM cgcloud__Order__c
      WHERE cgcloud__Phase__c = 'Released'
      LIMIT 1
    ];
    System.Test.startTest();
    TPB_UpdateInvPriceByAdOrderItemBatch batchJob = new TPB_UpdateInvPriceByAdOrderItemBatch(
      new Set<Id>{ objOrder.Id },
      true,
      new Set<Id>()
    );
    Database.executeBatch(batchJob);
    System.Test.stopTest();
    //assert batch job result.
    cgcloud__Inventory__c inv = [
      SELECT TPB_AvgPrice__c
      FROM cgcloud__Inventory__c
      WHERE cgcloud__User__c = :userOne.Id
    ];
    System.assertEquals(10.99, inv.TPB_AvgPrice__c, false);
  }
}