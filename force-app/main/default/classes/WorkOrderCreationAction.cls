public without sharing class WorkOrderCreationAction {

    // @InvocableMethod(label='Ideal Kit Records' description='Adds Ideal Kit items as WOLIs')
    // public static void idealKitItems(List<WorkOrder> workOrders) {
    //     Set<Id> workOrderIds = new Set<Id>();
    //     Set<Id> accIds = new Set<Id>();
    //     Set<Id> pricebookIds = new Set<Id>();
        
    //     for(WorkOrder wo : workOrders) {
    //         accIds.add(wo.AccountId);
    //         pricebookIds.add(wo.Pricebook2Id);
    //         workOrderIds.add(wo.Id);
    //     }

    //     if(!accIds.isEmpty()) {
    //         Set<Id> productIds = new Set<Id>();
    //         Map<String,Id> entryMap = new Map<String,Id>();
    //         Map<Id,List<Ideal_Kit__c>> kitMap = new Map<Id,List<Ideal_Kit__c>>();
    //         List<WorkOrderLineItem> lineItems = new List<WorkOrderLineItem>();
    //         Map<String,WorkOrderLineItem> lineItemMap = new Map<String,WorkOrderLineItem>();
    //         Set<String> lineDupeCheck = new Set<String>();
    //         //Only store values from the most recent work order
    //         Map<Id,DateTime> dateMap = new Map<Id,DateTime>();

    //         //Get previous line items
    //         for(WorkOrderLineItem line : [SELECT Id, PricebookEntryId, WorkOrder.AccountId, WorkOrder.EndDate FROM WorkOrderLineItem
    //                                       WHERE WorkOrder.AccountId IN :accIds AND PricebookEntryId != null AND WorkOrderId NOT IN :workOrderIds
    //                                       ORDER BY WorkOrder.EndDate ASC NULLS FIRST]) {
    //             lineItemMap.put(line.WorkOrder.AccountId + '-' + line.PricebookEntryId, line);
    //             dateMap.put(line.WorkOrder.AccountId, line.WorkOrder.EndDate);
    //         }

    //         //Get Ideal Kit products
    //         for(Ideal_Kit__c kit : [SELECT Id, Item_Type__c, Price__c, Product__c, Quantity__c, Account__c FROM Ideal_Kit__c WHERE Account__c IN :accIds]) {
    //             productIds.add(kit.Product__c);

    //             if(kitMap.containsKey(kit.Account__c)) {
    //                 kitMap.get(kit.Account__c).add(kit);
    //             }
    //             else {
    //                 kitMap.put(kit.Account__c, new List<Ideal_Kit__c>{kit});
    //             }
    //         }

    //         for(PricebookEntry pbe : [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id IN :pricebookIds AND Product2Id IN :productIds]) {
    //             entryMap.put(pbe.Pricebook2Id + '-' + pbe.Product2Id, pbe.Id);
    //         }

    //         for(WorkOrder wo : workOrders) {
    //             for(String key : lineItemMap.keySet()) {
    //                 WorkOrderLineItem existingLine = lineItemMap.get(key);
    //                 DateTime mostRecentDate = dateMap.get(existingLine.WorkOrder.AccountId);

    //                 if(wo.AccountId == existingLine.WorkOrder.AccountId && mostRecentDate == existingLine.WorkOrder.EndDate) {
    //                     WorkOrderLineItem line = new WorkOrderLineItem();
    //                     line.WorkOrderId = wo.Id;
    //                     line.PricebookEntryId = existingLine.PricebookEntryId;
    //                     lineItems.add(line);
    //                     lineDupeCheck.add(line.WorkOrderId + '-' + line.PricebookEntryId);
    //                 }
    //             }

    //             List<Ideal_Kit__c> kits = kitMap.get(wo.AccountId);

    //             if(kits != null) {
    //                 for(Ideal_Kit__c kit : kits) {
    //                     Id pbeId = entryMap.get(wo.Pricebook2Id + '-' + kit.Product__c);

    //                     if(pbeId != null && !lineDupeCheck.contains(wo.Id + '-' + pbeId)) {
    //                         WorkOrderLineItem line = new WorkOrderLineItem();
    //                         line.WorkOrderId = wo.Id;
    //                         line.PricebookEntryId = pbeId;
    //                         line.Item_Type__c = kit.Item_Type__c;
    //                         line.UnitPrice = kit.Price__c;
    //                         line.Quantity = kit.Quantity__c;
    //                         line.Ideal_Kit__c = true;
    //                         lineItems.add(line);
    //                     }
    //                 }
    //             }
    //         }

    //         insert lineItems;
    //     }
    // }

}