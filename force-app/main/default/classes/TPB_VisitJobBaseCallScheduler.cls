/**
 * @author Mi Li
 * @date 3/1/2023
 * @description TPB_VisitJobBaseCallBatch:  Executed at 1:00 a.m. on January 1 every year
 * system.schedule('Executed at 1:00 a.m. on January 1 every year', '0 0 1 1 1 ?', new TPB_VisitJobBaseCallScheduler());
 */
public with sharing class TPB_VisitJobBaseCallScheduler implements Schedulable {
  private String strType;
  //is Test
  private Boolean boolRunTest;

  /**
   * @description Constructor class
   * @param  strType   statement
   * @param  boolRunTest   statement
   */
  public TPB_VisitJobBaseCallScheduler(String strType, Boolean boolRunTest) {
    this.strType = strType;
    this.boolRunTest = boolRunTest;
  }

  /**
   * @description execute description
   * @param  sc sc description
   */
  public void execute(SchedulableContext sc) {
    Database.executeBatch(
      new TPB_VisitJobBaseCallBatch(strType, boolRunTest),
      200
    );
  }
}