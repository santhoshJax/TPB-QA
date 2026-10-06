/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screen flow for Mass Prebook
 */
public without sharing class TPB_MassPrebookWrapper {
  /**
   * @description MassPrebookDetail
   */
  public class MassPrebookDetail {
    /**
     * @description orderId
     */
    @AuraEnabled
    public String oId { get; set; }
    /**
     * @description hq Account Id
     */
    @AuraEnabled
    public String aId { get; set; }
    /**
     * @description WholesalerAccount
     */
    @AuraEnabled
    public WholesalerAccount oAc { get; set; }

    /**
     * @description Item Name
     */
    @AuraEnabled
    public String itNm { get; set; }
    /**
     * @description item ProductId
     */
    @AuraEnabled
    public String pId { get; set; }
    /**
     * @description nTCItem
     */
    @AuraEnabled
    public String ntIm { get; set; }
    /**
     * @description wholesaler Item
     */
    @AuraEnabled
    public String wsIm { get; set; }
    /**
     * @description qTYPlanned
     */
    @AuraEnabled
    public Decimal qTP { get; set; }
    /**
     * @description MaxQuantity
     */
    @AuraEnabled
    public Decimal mxQ { get; set; }
    /**
     * @description qtyOrdered
     */
    @AuraEnabled
    public Decimal qTO { get; set; }
    /**
     * @description qtyOrdered
     */
    @AuraEnabled
    public Decimal qTOO { get; set; }
    /**
     * @description qtyRemaining
     */
    @AuraEnabled
    public Decimal qTR { get; set; }
    /**
     * @description orderItemId
     */
    @AuraEnabled
    public String oTId { get; set; }
    /**
     * @description brand UPW
     */
    @AuraEnabled
    public String bW { get; set; }

    /**
     * @description            set Product Fields
     * @param oAcc 　          WholesalerAccount
     * @param objOrderItem     OrderItem
     * @param strAccount       Account id
     */
    public void setProductFields(
      WholesalerAccount oAcc,
      OrderItem objOrderItem,
      String strAccount
    ) {
      //Inner class field assignment
      this.oAc = oAcc;
      this.aId = strAccount;
      this.oId = objOrderItem.OrderId;
      this.itNm = objOrderItem.Product2.Name;
      this.pId = objOrderItem.Product2Id;
      this.ntIm = objOrderItem.Product2.NTC_Case_ID__c;
      this.wsIm = objOrderItem.Product2.Item_ID__c;
      this.qTP = objOrderItem.TPB_QTY_Planned__c;
      this.mxQ = objOrderItem.TPB_Max_Quantity__c;
      this.qTO = objOrderItem.Quantity;
      this.qTOO = objOrderItem.Quantity;
      this.qTR = objOrderItem.TPB_QTY_Remaining__c;
      this.oTId = objOrderItem.Id;
      this.bW = objOrderItem.Product2.TPB_Brand_UPW__c;
    }
  }

  /**
   * @description WholesalerAccount
   */
  public class WholesalerAccount {
    /**
     * @description account Number
     */
    @AuraEnabled
    public String acNu { get; set; }
    /**
     * @description account Name
     */
    @AuraEnabled
    public String acNm { get; set; }
    /**
     * @description address
     */
    @AuraEnabled
    public String ads { get; set; }
    /**
     * @description city
     */
    @AuraEnabled
    public String cty { get; set; }
    /**
     * @description state
     */
    @AuraEnabled
    public String sta { get; set; }
    /**
     * @description zip
     */
    @AuraEnabled
    public String zip { get; set; }
    /**
     * @description wholesaler Name
     */
    @AuraEnabled
    public String wsNm { get; set; }
    /**
     * @description wholesaler
     */
    @AuraEnabled
    public String ws { get; set; }
    /**
     * @description nTC Customer Number
     */
    @AuraEnabled
    public String nTNu { get; set; }
    /**
     * @description wholesale Customer
     */
    @AuraEnabled
    public String wsCt { get; set; }

    /**
     * @description Related Account id
     */
    @AuraEnabled
    public String rAcId { get; set; }
  }
}