public with sharing class ServiceAppointmentLocatorController {

    // @AuraEnabled
    // public static List<Map<String,String>> getCallTypes() {
    //     return AppointmentUtilities.getPicklistVals('ServiceAppointment', 'Call_Type__c', new List<String>());
    // }

    // @RemoteAction
    // @AuraEnabled
    // public static String updateAppointment(ServiceAppointment appointment, String callType) {
    //     Set<String> lineChangeTypes = new Set<String>{'Tele-Visit', 'Admin Update'};
    //     List<WorkOrderLineItem> lineItems = new List<WorkOrderLineItem>();

    //     appointment.Id = appointment.Id;
    //     appointment.Status = 'In Progress';
    //     appointment.ActualStartTime = Datetime.now();
	// 	appointment.IP_Address__c = !Test.isRunningTest() ? Auth.SessionManagement.getCurrentSession().get('SourceIp') : null;
    //     appointment.Call_Type__c = callType;

    //     if(lineChangeTypes.contains(callType)) {
    //         List<WorkOrder> lastWorkOrder = [SELECT Id FROM WorkOrder WHERE AccountId = :appointment.AccountId AND Status = 'Completed' AND EndDate != null ORDER BY EndDate DESC LIMIT 1];

    //         if(!lastWorkOrder.isEmpty()) {
    //             Set<Id> entryIds = new Set<Id>();

    //             for(WorkOrderLineItem line : [SELECT PricebookEntryId FROM WorkOrderLineItem WHERE WorkOrderId = :lastWorkOrder[0].Id AND Close_Stock__c = true AND
    //             (PricebookEntry.Product2.NTC_Item_Classification__c = 'Straight Stock' OR PricebookEntry.Product2.NTC_Item_Classification__c = 'POS')]) {
    //                 entryIds.add(line.PricebookEntryId);
    //             }

    //             for(WorkOrderLineItem line : [SELECT Id, PricebookEntryId, In_Stock__c FROM WorkOrderLIneItem WHERE WorkOrderId = :appointment.ParentRecordId]) {
    //                 if(entryIds.contains(line.PricebookEntryId)) {
    //                     line.In_Stock__c = true;
    //                     lineItems.add(line);
    //                 }
    //             }
    //         }
    //     }

    //     try {
    //         update appointment;
    //         update lineItems;
    //     }
    //     catch(DmlException ex) {
    //         return ex.getMessage();
    //     }

    //     return 'SUCCESS';
    // }

}