/**
 * @author Qiyuan Dou
 * @date 5/30/2023
 * @description update inventory avg price by order items
 */
@IsTest
public with sharing class TPB_UpdateInvPriceByOrderItemBatchTest {
  @TestSetup
  static void setup() {
    //create Account for test.
    Account accObj = TPB_TestFactory.createAccount();

    //create Visit for test.
    Visit objVisit = TPB_TestFactory.createVisit(accObj);

    //create Order for test.
    Order objOrder1 = new Order();
    objOrder1.Related_Visit__c = objVisit.Id;
    objOrder1.AccountId = accObj.id;
    objOrder1.External_Order_Number__c = 'OD000001';
    objOrder1.External_Amount__c = 100;
    objOrder1.Status = 'Draft';
    objOrder1.TPB_State__c = 'NY';
    objOrder1.EffectiveDate = Date.today();
    objOrder1.Pricebook2Id = Test.getStandardPricebookId();
    insert objOrder1;

    //create Product2 data
    Product2 prod = TPB_TestFactory.createProduct();

    //create PricebookEntry data
    PricebookEntry entry = TPB_TestFactory.createPricebookEntry(prod.Id);

    //create OrderItem data
    OrderItem objOrderItem1 = new OrderItem();
    objOrderItem1.OrderId = objOrder1.Id;
    objOrderItem1.Product2Id = prod.Id;
    objOrderItem1.UoM__c = 'Carton';
    objOrderItem1.Quantity = 10;
    objOrderItem1.UnitPrice = 10.99;
    objOrderItem1.TPB_Type__c = 'Purchase';
    objOrderItem1.PricebookEntryId = entry.Id;
    insert objOrderItem1;
    //set date yesterday
    Test.setCreatedDate(objOrderItem1.Id, Datetime.now().addDays(-1));
    update objOrderItem1;

    //create Inventory
    TPB_TestFactory.createInventory(UserInfo.getUserId(), prod.Id);

    objOrder1.Status = 'Activated';
    update objOrder1;

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
    objUnitOfMeasure.cgcloud__Product__c = prod.Id;
    objUnitOfMeasure.cgcloud__Order_Ability__c = true;
    objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = true;
    objUnitOfMeasure.cgcloud__Sort__c = 1;
    uoms.add(objUnitOfMeasure);

    objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
    objUnitOfMeasure.cgcloud__Unit_Type__c = 'SalesUnit';
    objUnitOfMeasure.cgcloud__Pieces_per_Smallest_Unit__c = 10;
    objUnitOfMeasure.cgcloud__Product__c = prod.Id;
    objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = false;
    objUnitOfMeasure.cgcloud__Order_Ability__c = true;
    objUnitOfMeasure.cgcloud__Is_Order_Unit__c = true;
    objUnitOfMeasure.cgcloud__Sort__c = 2;
    uoms.add(objUnitOfMeasure);

    insert uoms;
  }

  @isTest
  static void testUpdateInvPriceByOrderItemBatch() {
    System.Test.startTest();
    //run batch
    TPB_UpdateInvPriceByOrderItemBatch batch = new TPB_UpdateInvPriceByOrderItemBatch(
      'TODAY',
      true,
      new Set<Id>()
    );
    Database.executeBatch(batch);
    System.Test.stopTest();
    //assert batch job result.
    List<cgcloud__Inventory__c> invs = [
      SELECT
        TPB_AvgPrice__c,
        TPB_StateClassId__c,
        cgcloud__Product__c,
        cgcloud__User__c,
        TPB_Tour_State__c,
        TPB_PricingCategory__c
      FROM cgcloud__Inventory__c
      WHERE cgcloud__Phase__c = 'Active'
    ];
    System.assertEquals(10.99, invs[0].TPB_AvgPrice__c, false);
  }

  @isTest
  static void testUpdateInventoryAvgPriceScheduler() {
    //Execute batch to determine expected returns
    System.Test.startTest();
    TPB_UpdateInventoryAvgPriceScheduler objScheduleJob = new TPB_UpdateInventoryAvgPriceScheduler(
      'TODAY',
      true,
      new Set<Id>()
    );
    objScheduleJob.execute(null);
    System.Test.stopTest();
    //assert batch job result.
    List<cgcloud__Inventory__c> invs = [
      SELECT
        TPB_AvgPrice__c,
        TPB_StateClassId__c,
        cgcloud__Product__c,
        cgcloud__User__c,
        TPB_Tour_State__c,
        TPB_PricingCategory__c
      FROM cgcloud__Inventory__c
      WHERE cgcloud__Phase__c = 'Active'
    ];
    System.assertEquals(10.99, invs[0].TPB_AvgPrice__c, false);
  }

  @isTest
  static void testUpdateInvPriceByOrderItemBatch2() {
    System.Test.startTest();
    Order objOrder = [SELECT Id FROM Order WHERE Status = 'Activated' LIMIT 1];
    //run batch
    TPB_UpdateInvPriceByOrderItemBatch batch = new TPB_UpdateInvPriceByOrderItemBatch(
      new Set<Id>{ objOrder.id },
      true,
      new Set<Id>()
    );
    Database.executeBatch(batch);
    System.Test.stopTest();
    //assert batch job result.
    List<cgcloud__Inventory__c> invs = [
      SELECT
        TPB_AvgPrice__c,
        TPB_StateClassId__c,
        cgcloud__Product__c,
        cgcloud__User__c,
        TPB_Tour_State__c,
        TPB_PricingCategory__c
      FROM cgcloud__Inventory__c
      WHERE cgcloud__Phase__c = 'Active'
    ];
    System.assertEquals(10.99, invs[0].TPB_AvgPrice__c, false);
  }
}