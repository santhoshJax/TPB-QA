/**
 * @date 2026-08-28
 * @description Audit tool: for every Account, checks whether the rep's raw OOS (Out of Stock)
 *              answer (cgcloud__Value__c) on that Account's most recent completed Visit is
 *              correctly reflected on the matching Activity Product
 *              (cgcloud__Job_Definition_List_Product__c), linked via TPB_Account__c (the
 *              "Activity Customer" relationship, cgcloud__Job_Definition_List_Account__c).
 *              Emails a CSV report of any exceptions found (mismatches and never-created
 *              records). Records that were legitimately removed by TPB_CreateSOVBatch's
 *              3-consecutive-OOS delisting rule are reported separately and are not treated
 *              as defects.
 *
 *              MISMATCH rows are further broken down by MismatchReason:
 *                - CASH_SALE_OR_FREE_ITEM_OVERRIDE: TPB_VisitJobEOVCalcuBatch legitimately
 *                  overrode the raw answer because a matching Cash Sale/Free Item order was
 *                  Released for that exact visit+product. Not a bug.
 *                - OLDER_VISIT_PROCESSED_LATER: the Activity Product's last-synced Visit Job
 *                  does not match this visit's Visit Job - TPB_CreateSOVBatch actually synced
 *                  from a different (typically older, out-of-order-processed) visit. Confirmed
 *                  bug, fixed in TPB_CreateSOVBatch.execute() via the newerVisitAlreadySynced
 *                  guard.
 *                - CALCULATED_DISTRIBUTION_FIELD_OVERRIDE: Calculated_Distribution__c is
 *                  populated and differs from the raw answer - TPB_Calculated_EOV__c's formula
 *                  always trusts Calculated_Distribution__c over TPB_EOV__c when populated.
 *                  Traced to a stale-seeding gap in TPB_OnlineAppController.ensureVisitJobsExist().
 *                - UNEXPLAINED: none of the above apply - needs further investigation.
 *
 *              Usage (Execute Anonymous):
 *                Database.executeBatch(new TPB_LastVisitOOSAuditBatch('you@example.com'), 50);
 */
