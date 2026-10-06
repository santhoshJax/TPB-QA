/**************************************************************************************
Apex Class Name : TPB_AccountHQFileDistributionHandler
Version         : 1.1
Created Date    : 2026-04-24
Function        : Account trigger handler. When a Retailer account is created or
                  re-parented to a Headquarter account, distributes all existing
                  HQ Execution Guide files to the new store via async batch.
                  When a store moves FROM one HQ to another, removes stale CDLs
                  from the old HQ's attachment files before distributing new ones.
                  Complements TPB_AccountAttachmentHandler (which handles new
                  file uploads) by covering the "new store added to chain" case.
Test Class      : TPB_AccountHQFileDistributionHandlerTest
Modification Log:
-----------------------------------------------------------------------------
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Jax Consulting         2026-04-24           Original Version
* Jax Consulting         2026-04-27           v1.1 - Remove stale HQ CDLs when
*                                             store is reparented to a new HQ
*************************************************************************************/
public with sharing class TPB_AccountHQFileDistributionHandler extends SDF_TGF_TriggerHandler {

    private static final String HQ_RECORD_TYPE_DEV   = 'Headquarter';
    private static final String CHILD_RECORD_TYPE_DEV = 'Retailer';
    private static final String NOTE_FILE_TYPE        = 'SNOTE';
    private static final String SHARE_TYPE            = 'V';
    private static final String VISIBILITY_CODE       = 'AllUsers';
    private static final Integer BATCH_SIZE           = 2000;

    protected override void afterInsert() {
        distributeToNewStores((List<Account>) Trigger.new, null);
    }

    protected override void afterUpdate() {
        List<Account> newAccounts = (List<Account>) Trigger.new;
        Map<Id, Account> oldMap  = (Map<Id, Account>) Trigger.oldMap;
        removeStaleHQLinks(newAccounts, oldMap);
        distributeToNewStores(newAccounts, oldMap);
    }

    /**
     * @description When a store moves from one HQ to another, deletes CDLs on the
     *              store that originated from the old HQ's attachment files.
     */
    private void removeStaleHQLinks(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get(CHILD_RECORD_TYPE_DEV).getRecordTypeId();
        Id hqRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get(HQ_RECORD_TYPE_DEV).getRecordTypeId();

        // Collect stores that had a previous HQ parent that changed
        Map<Id, Id> storeToOldHQ = new Map<Id, Id>(); // store Id → old HQ Id
        for (Account acc : newAccounts) {
            if (acc.RecordTypeId != retailerRtId) continue;
            Id prevParentId = oldMap.get(acc.Id)?.ParentId;
            if (prevParentId == null || prevParentId == acc.ParentId) continue;
            storeToOldHQ.put(acc.Id, prevParentId);
        }

        if (storeToOldHQ.isEmpty()) return;

        // Confirm old parents were Headquarter record type
        Set<Id> confirmedOldHQIds = new Set<Id>();
        for (Account hq : [
            SELECT Id FROM Account
            WHERE Id IN :storeToOldHQ.values() AND RecordTypeId = :hqRtId
        ]) {
            confirmedOldHQIds.add(hq.Id);
        }

        Set<Id> storeIds = new Set<Id>();
        for (Id storeId : storeToOldHQ.keySet()) {
            if (confirmedOldHQIds.contains(storeToOldHQ.get(storeId))) {
                storeIds.add(storeId);
            }
        }

        if (storeIds.isEmpty()) return;

        // Get doc IDs linked to old HQ accounts
        Set<Id> oldHQDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :confirmedOldHQIds
        ]) {
            oldHQDocIds.add(cdl.ContentDocumentId);
        }

        if (oldHQDocIds.isEmpty()) return;

        // Filter to HQ attachment docs only
        Set<Id> validOldDocIds = new Set<Id>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId FROM ContentVersion
            WHERE ContentDocumentId IN :oldHQDocIds
            AND IsLatest = true
            AND TPB_IsHQAttachment__c = true
        ]) {
            validOldDocIds.add(cv.ContentDocumentId);
        }

        if (validOldDocIds.isEmpty()) return;

        // Delete stale CDLs on the reparented stores
        List<ContentDocumentLink> linksToDelete = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId IN :validOldDocIds
            AND LinkedEntityId IN :storeIds
        ];

        if (!linksToDelete.isEmpty()) {
            Database.delete(linksToDelete, false);
        }
    }

    /**
     * @description Finds stores that are newly assigned to an HQ parent and
     *              distributes all existing HQ attachment files to them.
     */
    private void distributeToNewStores(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get(CHILD_RECORD_TYPE_DEV).getRecordTypeId();
        Id hqRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get(HQ_RECORD_TYPE_DEV).getRecordTypeId();

        // Collect stores whose HQ parent just changed or was first assigned
        Map<Id, Id> storeToHQ = new Map<Id, Id>(); // store Id → new HQ Id
        for (Account acc : newAccounts) {
            if (acc.RecordTypeId != retailerRtId || acc.ParentId == null) {
                continue;
            }
            Id prevParentId = oldMap != null ? oldMap.get(acc.Id)?.ParentId : null;
            if (acc.ParentId != prevParentId) {
                storeToHQ.put(acc.Id, acc.ParentId);
            }
        }

        if (storeToHQ.isEmpty()) {
            return;
        }

        // Verify parent accounts are Headquarter record type
        Set<Id> candidateHQIds = new Set<Id>(storeToHQ.values());
        Set<Id> confirmedHQIds = new Set<Id>();
        for (Account hq : [
            SELECT Id FROM Account
            WHERE Id IN :candidateHQIds AND RecordTypeId = :hqRtId
        ]) {
            confirmedHQIds.add(hq.Id);
        }

        Map<Id, Id> confirmedStoreToHQ = new Map<Id, Id>();
        for (Id storeId : storeToHQ.keySet()) {
            if (confirmedHQIds.contains(storeToHQ.get(storeId))) {
                confirmedStoreToHQ.put(storeId, storeToHQ.get(storeId));
            }
        }

        if (confirmedStoreToHQ.isEmpty()) {
            return;
        }

        // Collect all ContentDocumentLinks on confirmed HQ accounts
        Map<Id, List<Id>> hqToDocIds = new Map<Id, List<Id>>();
        Set<Id> candidateDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :confirmedHQIds
        ]) {
            Id hqId = (Id) cdl.LinkedEntityId;
            if (!hqToDocIds.containsKey(hqId)) {
                hqToDocIds.put(hqId, new List<Id>());
            }
            hqToDocIds.get(hqId).add(cdl.ContentDocumentId);
            candidateDocIds.add(cdl.ContentDocumentId);
        }

        if (candidateDocIds.isEmpty()) {
            return;
        }

        // Filter to HQ attachment files: IsLatest = true AND TPB_IsHQAttachment__c = true
        Set<Id> validDocIds = new Set<Id>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId FROM ContentVersion
            WHERE ContentDocumentId IN :candidateDocIds
            AND IsLatest = true
            AND TPB_IsHQAttachment__c = true
        ]) {
            validDocIds.add(cv.ContentDocumentId);
        }

        if (validDocIds.isEmpty()) {
            return;
        }

        // Exclude Notes (SNOTE)
        for (ContentDocument doc : [
            SELECT Id FROM ContentDocument
            WHERE Id IN :validDocIds AND FileType = :NOTE_FILE_TYPE
        ]) {
            validDocIds.remove(doc.Id);
        }

        if (validDocIds.isEmpty()) {
            return;
        }

        // Skip documents already linked to these stores to avoid duplicate CDL errors
        Set<String> existingKeys = new Set<String>();
        for (ContentDocumentLink existing : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :validDocIds
            AND LinkedEntityId IN :confirmedStoreToHQ.keySet()
        ]) {
            existingKeys.add(existing.ContentDocumentId + '_' + existing.LinkedEntityId);
        }

        // Build ContentDocumentLink records for each new store
        List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
        for (Id storeId : confirmedStoreToHQ.keySet()) {
            Id hqId = confirmedStoreToHQ.get(storeId);
            List<Id> hqDocIds = hqToDocIds.get(hqId);
            if (hqDocIds == null) {
                continue;
            }
            for (Id docId : hqDocIds) {
                if (!validDocIds.contains(docId)) {
                    continue;
                }
                if (existingKeys.contains(docId + '_' + storeId)) {
                    continue;
                }
                linksToCreate.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId    = storeId,
                    ShareType         = SHARE_TYPE,
                    Visibility        = VISIBILITY_CODE
                ));
            }
        }

        if (!linksToCreate.isEmpty()) {
            Database.executeBatch(
                new TPB_ContentDocumentLinkBatch(linksToCreate),
                BATCH_SIZE
            );
        }
    }
}