/**
 * @author Mi Li
 * @date 5/19/2023
 * @description CON0001729-1161 RSM C-Fund Audit (TSM View)
 */
public with sharing class TPB_AddCFundAuditWrapper {
  /**
   * @description CFundAudit Internal Classes
   */
  public class CFundAudit {
    /**
     * @description baseCFund
     */
    @AuraEnabled
    public Decimal baseCFund { get; set; }
    /**
     * @description total Adjustments
     */
    @AuraEnabled
    public Decimal totalAdjustments { get; set; }
    /**
     * @description expected Product Value
     */
    @AuraEnabled
    public Decimal expectedProductValue { get; set; }
    /**
     * @description pending Reimbursements
     */
    @AuraEnabled
    public Decimal pendingReimbursements { get; set; }
    /**
     * @description promoValue
     */
    @AuraEnabled
    public Decimal promoValue { get; set; }
    /**
     * @description total Accoun table CFund
     */
    @AuraEnabled
    public Decimal totalAccountableCFund { get; set; }
    /**
     * @description bank Balance
     */
    @AuraEnabled
    public Decimal bankBalance { get; set; }
    /**
     * @description actual Cash On Hand
     */
    @AuraEnabled
    public Decimal actualCashOnHand { get; set; }

    /**
     * @description expected Cash And Cash Equivalents
     */
    @AuraEnabled
    public Decimal expectedCashAndCashEquivalents { get; set; }
    /**
     * @description recordId
     */
    @AuraEnabled
    public String recordId { get; set; }
  }
}