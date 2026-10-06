/**
 * @author: Zeen Liu
 * date:2/7/2023
 * @description EOV Calculation of Visit Job.
 */
public class TPB_VisitJobEOVCalcuBatch implements Database.Batchable<sObject> {
  //create query
  String query;
  /**
   * @description start description
   * @param   bc description
   * @return  return description
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    //return Database.getQueryLocator
    return Database.getQueryLocator(query);
  }
  /**
   * @description Constructor class
   */
  public TPB_VisitJobEOVCalcuBatch() {
    //query Visit data
    this.query = 'SELECT ID,AccountId FROM Visit WHERE ActualVisitEndTime >= LAST_N_DAYS:30 AND Status = \'Completed\' AND TPB_EOV_Done__c = false ORDER BY ActualVisitEndTime ASC';
  }
  /**
   * @description Constructor class
   * @param  query     Query statement
   */
  public TPB_VisitJobEOVCalcuBatch(String query) {
    //Assignment query
    this.query = query;
  }
  /**
   * @description Get Map Activity To Quenstion
   * @author Guanshu Wang
   * @param  mapAcocuntIdToActivity Account id to Activity
   * @return                        Map Id - Id
   */
  public static Map<Id, Id> getMapActivityToQuestion(
    Map<Id, Id> mapAcocuntIdToActivity
  ) {
    //query cgcloud__Job_DL_Job_Definition_Template__c data
    List<cgcloud__Job_DL_Job_Definition_Template__c> listQuestion = [
      SELECT Id, cgcloud__Job_Definition_List__c
      FROM cgcloud__Job_DL_Job_Definition_Template__c
      WHERE cgcloud__Job_Definition_List__c = :mapAcocuntIdToActivity.values()
    ];
    //crate mapActivityToQuestion map
    Map<Id, Id> mapActivityToQuestion = new Map<Id, Id>();
    for (cgcloud__Job_DL_Job_Definition_Template__c item : listQuestion) {
      mapActivityToQuestion.put(item.cgcloud__Job_Definition_List__c, item.Id);
    }

    //return mapActivityToQuestion
    return mapActivityToQuestion;
  }
  /**
   * @description Get Map Account To Activity
   * @author Guanshu Wang
   * @param  mapVisitToAccount Visit to Account Map
   * @return                   Map Id - Id
   */
  public static Map<Id, Id> getMapAcocuntIdToActivity(
    Map<Id, Id> mapVisitToAccount
  ) {
    //query cgcloud__Job_Definition_List_Account__c data
    List<cgcloud__Job_Definition_List_Account__c> listActivityAccount = [
      SELECT Id, cgcloud__Account__c, cgcloud__Job_Definition_List__c
      FROM cgcloud__Job_Definition_List_Account__c
      WHERE cgcloud__Account__c = :mapVisitToAccount.values()
    ];
    //create mapAccountIdToActivity map
    Map<Id, Id> mapAcocuntIdToActivity = new Map<Id, Id>();
    for (cgcloud__Job_Definition_List_Account__c item : listActivityAccount) {
      mapAcocuntIdToActivity.put(
        item.cgcloud__Account__c,
        item.cgcloud__Job_Definition_List__c
      );
    }

    //return mapAcocuntIdToActivity
    return mapAcocuntIdToActivity;
  }
  /**
   * @description Get Visit Id Set
   * @author Guanshu Wang
   * @param  visitList List Visit
   * @return           Set Vist Id
   */
  public Set<Id> getVisitIdSet(List<Visit> visitList) {
    //create visit set
    Set<Id> setVisitId = new Set<Id>();
    for (Visit item : visitList) {
      setVisitId.add(item.Id);
    }

    //return setVisitId
    return setVisitId;
  }

  /**
   * @description getVisitById
   * @param  paramVisitList List<Visit>
   * @param  paramVisitId   Id
   * @return returnVisit    Set visit Id
   */
  public Visit getVisitById(List<Visit> paramVisitList, Id paramVisitId) {
    //Assignment  visit
    Visit returnVisit = new Visit();
    for (Visit item : paramVisitList) {
      if (item.Id == paramVisitId) {
        returnVisit = item;
      }
    }

    //return returnVisit
    return returnVisit;
  }

