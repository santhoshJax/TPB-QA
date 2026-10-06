/**************************************************************************************
Apex Class Name:  TPB_OpportunityPEHandler
Version     : 1.0
Created Date    : 2023-03-24
Function    : platform event handler class on Opportunity to detect field changes on Opportunity include fields as below
OwnerId,
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description platform event handler class on Opportunity to detect field changes on Opportunity include fields as below
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Tina.Wu              2023-03-24            Original Version
*************************************************************************************/
public without sharing class TPB_OpportunityPEHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description afterUpdate description
     *
     */
    protected override void afterUpdate() {
        updateHiddenFieldAfterUpdate((List<Opportunity>)Trigger.new, (Map<Id,Opportunity>)Trigger.oldMap);
    }

     /**
     * @description updateHiddenFieldAfterUpdate
     * Create the method for integration to update hidden fields,
     * so that integrations can merge formula fields in ADW
     * @param  opportunityNewList opportunityNewList description
     * @param  opportunityOldMap  opportunityOldMap description
     */
    private void updateHiddenFieldAfterUpdate(List<Opportunity> opportunityNewList,
    Map<Id,Opportunity> opportunityOldMap) {
        Set<Id> opportunityId = new Set<Id>();

        for(Opportunity item : opportunityNewList){
            Opportunity oldOpportunity = opportunityOldMap.get(item.Id);

            if(oldOpportunity.Amount != item.Amount){
            	//detect fields changes on Opportunity: Last_Completed_Work_Order__c
                opportunityId.add(item.AccountId);
            }
        }

        if(opportunityId.size() > 0){
        	//opportunity change related Account list
            List<Account> accList = [SELECT Id, Total_Amount_of_Orders__c FROM Account WHERE Id IN : opportunityId];

            if(accList!=null && accList.size() > 0){
                for(Account item : accList){
                    item.TPB_Formula_Rollup_Trigger__c = system.now();
                }
                update accList;
            }
        }

    }
}