/**************************************************************************************
Apex Class Name:  TPB_AccountPEHandler
Version     : 1.0
Created Date    : 2023-03-24
Function    : platform event handler class on Account to detect field changes on Account include fields as below
OwnerId,
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* @description CON0001729-902 ERP_ARCustomer_Integration_PE trigger handler
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Jeff.xu              2023-03-24            Original Version
*************************************************************************************/
public without sharing class TPB_AccountPEHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description beforeUpdate description
     *
     */
    protected override void beforeUpdate() {
        updateHiddenFieldBeforeUpdate((List<Account>)Trigger.new, (Map<Id,Account>)Trigger.oldMap);
    }

    /**
     * @description afterUpdate description
     *
     */
    // protected override void afterUpdate() {
    //     updateHiddenFieldAfterUpdate((List<Account>)Trigger.new, (Map<Id,Account>)Trigger.oldMap);
    // }

    /**
    * @description updateHiddenFieldBeforeUpdate
    * Create the method for integration to update hidden fields,
    * so that integrations can merge formula fields in ADW
    * @param  accountNewList accountNewList description
    * @param  accountOldMap  accountOldMap description
    */
    private void updateHiddenFieldBeforeUpdate(List<Account> accountNewList, Map<Id,Account> accountOldMap) {

       //loop all changed accounts
       for(Account accItem : accountNewList){

           Account oldAccItem = accountOldMap.get(accItem.Id);

           //SF --> ERP AR Customer Integration - Platform Events / CON0001729-902
           if(oldAccItem.OwnerId != accItem.OwnerId){
               //detect ownerid changes on account, and update hidden fields
               accItem.TPB_AR_Customer_Trigger__c = System.now();
           }
       }

   }


   // /**
   //  * @description updateHiddenFieldAfterUpdate
   //  * Create the method for integration to update hidden fields,
   //  * so that integrations can merge formula fields in ADW
   //  * @param  accountNewList accountNewList description
   //  * @param  accountOldMap  accountOldMap description
   //  */
   // private void updateHiddenFieldAfterUpdate(List<Account> accountNewList, Map<Id,Account> accountOldMap) {
   //     Set<Id> accIdForVisitSet = new Set<Id>();

   //     for(Account accItem : accountNewList){
   //         Account oldAccItem = accountOldMap.get(accItem.Id);
   //         if(oldAccItem.Last_Completed_Call__c != accItem.Last_Completed_Call__c){
   //             //detect fields changes on accounts: Last_Completed_call__c
   //             accIdForVisitSet.add(accItem.Id);
   //         }
   //     }

   //     if(accIdForVisitSet.size() > 0){
   //         //Account change related workOrder list
   //         List<Visit> vList = [SELECT Id FROM Visit WHERE AccountId IN : accIdForVisitSet];

   //         if(vList!=null && vList.size() > 0){
   //             for(Visit vItem : vList){
   //                 vItem.TPB_Formula_Rollup_Trigger__c = system.now();
   //             }
   //             update vList;
   //         }
   //     }

   // }

}