/**
 * @author: Mi Li
 * date:6/11/2023
 * @description  Inventory Trigger
 */
trigger TPB_InventoryTrigger on cgcloud__Inventory__c(
  after update,
  after insert
) {
  //new SDF_TGF_MetadataTriggerHandler().run();
}