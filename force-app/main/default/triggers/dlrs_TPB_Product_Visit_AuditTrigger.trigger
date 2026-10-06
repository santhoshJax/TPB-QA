/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_TPB_Product_Visit_AuditTrigger on TPB_Product_Visit_Audit__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(TPB_Product_Visit_Audit__c.SObjectType);
}