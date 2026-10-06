/**************************************************************************************
Apex Class Name:  TPB_OpportunityTrigger
Version     : 1.0 
Created Date    : 2023-03-24
Function    : Trigger
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Tina.wu              2023-03-24            Original Version
*************************************************************************************/
trigger TPB_OpportunityTrigger on Opportunity(after update){
    new SDF_TGF_MetadataTriggerHandler().run();
}