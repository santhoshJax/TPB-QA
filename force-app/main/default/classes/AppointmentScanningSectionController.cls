public with sharing class AppointmentScanningSectionController {

    // @AuraEnabled
    // public static List<Product_Code__c> getProductCodes(Id pricebookId) {
    //     return [SELECT UPC__c, Product__r.Name FROM Product_Code__c WHERE Product__r.IsActive = true AND Product__c IN
    //             (SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND IsActive = true)];
    // }

    // @AuraEnabled
    // public static String upsertRecords(Id workOrderId, Id pricebookId, List<String> scannedBarcodes) {
    //     system.debug(workOrderId);
    //     system.debug(pricebookId);
    //     system.debug(scannedBarcodes);
    //     List<WorkOrderLineItem> lineItemUpserts = new List<WorkOrderLineItem>();
    //     Map<Id,String> upcMap = new Map<Id,String>();
    //     Map<String,WorkOrderLineItem> lineMap = new Map<String,WorkOrderLineItem>();
    //     Set<String> newLineCodes = new Set<String>();

    //     for(Product_Code__c code : [SELECT Id, UPC__c, Product__c FROM Product_Code__c WHERE UPC__c IN :scannedBarcodes]) {
    //         upcMap.put(code.Product__c, code.UPC__c);
    //     }

    //     for(WorkOrderLineItem woli : [SELECT Id, Product2Id, PricebookEntry.UnitPrice, In_Stock__c FROM WorkOrderLineItem WHERE WorkOrderId = :workOrderId]) {
    //         String upc = upcMap.get(woli.Product2Id);
    //         lineMap.put(upc, woli);
    //     }

    //     for(String barcode : scannedBarcodes) {
    //         WorkOrderLineItem woli = lineMap.get(barcode);

    //         if(woli != null) {
    //             woli.In_Stock__c = true;
    //             lineItemUpserts.add(woli);
    //         }
    //         else {
    //             newLineCodes.add(barcode);
    //         }
    //     }

    //     if(!newLineCodes.isEmpty()) {
    //         for(PricebookEntry pbe : [SELECT Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id = :pricebookId
    //                                   AND Product2Id IN (SELECT Product__c FROM Product_Code__c WHERE UPC__c IN :newLineCodes)]) {
    //             WorkOrderLineItem woli = new WorkOrderLineItem();
    //             woli.PricebookEntryId = pbe.Id;
    //             woli.WorkOrderId = workOrderId;
    //             woli.UnitPrice = pbe.UnitPrice;
    //             woli.In_Stock__c = true;
    //             lineItemUpserts.add(woli);
    //         }
    //     }

    //     try {
    //         upsert lineItemUpserts;
    //     }
    //     catch(DmlException e) {
    //         return e.getMessage();
    //     }

    //     return 'SUCCESS';
    // }

}