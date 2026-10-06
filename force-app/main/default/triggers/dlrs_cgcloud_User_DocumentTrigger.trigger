/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_cgcloud_User_DocumentTrigger on cgcloud__User_Document__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(cgcloud__User_Document__c.SObjectType);
}