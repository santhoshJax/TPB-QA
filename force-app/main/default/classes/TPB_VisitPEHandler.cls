/**************************************************************************************
Apex Class Name:  TPB_VisitPEHandler
Version     : 1.0 
Created Date    : 2023-03-24
Function    : platform event handler class on Visit to detect field changes on Account include fields as below
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description TPB_VisitPEHandler trigger handler
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Tina.Wu              2023-03-24            Original Version
*************************************************************************************/
public without sharing class TPB_VisitPEHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description afterUpdate description
     *
     */
    protected override void afterUpdate() {
        updateHiddenFieldAfterUpdate((List<Visit>)Trigger.new, (Map<Id,Visit>)Trigger.oldMap);
    }
    
    /**
     * @description updateHiddenFieldAfterUpdate 
     * Create the method for integration to update hidden fields,
     * so that integrations can merge formula fields in ADW 
     * @param  visitNewList visitNewList description
     * @param  visitOldMap  visitOldMap description
     */ 
    private void updateHiddenFieldAfterUpdate(List<Visit> visitNewList, 
    Map<Id,Visit> visitOldMap) {
        //initial id set
        Set<Id> vIdForAccount = new Set<Id>();
     
        for(Visit item : visitNewList){
            Visit oldVitem = visitOldMap.get(item.Id);
            if(oldVitem.ActualVisitEndTime != item.ActualVisitEndTime){
                //detect fields changes on Visit: ActualVisitEndTime
                vIdForAccount.add(item.Id);
            }
        }

        if(vIdForAccount !=null && vIdForAccount.size() > 0){
            //ServiceAppointment change related Account list
            List<Account> accList = [SELECT Id FROM Account WHERE Last_Completed_call__c IN : vIdForAccount];
            //
            if(accList!=null && accList.size() > 0){
                for(Account item : accList){
                    item.TPB_Formula_Rollup_Trigger__c = system.now();
                }
                update accList;
            }
        }

    }
}