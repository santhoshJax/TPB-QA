/**
 * @author Mi Li
 * @date 5/31/2023
 * @description CON0001729-1187  Inventory Balance & Current C-Fund Balance Logic
 */
public with sharing class TPB_UpdateUserInventoryBalanceBatch implements Database.Batchable<sObject> {
  //Variable Definition
  private String strQuery;
  private Set<String> setReimbursementStatus = new Set<String>{
    'Paid',
    'Rejected'
  };

  /**
   * @description Constructor class
   */
  public TPB_UpdateUserInventoryBalanceBatch() {
    //Find all User data that needs to be generated
    this.strQuery = 'SELECT Id, TPB_Inventory_Balance__c, TPB_Total_Adjustments__c, TPB_Reimbursable_Amount_Owed__c, TPB_Reimbursements_Issued__c, TPB_Reimbursements_Pending__c FROM User WHERE Profile.Name = \'CG Cloud Mobile - TSM\' AND IsActive = true ';
  }

  /**
   * @description Constructor class
   * @param  strQuery statement
   */
  public TPB_UpdateUserInventoryBalanceBatch(String strQuery) {
    //Creating a Parametric Construction Method
    this.strQuery = strQuery;
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
   * @param  lstUser    description
   */
  public void execute(Database.BatchableContext bc, List<User> lstUser) {
    //Data rollback when an exception occurs
    User objUser = lstUser[0];
    List<cgcloud__Inventory__c> lstInventory = [
      SELECT Id, cgcloud__Balance__c, TPB_AvgPrice__c
      FROM cgcloud__Inventory__c
      WHERE
        cgcloud__User__c = :objUser.Id
        AND cgcloud__Phase__c = 'Active'
        AND ((cgcloud__Valid_From__c <= :Date.today()
        AND cgcloud__Valid_Thru__c > :Date.today())
        OR (cgcloud__Valid_From__c < :Date.today()
        AND cgcloud__Valid_Thru__c >= :Date.today()))
        AND cgcloud__Balance__c != NULL
        AND TPB_AvgPrice__c != NULL
      LIMIT 5000
    ];
    Decimal allInventoryBalance = 0;
    for (cgcloud__Inventory__c objInventory : lstInventory) {
      allInventoryBalance +=
        objInventory.cgcloud__Balance__c * objInventory.TPB_AvgPrice__c;
    }

    //query Order Item data
    List<cgcloud__Order_Item__c> lstOrderItem = [
      SELECT
        Id,
        Reimbursable_Amt__c,
        Reimbursement_Status__c,
        cgcloud__Special_Price__c,
        cgcloud__Base_Price__c,
        cgcloud__Quantity__c,
        Reimbursed_Week_End_Date__c,
        cgcloud__Promotion__r.TPB_Promotion_Type__c
      FROM cgcloud__Order_Item__c
      WHERE
        cgcloud__Order__r.cgcloud__Accountable__c = :objUser.Id
        AND (Reimbursable_Amt__c > 0
        OR cgcloud__Special_Price__c > 0)
        AND cgcloud__Order__r.cgcloud__Phase__c = 'Released'
    ];

    assignment(lstOrderItem, allInventoryBalance, objUser);
  }

  /**
   * @description user assignment
   * @param lstOrderItem List<cgcloud__Order_Item__c> description
   * @param allInventoryBalance      Decimal description
   * @param objUser      User description
   */
  private void assignment(
    List<cgcloud__Order_Item__c> lstOrderItem,
    Decimal allInventoryBalance,
    User objUser
  ) {
    Decimal allReimbursableAmt = 0;
    Decimal allInProgressAmt = 0;
    Decimal allInPaidAmt = 0;

    for (cgcloud__Order_Item__c objOrderItem : lstOrderItem) {
      if (objOrderItem.Reimbursement_Status__c == 'In Progress') {
        allInProgressAmt += (objOrderItem.Reimbursable_Amt__c == null
          ? 0
          : objOrderItem.Reimbursable_Amt__c);
      }
      if (
        objOrderItem.Reimbursement_Status__c == 'Paid' &&
        System.Date.today() < objOrderItem.Reimbursed_Week_End_Date__c &&
        System.Date.today().toStartOfWeek() <= System.Date.today() &&
        objOrderItem.Reimbursed_Week_End_Date__c <
        System.Date.today().toStartOfWeek().adddays(7)
      ) {
        allInPaidAmt += (objOrderItem.Reimbursable_Amt__c == null
          ? 0
          : objOrderItem.Reimbursable_Amt__c);
      }
      if (
        !setReimbursementStatus.contains(
          objOrderItem.Reimbursement_Status__c
        ) && objOrderItem.cgcloud__Promotion__r.TPB_Promotion_Type__c != null
      ) {
        allReimbursableAmt += (objOrderItem.Reimbursable_Amt__c == null
          ? 0
          : objOrderItem.Reimbursable_Amt__c);
      }
    }

    Boolean isChange = false;
    if (objUser.TPB_Inventory_Balance__c != allInventoryBalance) {
      objUser.TPB_Inventory_Balance__c = allInventoryBalance;
      isChange = true;
    }
    if (objUser.TPB_Reimbursable_Amount_Owed__c != allReimbursableAmt) {
      objUser.TPB_Reimbursable_Amount_Owed__c = allReimbursableAmt;
      isChange = true;
    }
    if (objUser.TPB_Reimbursements_Issued__c != allInPaidAmt) {
      objUser.TPB_Reimbursements_Issued__c = allInPaidAmt;
      isChange = true;
    }
    if (objUser.TPB_Reimbursements_Pending__c != allInProgressAmt) {
      objUser.TPB_Reimbursements_Pending__c = allInProgressAmt;
      isChange = true;
    }

    if (isChange) {
      update objUser;
    }
  }

  /**
   * @description finish description
   * @param  bc description
   */
  public void finish(Database.BatchableContext bc) {
    strQuery = '';
  }
}