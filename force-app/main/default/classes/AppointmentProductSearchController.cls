public with sharing class AppointmentProductSearchController {

    // @AuraEnabled
    // public static List<PricebookEntry> getProducts(String pricebookId) {
    //     return [SELECT Id, Product2.Name, Product2.Display_Group__c, UnitPrice FROM PricebookEntry
    //             WHERE Pricebook2Id = :pricebookId AND IsActive = true AND Product2.IsActive = true
    //             ORDER BY Product2.Sort_Order__c ASC NULLS LAST];
    // }

    // @AuraEnabled
    // public static Map<String,Decimal> getDisplayGroups() {
    //     Map<String,Decimal> displayMap = new Map<String,Decimal>();

    //     for(Display_Group__c display : [SELECT Id, Display_Group__c, Sort_Order__c FROM Display_Group__c LIMIT 500]) {
    //         displayMap.put(display.Display_Group__c, display.Sort_Order__c);
    //     }

    //     return displayMap;
    // }

    // @AuraEnabled
    // public static String saveRecords(Id workOrderId, List<PricebookEntry> entries) {
    //     List<WorkOrderLineItem> lineItems = new List<WorkOrderLineItem>();

    //     for(PricebookEntry pbe : entries) {
    //         WorkOrderLineItem woli = new WorkOrderLineItem();
    //         woli.WorkOrderId = workOrderId;
    //         woli.PricebookEntryId = pbe.Id;
    //         woli.UnitPrice = pbe.UnitPrice;
    //         lineItems.add(woli);
    //     }

    //     try {
    //         insert lineItems;
    //     }
    //     catch(DmlException e) {
    //         return e.getMessage();
    //     }

    //     return 'SUCCESS';
    // }

}