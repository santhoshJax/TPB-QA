public without sharing class AccountTriggerHandler {

    public static void childCount(List<Account> accounts, Map<Id,Account> accountMap) {
        Set<Id> parentIds = new Set<Id>();

        for(Account acc : accounts) {
            //update
            if(accountMap != null) {
                Account oldAcc = accountMap.get(acc.Id);

                if(acc.ParentId != oldAcc.ParentId) {
                    Id parentId = acc.ParentId != null ? acc.ParentId : oldAcc.ParentId;
                    parentIds.add(parentId);
                }
            }
            //insert or delete
            else {
                if(acc.ParentId != null) {
                    parentIds.add(acc.ParentId);
                }
            }
        }

        if(!parentIds.isEmpty()) {
            Map<Id, Decimal> parentMap = new Map<Id,Decimal>();
            List<Account> parentUpdate = new List<Account>();

            for(Account acc : [SELECT Id, ParentId FROM Account WHERE ParentId IN :parentIds AND RecordType.Name = 'Retailer']) {
                if(parentMap.containsKey(acc.ParentId)) {
                    Decimal count = parentMap.get(acc.ParentId);
                    parentMap.put(acc.ParentId, count + 1);
                }
                else {
                    parentMap.put(acc.ParentId, 1);
                }
            }

            for(Id parentId : parentMap.keySet()) {
                Account acc = new Account();
                acc.Id = parentId;
                acc.Number_of_Linked_Stores__c = parentMap.get(parentId);
                parentUpdate.add(acc);
            }

            update parentUpdate;
        }

    }

    /**
    * Method name  : updateFlagDownToStoresThatAreLinkedToHQ
    * Description  : Updates child account flags based on changes in HQ parent relationships or HQ flag updates.
    * Return Type  : void
    * Parameter    : List<Account> newList, Map<Id, Account> oldMap
    **/
    public static void updateFlagDownToStoresThatAreLinkedToHQ(List<Account> newList, Map<Id, Account> oldMap){
        if(newList == null || newList.isEmpty() || System.isBatch()) return;

        Id HQ_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Headquarter').getRecordTypeId();

        Map<Id, Account> accountMap = new Map<Id, Account>();
        Set<Id> parentIdSet         = collectParentIdsToEvaluate(newList, oldMap, accountMap, HQ_RECORD_TYPE_ID);
        if(parentIdSet.isEmpty()){
            return;
        }

        accountMap = new Map<Id, Account>([
            SELECT Id, ParentId, Parent.RecordTypeId, RecordTypeId
            FROM Account WHERE Id IN :parentIdSet
        ]);

        List<Account> lstChildAccountToUpdate = new List<Account>();
        Set<Id> parentIdsToSyncFlagsOnChild   = new Set<Id>();
        // Evaluate accounts for flag sync
        evaluateAccountsForFlagSync(newList, oldMap, accountMap, HQ_RECORD_TYPE_ID, parentIdsToSyncFlagsOnChild, lstChildAccountToUpdate);
        
        if(!lstChildAccountToUpdate.isEmpty()){
            Database.update(lstChildAccountToUpdate, false);
        }

        if(!parentIdsToSyncFlagsOnChild.isEmpty()){
            processHQChildFlagUpdates(parentIdsToSyncFlagsOnChild);
        }
    }

    /**
    * Method name  : collectParentIdsToEvaluate
    * Description  : Collects the parent account IDs that need to be evaluated based on changes in the provided account lists.
    * Return Type  : Set<Id>
    * Parameter    : List<Account> newList - The list of new account records.
    *              : Map<Id, Account> oldMap - The map of old account records keyed by their IDs.
    *              : Id HQ_RECORD_TYPE_ID - The record type ID for HQ accounts.
    **/
    private static Set<Id> collectParentIdsToEvaluate(List<Account> newList, Map<Id, Account> oldMap, Map<Id, Account> accountMap, Id HQ_RECORD_TYPE_ID){
        Set<Id> parentIdSet = new Set<Id>();
        for(Account objAccount : newList){
            Account oldAccount = !oldMap.isEmpty() ? oldMap.get(objAccount.Id) : new Account();
            if(isChildHQChanged(objAccount, oldAccount, HQ_RECORD_TYPE_ID)){
                if(isChildWithNewHQ(objAccount, accountMap, HQ_RECORD_TYPE_ID)){
                    parentIdSet.add(objAccount.ParentId);
                } else if(isChildWithRemovedHQ(objAccount, oldAccount, accountMap, HQ_RECORD_TYPE_ID)){
                    parentIdSet.add(oldAccount.ParentId);
                }
            } else if(isHQWithFlagChange(objAccount, oldAccount, HQ_RECORD_TYPE_ID)){
                parentIdSet.add(objAccount.Id);
            } else if (oldAccount?.Id == null && isChildWithNewHQ(objAccount, accountMap, HQ_RECORD_TYPE_ID)) {
                parentIdSet.add(objAccount.Id);
            }
        }
        return parentIdSet;
    }

    /**
    * Method name  : evaluateAccountsForFlagSync
    * Description  : Evaluates and synchronizes flags on child accounts based on changes in parent account relationships or flag updates.
    * Return Type  : void
    * Parameters   : 
    *   - List<Account> newList: The list of new Account records being processed.
    *   - Map<Id, Account> oldMap: The map of old Account records with their Ids as keys.
    *   - Map<Id, Account> accountMap: A map of Account records for processing.
    *   - Id HQ_RECORD_TYPE_ID: The Id of the HQ record type to identify HQ accounts.
    *   - Set<Id> parentIdsToSyncFlagsOnChild: A set of parent Account Ids whose child accounts need flag synchronization.
    *   - List<Account> lstChildAccountToUpdate: A list of child Account records to be updated.
    **/
    private static void evaluateAccountsForFlagSync(
        List<Account> newList,
        Map<Id, Account> oldMap,
        Map<Id, Account> accountMap,
        Id HQ_RECORD_TYPE_ID,
        Set<Id> parentIdsToSyncFlagsOnChild,
        List<Account> lstChildAccountToUpdate
    ) {
        for(Account objAccount : newList){
            Account oldAccount = !oldMap.isEmpty() ? oldMap.get(objAccount.Id) : new Account();

            if(isChildHQChanged(objAccount, oldAccount, HQ_RECORD_TYPE_ID)){
                if(isChildWithNewHQ(objAccount, accountMap, HQ_RECORD_TYPE_ID)){
                    parentIdsToSyncFlagsOnChild.add(objAccount.Id);
                } else if(isChildWithRemovedHQ(objAccount, oldAccount, accountMap, HQ_RECORD_TYPE_ID)){
                    lstChildAccountToUpdate.add(clearChildFlags(objAccount.Id));
                }
            } else if(isHQWithFlagChange(objAccount, oldAccount, HQ_RECORD_TYPE_ID)){
                parentIdsToSyncFlagsOnChild.add(objAccount.Id);
            } else if (oldAccount == null && isChildWithNewHQ(objAccount, accountMap, HQ_RECORD_TYPE_ID)) {
                parentIdsToSyncFlagsOnChild.add(objAccount.Id);
            }
        }
    }

    /**
    * Method name  : isChildHQChanged
    * Description  : Checks if the RecordTypeId of an Account has changed, specifically for child accounts linked to HQ.
    * Return Type  : Boolean
    * Parameter    : Account newAcc, Account oldAcc
    **/
    private static Boolean isChildHQChanged(Account newAcc, Account oldAcc, Id HQ_RECORD_TYPE_ID) {
        return newAcc.ParentId != oldAcc.ParentId && newAcc.RecordTypeId != HQ_RECORD_TYPE_ID;
    }

    /**
    * Method name  : isChildWithNewHQ
    * Description  : Checks if the given account is a child account with a new HQ parent relationship.
    * Return Type  : Boolean
    * Parameter    : Account newAcc - The account being evaluated.
    *                Map<Id, Account> accountMap - A map of account records for reference.
    *                Id HQ_RECORD_TYPE_ID - The record type ID representing HQ accounts.
    **/
    private static Boolean isChildWithNewHQ(Account newAcc, Map<Id, Account> accountMap, Id HQ_RECORD_TYPE_ID) {
        return newAcc.ParentId != null && newAcc.RecordTypeId != HQ_RECORD_TYPE_ID && (accountMap.isEmpty() || accountMap.get(newAcc.ParentId).RecordTypeId == HQ_RECORD_TYPE_ID);
    }

    /**
    * Method name  : isChildWithRemovedHQ
    * Description  : Determines if an account has been disassociated from its HQ parent account.
    * Return Type  : Boolean
    * Parameter    : Account newAcc - The updated account record.
    *              : Account oldAcc - The original account record before the update.
    *              : Map<Id, Account> accountMap - A map of account records for reference.
    *              : Id HQ_RECORD_TYPE_ID - The record type ID representing HQ accounts.
    **/
    private static Boolean isChildWithRemovedHQ(Account newAcc, Account oldAcc, Map<Id, Account> accountMap, Id HQ_RECORD_TYPE_ID) {
        return newAcc.ParentId == null && oldAcc?.ParentId != null && (accountMap.isEmpty() || accountMap.get(oldAcc.ParentId).RecordTypeId == HQ_RECORD_TYPE_ID);
    }

    /**
    * Method name  : isHQWithFlagChange
    * Description  : Checks if the account is an HQ record type and if the flag has changed between the new and old account records.
    * Return Type  : Boolean
    * Parameter    : Account newAcc - The new account record.
    *                Account oldAcc - The old account record.
    *                Id HQ_RECORD_TYPE_ID - The record type ID for HQ accounts.
    **/
    private static Boolean isHQWithFlagChange(Account newAcc, Account oldAcc, Id HQ_RECORD_TYPE_ID) {
        return oldAcc?.Id != null && newAcc.RecordTypeId == HQ_RECORD_TYPE_ID && hasFlagChanged(newAcc, oldAcc);
    }

    /**
    * Method name  : hasFlagChanged
    * Description  : Checks if the Cash_Sales__c flag has changed between the new and old Account records.
    * Return Type  : Boolean
    * Parameter    : Account newAcc - The new Account record.
    *              : Account oldAcc - The old Account record.
    **/
    private static Boolean hasFlagChanged(Account newAcc, Account oldAcc) {
        return newAcc.Cash_Sales__c != oldAcc.Cash_Sales__c ||
               newAcc.Mobile_Coupon_Enrollment__c != oldAcc.Mobile_Coupon_Enrollment__c ||
               newAcc.Prohibit_Visit__c != oldAcc.Prohibit_Visit__c ||
               newAcc.Reason_Not_Visited__c != oldAcc.Reason_Not_Visited__c;
    }
    
    /**
    * Method name  : clearChildFlags
    * Description  : Clears specific flags on child accounts associated with the given parent account.
    * Return Type  : Account
    * Parameter    : Id accountId
    **/
    private static Account clearChildFlags(Id accountId){
        return new Account(
            Id = accountId,
            Cash_Sales__c = false,
            Mobile_Coupon_Enrollment__c = false,
            Prohibit_Visit__c = null,
            Reason_Not_Visited__c = null
        );
    }

    /**
    * Method name  : processHQChildFlagUpdates
    * Description  : Synchronizes HQ-related flags from parent accounts to their child accounts.
    * Return Type  : void
    * Parameter    : Set<Id> parentIdsToSyncFlagsOnChild - A set of parent account IDs whose child accounts need flag updates.
    **/
    private static void processHQChildFlagUpdates(Set<Id> parentIdsToSyncFlagsOnChild){
        TPB_HQLinkedStoreFlagSyncBatch batchClass = new TPB_HQLinkedStoreFlagSyncBatch(parentIdsToSyncFlagsOnChild);
        List<Account> lstChildAccountToUpdate = Database.query(batchClass.buildQuery());

        if(lstChildAccountToUpdate.isEmpty()) return;

        Integer remainingDML = Limits.getLimitDMLRows() - Limits.getDMLRows();
        if(remainingDML > lstChildAccountToUpdate.size() && !Test.isRunningTest() && lstChildAccountToUpdate.size() < 50){
            batchClass.syncChildAccountsWithParentSettings(lstChildAccountToUpdate);
        } else {
            Database.executeBatch(batchClass, 50);
        }
    }
}