public with sharing class TPB_LastVisitOOSAuditBatch implements Database.Batchable<sObject>, Database.Stateful {
  private static final String OOS = 'OutOfStock';

  // Recipient(s) for the CSV report - comma separated
  private String recipientEmails;

  // Accumulated report rows (persists across execute() chunks via Database.Stateful)
  private List<String> reportRows = new List<String>();

  private Integer totalOosVisitJobsChecked = 0;
  private Integer totalOk = 0;
  private Integer totalMismatch = 0;
  private Integer totalLegitimatelyDeleted = 0;
  private Integer totalNeverExisted = 0;

  // MismatchReason breakdown
  private Integer totalCashSaleOverride = 0;
  private Integer totalOlderVisitProcessedLater = 0;
  private Integer totalCalculatedDistributionOverride = 0;
  private Integer totalUnexplained = 0;

  /**
   * @description Constructor
   * @param  emails comma-separated email address(es) to send the CSV report to
   */
  public TPB_LastVisitOOSAuditBatch(String emails) {
    this.recipientEmails = emails;
    reportRows.add(
      'Classification,MismatchReason,AccountId,AccountName,ProductId,ProductName,VisitId,VisitDate,VisitJobId,VisitJob_RawAnswer,Calculated_Distribution__c,ActivityProductId,ActivityProduct_EOV,ActivityProduct_LastSyncedVisitJob'
    );
  }

  /**
   * @description scope: every Account that has at least one completed Visit
   * @param  bc BatchableContext
   * @return    QueryLocator of Accounts to audit
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      [
        SELECT Id, Name
        FROM Account
        WHERE Id IN (SELECT AccountId FROM Visit WHERE ActualVisitEndTime != NULL)
      ]
    );
  }

  /**
   * @description For this chunk of accounts: find each account's last completed Visit, its
   *              raw-answer OOS Visit Jobs, and compare each against the matching Activity
   *              Product - classifying any mismatch by likely root cause.
   * @param  bc            BatchableContext
   * @param  scopeAccounts Account chunk
   */
  public void execute(Database.BatchableContext bc, List<Account> scopeAccounts) {
    Map<Id, Account> accountMap = new Map<Id, Account>(scopeAccounts);

    // 1. last completed Visit per account in this chunk
    Map<Id, Id> accountToLastVisitId = new Map<Id, Id>();
    for (
      Visit v : [
        SELECT Id, AccountId
        FROM Visit
        WHERE AccountId IN :accountMap.keySet() AND ActualVisitEndTime != NULL
        ORDER BY ActualVisitEndTime DESC
      ]
    ) {
      if (!accountToLastVisitId.containsKey(v.AccountId)) {
        accountToLastVisitId.put(v.AccountId, v.Id);
      }
    }
    if (accountToLastVisitId.isEmpty()) {
      return;
    }
    Set<Id> lastVisitIds = new Set<Id>(accountToLastVisitId.values());

    // 2. raw-answer OOS Visit Jobs on those last visits
    List<cgcloud__Visit_Job__c> oosVisitJobs = [
      SELECT
        Id,
        cgcloud__Visit__c,
        cgcloud__Visit__r.AccountId,
        cgcloud__Visit__r.ActualVisitEndTime,
        cgcloud__Product__c,
        cgcloud__Product__r.Name,
        cgcloud__Value__c,
        Calculated_Distribution__c
      FROM cgcloud__Visit_Job__c
      WHERE cgcloud__Visit__c IN :lastVisitIds AND cgcloud__Value__c = :OOS
    ];
    if (oosVisitJobs.isEmpty()) {
      return;
    }
    totalOosVisitJobsChecked += oosVisitJobs.size();

    Set<Id> productIds = new Set<Id>();
    for (cgcloud__Visit_Job__c vj : oosVisitJobs) {
      productIds.add(vj.cgcloud__Product__c);
    }

    // 3. matching Activity Products - linked by TPB_Account__c ("Activity Customer") + Product.
    //    ALL ROWS so we can tell "legitimately deleted" (3-strike rule) apart from "never existed".
    Map<String, cgcloud__Job_Definition_List_Product__c> activeKeyToAp = new Map<String, cgcloud__Job_Definition_List_Product__c>();
    Map<String, Boolean> keyIsDeleted = new Map<String, Boolean>();

    for (
      cgcloud__Job_Definition_List_Product__c ap : [
        SELECT Id, TPB_Account__c, cgcloud__Product__c, TPB_EOV__c, TPB_Visit_Job__c, IsDeleted
        FROM cgcloud__Job_Definition_List_Product__c
        WHERE TPB_Account__c IN :accountMap.keySet() AND cgcloud__Product__c IN :productIds
        ALL ROWS
      ]
    ) {
      String key = ap.TPB_Account__c + '-' + ap.cgcloud__Product__c;
      if (!ap.IsDeleted) {
        activeKeyToAp.put(key, ap);
      }
      // remember "ever existed" state; an active record always wins over a deleted one
      if (!keyIsDeleted.containsKey(key) || keyIsDeleted.get(key) == true) {
        keyIsDeleted.put(key, ap.IsDeleted);
      }
    }

    // 4. qualifying Cash Sale / Free Item order items on these visits - a legitimate reason
    //    TPB_VisitJobEOVCalcuBatch would have overridden the raw OOS answer to 'Distributed'.
    Set<String> cashSaleOverrideKeys = new Set<String>();
    for (
      cgcloud__Order_Item__c oi : [
        SELECT cgcloud__Product__c, cgcloud__Order__r.cgcloud__Visit__c
        FROM cgcloud__Order_Item__c
        WHERE
          cgcloud__Order__r.cgcloud__Visit__c IN :lastVisitIds
          AND (
            cgcloud__Order_Item_Template__r.Name = 'Cash Sale'
            OR cgcloud__Order_Item_Template__r.Name = 'Free Item'
          )
          AND cgcloud__Quantity__c > 0
          AND cgcloud__Order__r.cgcloud__Phase__c = 'Released'
      ]
    ) {
      cashSaleOverrideKeys.add(oi.cgcloud__Order__r.cgcloud__Visit__c + '-' + oi.cgcloud__Product__c);
    }

    // 5. classify each raw-answer OOS Visit Job
    for (cgcloud__Visit_Job__c vj : oosVisitJobs) {
      Id accId = vj.cgcloud__Visit__r.AccountId;
      String key = accId + '-' + vj.cgcloud__Product__c;
      Account acc = accountMap.get(accId);
      cgcloud__Job_Definition_List_Product__c ap = activeKeyToAp.get(key);

      String classification;
      String mismatchReason = '';
      Id apId = null;
      String apEov = null;
      Id apLastSyncedVisitJob = null;

      if (ap != null) {
        apId = ap.Id;
        apEov = ap.TPB_EOV__c;
        apLastSyncedVisitJob = ap.TPB_Visit_Job__c;
        if (ap.TPB_EOV__c == OOS) {
          classification = 'OK';
          totalOk++;
        } else {
          classification = 'MISMATCH';
          totalMismatch++;

          String orderKey = vj.cgcloud__Visit__c + '-' + vj.cgcloud__Product__c;
          if (cashSaleOverrideKeys.contains(orderKey)) {
            mismatchReason = 'CASH_SALE_OR_FREE_ITEM_OVERRIDE';
            totalCashSaleOverride++;
          } else if (ap.TPB_Visit_Job__c != vj.Id) {
            mismatchReason = 'OLDER_VISIT_PROCESSED_LATER';
            totalOlderVisitProcessedLater++;
          } else if (
            String.isNotBlank(vj.Calculated_Distribution__c) &&
            vj.Calculated_Distribution__c != vj.cgcloud__Value__c
          ) {
            mismatchReason = 'CALCULATED_DISTRIBUTION_FIELD_OVERRIDE';
            totalCalculatedDistributionOverride++;
          } else {
            mismatchReason = 'UNEXPLAINED';
            totalUnexplained++;
          }
        }
      } else if (keyIsDeleted.containsKey(key) && keyIsDeleted.get(key) == true) {
        classification = 'LEGITIMATELY_DELETED';
        totalLegitimatelyDeleted++;
      } else {
        classification = 'NEVER_EXISTED';
        totalNeverExisted++;
      }

      // only report exceptions - keep the report focused on what needs a human look
      if (classification != 'OK') {
        reportRows.add(
          String.join(
            new List<String>{
              classification,
              mismatchReason,
              String.valueOf(accId),
              csvEscape(acc != null ? acc.Name : ''),
              String.valueOf(vj.cgcloud__Product__c),
              csvEscape(vj.cgcloud__Product__r != null ? vj.cgcloud__Product__r.Name : ''),
              String.valueOf(vj.cgcloud__Visit__c),
              vj.cgcloud__Visit__r.ActualVisitEndTime != null
                ? String.valueOf(vj.cgcloud__Visit__r.ActualVisitEndTime.date())
                : '',
              String.valueOf(vj.Id),
              String.valueOf(vj.cgcloud__Value__c),
              vj.Calculated_Distribution__c != null ? vj.Calculated_Distribution__c : '',
              apId != null ? String.valueOf(apId) : '',
              apEov != null ? apEov : '',
              apLastSyncedVisitJob != null ? String.valueOf(apLastSyncedVisitJob) : ''
            },
            ','
          )
        );
      }
    }
  }

  /**
   * @description escapes a value for safe CSV output
   * @param  val raw value
   * @return     CSV-safe value
   */
  private String csvEscape(String val) {
    if (String.isBlank(val)) {
      return '';
    }
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"' + val.replace('"', '""') + '"';
    }
    return val;
  }

  // Test-only capture point: Database.Stateful instance state is not reliably readable
  // through the original object reference after Test.stopTest() (the platform can
  // serialize/deserialize a working copy for execute()/finish()). Static state set here
  // during finish() is visible to the test method afterward within the same transaction.
  @TestVisible
  private static Integer testTotalOosVisitJobsChecked;
  @TestVisible
  private static Integer testTotalOk;
  @TestVisible
  private static Integer testTotalMismatch;
  @TestVisible
  private static Integer testTotalLegitimatelyDeleted;
  @TestVisible
  private static Integer testTotalNeverExisted;
  @TestVisible
  private static Integer testTotalCashSaleOverride;
  @TestVisible
  private static Integer testTotalOlderVisitProcessedLater;
  @TestVisible
  private static Integer testTotalCalculatedDistributionOverride;
  @TestVisible
  private static Integer testTotalUnexplained;
  @TestVisible
  private static List<String> testReportRows;

  /**
   * @description builds and emails the CSV report
   * @param  bc BatchableContext
   */
  public void finish(Database.BatchableContext bc) {
    if (Test.isRunningTest()) {
      testTotalOosVisitJobsChecked = totalOosVisitJobsChecked;
      testTotalOk = totalOk;
      testTotalMismatch = totalMismatch;
      testTotalLegitimatelyDeleted = totalLegitimatelyDeleted;
      testTotalNeverExisted = totalNeverExisted;
      testTotalCashSaleOverride = totalCashSaleOverride;
      testTotalOlderVisitProcessedLater = totalOlderVisitProcessedLater;
      testTotalCalculatedDistributionOverride = totalCalculatedDistributionOverride;
      testTotalUnexplained = totalUnexplained;
      testReportRows = reportRows;
    }

    String summary =
      'Last-Visit OOS Audit complete.\n' +
      'OOS Visit Jobs checked: ' +
      totalOosVisitJobsChecked +
      '\n' +
      'OK (correctly synced): ' +
      totalOk +
      '\n' +
      'MISMATCH (Activity Product exists but wrong EOV): ' +
      totalMismatch +
      '\n' +
      '  - CASH_SALE_OR_FREE_ITEM_OVERRIDE (not a bug): ' +
      totalCashSaleOverride +
      '\n' +
      '  - OLDER_VISIT_PROCESSED_LATER (confirmed bug, fixed in TPB_CreateSOVBatch): ' +
      totalOlderVisitProcessedLater +
      '\n' +
      '  - CALCULATED_DISTRIBUTION_FIELD_OVERRIDE (Online App seeding gap): ' +
      totalCalculatedDistributionOverride +
      '\n' +
      '  - UNEXPLAINED (needs further investigation): ' +
      totalUnexplained +
      '\n' +
      'LEGITIMATELY_DELETED (3-strike OOS rule, not a bug): ' +
      totalLegitimatelyDeleted +
      '\n' +
      'NEVER_EXISTED (real gap - no Activity Product ever created): ' +
      totalNeverExisted +
      '\n\n' +
      'Full detail (exceptions only) attached as CSV.';

    Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
    csvAttachment.setFileName('Last_Visit_OOS_Audit_' + String.valueOf(Date.today()) + '.csv');
    csvAttachment.setBody(Blob.valueOf(String.join(reportRows, '\n')));
    csvAttachment.setContentType('text/csv');

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(recipientEmails.split(','));
    mail.setSubject('Last-Visit OOS vs Activity Product Audit Report');
    mail.setPlainTextBody(summary);
    mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttachment });

    if (!Test.isRunningTest()) {
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
  }
}