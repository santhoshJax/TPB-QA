/**
 * @author Mi Li
 * @date 5/8/2023
 * @description CON0001729-330:Add Inventory Purchased from Wholesaler   TPB_AddInventoryPurchasedForm test class
 */
@isTest
private class TPB_AddInventoryPurchasedForm_Test {
  public static String salesOrg = '0001';
  private static String strTest = 'test';
  private static String strTestDotPdf = 'test.pdf';
  //Order  Van_Load recordType Id
  public static String orderVanLoadRecordTypeId = TPB_TestFactory.orderVanLoadRecordTypeId;
  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  //user name and Email
  private static String strUser =
    'testUser2' +
    '@test' +
    UserInfo.getOrganizationId() +
    '.org';

  @testSetup
  static void setup() {
    //create profile data
    profile profileOne = [
      SELECT id
      FROM Profile
      WHERE Name = 'CG Cloud Mobile - TSM'
    ];

    //create User data
    User userOne = new User(
      Firstname = 'test',
      Username = strUser,
      LastName = 'Test',
      Email = strUser,
      Alias = 'tsmtwo',
      TimeZoneSidKey = 'Asia/Shanghai',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'ISO-8859-1',
      ProfileId = profileOne.Id,
      TPB_Territory__c = '208A01T',
      LanguageLocaleKey = 'en_US'
    );
    //insert userOne
    insert userOne;

    //create Inventory Control Template
    TPB_TestFactory.createInventoryControlTemplate();
    //create Inventory Transaction Template
    TPB_TestFactory.createInventoryTransactionTemplate();

    // cgcloud__Warehouse__c
    cgcloud__Warehouse__c warehouseOne = new cgcloud__Warehouse__c(
      Name = 'testWarehouse1',
      cgcloud__Sales_Org__c = salesOrg,
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1',
      //set state
      cgcloud__State__c = 'NY'
    );
    //insert warehouseOne
    insert warehouseOne;

    //cgcloud__Tour_Template__c
    cgcloud__Tour_Template__c tourTemplateOne = new cgcloud__Tour_Template__c(
      Name = 'testTourTemplate1',
      cgcloud__Sales_Org__c = salesOrg,
      //set description
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1'
    );
    //insert tourTemplateOne
    insert tourTemplateOne;

    //cgcloud__Tour__c
    cgcloud__Tour__c tourOne = new cgcloud__Tour__c(
      Name = 'testTour3',
      cgcloud__Sales_Org__c = salesOrg,
      cgcloud__Description_Language_1__c = 'testWarehouseDescription1',
      //set default driver
      cgcloud__Default_Driver__c = UserInfo.getUserId(),
      cgcloud__Tour_Template__c = tourTemplateOne.Id,
      cgcloud__Status__c = 'initial',
      //set warehouse to get state
      cgcloud__Start_Warehouse__c = warehouseOne.Id
    );
    //insert tourOne
    insert tourOne;

    System.runAs(userOne) {
      //insert cgcloud__Org_Unit__c
      cgcloud__Org_Unit__c objOrgUnit = new cgcloud__Org_Unit__c();
      objOrgUnit.cgcloud__Org_Level__c = 'SalesRep';
      objOrgUnit.cgcloud__Org_Type__c = 'Sales';
      objOrgUnit.cgcloud__Sales_Org__c = '0001';
      objOrgUnit.Org_Unit_Main__c = true;
      objOrgUnit.Name = '109A17T';
      insert objOrgUnit;
      //insert objOrgUnit

      //insert TPB_Org_Unit_Mapping__c
      TPB_Org_Unit_Mapping__c objOrgUnitMapping = new TPB_Org_Unit_Mapping__c();
      objOrgUnitMapping.TPB_Zip_Code__c = '20001';
      objOrgUnitMapping.TPB_Org_Unit__c = objOrgUnit.Id;
      insert objOrgUnitMapping;
      //insert objOrgUnitMapping

      //insert cgcloud__Org_Unit_User__c
      cgcloud__Org_Unit_User__c objOrgUnitUser = new cgcloud__Org_Unit_User__c();
      objOrgUnitUser.cgcloud__Org_Unit__c = objOrgUnit.Id;
      objOrgUnitUser.cgcloud__User__c = userOne.Id;
      insert objOrgUnitUser;
      //insert objOrgUnitUser

      //create Account for test.
      Account accObj = TPB_TestFactory.createAccount();
      //create visit for test.
      Visit objVisit = TPB_TestFactory.createVisit(accObj);
      //create Order for test.
      Order objOrder = new Order();
      objOrder.Related_Visit__c = objVisit.Id;
      objOrder.TPB_State__c = 'KY';
      objOrder.AccountId = accObj.id;
      objOrder.External_Order_Number__c = 'OD000001';
      objOrder.External_Amount__c = 100;
      objOrder.Status = 'Draft';
      objOrder.EffectiveDate = Date.today();
      objOrder.Pricebook2Id = test.getStandardPricebookId();
      objOrder.RecordTypeId = orderVanLoadRecordTypeId;
      insert objOrder;
      //insert objOrder

      //crate Order data
      Order objOrder2 = new Order();
      objOrder2.Related_Visit__c = objVisit.Id;
      objOrder2.TPB_State__c = 'NY';
      objOrder2.AccountId = accObj.id;
      objOrder2.External_Order_Number__c = 'OD000001';
      objOrder2.External_Amount__c = 100;
      objOrder2.Status = 'Draft';
      objOrder2.EffectiveDate = Date.today();
      objOrder2.Pricebook2Id = test.getStandardPricebookId();
      objOrder2.RecordTypeId = orderVanLoadRecordTypeId;
      insert objOrder2;
      //insert Order data

      //create Product2 data
      Product2 prod = TPB_TestFactory.createProduct();
      //create Pricebook Entry
      PricebookEntry entry = TPB_TestFactory.createPricebookEntry(prod.Id);

      //create Unit of Measure for test.
      List<cgcloud__Unit_of_Measure__c> lstUom = new List<cgcloud__Unit_of_Measure__c>();
      //create Unit of Measure for test.
      cgcloud__Unit_of_Measure__c objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
      objUnitOfMeasure.cgcloud__GTIN__c = '09291934';
      objUnitOfMeasure.cgcloud__Unit_Type__c = 'ConsumerUnit';
      objUnitOfMeasure.cgcloud__Pieces_per_Smallest_Unit__c = 1;
      objUnitOfMeasure.cgcloud__Product__c = prod.Id;
      objUnitOfMeasure.cgcloud__Order_Ability__c = true;
      objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = true;
      objUnitOfMeasure.cgcloud__Sort__c = 1;
      lstUom.add(objUnitOfMeasure);

      //create SalesUnit Unit of Measure for test.
      objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
      objUnitOfMeasure.cgcloud__Unit_Type__c = 'SalesUnit';
      objUnitOfMeasure.cgcloud__Pieces_per_Smallest_Unit__c = 10;
      objUnitOfMeasure.cgcloud__Product__c = prod.Id;
      objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = false;
      objUnitOfMeasure.cgcloud__Order_Ability__c = true;
      objUnitOfMeasure.cgcloud__Is_Order_Unit__c = true;
      objUnitOfMeasure.cgcloud__Sort__c = 2;
      lstUom.add(objUnitOfMeasure);

      //create Layer Unit of Measure for test.
      objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
      objUnitOfMeasure.cgcloud__Unit_Type__c = 'Layer';
      objUnitOfMeasure.cgcloud__Pieces_per_Smallest_Unit__c = 50;
      objUnitOfMeasure.cgcloud__Product__c = prod.Id;
      objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = false;
      objUnitOfMeasure.cgcloud__Order_Ability__c = true;
      objUnitOfMeasure.cgcloud__Is_Order_Unit__c = false;
      objUnitOfMeasure.cgcloud__Sort__c = 3;
      lstUom.add(objUnitOfMeasure);

      //insert cgcloud__Unit_of_Measure__c
      insert lstUom;

      //create OrderItem data
      OrderItem objOrderItem = new OrderItem();
      objOrderItem.OrderId = objOrder.Id;
      objOrderItem.Product2Id = prod.Id;
      objOrderItem.UoM__c = 'Case';
      objOrderItem.Quantity = 1;
      objOrderItem.UnitPrice = 100;
      objOrderItem.TPB_Type__c = 'Purchase';
      objOrderItem.PricebookEntryId = entry.Id;
      insert objOrderItem;
      //insert objOrderItem

      //create OrderItem data
      OrderItem objOrderItem2 = new OrderItem();
      objOrderItem2.OrderId = objOrder2.Id;
      objOrderItem2.Product2Id = prod.Id;
      objOrderItem2.UoM__c = 'Case';
      objOrderItem2.Quantity = 1;
      objOrderItem2.UnitPrice = 100;
      objOrderItem2.TPB_Type__c = 'Purchase';
      objOrderItem2.PricebookEntryId = entry.Id;
      insert objOrderItem2;
      //insert objOrderItem2

      //create ContentVersion for test.
      ContentVersion objContentVersion = new ContentVersion(
        VersionData = Blob.valueOf(strTest),
        PathOnClient = strTestDotPdf,
        Title = strTest
      );
      //insert objContentVersion
      insert objContentVersion;

      //create ContentDocumentLink for test.
      List<ContentVersion> lstContentVersion = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :objContentVersion.Id
      ];
      //insert ContentDocumentLink for test.
      insert new ContentDocumentLink(
        LinkedEntityId = objOrder.Id,
        ContentDocumentId = lstContentVersion[0].ContentDocumentId
      );
    }
  }

  @isTest
  static void testSearchDataResult() {
    System.Test.startTest();
    TPB_AddInventoryPurchasedFormService.strPriceBook = null;
    //query Order data
    Order objOrder = [SELECT Id FROM Order WHERE TPB_State__c = 'KY' LIMIT 1];
    //query Visit data
    Visit objVisit = [
      SELECT Id
      FROM Visit
      WHERE cgcloud__Creation_Mode__c = 'Manually'
      LIMIT 1
    ];
    //searchDataResult  Incoming parameters
    Map<String, Object> mapOrderData = TPB_AddInventoryPurchasedFormService.searchDataResult(
      objOrder.id
    );
    //searchDataResult  Incoming parameters
    Map<String, Object> mapVisitData = TPB_AddInventoryPurchasedFormService.searchDataResult(
      objVisit.id
    );
    //searchOrderItems Method
    Map<String, Object> mapOrderItemData = TPB_AddInventoryPurchasedForm.searchOrderItems(
      objOrder.id
    );

    System.Test.stopTest();
    //assert map result.
    System.assertEquals(objVisit.Id, mapVisitData.get('dataVisit'), '');
    //assert map result.
    System.assertNotEquals(null, mapOrderData.get('dataOrder'), RTN_KEY_NG);
    //assert map result.
    System.assertNotEquals(null, mapOrderData.get('dataFile'), RTN_KEY_NG);
    //assert map result.
    System.assertNotEquals(null, mapOrderItemData.get('data'), RTN_KEY_NG);
  }

  @isTest
  static void testSaveOrder() {
    System.Test.startTest();
    TPB_AddInventoryPurchasedFormService.strPriceBook = null;
    //query Visit data
    Visit objVisit = [
      SELECT Id
      FROM Visit
      WHERE cgcloud__Creation_Mode__c = 'Manually'
      LIMIT 1
    ];
    //saveOrder Method
    TPB_AddInventoryPurchasedForm.OrderObject orderObjectClass = new TPB_AddInventoryPurchasedForm.OrderObject();
    orderObjectClass.strOrderId = null;
    orderObjectClass.strVisitId = objVisit.Id;
    orderObjectClass.stateOptionsValue = 'KY';
    orderObjectClass.strInvoiceNumber = 'OD000002';
    orderObjectClass.strDollarAmountOfInvoice = '100';
    // run saveOrder
    Map<String, String> mapResult = TPB_AddInventoryPurchasedFormService.saveOrder(
      orderObjectClass
    );

    System.Test.stopTest();
    //assert map result.
    System.assertNotEquals(null, mapResult.get(RTN_KEY_RESULT), RTN_KEY_NG);
  }

  @isTest
  static void testSaveOrderDetail() {
    System.Test.startTest();
    TPB_AddInventoryPurchasedFormService.strPriceBook = null;
    //Internal class methods pass values
    TPB_AddInventoryPurchasedFormWrapper.OrderDetail objOrderDetail = new TPB_AddInventoryPurchasedFormWrapper.OrderDetail();
    objOrderDetail.Product2Id = '';
    objOrderDetail.UnitPrice = 1.0;
    objOrderDetail.Quantity = 1;
    objOrderDetail.UoM = '';

    //query Order data
    Order objOrder = [SELECT Id FROM Order WHERE TPB_State__c = 'KY' LIMIT 1];
    //query Product2 data
    Product2 objProduct2 = [
      SELECT Id
      FROM Product2
      WHERE Name = 'NICOTINE CHEW - TPR'
      LIMIT 1
    ];
    //query OrderItem data
    OrderItem objOrderItem = [
      SELECT Id
      FROM OrderItem
      WHERE OrderId = :objOrder.Id
      LIMIT 1
    ];

    //Create test data
    List<Map<String, String>> inputItems = new List<Map<String, String>>();
    Map<String, String> mapProductData = new Map<String, String>();
    mapProductData.put('Product2Id', objProduct2.Id);
    mapProductData.put('UnitPrice', '100');
    mapProductData.put('Quantity', '10');
    mapProductData.put('UoM__c', 'Case');
    inputItems.add(mapProductData);

    //saveOrderDetail Method
    Map<String, String> mapResult = TPB_AddInventoryPurchasedForm.saveOrderDetail(
      String.valueOf(objOrder.Id),
      inputItems
    );
    //deleteOrderItem Method
    Map<String, String> mapDeleteOrderItemResult = TPB_AddInventoryPurchasedForm.deleteOrderItem(
      objOrderItem.Id
    );

    System.Test.stopTest();
    //assert map result.
    System.assertNotEquals(null, mapResult.get(RTN_KEY_RESULT), RTN_KEY_NG);
    //assert map result.
    System.assertEquals(
      RTN_KEY_OK,
      mapDeleteOrderItemResult.get(RTN_KEY_RESULT),
      ''
    );
  }

  @isTest
  static void testAddContentDocumentLink() {
    System.Test.startTest();
    //query Order data
    Order objOrder = [
      SELECT Id, AccountId
      FROM Order
      WHERE TPB_State__c = 'KY' AND AccountId != NULL
      LIMIT 1
    ];
    //query User data
    User objUser = [SELECT Id FROM User WHERE Username = :strUser LIMIT 1];
    //query ContentDocumentLink data
    List<ContentDocumentLink> lstContentDocument = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :objOrder.Id
    ];
    List<String> lstDocumentId = new List<String>();
    lstDocumentId.add(lstContentDocument[0].ContentDocumentId);

    //addContentDocumentLink Method
    Map<String, String> mapResult = TPB_AddInventoryPurchasedFormService.addContentDocumentLink(
      lstDocumentId,
      objOrder.Id
    );
    //deleteFiles Method
    Map<String, String> mapDeleteFilesResult = TPB_AddInventoryPurchasedForm.deleteFiles(
      lstContentDocument[0].id
    );

    //searchUserState Method
    Map<String, Object> mapStateData = new Map<String, Object>();
    System.runAs(objUser) {
      mapStateData = TPB_AddInventoryPurchasedFormService.searchUserState();
    }
    //searchUserState Method
    Map<String, Object> mapStateData2 = TPB_AddInventoryPurchasedFormService.searchUserState();
    System.Test.stopTest();
    //assert map result.
    System.assertNotEquals(null, mapResult.get(RTN_KEY_RESULT), RTN_KEY_NG);
    //assert map result.
    System.assertEquals(
      RTN_KEY_OK,
      mapDeleteFilesResult.get(RTN_KEY_RESULT),
      RTN_KEY_NG
    );
    //assert map result.
    System.assertEquals(
      RTN_KEY_OK,
      mapStateData.get(RTN_KEY_RESULT),
      RTN_KEY_NG
    );
    //assert map result.
    System.assertEquals(
      RTN_KEY_OK,
      mapStateData2.get(RTN_KEY_RESULT),
      RTN_KEY_NG
    );
  }

  @isTest
  static void testAddScannedProduct() {
    System.Test.startTest();
    TPB_AddInventoryPurchasedFormService.strPriceBook = null;
    //query TPB_State__c = 'KY' data
    Order objOrder = [
      SELECT Id, AccountId
      FROM Order
      WHERE TPB_State__c = 'KY' AND AccountId != NULL
      LIMIT 1
    ];
    //query TPB_State__c = 'NY' data
    Order objOrder2 = [
      SELECT Id, AccountId
      FROM Order
      WHERE TPB_State__c = 'NY' AND AccountId != NULL AND Status = 'Draft'
      LIMIT 1
    ];
    //saveOrder Method
    Map<String, String> mapResult = TPB_AddInventoryPurchasedForm.addScannedProduct(
      objOrder.Id,
      '09291934',
      'Purchase'
    );
    // complete Order
    Map<String, String> mapResultSave = TPB_AddInventoryPurchasedForm.completeOrder(
      objOrder2.Id
    );
    System.Test.stopTest();
    //assert map result.
    System.assertNotEquals(null, mapResult.get(RTN_KEY_RESULT), RTN_KEY_NG);
    //assert map result.
    System.assertNotEquals(null, mapResultSave.get(RTN_KEY_RESULT), RTN_KEY_NG);
  }
}