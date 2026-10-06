public without sharing class WorkOrderLineItemHandler {

    //Insert
    // public static void setShelfPrice(List<WorkOrderLineItem> lines) {
    //     Set<Id> workOrderIds = new Set<Id>();

    //     for(WorkOrderLineItem line : lines) {
    //         workOrderIds.add(line.WorkOrderId);
    //     }

    //     if(!workOrderIds.isEmpty()) {
    //         Map<Id,Id> accountMap = new Map<Id,Id>();
    //         //Contains price for each item from most recent work order
    //         Map<String,Decimal> shelfPriceMap = new Map<String,Decimal>();

    //         for(WorkOrder wo : [SELECT Id, AccountId FROM WorkOrder WHERE Id IN :workOrderIds AND AccountId != null]) {
    //             accountMap.put(wo.Id, wo.AccountId);
    //         }

    //         for(WorkOrderLineItem line : [SELECT PricebookEntryId, Shelf_Price__c, WorkOrder.AccountId FROM WorkOrderLineItem WHERE WorkOrder.AccountId IN :accountMap.values()
    //                                       AND PricebookEntryId != null AND Shelf_Price__c != null AND WorkOrder.Status = 'Completed' AND WorkOrder.EndDate != null
    //                                       ORDER BY WorkOrder.EndDate ASC]) {
    //             shelfPriceMap.put(line.WorkOrder.AccountId + '-' + line.PricebookEntryId, line.Shelf_Price__c);
    //         }

    //         if(!shelfPriceMap.isEmpty()) {
    //             for(WorkOrderLineItem line : lines) {
    //                 Id accountId = accountMap.get(line.WorkOrderId);
    //                 Decimal shelfPrice = shelfPriceMap.get(accountId + '-' + line.PricebookEntryId);

    //                 if(line.Shelf_Price__c == null) {
    //                     line.Shelf_Price__c = shelfPrice;
    //                 }
    //             }
    //         }
    //     }
    // }

    // //Insert
    // public static void setUnitPrice(List<WorkOrderLineItem> lines) {
    //     //Product2Id is not set at this point
    //     Set<Id> pbeIds = new Set<Id>();
    //     Set<Id> workOrderIds = new Set<Id>();

    //     for(WorkOrderLineItem line : lines) {
    //         if(line.Origin__c != 'Ideal Kit') {
    //             pbeIds.add(line.PricebookEntryId);
    //         }
    //         else if(line.Origin__c == 'Ideal Kit' && line.UnitPrice == 0) {
    //             pbeIds.add(line.PricebookEntryId);
    //         }

    //         workOrderIds.add(line.WorkOrderId);
    //     }

    //     if(!pbeIds.isEmpty()) {
    //         Map<Id, PricebookEntry> entries = new Map<Id, PricebookEntry>([SELECT Product2Id FROM PricebookEntry WHERE Id IN :pbeIds]);
    //         Set<Id> locationIds = new Set<Id>();
    //         Map<Id,Decimal> unitPriceMap = new Map<Id,Decimal>();

    //         for(WorkOrder wo : [SELECT LocationId FROM WorkOrder WHERE Id IN :workOrderIds AND LocationId != null]) {
    //             locationIds.add(wo.LocationId);
    //         }

    //         for(ProductItem item : [SELECT Product2Id, Price__c FROM ProductItem WHERE LocationId IN :locationIds AND Product2Id != null AND Price__c != null]) {
    //             unitPriceMap.put(item.Product2Id, item.Price__c);
    //         }

    //         for(WorkOrderLineItem line : lines) {
    //             if(pbeIds.contains(line.PricebookEntryId)) {
    //                 Id productId = entries.get(line.PricebookEntryId).Product2Id;
    //                 Decimal unitPrice = unitPriceMap.get(productId);

    //                 line.UnitPrice = unitPrice;
    //             }
    //         }
    //     }
    // }

}