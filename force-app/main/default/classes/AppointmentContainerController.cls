public with sharing class AppointmentContainerController {

    // @AuraEnabled
    // public static String getServiceReport(Id workOrderId) {
    //     //Only one service report / invoice gets stored at the work order
    //     String documentId = '';

    //     for(ServiceReport sr : [SELECT ContentVersionDocument.ContentDocumentId FROM ServiceReport WHERE ParentId = :workOrderId ORDER BY CreatedDate DESC LIMIT 1]) {
    //         documentId = sr.ContentVersionDocument.ContentDocumentId;
    //     }

    //     return documentId;
    // }

}