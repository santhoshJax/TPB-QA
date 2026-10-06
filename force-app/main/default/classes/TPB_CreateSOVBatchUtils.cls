/**
 * @author Guanshu Wang
 * @date 6/5/2023
 * @description Create SOV Batch Utils
 */
public with sharing class TPB_CreateSOVBatchUtils {
  private TPB_CreateSOVBatchUtils() {
  }
  /**
   * @description convert activit list to map
   * @author Guanshu Wang
   * @param  paramActivityList Activity product list
   * @return                   return activity id 2 account id map
   */
  public static Map<Id, Id> getActivityId2AccountIdMap(
    List<cgcloud__Job_Definition_List__c> paramActivityList
  ) {
    // Query activity customer by activity id
    List<cgcloud__Job_Definition_List_Account__c> activityCustomerList = [
      SELECT Id, cgcloud__Job_Definition_List__c, cgcloud__Account__c
      FROM cgcloud__Job_Definition_List_Account__c
      WHERE cgcloud__Job_Definition_List__c = :paramActivityList
    ];
    Map<Id, Id> returnActivityId2AccountIdMap = new Map<Id, Id>();
    // List to Map in loop
    for (
      cgcloud__Job_Definition_List_Account__c activityAccountItem : activityCustomerList
    ) {
      if (
        !returnActivityId2AccountIdMap.containsKey(
          activityAccountItem.cgcloud__Job_Definition_List__c
        )
      ) {
        // Activity id to account id Map
        returnActivityId2AccountIdMap.put(
          activityAccountItem.cgcloud__Job_Definition_List__c,
          activityAccountItem.cgcloud__Account__c
        );
      }
    }
    return returnActivityId2AccountIdMap;
  }
  /**
   * @description convert activity list to map
   * @author Guanshu Wang
   * @param  paramActivityList Activity list
   * @return                   return activity id 2 activity product
   */
  public static Map<Id, List<cgcloud__Job_Definition_List_Product__c>> getActivityId2ActivityProductMap(
    List<cgcloud__Job_Definition_List__c> paramActivityList
  ) {
    // Query activity product by activity id
    List<cgcloud__Job_Definition_List_Product__c> activityProductList = [
      SELECT
        Id,
        cgcloud__Product__c,
        cgcloud__Job_Definition_List__c,
        TPB_EOV__c,
        TPB_OOS_Number__c,
        TPB_Account__c,
        TPB_Visit_Job__c
      FROM cgcloud__Job_Definition_List_Product__c
      WHERE cgcloud__Job_Definition_List__c = :paramActivityList
    ];
    // New a activity id 2 activity product map
    Map<Id, List<cgcloud__Job_Definition_List_Product__c>> returnActivityId2ActivityProductMap = new Map<Id, List<cgcloud__Job_Definition_List_Product__c>>();
    // Convert list to map
    for (
      cgcloud__Job_Definition_List_Product__c activityProductItem : activityProductList
    ) {
      if (
        !returnActivityId2ActivityProductMap.containsKey(
          activityProductItem.cgcloud__Job_Definition_List__c
        )
      ) {
        // Create new list
        returnActivityId2ActivityProductMap.put(
          activityProductItem.cgcloud__Job_Definition_List__c,
          new List<cgcloud__Job_Definition_List_Product__c>()
        );
      }
      // Add activity product to list in map
      returnActivityId2ActivityProductMap.get(
          activityProductItem.cgcloud__Job_Definition_List__c
        )
        .add(activityProductItem);
    }
    // Add activity without activity product to map
    for (cgcloud__Job_Definition_List__c activityItem : paramActivityList) {
      if (!returnActivityId2ActivityProductMap.containsKey(activityItem.Id)) {
        returnActivityId2ActivityProductMap.put(
          activityItem.Id,
          new List<cgcloud__Job_Definition_List_Product__c>()
        );
      }
    }
    return returnActivityId2ActivityProductMap;
  }
  /**
   * @description convert visit map to account2visit map
   * @author Guanshu Wang
   * @param  paramVisitMap visit map
   * @return               return account id 2 visit map
   */
  public static Map<Id, Visit> getAccountId2VisitMap(
    Map<Id, Visit> paramVisitMap
  ) {
    Map<Id, Visit> returnAccountToVisitMap = new Map<Id, Visit>();
    for (Visit visitItem : paramVisitMap.values()) {
      if (!returnAccountToVisitMap.containsKey(visitItem.AccountId)) {
        returnAccountToVisitMap.put(visitItem.AccountId, visitItem);
      }
    }
    return returnAccountToVisitMap;
  }
  /**
   * @description get visit id 2 visit job map
   * @author Guanshu Wang
   * @param  paramLastVisitList  Last Visit List
   * @param  paramLast2VisitList Last but not one Visit List
   * @return                     return visit id 2 visit job list map
   */
  public static Map<Id, List<cgcloud__Visit_Job__c>> getVisitId2VisitJobMap(
    List<Visit> paramLastVisitList,
    List<Visit> paramLast2VisitList
  ) {
    // Get VisitId
    Set<Id> visitIdSet = new Set<Id>();
    for (Visit item : paramLastVisitList) {
      visitIdSet.add(item.Id);
    }
    for (Visit item : paramLast2VisitList) {
      visitIdSet.add(item.Id);
    }
    List<cgcloud__Visit_Job__c> visitJobList = [
      SELECT
        Id,
        cgcloud__Product__c,
        TPB_EOV__c,
        TPB_SOV__c,
        cgcloud__Visit__c,
        Calculated_Distribution__c,
        cgcloud__Visit__r.AccountId,
        TPB_Calculated_EOV__c
      FROM cgcloud__Visit_Job__c
      WHERE cgcloud__Visit__c = :visitIdSet AND cgcloud__Product__c != NULL
    ];
    Map<Id, List<cgcloud__Visit_Job__c>> returnVisitId2VisitJobMap = new Map<Id, List<cgcloud__Visit_Job__c>>();
    for (cgcloud__Visit_Job__c item : visitJobList) {
      if (!returnVisitId2VisitJobMap.containsKey(item.cgcloud__Visit__c)) {
        returnVisitId2VisitJobMap.put(
          item.cgcloud__Visit__c,
          new List<cgcloud__Visit_Job__c>()
        );
      }
      returnVisitId2VisitJobMap.get(item.cgcloud__Visit__c).add(item);
    }
    return returnVisitId2VisitJobMap;
  }

  /**
   * @description check if porduct is in activity product list
   * @author Guanshu Wang
   * @param  paramVisitJob            current visit job
   * @param  paramActivityProductList activity product
   * @return                          return boolean
   */
  public static Boolean checkProductInActivityProduct(
    cgcloud__Visit_Job__c paramVisitJob,
    List<cgcloud__Job_Definition_List_Product__c> paramActivityProductList
  ) {
    Boolean returnNotExist = true;
    for (
      cgcloud__Job_Definition_List_Product__c item : paramActivityProductList
    ) {
      if (item.cgcloud__Product__c == paramVisitJob.cgcloud__Product__c) {
        returnNotExist = false;
        return returnNotExist;
      }
    }
    return returnNotExist;
  }
  /**
   * @description get activity product by visit job
   * @author Guanshu Wang
   * @param  paramVisitJob            current visit job
   * @param  paramActivityProductList activity product list
   * @return                          return activity product item
   */
  public static cgcloud__Job_Definition_List_Product__c getOldActivityProductByVisitJob(
    cgcloud__Visit_Job__c paramVisitJob,
    List<cgcloud__Job_Definition_List_Product__c> paramActivityProductList
  ) {
    cgcloud__Job_Definition_List_Product__c returnActivityProduct = new cgcloud__Job_Definition_List_Product__c();
    for (
      cgcloud__Job_Definition_List_Product__c item : paramActivityProductList
    ) {
      if (item.cgcloud__Product__c == paramVisitJob.cgcloud__Product__c) {
        returnActivityProduct = item;
      }
    }
    return returnActivityProduct;
  }
  /**
   * @description check if product is in last but not one visit
   * @author Guanshu Wang
   * @param  paramLastVisitJobItem  last visit job
   * @param  paramLast2VisitJobList last 2 visit job
   * @return                        return boolean
   */
  public static Boolean checkProductInLast2Visit(
    cgcloud__Visit_Job__c paramLastVisitJobItem,
    List<cgcloud__Visit_Job__c> paramLast2VisitJobList
  ) {
    Boolean returnExist = false;
    for (cgcloud__Visit_Job__c item : paramLast2VisitJobList) {
      if (
        paramLastVisitJobItem.cgcloud__Product__c == item.cgcloud__Product__c
      ) {
        returnExist = true;
      }
    }
    return returnExist;
  }
  /**
   * @description get last visit job EOV value
   * @author Guanshu Wang
   * @param  paramLastVisitJobItem  current visit job item
   * @param  paramLast2VisitJobList last visit job list
   * @return                        return EOV string
   */
  public static String getLast2VisitJobItemEOV(
    cgcloud__Visit_Job__c paramLastVisitJobItem,
    List<cgcloud__Visit_Job__c> paramLast2VisitJobList
  ) {
    cgcloud__Visit_Job__c returnVisitJob = new cgcloud__Visit_Job__c();
    for (cgcloud__Visit_Job__c item : paramLast2VisitJobList) {
      if (
        paramLastVisitJobItem.cgcloud__Product__c == item.cgcloud__Product__c
      ) {
        returnVisitJob = item;
      }
    }
    String returnItemEOV = returnVisitJob.TPB_Calculated_EOV__c;
    if (returnVisitJob.Calculated_Distribution__c != null) {
      returnItemEOV = returnVisitJob.Calculated_Distribution__c;
    }
    return returnItemEOV;
  }

  /**
   * @description update Activity Product
   * @author Guanshu Wang
   * @param  paramActivityProductItem Activity Product Item
   * @param  paramVisitJob            Visit Job
   * @return                          Return Activity Product Item
   */
  public static cgcloud__Job_Definition_List_Product__c updateActivityProductAccountId(
    cgcloud__Job_Definition_List_Product__c paramActivityProductItem,
    cgcloud__Visit_Job__c paramVisitJob
  ) {
    if (
      paramActivityProductItem.TPB_Account__c !=
      paramVisitJob.cgcloud__Visit__r.AccountId
    ) {
      paramActivityProductItem.TPB_Account__c = paramVisitJob.cgcloud__Visit__r.AccountId;
    }
    return paramActivityProductItem;
  }
  /**
   * @description update Activity Product
   * @author Guanshu Wang
   * @param  paramActivityProductItem Activity Product Item
   * @param  paramVisitJob            Visit Job
   * @param  paramVisitJobEovValueStr EOV Value
   * @return                          Return Activity Product Item
   */
  public static cgcloud__Job_Definition_List_Product__c updateActivityProductOOSNumber(
    cgcloud__Job_Definition_List_Product__c paramActivityProductItem,
    cgcloud__Visit_Job__c paramVisitJob,
    String paramVisitJobEovValueStr
  ) {
    if (
      paramVisitJob.TPB_Calculated_EOV__c == paramVisitJobEovValueStr ||
      paramVisitJob.Calculated_Distribution__c == paramVisitJobEovValueStr
    ) {
      if (paramActivityProductItem.TPB_OOS_Number__c == null) {
        paramActivityProductItem.TPB_OOS_Number__c = 0;
      }
      paramActivityProductItem.TPB_OOS_Number__c++;
    } else {
      // Reset Number as 0
      paramActivityProductItem.TPB_OOS_Number__c = 0;
    }
    //Activity Product TPB_Calculated_Distribution__c
    if (paramActivityProductItem.TPB_Visit_Job__c != paramVisitJob.Id) {
      paramActivityProductItem.TPB_Visit_Job__c = paramVisitJob.Id;
    }
    return paramActivityProductItem;
  }
}