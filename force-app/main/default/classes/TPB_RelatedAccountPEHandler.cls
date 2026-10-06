/**************************************************************************************
Apex Class Name:  TPB_RelatedAccountPEHandler
Version     : 1.0 
Created Date    : 2023-03-24
Function    : platform event handler class on RelatedAccount to detect field changes on WorkOrderLineItem include fields as below
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description relatedAccount trigger handler
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Tina.Wu              2023-03-24            Original Version
*************************************************************************************/
public without sharing class TPB_RelatedAccountPEHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description afterUpdate description
     *
     */
    protected override void afterUpdate() {
        //updateHiddenFieldAfterUpdate((List<Related_Account__c>)Trigger.new, (Map<Id,Related_Account__c>)Trigger.oldMap);
    }    
}