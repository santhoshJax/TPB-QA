/**
 * @author Guanshu Wang
 * @date 2/16/2023
 * @description Create SOV Based on Visit Job
 */
public with sharing class TPB_CreateSOVBatch implements Database.Batchable<sObject> {
  // Using Update Visit job dataset
  List<cgcloud__Visit_Job__c> updateVisitJob = new List<cgcloud__Visit_Job__c>();
  // Using Insert Activity Product
  Map<String, cgcloud__Job_Definition_List_Product__c> insertActivityProduct = new Map<String, cgcloud__Job_Definition_List_Product__c>();
  // Using delete Activity Product
  List<cgcloud__Job_Definition_List_Product__c> deleteActivityProduct = new List<cgcloud__Job_Definition_List_Product__c>();
  // Using update Activity Product
  List<cgcloud__Job_Definition_List_Product__c> updateActivityProduct = new List<cgcloud__Job_Definition_List_Product__c>();
  // Using update Visit
  List<Visit> updateVisit = new List<Visit>();
  String queryStr;
  // Check OOS Value of EOV
  String visitJobEovValueStr = 'OutOfStock';
  // Adjust Day Number
  Integer dayNumber = 30;
  /**
   * @description Constructed Function
   * @author Guanshu Wang
   * @param  queryStr query String
   */
  public TPB_CreateSOVBatch(String queryStr) {
    this.queryStr = queryStr;
  }
  /**
   * @description Constructed Function
   * @author Guanshu Wang
   * @param  dayNumber The Number to Adjust DateTime
   * @param  queryStr  Query String
   */
  public TPB_CreateSOVBatch(Integer dayNumber, String queryStr) {
    this.queryStr = queryStr;
    this.dayNumber = dayNumber;
  }
  /**
   * @description Constructed Function
   * @author Guanshu Wang
   * @param  dayNumber The Number to adjust DateTime
   */
  public TPB_CreateSOVBatch(Integer dayNumber) {
    this.dayNumber = dayNumber;
  }
  /**
   * @description Constructed Function
   * @author Guanshu Wang
   */
  public TPB_CreateSOVBatch() {
    queryStr = 'SELECT ID FROM cgcloud__Job_Definition_List__c WHERE cgcloud__Active__c = true';
    dayNumber = 30;
  }
  /**
   * @description Start Batch
   * @author Guanshu Wang
   * @param  bc BatchableContext
   * @return    return QueryLocator
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    // collect the batches of records or objects to be passed to execute
    return Database.getQueryLocator(queryStr);
  }
  /**
   * @description update Visit Job SOV field
   * @author Guanshu Wang
   * @param  paramLast2VisitId        Last Visit Id
   * @param  paramVisitId2VisitJobMap Visit Id to Visit Job
   * @param  paramVisitJob            Current Visit Job
   */
  public void updateVisitJobSOVField(
    Id paramLast2VisitId,
    Map<Id, List<cgcloud__Visit_Job__c>> paramVisitId2VisitJobMap,
    cgcloud__Visit_Job__c paramVisitJob
  ) {
    if (paramVisitId2VisitJobMap.containsKey(paramLast2VisitId)) {
      // Get Visit Job
      List<cgcloud__Visit_Job__c> last2VisitJobList = paramVisitId2VisitJobMap.get(
        paramLast2VisitId
      );
      if (
        TPB_CreateSOVBatchUtils.checkProductInLast2Visit(
          paramVisitJob,
          last2VisitJobList
        )
      ) {
        paramVisitJob.TPB_SOV__c = TPB_CreateSOVBatchUtils.getLast2VisitJobItemEOV(
          paramVisitJob,
          last2VisitJobList
        );
      }
    } else {
      paramVisitJob.TPB_SOV__c = null;
    }
    updateVisitJob.add(paramVisitJob);
  }
  /**
   * @description Loop Visit Job list to update
   * @author Guanshu Wang
   * @param  paramVisitJobList        Visit Job List for update
   * @param  paramActivityProductList Activity Product List for update and insert
   * @param  paramActivityItem        current Activity
   * @param  paramLast2VisitId        Last Visit Id
   * @param  paramVisitId2VisitJobMap Visit Id to Visit Job
   */
  public void loopVisitJob(
    List<cgcloud__Visit_Job__c> paramVisitJobList,
    List<cgcloud__Job_Definition_List_Product__c> paramActivityProductList,
    cgcloud__Job_Definition_List__c paramActivityItem,
    Id paramLast2VisitId,
    Map<Id, List<cgcloud__Visit_Job__c>> paramVisitId2VisitJobMap
  ) {
    // Loop Visit Job to Check Activity Product
    for (cgcloud__Visit_Job__c visitJobItem : paramVisitJobList) {
      // Check Activity Product
      if (
        TPB_CreateSOVBatchUtils.checkProductInActivityProduct(
          visitJobItem,
          paramActivityProductList
        )
      ) {
        // Activity Product not Exist
        cgcloud__Job_Definition_List_Product__c newActivityProduct = new cgcloud__Job_Definition_List_Product__c();
        newActivityProduct.cgcloud__Job_Definition_List__c = paramActivityItem.Id;
        newActivityProduct.cgcloud__Manually__c = false;
        newActivityProduct.cgcloud__Product__c = visitJobItem.cgcloud__Product__c;
        newActivityProduct.cgcloud__Sales_Org__c = '0001';
        newActivityProduct.TPB_EOV__c = visitJobItem.TPB_Calculated_EOV__c;
        newActivityProduct.TPB_Account__c = visitJobItem.cgcloud__Visit__r.AccountId;
        newActivityProduct.TPB_Visit_Job__c = visitJobItem.Id;
        // Store OOS Number
        if (
          visitJobItem.TPB_Calculated_EOV__c == visitJobEovValueStr ||
          visitJobItem.Calculated_Distribution__c == visitJobEovValueStr
        ) {
          newActivityProduct.TPB_OOS_Number__c = 1;
        } else {
          newActivityProduct.TPB_OOS_Number__c = 0;
        }
        String mapKey =
          String.valueOf(visitJobItem.cgcloud__Visit__c) +
          String.valueOf(visitJobItem.cgcloud__Product__c);
        if (insertActivityProduct.containsKey(mapKey)) {
          insertActivityProduct.get(mapKey)
            .TPB_OOS_Number__c = insertActivityProduct.get(mapKey)
              .TPB_OOS_Number__c > newActivityProduct.TPB_OOS_Number__c
            ? insertActivityProduct.get(mapKey).TPB_OOS_Number__c
            : newActivityProduct.TPB_OOS_Number__c;
        } else {
          insertActivityProduct.put(mapKey, newActivityProduct);
        }
      } else {
        // Activity Product is Exist
        cgcloud__Job_Definition_List_Product__c oldActivityProductItem = TPB_CreateSOVBatchUtils.getOldActivityProductByVisitJob(
          visitJobItem,
          paramActivityProductList
        );
        if (
          oldActivityProductItem.TPB_EOV__c !=
          visitJobItem.TPB_Calculated_EOV__c
        ) {
          oldActivityProductItem.TPB_EOV__c = visitJobItem.TPB_Calculated_EOV__c;
        }
        //Activity Product Account
        oldActivityProductItem = TPB_CreateSOVBatchUtils.updateActivityProductAccountId(
          oldActivityProductItem,
          visitJobItem
        );
        // Check Visit Job EOV Value == EOV
        oldActivityProductItem = TPB_CreateSOVBatchUtils.updateActivityProductOOSNumber(
          oldActivityProductItem,
          visitJobItem,
          visitJobEovValueStr
        );
        updateActivityProduct.add(oldActivityProductItem);
        // Check OOS Number to Delete
        if (oldActivityProductItem.TPB_OOS_Number__c == 3) {
          deleteActivityProduct.add(oldActivityProductItem);
        }
      }
      // Update Visit Job SOV field
      updateVisitJobSOVField(
        paramLast2VisitId,
        paramVisitId2VisitJobMap,
        visitJobItem
      );
    }
  }
  /**
   * @description Delete all activity product
   * @author Guanshu Wang
   * @param  paramActivityProductList Activity Product list
   */
  public void deleteAllActivityProdut(
    List<cgcloud__Job_Definition_List_Product__c> paramActivityProductList
  ) {
    deleteActivityProduct.addAll(paramActivityProductList);
  }
  /**
   * @description Remove duplicate item in list for DML
   * @author Guanshu Wang
   */
  public void removeDuplicateAndDML() {
    List<cgcloud__Visit_Job__c> updateVisitJobTemp = new List<cgcloud__Visit_Job__c>();
    // Using delete Activity Product
    List<cgcloud__Job_Definition_List_Product__c> deleteActivityProductTemp = new List<cgcloud__Job_Definition_List_Product__c>();
    // Using update Activity Product
    List<cgcloud__Job_Definition_List_Product__c> updateActivityProductTemp = new List<cgcloud__Job_Definition_List_Product__c>();
    for (cgcloud__Visit_Job__c item : updateVisitJob) {
      if (!updateVisitJobTemp.contains(item)) {
        updateVisitJobTemp.add(item);
      }
    }
    for (cgcloud__Job_Definition_List_Product__c item : updateActivityProduct) {
      if (!updateActivityProductTemp.contains(item)) {
        updateActivityProductTemp.add(item);
      }
    }
    for (cgcloud__Job_Definition_List_Product__c item : deleteActivityProduct) {
      if (!deleteActivityProductTemp.contains(item)) {
        deleteActivityProductTemp.add(item);
      }
    }
    // update
    update updateVisitJobTemp;
    // update activity product
    update updateActivityProductTemp;
    // delete activity product
    delete deleteActivityProductTemp;
  }
  /**
   * @description remove duplicate item and update visit list
   * @author Guanshu Wang
   */
  public void removeDuplicateAndDMLVisitList() {
    // Using update Visit
    List<Visit> updateVisitTemp = new List<Visit>();
    for (Visit item : updateVisit) {
      if (!updateVisitTemp.contains(item)) {
        updateVisitTemp.add(item);
      }
    }
    // update visit
    update updateVisitTemp;
  }
  /**
   * @description execute batch
   * @author Guanshu Wang
   * @param  bc                       batch context
   * @param  batchParamActivitiesList activity list
   */
  public void execute(
    Database.BatchableContext bc,
    List<cgcloud__Job_Definition_List__c> batchParamActivitiesList
  ) {
    // Get Activity to Account Map
    Map<Id, Id> activityId2AccountIdMap = TPB_CreateSOVBatchUtils.getActivityId2AccountIdMap(
      batchParamActivitiesList
    );
    // Get Activity to Activity Product Map
    Map<Id, List<cgcloud__Job_Definition_List_Product__c>> activityId2ActivityProductMap = TPB_CreateSOVBatchUtils.getActivityId2ActivityProductMap(
      batchParamActivitiesList
    );
    Map<Id, Visit> lastVisitListDesc = new Map<Id, Visit>(
      [
        SELECT ActualVisitEndTime, Id, AccountId, TPB_SOV_Done__c
        FROM Visit
        WHERE
          ActualVisitEndTime != NULL
          AND AccountId = :activityId2AccountIdMap.values()
          AND (TPB_Number_of_Distribution__c > 0
          OR Number_of_OOS__c > 0)
          AND TPB_SOV_Done__c = FALSE
        ORDER BY ActualVisitEndTime DESC
      ]
    );
    Map<Id, Visit> last2VisitListDesc = new Map<Id, Visit>(
      [
        SELECT ActualVisitEndTime, Id, AccountId, TPB_SOV_Done__c
        FROM Visit
        WHERE
          ActualVisitEndTime != NULL
          AND AccountId = :activityId2AccountIdMap.values()
          AND (TPB_Number_of_Distribution__c > 0
          OR Number_of_OOS__c > 0)
          AND TPB_SOV_Done__c = TRUE
        ORDER BY ActualVisitEndTime DESC
      ]
    );
    // Get Account to Last Visit Map
    Map<Id, Visit> accountId2LastVisitMap = TPB_CreateSOVBatchUtils.getAccountId2VisitMap(
      lastVisitListDesc
    );
    // Get Account to Last2 Visit Map
    Map<Id, Visit> accountId2LastTwoVisitMap = TPB_CreateSOVBatchUtils.getAccountId2VisitMap(
      last2VisitListDesc
    );
    // Get Visit to Visit Job Map
    Map<Id, List<cgcloud__Visit_Job__c>> visitId2VisitJobMap = TPB_CreateSOVBatchUtils.getVisitId2VisitJobMap(
      accountId2LastVisitMap.values(),
      accountId2LastTwoVisitMap.values()
    );
    // Loop Activity to Check Activity Product and Update Visit Job
    for (
      cgcloud__Job_Definition_List__c activityItem : batchParamActivitiesList
    ) {
      // Check Visit Date
      Id accountIdItem = activityId2AccountIdMap.get(activityItem.Id);
      if (accountId2LastVisitMap.containsKey(accountIdItem)) {
        Visit lastVisitItem = accountId2LastVisitMap.get(accountIdItem);
        Id last2VisitId = null;
        if (accountId2LastTwoVisitMap.containsKey(accountIdItem)) {
          last2VisitId = accountId2LastTwoVisitMap.get(accountIdItem).Id;
        }
        // Get Activity Product
        List<cgcloud__Job_Definition_List_Product__c> activityProductList = activityId2ActivityProductMap.get(
          activityItem.Id
        );
        // Guard against out-of-order processing: if a MORE RECENT visit for this
        // account has already been synced (TPB_SOV_Done__c = true with a later
        // ActualVisitEndTime), this older, backlogged visit must not be allowed to
        // overwrite that newer, correct sync.
        Boolean newerVisitAlreadySynced =
          accountId2LastTwoVisitMap.containsKey(accountIdItem) &&
          accountId2LastTwoVisitMap.get(accountIdItem).ActualVisitEndTime >
          lastVisitItem.ActualVisitEndTime;
        if (!newerVisitAlreadySynced) {
          if (
            lastVisitItem.ActualVisitEndTime.date().addDays(dayNumber) >=
            System.now().date() &&
            lastVisitItem.TPB_SOV_Done__c == false
          ) {
            // Get Visit Job
            List<cgcloud__Visit_Job__c> lastVisitJob = visitId2VisitJobMap.get(
              lastVisitItem.Id
            );
            // Create SOV and Update Visit Job
            loopVisitJob(
              lastVisitJob,
              activityProductList,
              activityItem,
              last2VisitId,
              visitId2VisitJobMap
            );
          } else if (
            lastVisitItem.ActualVisitEndTime.date().addYears(1) <=
            System.now().date() &&
            lastVisitItem.TPB_SOV_Done__c == false
          ) {
            // Delete Over One Year
            deleteAllActivityProdut(activityProductList);
          }
        }
        // update Visit - always mark done regardless, so this visit clears the
        // backlog and is never reprocessed again, even when superseded above.
        lastVisitItem.TPB_SOV_Done__c = true;
        updateVisit.add(lastVisitItem);
      }
    }
    // DML
    insert insertActivityProduct.values();
    removeDuplicateAndDML();
    removeDuplicateAndDMLVisitList();
  }
  /**
   * @description batch finish
   * @author Guanshu Wang
   * @param  bc batchableContext
   */
  public void finish(Database.BatchableContext bc) {
    // execute any post-processing operations
    queryStr = '';
  }
}