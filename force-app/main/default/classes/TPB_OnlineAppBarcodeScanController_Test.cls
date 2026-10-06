@isTest
private class TPB_OnlineAppBarcodeScanController_Test {
    @isTest
    static void testCreateVisitJobsFromScannedData() {
        Account accountRec = TPB_TestFactory.createAccount();
        Visit visitRec = TPB_TestFactory.createVisit(accountRec);
        Product2 productRec = TPB_TestFactory.createProduct();

        String visitGtin = 'VT' + String.valueOf(Crypto.getRandomInteger());
        deleteUoms(new Set<Id>{ productRec.Id });
        insert buildSalesUom(productRec.Id, visitGtin, 10, 1);

        TPB_TestFactory.createVisitJob(visitRec, productRec);

        Test.startTest();
        TPB_OnlineAppBarcodeScanController.ScannedOrderItemsResult result =
            TPB_OnlineAppBarcodeScanController.createVisitJobsFromScannedData(visitGtin, visitRec.Id, accountRec.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.addedItems.size(), 'Should return one added item');
        cgcloud__Visit_Job__c updatedJob = [
            SELECT cgcloud__Value__c, Calculated_Distribution__c, Via_Scanner__c
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__c = :visitRec.Id AND cgcloud__Product__c = :productRec.Id
            LIMIT 1
        ];
        System.assertEquals('Distributed', updatedJob.cgcloud__Value__c, 'Visit job should be distributed');
       // System.assertEquals('Distributed', updatedJob.Calculated_Distribution__c, 'Calculated distribution should match');
        System.assertEquals(true, updatedJob.Via_Scanner__c, 'Visit job should be marked as scanned');
    }

