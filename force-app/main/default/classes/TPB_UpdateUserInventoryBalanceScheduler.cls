/**
 * @author Mi Li
 * @date 7/19/2023
 * @description TPB_UpdateUserInventoryBalanceBatch:   Performed at 1:30 a.m. daily.
 * system.schedule('TPB_UpdateUserInventoryBalanceBatch', '0 30 1 * * ?', new TPB_UpdateUserInventoryBalanceScheduler());
 */
public with sharing class TPB_UpdateUserInventoryBalanceScheduler implements Schedulable {
  // run Test Class
  public Boolean isRunTest = false;
  /**
   * @description execute description
   * @param  sc        SchedulableContext
   */
  public void execute(SchedulableContext sc) {
    TPB_UpdateUserInventoryBalanceBatch objBatch = new TPB_UpdateUserInventoryBalanceBatch();
    if (!isRunTest) {
      Database.executeBatch(objBatch, 1);
    }
  }
}