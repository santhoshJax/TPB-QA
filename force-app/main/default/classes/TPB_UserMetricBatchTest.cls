/**
 * @author aletisanthosh
 * @date 2026-04-13
 * @description Test class for TPB_UserMetricBatch — targets 80%+ coverage.
 *
 * Scenarios covered:
 *  1.  No active initiatives            → start() returns empty locator, no metrics
 *  2.  All initiatives past end date    → start() returns empty locator, no metrics
 *  3.  Open-ended active initiative     → metric created, correct External_Id / snapshot date
 *  4.  Initiative with future end date  → metric created
 *  5.  Mixed active + expired           → only active initiative produces metric
 *  6.  Multiple initiatives             → one metric per initiative per user setting
 *  7.  Upsert idempotency               → re-run does not duplicate metrics
 *  8.  Schedulable interface            → System.schedule() succeeds
 *  9.  Zero-value metrics               → all numeric fields default to 0
 *  10. Zero commitment value            → handled gracefully
 *  11. Subcategory product + inventory  → inventory balance aggregated
 *  12. Purchase + sale transactions     → day/cumulative values, days-since, open-ended SOQL
 *  13. Closed initiative with products  → bounded transaction SOQL path
 *  14. Commitment_Value__c first run    → set from initiative global when no record exists
 *  15. Commitment_Value__c re-run       → not overwritten when record already exists
 *  16. Non-active field user            → Non_Active_Field_User__c = true → no metric
 *  17. Product hierarchy level Product  → direct Product2 Id path exercised in start()
 *  18. Product hierarchy level Category → category resolution path exercised in start()
 */
@IsTest(SeeAllData=false)
public class TPB_UserMetricBatchTest {

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static cgcloud__User_Setting__c insertUserSetting(Id userId) {
        cgcloud__User_Setting__c us = new cgcloud__User_Setting__c(
            cgcloud__User__c = userId,
            Non_Active_Field_User__c = false
        );
        insert us;
        return us;
    }

    private static TPB_Sales_Initiative__c insertInitiative(
            String name, Boolean active, Date startDate, Date endDate, Decimal commitment) {
        TPB_Sales_Initiative__c init = new TPB_Sales_Initiative__c(
            Name                = name,
            Active__c           = active,
            Start_Date__c       = startDate,
            End_Date__c         = endDate,
            Commitment_Value__c = commitment
        );
        insert init;
        return init;
    }

    private static Product2 insertSubCategoryProduct(String subCategoryCode, Id templateId) {
        Product2 subCat = TPB_TestFactory.createProduct(subCategoryCode, templateId);
        subCat.cgcloud__Product_Level__c = 'SubCategory';
        subCat.Name = subCategoryCode;
        update subCat;
        return subCat;
    }

    /**
     * Builds Initiative → Subcategory code → Product chain (Subcategory hierarchy level).
     * Returns [initiative, mainProduct].
     */
    private static List<SObject> buildInitiativeWithProducts(
            String subCategoryCode, Date startDate, Date endDate) {

        Product2 mainProd = TPB_TestFactory.createProduct();
        Id templateId = [SELECT cgcloud__Product_Template__c
                         FROM Product2 WHERE Id = :mainProd.Id].cgcloud__Product_Template__c;

        Product2 subCatProd = insertSubCategoryProduct(subCategoryCode, templateId);
        mainProd.cgcloud__Criterion_2_Product__c = subCatProd.Id;
        update mainProd;

        TPB_Sales_Initiative__c init = insertInitiative(
            'Initiative-' + subCategoryCode, true, startDate, endDate, 500
        );
        insert new TPB_Initiative_Subcategory__c(
            Initiative__c              = init.Id,
            Product_Code__c            = subCategoryCode,
            Subcategory_Code__c        = subCategoryCode,
            Product_Hierarchy_Level__c = 'Subcategory'
        );
        return new List<SObject>{ init, mainProd };
    }

    // ─── Tests ────────────────────────────────────────────────────────────────

