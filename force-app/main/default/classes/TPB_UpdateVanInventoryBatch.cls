/**
 * @author Feng Lian
 * @date 6/25/2023
 * @description create inventory and transaction records based on the wholesale purchase orders
 */
public class TPB_UpdateVanInventoryBatch implements Database.Batchable<sObject>, Schedulable {
  //Order Item Type: Purchase
  private static final String WHOLESALERPURCHASE = 'Purchase';
  //Active Order
  private static final String ACTIVEORDER = 'Activated';
  // Order DeveloperName Van_Load
  private static final String RECORDTYPENAME = 'Van_Load';
  //OrderId list
  private Set<Id> orderIds;
  // query
  private String query;

  /**
   * @description default constructor method
   */
  public TPB_UpdateVanInventoryBatch() {
    this.query =
      'SELECT TPB_Type__c, UoM__c, Product2.TPB_Exclude_From_Base_Pricing__c, Product2Id, Quantity, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c,' +
      ' Order.CreatedById FROM OrderItem WHERE Order.Status = :ACTIVEORDER AND Order.ActivatedDate = TODAY  AND Order.RecordType.DeveloperName = :RECORDTYPENAME ' +
      ' ORDER BY OrderId';
  }

  /**
   * @param  orderIds  Set<Id>
   * @description default constructor method
   */
  public TPB_UpdateVanInventoryBatch(Set<Id> orderIds) {
    if (orderIds != null && orderIds.size() > 0) {
      this.orderIds = orderIds;
      this.query =
        'SELECT TPB_Type__c, UoM__c, Product2.TPB_Exclude_From_Base_Pricing__c, Product2Id, Quantity, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c,' +
        ' Order.CreatedById FROM OrderItem WHERE Order.Status = :ACTIVEORDER AND OrderId IN : orderIds  AND Order.RecordType.DeveloperName = :RECORDTYPENAME ' +
        ' ORDER BY OrderId';
    }
  }

  /**
   * @description start description
   * @param  bc bc description
   * @return    return description
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  /**
   * @description execute description
   * @param  bc description
   * @param  items  description
   */
  public void execute(Database.BatchableContext bc, List<sObject> items) {
    TPB_InventoryService.createInventory((List<OrderItem>) items);
  }

  /**
   * @description finish description
   * @param  bc bc description
   */
  public void finish(Database.BatchableContext bc) {
  }

  /**
   * @description execute description
   * @param  sc sc description
   */
  public void execute(SchedulableContext sc) {
    Database.executeBatch(new TPB_UpdateVanInventoryBatch());
  }
}