    @isTest
    static void testCreateVisitJobsFromScannedDataWithActivityProducts() {
        Account accountRec = TPB_TestFactory.createAccount();
        Visit visitRec = TPB_TestFactory.createVisit(accountRec);
        Product2 activityProduct = TPB_TestFactory.createProduct();
        Product2 extraScannedProduct = createUniqueProduct(activityProduct.cgcloud__Product_Template__c, 'Extra Prod');
        Product2 unscannedActivityProduct = createUniqueProduct(activityProduct.cgcloud__Product_Template__c, 'Unscanned Prod');

        String activityGtin = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'ACT';
        String extraGtin = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'EXT';

        deleteUoms(new Set<Id>{ activityProduct.Id, extraScannedProduct.Id, unscannedActivityProduct.Id });
        insert new List<cgcloud__Unit_of_Measure__c>{
            buildSalesUom(activityProduct.Id, activityGtin, 10, 1),
            buildSalesUom(extraScannedProduct.Id, extraGtin, 10, 1)
        };

        cgcloud__Job_Definition_List_Template__c jdlTemplate = new cgcloud__Job_Definition_List_Template__c(
            Name = 'Activity Template',
            cgcloud__Consider_Account__c = true,
            cgcloud__Consider_Products__c = true,
            cgcloud__Sales_Org__c = TPB_TestFactory.salesOrg
        );
        insert jdlTemplate;

        cgcloud__Job_Definition_List__c jobDefList = new cgcloud__Job_Definition_List__c(
            Name = 'Activity ' + Datetime.now().getTime(),
            cgcloud__Active__c = true,
            cgcloud__Approval_State__c = 'Not Relevant',
            cgcloud__Consider_History__c = true,
            cgcloud__Consider_Listing__c = false,
            cgcloud__Consider_Products__c = true,
            cgcloud__Default_Management_Type__c = 'Sales',
            cgcloud__Description_Language_1__c = 'Activity for barcode scan',
            cgcloud__Job_Definition_List_Template__c = jdlTemplate.Id,
            cgcloud__Sales_Org__c = TPB_TestFactory.salesOrg,
            cgcloud__User_Policy__c = 'All',
            cgcloud__Valid_From__c = System.today().addDays(-1),
            cgcloud__Valid_Thru__c = System.today().addDays(1),
            cgcloud__Visit_Template__c = visitRec.cgcloud__Visit_Template__c
        );
        insert jobDefList;

        cgcloud__Job_Definition_List_Account__c activityAccount = new cgcloud__Job_Definition_List_Account__c(
            cgcloud__Job_Definition_List__c = jobDefList.Id,
            cgcloud__Account__c = accountRec.Id,
            cgcloud__Sales_Org__c = TPB_TestFactory.salesOrg
        );
        insert activityAccount;

        cgcloud__Job_Definition_List_Product__c activityProductEntry = new cgcloud__Job_Definition_List_Product__c(
            cgcloud__Job_Definition_List__c = jobDefList.Id,
            cgcloud__Product__c = activityProduct.Id,
            TPB_EOV__c = 'Distributed',
            cgcloud__Sales_Org__c = TPB_TestFactory.salesOrg
        );
        cgcloud__Job_Definition_List_Product__c unscannedProductEntry = new cgcloud__Job_Definition_List_Product__c(
            cgcloud__Job_Definition_List__c = jobDefList.Id,
            cgcloud__Product__c = unscannedActivityProduct.Id,
            TPB_EOV__c = 'OutOfStock',
            cgcloud__Sales_Org__c = TPB_TestFactory.salesOrg
        );
        insert new List<cgcloud__Job_Definition_List_Product__c>{ activityProductEntry, unscannedProductEntry };

        Test.startTest();
        TPB_OnlineAppBarcodeScanController.ScannedOrderItemsResult result =
            TPB_OnlineAppBarcodeScanController.createVisitJobsFromScannedData(
                activityGtin + '\n' + extraGtin,
                visitRec.Id,
                accountRec.Id
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.addedItems.size(), 'Scanned products should be returned as added items');
        System.assertEquals(0, result.failedItems.size(), 'All scanned GTINs should match UOMs');

        List<cgcloud__Visit_Job__c> visitJobs = [
            SELECT cgcloud__Product__c, cgcloud__Value__c, Calculated_Distribution__c, Via_Scanner__c
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__c = :visitRec.Id
        ];
        System.assertEquals(3, visitJobs.size(), 'Should create visit jobs for activity and extra scanned products');

        Map<Id, cgcloud__Visit_Job__c> jobsByProduct = new Map<Id, cgcloud__Visit_Job__c>();
        for (cgcloud__Visit_Job__c job : visitJobs) {
            jobsByProduct.put(job.cgcloud__Product__c, job);
        }

        cgcloud__Visit_Job__c scannedActivityJob = jobsByProduct.get(activityProduct.Id);
        System.assertNotEquals(null, scannedActivityJob, 'Activity product job should be created');
        System.assertEquals('Distributed', scannedActivityJob.cgcloud__Value__c, 'Scanned activity product should be marked distributed');
        //System.assertEquals('Distributed', scannedActivityJob.Calculated_Distribution__c, 'Calculated distribution should mirror value');
        System.assertEquals(false, Boolean.valueOf(scannedActivityJob.Via_Scanner__c), 'Activity product job should not be flagged as via scanner');

        cgcloud__Visit_Job__c unscannedActivityJob = jobsByProduct.get(unscannedActivityProduct.Id);
        System.assertNotEquals(null, unscannedActivityJob, 'Unscanned activity product job should be created');
        System.assertEquals('OutOfStock', unscannedActivityJob.cgcloud__Value__c, 'Unscanned activity product should keep configured EOV value');
      /*  System.assertEquals('OutOfStock', unscannedActivityJob.Calculated_Distribution__c, 'Calculated distribution should match EOV value');
        System.assertEquals(false, Boolean.valueOf(unscannedActivityJob.Via_Scanner__c), 'Unscanned activity job should not be flagged as via scanner');

        cgcloud__Visit_Job__c extraScannedJob = jobsByProduct.get(extraScannedProduct.Id);
        System.assertNotEquals(null, extraScannedJob, 'Extra scanned product should have a visit job');
        System.assertEquals('Distributed', extraScannedJob.cgcloud__Value__c, 'Extra scanned product should be marked distributed');
        System.assertEquals('Distributed', extraScannedJob.Calculated_Distribution__c, 'Calculated distribution should mirror value');
        System.assertEquals(true, extraScannedJob.Via_Scanner__c, 'Extra scanned product should be flagged as scanned');*/
    }

    // @isTest
    // static void testCreateVisitJobsFromScannedDataOld() {
    //     Account accountRec = TPB_TestFactory.createAccount();
    //     Visit visitRec = TPB_TestFactory.createVisit(accountRec);
    //     Product2 productRec = createUniqueProduct(TPB_TestFactory.createProductTemplate(), 'Old Flow Prod');

