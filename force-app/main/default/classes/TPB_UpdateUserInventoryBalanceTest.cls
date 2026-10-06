/**
 * @author Mi Li
 * @date 5/31/2023
 * @description CON0001729-1187  Inventory Balance & Current C-Fund Balance Logic
 */
@isTest
private class TPB_UpdateUserInventoryBalanceTest {
  //Defining static constants
  public static String salesOrg = '0001';
  public static String strUserName =
    'test' +
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

    //create Account for test.
    Account accObj = TPB_TestFactory.createAccount();
    //create Vsisit for test.
    Visit objVisit = TPB_TestFactory.createVisit(accObj);

    //create User data
    User userOne = new User(
      Firstname = 'test',
      Username = strUserName,
      LastName = 'Test',
      Email = strUserName,
      Alias = 'tsmtwo',
      TimeZoneSidKey = 'Asia/Shanghai',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'ISO-8859-1',
      ProfileId = profileOne.Id,
      TPB_Territory__c = '208A01T',
      LanguageLocaleKey = 'en_US',
      Need_CG_Cloud_Setup__c = false
    );

    //insert userOne
    insert userOne;

    //create Order for test.
    cgcloud__Order__c objOrder = TPB_TestFactory.createAdOrder(objVisit);
    objOrder.cgcloud__Phase__c = 'Released';
    objOrder.cgcloud__Release_Time__c = Date.today();
    objOrder.cgcloud__Order_Account__c = accObj.id;
    objOrder.cgcloud__Delivery_Recipient__c = accObj.id;
    objOrder.cgcloud__Accountable__c = userOne.Id;
    objOrder.cgcloud__Gross_Total_Value__c = null;
    //update objOrder
    update objOrder;

    //cgcloud__Inventory_Inventory_Transaction_Template__c
    cgcloud__Inventory_Transaction_Template__c inventoryTranTempOne = new cgcloud__Inventory_Transaction_Template__c(
      Name = 'TPB_initial',
      cgcloud__Sales_Org__c = salesOrg,
      cgcloud__Description_Language_1__c = 'TPB_initial',
      //set data
      cgcloud__Transaction_Control__c = 'Add',
      cgcloud__Transaction_Type__c = 'Addition',
      cgcloud__Use_Inventory_Reference_1__c = true,
      cgcloud__Use_Inventory_Reference_2__c = true,
      cgcloud__Active__c = true
    );
    //insert inventoryTranTempOne
    insert inventoryTranTempOne;

    System.runAs(userOne) {
      //create Order Item for test.
      cgcloud__Order_Item__c objOrderItem = new cgcloud__Order_Item__c();
      objOrderItem.cgcloud__Special_Price__c = 12;
      objOrderItem.cgcloud__Discount__c = 123;
      objOrderItem.cgcloud__Order__c = objOrder.id;
      objOrderItem.cgcloud__Value__c = 12;
      objOrderItem.Reimbursable_Amt__c = 12;
      objOrderItem.Reimbursement_Status__c = 'In Progress';
      objOrderItem.cgcloud__Pricing_Info_1__c = 123;
      insert objOrderItem;

      //create Product2 data
      Product2 prod = TPB_TestFactory.createProduct();
      //create Inventory
      TPB_TestFactory.createInventory(userOne.Id, prod.Id);
      cgcloud__Inventory__c objInventory = [
        SELECT
          Id,
          TPB_AvgPrice__c,
          cgcloud__Valid_From__c,
          cgcloud__Valid_Thru__c
        FROM cgcloud__Inventory__c
        WHERE cgcloud__Phase__c = 'Active'
        LIMIT 1
      ];
      objInventory.cgcloud__Valid_From__c = Date.today() - 2;
      objInventory.cgcloud__Valid_Thru__c = Date.today() + 10;
      objInventory.TPB_AvgPrice__c = 2;
      //update objInventory
      update objInventory;

      //create Inventory_Transaction data
      cgcloud__Inventory_Transaction__c objTransaction = new cgcloud__Inventory_Transaction__c();
      objTransaction.cgcloud__Inventory__c = objInventory.Id;
      objTransaction.cgcloud__Inventory_Transaction_Template__c = inventoryTranTempOne.Id;
      objTransaction.cgcloud__Order_Document__c = objOrder.Id;
      objTransaction.cgcloud__Amount__c = 2;
      //insert objTransaction
      insert objTransaction;
    }
  }

  @isTest
  static void testReferenceUpdateUserInventoryBalance() {
    //Execute batch to determine expected returns
    System.Test.startTest();
    TPB_UpdateUserInventoryBalanceBatch batch = new TPB_UpdateUserInventoryBalanceBatch();
    Database.executeBatch(batch);

    //create sql statement
    String strQuery =
      'SELECT Id, TPB_Inventory_Balance__c, TPB_Total_Adjustments__c, TPB_Reimbursable_Amount_Owed__c, TPB_Reimbursements_Issued__c, TPB_Reimbursements_Pending__c FROM User WHERE Username = \'' +
      strUserName +
      '\' ';
    TPB_UpdateUserInventoryBalanceBatch batch2 = new TPB_UpdateUserInventoryBalanceBatch(
      strQuery
    );
    //execute Batch
    Database.executeBatch(batch2);

    System.Test.stopTest();
    //assert batch job result.
    User userOne = [
      SELECT Id, TPB_Inventory_Balance__c, TPB_Reimbursable_Amount_Owed__c,TPB_Reimbursements_Issued__c, TPB_Reimbursements_Pending__c
      FROM User
      WHERE Username = :strUserName
      LIMIT 1
    ];
    System.assertEquals(4, userOne.TPB_Inventory_Balance__c, false);
  }

  @isTest
  static void testReferenceUpdateUserInventoryScheduler() {
    System.Test.startTest();
    //Execute TPB_UpdateUserInventoryBalanceScheduler Scheduler
    TPB_UpdateUserInventoryBalanceScheduler objScheduleJob = new TPB_UpdateUserInventoryBalanceScheduler();
    objScheduleJob.isRunTest = true;
    objScheduleJob.execute(null);
    System.Test.stopTest();
    //assert batch job result.
    System.assertEquals(true, objScheduleJob != null, 'fail');
  }
}