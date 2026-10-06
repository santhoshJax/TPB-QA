/**************************************************************************************
Apex Class Name : TPB_AccountAttachmentHandler
Version         : 2.0
Created Date    : 2023-06-08
Function        : ContentDocumentLink object handler class to link parent HQ
                  attachments to child Retailer accounts asynchronously via batch.
                  Only shares files where ContentVersion.TPB_IsHQAttachment__c = true.
Test Class      : TPB_AccountAttachmentHandlerTest
Modification Log:
-----------------------------------------------------------------------------
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Eric.Chen              2023-06-08           Original Version
* [Developer]            2026-03-05           v2.0 - Refactored to async batch
*                                             processing. Added TPB_IsHQAttachment__c
*                                             filter. Added recursion guard.
*************************************************************************************/
public with sharing class TPB_AccountAttachmentHandler extends SDF_TGF_TriggerHandler {

    // Share Type: V = Viewer
    private static final String SHARE_TYPE = 'V';
    // Visibility Level
    private static final String VISIBILITY_CODE = 'AllUsers';
    // HQ Record Type Name
    private static final String HQ_RECORD_TYPE = 'Headquarter';
    // HQ Child Record Type Name
    private static final String CHILD_RECORD_TYPE = 'Retailer';
    // Account Id Prefix
    private static final String ACCOUNT_ID_PREFIX = '001';
    // File type of Notes - always excluded
    private static final String NOTE_FILE_TYPE = 'SNOTE';
    // Batch size for ContentDocumentLink insert batches
    private static final Integer BATCH_SIZE = 2000;

    /**
     * @description Recursion guard. Set to true by TPB_ContentDocumentLinkBatch
     *              before inserting child ContentDocumentLinks to prevent this
     *              handler from re-processing batch-inserted records.
     */
    public static Boolean isBatchProcessing = false;

    /**
     * @description afterInsert - entry point from trigger framework.
     */
    protected override void afterInsert() {
        // Exit if this insert was triggered by our own batch job
        if (isBatchProcessing) {
            return;
        }
        addContentDocumentLinkToChildAccounts((List<ContentDocumentLink>) Trigger.new);
    }

    /**
     * @description Identifies HQ attachment uploads, filters by TPB_IsHQAttachment__c,
     *              and enqueues a batch job to create ContentDocumentLinks on child
     *              Retailer accounts.
     * @param lstNewDocumentLink The list of new ContentDocumentLink records from trigger.
     */
    private void addContentDocumentLinkToChildAccounts(
        List<ContentDocumentLink> lstNewDocumentLink
    ) {
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setDocumentIds = new Set<Id>();
        Map<Id, List<Id>> mapAccountId2ContentDocumentIds = new Map<Id, List<Id>>();

        // Step 1: Collect Account-linked documents only
        for (ContentDocumentLink objLink : lstNewDocumentLink) {
            String linkedEntityId = objLink.LinkedEntityId;
            if (linkedEntityId.startsWith(ACCOUNT_ID_PREFIX)) {
                setAccountIds.add(linkedEntityId);
                if (!mapAccountId2ContentDocumentIds.containsKey(linkedEntityId)) {
                    mapAccountId2ContentDocumentIds.put(linkedEntityId, new List<Id>());
                }
                mapAccountId2ContentDocumentIds.get(linkedEntityId)
                    .add(objLink.ContentDocumentId);
                setDocumentIds.add(objLink.ContentDocumentId);
            }
        }

        if (setAccountIds.isEmpty() || setDocumentIds.isEmpty()) {
            return;
        }

        // Step 2: Filter to only HQ attachment documents
        // Must have TPB_IsHQAttachment__c = true AND not be a Note (SNOTE)
        Set<Id> validDocumentIds = new Set<Id>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :setDocumentIds
            AND IsLatest = true
            AND TPB_IsHQAttachment__c = true
        ]) {
            validDocumentIds.add(cv.ContentDocumentId);
        }

        if (validDocumentIds.isEmpty()) {
            return;
        }

        // Step 3: Get file types to exclude Notes
        Map<Id, ContentDocument> mapDocument = new Map<Id, ContentDocument>([
            SELECT Id, FileType
            FROM ContentDocument
            WHERE Id IN :validDocumentIds
        ]);

        // Remove any SNOTE file types from valid set
        for (Id docId : new Set<Id>(validDocumentIds)) {
            ContentDocument doc = mapDocument.get(docId);
            if (doc != null && doc.FileType == NOTE_FILE_TYPE) {
                validDocumentIds.remove(docId);
            }
        }

        if (validDocumentIds.isEmpty()) {
            return;
        }

        // Step 4: Get child Retailer accounts under HQ parents
        List<Account> lstChildAccount = [
            SELECT Id, Name, ParentId
            FROM Account
            WHERE RecordType.Name = :CHILD_RECORD_TYPE
            AND ParentId IN :setAccountIds
            AND Parent.RecordType.Name = :HQ_RECORD_TYPE
        ];

        if (lstChildAccount.isEmpty()) {
            return;
        }

        // Step 5: Build list of ContentDocumentLinks for child accounts
        List<ContentDocumentLink> lstLink2ChildAccount = new List<ContentDocumentLink>();
        for (Account objChild : lstChildAccount) {
            List<Id> lstContentDocumentIds = mapAccountId2ContentDocumentIds.get(
                objChild.ParentId
            );
            if (lstContentDocumentIds == null || lstContentDocumentIds.isEmpty()) {
                continue;
            }
            for (Id contentDocId : lstContentDocumentIds) {
                if (!validDocumentIds.contains(contentDocId)) {
                    continue;
                }
                lstLink2ChildAccount.add(new ContentDocumentLink(
                    ContentDocumentId = contentDocId,
                    LinkedEntityId = objChild.Id,
                    ShareType = SHARE_TYPE,
                    Visibility = VISIBILITY_CODE
                ));
            }
        }

        // Step 6: Enqueue batch job if there are links to create
        if (!lstLink2ChildAccount.isEmpty()) {
            Database.executeBatch(
                new TPB_ContentDocumentLinkBatch(lstLink2ChildAccount),
                BATCH_SIZE
            );
        }
    }
}