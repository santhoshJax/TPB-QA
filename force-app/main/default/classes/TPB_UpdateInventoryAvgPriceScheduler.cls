/**
 * @author Mi Li
 * @date 6/9/2023
 * @description TPB_UpdateInvPriceByOrderItemBatch:   Every 15 minutes.
 * system.schedule('TPB_UpdateInvPriceByOrderItemBatch', '0 15 * * * ?', new TPB_UpdateInventoryAvgPriceScheduler());
 */
public with sharing class TPB_UpdateInventoryAvgPriceScheduler implements Schedulable {
  // run Test Class
  private Boolean isRunTest = false;
  // batch query data time
  private String strRunDate = 'TODAY';
  //Product Group Ids
  private Set<Id> setProductGroupIds;

  /**
   * @description Constructor class
   * @param  strRunDate   statement
   * @param  isRunTest    statement
   * @param  setProductGroupIds    statement
   */
  public TPB_UpdateInventoryAvgPriceScheduler(
    String strRunDate,
    Boolean isRunTest,
    Set<Id> setProductGroupIds
  ) {
    this.strRunDate = strRunDate;
    this.isRunTest = isRunTest;
    this.setProductGroupIds = setProductGroupIds;
  }

  /**
   * @description execute description
   * @param  sc        SchedulableContext
   */
  public void execute(SchedulableContext sc) {
    TPB_UpdateInvPriceByOrderItemBatch objBatch = new TPB_UpdateInvPriceByOrderItemBatch(
      strRunDate,
      isRunTest,
      setProductGroupIds
    );
    Database.executeBatch(objBatch, 200);
  }
}