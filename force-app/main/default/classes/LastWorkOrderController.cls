public with sharing class LastWorkOrderController {

    // @AuraEnabled(cacheable=true)
    // public static List<WorkOrderLineItem> getPreviousLines(Id accountId) {
    //     List<WorkOrder> mostRecentWorkOrder = [SELECT Id, EndDate FROM WorkOrder WHERE AccountId = :accountId AND Status = 'Completed' ORDER BY EndDate DESC LIMIT 1];

    //     if(!mostRecentWorkOrder.isEmpty()) {
    //         return [SELECT Id, PricebookEntryId, Product2.Name, Metric_Status__c, Close_Stock__c, WorkOrder.EndDate, In_Stock__c FROM WorkOrderLineItem
    //                 WHERE WorkOrderId = :mostRecentWorkOrder[0].Id AND WorkOrder.EndDate = :mostRecentWorkOrder[0].EndDate
    //                 AND Close_Stock__c = true ORDER BY Product2.Name ASC];
    //     }
    //     else {
    //         return new List<WorkOrderLineItem>();
    //     }
    // }

}