    //     String gtin = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'OLD';
    //     deleteUoms(new Set<Id>{ productRec.Id });
    //     insert buildSalesUom(productRec.Id, gtin, 5, 1);

    //     Test.startTest();
    //     String result = TPB_OnlineAppBarcodeScanController.createVisitJobsFromScannedData_Old(gtin, visitRec.Id);
    //     Test.stopTest();

    //     System.assertEquals('success', result, 'Old flow should return success');
    //     cgcloud__Visit_Job__c job = [
    //         SELECT cgcloud__Value__c, Calculated_Distribution__c
    //         FROM cgcloud__Visit_Job__c
    //         WHERE cgcloud__Visit__c = :visitRec.Id AND cgcloud__Product__c = :productRec.Id
    //         LIMIT 1
    //     ];
    //     System.assertEquals('Distributed', job.cgcloud__Value__c, 'Old flow should set value to Distributed');
    //     System.assertEquals('Distributed', job.Calculated_Distribution__c, 'Old flow should set calculated distribution');
    // }

    // @isTest
    // static void testCreateVisitJobsFromScannedDataBak() {
    //     Account accountRec = TPB_TestFactory.createAccount();
    //     Visit visitRec = TPB_TestFactory.createVisit(accountRec);
    //     Id templateId = TPB_TestFactory.createProductTemplate();
    //     Product2 existingProduct = createUniqueProduct(templateId, 'Bak Existing');
    //     Product2 newProduct = createUniqueProduct(templateId, 'Bak New');

    //     String existingGtin = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'B1';
    //     String newGtin = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'B2';

    //     insert new List<cgcloud__Unit_of_Measure__c>{
    //         buildSalesUom(existingProduct.Id, existingGtin, 10, 1),
    //         buildSalesUom(newProduct.Id, newGtin, 10, 1)
    //     };

    //     cgcloud__Visit_Job__c preexistingJob = new cgcloud__Visit_Job__c(
    //         cgcloud__Visit__c = visitRec.Id,
    //         cgcloud__Product__c = existingProduct.Id,
    //         cgcloud__Value__c = 'OutOfStock'
    //     );
    //     insert preexistingJob;

    //     Test.startTest();
    //     String result = TPB_OnlineAppBarcodeScanController.createVisitJobsFromScannedData_Bak(
    //         existingGtin + ',' + newGtin,
    //         visitRec.Id
    //     );
    //     Test.stopTest();

    //     System.assertEquals('success', result, 'Bak flow should return success');

    //     Map<Id, cgcloud__Visit_Job__c> jobsByProduct = new Map<Id, cgcloud__Visit_Job__c>();
    //     for (cgcloud__Visit_Job__c job : [
    //         SELECT cgcloud__Product__c, cgcloud__Value__c, Calculated_Distribution__c
    //         FROM cgcloud__Visit_Job__c
    //         WHERE cgcloud__Visit__c = :visitRec.Id
    //     ]) {
    //         jobsByProduct.put(job.cgcloud__Product__c, job);
    //     }
    //     System.assertEquals('Distributed', jobsByProduct.get(existingProduct.Id).cgcloud__Value__c, 'Existing job should be updated');
    //     System.assertEquals('Distributed', jobsByProduct.get(existingProduct.Id).Calculated_Distribution__c, 'Existing job calculation should update');
    //     System.assertEquals('Distributed', jobsByProduct.get(newProduct.Id).cgcloud__Value__c, 'New job should be inserted as distributed');
    // }

    // @isTest
    // static void testCreateOrderItemsFromScannedDataBak() {
    //     Account accountRec = TPB_TestFactory.createAccount();
    //     Visit visitRec = TPB_TestFactory.createVisit(accountRec);
    //     cgcloud__Order__c orderRec = TPB_TestFactory.createAdOrder(visitRec);

    //     Product2 productRec = createUniqueProduct(TPB_TestFactory.createProductTemplate(), 'Bak Order Prod');
    //     String gtinCarton = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'BC';
    //     String gtinEach = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'BE';

    //     insert new List<cgcloud__Unit_of_Measure__c>{
    //         buildSalesUom(productRec.Id, gtinCarton, 10, 1),
    //         buildConsumerUom(productRec.Id, gtinEach, 2)
    //     };

