@isTest
public inherited sharing class WorkOrderLineItemHandlerTest {
    
    // public static testMethod void testWorkOrderLineItemCreate() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     ProductItem item = TestDataFactory.createProductItem(locationObj.Id, prod.Id);
    //     WorkOrder previousWO = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem previousLine = TestDataFactory.createWorkOrderLineItem(previousWO.Id, entry.Id);

    //     test.startTest();
    //     WorkOrder newWO = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem newLine = TestDataFactory.createWorkOrderLineItemNoShelf(newWO.Id, entry.Id);
    //     test.stopTest();

    //     WorkOrderLineItem woli = [SELECT Id, Shelf_Price__c, UnitPrice FROM WorkOrderLineItem WHERE Id = :newLine.Id];

    //     system.assertEquals(100, woli.Shelf_Price__c);
    //     system.assertEquals(100, woli.UnitPrice);
    // }

    // public static testMethod void testWorkOrderLineItemUpdate() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder previousWO = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem previousLine = TestDataFactory.createWorkOrderLineItem(previousWO.Id, entry.Id);

    //     test.startTest();
    //     WorkOrder newWO = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem newLine = TestDataFactory.createWorkOrderLineItemNoShelf(newWO.Id, entry.Id);

    //     newLine.In_Stock__c = true;
    //     update newLine;
    //     test.stopTest();
    // }

}