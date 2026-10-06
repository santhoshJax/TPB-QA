/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screen flow for Mass Prebook
 */
@isTest
public with sharing class TPB_MassPrebookController_Test {
  // map returns the result of calling
  private static final String RTN_KEY_OK = 'OK';
  private static final String RTN_KEY_NG = 'NG';
  private static final String RTN_KEY_RESULT = 'result';
  private static final String RTN_KEY_DATA = 'data';
  private static final Decimal AMOUNT_DATA = 100;
  public static String salesOrg = '0001';
  //Order  Van_Load recordType Id
  public static String orderMassPrebookRecordTypeId = TPB_TestFactory.orderMassPrebookRecordTypeId;
  //account Headquarter recordType Id
  public static String accountHeadquarterRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
    .get('Headquarter')
    .getRecordTypeId();
  public static String accountRetailerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
    .get('Retailer')
    .getRecordTypeId();

  //Wrapped in a map
  private static final String ACCOUNT_ORG_UNIT = 'mapAccOrgUnit';
  private static final String ACCOUNT_ORG_UNIT_QUANTITY = 'mapOrgUnitQuantity';

  //TPB_Promotion_Allocation_Item__c  recordType Id
  public static String proAllocationItemOrgRecordTypeId = TPB_TestFactory.proAllocationItemOrgRecordTypeId;
  public static String proAllocationItemStoreRecordTypeId = TPB_TestFactory.proAllocationItemStoreRecordTypeId;
  private static final String ORDER_ID = 'OrderId';
  public static String strDateThru = '2099-01-01';
  private static String strUser =
    'test' +
    '@test' +
    UserInfo.getOrganizationId() +
    '.org';

  //Interface transfer variable
  private static final String ORDER_TYPE = 'Promo';
  private static final String ORDER_TYPE_STOCK = 'Straight Stock';

  @testSetup
  static void setup() {
    //Declare variable
    String strShippingPostalCode = '20001';
    String strShippingStreet = 'U.S. Route 66 ';
    String strShippingCity = 'Baltimore';
    String strShippingCountry = 'US';
    String strShippingState = 'DC';
    //create Date Thru

    //create Org Unit for test.
    cgcloud__Org_Unit__c objOrgUnit = new cgcloud__Org_Unit__c();
    objOrgUnit.cgcloud__Org_Level__c = 'SalesRep';
    objOrgUnit.cgcloud__Org_Type__c = 'Sales';
    objOrgUnit.cgcloud__Sales_Org__c = '0001';
    objOrgUnit.Org_Unit_Main__c = true;
    objOrgUnit.Name = '208A01T';
    //insert lstOrgUnit data
    insert objOrgUnit;

    //create User
    User userOne = new User(
      Firstname = 'testUser1',
      Username = strUser,
      LastName = 'testUser1L',
      //Set Email
      Email = strUser,
      Alias = 'tsmone',
      TimeZoneSidKey = 'Asia/Shanghai',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'ISO-8859-1',
      //Set Profile
      ProfileId = UserInfo.getProfileId(),
      LanguageLocaleKey = 'en_US',
      TPB_Territory__c = '208A01T',
      TPB_Parent_Territory__c = 'Region 09'
    );
    TPB_AddUserMarketHandler.disableTriggerUsed = true;
    //insert userOne
    insert userOne;

    //System.runAs
    System.runAs(userOne) {
      TestDataFactory.ensureVisitTemplate('0001');
      //create Org Unit User data for test.
      cgcloud__Org_Unit_User__c objOrgUnitUser = new cgcloud__Org_Unit_User__c();
      objOrgUnitUser.cgcloud__User__c = userOne.Id;
      objOrgUnitUser.cgcloud__Org_Unit__c = objOrgUnit.Id;
      objOrgUnitUser.cgcloud__Main__c = true;
      objOrgUnitUser.cgcloud__Valid_From__c = System.Date.today().adddays(-100);
      objOrgUnitUser.cgcloud__Valid_Thru__c = System.Date.today().adddays(100);
      insert objOrgUnitUser;

      //create cgcloud__Account_Template__c data
      cgcloud__Account_Template__c accTemplate = new cgcloud__Account_Template__c(
        //set account template as active.
        cgcloud__Active__c = true,
        cgcloud__Available_Product_Level__c = 'Category;SubCategory;Brand;Flavor',
        cgcloud__Description_Language_1__c = 'Customer',
        cgcloud__Initial_Roles__c = 'customer;deliveryrecipient;order;payer;store',
        cgcloud__Sales_Org__c = '0001',
        Name = 'Customer'
      );
      // insert accTemplate
      insert accTemplate;

      //create  HQ Account for test.
      Account headquarter = new Account(
        ShippingCountry = strShippingCountry,
        ShippingLatitude = 38.90996,
        ShippingLongitude = -77.01893,
        ShippingPostalCode = strShippingPostalCode,
        ShippingState = strShippingState,
        ShippingStreet = strShippingStreet,
        ShippingCity = strShippingCity,
        OwnerId = userOne.Id,
        cgcloud__Account_Template__c = accTemplate.Id
      );
      headquarter.Name = 'Test Headquarter';
      headquarter.RecordTypeId = accountHeadquarterRecordTypeId;
      //insert headquarter
      insert headquarter;

      //create account list
      List<Account> lstInsertAccount = new List<Account>();
      //create  Retailer Account for test.
      Account retailer = new Account(
        ShippingCountry = strShippingCountry,
        ShippingLatitude = 38.90996,
        ShippingLongitude = -77.01893,
        ShippingPostalCode = strShippingPostalCode,
        ShippingState = strShippingState,
        ShippingStreet = strShippingStreet,
        cgcloud__Account_Template__c = accTemplate.Id,
        ShippingCity = strShippingCity
      );
      retailer.Name = 'Test Retailer';
      retailer.RecordTypeId = accountRetailerRecordTypeId;
      retailer.ParentId = headquarter.Id;
      //insert retailer
      lstInsertAccount.add(retailer);

      //create  Retailer Account for test.
      Account wholesalerAccount = new Account(
        ShippingCountry = strShippingCountry,
        ShippingLatitude = 38.90996,
        ShippingLongitude = -77.01893,
        ShippingPostalCode = strShippingPostalCode,
        ShippingState = strShippingState,
        ShippingStreet = strShippingStreet,
        ShippingCity = strShippingCity
      );
      wholesalerAccount.Name = 'Test wholesalerAccount';
      wholesalerAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Wholesaler')
        .getRecordTypeId();
      //insert wholesalerAccount
      insert wholesalerAccount;

      //create  Retailer Account for test.
      Account retailer2 = new Account(
        ShippingCountry = strShippingCountry,
        ShippingLatitude = 38.90996,
        ShippingLongitude = -77.01893,
        ShippingPostalCode = strShippingPostalCode,
        ShippingState = strShippingState,
        ShippingStreet = strShippingStreet,
        cgcloud__Account_Template__c = accTemplate.Id,
        ShippingCity = strShippingCity
      );
      retailer2.Name = 'Test Retailer2';
      retailer2.RecordTypeId = accountRetailerRecordTypeId;
      retailer2.ParentId = headquarter.Id;
      lstInsertAccount.add(retailer2);
      //insert lstInsertAccount

      //create  Retailer Account for test.
      Account retailer3 = new Account(
        ShippingCountry = strShippingCountry,
        ShippingLatitude = 38.90996,
        ShippingLongitude = -77.01893,
        ShippingPostalCode = strShippingPostalCode,
        ShippingState = strShippingState,
        ShippingStreet = strShippingStreet,
        cgcloud__Account_Template__c = accTemplate.Id,
        ShippingCity = strShippingCity
      );
      retailer3.Name = 'Test Retailer3';
      retailer3.RecordTypeId = accountRetailerRecordTypeId;
      retailer3.ParentId = headquarter.Id;
      lstInsertAccount.add(retailer3);
      //insert lstInsertAccount
      insert lstInsertAccount;

      //create Org Unit User data for test.
      List<cgcloud__Account_Org_Unit__c> lstOrgUnitAccount = new List<cgcloud__Account_Org_Unit__c>();
      cgcloud__Account_Org_Unit__c objOrgUnitAccount = new cgcloud__Account_Org_Unit__c();
      objOrgUnitAccount.cgcloud__Account__c = retailer.Id;
      objOrgUnitAccount.cgcloud__Org_Unit__c = objOrgUnit.Id;
      objOrgUnitAccount.cgcloud__Active__c = true;
      objOrgUnitAccount.cgcloud__Valid_From__c = System.Date.today()
        .adddays(-100);
      objOrgUnitAccount.cgcloud__Valid_Thru__c = System.Date.today()
        .adddays(100);
      lstOrgUnitAccount.add(objOrgUnitAccount);

      //create cgcloud__Account_Org_Unit__c data
      cgcloud__Account_Org_Unit__c objOrgUnitAccount2 = new cgcloud__Account_Org_Unit__c();
      objOrgUnitAccount2.cgcloud__Account__c = retailer2.Id;
      objOrgUnitAccount2.cgcloud__Org_Unit__c = objOrgUnit.Id;
      objOrgUnitAccount2.cgcloud__Active__c = true;
      objOrgUnitAccount2.cgcloud__Valid_From__c = System.Date.today()
        .adddays(-100);
      objOrgUnitAccount2.cgcloud__Valid_Thru__c = System.Date.today()
        .adddays(100);
      lstOrgUnitAccount.add(objOrgUnitAccount2);

      //create cgcloud__Account_Org_Unit__c data
      cgcloud__Account_Org_Unit__c objOrgUnitAccount3 = new cgcloud__Account_Org_Unit__c();
      objOrgUnitAccount3.cgcloud__Account__c = retailer3.Id;
      objOrgUnitAccount3.cgcloud__Org_Unit__c = objOrgUnit.Id;
      objOrgUnitAccount3.cgcloud__Active__c = true;
      objOrgUnitAccount3.cgcloud__Valid_From__c = System.Date.today()
        .adddays(-100);
      objOrgUnitAccount3.cgcloud__Valid_Thru__c = System.Date.today()
        .adddays(100);
      lstOrgUnitAccount.add(objOrgUnitAccount3);

      insert lstOrgUnitAccount;

      //create visit for test.
      Visit objVisit = TPB_TestFactory.createVisit(retailer);

      //create  Related_Account data
      Related_Account__c objRelatedAccount = new Related_Account__c();
      objRelatedAccount.Retailer__c = retailer.Id;
      objRelatedAccount.Wholesaler__c = wholesalerAccount.Id;
      objRelatedAccount.TPB_MSA_Wholesaler__c = true;
      //insert objRelatedAccount
      insert objRelatedAccount;

      //create Product2 data
      Product2 prod = TPB_TestFactory.createProduct();
      prod.NTC_Item_Classification__c = ORDER_TYPE;
      //update prod
      update prod;

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

      // createPricebookEntry
      TPB_TestFactory.createPricebookEntry(prod.Id);

      //create  Promotion_Waves data
      List<TPB_Promotion_Waves__c> lstWave = new List<TPB_Promotion_Waves__c>();
      TPB_Promotion_Waves__c objWave = new TPB_Promotion_Waves__c();
      objWave.TPB_Wave_Period_Date_From__c = System.Date.today().adddays(100);
      objWave.TPB_Wave_Period_Date_Thru__c = Date.valueOf(strDateThru);
      objWave.TPB_Order_Entry_Date_From__c = System.Date.today().adddays(-5);
      objWave.TPB_Order_Entry_Date_Thru__c = System.Date.today().adddays(80);
      //add objWave
      lstWave.add(objWave);

      //create TPB_Promotion_Waves__c data
      TPB_Promotion_Waves__c objWave2 = new TPB_Promotion_Waves__c();
      objWave2.TPB_Wave_Period_Date_From__c = System.Date.today().adddays(50);
      objWave2.TPB_Wave_Period_Date_Thru__c = Date.valueOf(strDateThru);
      objWave2.TPB_Order_Entry_Date_From__c = System.Date.today().adddays(-5);
      objWave2.TPB_Order_Entry_Date_Thru__c = System.Date.today().adddays(30);
      //add objWave2
      lstWave.add(objWave2);

      //insert objWave
      insert lstWave;

      //create TPB_Promotion_Allocation_Item__c data
      List<TPB_Promotion_Allocation_Item__c> lstTPBPromotionAllocationsItem = new List<TPB_Promotion_Allocation_Item__c>();
      TPB_Promotion_Allocation_Item__c objPromotionAllocationsItem = new TPB_Promotion_Allocation_Item__c();
      objPromotionAllocationsItem.TPB_Max_Quantity__c = 100;
      objPromotionAllocationsItem.TPB_Product__c = prod.Id;
      objPromotionAllocationsItem.TPB_Quantity_Planned__c = 100;
      objPromotionAllocationsItem.TPB_Account__c = retailer.Id;
      objPromotionAllocationsItem.TPB_Promotion_Waves__c = objWave.Id;
      objPromotionAllocationsItem.RecordTypeId = proAllocationItemStoreRecordTypeId;
      //insert objPromotionAllocationsItem
      lstTPBPromotionAllocationsItem.add(objPromotionAllocationsItem);

      //create  Promotion_Allocation_Item data
      TPB_Promotion_Allocation_Item__c objPromotionAllocationsItem2 = new TPB_Promotion_Allocation_Item__c();
      objPromotionAllocationsItem2.TPB_Max_Quantity__c = 100;
      objPromotionAllocationsItem2.TPB_Product__c = prod.Id;
      objPromotionAllocationsItem2.TPB_Quantity_Planned__c = 100;
      objPromotionAllocationsItem2.TPB_Account__c = retailer2.Id;
      objPromotionAllocationsItem2.TPB_Promotion_Waves__c = objWave2.Id;
      objPromotionAllocationsItem2.RecordTypeId = proAllocationItemStoreRecordTypeId;
      //insert objPromotionAllocationsItem2
      lstTPBPromotionAllocationsItem.add(objPromotionAllocationsItem2);

      //create  Promotion_Allocation_Item data
      TPB_Promotion_Allocation_Item__c objPromotionAllocationsItem3 = new TPB_Promotion_Allocation_Item__c();
      objPromotionAllocationsItem3.TPB_Max_Quantity__c = 100;
      objPromotionAllocationsItem3.TPB_Product__c = prod.Id;
      objPromotionAllocationsItem3.TPB_Quantity_Planned__c = 100;
      objPromotionAllocationsItem3.TPB_Account__c = retailer3.Id;
      objPromotionAllocationsItem3.TPB_Promotion_Waves__c = objWave.Id;
      objPromotionAllocationsItem3.RecordTypeId = proAllocationItemStoreRecordTypeId;
      //insert objPromotionAllocationsItem3
      lstTPBPromotionAllocationsItem.add(objPromotionAllocationsItem3);

      //create  Promotion_Allocation_Item data
      TPB_Promotion_Allocation_Item__c objPromotionAllocationsItem4 = new TPB_Promotion_Allocation_Item__c();
      objPromotionAllocationsItem4.TPB_Total_Max_Allocation__c = 100;
      objPromotionAllocationsItem4.TPB_Org_Unit__c = objOrgUnit.Id;
      objPromotionAllocationsItem4.TPB_Product__c = prod.Id;
      objPromotionAllocationsItem4.TPB_Promotion_Waves__c = objWave.Id;
      objPromotionAllocationsItem4.RecordTypeId = proAllocationItemOrgRecordTypeId;
      //insert objPromotionAllocationsItem4
      lstTPBPromotionAllocationsItem.add(objPromotionAllocationsItem4);

      //insert lstTPBPromotionAllocationsItem
      insert lstTPBPromotionAllocationsItem;

      //create Order for test.
      cgcloud__Order__c objOrder = TPB_TestFactory.createAdOrder(objVisit);

      //create Order Item for test.
      cgcloud__Order_Item__c objOrderItem = new cgcloud__Order_Item__c();
      objOrderItem.cgcloud__Special_Price__c = 12;
      objOrderItem.cgcloud__Discount__c = 123;
      objOrderItem.cgcloud__Order__c = objOrder.id;
      objOrderItem.cgcloud__Quantity__c = 12;
      objOrderItem.cgcloud__Product__c = prod.Id;
      objOrderItem.cgcloud__UoM__c = 'SalesUnit';
      objOrderItem.Reimbursable_Amt__c = 12;
      objOrderItem.TPB_Promotion_Waves__c = objWave.Id;
      objOrderItem.cgcloud__Pricing_Info_1__c = 123;
      //insert objOrderItem
      insert objOrderItem;

      //update phase 'Released'
      objOrder.cgcloud__Phase__c = 'Released';
      objOrder.cgcloud__Release_Time__c = Date.today();
      objOrder.cgcloud__Order_Account__c = retailer.Id;
      objOrder.cgcloud__Delivery_Recipient__c = retailer.Id;
      objOrder.cgcloud__Accountable__c = userOne.Id;
      //update objOrder
      update objOrder;
    }
  }

  @isTest
  static void testInitDataResult() {
    //query User data
    User objUser = [SELECT Id FROM User WHERE Username = :strUser];

    // Test. startTest
    System.Test.startTest();
    System.runAs(objUser) {
      //query Product2 data.
      Product2 objProduct2 = [
        SELECT Id, Name
        FROM Product2
        WHERE Name = 'NICOTINE CHEW - TPR'
        LIMIT 1
      ];

      //query HQ Account data.
      Account objAcc = [
        SELECT
          Id,
          Name,
          Account_Number_old__c,
          ParentId,
          Parent.Name,
          Parent.ShippingStreet,
          Parent.ShippingCity,
          Parent.ShippingState,
          Parent.ShippingAddress,
          Parent.Account_Number_old__c,
          Parent.cgcloud__Account_Number__c
        FROM Account
        WHERE
          Name = 'Test Headquarter'
          AND RecordTypeId = :accountHeadquarterRecordTypeId
          AND OwnerId = :objUser.Id
        LIMIT 1
      ];

      //TPB_AddInventoryPurchasedFormService.strPriceBook
      TPB_AddInventoryPurchasedFormService.strPriceBook = null;
      //TPB_MassPrebookController.boolRunTest
      TPB_MassPrebookController.boolRunTest = true;
      //Test getAllWholesalerAccount method
      String strWave =
        String.valueOf(System.Date.today().adddays(100)) +
        '=' +
        strDateThru +
        ',' +
        String.valueOf(System.Date.today().adddays(-5)) +
        '=' +
        String.valueOf(System.Date.today().adddays(80));

      //Promo product getAllWholesalerAccount
      Map<String, Object> mapResultPromo = TPB_MassPrebookController.getAllWholesalerAccount(
        objAcc.Id,
        objProduct2.Id,
        String.valueOf(System.Date.today().adddays(100)),
        ORDER_TYPE,
        strWave
      );
      //assert Equals
      System.assertEquals(RTN_KEY_OK, mapResultPromo.get(RTN_KEY_RESULT), '');

      //Test searchDataResult method
      Map<String, Object> mapResultSearchDataResult = TPB_MassPrebookController.searchDataResult(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        objAcc.Id
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultSearchDataResult.get(RTN_KEY_RESULT),
        ''
      );

      //Test getOrderRecordType method
      Map<String, Object> mapResultGetOrderRecordType = TPB_MassPrebookController.getOrderRecordType(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultGetOrderRecordType.get(RTN_KEY_RESULT),
        ''
      );

      //Test getOrderData method
      Map<String, Object> mapResultGetOrderData = TPB_MassPrebookController.getOrderData(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultGetOrderData.get(RTN_KEY_RESULT),
        ''
      );

      //Test validationsPromotion method
      Map<String, Object> mapResultValidationsPromotion = TPB_MassPrebookController.validationsPromotion(
        objProduct2.Id,
        objAcc.Id
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultValidationsPromotion.get(RTN_KEY_RESULT),
        ''
      );

      //get All Wholesaler Account
      Map<String, Account> mapWholesalerAccount = TPB_MassPrebookService.getAllWholesalerAccount(
        objAcc.Id
      );
      //get all Promotion Allocation Item data
      Map<String, TPB_Promotion_Allocation_Item__c> mapProductPromotionAllocationItem = TPB_MassPrebookService.getAllPromotionAllocationItem(
        objAcc.Id,
        objProduct2.Id,
        strWave,
        new Set<String>()
      );

      //create OrderItem Data
      Map<String, OrderItem> mapAccOrderItem = TPB_MassPrebookController.createOrderItemData(
        objProduct2.Id,
        mapWholesalerAccount.KeySet(),
        mapProductPromotionAllocationItem,
        ORDER_TYPE
      );
      //get Wholesaler Account
      Map<String, TPB_MassPrebookWrapper.WholesalerAccount> mapRetailerAccount = TPB_MassPrebookService.getWholesalerAccount(
        objAcc.Id
      );

      //data Encapsulation
      List<TPB_MassPrebookWrapper.MassPrebookDetail> lstMassPrebookWrapper = TPB_MassPrebookController.dataEncapsulation(
        mapAccOrderItem,
        mapRetailerAccount,
        objAcc.Id,
        mapWholesalerAccount
      );

      //Test updateOrderItems method
      Map<String, Object> mapResultUpdateOrderItems = TPB_MassPrebookController.updateOrderItems(
        lstMassPrebookWrapper,
        ORDER_TYPE,
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultUpdateOrderItems.get(RTN_KEY_RESULT),
        ''
      );

      //Encapsulation into data call methods
      Map<String, Object> mapResultVerify = new Map<String, Object>();
      //add OrderId value
      mapResultVerify.put(
        'OrderId',
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //add OrderType value
      mapResultVerify.put('OrderType', ORDER_TYPE);
      mapResultVerify.put(
        ACCOUNT_ORG_UNIT,
        new Map<Object, Object>{ ACCOUNT_ORG_UNIT => ACCOUNT_ORG_UNIT }
      );
      mapResultVerify.put(
        ACCOUNT_ORG_UNIT_QUANTITY,
        new Map<Object, Object>{ ACCOUNT_ORG_UNIT_QUANTITY => '0' }
      );
      //Test saveOrderByFrame method
      Map<String, Object> mapResultSaveOrderByFrame = TPB_MassPrebookController.saveOrderByFrame(
        2,
        2,
        lstMassPrebookWrapper,
        mapResultVerify
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultSaveOrderByFrame.get(RTN_KEY_RESULT),
        ''
      );

      //Test completeOrder method
      Map<String, Object> mapResultPromoCompleteOrder = TPB_MassPrebookController.completeOrder(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        objAcc.Id,
        ORDER_TYPE
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultPromoCompleteOrder.get(RTN_KEY_RESULT),
        ''
      );

      //Test searchDataResult method
      Map<String, Object> mapResultPromoSearchDataResult = TPB_MassPrebookController.searchDataResult(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        objAcc.Id
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultPromoSearchDataResult.get(RTN_KEY_RESULT),
        ''
      );

      //Test cancelOrderData method
      Map<String, Object> mapResultPromoCancelOrderData = TPB_MassPrebookController.cancelOrderData(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        ORDER_TYPE,
        strWave
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultPromoCancelOrderData.get(RTN_KEY_RESULT),
        ''
      );
    }
    //Test stopTest
    System.Test.stopTest();
  }

  @isTest
  static void testInitDataResult2() {
    //query User data
    User objUser = [SELECT Id FROM User WHERE Username = :strUser];

    //Test startTest
    System.Test.startTest();
    //runAs
    System.runAs(objUser) {
      //query Product2 data.
      Product2 objProduct2 = [
        SELECT Id, Name
        FROM Product2
        WHERE Name = 'NICOTINE CHEW - TPR'
        LIMIT 1
      ];

      //query HQ Account data.
      Account objAcc = [
        SELECT
          Id,
          Name,
          Account_Number_old__c,
          ParentId,
          Parent.Name,
          Parent.ShippingStreet,
          Parent.ShippingCity,
          Parent.ShippingState,
          Parent.ShippingAddress,
          Parent.Account_Number_old__c,
          Parent.cgcloud__Account_Number__c
        FROM Account
        WHERE
          Name = 'Test Headquarter'
          AND RecordTypeId = :accountHeadquarterRecordTypeId
          AND OwnerId = :objUser.Id
        LIMIT 1
      ];

      //query HQ Account data.
      Account objAccRetailer = [
        SELECT Id
        FROM Account
        WHERE
          Name = 'Test Retailer'
          AND RecordTypeId = :accountRetailerRecordTypeId
        LIMIT 1
      ];

      //TPB_AddInventoryPurchasedFormService.strPriceBook
      TPB_AddInventoryPurchasedFormService.strPriceBook = null;
      //TPB_MassPrebookController.boolRunTest
      TPB_MassPrebookController.boolRunTest = true;
      //Test getAllWholesalerAccount method
      String strWave =
        String.valueOf(System.Date.today().adddays(100)) +
        '=' +
        strDateThru +
        ',' +
        String.valueOf(System.Date.today().adddays(-5)) +
        '=' +
        String.valueOf(System.Date.today().adddays(80));
      //Promo product getAllWholesalerAccount
      Map<String, Object> mapResultPromo = TPB_MassPrebookController.getAllWholesalerAccount(
        objAcc.Id,
        objProduct2.Id,
        String.valueOf(System.Date.today().adddays(100)),
        ORDER_TYPE_STOCK,
        strWave
      );
      //assert Equals
      System.assertEquals(RTN_KEY_OK, mapResultPromo.get(RTN_KEY_RESULT), '');

      //Test searchDataResult method
      Map<String, Object> mapResultSearchDataResult = TPB_MassPrebookController.searchDataResult(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        objAcc.Id
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultSearchDataResult.get(RTN_KEY_RESULT),
        ''
      );

      //Test getOrderRecordType method
      Map<String, Object> mapResultGetOrderRecordType = TPB_MassPrebookController.getOrderRecordType(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultGetOrderRecordType.get(RTN_KEY_RESULT),
        ''
      );

      //Test getOrderData method
      Map<String, Object> mapResultGetOrderData = TPB_MassPrebookController.getOrderData(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultGetOrderData.get(RTN_KEY_RESULT),
        ''
      );

      //Test validationsPromotion method
      Map<String, Object> mapResultValidationsPromotion = TPB_MassPrebookController.validationsPromotion(
        objProduct2.Id,
        objAcc.Id
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultValidationsPromotion.get(RTN_KEY_RESULT),
        ''
      );

      //get All Wholesaler Account
      Map<String, Account> mapWholesalerAccount = TPB_MassPrebookService.getAllWholesalerAccount(
        objAcc.Id
      );
      //get all Promotion Allocation Item data
      Map<String, TPB_Promotion_Allocation_Item__c> mapProductPromotionAllocationItem = TPB_MassPrebookService.getAllPromotionAllocationItem(
        objAcc.Id,
        objProduct2.Id,
        strWave,
        new Set<String>()
      );

      //create OrderItem Data
      Map<String, OrderItem> mapAccOrderItem = TPB_MassPrebookController.createOrderItemData(
        objProduct2.Id,
        mapWholesalerAccount.KeySet(),
        mapProductPromotionAllocationItem,
        ORDER_TYPE_STOCK
      );
      //get Wholesaler Account
      Map<String, TPB_MassPrebookWrapper.WholesalerAccount> mapRetailerAccount = TPB_MassPrebookService.getWholesalerAccount(
        objAcc.Id
      );

      //data Encapsulation
      List<TPB_MassPrebookWrapper.MassPrebookDetail> lstMassPrebookWrapper = TPB_MassPrebookController.dataEncapsulation(
        mapAccOrderItem,
        mapRetailerAccount,
        objAcc.Id,
        mapWholesalerAccount
      );

      //Test updateOrderItems method
      Map<String, Object> mapResultUpdateOrderItems = TPB_MassPrebookController.updateOrderItems(
        lstMassPrebookWrapper,
        ORDER_TYPE_STOCK,
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultUpdateOrderItems.get(RTN_KEY_RESULT),
        ''
      );

      //Encapsulation into data call methods
      Map<String, Object> mapResultVerify = new Map<String, Object>();
      //add OrderId value
      mapResultVerify.put(
        'OrderId',
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID))
      );
      //add OrderType value
      mapResultVerify.put('OrderType', ORDER_TYPE_STOCK);
      mapResultVerify.put(
        ACCOUNT_ORG_UNIT,
        new Map<Object, Object>{ ACCOUNT_ORG_UNIT => ACCOUNT_ORG_UNIT }
      );
      mapResultVerify.put(
        ACCOUNT_ORG_UNIT_QUANTITY,
        new Map<Object, Object>{ ACCOUNT_ORG_UNIT_QUANTITY => '0' }
      );
      //Test saveOrderByFrame method
      Map<String, Object> mapResultSaveOrderByFrame = TPB_MassPrebookController.saveOrderByFrame(
        2,
        2,
        lstMassPrebookWrapper,
        mapResultVerify
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultSaveOrderByFrame.get(RTN_KEY_RESULT),
        ''
      );

      //Test completeOrder method
      Map<String, Object> mapResultPromoCompleteOrder = TPB_MassPrebookController.completeOrder(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        objAcc.Id,
        ORDER_TYPE_STOCK
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultPromoCompleteOrder.get(RTN_KEY_RESULT),
        ''
      );

      //Test searchDataResult method
      Map<String, Object> mapResultPromoSearchDataResult = TPB_MassPrebookController.searchDataResult(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        objAcc.Id
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultPromoSearchDataResult.get(RTN_KEY_RESULT),
        ''
      );

      //Test cancelOrderData method
      Map<String, Object> mapResultPromoCancelOrderData = TPB_MassPrebookController.cancelOrderData(
        String.valueOf(mapResultPromo.get(RTN_KEY_DATA + ORDER_ID)),
        ORDER_TYPE_STOCK,
        strWave
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapResultPromoCancelOrderData.get(RTN_KEY_RESULT),
        ''
      );
      //getAllOrderItemData
      TPB_MassPrebookService.getAllOrderItemData(objAcc.Id, objProduct2.Id);
      //getRelatedAccountsByRetailerId
      TPB_MassPrebookController.getRelatedAccountsByRetailerId(
        objAccRetailer.Id
      );
    }
    //Test.stopTest
    System.Test.stopTest();
  }

  @isTest
  static void testInitDataResult3() {
    //query user data.
    User objUser = [SELECT Id FROM User WHERE Username = :strUser];

    //searchChainOrgUnit
    TPB_MassPrebookControllerUtility.searchChainOrgUnit(
      new Set<String>{ objUser.Id }
    );
    //query cgcloud__Order__c data
    List<cgcloud__Order__c> lstOrder = [
      SELECT Id
      FROM cgcloud__Order__c
      WHERE cgcloud__Phase__c = 'Released'
    ];
    //add order id
    List<String> lstString = new List<String>();
    for (cgcloud__Order__c obj : lstOrder) {
      lstString.add(obj.Id);
    }
    //Test.startTest
    System.Test.startTest();
    //Test.runAs
    System.runAs(objUser) {
      //create test inner object
      TPB_MassPrebookAdOrderFlow.InputParameters testObj = new TPB_MassPrebookAdOrderFlow.InputParameters();
      testObj.lstAdvancedOrder = lstString;
      //Add object to list
      List<TPB_MassPrebookAdOrderFlow.InputParameters> testLst = new List<TPB_MassPrebookAdOrderFlow.InputParameters>();
      testLst.add(testObj);
      //Test promotionAllocationItem method
      TPB_MassPrebookAdOrderFlow.promotionAllocationItem(testLst);

      //query update org uint Promotion_Allocation_Item data
      List<TPB_Promotion_Allocation_Item__c> lstPromotionAllocationItem = [
        SELECT Id, TPB_Total_QTY_Ordered__c, TPB_Org_Unit__c
        FROM TPB_Promotion_Allocation_Item__c
        WHERE
          TPB_Org_Unit__c != NULL
          AND TPB_Product__c != NULL
          AND TPB_Promotion_Waves__c != NULL
      ];
      //assert Equals
      System.assertEquals(
        24,
        lstPromotionAllocationItem[0].TPB_Total_QTY_Ordered__c,
        0
      );
    }
    //Test.stopTest
    System.Test.stopTest();
  }
}