@isTest
public class GenerateInvoiceTest {

    // public static testMethod void testWorkOrder() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     ServiceReport report = TestDataFactory.createServiceReport(wOrder.Id, wOrder.ServiceReportTemplateId);

    //     test.startTest();
    //         Test.setMock(HttpCalloutMock.class, new MockHttpServiceReport());

    //         String response = GenerateInvoiceController.createInvoice(wOrder.Id, 'TOKEN', 'SIGNED_BY', 'SIGNATURE', 'NOTE');
    //     test.stopTest();
    // }

    // public static testMethod void testServiceAppointment() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     WorkOrder wOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry entry = TestDataFactory.createPricebookEntry(prod.Id);
    //     WorkOrderLineItem line = TestDataFactory.createWorkOrderLineItem(wOrder.Id, entry.Id);
    //     ServiceReport report = TestDataFactory.createServiceReport(wOrder.Id, wOrder.ServiceReportTemplateId);
    //     ServiceAppointment appointment = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :wOrder.Id];

    //     test.startTest();
    //         Boolean sortLines = GenerateInvoiceController.sortLines(appointment.Id);
    //     test.stopTest();
    // }

}