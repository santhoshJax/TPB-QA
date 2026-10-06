public with sharing class AppointmentLineItemSectionController {

    // @AuraEnabled
    // public static List<AppointmentLineItemsSectionWrapper> getLineItems(Id workOrderId, Id accountId) {
    //     List<AppointmentLineItemsSectionWrapper> wrapper = new List<AppointmentLineItemsSectionWrapper>();
    //     Set<Id> productIds = new Set<Id>();
    //     Set<Id> wholesalerIds = new Set<Id>();
    //     String primaryId = '';
    //     Boolean clearingHouse = false;
    //     Map<Id,Boolean> eOrderMap = new Map<Id,Boolean>();
    //     Map<String,String> skuMap = new Map<String,String>();
    //     Map<Id,Object> prevLineMap = new Map<Id,Object>();

    //     List<WorkOrderLineItem> lines = [SELECT Id, Item_Type__c, Product2.Name, Product2.Display_Group__c, Product2.Discount__c, Prebook_Date__c, Related_Account__c, Zone__c,
    //                                      UnitPrice, Quantity, Discount__c, Total__c, Product2.Packs_Carton__c, In_Stock__c, UOM__c, Shelf_Price__c, Resale__c,
    //                                      WorkOrderId, PricebookEntryId, Origin__c
    //                                      FROM WorkOrderLineItem WHERE WorkOrderId = :workOrderId ORDER BY Product2.Display_Group__c ASC, Product2.Name ASC];

    //     for(WorkOrderLineItem line : lines) {
    //         productIds.add(line.Product2Id);
    //     }

    //     for(Related_Account__c related : [SELECT Id, Type__c, Wholesaler__r.Clearing_House_Participant__c FROM Related_Account__c WHERE Retailer__c = :accountId]) {
    //         //Determine if E-Order available
    //         if(related.Type__c == 'Primary') {
    //             primaryId = related.Wholesaler__c;

    //             if(related.Wholesaler__r.Clearing_House_Participant__c) {
    //                 clearingHouse = true;
    //             }
    //         }

    //         //Determine item code (sku) for primary and secondary
    //         if(related.Type__c == 'Primary' || related.Type__c == 'Secondary') {
    //             wholesalerIds.add(related.Wholesaler__c);
    //         }
    //     }

    //     for(Account_Product__c accProd : [SELECT Id, Account__c, Product__c, SKU__c FROM Account_Product__c WHERE Account__c IN :wholesalerIds AND Product__c IN :productIds]) {
    //         if(primaryId == accProd.Account__c && clearingHouse && accProd.SKU__c != null) {
    //             eOrderMap.put(accProd.Product__c, true);
    //         }

    //         if(primaryId == accProd.Account__c) {
    //             skuMap.put('PRIMARY-' + accProd.Product__c, accProd.SKU__c);
    //         }
    //         else {
    //             skuMap.put('SECONDARY-' + accProd.Product__c, accProd.SKU__c);
    //         }
    //     }

    //     for(WorkOrderLineItem line : lines) {
    //         AppointmentLineItemsSectionWrapper item = new AppointmentLineItemsSectionWrapper(line, eOrderMap, skuMap, prevLineMap);
    //         wrapper.add(item);
    //     }

    //     return wrapper;
    // }

    // @AuraEnabled
    // public static List<Related_Account__c> getWholesalers(Id accountId) {
    //     return [SELECT Id, Wholesaler__r.Name, Type__c FROM Related_Account__c WHERE Retailer__c = :accountId];
    // }

    // @AuraEnabled
    // public static String updateRecords(String lineItems) {
    //     List<WorkOrderLineItem> woliUpsert = new List<WorkOrderLineItem>();
    //     List<AppointmentLineItemsSectionWrapper> wrapperLines = (List<AppointmentLineItemsSectionWrapper>)JSON.deserialize(lineItems, List<AppointmentLineItemsSectionWrapper>.class);

    //     for(AppointmentLineItemsSectionWrapper wrapper : wrapperLines) {
    //         WorkOrderLineItem woli = AppointmentLineItemSectionHelper.createLineItem(wrapper);
    //         system.debug(woli.Related_Account__c);
    //         woliUpsert.add(woli);
    //     }

    //     try {
    //         upsert woliUpsert;
    //     }
    //     catch(DmlException e) {
    //         return e.getMessage();
    //     }

    //     return 'SUCCESS';
    // }

}