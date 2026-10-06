@isTest
public inherited sharing class AppointmentLineItemSectionTest {

    // public static testMethod void testAppointmentLineItemSection() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Account wholesaler = TestDataFactory.createWholesaleAccount();
    //     Related_Account__c related = TestDataFactory.createRelatedAccount(retailer.Id, wholesaler.Id);
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
    //     WorkOrderLineItem line = TestDataFactory.createWorkOrderLineItem(wOrder.Id, entry.Id);
    //     Account_Product__c accProd = TestDataFactory.createAccountProduct(wholesaler.Id, prod.Id);

    //     test.startTest();
    //     List<AppointmentLineItemsSectionWrapper> lines = AppointmentLineItemSectionController.getLineItems(wOrder.Id, retailer.Id);
    //     List<Related_Account__c> relatedAccounts = AppointmentLineItemSectionController.getWholesalers(retailer.Id);
    //     String recordUpsert = AppointmentLineItemSectionController.updateRecords(JSON.serialize(lines));
    //     test.stopTest();

    //     system.assertEquals(true, lines[0].isNotPrebook);
    //     system.assertEquals(1, relatedAccounts.size());
    //     system.assertEquals('SUCCESS', recordUpsert);
    // }

}