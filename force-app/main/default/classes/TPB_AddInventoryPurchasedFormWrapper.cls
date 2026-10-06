/**
 * @author Mi Li
 * @date 4/28/2023
 * @description CON0001729-330:Add Inventory Purchased from Wholesaler
 */
public with sharing class TPB_AddInventoryPurchasedFormWrapper {
  /**
   * @description TpbUnitOfMeasure Internal Classes
   */
  public class TpbUnitOfMeasure {
    /**
     * @description gtIn
     */
    public string gtIn;
    /**
     * @description product
     */
    public string product;
    /**
     * @description Unit Type
     */
    public string unitType;

    /**
     * @description    setFieldsByCgcObject
     * @param record   cgcloud__Unit_of_Measure__c
     */
    public void setFieldsByCgcObject(cgcloud__Unit_of_Measure__c record) {
      this.gtIn = record.cgcloud__GTIN__c;
      this.product = record.cgcloud__Product__c;
      if (record.cgcloud__Unit_Type__c == 'SalesUnit') {
        this.unitType = 'Carton';
      } else if (record.cgcloud__Unit_Type__c == 'ConsumerUnit') {
        this.unitType = 'Each';
      } else if (record.cgcloud__Unit_Type__c == 'Layer') {
        this.unitType = 'Case';
      } else {
        this.unitType = record.cgcloud__Unit_Type__c;
      }
    }
  }

  /**
   * @description OrderDetail Internal Classes
   */
  public class OrderDetail {
    /**
     * @description OrderItem Id
     */
    @AuraEnabled
    public String orderItemId { get; set; }
    /**
     * @description Product2 Id
     */
    @AuraEnabled
    public String product2Id { get; set; }
    /**
     * @description product Name
     */
    @AuraEnabled
    public String productName { get; set; }
    /**
     * @description uoM
     */
    @AuraEnabled
    public String uoM { get; set; }
    /**
     * @description quantity
     */
    @AuraEnabled
    public Integer quantity { get; set; }
    /**
     * @description unit Price
     */
    @AuraEnabled
    public Decimal unitPrice { get; set; }
    /**
     * @description type
     */
    @AuraEnabled
    public String type { get; set; }

    /**
     * @description         setFields
     * @param objOrderItem  OrderItem
     */
    public void setFields(OrderItem objOrderItem) {
      //Inner class field assignment
      this.orderItemId = objOrderItem.Id;
      this.product2Id = objOrderItem.Product2Id;
      this.uoM = objOrderItem.UoM__c;
      this.type = objOrderItem.TPB_Type__c;
      this.productName = objOrderItem.Product2.Name;
      this.quantity = Integer.valueOf(objOrderItem.Quantity);
      this.unitPrice = objOrderItem.UnitPrice;
    }
  }
}