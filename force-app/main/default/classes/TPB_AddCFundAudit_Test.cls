/**
 * @author Mi Li
 * @date 5/22/2023
 * @description CON0001729-1161 RSM C-Fund Audit (TSM View)
 */
@isTest
private class TPB_AddCFundAudit_Test {
  // map returns the result of calling
  private static final String RTN_KEY_OK = 'OK';
  private static final String RTN_KEY_NG = 'NG';
  private static final String RTN_KEY_RESULT = 'result';
  private static final String RTN_KEY_DATA = 'data';
  private static final Decimal AMOUNT_DATA = 100;
  public static String salesOrg = '0001';
  private static String strUser =
    'test' +
    '@test' +
    UserInfo.getOrganizationId() +
    '.org';

  @testSetup
  static void setup() {
    //create Org Unit for test.
    List<cgcloud__Org_Unit__c> lstOrgUnit = new List<cgcloud__Org_Unit__c>();
    cgcloud__Org_Unit__c objOrgUnitRegion = new cgcloud__Org_Unit__c();
    objOrgUnitRegion.cgcloud__Org_Level__c = 'SalesRep';
    objOrgUnitRegion.cgcloud__Org_Type__c = 'Sales';
    objOrgUnitRegion.cgcloud__Sales_Org__c = '0001';
    objOrgUnitRegion.Org_Unit_Main__c = true;
    objOrgUnitRegion.Name = 'Region 09';
    lstOrgUnit.add(objOrgUnitRegion);

    //create Org Unit for test.
    cgcloud__Org_Unit__c objOrgUnit = new cgcloud__Org_Unit__c();
    objOrgUnit.cgcloud__Org_Level__c = 'SalesRep';
    objOrgUnit.cgcloud__Org_Type__c = 'Sales';
    objOrgUnit.cgcloud__Sales_Org__c = '0001';
    objOrgUnit.Org_Unit_Main__c = true;
    objOrgUnit.Name = '109A17T';
    lstOrgUnit.add(objOrgUnit);

    //insert lstOrgUnit data
    insert lstOrgUnit;

    //create Account for test.
    Account accObj = TPB_TestFactory.createAccount();

    //create Product Template
    Id tempId = TPB_TestFactory.createProductTemplate();
    //create Product2 for test.
    Product2 prod = TPB_TestFactory.createProduct('Test Product2', tempId);
    Product2 prod2 = TPB_TestFactory.createProduct('Test Product', tempId);

    //create Org Unit User for test.
    cgcloud__Org_Unit_User__c objOrgUnitUser = new cgcloud__Org_Unit_User__c();
    objOrgUnitUser.cgcloud__Org_Unit__c = objOrgUnitRegion.Id;
    objOrgUnitUser.cgcloud__User__c = UserInfo.getUserId();
    insert objOrgUnitUser;

    //create Unit of Measure for test.
    cgcloud__Unit_of_Measure__c objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
    objUnitOfMeasure.cgcloud__GTIN__c = '09291934';
    objUnitOfMeasure.cgcloud__Product__c = prod.Id;
    objUnitOfMeasure.cgcloud__Unit_Type__c = 'SalesUnit';
    insert objUnitOfMeasure;

    //create visit for test.
    Visit objVisit = TPB_TestFactory.createVisit(accObj);
    // create user
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

    //create Inventory Control Template
    TPB_TestFactory.createInventoryControlTemplate();
    //create Inventory Transaction Template
    TPB_TestFactory.createInventoryTransactionTemplate();

    System.runAs(userOne) {
      //create Order for test.
      cgcloud__Order__c objOrder = TPB_TestFactory.createAdOrder(objVisit);
      objOrder.cgcloud__Phase__c = 'Released';
      objOrder.cgcloud__Release_Time__c = Date.today();
      objOrder.cgcloud__Order_Account__c = accObj.id;
      objOrder.cgcloud__Delivery_Recipient__c = accObj.id;
      objOrder.cgcloud__Accountable__c = userOne.Id;
      //update objOrder
      update objOrder;

      //create Order Item for test.
      cgcloud__Order_Item__c objOrderItem = new cgcloud__Order_Item__c();
      objOrderItem.cgcloud__Special_Price__c = 12;
      objOrderItem.cgcloud__Discount__c = 123;
      objOrderItem.cgcloud__Order__c = objOrder.id;
      objOrderItem.cgcloud__Value__c = 12;
      objOrderItem.Reimbursable_Amt__c = 12;
      objOrderItem.cgcloud__Pricing_Info_1__c = 123;
      //insert objOrderItem
      insert objOrderItem;
      //create Inventory
      TPB_TestFactory.createInventory(userOne.Id, prod2.Id);
    }
  }