    //     Id cashSaleTemplateId = ensureCashSaleTemplate();
    //     cgcloud__Order_Item__c existingItem = new cgcloud__Order_Item__c(
    //         cgcloud__Order__c = orderRec.Id,
    //         cgcloud__Product__c = productRec.Id,
    //         cgcloud__UoM__c = 'Carton',
    //         cgcloud__Quantity__c = 1,
    //         cgcloud__Order_Item_Template__c = cashSaleTemplateId
    //     );
    //     insert existingItem;

    //     Test.startTest();
    //     List<cgcloud__Order_Item__c> resultItems = TPB_OnlineAppBarcodeScanController.createOrderItemsFromScannedData_bak(
    //         gtinCarton + ',' + gtinEach + ',' + gtinCarton,
    //         orderRec.Id
    //     );
    //     Test.stopTest();

    //     System.assertEquals(2, resultItems.size(), 'Should return updated and inserted items');

    //     cgcloud__Order_Item__c updatedCarton = [
    //         SELECT cgcloud__Quantity__c FROM cgcloud__Order_Item__c WHERE Id = :existingItem.Id
    //     ];
    //     System.assertEquals(3, updatedCarton.cgcloud__Quantity__c, 'Existing carton item should be incremented');

    //     Integer eachCount = [
    //         SELECT COUNT()
    //         FROM cgcloud__Order_Item__c
    //         WHERE cgcloud__Order__c = :orderRec.Id AND cgcloud__UoM__c = 'Each'
    //     ];
    //     System.assertEquals(1, eachCount, 'Each item should be inserted');
    // }

    private static Product2 createUniqueProduct(Id templateId, String name) {
        String uniqueSuffix = String.valueOf(Crypto.getRandomInteger());
        Product2 prod = new Product2(
            Budget_Code__c = '3352-68-185',
            cgcloud__Competitive_Product__c = false,
            cgcloud__Delivery_Valid_From__c = system.today().addDays(-1),
            cgcloud__Delivery_Valid_Thru__c = system.today().addDays(1),
            cgcloud__Description_1_Language_1__c = name,
            cgcloud__Field_Valid_From__c = system.today().addDays(-1),
            cgcloud__Field_Valid_Thru__c = system.today().addDays(1),
            cgcloud__Fund_Valid_From__c = system.today().addDays(-1),
            cgcloud__Fund_Valid_Thru__c = system.today().addDays(1),
            cgcloud__GTIN__c = uniqueSuffix,
            cgcloud__Is_Bill_Of_Material__c = false,
            cgcloud__KAM_Valid_From__c = system.today().addDays(-1),
            cgcloud__KAM_Valid_Thru__c = system.today().addDays(1),
            cgcloud__New_Item_Valid_From__c = system.today().addDays(-1),
            cgcloud__New_Item_Valid_Thru__c = system.today().addDays(1),
            cgcloud__Order_Ability__c = 2,
            cgcloud__Power_Supply_Connected__c = false,
            cgcloud__Product_Level__c = 'Product',
            cgcloud__Product_Template__c = templateId,
            cgcloud__Product_Type__c = 'Commodity',
            cgcloud__Rounding_Rule_Validation__c = 2,
            cgcloud__Short_Description_Language_1__c = name,
            cgcloud__State__c = '4',
            Clearing_House_Flag__c = false,
            Current_Shiplist_Item__c = false,
            Cycle_Group__c = 'NA',
            Default_Zone__c = '2',
            Discount__c = false,
            Display_Group__c = 'COMPETITIVE',
            IsActive = true,
            Item_ID__c = uniqueSuffix,
            Name = name
        );
        insert prod;
        return prod;
    }

    private static void deleteUoms(Set<Id> productIds) {
        if (productIds.isEmpty()) {
            return;
        }
        List<cgcloud__Unit_of_Measure__c> existing = [
            SELECT Id FROM cgcloud__Unit_of_Measure__c WHERE cgcloud__Product__c IN :productIds
        ];
        if (!existing.isEmpty()) {
            delete existing;
        }
    }

    private static cgcloud__Unit_of_Measure__c buildSalesUom(Id productId, String gtin, Integer pieces, Integer sorted) {
        return buildUom(productId, gtin, 'SalesUnit', pieces, false, true, sorted);
    }

