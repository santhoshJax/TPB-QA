public without sharing class GenerateInvoiceController {
    //This creates a ServiceReport

    // public GenerateInvoiceController(ApexPages.StandardController stdController) {}

    // @RemoteAction
    // public static Boolean sortLines(Id recordId) {
    //     Map<String,String> objectMap = objectMap(recordId);
    //     List<WorkOrderLineItem> lines = new List<WorkOrderLineItem>();
    //     Integer count = 0;

    //     for(WorkOrderLineItem woli : [SELECT Id, Sort_Order__c FROM WorkOrderLineItem WHERE WorkOrderId = :objectMap.get('workOrderId') ORDER BY PricebookEntry.Product2.Name ASC]) {
    //         woli.Sort_Order__c = count;
    //         lines.add(woli);
    //         count++;
    //     }

    //     try {
    //         update lines;
    //     }
    //     catch(DmlException e) {
    //         return false;
    //     }

    //     return true;
    // }

    // @RemoteAction
    // public static String createInvoice(Id recordId, String token, String signedBy, String signature, String note) {
    //     Map<String,String> objectMap = objectMap(recordId);
    //     return callout(objectMap.get('workOrderId'), objectMap.get('templateId'), token, signedBy, signature, note);
    // }

    // private static Map<String,String> objectMap(Id recordId) {
    //     String sObjName = recordId.getSObjectType().getDescribe().getName();
    //     Id workOrderId;
    //     String templateType = '';

    //     switch on sObjName {
    //         when 'WorkOrder' {
    //             WorkOrder workOrder = [SELECT Id, StateCode FROM WorkOrder WHERE Id = :recordId];
    //             workOrderId = workOrder.Id;
    //             templateType = workOrder.StateCode == 'KY' ? 'Kentucky Template' : 'Non-Kentucky Template';
    //         }
    //         when 'ServiceAppointment' {
    //             ServiceAppointment appointment = [SELECT ParentRecordId, StateCode FROM ServiceAppointment WHERE Id = :recordId];
    //             workOrderId = appointment.ParentRecordId;
    //             templateType = appointment.StateCode == 'KY' ? 'Kentucky Template' : 'Non-Kentucky Template';
    //         }
    //     }

    //     String templateId = [SELECT Id FROM ServiceReportLayout WHERE DeveloperName = :templateType].Id;
    //     return new Map<String,String>{'workOrderId' => workOrderId, 'templateId' => templateId};
    // }

    // private static String callout(Id workOrderId, String templateId, String token, String signedBy, String signature, String note) {
    //     HttpResponse response = ServiceReportCalloutHelper.callout(workOrderId, templateId, token, signedBy, signature, note);
            
    //     if(response.getStatusCode() != 200) {
    //         return 'There was a problem creating the invoice. Please try again.';
    //     }
    //     else {
    //         return [SELECT ContentVersionDocument.ContentDocumentId
    //                 FROM ServiceReport WHERE ParentId = :workOrderId ORDER BY CreatedDate DESC LIMIT 1].ContentVersionDocument.ContentDocumentId;
    //     }
    // }

}