  @isTest
  static void testInitDataResult() {
    //query user data.
    User objUser = [SELECT Id FROM User WHERE Username = :strUser];
    //query Product2 data.
    Product2 objProduct2 = [
      SELECT Id, Name
      FROM Product2
      WHERE Name = 'Test Product'
      LIMIT 1
    ];
    System.Test.startTest();
    System.runAs(objUser) {
      //CFundAudit Internal Classes
      TPB_AddCFundAuditWrapper.CFundAudit cFundAuditClass = new TPB_AddCFundAuditWrapper.CFundAudit();
      cFundAuditClass.recordId = null;
      cFundAuditClass.actualCashOnHand = AMOUNT_DATA;
      cFundAuditClass.bankBalance = AMOUNT_DATA;
      cFundAuditClass.totalAccountableCFund = AMOUNT_DATA;
      cFundAuditClass.promoValue = AMOUNT_DATA;
      cFundAuditClass.pendingReimbursements = AMOUNT_DATA;

      //calling saveAndSubmit method for test.
      Map<String, String> mapInsertResult = TPB_AddCFundAudit.saveAndSubmit(
        cFundAuditClass
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapInsertResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );

      //Assignment id
      cFundAuditClass.recordId = mapInsertResult.get(RTN_KEY_DATA);

      //calling saveAndSubmit method for test.
      Map<String, String> mapUpdateResult = TPB_AddCFundAudit.saveAndSubmit(
        cFundAuditClass
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapUpdateResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );

      //calling addScannedProduct method for test.
      Map<String, Object> mapAddProductResult = TPB_AddCFundAudit.addScannedProduct(
        mapInsertResult.get(RTN_KEY_DATA),
        '09291934',
        'NY'
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapAddProductResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );

      //get TPB_CFund_Audit_Product__c data
      TPB_CFund_Audit_Product__c objAuditProduct = (TPB_CFund_Audit_Product__c) mapAddProductResult.get(
        RTN_KEY_DATA
      );

      //update TPB_CFund_Audit_Product__c data
      TPB_CFund_Audit_Product__c objAuditProduct2 = new TPB_CFund_Audit_Product__c();
      objAuditProduct2.id = objAuditProduct.Id;
      objAuditProduct2.TPB_Expected_Quantity__c = 1200;
      //update objAuditProduct2
      update objAuditProduct2;

      //update Approval status
      TPB_CFund_Audit__c objCFundAudit = new TPB_CFund_Audit__c();
      objCFundAudit.Id = mapInsertResult.get(RTN_KEY_DATA);
      objCFundAudit.TPB_Status__c = 'Approval In Progress';
      //update objCFundAudit
      update objCFundAudit;

      //update Approval status
      objCFundAudit.TPB_Status__c = 'Approved';
      update objCFundAudit;

      // Internal Classes
      TPB_AddCFundAuditServiceWrapper.CFundAuditProduct objCFundAuditProduct = new TPB_AddCFundAuditServiceWrapper.CFundAuditProduct();
      objCFundAuditProduct.id = objAuditProduct.Id;
      objCFundAuditProduct.auditId = String.valueOf(
        mapInsertResult.get(RTN_KEY_DATA)
      );
      //Assignment productId
      objCFundAuditProduct.productId = objProduct2.Id;
      //Assignment productName
      objCFundAuditProduct.productName = objProduct2.Name;
      //Assignment unitPrice
      objCFundAuditProduct.unitPrice = 100;
      //Assignment quantity
      objCFundAuditProduct.quantity = 1;
      //Assignment totalAmount
      objCFundAuditProduct.totalAmount = 100;
      //Assignment expectedQuantity
      objCFundAuditProduct.expectedQuantity = 100;

      //calling updateCFundAuditProduct method for test.
      Map<String, Object> mapCFundAuditProductResult = TPB_AddCFundAuditService.updateCFundAuditProduct(
        new List<TPB_AddCFundAuditServiceWrapper.CFundAuditProduct>{
          objCFundAuditProduct
        },
        'NY'
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapCFundAuditProductResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );

      //calling deleteCFundAuditProduct method for test.
      Map<String, Object> mapDeleteProductResult = TPB_AddCFundAuditService.deleteCFundAuditProduct(
        objAuditProduct.id
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapDeleteProductResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );
    }
    System.Test.stopTest();
  }

