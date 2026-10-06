@isTest
public inherited sharing class WorkOrderHandlerTest {

    // public static testMethod void testWorkOrderCreation() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
    //     WorkOrderLineItem line = TestDataFactory.createWorkOrderLineItem(wOrder.Id, entry.Id);
    //     //This does not get created as a new line because it's a duplicate of the above line item
    //     Ideal_Kit__c kit = TestDataFactory.createIdealKit(retailer.Id, prod.Id);

    //     test.startTest();
    //     WorkOrder newWO = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     test.stopTest();
        
    //     WorkOrderLineItem newLine = [SELECT Id, PricebookEntryId FROM WorkOrderLineItem WHERE WorkOrderId = :newWo.Id];
    //     system.assertEquals(entry.Id, newLine.PricebookEntryId);
    // }

    // public static testMethod void testPODRIA_P() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
        
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = wOrder.Id;
    //     line.PricebookEntryId = entry.Id;
    //     line.In_Stock__c = true;
    //     insert line;

    //     WorkOrder newWO = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     List<WorkOrderLineItem> lineUpdates = new List<WorkOrderLineItem>();

    //     for(WorkOrderLineItem woli : [SELECT Id, In_Stock__c, Item_Type__c, PODRIA_Status__c FROM WorkOrderLineItem WHERE WorkOrderId = :newWO.Id]) {
    //         woli.In_Stock__c = true;
    //         lineUpdates.add(woli);
    //     }

    //     update lineUpdates;

    //     test.startTest();
    //     newWo.Status = 'Completed';
    //     update newWO;
    //     test.stopTest();

    //     WorkorderLineItem newLine = [SELECT PODRIA_Status__c FROM WOrkOrderLineItem WHERE WorkOrderId = :newWO.Id];
    //     system.assertEquals('P', newLine.PODRIA_Status__c);
    // }

    // public static testMethod void testPODRIA_I() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
        
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = wOrder.Id;
    //     line.PricebookEntryId = entry.Id;
    //     line.PODRIA_Status__c = 'D';
    //     insert line;

    //     WorkOrder newWO = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem newLine = new WorkOrderLineItem();
    //     newLine.WorkOrderId = newWO.Id;
    //     newLine.PricebookEntryId = entry.Id;
    //     newLine.In_Stock__c = true;
    //     insert newLine;

    //     test.startTest();
    //     newWo.Status = 'Completed';
    //     update newWO;
    //     test.stopTest();

    //     newLine = [SELECT PODRIA_Status__c FROM WOrkOrderLineItem WHERE WorkOrderId = :newWO.Id];
    //     system.assertEquals('I', newLine.PODRIA_Status__c);
    // }

    // public static testMethod void testPODRIA_O() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
        
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = wOrder.Id;
    //     line.PricebookEntryId = entry.Id;
    //     line.PODRIA_Status__c = 'R';
    //     line.In_Stock__c = true;
    //     insert line;

    //     WorkOrder newWO = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     List<WorkOrderLineItem> lineUpdates = new List<WorkOrderLineItem>();

    //     test.startTest();
    //     newWo.Status = 'Completed';
    //     update newWO;
    //     test.stopTest();

    //     //WorkorderLineItem newLine = [SELECT PODRIA_Status__c FROM WOrkOrderLineItem WHERE WorkOrderId = :newWO.Id];
    //     //system.assertEquals('O', newLine.PODRIA_Status__c);
    // }

    // public static testMethod void testPODRIA_D() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
        
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = wOrder.Id;
    //     line.PricebookEntryId = entry.Id;
    //     line.PODRIA_Status__c = 'D';
    //     insert line;

    //     WorkOrder newWO = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem newLine = new WorkOrderLineItem();
    //     newLine.WorkOrderId = newWO.Id;
    //     newLine.PricebookEntryId = entry.Id;
    //     insert newLine;

    //     test.startTest();
    //     newWo.Status = 'Completed';
    //     update newWO;
    //     test.stopTest();

    //     newLine = [SELECT PODRIA_Status__c FROM WOrkOrderLineItem WHERE WorkOrderId = :newWO.Id];
    //     system.assertEquals('D', newLine.PODRIA_Status__c);
    // }

    // public static testMethod void testPODRIA_R() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
        
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = wOrder.Id;
    //     line.PricebookEntryId = entry.Id;
    //     line.In_Stock__c = true;
    //     insert line;

    //     WorkOrder newWO = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     List<WorkOrderLineItem> lineUpdates = new List<WorkOrderLineItem>();

    //     for(WorkOrderLineItem woli : [SELECT Id, In_Stock__c, Item_Type__c, PODRIA_Status__c FROM WorkOrderLineItem WHERE WorkOrderId = :newWO.Id]) {
    //         woli.Item_Type__c = 'Cash Sale';
    //         lineUpdates.add(woli);
    //     }

    //     update lineUpdates;

    //     test.startTest();
    //     newWo.Status = 'Completed';
    //     update newWO;
    //     test.stopTest();

    //     //WorkorderLineItem newLine = [SELECT PODRIA_Status__c FROM WOrkOrderLineItem WHERE WorkOrderId = :newWO.Id];
    //     //system.assertEquals('R', newLine.PODRIA_Status__c);
    // }

    // public static testMethod void testPODRIA_I_v2() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
        
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = wOrder.Id;
    //     line.PricebookEntryId = entry.Id;
    //     line.PODRIA_Status__c = 'D';
    //     insert line;

    //     WorkOrder newWO = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem newLine = new WorkOrderLineItem();
    //     newLine.WorkOrderId = newWO.Id;
    //     newLine.PricebookEntryId = entry.Id;
    //     newLine.Item_Type__c = 'Cash Sale';
    //     insert newLine;

    //     test.startTest();
    //     newWo.Status = 'Completed';
    //     update newWO;
    //     test.stopTest();

    //     newLine = [SELECT PODRIA_Status__c FROM WOrkOrderLineItem WHERE WorkOrderId = :newWO.Id];
    //     system.assertEquals('I', newLine.PODRIA_Status__c);
    // }

    // public static testMethod void testPODRIA_A() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
        
    //     WorkOrderLineItem line = new WorkOrderLineItem();
    //     line.WorkOrderId = wOrder.Id;
    //     line.PricebookEntryId = entry.Id;
    //     line.PODRIA_Status__c = 'A';
    //     insert line;

    //     WorkOrder newWO = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem newLine = new WorkOrderLineItem();
    //     newLine.WorkOrderId = newWO.Id;
    //     newLine.PricebookEntryId = entry.Id;
    //     newLine.Item_Type__c = 'Return';
    //     insert newLine;

    //     test.startTest();
    //     newWo.Status = 'Completed';
    //     update newWO;
    //     test.stopTest();

    //     newLine = [SELECT PODRIA_Status__c FROM WOrkOrderLineItem WHERE WorkOrderId = :newWO.Id];
    //     system.assertEquals('A', newLine.PODRIA_Status__c);
    // }

    // public static testMethod void testCallsPerDay() {
    //     User tsm = TestDataFactory.createTSM();
    //     Goals__c goals = TestDataFactory.createGoals();

    //     system.runAs(tsm) {
    //         Account retailer = TestDataFactory.createRetailAccount();
    //         Schema.Location locationObj = TestDataFactory.createLocation();
    //         WorkOrder wOrder = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //         ServiceAppointment appointment = TestDataFactory.createServiceAppointment(wOrder.Id, null);
    //         appointment.Status = 'In Progress';
    //         update appointment;
            
    //         test.startTest();
    //         appointment.Status = 'Completed';
    //         update appointment;
    //         test.stopTest();
    //     }

    //     //300 / 90
    //     Integer count = [SELECT count() FROM User WHERE Id = :tsm.Id AND Calls_per_Day_Goal__c = 3.3];
    //     system.assertEquals(1, count);
    // }

}