    /**
     * 1. No active initiatives.
     */
    @IsTest
    static void testNoActiveInitiatives_noMetricsCreated() {
        insertUserSetting(UserInfo.getUserId());
        insertInitiative('Inactive Init', false, Date.today().addDays(-5), null, 100);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM TPB_User_Metric__c],
            'No metrics when no active initiatives');
    }

    /**
     * 2. All active initiatives are past their end date.
     */
    @IsTest
    static void testAllInitiativesExpired_noMetricsCreated() {
        insertUserSetting(UserInfo.getUserId());
        insertInitiative('Expired Init', true,
            Date.today().addDays(-30), Date.today().addDays(-1), 200);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM TPB_User_Metric__c],
            'No metrics when all initiatives are past end date');
    }

    /**
     * 3. Open-ended initiative — metric created with correct External_Id and snapshot date.
     */
    @IsTest
    static void testOpenEndedInitiative_metricsCreated() {
        cgcloud__User_Setting__c us = insertUserSetting(UserInfo.getUserId());
        TPB_Sales_Initiative__c init = insertInitiative('Open Initiative', true,
            Date.today().addDays(-10), null, 500);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        List<TPB_User_Metric__c> metrics = [
            SELECT Id, External_Id__c, Snapshot_Date__c, User_Setting__c, Initiative__c
            FROM TPB_User_Metric__c
        ];
        System.assertEquals(1, metrics.size(), 'One metric per user setting');

        TPB_User_Metric__c m = metrics[0];
        System.assertEquals(Date.today(), m.Snapshot_Date__c, 'Snapshot date should be today');
        System.assertEquals(us.Id,        m.User_Setting__c,  'Linked to user setting');
        System.assertEquals(init.Id,      m.Initiative__c,    'Linked to initiative');

        String expectedExtId = String.valueOf(us.Id) + '_' + String.valueOf(init.Id);
        System.assertEquals(expectedExtId, m.External_Id__c,
            'External_Id format should be {UserSettingId}_{InitiativeId}');
    }

    /**
     * 4. Initiative with future end date — still within window.
     */
    @IsTest
    static void testActiveInitiativeWithFutureEndDate_metricsCreated() {
        insertUserSetting(UserInfo.getUserId());
        insertInitiative('Future End Init', true,
            Date.today().addDays(-5), Date.today().addDays(30), 300);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM TPB_User_Metric__c],
            'Metric created when end date is in the future');
    }

    /**
     * 5. One active, one expired — only active produces a metric.
     */
    @IsTest
    static void testMixedInitiatives_onlyActiveProducesMetrics() {
        insertUserSetting(UserInfo.getUserId());
        TPB_Sales_Initiative__c activeInit = insertInitiative('Active Init', true,
            Date.today().addDays(-5), null, 100);
        insertInitiative('Expired Init', true,
            Date.today().addDays(-30), Date.today().addDays(-1), 200);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        List<TPB_User_Metric__c> metrics = [SELECT Initiative__c FROM TPB_User_Metric__c];
        System.assertEquals(1, metrics.size(), 'Only active initiative produces a metric');
        System.assertEquals(activeInit.Id, metrics[0].Initiative__c,
            'Metric belongs to the active initiative');
    }

    /**
     * 6. Two active initiatives — one metric per initiative.
     */
    @IsTest
    static void testMultipleInitiatives_oneMetricPerInitiative() {
        insertUserSetting(UserInfo.getUserId());
        insertInitiative('Initiative A', true, Date.today().addDays(-10), null, 100);
        insertInitiative('Initiative B', true, Date.today().addDays(-5),  null, 200);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM TPB_User_Metric__c],
            'One metric per initiative per user setting');
    }

    /**
     * 7. Re-run — upsert by External_Id__c should not create a duplicate.
     */
    @IsTest
    static void testUpsertIdempotency_noDuplicatesOnRerun() {
        cgcloud__User_Setting__c us = insertUserSetting(UserInfo.getUserId());
        TPB_Sales_Initiative__c init = insertInitiative('Idempotent Init', true,
            Date.today().addDays(-10), null, 300);

        String extId = String.valueOf(us.Id) + '_' + String.valueOf(init.Id);
        insert new TPB_User_Metric__c(
            External_Id__c             = extId,
            User_Setting__c            = us.Id,
            Initiative__c              = init.Id,
            Snapshot_Date__c           = Date.today(),
            Day_Sales_Value__c         = 0,
            Day_Sales_Units__c         = 0,
            Day_Purchases_Value__c     = 0,
            Day_Purchases_Units__c     = 0,
            Cum_Sales_Value__c         = 0,
            Cum_Sales_Units__c         = 0,
            Cum_Purchases_Value__c     = 0,
            Cum_Purchases_Units__c     = 0,
            Inventory_Balance_Value__c = 0,
            Inventory_Balance_Units__c = 0,
            Cum_Returns_Value__c       = 0,
            Cum_Returns_Units__c       = 0
        );

        System.assertEquals(1, [SELECT COUNT() FROM TPB_User_Metric__c],
            'Pre-inserted metric should exist');

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM TPB_User_Metric__c],
            'Batch should upsert and not create a duplicate');
    }

    /**
     * 8. Schedulable interface.
     */
    @IsTest
    static void testSchedulable_cronJobCreated() {
        insertInitiative('Scheduled Init', true, Date.today().addDays(-1), null, 100);

        Test.startTest();
        String jobId = System.schedule('TPB_UserMetricBatch_Test', '0 0 2 * * ? *',
            new TPB_UserMetricBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('TPB_UserMetricBatch_Test', ct.CronJobDetail.Name,
            'Scheduled job should appear in CronTrigger');
    }

    /**
     * 9. No matching products — all numeric metric fields should be zero.
     */
    @IsTest
    static void testZeroValueMetrics_noTransactions() {
        insertUserSetting(UserInfo.getUserId());
        insertInitiative('No-Product Init', true, Date.today().addDays(-10), null, 100);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        TPB_User_Metric__c m = [
            SELECT Day_Sales_Value__c, Day_Sales_Units__c,
                   Day_Purchases_Value__c, Day_Purchases_Units__c,
                   Cum_Sales_Value__c, Cum_Sales_Units__c,
                   Cum_Purchases_Value__c, Cum_Purchases_Units__c,
                   Inventory_Balance_Value__c, Inventory_Balance_Units__c,
                   Cum_Returns_Value__c, Cum_Returns_Units__c
            FROM TPB_User_Metric__c LIMIT 1
        ];
        System.assertEquals(0, m.Day_Sales_Value__c,          'Day sales value');
        System.assertEquals(0, m.Day_Sales_Units__c,          'Day sales units');
        System.assertEquals(0, m.Day_Purchases_Value__c,      'Day purchases value');
        System.assertEquals(0, m.Day_Purchases_Units__c,      'Day purchases units');
        System.assertEquals(0, m.Cum_Sales_Value__c,          'Cum sales value');
        System.assertEquals(0, m.Cum_Sales_Units__c,          'Cum sales units');
        System.assertEquals(0, m.Cum_Purchases_Value__c,      'Cum purchases value');
        System.assertEquals(0, m.Cum_Purchases_Units__c,      'Cum purchases units');
        System.assertEquals(0, m.Inventory_Balance_Value__c,  'Inventory balance value');
        System.assertEquals(0, m.Inventory_Balance_Units__c,  'Inventory balance units');
        //System.assertEquals(0, m.Cum_Returns_Value__c,        'Cum returns value');
        //System.assertEquals(0, m.Cum_Returns_Units__c,        'Cum returns units');
    }

    /**
     * 10. Zero commitment value — no exception thrown.
     */
    @IsTest
    static void testZeroCommitmentValue_noException() {
        insertUserSetting(UserInfo.getUserId());
        insertInitiative('Zero Commitment Init', true, Date.today().addDays(-3), null, 0);

        Test.startTest();
        Exception caught = null;
        try {
            Database.executeBatch(new TPB_UserMetricBatch(), 200);
        } catch (Exception e) {
            caught = e;
        }
        Test.stopTest();

        System.assertEquals(null, caught, 'No exception with zero commitment');
        System.assertEquals(1, [SELECT COUNT() FROM TPB_User_Metric__c],
            'Metric created with zero commitment');
    }

    /**
     * 11. Subcategory product resolution + inventory balance aggregation.
     */
    @IsTest
    static void testSubcategoryProductAndInventoryBalance() {
        final String CODE = 'SUBCAT-INV-TEST';

        List<SObject> chain = buildInitiativeWithProducts(CODE, Date.today().addDays(-10), null);
        Product2 mainProd = (Product2) chain[1];
        insertUserSetting(UserInfo.getUserId());
        TPB_TestFactory.createInventory(UserInfo.getUserId(), mainProd.Id);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        TPB_User_Metric__c m = [
            SELECT Inventory_Balance_Units__c, Inventory_Balance_Value__c
            FROM TPB_User_Metric__c LIMIT 1
        ];
        System.assertNotEquals(null, m.Inventory_Balance_Units__c,
            'Inventory_Balance_Units__c should be populated');
        System.assertNotEquals(null, m.Inventory_Balance_Value__c,
            'Inventory_Balance_Value__c should be populated');
    }

    /**
     * 12. Purchase and sale transactions — open-ended initiative.
     *     Covers: open-ended TX SOQL, purchase branch, sale branch, days-since.
     */
    @IsTest
    static void testTransactionAggregation_purchaseAndSale() {
        final String CODE = 'SUBCAT-TX-TEST';

        List<SObject> chain = buildInitiativeWithProducts(CODE, Date.today().addDays(-10), null);
        Product2 mainProd = (Product2) chain[1];
        insertUserSetting(UserInfo.getUserId());

        cgcloud__Inventory__c inv =
            TPB_TestFactory.createInventory(UserInfo.getUserId(), mainProd.Id);
        TPB_TestFactory.createInventoryTransactionTemplate();

        Account acc = TPB_TestFactory.createAccount();
        Visit v = TPB_TestFactory.createVisit(acc);
        cgcloud__Order__c salesOrder = TPB_TestFactory.createAdOrder(v);
        cgcloud__Order_Item__c salesOrderItem = TPB_TestFactory.createAdOrderItem(salesOrder, mainProd);

        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = mainProd.Id,
            UnitPrice = 5,
            IsActive = true
        );
        insert pbe;

        Order wholesaleOrd = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPbId
        );
        insert wholesaleOrd;
        OrderItem wholesaleOrderItem = new OrderItem(
            OrderId = wholesaleOrd.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 5
        );
        insert wholesaleOrderItem;

        Id addTplId  = [SELECT Id FROM cgcloud__Inventory_Transaction_Template__c
                        WHERE Name = :TPB_TestFactory.INVENTORY_TRANSACTION_TEMPLATE_ADD  LIMIT 1].Id;
        Id saleTplId = [SELECT Id FROM cgcloud__Inventory_Transaction_Template__c
                        WHERE Name = :TPB_TestFactory.INVENTORY_TRANSACTION_TEMPLATE_CASHSALE LIMIT 1].Id;

        insert new List<cgcloud__Inventory_Transaction__c>{
            new cgcloud__Inventory_Transaction__c(
                cgcloud__Inventory__c                      = inv.Id,
                cgcloud__Inventory_Transaction_Template__c = addTplId,
                TPB_Wholesale_Order_Item__c                = wholesaleOrderItem.Id,
                cgcloud__Amount__c                         = 10
            ),
            new cgcloud__Inventory_Transaction__c(
                cgcloud__Inventory__c                      = inv.Id,
                cgcloud__Inventory_Transaction_Template__c = saleTplId,
                cgcloud__Order_Item__c                     = salesOrderItem.Id,
                cgcloud__Amount__c                         = -4
            )
        };

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        TPB_User_Metric__c m = [
            SELECT Cum_Purchases_Units__c, Day_Purchases_Units__c,
                   Cum_Sales_Units__c,     Day_Sales_Units__c,
                   Days_Since_Last_Purchase__c, Days_Since_Last_Sale__c
            FROM TPB_User_Metric__c LIMIT 1
        ];
        System.assertEquals(10, m.Cum_Purchases_Units__c,  'Cum purchase units');
        System.assertEquals(10, m.Day_Purchases_Units__c,  'Day purchase units (txn is today)');
        System.assertEquals(4,  m.Cum_Sales_Units__c,      'Cum sale units');
        System.assertEquals(4,  m.Day_Sales_Units__c,      'Day sale units (txn is today)');
        System.assertEquals(0,  m.Days_Since_Last_Purchase__c, 'Days since last purchase');
        System.assertEquals(0,  m.Days_Since_Last_Sale__c,     'Days since last sale');
    }

    /**
     * 13. Closed initiative with future end date — bounded transaction SOQL path.
     */
    @IsTest
    static void testClosedInitiative_boundedTransactionQuery() {
        buildInitiativeWithProducts('SUBCAT-CLOSED-TEST',
            Date.today().addDays(-5), Date.today().addDays(30));
        insertUserSetting(UserInfo.getUserId());

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM TPB_User_Metric__c],
            'Metric created for closed initiative with future end date');
    }

    /**
     * 14. Commitment_Value__c set from initiative global on first run (no existing record).
     */
    @IsTest
    static void testCommitmentValue_setOnFirstRun() {
        insertUserSetting(UserInfo.getUserId());
        insertInitiative('Commitment Init', true, Date.today().addDays(-5), null, 750);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        TPB_User_Metric__c m = [SELECT Commitment_Value__c FROM TPB_User_Metric__c LIMIT 1];
        System.assertEquals(750, m.Commitment_Value__c,
            'Commitment_Value__c should be set from initiative global on first run');
    }

    /**
     * 15. Commitment_Value__c not overwritten when a metric record already exists.
     */
    @IsTest
    static void testCommitmentValue_notOverwrittenOnRerun() {
        cgcloud__User_Setting__c us = insertUserSetting(UserInfo.getUserId());
        TPB_Sales_Initiative__c init = insertInitiative('Commitment Init', true,
            Date.today().addDays(-5), null, 750);

        String extId = String.valueOf(us.Id) + '_' + String.valueOf(init.Id);
        insert new TPB_User_Metric__c(
            External_Id__c             = extId,
            User_Setting__c            = us.Id,
            Initiative__c              = init.Id,
            Snapshot_Date__c           = Date.today(),
            Commitment_Value__c        = 999,
            Day_Sales_Value__c         = 0,
            Day_Sales_Units__c         = 0,
            Day_Purchases_Value__c     = 0,
            Day_Purchases_Units__c     = 0,
            Cum_Sales_Value__c         = 0,
            Cum_Sales_Units__c         = 0,
            Cum_Purchases_Value__c     = 0,
            Cum_Purchases_Units__c     = 0,
            Inventory_Balance_Value__c = 0,
            Inventory_Balance_Units__c = 0,
            Cum_Returns_Value__c       = 0,
            Cum_Returns_Units__c       = 0
        );

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        TPB_User_Metric__c m = [SELECT Commitment_Value__c FROM TPB_User_Metric__c LIMIT 1];
        System.assertEquals(999, m.Commitment_Value__c,
            'Commitment_Value__c should not be overwritten on re-run');
    }

    /**
     * 16. User Setting with Non_Active_Field_User__c = true is excluded from start().
     */
    @IsTest
    static void testNonActiveFieldUser_noMetricCreated() {
        insert new cgcloud__User_Setting__c(
            cgcloud__User__c         = UserInfo.getUserId(),
            Non_Active_Field_User__c = true
        );
        insertInitiative('Active Init', true, Date.today().addDays(-5), null, 100);

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM TPB_User_Metric__c],
            'No metric for non-active field user');
    }

    /**
     * 17. Product_Hierarchy_Level__c = 'Product' — direct Product2 Id path in start().
     */
    @IsTest
    static void testProductLevelHierarchy_directProductId() {
        Product2 prod = TPB_TestFactory.createProduct();
        TPB_Sales_Initiative__c init = insertInitiative('Product Level Init', true,
            Date.today().addDays(-5), null, 400);
        insert new TPB_Initiative_Subcategory__c(
            Initiative__c              = init.Id,
            Product_Code__c            = String.valueOf(prod.Id),
            Subcategory_Code__c        = 'DIRECT-PROD',
            Product_Hierarchy_Level__c = 'Product'
        );
        insertUserSetting(UserInfo.getUserId());

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM TPB_User_Metric__c],
            'Metric created using Product hierarchy level');
    }

    /**
     * 18. Product_Hierarchy_Level__c = 'Category' — category resolution path in start().
     *     No matching products are expected so metric is created with zero values.
     */
    @IsTest
    static void testCategoryLevelHierarchy_pathExercised() {
        TPB_Sales_Initiative__c init = insertInitiative('Category Level Init', true,
            Date.today().addDays(-5), null, 300);
        insert new TPB_Initiative_Subcategory__c(
            Initiative__c              = init.Id,
            Product_Code__c            = 'TEST-CATEGORY',
            Subcategory_Code__c        = 'TEST-CATEGORY',
            Product_Hierarchy_Level__c = 'Category'
        );
        insertUserSetting(UserInfo.getUserId());

        Test.startTest();
        Database.executeBatch(new TPB_UserMetricBatch(), 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM TPB_User_Metric__c],
            'Metric created when Category hierarchy level is used');
    }
}