public without sharing class WorkOrderHandler {

    // public static void setPricebook(List<WorkOrder> workOrders) {
    //     List<Pricebook2> pricebooks = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true LIMIT 1];

    //     for(WorkOrder wo : workOrders) {
    //         if(wo.Pricebook2Id == null) {
    //             if(!pricebooks.isEmpty()) {
    //                 wo.Pricebook2Id = pricebooks[0].Id;
    //             }
    //             else {
    //                 wo.addError('There is no active standard pricebook.');
    //             }
    //         }
    //     }
    // }

    // public static void defaultLines(List<WorkOrder> workOrders) {
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
    //         for(WorkOrderLineItem line : [SELECT Id, PricebookEntryId, WorkOrder.AccountId, WorkOrder.EndDate, Close_Stock__c FROM WorkOrderLineItem
    //                                       WHERE WorkOrder.AccountId IN :accIds AND PricebookEntryId != null AND PricebookEntry.IsActive = true
    //                                       AND PricebookEntry.Product2.IsActive = true AND WorkOrderId NOT IN :workOrderIds
    //                                       AND (PricebookEntry.Product2.NTC_Item_Classification__c = 'Straight Stock' OR PricebookEntry.Product2.NTC_Item_Classification__c = 'POS')
    //                                       AND (In_Stock__c = true OR Item_Type__c = 'Cash Sale' OR Item_Type__c = 'Bill Thru' OR PODRIA_Status__c = 'O')
    //                                       AND WorkOrder.Status = 'Completed' AND WorkOrder.EndDate != null ORDER BY WorkOrder.EndDate ASC]) {
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
    //                     line.Origin__c = 'Previous WO';
    //                     line.In_Stock__c = existingLine.Close_Stock__c;
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
    //                         line.Origin__c = 'Ideal Kit';
    //                         lineItems.add(line);
    //                     }
    //                 }
    //             }
    //         }

    //         insert lineItems;
    //     }
    // }

    // public static void completionActions(List<WorkOrder> workOrders, Map<Id,WorkOrder> workOrderMap) {
    //     Set<Id> completedOrderIds = new Set<Id>();
    //     Set<Id> completedAccIds = new Set<Id>();
    //     Set<Id> ownerIds = new Set<Id>();

    //     for(WorkOrder wo : workOrders) {
    //         WorkOrder oldWo = workOrderMap.get(wo.Id);

    //         if(oldWo.Status != 'Completed' && wo.Status == 'Completed') {
    //             completedOrderIds.add(wo.Id);
    //             completedAccIds.add(wo.AccountId);
    //             ownerIds.add(wo.OwnerId);
    //         }
    //     }

    //     if(!completedOrderIds.isEmpty()) {
    //         //PODRIA LOGIC
    //         //Most recent Work Order
    //         Map<String,WorkOrderLineItem> lineItemMap = new Map<String,WorkOrderLineItem>();
    //         //Second most recent Work Order
    //         Map<String,WorkOrderLineItem> lineItemMapPreceding = new Map<String,WorkOrderLineItem>();

    //         for(WorkOrderLineItem line : [SELECT Id, PricebookEntryId, PODRIA_Status__c, In_Stock__c, WorkOrder.AccountId, Item_Type__c FROM WorkOrderLineItem
    //                                       WHERE WorkOrderId NOT IN :completedOrderIds AND WorkOrder.AccountId IN :completedAccIds AND PricebookEntryId != null
    //                                       AND WorkOrder.Status = 'Completed' AND WorkOrder.EndDate != null ORDER BY WorkOrder.EndDate ASC]) {
    //             lineItemMap.put(line.WorkOrder.AccountId + '-' + line.PricebookEntryId, line);
    //         }

    //         List<WorkOrderLineItem> linesUpdate = new List<WorkOrderLineItem>();
            
    //         for(WorkOrderLineItem line : [SELECT Id, WorkOrderId, PricebookEntryId, In_Stock__c, Item_Type__c, PODRIA_Status__c, WorkOrder.AccountId
    //                                         FROM WorkOrderLineItem WHERE WorkOrderId IN :completedOrderIds]) {
    //             WorkOrderLineItem previousLine = lineItemMap.get(line.WorkOrder.AccountId + '-' + line.PricebookEntryId);
    //             Boolean currentInStock = line.In_Stock__c;
    //             Boolean saleType = line.Item_Type__c == 'Cash Sale' || line.Item_Type__c == 'Bill Thru' ? true : false;

    //             if(previousLine != null) {
    //                 Boolean previousCloseStock = previousLine.In_Stock__c || previousLine.Item_Type__c == 'Cash Sale' || previousLine.Item_Type__c == 'Bill Thru' ? true : false;
    //                 String previousPodriaStatus = previousLine.PODRIA_Status__c;

    //                 if(currentInStock) {
    //                     if(previousCloseStock || previousPodriaStatus == 'O') {
    //                         line.PODRIA_Status__c = 'P';
    //                     }
    //                     else if(previousPodriaStatus == 'D' || previousPodriaStatus == 'A' || previousCloseStock != true) {
    //                         line.PODRIA_Status__c = 'I';
    //                     }
    //                 }
    //                 else {
    //                     if(previousCloseStock && saleType != true) {
    //                         line.PODRIA_Status__c = 'O';
    //                     }
    //                     else if((previousPodriaStatus == 'O' && saleType != true) || (previousPodriaStatus == 'D' && saleType != true)) {
    //                         line.PODRIA_Status__c = 'D';
    //                     }
    //                     else if((previousCloseStock && saleType) || (previousPodriaStatus == 'O' && saleType)) {
    //                         line.PODRIA_Status__c = 'R';
    //                     }
    //                     else if(((previousPodriaStatus == 'D' || previousPodriaStatus == 'A') && saleType) || (previousCloseStock && saleType)) {
    //                         line.PODRIA_Status__c = 'I';
    //                     }
    //                     else if((previousPodriaStatus == 'A' && saleType != true) || (previousCloseStock != true && previousPodriaStatus != 'O' && previousPodriaStatus != 'D')) {
    //                         line.PODRIA_Status__c = 'A';
    //                     }
    //                 }
    //             }
    //             else if(currentInStock || saleType) {
    //                 line.PODRIA_Status__c = 'I';
    //             }

    //             linesUpdate.add(line);
    //         }

    //         update linesUpdate;

    //         CallsPerDayAsync job = new CallsPerDayAsync(ownerIds);
    //         Id jobId = system.enqueueJob(job);
    //     }
    // }

}