  @isTest
  static void testInitDataResult2() {
    //query user data
    User objUser = [SELECT Id FROM User WHERE Username = :strUser];
    System.Test.startTest();
    System.runAs(objUser) {
      //CFundAudit Internal Classes
      TPB_AddCFundAuditWrapper.CFundAudit cFundAuditClass = new TPB_AddCFundAuditWrapper.CFundAudit();
      cFundAuditClass.recordId = null;
      cFundAuditClass.actualCashOnHand = AMOUNT_DATA;
      cFundAuditClass.bankBalance = AMOUNT_DATA;
      cFundAuditClass.totalAccountableCFund = AMOUNT_DATA;
      cFundAuditClass.promoValue = AMOUNT_DATA;
      cFundAuditClass.pendingReimbursements = AMOUNT_DATA;

      //calling saveAndSubmit method for test.
      Map<String, String> mapInsertResult = TPB_AddCFundAudit.saveAndSubmit(
        cFundAuditClass
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapInsertResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );
      cFundAuditClass.recordId = mapInsertResult.get(RTN_KEY_DATA);

      //calling init method for test.
      Map<String, Object> mapInitResult = TPB_AddCFundAudit.init(
        mapInsertResult.get(RTN_KEY_DATA)
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapInitResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );

      //calling getCFundAuditProducts method for test.
      Map<String, Object> mapGetCFundAuditProductResult = TPB_AddCFundAuditService.getCFundAuditProducts(
        mapInsertResult.get(RTN_KEY_DATA),
        'NY'
      );
      //assert Equals
      System.assertEquals(
        RTN_KEY_OK,
        mapGetCFundAuditProductResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );
    }
    System.Test.stopTest();
  }

  @isTest
  static void testSaveAndSubmitResult() {
    //query user data
    User objUser = [SELECT Id FROM User WHERE Username = :strUser];
    System.Test.startTest();
    System.runAs(objUser) {
      //CFundAudit Internal Classes
      TPB_AddCFundAuditWrapper.CFundAudit cFundAuditClass = new TPB_AddCFundAuditWrapper.CFundAudit();
      cFundAuditClass.recordId = null;
      cFundAuditClass.actualCashOnHand = AMOUNT_DATA;
      cFundAuditClass.bankBalance = AMOUNT_DATA;
      cFundAuditClass.totalAccountableCFund = AMOUNT_DATA;
      cFundAuditClass.promoValue = AMOUNT_DATA;
      cFundAuditClass.pendingReimbursements = AMOUNT_DATA;

      //calling init method for test.
      Map<String, String> mapInsertResult = TPB_AddCFundAudit.saveAndSubmit(
        cFundAuditClass
      );
      cFundAuditClass.recordId = mapInsertResult.get(RTN_KEY_DATA);

      //calling addScannedProduct method for test.
      Map<String, Object> mapAddProductResult = TPB_AddCFundAudit.addScannedProduct(
        mapInsertResult.get(RTN_KEY_DATA),
        '09291934',
        'NY'
      );

      TPB_CFund_Audit_Product__c objAuditProduct = (TPB_CFund_Audit_Product__c) mapAddProductResult.get(
        RTN_KEY_DATA
      );
      objAuditProduct.TPB_Unit_Price__c = 122;
      objAuditProduct.TPB_Quantity__c = 1;
      objAuditProduct.TPB_Expected_Quantity__c = 1200;
      //update objAuditProduct
      update objAuditProduct;

      //submitAndProcessApprovalRequest
      Map<String, String> mapSubmitResult = TPB_AddCFundAudit.submitAndProcessApprovalRequest(
        cFundAuditClass
      );

      //searchInventoryUserState
      Map<String, Object> mapUserStateResult = TPB_AddCFundAuditService.searchInventoryUserState();
      //assert map result.
      System.assertEquals(
        RTN_KEY_OK,
        mapInsertResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );
      //assert map result.
      System.assertEquals(
        RTN_KEY_OK,
        mapSubmitResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );
      //assert map result.
      System.assertEquals(
        RTN_KEY_OK,
        mapUserStateResult.get(RTN_KEY_RESULT),
        RTN_KEY_NG
      );
    }
    System.Test.stopTest();
  }
}