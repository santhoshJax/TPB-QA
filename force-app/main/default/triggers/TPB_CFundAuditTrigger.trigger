/**
 * @author: Mi Li
 * date:6/29/2023
 * @description  CFund Audit Trigger
 */
trigger TPB_CFundAuditTrigger on TPB_CFund_Audit__c(after update) {
  //run SDF_TGF_MetadataTriggerHandler
  new SDF_TGF_MetadataTriggerHandler().run();
}