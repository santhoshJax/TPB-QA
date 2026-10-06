/**
* @author Feng Lian
* @date 6/25/2023
* @description TPB_UpdateVanInventoryBatch test class
*/
@isTest
public class TPB_UpdateVanInventoryBatchTest {
    public static String salesOrg = '0001';

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
        objOrderItem1.UoM__c = 'Each';
        objOrderItem1.Quantity = 10;
        objOrderItem1.UnitPrice = 10.99;
        objOrderItem1.TPB_Type__c = 'Purchase';
        objOrderItem1.PricebookEntryId = entry.Id;
        insert objOrderItem1;

        Test.setCreatedDate(objOrderItem1.Id, Datetime.now().addSeconds(-1));
        update objOrderItem1;

        cgcloud__Trigger_Setting__c customset = new cgcloud__Trigger_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Name = 'InventoryTrigger',
            cgcloud__Deactivate__c = true
        );
        insert customset;

        objOrder1.Status = 'Activated';
        update objOrder1;

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
        
        objUnitOfMeasure = new cgcloud__Unit_of_Measure__c();
        objUnitOfMeasure.cgcloud__Unit_Type__c = 'Layer';
        objUnitOfMeasure.cgcloud__Pieces_per_Smallest_Unit__c = 50;
        objUnitOfMeasure.cgcloud__Product__c = prod.Id;
        objUnitOfMeasure.cgcloud__Is_Consumer_Unit__c = false;
        objUnitOfMeasure.cgcloud__Order_Ability__c = true;
        objUnitOfMeasure.cgcloud__Is_Order_Unit__c = false;
        objUnitOfMeasure.cgcloud__Sort__c = 3;
        uoms.add(objUnitOfMeasure);

        insert uoms;

        TPB_TestFactory.createInventoryControlTemplate();
        TPB_TestFactory.createInventoryTransactionTemplate();

        // cgcloud__Warehouse__c
        cgcloud__Warehouse__c warehouseOne = new cgcloud__Warehouse__c(
            Name = 'testWarehouse1',
            cgcloud__Sales_Org__c = salesOrg,
            cgcloud__Description_Language_1__c = 'testWarehouseDescription1',
            //set state
            cgcloud__State__c = 'NY'
        );
        insert warehouseOne;

        //cgcloud__Tour_Template__c
        cgcloud__Tour_Template__c tourTemplateOne = new cgcloud__Tour_Template__c(
            Name = 'testTourTemplate1',
            cgcloud__Sales_Org__c = salesOrg,
            //set description
            cgcloud__Description_Language_1__c = 'testWarehouseDescription1'
        );
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
        insert tourOne;
    }

    @isTest
    static void testUpdateInvBatch() {
        Test.startTest();
        //run batch
        TPB_UpdateVanInventoryBatch batch = new TPB_UpdateVanInventoryBatch();
        batch.execute(null);
        Test.stopTest();
        //assert batch job result.
        List<cgcloud__Inventory__c> invs = [
            SELECT TPB_AvgPrice__c, cgcloud__Balance__c, cgcloud__Product__c
            FROM cgcloud__Inventory__c
            WHERE cgcloud__Phase__c = 'Active' AND cgcloud__User__c = : UserInfo.getUserId()
        ];

        System.assertEquals(1, invs[0].cgcloud__Balance__c, false);
    }

    @isTest
    static void testUpdateInvBatchTwo() {
        Map<Id, Order> orders = new Map<Id, Order>([SELECT Id FROM Order WHERE Status = 'Activated']);
        Test.startTest();
        //run batch
        TPB_UpdateVanInventoryBatch batch = new TPB_UpdateVanInventoryBatch(orders.keySet());
        Database.executeBatch(batch);
        Test.stopTest();
        //assert batch job result.
        List<cgcloud__Inventory__c> invs = [
            SELECT TPB_AvgPrice__c, cgcloud__Balance__c, cgcloud__Product__c
            FROM cgcloud__Inventory__c
            WHERE cgcloud__Phase__c = 'Active' AND cgcloud__User__c = : UserInfo.getUserId()
        ];

        System.assertEquals(1, invs[0].cgcloud__Balance__c, false);
    }
    
    @isTest
    static void testUpdateInvBatchThree() {
        Test.startTest();
        //run batch
        TPB_UpdateVanInventoryBatch batch = new TPB_UpdateVanInventoryBatch();
        batch.execute(null);
        Test.stopTest();
        List<cgcloud__Inventory__c> invs = [
            SELECT TPB_AvgPrice__c, cgcloud__Balance__c, cgcloud__Product__c
            FROM cgcloud__Inventory__c
            WHERE cgcloud__Phase__c = 'Active' AND cgcloud__User__c = : UserInfo.getUserId()
        ];
        List<cgcloud__Inventory_Transaction__c> transList =
            [
                SELECT TPB_Wholesale_Order_Item__c, cgcloud__Amount__c
                FROM cgcloud__Inventory_Transaction__c
                WHERE cgcloud__Inventory__c IN : invs 
            ];
        transList[0].cgcloud__Amount__c = 10;
        update transList[0];
        
        List<OrderItem> items =
            [
                SELECT TPB_Type__c, UoM__c, Product2Id, Quantity, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c, Order.CreatedById
                FROM OrderItem
                WHERE Order.Status = 'Activated' AND Order.ActivatedDate = TODAY
                ORDER BY OrderId
            ];
        TPB_InventoryService.createInventory(items);
        invs = [
            SELECT TPB_AvgPrice__c, cgcloud__Balance__c, cgcloud__Product__c
            FROM cgcloud__Inventory__c
            WHERE cgcloud__Phase__c = 'Active' AND cgcloud__User__c = : UserInfo.getUserId()
        ];

        System.assertEquals(1, invs[0].cgcloud__Balance__c, false);
    }
}