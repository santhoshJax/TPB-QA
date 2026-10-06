/**************************************************************************************
Apex Class Name:  TPB_UserPEHandler
Version     : 1.0
Created Date    : 2023-03-24
Function    : platform event handler class on User to detect field changes on WorkOrder include fields as below
OwnerId,
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description user trigger handler
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Tina.Wu              2023-03-24            Original Version
*************************************************************************************/
public without sharing class TPB_UserPEHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description afterUpdate description
     *
     */
    protected override void afterUpdate() {
        updateHiddenFieldAfterUpdate((List<User>)Trigger.new, (Map<Id,User>)Trigger.oldMap);
    }

    /**
     * @description updateHiddenFieldAfterUpdate description
     * @param  userNewList userNewList description
     * @param  userOldMap  userOldMap description
     */
    private void updateHiddenFieldAfterUpdate(List<User> userNewList, Map<Id,User> userOldMap) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> accUserIds = new Set<Id>();

        for(User item : userNewList){
            User oldUser = userOldMap.get(item.Id);
            if(oldUser.TPB_Territory__c != item.TPB_Territory__c){
            	//detect fields changes on User: Territory_Id__c
                userIds.add(item.Id);
            }

            if(oldUser.ProfileId != item.ProfileId){
            	//detect fields changes on User: ProfileId
                accUserIds.add(item.Id);
            }
        }
        if(userIds.size() > 0){
            updateHiddenFieldAfterUpdateForVisit(userIds);
        }

        if(accUserIds.size() > 0){
            updateHiddenFieldAfterUpdateForAccount(accUserIds);
        }
    }

     /**
     * @description updateHiddenFieldAfterUpdate
     * Create the method for integration to update hidden fields,
     * so that integrations can merge formula fields in ADW
     * @param  accUserIds userNewList description
     */
    @future
    private static void updateHiddenFieldAfterUpdateForAccount(Set<Id> accUserIds) {

        if(accUserIds.size() > 0){
        	//User change related Account list
            List<Account> accountList = [SELECT Id FROM Account WHERE OwnerId IN : accUserIds OR Parent.OwnerId IN : accUserIds];

            if(accountList != null && accountList.size() > 0){
                for(Account item : accountList){
                    item.TPB_Formula_Rollup_Trigger__c = system.now();
                }
                update accountList;
            }
        }
    }

    /**
     * @description updateHiddenFieldAfterUpdateForWorkOrder description
     * @param  userIds userIds description
     */
    @future
    private static void updateHiddenFieldAfterUpdateForVisit(Set<Id> userIds) {

        if(userIds.size() > 0){
        	//User change related Work Order list
            List<Visit> vList = [SELECT Id FROM Visit WHERE cgcloud__Responsible__c IN : userIds and ActualvisitEndTime = LAST_N_DAYS:365];

            if(vList != null && vList.size() > 0){
                for(Visit item : vList){
                    item.TPB_Formula_Rollup_Trigger__c = system.now();
                }
                update vList;
            }
        }
    }
}