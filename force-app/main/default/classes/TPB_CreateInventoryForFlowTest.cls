/**
 * TPB_CreateInventoryForFlowTest
 *
 * @author Qiyuan Dou
 * @date 2023-04-26
 * @description Create Inventory by flow (Test Class)
 *
 */
@IsTest
public with sharing class TPB_CreateInventoryForFlowTest {
  @TestSetup
  static void setup() {
    //Close inventory trigger
    cgcloud__Trigger_Setting__c customset = new cgcloud__Trigger_Setting__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Name = 'InventoryTrigger',
      cgcloud__Deactivate__c = true
    );
    insert customset;
    // Org Unit
    cgcloud__Org_Unit__c orgUnitOne = new cgcloud__Org_Unit__c(
      cgcloud__Sales_Org__c = '0001',
      Name = 'test1'
    );
    insert orgUnitOne;
    // User
    String orgId = UserInfo.getOrganizationId();
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
      ProfileId = UserInfo.getProfileId(),
      LanguageLocaleKey = 'en_US'
    );
    insert userOne;
    //create product template.
    cgcloud__Product_Template__c proTemplate = new cgcloud__Product_Template__c(
      cgcloud__Active__c = true,
      cgcloud__Description_Language_1__c = 'Product3',
      cgcloud__Price_Required__c = false,
      //set sales org on product template.
      cgcloud__Sales_Org__c = orgUnitOne.cgcloud__Sales_Org__c,
      Name = 'Product3'
    );
    insert proTemplate;
    //create product for test.
    Product2 productThree = new Product2(
      Budget_Code__c = '3352-68-183',
      cgcloud__Competitive_Product__c = false,
      cgcloud__Consumer_Goods_Product_Code__c = '003',
      //set the start date as yesterday.
      cgcloud__Delivery_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Delivery_Valid_Thru__c = system.today().addDays(1),
      cgcloud__Description_1_Language_1__c = 'NICOTINE CHEW - TPR3',
      //set the start date as yesterday.
      cgcloud__Field_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Field_Valid_Thru__c = system.today().addDays(1),
      //set the start date as yesterday.
      cgcloud__Fund_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__Fund_Valid_Thru__c = system.today().addDays(1),
      cgcloud__GTIN__c = '00003',
      cgcloud__Is_Bill_Of_Material__c = false,
      //set the start date as yesterday.
      cgcloud__KAM_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__KAM_Valid_Thru__c = system.today().addDays(1),
      //set the start date as yesterday.
      cgcloud__New_Item_Valid_From__c = system.today().addDays(-1),
      //set the start date as tomorrow.
      cgcloud__New_Item_Valid_Thru__c = system.today().addDays(1),
      cgcloud__Order_Ability__c = 2,
      cgcloud__Power_Supply_Connected__c = false,
      //set product type 'brand'
      cgcloud__Product_Level__c = 'Brand',
      cgcloud__Product_Template__c = proTemplate.Id,
      cgcloud__Product_Type__c = 'Commodity',
      cgcloud__Rounding_Rule_Validation__c = 2,
      //set description
      cgcloud__Short_Description_Language_1__c = 'NICOTINE CHEW - TPR3',
      cgcloud__State__c = '4',
      Clearing_House_Flag__c = false,
      Current_Shiplist_Item__c = false,
      //set cycle group
      Cycle_Group__c = 'NA',
      Default_Zone__c = '2',
      Discount__c = false,
      Display_Group__c = 'COMPETITIVE',
      //set status
      IsActive = true,
      Item_ID__c = '0000',
      Name = 'NICOTINE CHEW - TPR3'
    );
    //insert product to update another product brand
    insert productThree;
    // Set Product brand
    Product2 productOne = TPB_TestFactory.createProduct();
    productOne.cgcloud__Criterion_3_Product__c = productThree.Id;
    update productOne;
    // cgcloud__Warehouse__c
    cgcloud__Warehouse__c warehouseOne = new cgcloud__Warehouse__c(
      Name = 'testWarehouse1',
      cgcloud__Sales_Org__c = orgUnitOne.cgcloud__Sales_Org__c,
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1',
      //set state
      cgcloud__State__c = 'WA'
    );
    insert warehouseOne;
    //cgcloud__Tour_Template__c
    cgcloud__Tour_Template__c tourTemplateOne = new cgcloud__Tour_Template__c(
      Name = 'testTourTemplate1',
      cgcloud__Sales_Org__c = orgUnitOne.cgcloud__Sales_Org__c,
      //set description
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1'
    );
    insert tourTemplateOne;
    //cgcloud__Tour__c
    cgcloud__Tour__c tourOne = new cgcloud__Tour__c(
      Name = 'testTour3',
      cgcloud__Sales_Org__c = orgUnitOne.cgcloud__Sales_Org__c,
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1',
      //set default driver
      cgcloud__Default_Driver__c = userOne.Id,
      cgcloud__Tour_Template__c = tourTemplateOne.Id,
      cgcloud__Status__c = 'initial',
      //set warehouse to get state
      cgcloud__Start_Warehouse__c = warehouseOne.Id
    );
    insert tourOne;
    //cgcloud__Inventory_Control_Template__c
    cgcloud__Inventory_Control_Template__c inventoryTemplateOne = new cgcloud__Inventory_Control_Template__c(
      Name = 'TPB Control Template',
      cgcloud__Sales_Org__c = orgUnitOne.cgcloud__Sales_Org__c,
      //set description
      cgcloud__Description_Language_1__c = 'TPB Control Template'
    );
    insert inventoryTemplateOne;
    //cgcloud__Inventory_Inventory_Transaction_Template__c
    cgcloud__Inventory_Transaction_Template__c inventoryTranTempOne = new cgcloud__Inventory_Transaction_Template__c(
      Name = 'TPB_initial',
      cgcloud__Sales_Org__c = orgUnitOne.cgcloud__Sales_Org__c,
      cgcloud__Description_Language_1__c = 'TPB_initial',
      //set data
      cgcloud__Transaction_Control__c = 'Add',
      cgcloud__Transaction_Type__c = 'Addition',
      cgcloud__Use_Inventory_Reference_1__c = true,
      cgcloud__Use_Inventory_Reference_2__c = true,
      cgcloud__Active__c = true
    );
    //insert
    insert inventoryTranTempOne;
  }
  //test class
  @isTest
  static void test() {
    Test.startTest();
    //set product list
    List<Product2> productLst = [
      SELECT Id, cgcloud__Criterion_3_Product__c
      FROM Product2
      WHERE Name = 'NICOTINE CHEW - TPR'
      LIMIT 1
    ];
    //Add product field to string list
    List<String> prdIdLst = new List<String>();
    if (productLst.size() > 0) {
      prdIdLst.add(productLst[0].cgcloud__Criterion_3_Product__c);
    }
    //set tour list
    List<cgcloud__Tour__c> tourLst = [
      SELECT Id
      FROM cgcloud__Tour__c
      WHERE Name = 'testTour3'
      LIMIT 1
    ];
    //Add tour field to string list
    List<String> tourIdLst = new List<String>();
    if (tourLst.size() > 0) {
      tourIdLst.add(tourLst[0].Id);
    }
    //set initialInventory number
    Integer initialInventoryNum = 1000;
    //create test inner object
    TPB_CreateInventoryForFlow.InputParameters testObj = new TPB_CreateInventoryForFlow.InputParameters();
    testObj.lstCgcloudTour = tourIdLst;
    testObj.lstCgcloudProduct = prdIdLst;
    testObj.cgcloudInitialInventory = initialInventoryNum;
    //Add object to list
    List<TPB_CreateInventoryForFlow.InputParameters> testLst = new List<TPB_CreateInventoryForFlow.InputParameters>();
    testLst.add(testObj);
    //run
    List<Integer> result = TPB_CreateInventoryForFlow.createInventory(testLst);
    System.assertEquals(true, result.size() > 0, 'Success');
    //end test
    Test.stopTest();
  }
}