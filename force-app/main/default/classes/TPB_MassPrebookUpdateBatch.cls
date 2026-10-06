/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screenflow for Mass Prebook
 */
public without sharing class TPB_MassPrebookUpdateBatch implements Database.Batchable<sObject> {
  private List<TPB_Promotion_Allocation_Item__c> lstUpdatePromotionAllocationItem;

  /**
   * @description TPB_MassPrebookUpdateBatch
   * @param  lstUpdatePromotionAllocationItem   List<TPB_Promotion_Allocation_Item__c>
   */
  public TPB_MassPrebookUpdateBatch(
    List<TPB_Promotion_Allocation_Item__c> lstUpdatePromotionAllocationItem
  ) {
    this.lstUpdatePromotionAllocationItem = lstUpdatePromotionAllocationItem;
  }

  /**
   * @description QueryLocator Start
   * @param  bc BatchableContext
   * @return    return List<TPB_Promotion_Allocation_Item__c>
   */
  public List<TPB_Promotion_Allocation_Item__c> start(
    Database.BatchableContext bc
  ) {
    // collect the batches of records or objects to be passed to execute
    return lstUpdatePromotionAllocationItem;
  }
  /**
   * @description execute
   * @param  bc                 BatchableContext Input
   * @param  lstUpdatePromotionAllocationItem              List Related Account
   */
  public void execute(
    Database.BatchableContext bc,
    List<TPB_Promotion_Allocation_Item__c> lstUpdatePromotionAllocationItem
  ) {
    update lstUpdatePromotionAllocationItem;
  }
  /**
   * @description Batch Finish
   * @param  bc BatchableContext
   */
  public void finish(Database.BatchableContext bc) {
  }
}