  /**
   * @description getVisit2AccountMap
   * @param  visitList List<Visit>
   * @return mapVisitToAccount  Map<Id, Id>
   */
  public Map<Id, Id> getVisit2AccountMap(List<Visit> visitList) {
    //create visit map
    Map<Id, Id> mapVisitToAccount = new Map<Id, Id>();
    for (Visit item : visitList) {
      mapVisitToAccount.put(item.Id, item.AccountId);
    }

    //return mapVisitToAccount map
    return mapVisitToAccount;
  }

  /**
   * @description updateVisitByVisitId
   * @param  paramVisitIdSet Set<Id>
   * @param  paramVisitList  List<Visit>
   */
  public void updateVisitByVisitId(
    Set<Id> paramVisitIdSet,
    List<Visit> paramVisitList
  ) {
    //create visit list
    List<Visit> updateVisitList = new List<Visit>();
    for (Id visitId : paramVisitIdSet) {
      //getVisitById
      Visit visitItem = getVisitById(paramVisitList, visitId);
      visitItem.TPB_EOV_Done__c = true;
      updateVisitList.add(visitItem);
    }
    //update TPB_EOV_Done__c on visit
    update updateVisitList;
  }
  /**
   * @description Get Visit Job List
   * @author Guanshu Wang
   * @param  paramSetVisitId Visit Id Set
   * @return                 return item
   */
  public List<cgcloud__Visit_Job__c> getVisitJobList(Set<Id> paramSetVisitId) {
    List<cgcloud__Visit_Job__c> visitJobList = [
      SELECT
        ID,
        TPB_EOV__c,
        cgcloud__Product__c,
        cgcloud__Visit__c,
        cgcloud__Value__c,
        Distribution_Source__c
      FROM cgcloud__Visit_Job__c
      WHERE
        cgcloud__Product__r.cgcloud__Product_Template__r.RecordType.DeveloperName = 'Product'
        AND cgcloud__Visit__c = :paramSetVisitId
    ];
    return visitJobList;
  }
  /**
   * @description get Data Type Item
   * @author Guanshu Wang
   * @return   Return  item
   */
  public cgcloud__Data_Type__c getDataTypeItem() {
    cgcloud__Data_Type__c dataTypeItem = [
      SELECT Id
      FROM cgcloud__Data_Type__c
      WHERE cgcloud__Sales_Org__c = '0001' AND Name = 'DomPrdDistributed'
    ][0];
    return dataTypeItem;
  }
  /**
   * @description get Job Definition Template
   * @author Guanshu Wang
   * @return   return item
   */
  public cgcloud__Job_Definition_Template__c getJDTemplateItem() {
    cgcloud__Job_Definition_Template__c jDTemplateItem = [
      SELECT Id
      FROM cgcloud__Job_Definition_Template__c
      WHERE
        cgcloud__Sales_Org__c = '0001'
        AND cgcloud__Description__c = 'Distribution'
    ][0];
    return jDTemplateItem;
  }
  /**
   * @description get  DataType Option Item
   * @author Guanshu Wang
   * @param  paramDataTypeItem Data Type Item
   * @return                   return item
   */
  public cgcloud__Data_Type_Option__c getDataTypeOptionItem(
    cgcloud__Data_Type__c paramDataTypeItem
  ) {
    cgcloud__Data_Type_Option__c dataTypeOptionItem = [
      SELECT Id
      FROM cgcloud__Data_Type_Option__c
      WHERE
        cgcloud__Description__c = 'Distributed'
        AND cgcloud__Data_Type__c = :paramDataTypeItem.Id
    ][0];
    return dataTypeOptionItem;
  }
  /**
   * @description execute description
   * @param  bc                bc description
   * @param  visitList records description
   */
  public void execute(Database.BatchableContext bc, List<Visit> visitList) {
    //getVisitIdSet
    Set<Id> setVisitId = getVisitIdSet(visitList);
    // SAL-281 Distribution Origin Tracking: map each visit to whether it was ended via the
    // online app. End_Visit_Online__c is set true by TPBOnlineAppVisitProcess; false => offline app.
    // Queried directly off the visit Ids so it is independent of the batch's start query.
    Map<Id, Boolean> mapVisitToEndOnline = new Map<Id, Boolean>();
    for (Visit v : [SELECT Id, End_Visit_Online__c FROM Visit WHERE Id IN :setVisitId]) {
      mapVisitToEndOnline.put(v.Id, v.End_Visit_Online__c == true);
    }
    //query cgcloud__Visit_Job__c list
    List<cgcloud__Visit_Job__c> visitJobList = getVisitJobList(setVisitId);
    Map<Id, List<cgcloud__Visit_Job__c>> mapVisitToVisitJob = new Map<Id, List<cgcloud__Visit_Job__c>>();
    Map<Id, cgcloud__Visit_Job__c> updateVisitJobs = new Map<Id, cgcloud__Visit_Job__c>();
    List<cgcloud__Visit_Job__c> insertVisitJob = new List<cgcloud__Visit_Job__c>();
    //query cgcloud__Job_Definition_Template__c data
    cgcloud__Job_Definition_Template__c jDTemplateItem = getJDTemplateItem();
    //query cgcloud__Data_Type__c data
    cgcloud__Data_Type__c dataTypeItem = getDataTypeItem();
    //query cgcloud__Data_Type_Option__c data
    cgcloud__Data_Type_Option__c dataTypeOptionItem = getDataTypeOptionItem(
      dataTypeItem
    );
    //foreach visitJobList data
    Set<String> setProductIdForDuplicate = new Set<String>();
    for (cgcloud__Visit_Job__c visitJob : visitJobList) {
      if (!mapVisitToVisitJob.containsKey(visitJob.cgcloud__Visit__c)) {
        mapVisitToVisitJob.put(
          visitJob.cgcloud__Visit__c,
          new List<cgcloud__Visit_Job__c>()
        );
      }
      visitJob.TPB_EOV__c = visitJob.cgcloud__Value__c;
      // SAL-281: stamp distribution origin from the visit's channel if not already set
      // (preserves Scanner / Online App attribution made at distribution time).
      // SAL-281b: offline default is 'Offline Manual'; the order-item loop below upgrades to
      // 'Offline Scanner' for any line the offline app flagged as scanned.
      if (String.isBlank(visitJob.Distribution_Source__c)) {
        visitJob.Distribution_Source__c = mapVisitToEndOnline.get(visitJob.cgcloud__Visit__c) == true
          ? 'Online App'
          : 'Offline Manual';
      }
      mapVisitToVisitJob.get(visitJob.cgcloud__Visit__c).add(visitJob);
      updateVisitJobs.put(visitJob.Id, visitJob);
    }
    //getVisit2AccountMap
    Map<Id, Id> mapVisitToAccount = getVisit2AccountMap(visitList);
    //getMapAcocuntIdToActivity
    Map<Id, Id> mapAcocuntIdToActivity = getMapAcocuntIdToActivity(
      mapVisitToAccount
    );
    //getMapActivityToQuestion
    Map<Id, Id> mapActivityToQuestion = getMapActivityToQuestion(
      mapAcocuntIdToActivity
    );
    //query cgcloud__Order_Item__c data
    for (cgcloud__Order_Item__c orderItem : [
      SELECT
        Id,
        cgcloud__Product__c,
        TPB_Via_Scanner__c,
        cgcloud__Order__r.cgcloud__Visit__c,
        cgcloud__Order__r.cgcloud__Visit__r.ActualVisitEndTime
      FROM cgcloud__Order_Item__c
      WHERE
        cgcloud__Order__r.cgcloud__Visit__c IN :setVisitId
        AND (cgcloud__Order_Item_Template__r.Name = 'Cash Sale'
        OR cgcloud__Order_Item_Template__r.Name = 'Free Item')
        AND cgcloud__Quantity__c > 0
        AND cgcloud__Order__r.cgcloud__Phase__c = 'Released'
    ]) {
      //get mapVisitToVisitJob data
      String stringVisitId = orderItem.cgcloud__Order__r.cgcloud__Visit__c;
      String stringProductId = orderItem.cgcloud__Product__c;
      Boolean hasVisitJob = false;
      if (
        mapVisitToVisitJob.containsKey(
          orderItem.cgcloud__Order__r.cgcloud__Visit__c
        )
      ) {
        //get mapVisitToVisitJob data
        for (
          cgcloud__Visit_Job__c visitJob : mapVisitToVisitJob.get(
            orderItem.cgcloud__Order__r.cgcloud__Visit__c
          )
        ) {
          //cgcloud__Product__c == orderItem.cgcloud__Product__c   continue
          if (visitJob.cgcloud__Product__c == orderItem.cgcloud__Product__c) {
            hasVisitJob = true;
            visitJob.TPB_EOV__c = 'Distributed';
            // SAL-281b: a scanned offline line that matches a pre-planned product VJ.
            // The first loop already stamped it 'Offline Manual'; scanner is more-specific
            // attribution so override here (not stamp-if-blank).
            if (orderItem.TPB_Via_Scanner__c == true) {
              visitJob.Distribution_Source__c = 'Offline Scanner';
              visitJob.Via_Scanner__c = true;
            }
            updateVisitJobs.put(visitJob.Id, visitJob);
            continue;
          }
        }
      }
      //hasVisitJob == false
      if (
        hasVisitJob == false &&
        !setProductIdForDuplicate.contains(stringVisitId + stringProductId)
      ) {
        Id questionId = mapActivityToQuestion.get(
          mapAcocuntIdToActivity.get(
            mapVisitToAccount.get(orderItem.cgcloud__Order__r.cgcloud__Visit__c)
          )
        );
        // New Visit Job For Add Product
        //create cgcloud__Visit_Job__c data
        cgcloud__Visit_Job__c newVisitJobItem = new cgcloud__Visit_Job__c(
          TPB_EOV__c = 'Distributed',
          cgcloud__Manually__c = true,
          // SAL-281 / SAL-281b: order-derived VJ inherits the visit's channel; offline splits
          // into Offline Scanner vs Offline Manual on the order item's scan flag.
          Distribution_Source__c = mapVisitToEndOnline.get(orderItem.cgcloud__Order__r.cgcloud__Visit__c) == true
            ? 'Online App'
            : (orderItem.TPB_Via_Scanner__c == true ? 'Offline Scanner' : 'Offline Manual'),
          cgcloud__Product__c = orderItem.cgcloud__Product__c,
          cgcloud__Visit__c = orderItem.cgcloud__Order__r.cgcloud__Visit__c,
          cgcloud__Job_Definition__c = questionId,
          cgcloud__Job_Definition_Template__c = jDTemplateItem.Id,
          cgcloud__Data_Type_Option__c = dataTypeOptionItem.Id,
          cgcloud__Done__c = true,
          cgcloud__Value__c = 'Distributed',
          cgcloud__Visit_Date__c = orderItem.cgcloud__Order__r.cgcloud__Visit__r.ActualVisitEndTime.date()
        );
        insertVisitJob.add(newVisitJobItem);
      }
      //add setProductIdForDuplicate set
      setProductIdForDuplicate.add(stringVisitId + stringProductId);
    }
    //updateVisitByVisitId
    updateVisitByVisitId(setVisitId, visitList);
    //update TPB_EOV__c on visit jobs
    update updateVisitJobs.values();
    //insert new visit jobs
    insert insertVisitJob;
  }

  /**
   * @description finish description
   * @param  bc bc description
   */
  public void finish(Database.BatchableContext bc) {
    //query = ''
    query = '';
  }
}