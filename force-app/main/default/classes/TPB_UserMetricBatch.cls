public class TPB_UserMetricBatch
    implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    // Set<Id> is stateful-safe — no CSV serialization needed
    private Map<Id, Set<Id>>  initiativeToProductIds  = new Map<Id, Set<Id>>();
    private Map<Id, Date>     initiativeStartDates    = new Map<Id, Date>();
    private Map<Id, Date>     initiativeEndDates      = new Map<Id, Date>();
    private Map<Id, Decimal>  initiativeCommitments   = new Map<Id, Decimal>();
 
    private Map<Id, Set<Id>>  initiativeTodaySellerIds      = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>>  initiativeLastWeekSellerIds   = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>>  initiativeCumulativeSellerIds = new Map<Id, Set<Id>>();
    private Integer           totalActiveTBMs               = 0;
    private Datetime          batchRunTime                  = System.now();

    

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TPB_UserMetricBatch(), 10);
    }

   
    public Database.QueryLocator start(Database.BatchableContext bc) {

        // 1. Load all active initiatives with their subcategory children
        List<TPB_Sales_Initiative__c> initiatives = [
            SELECT Id, Name, Start_Date__c, End_Date__c, Commitment_Value__c,
                   (SELECT Product_Code__c, Product_Hierarchy_Level__c
                    FROM Initiative_Subcategory__r)
            FROM TPB_Sales_Initiative__c
            WHERE Active__c = true
        ];

        System.debug('START: Active initiatives found: ' + initiatives.size());

        if (initiatives.isEmpty()) {
            return Database.getQueryLocator(
                'SELECT Id FROM cgcloud__User_Setting__c WHERE Id = null'
            );
        }

       
        Map<Id, Set<String>> initCatCodes = new Map<Id, Set<String>>();
        Map<Id, Set<String>> initSubCodes = new Map<Id, Set<String>>();
        Map<Id, Set<Id>>     initProdIds  = new Map<Id, Set<Id>>();

        Set<String> allCatCodes = new Set<String>();
        Set<String> allSubCodes = new Set<String>();

        for (TPB_Sales_Initiative__c init : initiatives) {

            Set<String> catCodes = new Set<String>();
            Set<String> subCodes = new Set<String>();
            Set<Id>     prodIds  = new Set<Id>();

            for (TPB_Initiative_Subcategory__c sub : init.Initiative_Subcategory__r) {

                if (String.isBlank(sub.Product_Code__c)) continue;

                String level = String.isNotBlank(sub.Product_Hierarchy_Level__c)
                               ? sub.Product_Hierarchy_Level__c
                               : 'Subcategory';

                if (level == 'Category') {
                    catCodes.add(sub.Product_Code__c);
                    allCatCodes.add(sub.Product_Code__c);

                } else if (level == 'Product') {
                    for (String rawId : sub.Product_Code__c.split(',')) {
                        String trimmed = rawId.trim();
                        if (String.isNotBlank(trimmed)) {
                            try {
                                prodIds.add((Id) trimmed);
                            } catch (Exception e) {
                                System.debug('START: Invalid Product2 Id "'
                                    + trimmed + '" on initiative '
                                    + init.Name + ' — skipping');
                            }
                        }
                    }
                }
                 else {
                    // 'Subcategory' — existing behavior
                    subCodes.add(sub.Product_Code__c);
                    allSubCodes.add(sub.Product_Code__c);
                }
            }

            initCatCodes.put(init.Id, catCodes);
            initSubCodes.put(init.Id, subCodes);
            initProdIds.put(init.Id,  prodIds);

            System.debug('START: Initiative "' + init.Name
                + '" | Category codes: '    + catCodes.size()
                + ' | Subcategory codes: '  + subCodes.size()
                + ' | Direct Product IDs: ' + prodIds.size());
        }

        // 3. Resolve Subcategory codes → Product2 Ids
        //    cgcloud__Criterion_2_Product__r.Name = Subcategory name on Product2
        Map<String, Set<Id>> subCodeToProductIds = new Map<String, Set<Id>>();
        if (!allSubCodes.isEmpty()) {
            for (Product2 p : [
                SELECT Id, cgcloud__Criterion_2_Product__r.Name
                FROM Product2
                WHERE cgcloud__Criterion_2_Product__r.Name IN :allSubCodes
                  AND IsActive = true
            ]) {
                String key = p.cgcloud__Criterion_2_Product__r.Name;
                if (!subCodeToProductIds.containsKey(key)) {
                    subCodeToProductIds.put(key, new Set<Id>());
                }
                subCodeToProductIds.get(key).add(p.Id);
            }
            System.debug('START: Subcategory codes resolved — buckets: '
                + subCodeToProductIds.size());
        }

        // 4. Resolve Category codes → Product2 Ids
        //    cgcloud__Criterion_1_Product__r.Name = Category name on Product2
        //    CONFIRM this relationship name with Santhosh before deploying
        Map<String, Set<Id>> catCodeToProductIds = new Map<String, Set<Id>>();
        if (!allCatCodes.isEmpty()) {
            for (Product2 p : [
                SELECT Id, cgcloud__Criterion_1_Product__r.Name
                FROM Product2
                WHERE cgcloud__Criterion_1_Product__r.Name IN :allCatCodes
                  AND IsActive = true
            ]) {
                String key = p.cgcloud__Criterion_1_Product__r.Name;
                if (!catCodeToProductIds.containsKey(key)) {
                    catCodeToProductIds.put(key, new Set<Id>());
                }
                catCodeToProductIds.get(key).add(p.Id);
            }
            System.debug('START: Category codes resolved — buckets: '
                + catCodeToProductIds.size());
        }

        // 5. Merge all resolved Product Ids per initiative into stateful maps
        for (TPB_Sales_Initiative__c init : initiatives) {

            Set<Id> mergedIds = new Set<Id>();

            for (String code : initSubCodes.get(init.Id)) {
                if (subCodeToProductIds.containsKey(code)) {
                    mergedIds.addAll(subCodeToProductIds.get(code));
                }
            }

            for (String code : initCatCodes.get(init.Id)) {
                if (catCodeToProductIds.containsKey(code)) {
                    mergedIds.addAll(catCodeToProductIds.get(code));
                }
            }

            // Direct Product Ids — no resolution needed
            mergedIds.addAll(initProdIds.get(init.Id));

            initiativeToProductIds.put(init.Id, mergedIds);
            initiativeStartDates.put(init.Id,   init.Start_Date__c);
            initiativeEndDates.put(init.Id,     init.End_Date__c);
            initiativeCommitments.put(init.Id,
                init.Commitment_Value__c != null ? init.Commitment_Value__c : 0);

            System.debug('START: Stateful built "' + init.Name
                + '" | Merged product IDs: ' + mergedIds.size()
                + ' | Start: '               + init.Start_Date__c
                + ' | End: '                 + (init.End_Date__c != null
                                                 ? String.valueOf(init.End_Date__c)
                                                 : 'open ended')
                + ' | Commitment: '          + init.Commitment_Value__c);
        }

        // 6. Active-window guard
        //    If ALL initiatives are past their end date, skip the entire batch.
        //    Null end date = open ended = always active.
        Date today = Date.today();
        Boolean hasActiveWindow = false;
        for (Id initId : initiativeEndDates.keySet()) {
            Date endDate = initiativeEndDates.get(initId);
            if (endDate == null || endDate >= today) {
                hasActiveWindow = true;
                break;
            }
        }
        if (!hasActiveWindow) {
            System.debug('START: All initiatives past end date — '
                + 'no snapshots will be created today (' + today + ')');
            return Database.getQueryLocator(
                'SELECT Id FROM cgcloud__User_Setting__c WHERE Id = null'
            );
        }

        // 7. Return ONLY field rep User Settings
        totalActiveTBMs = [
            SELECT COUNT() FROM cgcloud__User_Setting__c
            WHERE Non_Active_Field_User__c != true
        ];
        for (Id initId : initiativeToProductIds.keySet()) {
            initiativeTodaySellerIds.put(initId,      new Set<Id>());
            initiativeLastWeekSellerIds.put(initId,   new Set<Id>());
            initiativeCumulativeSellerIds.put(initId, new Set<Id>());
        }

        System.debug('START: Total active TBMs: ' + totalActiveTBMs);

               return Database.getQueryLocator([
    SELECT Id,
           cgcloud__User__c,
           cgcloud__User__r.TPB_Territory__c
    FROM cgcloud__User_Setting__c
    WHERE Non_Active_Field_User__c != true   
]);
    }

    
    public void execute(Database.BatchableContext bc,
                        List<cgcloud__User_Setting__c> userSettings) {

        System.debug('EXECUTE: Chunk size: ' + userSettings.size());

        if (initiativeToProductIds.isEmpty()) {
            System.debug('EXECUTE: Stateful map empty — skipping chunk');
            return;
        }

        Date today = Date.today();

        // Collect User Ids and User Setting Ids for this chunk
        Set<Id> userIds        = new Set<Id>();
        Set<Id> userSettingIds = new Set<Id>();
        for (cgcloud__User_Setting__c us : userSettings) {
            userSettingIds.add(us.Id);
            if (us.cgcloud__User__c != null) {
                userIds.add(us.cgcloud__User__c);
            }
        }
        if (userIds.isEmpty()) return;

        // Check which user-setting + initiative combinations already have a metric record.
        Set<String> existingMetricKeys = new Set<String>();
        for (TPB_User_Metric__c m : [
            SELECT User_Setting__c, Initiative__c
            FROM TPB_User_Metric__c
            WHERE User_Setting__c IN :userSettingIds
              AND Initiative__c   IN :initiativeToProductIds.keySet()
        ]) {
            existingMetricKeys.add(
                String.valueOf(m.User_Setting__c) + '_' + String.valueOf(m.Initiative__c)
            );
        }

        List<TPB_User_Metric__c> metricsToUpsert = new List<TPB_User_Metric__c>();

        for (Id initiativeId : initiativeToProductIds.keySet()) {

            Set<Id>  productIds = initiativeToProductIds.get(initiativeId);
            Date     startDate  = initiativeStartDates.get(initiativeId);
            Date     endDate    = initiativeEndDates.get(initiativeId);
            Decimal  commitment = initiativeCommitments.get(initiativeId);

            // Per-initiative end-date check — skip expired initiatives individually
            // so that if multiple initiatives exist, only expired ones are skipped
            if (endDate != null && today > endDate) {
                System.debug('EXECUTE: Skipping initiative ' + initiativeId
                    + ' — end date ' + endDate + ' has passed (today = ' + today + ')');
                continue;
            }

            System.debug('EXECUTE: Initiative: ' + initiativeId
                + ' | Products: '   + productIds.size()
                + ' | Start: '      + startDate
                + ' | End: '        + (endDate != null
                                        ? String.valueOf(endDate)
                                        : 'open ended')
                + ' | Commitment: ' + commitment);

            
            Map<Id, List<cgcloud__Inventory_Transaction__c>> txByUser =
                new Map<Id, List<cgcloud__Inventory_Transaction__c>>();

            if (!productIds.isEmpty()) {

                List<cgcloud__Inventory_Transaction__c> txList;

                if (endDate != null) {
                    // Closed initiative — bounded window
                    txList = [
                        SELECT Id,
                               cgcloud__Inventory__r.cgcloud__User__c,
                               cgcloud__Amount__c,
                               TPB_Wholesale_Order_Item__c,
                               cgcloud__Order_Item__c,
                               Purchase_Price__c,
                               Sell_Price__c,
                               CreatedDate
                        FROM cgcloud__Inventory_Transaction__c
                        WHERE (TPB_Wholesale_Order_Item__r.Product2Id
                                   IN :productIds
                            OR cgcloud__Order_Item__r.cgcloud__Product__c
                                   IN :productIds)
                          AND cgcloud__Inventory__r.cgcloud__User__c IN :userIds
                          AND CreatedDate >= :startDate
                          AND CreatedDate <= :endDate
                        ORDER BY CreatedDate ASC
                    ];
                } else {
                    // Open-ended initiative — no upper bound
                    txList = [
                        SELECT Id,
                               cgcloud__Inventory__r.cgcloud__User__c,
                               cgcloud__Amount__c,
                               TPB_Wholesale_Order_Item__c,
                               cgcloud__Order_Item__c,
                               Purchase_Price__c,
                               Sell_Price__c,
                               CreatedDate
                        FROM cgcloud__Inventory_Transaction__c
                        WHERE (TPB_Wholesale_Order_Item__r.Product2Id
                                   IN :productIds
                            OR cgcloud__Order_Item__r.cgcloud__Product__c
                                   IN :productIds)
                          AND cgcloud__Inventory__r.cgcloud__User__c IN :userIds
                          AND CreatedDate >= :startDate
                        ORDER BY CreatedDate ASC
                    ];
                }

                for (cgcloud__Inventory_Transaction__c tx : txList) {
                    Id uid = tx.cgcloud__Inventory__r.cgcloud__User__c;
                    if (!txByUser.containsKey(uid)) {
                        txByUser.put(uid,
                            new List<cgcloud__Inventory_Transaction__c>());
                    }
                    txByUser.get(uid).add(tx);
                }

                System.debug('EXECUTE: Initiative ' + initiativeId
                    + ' | Users with transactions: ' + txByUser.size());
            }

            // ── SOQL 2: Inventory balances ────────────────────────────────────
            // End-of-day ALP inventory carrying value and unit count per user.
            // Null Balance or AvgPrice treated as 0 (null-safe per spec).
            Map<Id, Decimal> invValueByUser = new Map<Id, Decimal>();
            Map<Id, Decimal> invUnitsByUser = new Map<Id, Decimal>();
            Map<Id, Decimal> stockValueByUser = new Map<Id, Decimal>();

            if (!productIds.isEmpty()) {
                for (cgcloud__Inventory__c inv : [
                    SELECT cgcloud__User__c,
                           cgcloud__Balance__c,
                           TPB_AvgPrice__c, Extended_Cost__c
                    FROM cgcloud__Inventory__c
                    WHERE cgcloud__Product__c IN :productIds
                      AND cgcloud__User__c    IN :userIds
                ]) {
                    Id      uid   = inv.cgcloud__User__c;
                    Decimal bal   = inv.cgcloud__Balance__c != null
                                    ? inv.cgcloud__Balance__c : 0;
                    Decimal price = inv.TPB_AvgPrice__c    != null
                                    ? inv.TPB_AvgPrice__c    : 0;
                  Decimal extCost  = inv.Extended_Cost__c    != null 
                                    ? inv.Extended_Cost__c    : 0;

                    invUnitsByUser.put(uid,
                        (invUnitsByUser.containsKey(uid)
                            ? invUnitsByUser.get(uid) : 0) + bal);
                    invValueByUser.put(uid,
                        (invValueByUser.containsKey(uid)
                            ? invValueByUser.get(uid) : 0) + (bal * price));
                     stockValueByUser.put(uid, (stockValueByUser.containsKey(uid) 
                            ? stockValueByUser.get(uid) : 0) + extCost);

                }
            }

            // ── Build one metric row per User Setting per initiative ───────────
            for (cgcloud__User_Setting__c us : userSettings) {

                if (us.cgcloud__User__c == null) continue;

                Id userId = us.cgcloud__User__c;

                List<cgcloud__Inventory_Transaction__c> txs =
                    txByUser.containsKey(userId)
                        ? txByUser.get(userId)
                        : new List<cgcloud__Inventory_Transaction__c>();

                // Accumulators
                Decimal daySalesVal    = 0;
                Decimal daySalesUnits  = 0;
                Decimal dayPurchVal    = 0;
                Decimal dayPurchUnits  = 0;
                Decimal cumSalesVal    = 0;
                Decimal cumSalesUnits  = 0;
                Decimal cumPurchVal    = 0;
                Decimal cumPurchUnits  = 0;
                DateTime lastSaleDate  = null;
                DateTime lastPurchDate = null;
                Decimal last7SalesVal  = 0;


                for (cgcloud__Inventory_Transaction__c tx : txs) {

                    // FK-based type discrimination — spec requirement
                    // Do NOT use template name or Amount sign as primary discriminator
                    Boolean isPurchase = tx.TPB_Wholesale_Order_Item__c != null;
                    Boolean isSale     = tx.cgcloud__Order_Item__c      != null;

                    // Null-safe field reads — all nulls treated as 0 per spec
                    Decimal amt        = tx.cgcloud__Amount__c   != null
                                         ? tx.cgcloud__Amount__c   : 0;
                    Decimal purchPrice = tx.Purchase_Price__c    != null
                                         ? tx.Purchase_Price__c    : 0;
                    Decimal sellPrice  = tx.Sell_Price__c        != null
                                         ? tx.Sell_Price__c        : 0;

                     Boolean isToday     = tx.CreatedDate.date() == today;
                     Boolean isLast7Days = tx.CreatedDate.date() >= today.addDays(-100)
                                                              && tx.CreatedDate.date() <= today;
                     
                    if (isPurchase) {
                        Decimal val    = amt * purchPrice;
                        cumPurchVal   += val;
                        cumPurchUnits += amt;
                        if (isToday) {
                            dayPurchVal   += val;
                            dayPurchUnits += amt;
                        }
                        if (lastPurchDate == null || tx.CreatedDate > lastPurchDate) {
                            lastPurchDate = tx.CreatedDate;
                        }

                    } else if (isSale) {
                        Decimal val   = Math.abs(amt) * sellPrice;
                        cumSalesVal   += val;
                        cumSalesUnits += Math.abs(amt);
                        if (isToday) {
                            daySalesVal   += val;
                            daySalesUnits += Math.abs(amt);
                        }if (isLast7Days) {
                            last7SalesVal += val;
                        }
                        if (lastSaleDate == null || tx.CreatedDate > lastSaleDate) {
                            lastSaleDate = tx.CreatedDate;
                        }
                    }
                    // Transactions where neither FK is populated are ignored
                }
              // ── Accumulate into stateful seller sets 

                if (daySalesVal   > 0) initiativeTodaySellerIds.get(initiativeId).add(userId);
                if (last7SalesVal > 0) initiativeLastWeekSellerIds.get(initiativeId).add(userId);
                if (cumSalesVal > 0 && daySalesVal > 0) initiativeCumulativeSellerIds.get(initiativeId).add(userId);


                // Days since last activity — null when no activity exists in window
                Integer daysSinceLastSale  =
                    lastSaleDate  != null
                        ? lastSaleDate.date().daysBetween(today)  : null;
                Integer daysSinceLastPurch =
                    lastPurchDate != null
                        ? lastPurchDate.date().daysBetween(today) : null;

                // External Id format: {UserSettingId}_{InitiativeId}_{YYYYMMDD}
                // Used as upsert key — makes re-runs idempotent for same Snapshot_Date
                String extId = String.valueOf(us.Id) + '_' + String.valueOf(initiativeId);

                TPB_User_Metric__c metric = new TPB_User_Metric__c(
                    External_Id__c              = extId,
                    User_Setting__c             = us.Id,
                    Initiative__c               = initiativeId,
                    Snapshot_Date__c            = today,
                    Territory__c                = us.cgcloud__User__r.TPB_Territory__c,

                    // Day-level fields (today's activity only)
                    Day_Sales_Value__c          = daySalesVal,
                    Day_Sales_Units__c          = daySalesUnits,
                    Day_Purchases_Value__c      = dayPurchVal,
                    Day_Purchases_Units__c      = dayPurchUnits,

                    // Cumulative fields (since initiative Start_Date)
                    Cum_Sales_Value__c          = cumSalesVal,
                    Cum_Sales_Units__c          = cumSalesUnits,
                    Cum_Purchases_Value__c      = cumPurchVal,
                    Cum_Purchases_Units__c      = cumPurchUnits,

                    // Activity recency — null when no activity in window
                    Days_Since_Last_Sale__c     = daysSinceLastSale,
                    Days_Since_Last_Purchase__c = daysSinceLastPurch,

                    // End-of-day inventory snapshot
                    Inventory_Balance_Value__c  =
                        invValueByUser.containsKey(userId)
                            ? invValueByUser.get(userId) : 0,
                    Inventory_Balance_Units__c  =
                        invUnitsByUser.containsKey(userId)
                            ? invUnitsByUser.get(userId) : 0
                   


                    // Returns deferred to follow-on ticket — always 0 this build
                   // Cum_Returns_Value__c        = 0,
                   // Cum_Returns_Units__c        = 0
                );

                // Set Commitment_Value__c only when no record exists for this user+initiative.
                String commitKey = String.valueOf(us.Id) + '_' + String.valueOf(initiativeId);
                if (!existingMetricKeys.contains(commitKey)) {
                    metric.Commitment_Value__c = commitment;
                }

                metricsToUpsert.add(metric);
            }
        }

        System.debug('EXECUTE: Total records to upsert: ' + metricsToUpsert.size());

        if (!metricsToUpsert.isEmpty()) {
            Schema.SObjectField extIdField =
                TPB_User_Metric__c.Fields.External_Id__c;
            List<Database.UpsertResult> results =
                Database.upsert(metricsToUpsert, extIdField, false);

            Integer successCount = 0;
            Integer failCount    = 0;
            for (Database.UpsertResult r : results) {
                if (r.isSuccess()) {
                    successCount++;
                } else {
                    failCount++;
                    for (Database.Error e : r.getErrors()) {
                        System.debug('UPSERT ERROR: '
                            + e.getStatusCode()
                            + ' | ' + e.getMessage()
                            + ' | Fields: ' + e.getFields());
                    }
                }
            }
            System.debug('EXECUTE: Success: ' + successCount
                + ' | Failures: ' + failCount);
        }
    }

   
    public void finish(Database.BatchableContext bc) {
        // ── Update initiative rollup fields once across the full batch ────────
        List<TPB_Sales_Initiative__c> initiativesToUpdate = new List<TPB_Sales_Initiative__c>();
        for (Id initId : initiativeToProductIds.keySet()) {
            initiativesToUpdate.add(new TPB_Sales_Initiative__c(
                Id                        = initId,
                Total_TBMs__c             = totalActiveTBMs,
                Sellers_Today__c          = initiativeTodaySellerIds.get(initId).size(),
                Sellers_Last_Week__c      = initiativeLastWeekSellerIds.get(initId).size(),
                Sellers_Cumulative__c     = initiativeCumulativeSellerIds.get(initId).size(),
                Metrics_Last_Refreshed__c = batchRunTime
            ));
        }

        if (!initiativesToUpdate.isEmpty()) {
            List<Database.SaveResult> results =
                Database.update(initiativesToUpdate, false);

            Integer successCount = 0;
            Integer failCount    = 0;
            for (Database.SaveResult r : results) {
                if (r.isSuccess()) {
                    successCount++;
                } else {
                    failCount++;
                    for (Database.Error e : r.getErrors()) {
                        System.debug('INITIATIVE UPDATE ERROR: '
                            + e.getStatusCode()
                            + ' | ' + e.getMessage()
                            + ' | Fields: ' + e.getFields());
                    }
                }
            }
            System.debug('FINISH: Initiative update — Success: ' + successCount
                + ' | Failures: ' + failCount);
        }

        // ── Job summary ───────────────────────────────────────────────────────
        List<AsyncApexJob> jobs = [
            SELECT Status, NumberOfErrors,
                   TotalJobItems, JobItemsProcessed
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        if (!jobs.isEmpty()) {
            System.debug('FINISH: Status: '       + jobs[0].Status
                + ' | Errors: '                   + jobs[0].NumberOfErrors
                + ' | Total chunks: '             + jobs[0].TotalJobItems
                + ' | Chunks processed: '         + jobs[0].JobItemsProcessed);
        }
    }
}