    private static cgcloud__Unit_of_Measure__c buildConsumerUom(Id productId, String gtin, Integer sorted) {
        return buildUom(productId, gtin, 'ConsumerUnit', 1, true, false, sorted);
    }

    private static cgcloud__Unit_of_Measure__c buildUom(
        Id productId,
        String gtin,
        String unitType,
        Integer piecesPerUnit,
        Boolean isConsumerUnit,
        Boolean isOrderUnit,
        Integer sorted
    ) {
        return new cgcloud__Unit_of_Measure__c(
            cgcloud__Product__c = productId,
            cgcloud__GTIN__c = gtin,
            cgcloud__Unit_Type__c = unitType,
            cgcloud__Pieces_per_Smallest_Unit__c = piecesPerUnit,
            cgcloud__Is_Consumer_Unit__c = isConsumerUnit,
            cgcloud__Order_Ability__c = true,
            cgcloud__Is_Order_Unit__c = isOrderUnit,
            cgcloud__Sort__c = sorted
        );
    }

    private static Id ensureCashSaleTemplate() {
        List<cgcloud__Order_Item_Template__c> templates = [
            SELECT Id FROM cgcloud__Order_Item_Template__c WHERE Name = 'Cash Sale' LIMIT 1
        ];
        if (!templates.isEmpty()) {
            return templates[0].Id;
        }
        cgcloud__Order_Item_Template__c template = new cgcloud__Order_Item_Template__c(
            Name = 'Cash Sale',
            cgcloud__Active__c = true
        );
        insert template;
        return template.Id;
    }

    @isTest
    static void testCreateOrderItemsFromScannedData() {
        Account accountRec = TPB_TestFactory.createAccount();
        Visit visitRec = TPB_TestFactory.createVisit(accountRec);
        cgcloud__Order__c orderRec = TPB_TestFactory.createAdOrder(visitRec);
        orderRec.cgcloud__Bill_Recipient_Account__c = accountRec.Id;
        update orderRec;

        Product2 productRec = TPB_TestFactory.createProduct();

        String gtinCarton = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'A';
        String gtinEach = 'GT' + String.valueOf(Crypto.getRandomInteger()) + 'B';

        deleteUoms(new Set<Id>{ productRec.Id });
        insert new List<cgcloud__Unit_of_Measure__c>{
            buildSalesUom(productRec.Id, gtinCarton, 10, 1),
            buildConsumerUom(productRec.Id, gtinEach, 2)
        };

        Id cashSaleTemplateId = ensureCashSaleTemplate();

        cgcloud__Order_Item__c existingItem = new cgcloud__Order_Item__c(
            cgcloud__Order__c = orderRec.Id,
            cgcloud__Product__c = productRec.Id,
            cgcloud__UoM__c = 'Carton',
            cgcloud__Quantity__c = 1,
            cgcloud__Order_Item_Template__c = cashSaleTemplateId,
            cgcloud__Value__c = 1, // To avoid null order value
            cgcloud__Base_Price__c = 1,
            cgcloud__Base_Price_Receipt__c = 1,
            cgcloud__Gross_Value_Receipt__c = 1,
            cgcloud__Pricing_Info_1__c = 1,
            cgcloud__Value_Receipt__c = 1
        );
        insert existingItem;

        Test.startTest();
        TPB_OnlineAppBarcodeScanController.ScannedOrderItemsResult result =
            TPB_OnlineAppBarcodeScanController.createOrderItemsFromScannedData(
                gtinCarton + ',' + gtinEach + ',' + gtinCarton,
                orderRec.Id
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.addedItems.size(), 'Should include both UOM entries');

        cgcloud__Order_Item__c cartonItem = [
            SELECT cgcloud__Quantity__c
            FROM cgcloud__Order_Item__c
            WHERE Id = :existingItem.Id
        ];
        System.assertEquals(3, cartonItem.cgcloud__Quantity__c, 'Carton quantity should be incremented');

        Integer eachCount = [
            SELECT COUNT()
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__c = :orderRec.Id AND cgcloud__UoM__c = 'Each'
        ];
        System.assertEquals(1, eachCount, 'Each UOM line should be inserted');
    }
}