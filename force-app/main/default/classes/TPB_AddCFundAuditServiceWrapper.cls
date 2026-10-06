/**
 * @author Mi Li
 * @date 5/19/2023
 * @description CON0001729-1161 RSM C-Fund Audit (TSM View)
 */
public with sharing class TPB_AddCFundAuditServiceWrapper {
  /**
   * @description CFundAuditProduct
   */
  public class CFundAuditProduct {
    /**
     * @description id
     */
    @AuraEnabled
    public String id { get; set; }
    /**
     * @description auditId
     */
    @AuraEnabled
    public String auditId { get; set; }
    /**
     * @description productId
     */
    @AuraEnabled
    public String productId { get; set; }
    /**
     * @description productName
     */
    @AuraEnabled
    public String productName { get; set; }
    /**
     * @description unitPrice
     */
    @AuraEnabled
    public Decimal unitPrice { get; set; }
    /**
     * @description quantity
     */
    @AuraEnabled
    public Decimal quantity { get; set; }
    /**
     * @description totalAmount
     */
    @AuraEnabled
    public Decimal totalAmount { get; set; }
    /**
     * @description expectedQuantity
     */
    @AuraEnabled
    public Decimal expectedQuantity { get; set; }
    /**
     * @description variance
     */
    @AuraEnabled
    public String variance { get; set; }

    /**
     * @description              setFields
     * @param oProduct 　        TPB_CFund_Audit_Product__c
     * @param expectedQuantity   Decimal
     */
    public void setFields(
      TPB_CFund_Audit_Product__c oProduct,
      Decimal expectedQuantity
    ) {
      //Inner class field assignment
      this.auditId = oProduct.TPB_CFund_Audit__c;
      this.id = oProduct.Id;
      this.productId = oProduct.TPB_Actual_Product__c;
      this.productName = oProduct.TPB_Actual_Product__r.Name;
      this.quantity = oProduct.TPB_Quantity__c;
      this.unitPrice = oProduct.TPB_Unit_Price__c;
      this.totalAmount = oProduct.TPB_Total_Amount__c;
      this.expectedQuantity = expectedQuantity;
      if (this.quantity < this.expectedQuantity) {
        this.variance =
          '(' +
          String.valueOf(
            Math.abs(this.quantity - this.expectedQuantity).setscale(3)
          ) +
          ')';
      } else {
        this.variance = String.valueOf(
          Math.abs(this.quantity - this.expectedQuantity).setscale(3)
        );
      }
    }
  }
}