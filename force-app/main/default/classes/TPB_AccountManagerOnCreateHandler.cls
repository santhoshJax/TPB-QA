/**************************************************************************************
Apex Class Name:  TPB_AccountManagerOnCreateHandler
Version     : 1.0
Created Date    : 2026-02-18
Function    : Create cgcloud__Account_Manager__c records for Accounts created from online app
*************************************************************************************/
public without sharing class TPB_AccountManagerOnCreateHandler extends SDF_TGF_TriggerHandler {
    /**
     * @description afterInsert description
     */
    protected override void afterInsert() {
        List<Account> newAccounts = (List<Account>) Trigger.new;
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }

        Map<Id, Id> accountToUserId = new Map<Id, Id>();
        for (Account acc : newAccounts) {
            if (acc.Created_from_Online_App__c == true) {
                accountToUserId.put(acc.Id, acc.CreatedById);
            }
        }

        if (accountToUserId.isEmpty()) {
            return;
        }

        Set<Id> accountIds = accountToUserId.keySet();
        Set<Id> userIds = new Set<Id>();
        userIds.addAll(accountToUserId.values());

        List<cgcloud__Account_Manager__c> existingMgrs = [
            SELECT cgcloud__Account__c, cgcloud__User__c
            FROM cgcloud__Account_Manager__c
            WHERE cgcloud__Account__c IN :accountIds
            AND cgcloud__User__c IN :userIds
        ];

        Set<String> existingKeys = new Set<String>();
        for (cgcloud__Account_Manager__c mgr : existingMgrs) {
            existingKeys.add(mgr.cgcloud__Account__c + ':' + mgr.cgcloud__User__c);
        }

        List<cgcloud__Account_Manager__c> toInsert = new List<cgcloud__Account_Manager__c>();
        for (Id accountId : accountIds) {
            Id userId = accountToUserId.get(accountId);
            if (userId == null) {
                continue;
            }
            String key = accountId + ':' + userId;
            if (!existingKeys.contains(key)) {
                toInsert.add(new cgcloud__Account_Manager__c(
                    cgcloud__Account__c = accountId,
                    cgcloud__User__c = userId,
                    cgcloud__Active__c = true
                ));
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
}