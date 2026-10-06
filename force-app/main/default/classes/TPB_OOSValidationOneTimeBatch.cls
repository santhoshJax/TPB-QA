public with sharing class TPB_OOSValidationOneTimeBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    private static final String OOS_VALUE = 'OutOfStock';

    // Stores ONLY mismatches.
    // Correct records are not stored.
    private List<String> mismatchRows = new List<String>();

    private Integer totalChecked = 0;
    private Integer totalMismatches = 0;
    private Integer activityProductNotFound = 0;


    // ============================================================
    // START
    //
    // ALL-TIME.
    //
    // No 90-day restriction.
    //
    // We select Accounts that have at least one relevant Visit.
    // ============================================================

    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {

        return Database.getQueryLocator([
            SELECT
                Id,
                Name
            FROM Account
            WHERE Id IN (
                SELECT AccountId
                FROM Visit
                WHERE AccountId != NULL
                AND ActualVisitEndTime != NULL
                AND (
                    TPB_Number_of_Distribution__c > 0
                    OR Number_of_OOS__c > 0
                )
            )
        ]);
    }


    // ============================================================
    // EXECUTE
    // ============================================================

    public void execute(
        Database.BatchableContext bc,
        List<Account> accounts
    ) {

        if (accounts == null || accounts.isEmpty()) {
            return;
        }


        // ========================================================
        // ACCOUNT INFORMATION
        // ========================================================

        Set<Id> accountIds = new Set<Id>();

        Map<Id, String> accountNameById =
            new Map<Id, String>();

        for (Account acc : accounts) {

            accountIds.add(acc.Id);

            accountNameById.put(
                acc.Id,
                acc.Name
            );
        }


        // ========================================================
        // GET ALL RELEVANT VISITS
        //
        // NO DATE FILTER.
        //
        // We get ALL relevant Visits for these Accounts.
        //
        // Ordered oldest -> newest so we can determine:
        //
        //   Latest Visit
        //   Previous Visit
        //
        // without manually sorting a List.
        // ========================================================

        List<Visit> visits = [
            SELECT
                Id,
                AccountId,
                ActualVisitEndTime,
                TPB_SOV_Done__c
            FROM Visit
            WHERE AccountId IN :accountIds
            AND ActualVisitEndTime != NULL
            AND (
                TPB_Number_of_Distribution__c > 0
                OR Number_of_OOS__c > 0
            )
            ORDER BY
                AccountId ASC,
                ActualVisitEndTime ASC
        ];


        // ========================================================
        // FIND:
        //
        // latest relevant Visit
        // previous relevant Visit
        //
        // We keep the last two Visits for each Account.
        //
        // This avoids the previous list-index problem.
        // ========================================================

        Map<Id, Visit> latestVisitByAccount =
            new Map<Id, Visit>();

        Map<Id, Visit> previousVisitByAccount =
            new Map<Id, Visit>();


        for (Visit v : visits) {

            if (v.AccountId == null) {
                continue;
            }


            if (
                latestVisitByAccount.containsKey(
                    v.AccountId
                )
            ) {

                previousVisitByAccount.put(
                    v.AccountId,
                    latestVisitByAccount.get(
                        v.AccountId
                    )
                );
            }


            latestVisitByAccount.put(
                v.AccountId,
                v
            );
        }


        // ========================================================
        // VISIT IDS
        // ========================================================

        Set<Id> visitIds = new Set<Id>();

        for (
            Visit v :
            latestVisitByAccount.values()
        ) {

            visitIds.add(v.Id);
        }


        for (
            Visit v :
            previousVisitByAccount.values()
        ) {

            visitIds.add(v.Id);
        }


        if (visitIds.isEmpty()) {
            return;
        }


        // ========================================================
        // GET VISIT JOBS
        //
        // Query is already ordered by Visit End Time.
        // No custom list sorting is required.
        // ========================================================

        List<cgcloud__Visit_Job__c> visitJobs = [
            SELECT
                Id,
                cgcloud__Visit__c,
                cgcloud__Visit__r.AccountId,
                cgcloud__Visit__r.ActualVisitEndTime,
                cgcloud__Product__c,
                cgcloud__Product__r.Name,
                TPB_Calculated_EOV__c,
                Calculated_Distribution__c,
                TPB_EOV__c,
                TPB_SOV__c
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__c IN :visitIds
            AND cgcloud__Product__c != NULL
            ORDER BY
                cgcloud__Visit__r.ActualVisitEndTime ASC,
                cgcloud__Visit__c ASC
        ];


        // ========================================================
        // MAP:
        //
        // Visit + Product
        //       ->
        // Visit Job
        //
        // ========================================================

        Map<String, cgcloud__Visit_Job__c>
            visitProductJobMap =
            new Map<String, cgcloud__Visit_Job__c>();


        // Account + Product
        //       ->
        // Visit Jobs
        //
        // We use this to count/process products.

        Map<String, List<cgcloud__Visit_Job__c>>
            accountProductJobs =
            new Map<String, List<cgcloud__Visit_Job__c>>();


        for (
            cgcloud__Visit_Job__c vj :
            visitJobs
        ) {

            String visitProductKey =
                String.valueOf(
                    vj.cgcloud__Visit__c
                )
                +
                '_'
                +
                String.valueOf(
                    vj.cgcloud__Product__c
                );


            visitProductJobMap.put(
                visitProductKey,
                vj
            );


            String accountProductKey =
                String.valueOf(
                    vj.cgcloud__Visit__r.AccountId
                )
                +
                '_'
                +
                String.valueOf(
                    vj.cgcloud__Product__c
                );


            if (
                !accountProductJobs.containsKey(
                    accountProductKey
                )
            ) {

                accountProductJobs.put(
                    accountProductKey,
                    new List<cgcloud__Visit_Job__c>()
                );
            }


            accountProductJobs
                .get(accountProductKey)
                .add(vj);
        }


        // ========================================================
        // GET ACTIVITY PRODUCTS
        //
        // Object:
        // cgcloud__Job_Definition_List_Product__c
        //
        // Fields:
        //
        // TPB_Account__c
        // cgcloud__Product__c
        // TPB_OOS_Number__c
        // TPB_Visit_Job__c
        // ========================================================

        List<cgcloud__Job_Definition_List_Product__c>
            activityProducts = [
                SELECT
                    Id,
                    cgcloud__Job_Definition_List__c,
                    TPB_Account__c,
                    cgcloud__Product__c,
                    TPB_OOS_Number__c,
                    TPB_Visit_Job__c
                FROM cgcloud__Job_Definition_List_Product__c
                WHERE TPB_Account__c IN :accountIds
            ];


        // ========================================================
        // MAP ACTIVITY PRODUCTS
        //
        // Account + Product
        //       ->
        // Activity Product
        // ========================================================

        Map<String,
            cgcloud__Job_Definition_List_Product__c>
            activityProductByAccountProduct =
            new Map<String,
                cgcloud__Job_Definition_List_Product__c>();


        for (
            cgcloud__Job_Definition_List_Product__c ap :
            activityProducts
        ) {

            if (
                ap.TPB_Account__c == null ||
                ap.cgcloud__Product__c == null
            ) {
                continue;
            }


            String key =
                String.valueOf(
                    ap.TPB_Account__c
                )
                +
                '_'
                +
                String.valueOf(
                    ap.cgcloud__Product__c
                );


            activityProductByAccountProduct.put(
                key,
                ap
            );
        }


        // ========================================================
        // PROCESS EACH ACCOUNT
        // ========================================================

        for (
            Id accountId :
            latestVisitByAccount.keySet()
        ) {

            Visit latestVisit =
                latestVisitByAccount.get(
                    accountId
                );


            Visit previousVisit =
                previousVisitByAccount.get(
                    accountId
                );


            if (latestVisit == null) {
                continue;
            }


            // ====================================================
            // GET PRODUCT IDs FROM LATEST VISIT
            // ====================================================

            Set<Id> latestProductIds =
                new Set<Id>();


            for (
                cgcloud__Visit_Job__c vj :
                visitJobs
            ) {

                if (
                    vj.cgcloud__Visit__c ==
                    latestVisit.Id
                ) {

                    latestProductIds.add(
                        vj.cgcloud__Product__c
                    );
                }
            }


            if (latestProductIds.isEmpty()) {
                continue;
            }


            // ====================================================
            // PROCESS EACH PRODUCT
            // ====================================================

            for (
                Id productId :
                latestProductIds
            ) {


                // ------------------------------------------------
                // LATEST VISIT JOB
                // ------------------------------------------------

                String latestJobKey =
                    String.valueOf(
                        latestVisit.Id
                    )
                    +
                    '_'
                    +
                    String.valueOf(
                        productId
                    );


                cgcloud__Visit_Job__c latestJob =
                    visitProductJobMap.get(
                        latestJobKey
                    );


                if (latestJob == null) {
                    continue;
                }


                // ------------------------------------------------
                // PREVIOUS VISIT JOB
                // ------------------------------------------------

                cgcloud__Visit_Job__c previousJob =
                    null;


                if (previousVisit != null) {

                    String previousJobKey =
                        String.valueOf(
                            previousVisit.Id
                        )
                        +
                        '_'
                        +
                        String.valueOf(
                            productId
                        );


                    previousJob =
                        visitProductJobMap.get(
                            previousJobKey
                        );
                }


                // ------------------------------------------------
                // LATEST OOS
                //
                // Exact production condition:
                //
                // TPB_Calculated_EOV__c = OutOfStock
                // OR
                // Calculated_Distribution__c = OutOfStock
                // ------------------------------------------------

                Boolean latestIsOOS =
                    latestJob.TPB_Calculated_EOV__c ==
                    OOS_VALUE
                    ||
                    latestJob.Calculated_Distribution__c ==
                    OOS_VALUE;


                // ------------------------------------------------
                // PREVIOUS OOS
                // ------------------------------------------------

                Boolean previousIsOOS =
                    previousJob != null
                    &&
                    (
                        previousJob.TPB_Calculated_EOV__c ==
                        OOS_VALUE
                        ||
                        previousJob.Calculated_Distribution__c ==
                        OOS_VALUE
                    );


                // ------------------------------------------------
                // ACTIVITY PRODUCT
                // ------------------------------------------------

                String activityProductKey =
                    String.valueOf(
                        accountId
                    )
                    +
                    '_'
                    +
                    String.valueOf(
                        productId
                    );


                cgcloud__Job_Definition_List_Product__c
                    activityProduct =
                    activityProductByAccountProduct.get(
                        activityProductKey
                    );


                // ------------------------------------------------
                // ACTUAL OOS NUMBER
                // ------------------------------------------------

                Integer actualOOS = 0;


                if (
                    activityProduct != null
                    &&
                    activityProduct.TPB_OOS_Number__c != null
                ) {

                    actualOOS =
                        Integer.valueOf(
                            activityProduct.TPB_OOS_Number__c
                        );
                }


                // ------------------------------------------------
                // EXPECTED OOS
                //
                // For the latest/previous Visit comparison:
                //
                // Latest NOT OOS -> 0
                //
                // Latest OOS and previous NOT OOS -> 1
                //
                // Latest OOS and previous OOS -> 2
                //
                // ------------------------------------------------

                Integer expectedOOS;


                if (!latestIsOOS) {

                    expectedOOS = 0;

                } else if (previousIsOOS) {

                    expectedOOS = 2;

                } else {

                    expectedOOS = 1;
                }


                // ------------------------------------------------
                // RESULT
                // ------------------------------------------------

                totalChecked++;


                String result;


                if (activityProduct == null) {

                    result =
                        'ACTIVITY PRODUCT NOT FOUND';

                    activityProductNotFound++;

                } else if (
                    actualOOS == expectedOOS
                ) {

                    result = 'CORRECT';

                } else {

                    result = 'MISMATCH';

                    totalMismatches++;
                }


                // ------------------------------------------------
                // ONLY STORE MISMATCHES
                // ------------------------------------------------

                if (result != 'CORRECT') {

                    String accountName =
                        accountNameById.get(
                            accountId
                        );


                    String productName =
                        latestJob
                            .cgcloud__Product__r
                            .Name;


                    Integer difference =
                        actualOOS -
                        expectedOOS;


                    mismatchRows.add(
                        csv(accountName)
                        + ','
                        + csv(
                            String.valueOf(
                                accountId
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                latestVisit.Id
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                latestVisit.ActualVisitEndTime
                            )
                        )
                        + ','
                        + csv(
                            previousVisit == null
                                ? ''
                                : String.valueOf(
                                    previousVisit.Id
                                )
                        )
                        + ','
                        + csv(
                            previousVisit == null
                                ? ''
                                : String.valueOf(
                                    previousVisit.ActualVisitEndTime
                                )
                        )
                        + ','
                        + csv(
                            productName
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                productId
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                latestJob.Id
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                previousIsOOS
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                latestIsOOS
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                expectedOOS
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                actualOOS
                            )
                        )
                        + ','
                        + csv(
                            String.valueOf(
                                difference
                            )
                        )
                        + ','
                        + csv(
                            result
                        )
                    );
                }
            }
        }
    }


    // ============================================================
    // CSV ESCAPE
    // ============================================================

    private static String csv(
        String value
    ) {

        if (value == null) {
            return '""';
        }


        return '"' +
            value.replace(
                '"',
                '""'
            ) +
            '"';
    }


    // ============================================================
    // FINISH
    //
    // Create ONE CSV file.
    // ============================================================

    public void finish(
        Database.BatchableContext bc
    ) {

        String header =
            'Account Name,' +
            'Account Id,' +
            'Latest Visit Id,' +
            'Latest Visit Date,' +
            'Previous Visit Id,' +
            'Previous Visit Date,' +
            'Product,' +
            'Product Id,' +
            'Visit Job Id,' +
            'Previous OOS,' +
            'Latest OOS,' +
            'Expected OOS Number,' +
            'Actual OOS Number,' +
            'Difference,' +
            'Result\n';


        String csvData =
            header;


        for (
            String row :
            mismatchRows
        ) {

            csvData +=
                row +
                '\n';
        }


        // ========================================================
        // CREATE ONE SALESFORCE FILE
        // ========================================================

        ContentVersion cv =
            new ContentVersion();


        cv.Title =
            'TPB OOS Validation Mismatches';


        cv.PathOnClient =
            'TPB_OOS_Validation_Mismatches.csv';


        cv.VersionData =
            Blob.valueOf(
                csvData
            );


        cv.IsMajorVersion = true;


        insert cv;


        // ========================================================
        // SUMMARY
        // ========================================================

        System.debug(
            '======================================================'
        );


        System.debug(
            'TPB OOS VALIDATION COMPLETE'
        );


        System.debug(
            'Total combinations checked: ' +
            totalChecked
        );


        System.debug(
            'Total mismatches: ' +
            totalMismatches
        );


        System.debug(
            'Activity Products not found: ' +
            activityProductNotFound
        );


        System.debug(
            'CSV ContentVersion Id: ' +
            cv.Id
        );


        System.debug(
            '======================================================'
        );
    }
}