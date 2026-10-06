public class TPB_OnlineAppBarcodeScanController {
    public TPB_OnlineAppBarcodeScanController() {

    }

    
    @AuraEnabled
    public static ScannedOrderItemsResult createVisitJobsFromScannedData(String scannedValues, String visitId, String accountId) {
        try {
            if (String.isBlank(visitId)) {
                throw new AuraHandledException('Visit Id is required.');
            }
            if (String.isBlank(scannedValues)) {
                throw new AuraHandledException('No scanned values received.');
            }

            // 1. Split scanned values and get unique GTINs
            Set<String> gtinSet = new Set<String>();
            for (String val : scannedValues.split('[,\\n]+')) {
                String trimmed = val != null ? val.trim() : null;
                if (!String.isBlank(trimmed)) {
                    gtinSet.add(trimmed);
                }
            }

            if (gtinSet.isEmpty()) {
                throw new AuraHandledException('No valid GTIN values found.');
            }

            // 2. Query matching UOM records to get product Ids
            // Map<Id, String> productIdToGtinMap = new Map<Id, String>();
            // for (cgcloud__Unit_of_Measure__c uom : [
            //     SELECT cgcloud__Product__c, cgcloud__GTIN__c
            //     FROM cgcloud__Unit_of_Measure__c
            //     WHERE cgcloud__GTIN__c IN :gtinSet
            // ]) {
            //     productIdToGtinMap.put(uom.cgcloud__Product__c, uom.cgcloud__GTIN__c);
            // }
            
            Map<Id, cgcloud__Unit_of_Measure__c> productIdToGtinMap = new Map<Id, cgcloud__Unit_of_Measure__c>();
            List<cgcloud__Unit_of_Measure__c> uomList = [
                SELECT Id, cgcloud__GTIN__c, cgcloud__Unit_Type__c,
                    cgcloud__Product__c, cgcloud__Product__r.Name
                FROM cgcloud__Unit_of_Measure__c
                WHERE cgcloud__GTIN__c IN :gtinSet
            ];
            // Build matched/failed lists
            Set<String> matchedGtins = new Set<String>();
            for (cgcloud__Unit_of_Measure__c uom : uomList) {
                //productIdToGtinMap.put(uom.cgcloud__Product__c, uom.cgcloud__GTIN__c);
                productIdToGtinMap.put(uom.cgcloud__Product__c, uom);
                matchedGtins.add(uom.cgcloud__GTIN__c);
            }
            System.debug('productIdToGtinMap...'+productIdToGtinMap);
            List<FailedItemWrapper> failedItems = new List<FailedItemWrapper>();
            for (String gtin : gtinSet) {
                if (!matchedGtins.contains(gtin)) {
                    FailedItemWrapper f = new FailedItemWrapper();
                    f.gtin = gtin;
                    f.reason = 'GTIN_NOT_FOUND';
                    failedItems.add(f);
                }
            }

            if (productIdToGtinMap.isEmpty()) {
                throw new AuraHandledException('No matching products found for scanned values.');
            }

            List<cgcloud__Visit_Job__c> visitJobsToInsert = new List<cgcloud__Visit_Job__c>();
            List<cgcloud__Visit_Job__c> visitJobsToUpdate = new List<cgcloud__Visit_Job__c>();
            List<cgcloud__Job_Definition_List_Product__c> missedDistributedProducts = new List<cgcloud__Job_Definition_List_Product__c>();

            

            List<cgcloud__Visit_Job__c> productDistVisitJobs = [SELECT ID, cgcloud__Visit__c, cgcloud__Product__r.Name,cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name, cgcloud__Value__c,cgcloud__Job_Definition__c,cgcloud__Job_Definition_Template__c,cgcloud__Data_Type_Option__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c =: visitId];

            
            if(productDistVisitJobs.size() > 0){

                //New Code 16-Dec-2025
                Map<Id, cgcloud__Visit_Job__c> productIdToVisitJobMap = new Map<Id, cgcloud__Visit_Job__c>();
                for (cgcloud__Visit_Job__c job : productDistVisitJobs) {
                    if (job.cgcloud__Product__c != null) {
                        productIdToVisitJobMap.put(job.cgcloud__Product__c, job);
                    }
                }
                //End


                // 3. Query existing Visit Jobs for these products under this visit
                Map<Id, cgcloud__Visit_Job__c> existingVisitJobs = new Map<Id, cgcloud__Visit_Job__c>();
                for (cgcloud__Visit_Job__c existingJob : [
                    SELECT Id, cgcloud__product__c, cgcloud__Value__c, cgcloud__Visit_Date__c
                    FROM cgcloud__Visit_Job__c
                    WHERE cgcloud__Visit__c = :visitId
                    AND cgcloud__product__c IN :productIdToGtinMap.keySet()
                ]) {
                    existingVisitJobs.put(existingJob.cgcloud__product__c, existingJob);
                }
                // 4. Prepare Insert/Update lists
                for (Id productId : productIdToGtinMap.keySet()) {
                    if (existingVisitJobs.containsKey(productId)) {
                        cgcloud__Visit_Job__c existingJob = existingVisitJobs.get(productId);
                        // Only update if NOT already Distributed
                        //if (existingJob.cgcloud__Value__c != 'Distributed') {
                            existingJob.cgcloud__Value__c = 'Distributed';
                           // existingJob.Calculated_Distribution__c = 'Distributed';
                            existingJob.Via_Scanner__c = true; //For SAL-281
                            existingJob.cgcloud__Done__c = true;
                            if (existingJob.cgcloud__Visit_Date__c == null) {
                                existingJob.cgcloud__Visit_Date__c = Date.today();
                            }

                            if (productIdToVisitJobMap.containsKey(productId)) {
                                cgcloud__Visit_Job__c sourceJob = productIdToVisitJobMap.get(productId);
                                existingJob.cgcloud__Job_Definition__c = sourceJob.cgcloud__Job_Definition__c;
                                existingJob.cgcloud__Job_Definition_Template__c = sourceJob.cgcloud__Job_Definition_Template__c;
                                existingJob.cgcloud__Data_Type_Option__c = sourceJob.cgcloud__Data_Type_Option__c;
                            }

                            visitJobsToUpdate.add(existingJob);
                        //}
                    } else {
                        cgcloud__Visit_Job__c newJob = new cgcloud__Visit_Job__c();
                        newJob.cgcloud__Visit__c = visitId;
                        newJob.cgcloud__product__c = productId;
                        newJob.cgcloud__Value__c = 'Distributed';
                        //newJob.Calculated_Distribution__c = 'Distributed';
                        newJob.Via_Scanner__c = true; //For SAL-281
                        newJob.cgcloud__Done__c = true;
                        newJob.cgcloud__Visit_Date__c = Date.today();
                        visitJobsToInsert.add(newJob);
                    }
                }
            }else{
                Set<Id> activityCustomerIds = TPB_OnlineAppController.getActivityProducts(accountId); 
                System.debug('activityCustomerIds data...'+ activityCustomerIds);

                List<cgcloud__Job_Definition_List_Product__c> activityProducts = [SELECT Id,Name,cgcloud__Product__r.Name,cgcloud__Product__r.cgcloud__Criterion_2_Product__r.Name, TPB_EOV__c,cgcloud__Job_Definition_List__c FROM cgcloud__Job_Definition_List_Product__c WHERE cgcloud__Job_Definition_List__c  IN : activityCustomerIds];
                // Step 3: Prepare visit job records for all activity products
                Set<Id> scannedProductIds = productIdToGtinMap.keySet();
                // Step 4: Track activity product IDs
                Set<Id> activityProductIds = new Set<Id>();
                for (cgcloud__Job_Definition_List_Product__c actProd : activityProducts) {
                    activityProductIds.add(actProd.cgcloud__Product__c);
                }

                //New Code 16-Dec-2025
                List<cgcloud__Job_DL_Job_Definition_Template__c> activityDataTypes = [SELECT Id,
                                    cgcloud__Job_Definition_List__c,
                                    cgcloud__Job_Definition_Template__c,
                                    cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c
                            FROM cgcloud__Job_DL_Job_Definition_Template__c
                            WHERE cgcloud__Job_Definition_List__c IN :activityCustomerIds];
                system.debug('activityDataTypes'+ activityDataTypes);

                Map<Id, cgcloud__Job_DL_Job_Definition_Template__c> activityJobDefsMap = new Map<Id, cgcloud__Job_DL_Job_Definition_Template__c>();
                Set<Id> dataTypeOptionIds = new Set<Id>();

                for (cgcloud__Job_DL_Job_Definition_Template__c activityJobDef : activityDataTypes) {
                    activityJobDefsMap.put(activityJobDef.cgcloud__Job_Definition_List__c, activityJobDef);
                    dataTypeOptionIds.add(activityJobDef.cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c);
                }

                system.debug('activityJobDefsMap'+ activityJobDefsMap);
                system.debug('dataTypeOptionIds'+ dataTypeOptionIds);

                List<cgcloud__Data_Type_Option__c> dataTypeOptions = [SELECT Id,Name,cgcloud__Description__c,cgcloud__Data_Type__c,
                            cgcloud__Data_Type__r.Name FROM cgcloud__Data_Type_Option__c
                            WHERE cgcloud__Data_Type__c IN :dataTypeOptionIds];
                system.debug('dataTypeOptions'+ dataTypeOptions);
                Map<Id, Map<String, Id>> dataTypeOptionsMap = new Map<Id, Map<String, Id>>();

                for (cgcloud__Data_Type_Option__c option : dataTypeOptions) {

                    Id dataTypeId = option.cgcloud__Data_Type__c;

                    // Initialize sub-map if this DataType Id is not added yet
                    if (!dataTypeOptionsMap.containsKey(dataTypeId)) {
                        dataTypeOptionsMap.put(dataTypeId, new Map<String, Id>());
                    }

                    // Add option to that DataType's map
                    dataTypeOptionsMap.get(dataTypeId).put(option.cgcloud__Description__c, option.Id);
                }
                system.debug('dataTypeOptionsMap'+ dataTypeOptionsMap);
                //End


                // Step 5: Prepare visit jobs for activity products
                for (cgcloud__Job_Definition_List_Product__c actProd : activityProducts) {
                    cgcloud__Visit_Job__c vj = new cgcloud__Visit_Job__c();
                    vj.cgcloud__Visit__c = visitId;
                    vj.cgcloud__Product__c = actProd.cgcloud__Product__c;
                    vj.cgcloud__Value__c = scannedProductIds.contains(actProd.cgcloud__Product__c) ? 'Distributed' : actProd.TPB_EOV__c;
                    //vj.Calculated_Distribution__c = scannedProductIds.contains(actProd.cgcloud__Product__c) ? 'Distributed' : actProd.TPB_EOV__c;
                    //vj.Via_Scanner__c = true; //For SAL-281
                    vj.cgcloud__Done__c = true;
                    vj.cgcloud__Visit_Date__c = Date.today();


                    if(vj.cgcloud__Product__c != null){
                        vj.cgcloud__Job_Definition__c = activityJobDefsMap.containsKey(actProd.cgcloud__Job_Definition_List__c)
                                                ? activityJobDefsMap.get(actProd.cgcloud__Job_Definition_List__c).Id
                                                : null;

                        vj.cgcloud__Job_Definition_Template__c = activityJobDefsMap.containsKey(actProd.cgcloud__Job_Definition_List__c)
                                                            ? activityJobDefsMap.get(actProd.cgcloud__Job_Definition_List__c).cgcloud__Job_Definition_Template__c
                                                            : null;
                        String dataTypeId = activityJobDefsMap.containsKey(actProd.cgcloud__Job_Definition_List__c)
                                                            ? activityJobDefsMap.get(actProd.cgcloud__Job_Definition_List__c).cgcloud__Job_Definition_Template__r.cgcloud__Data_Type__c
                                                            : null;
                        
                        vj.cgcloud__Data_Type_Option__c = dataTypeOptionsMap.containsKey(dataTypeId) &&
                                                            dataTypeOptionsMap.get(dataTypeId).containsKey(vj.cgcloud__Value__c)
                                                            ? dataTypeOptionsMap.get(dataTypeId).get(vj.cgcloud__Value__c)
                                                            : null;
                    }
                    

                    visitJobsToInsert.add(vj);
                    // Step 4a: Check for missed scans with Distributed status
                    if (actProd.TPB_EOV__c == 'Distributed' && !scannedProductIds.contains(actProd.cgcloud__Product__c)) {
                        missedDistributedProducts.add(actProd);
                    }
                }
                // Step 6: Insert additional scanned products not in activity products
                for (Id scannedProductId : scannedProductIds) {
                    if (!activityProductIds.contains(scannedProductId)) {
                        cgcloud__Visit_Job__c vjExtra = new cgcloud__Visit_Job__c();
                        vjExtra.cgcloud__Visit__c = visitId;
                        vjExtra.cgcloud__Product__c = scannedProductId;
                        vjExtra.cgcloud__Value__c = 'Distributed';
                        //vjExtra.Calculated_Distribution__c = 'Distributed';
                        vjExtra.Via_Scanner__c = true; //For SAL-281
                        vjExtra.cgcloud__Done__c = true;
                        vjExtra.cgcloud__Visit_Date__c = Date.today();
                        visitJobsToInsert.add(vjExtra);
                    }
                }
            }
            System.debug('visitJobsToInsert...'+visitJobsToInsert);
            System.debug('visitJobsToUpdate...'+visitJobsToUpdate);
            // 5. Perform DML
            if (!visitJobsToInsert.isEmpty()) {
                Database.SaveResult[] insResults = Database.insert(visitJobsToInsert, false);
                for (Integer i = 0; i < insResults.size(); i++) {
                    if (!insResults[i].isSuccess()) {
                        if (productIdToGtinMap.containsKey(visitJobsToInsert[i].cgcloud__Product__c)) {
                            FailedItemWrapper f = new FailedItemWrapper();
                            f.gtin = productIdToGtinMap.get(visitJobsToInsert[i].cgcloud__Product__c).cgcloud__GTIN__c;
                            f.reason = 'DML_FAILED';
                            failedItems.add(f);
                        }
                    }
                }
            }
            if (!visitJobsToUpdate.isEmpty()) {
                Database.SaveResult[] updResults = Database.update(visitJobsToUpdate, false);
                for (Integer i = 0; i < updResults.size(); i++) {
                    if (!updResults[i].isSuccess()) {
                        if (productIdToGtinMap.containsKey(visitJobsToUpdate[i].cgcloud__Product__c)) {
                            FailedItemWrapper f = new FailedItemWrapper();
                            f.gtin = productIdToGtinMap.get(visitJobsToUpdate[i].cgcloud__Product__c).cgcloud__GTIN__c;
                            f.reason = 'DML_FAILED';
                            failedItems.add(f);
                        }
                    }
                }
            }
            // 🔑 Build AddedItemWrapper list from inserted/updated jobs
            List<AddedItemWrapper> addedItems = new List<AddedItemWrapper>();
            List<cgcloud__Visit_Job__c> allProcessedJobs = new List<cgcloud__Visit_Job__c>();
            allProcessedJobs.addAll(visitJobsToInsert);
            allProcessedJobs.addAll(visitJobsToUpdate);

            for (cgcloud__Visit_Job__c vj : allProcessedJobs) {
                if (productIdToGtinMap.containsKey(vj.cgcloud__Product__c)) {
                    cgcloud__Unit_of_Measure__c uom = productIdToGtinMap.get(vj.cgcloud__Product__c);
                    AddedItemWrapper a = new AddedItemWrapper();
                    a.productName = uom.cgcloud__Product__r.Name;
                    a.gtin = uom.cgcloud__GTIN__c;
                    addedItems.add(a);
                }
            }
            ScannedOrderItemsResult result = new ScannedOrderItemsResult();
            result.addedItems = addedItems;
            result.failedItems = failedItems;
            
            return result;
        }catch (AuraHandledException ahe) {
            throw ahe; // preserve original message
        }catch (Exception e) {
            System.debug('Error in createVisitJobsFromScannedData: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ScannedOrderItemsResult createOrderItemsFromScannedData(String scannedValues, Id orderId) {
        if (String.isBlank(scannedValues)) {
            throw new AuraHandledException('No scanned values received.');
        }
        Map<String, Integer> gtinCountMap = new Map<String, Integer>();
        for (String val : scannedValues.split('[,\\n]+')) {
            String trimmed = val != null ? val.trim() : null;
            if (!String.isBlank(trimmed)) {
                gtinCountMap.put(trimmed, gtinCountMap.containsKey(trimmed) ? gtinCountMap.get(trimmed) + 1 : 1);
            }
        }
        if (gtinCountMap.isEmpty()) {
            throw new AuraHandledException('No valid barcodes found.');
        }

        List<cgcloud__Unit_of_Measure__c> uomList = [
            SELECT Id, cgcloud__GTIN__c, cgcloud__Unit_Type__c,
                   cgcloud__Product__c, cgcloud__Product__r.Name,cgcloud__Pieces_per_Smallest_Unit__c
            FROM cgcloud__Unit_of_Measure__c
            WHERE cgcloud__GTIN__c IN :gtinCountMap.keySet() and cgcloud__Unit_Type__c IN ('ConsumerUnit', 'SalesUnit')  
        ];

        // Build matched/failed lists
        Set<String> matchedGtins = new Set<String>();
        Set<Id> productIds = new Set<Id>();
        for (cgcloud__Unit_of_Measure__c u : uomList) {
            matchedGtins.add(u.cgcloud__GTIN__c);
            productIds.add(u.cgcloud__Product__c);
        }


        // Build Product → Carton Pieces map (only SalesUnit records)
        Map<Id, Integer> productToPiecesMap = new Map<Id, Integer>();
        for (cgcloud__Unit_of_Measure__c u : uomList) {
            if (u.cgcloud__Unit_Type__c == 'SalesUnit') {
                Integer pcs = (u.cgcloud__Pieces_per_Smallest_Unit__c != null)
                                ? Integer.valueOf(u.cgcloud__Pieces_per_Smallest_Unit__c)
                                : 0;
                productToPiecesMap.put(u.cgcloud__Product__c, pcs);
            }
        }

        // Identify products missing carton pieces
        Set<Id> missingSalesUnitProducts = new Set<Id>();
        for (Id prodId : productIds) {
            if (!productToPiecesMap.containsKey(prodId)) {
                missingSalesUnitProducts.add(prodId);
            }
        }
        // Fetch SalesUnit UOMs for missing products (do NOT add to uomList)
        if (!missingSalesUnitProducts.isEmpty()) {
            List<cgcloud__Unit_of_Measure__c> extraSalesUoms = [
                SELECT cgcloud__Product__c, cgcloud__Pieces_per_Smallest_Unit__c
                FROM cgcloud__Unit_of_Measure__c
                WHERE cgcloud__Unit_Type__c = 'SalesUnit'
                AND cgcloud__Product__c IN :missingSalesUnitProducts
            ];
            for (cgcloud__Unit_of_Measure__c su : extraSalesUoms) {
                Integer pcs = su.cgcloud__Pieces_per_Smallest_Unit__c != null ?
                                Integer.valueOf(su.cgcloud__Pieces_per_Smallest_Unit__c) : 0;
                productToPiecesMap.put(su.cgcloud__Product__c, pcs);
            }
        }


        

        cgcloud__Order__c order = [SELECT ID, cgcloud__Bill_Recipient_Account__r.ShippingState FROM cgcloud__Order__c WHERE ID=: orderId];

        

        List<cgcloud__Inventory__c> inventories = [SELECT Id, TPB_AvgPrice__c, cgcloud__User__c, cgcloud__product__c,
                                                   cgcloud__Balance__c  
                                                   FROM cgcloud__Inventory__c WHERE cgcloud__User__c =: UserInfo.getUserId() AND Active_User__c = true AND cgcloud__product__c IN: productIds AND TPB_Tour_State__c = :order.cgcloud__Bill_Recipient_Account__r.ShippingState]; //AND cgcloud__Tour__c = : visit.Account.ShippingState
        Map<Id, cgcloud__Inventory__c> productInvMap = new Map<Id, cgcloud__Inventory__c>();
        for(cgcloud__Inventory__c inventory: inventories){
            productInvMap.put(inventory.cgcloud__product__c, inventory);
        }


        List<FailedItemWrapper> failedItems = new List<FailedItemWrapper>();
        for (String gtin : gtinCountMap.keySet()) {
            if (!matchedGtins.contains(gtin)) {
                FailedItemWrapper f = new FailedItemWrapper();
                f.gtin = gtin;
                f.quantity = gtinCountMap.get(gtin);
                failedItems.add(f);
            }
        }
        Id cashSaleTemplateId = [
            SELECT Id FROM cgcloud__Order_Item_Template__c 
            WHERE Name = 'Cash Sale' 
            LIMIT 1
        ].Id;
        Map<String, cgcloud__Order_Item__c> existingOrderItemsMap = new Map<String, cgcloud__Order_Item__c>();
        for (cgcloud__Order_Item__c item : [
            SELECT Id, cgcloud__Product__c, cgcloud__UoM__c, cgcloud__Quantity__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__c = :orderId AND cgcloud__Order_Item_Template__c =: cashSaleTemplateId
        ]) {
            String key = item.cgcloud__Product__c + '_' + item.cgcloud__UoM__c;
            existingOrderItemsMap.put(key, item);
        }
        List<cgcloud__Order_Item__c> orderItemsToInsert = new List<cgcloud__Order_Item__c>();
        List<cgcloud__Order_Item__c> orderItemsToUpdate = new List<cgcloud__Order_Item__c>();
        List<AddedItemWrapper> addedItems = new List<AddedItemWrapper>();
        for (cgcloud__Unit_of_Measure__c uom : uomList) {

            
            Integer qty = gtinCountMap.get(uom.cgcloud__GTIN__c);
            String finalUomType;
            Double basePriceVal = (productInvMap.containsKey(uom.cgcloud__Product__c)) ? productInvMap.get(uom.cgcloud__Product__c).TPB_AvgPrice__c : 0;
            Double calculatedValue;
            if (uom.cgcloud__Unit_Type__c == 'SalesUnit') {
                finalUomType = 'Carton';
                calculatedValue = basePriceVal * qty;  // price per carton × cartons
            } else if (uom.cgcloud__Unit_Type__c == 'ConsumerUnit') {
                finalUomType = 'Each';
                Integer cartonPieces = (productToPiecesMap.containsKey(uom.cgcloud__Product__c)) ? productToPiecesMap.get(uom.cgcloud__Product__c) : 0;
                Double piecePrice = (basePriceVal > 0 && cartonPieces > 0)
                                 ? (basePriceVal / cartonPieces)
                                 : 0;
                calculatedValue = piecePrice * qty;
                basePriceVal = piecePrice;  // base price per piece stored
            }
            String mapKey = uom.cgcloud__Product__c + '_' + finalUomType;
            if (existingOrderItemsMap.containsKey(mapKey)) {
                cgcloud__Order_Item__c existingItem = existingOrderItemsMap.get(mapKey);
                existingItem.cgcloud__Quantity__c += qty;
                orderItemsToUpdate.add(existingItem);
            } else {
                cgcloud__Order_Item__c newLineItem = new cgcloud__Order_Item__c();
                newLineItem.cgcloud__Order__c = orderId;
                newLineItem.cgcloud__Product__c = uom.cgcloud__Product__c;
                newLineItem.cgcloud__Quantity__c = qty;
                newLineItem.cgcloud__UoM__c = finalUomType;
                newLineItem.cgcloud__Erp_Id__c = '10';
                newLineItem.cgcloud__History__c = true;
                newLineItem.cgcloud__Listed__c = false;
                newLineItem.cgcloud__Discount__c = 0;
                newLineItem.cgcloud__Value__c = 0;
                newLineItem.cgcloud__Order_Item_Template__c = cashSaleTemplateId;

                newLineItem.cgcloud__Base_Price__c = basePriceVal;
                newLineItem.cgcloud__Base_Price_Receipt__c = basePriceVal;
                newLineItem.cgcloud__Gross_Value_Receipt__c = calculatedValue;
                newLineItem.cgcloud__Pricing_Info_1__c = calculatedValue;
                newLineItem.cgcloud__Value__c = calculatedValue;
                newLineItem.cgcloud__Value_Receipt__c = calculatedValue;
            
                orderItemsToInsert.add(newLineItem);
            }
            AddedItemWrapper a = new AddedItemWrapper();
            a.productName = uom.cgcloud__Product__r.Name;
            a.gtin = finalUomType;
            a.quantity = qty;
            addedItems.add(a);
        }
        if (!orderItemsToInsert.isEmpty()) insert orderItemsToInsert;
        if (!orderItemsToUpdate.isEmpty()) update orderItemsToUpdate;
        TPB_OnlineAppController.updateOrder(orderId);
        ScannedOrderItemsResult result = new ScannedOrderItemsResult();
        result.addedItems = addedItems;
        result.failedItems = failedItems;
        return result;
    }

    public class ScannedOrderItemsResult {
        @AuraEnabled public List<AddedItemWrapper> addedItems;
        @AuraEnabled public List<FailedItemWrapper> failedItems;
    }

    public class AddedItemWrapper {
        @AuraEnabled public String productName;
        @AuraEnabled public String gtin;
        @AuraEnabled public Integer quantity;
    }

    public class FailedItemWrapper {
        @AuraEnabled public String gtin;
        @AuraEnabled public Integer quantity;
        @AuraEnabled public String reason;
    }



   
    
    
}