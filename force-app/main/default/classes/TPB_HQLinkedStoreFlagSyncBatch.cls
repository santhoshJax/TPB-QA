/**************************************************************************************************   
Apex Class Name      :  TPB_HQLinkedStoreFlagSyncBatch
Version              :  1.0                                                                          
Created Date         :  April 03, 2025                                                               
Function             :  this batch class sync Flags on child Stores according to the parent HQ
Work Task            :    
Test Class Name      : TPB_HQLinkedStoreFlagSyncBatchTest                                                                           
Modification Log     :    
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* ------------------------------------------------------------------------------------------------- 
*                            03/04/2025             Initial Version
*/
global without sharing class TPB_HQLinkedStoreFlagSyncBatch implements Database.Batchable<SObject> {
    
    public Set<Id> parentIdsToSyncFlagsOnChild = new Set<Id>();

    global TPB_HQLinkedStoreFlagSyncBatch(Set<Id> pIdSet){
        parentIdsToSyncFlagsOnChild = pIdSet;
    }

    /**
    * Method name  : start
    * Description  : Called on Start of Batch Job
    * Return Type  : Database.QueryLocator
    * Parameter    : BatchableContext
    **/
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator( buildQuery() );
    }

    /**
    * Method name  : execute 
    * Description  : Called to Porcess record getting from Start method and called flow to process 1 by 1
    * Return Type  : vid
    * Parameter    : BatchableContext,scope
    **/
    global void execute(Database.BatchableContext BC , List<Account> scope){
        if(scope == null || scope.isEmpty()){
            return;
        }
        syncChildAccountsWithParentSettings(scope);
    }

    /**
    * Method name  : finish
    * Description  : Called after processing all records
    * Return Type  : vid
    * Parameter    : BatchableContext
    **/
    global void finish(Database.BatchableContext BC){
    }
    
    /**
    * Method name  : buildQuery
    * Description  : Constructs and returns a SOQL query string to fetch specific fields from the Account object 
    *                where the ParentId matches the provided list of parent IDs.
    * Return Type  : String
    **/
    global String buildQuery(){
        return 'SELECT Id, Parent.Cash_Sales__c, Parent.Mobile_Coupon_Enrollment__c, Parent.Prohibit_Visit__c, Parent.Reason_Not_Visited__c FROM Account WHERE ( ParentId in : parentIdsToSyncFlagsOnChild or ( Id in : parentIdsToSyncFlagsOnChild AND ParentId != null ) ) AND RecordType.Name = \'Retailer\'';
    }

    /**
    * Method name  : syncChildAccountsWithParentSettings
    * Description  : Synchronizes child accounts with their parent account settings.
    * Return Type  : void
    * Parameter    : List<Account> scope - List of Account records to process.
    **/
    global void syncChildAccountsWithParentSettings(List<Account> scope){
        List<Account> lstToUpdate = new List<Account>();
        for(Account childAccount : scope){
            Account objAccountToUpdate                     = new Account(Id = childAccount.Id);
            objAccountToUpdate.Cash_Sales__c               = childAccount.Parent.Cash_Sales__c;
            objAccountToUpdate.Mobile_Coupon_Enrollment__c = childAccount.Parent.Mobile_Coupon_Enrollment__c;
            objAccountToUpdate.Prohibit_Visit__c           = childAccount.Parent.Prohibit_Visit__c;
            objAccountToUpdate.Reason_Not_Visited__c       = childAccount.Parent.Reason_Not_Visited__c;
            lstToUpdate.add(objAccountToUpdate);
        }

        if(!lstToUpdate.isEmpty()){
            Database.update(lstToUpdate, false);
        }
    }
}