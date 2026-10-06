/**
 * @author Eric Chen
 * @date 2023-06-16
 * @description Test Class for TBP_PopulateInventoryTourBatchSchedule
 */
@isTest
private class TBP_PopulateInventoryTourBatchTest {
    /**
     * @description setup description
     */
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
        cgcloud__Org_Unit__c orgUnitOne = new cgcloud__Org_Unit__c(cgcloud__Sales_Org__c = '0001', Name = 'test1');
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
        insert inventoryTranTempOne;
        //create customer account
        Account accObj = TPB_TestFactory.createAccount();
        accObj.ShippingState = 'WA';
        update accObj;
        //create visit
        Visit objVisit = TPB_TestFactory.createVisit(accObj);
        //create advanced order
        cgcloud__Order__c objOrder = TPB_TestFactory.createAdOrder(objVisit);
        objOrder.cgcloud__Phase__c = 'Released';
        objOrder.cgcloud__Release_Time__c = Datetime.now();
        objOrder.cgcloud__Order_Account__c = accObj.id;
        objOrder.cgcloud__Delivery_Recipient__c = accObj.id;
        update objOrder;
        //create cgcloud__Inventory__c
        cgcloud__Inventory__c inv = new cgcloud__Inventory__c();
        inv.TPB_AvgPrice__c = 2;
        inv.cgcloud__Phase__c = 'Active';
        inv.TPB_Current_C_Fund_Balance__c = 1;
        inv.cgcloud__Initial_Inventory__c = 1000;
        inv.cgcloud__Valid_From__c = Date.today();
        inv.cgcloud__Valid_Thru__c = Date.today() + 1;
        inv.cgcloud__User__c = userOne.Id;
        inv.cgcloud__Product__c = productThree.Id;
        insert inv;
        //create cgcloud__Inventory_Transaction__c
        cgcloud__Inventory_Transaction__c objTransaction = new cgcloud__Inventory_Transaction__c();
        objTransaction.cgcloud__Inventory__c = inv.Id;
        objTransaction.cgcloud__Inventory_Transaction_Template__c = inventoryTranTempOne.Id;
        objTransaction.cgcloud__Order_Document__c = objOrder.Id;
        insert objTransaction;
    }

    /**
     * @description testExecute description
     */
    @isTest
    static void testExecute() {
        Test.startTest();
        Database.executeBatch(new TBP_PopulateInventoryTourBatchSchedule(), 100);
        String strQuery = 'SELECT Id FROM cgcloud__Inventory__c WHERE cgcloud__Tour__c = NULL LIMIT 5000';
        String jobName = 'TBP_PopulateInventoryTourBatchSchedule';
        DateTime currentDT = datetime.now();
        DateTime newDT = currentDT.addMinutes(1);
        String timePattern = newDT.format('ss mm HH dd MM \'?\' yyyy');
        System.schedule(jobName, timePattern, new TBP_PopulateInventoryTourBatchSchedule(strQuery));
        Test.stopTest();
        cgcloud__Inventory__c ojbInventory = [
            SELECT Id, cgcloud__Tour__c
            FROM cgcloud__Inventory__c
            LIMIT 1
        ];
        System.assert(ojbInventory.cgcloud__Tour__c != null, 'Error');
    }
}