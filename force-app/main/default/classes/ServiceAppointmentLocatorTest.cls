@isTest
public class ServiceAppointmentLocatorTest {

    // public static testMethod void serviceAppointmentTest() {
    //     Account retailer = TestDataFactory.createRetailAccount();
    //     Schema.Location locationObj = TestDataFactory.createLocation();
    //     Product2 prod = TestDataFactory.createProduct();
    //     PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id);
    //     WorkOrder prevWOrder = TestDataFactory.createWorkOrder(retailer.Id, locationObj.Id);
    //     WorkOrderLineItem lineItemOne = TestDataFactory.createWorkOrderLineItem(prevWOrder.Id, pbe.Id);
    //     WorkOrder wOrder = TestDataFactory.createOpenWorkOrder(retailer.Id, locationObj.Id);
    //     ServiceAppointment appointment = TestDataFactory.createServiceAppointment(wOrder.Id, null);
    //     //Need to requery for AccountId
    //     ServiceAppointment getAppointment = [SELECT Id, AccountId, ParentRecordId FROM ServiceAppointment WHERE Id = :appointment.Id];

    //     test.startTest();
    //     List<Map<String,String>> callTypes = ServiceAppointmentLocatorController.getCallTypes();
    //     String callType = callTypes[0].get('value');

    //     //Fail
    //     ServiceAppointmentLocatorController.updateAppointment(getAppointment, 'Tele-Visit');

    //     //getAppointment.Status = 'Dispatched';
    //     //update getAppointment;

    //     ServiceAppointmentLocatorController.updateAppointment(getAppointment, 'Tele-Visit');
    //     test.stopTest();

    //     Integer count = [SELECT count() FROM WorkOrderLineItem WHERE WorkOrderId = :wOrder.Id AND In_Stock__c = true];
    //     system.assertEquals(1, count);
    // }

}