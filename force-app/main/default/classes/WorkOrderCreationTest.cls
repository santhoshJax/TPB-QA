@isTest
public inherited sharing class WorkOrderCreationTest {

    // public static testMethod void testWorkOrderCreation() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
    //     WorkOrderLineItem line = TestDataFactory.createWorkOrderLineItem(wOrder.Id, entry.Id);
    //     Ideal_Kit__c kit = TestDataFactory.createIdealKit(retailer.Id, prod.Id);

    //     test.startTest();
    //     WorkOrder newWO = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     //Mimic process builder that calls this on creation
    //     WorkOrderCreationAction.idealKitItems(new List<WorkOrder>{newWo});
    //     test.stopTest();

    //     //WorkOrderLineItem newLine = [SELECT Id, PricebookEntryId FROM WorkOrderLineItem WHERE WorkOrderId = :newWo.Id];
    //     //system.assertEquals(entry.Id, newLine.PricebookEntryId);
    // }

}