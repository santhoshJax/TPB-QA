/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_cgcloud_Inventory_Transaca4WTrigger on cgcloud__Inventory_Transaction__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(cgcloud__Inventory_Transaction__c.SObjectType);
}