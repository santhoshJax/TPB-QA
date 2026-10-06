/**
 * @author Mi Li
 * @date 9/14/2023
 * @description CON0001729-1812 Trigger to Update Customer Anchor Set in Real Time
 */
public with sharing class TPB_AccountCustomerSetBatch implements Database.Batchable<sObject>, Schedulable {
  // query
  private String strQuery;
  //Product Group Ids
  private Set<Id> setAccountIds;
  // Example Query the time range of data
  private static Datetime dateTimeValue = System.Datetime.now().addMinutes(-16);
  //get Retailer account RecordTypeId
  public static String accountRetailerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Retailer')
    .getRecordTypeId();

  /**
   * @description Constructor class
   */
  public TPB_AccountCustomerSetBatch() {
    //Find all User data that needs to be generated
    this.strQuery = 'SELECT Id FROM Account WHERE LastModifiedDate >= :dateTimeValue AND RecordTypeId =: accountRetailerRecordTypeId ';
  }

  /**
   * @description Constructor class
   * @param  setAccountIds account ids
   */
  public TPB_AccountCustomerSetBatch(Set<Id> setAccountIds) {
    //Creating a Parametric Construction Method
    this.setAccountIds = setAccountIds;
    this.strQuery = 'SELECT Id FROM Account WHERE Id IN: setAccountIds AND RecordTypeId =: accountRetailerRecordTypeId ';
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
   * @param  lstAccount    description
   */
  public void execute(Database.BatchableContext bc, List<Account> lstAccount) {
    //for each account
    Map<String, Account> mapAccount = new Map<String, Account>();
    for (Account objAccount : lstAccount) {
      mapAccount.put(objAccount.Id, objAccount);
    }

    //updateCustomerSetCustomer
    if (mapAccount.size() > 0) {
      //apex call
      TPB_AccountCustomerSetHandler classAccCustomer = new TPB_AccountCustomerSetHandler();
      classAccCustomer.updateCustomerSetCustomer(mapAccount);
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
    Database.executeBatch(new TPB_AccountCustomerSetBatch(), 100);
  }
}