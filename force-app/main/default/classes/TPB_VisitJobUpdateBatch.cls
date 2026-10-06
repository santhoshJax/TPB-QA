/**
 * @author Mi Li
 * @date 9/26/2023
 * @description CON0001729-1981  MSA Calculated Distribution Updates
 */
public with sharing class TPB_VisitJobUpdateBatch implements Database.Batchable<sObject>, Schedulable {
  // query
  private String strQuery;
  //Product Group Ids
  private Set<Id> setVisitIds;
  //run date
  private Date datDate = System.today().addYears(-1);

  /**
   * @description Constructor class
   */
  public TPB_VisitJobUpdateBatch() {
    //Find all User data that needs to be generated
    this.strQuery = 'SELECT Id, Calculated_Distribution__c FROM cgcloud__Visit_Job__c WHERE Calculated_Distribution__c =null AND  cgcloud__Visit__r.Status = \'Completed\'  AND cgcloud__Visit__r.Last_Call__c = TRUE AND cgcloud__Visit__r.cgcloud__Completed_Date__c <=:datDate AND cgcloud__Visit__r.cgcloud__Visit_Template__c != NULL';
  }

  /**
   * @description Constructor class
   * @param  setVisitIds Visit ids
   */
  public TPB_VisitJobUpdateBatch(Set<Id> setVisitIds) {
    //Creating a Parametric Construction Method
    this.setVisitIds = setVisitIds;
    this.strQuery = 'SELECT Id, Calculated_Distribution__c FROM cgcloud__Visit_Job__c WHERE cgcloud__Visit__c IN: setVisitIds AND Calculated_Distribution__c =null AND  cgcloud__Visit__r.Status = \'Completed\'  AND cgcloud__Visit__r.Last_Call__c = TRUE AND cgcloud__Visit__r.cgcloud__Visit_Template__c != NULL';
  }

  /**
   * @description start description
   * @param   bc     description
   * @return  return description
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(strQuery);
  }

  /**
   * @description execute description
   * @param  bc         description
   * @param  lstVisitJob    description
   */
  public void execute(
    Database.BatchableContext bc,
    List<cgcloud__Visit_Job__c> lstVisitJob
  ) {
    //for each Visit
    //update
    if (lstVisitJob.size() > 0) {
      //query visit job data
      for (cgcloud__Visit_Job__c objVisitJob : lstVisitJob) {
        objVisitJob.Calculated_Distribution__c = 'OutOfStock';
      }

      //update visit job
      if (lstVisitJob.size() > 0) {
        update lstVisitJob;
      }
    }
  }

  /**
   * @description finish description
   * @param  bc description
   */
  public void finish(Database.BatchableContext bc) {
    strQuery = '';
  }

  /**
   * @description execute description
   * @param  sc sc description
   */
  public void execute(SchedulableContext sc) {
    Database.executeBatch(new TPB_VisitJobUpdateBatch(), 100);
  }
}