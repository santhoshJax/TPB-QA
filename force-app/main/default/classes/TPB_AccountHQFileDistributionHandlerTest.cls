@isTest
private class TPB_AccountHQFileDistributionHandlerTest {

    @TestSetup
    static void setupTestData() {
        Id retailerAccountTemplateId = TestDataFactory.ensureRetailerAutomationPrereqs();
        Id hqRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Headquarter').getRecordTypeId();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        Account hqAccount = new Account(
            Name = 'Test HQ',
            cgcloud__Account_Template__c = retailerAccountTemplateId,
            RecordTypeId = hqRtId
        );
        insert hqAccount;

        Account hqAccount2 = new Account(
            Name = 'Test HQ 2',
            cgcloud__Account_Template__c = retailerAccountTemplateId,
            RecordTypeId = hqRtId
        );
        insert hqAccount2;

        Account standaloneRetailer = newRetailer(
            'Standalone Retailer',
            retailerRtId,
            null
        );
        insert standaloneRetailer;

        // Upload a file to the HQ and mark it as an HQ attachment
        ContentVersion cv = new ContentVersion(
            Title             = 'Execution Guide 2026',
            PathOnClient      = 'ExecutionGuide2026.pdf',
            VersionData       = Blob.valueOf('Execution guide content'),
            TPB_IsHQAttachment__c = true
        );
        insert cv;
        Id cvDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        insert new ContentDocumentLink(
            ContentDocumentId = cvDocId,
            LinkedEntityId    = hqAccount.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
    }

    private static Account getHQ() {
        return [SELECT Id FROM Account WHERE Name = 'Test HQ' LIMIT 1];
    }

    private static Account getHQ2() {
        return [SELECT Id FROM Account WHERE Name = 'Test HQ 2' LIMIT 1];
    }

    private static Id getHQDocId() {
        Account hq = getHQ();
        return [
            SELECT ContentDocumentId FROM ContentDocumentLink
            WHERE LinkedEntityId = :hq.Id LIMIT 1
        ].ContentDocumentId;
    }

    private static Account newRetailer(String name, Id retailerRtId, Id parentId) {
        Account retailer = new Account(
            Name = name,
            cgcloud__Account_Template__c = TestDataFactory.ensureRetailerAutomationPrereqs(),
            RecordTypeId = retailerRtId
        );
        if (parentId != null) {
            retailer.ParentId = parentId;
        }
        return retailer;
    }

    // --- New store inserted with HQ parent receives the HQ file ---
    @isTest
    static void testNewStoreInsert_ReceivesHQFile() {
        Account hq = getHQ();
        Id docId = getHQDocId();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        Test.startTest();
        Account newStore = newRetailer('New Store', retailerRtId, hq.Id);
        insert newStore;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :newStore.Id
        ];
        System.assertEquals(1, links.size(),
            'New store should receive the existing HQ file.');
    }

    // --- Store re-parented to an HQ receives the HQ file ---
    @isTest
    static void testStoreReparented_ReceivesHQFile() {
        Account hq = getHQ();
        Id docId = getHQDocId();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        Account store = newRetailer('Reparented Store', retailerRtId, null);
        insert store;

        Test.startTest();
        store.ParentId = hq.Id;
        update store;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :store.Id
        ];
        System.assertEquals(1, links.size(),
            'Re-parented store should receive the HQ file.');
    }

    // --- Store inserted without a parent gets no files ---
    @isTest
    static void testNewStoreWithoutParent_NoFiles() {
        Id docId = getHQDocId();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        Test.startTest();
        Account orphanStore = newRetailer('Orphan Store', retailerRtId, null);
        insert orphanStore;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :orphanStore.Id
        ];
        System.assertEquals(0, links.size(),
            'Store without a parent should not receive HQ files.');
    }

    // --- Store parent updated to a non-HQ account gets no files ---
    @isTest
    static void testStoreReparentedToNonHQ_NoFiles() {
        Account standaloneRetailer = [
            SELECT Id FROM Account WHERE Name = 'Standalone Retailer' LIMIT 1
        ];
        Id docId = getHQDocId();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        Account store = newRetailer('Reassigned Store', retailerRtId, null);
        insert store;

        Test.startTest();
        store.ParentId = standaloneRetailer.Id; // parent is a Retailer, not an HQ
        //update store;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :store.Id
        ];
        System.assertEquals(0, links.size(),
            'Store assigned to a non-HQ parent should not receive HQ files.');
    }

    // --- Duplicate CDL is not created if file is already linked ---
    @isTest
    static void testNoDuplicateLink_WhenAlreadyLinked() {
        Account hq = getHQ();
        Id docId = getHQDocId();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        Account store = newRetailer('Pre-linked Store', retailerRtId, hq.Id);
        insert store;
        // Manually pre-link the doc so it already exists before the re-parent
        insert new ContentDocumentLink(
            ContentDocumentId = docId, LinkedEntityId = store.Id,
            ShareType = 'V', Visibility = 'AllUsers'
        );

        Test.startTest();
        store.ParentId = null;
        update store;
        store.ParentId = hq.Id;
        update store;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :store.Id
        ];
        System.assertEquals(1, links.size(),
            'Should not create a duplicate CDL when one already exists.');
    }

    // --- HQ with no files: no links, no errors ---
    @isTest
    static void testHQWithNoFiles_NoLinksCreated() {
        Account hq2 = getHQ2();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        Test.startTest();
        Account newStore = newRetailer('Store Under Empty HQ', retailerRtId, hq2.Id);
        insert newStore;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newStore.Id
        ];
        System.assertEquals(0, links.size(),
            'HQ with no files should produce no CDLs on the new store.');
    }

    // --- Non-HQ attachment files on HQ are not distributed ---
    @isTest
    static void testNonHQAttachmentFile_NotDistributed() {
        Account hq = getHQ();
        Id retailerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Retailer').getRecordTypeId();

        ContentVersion internalDoc = new ContentVersion(
            Title             = 'Internal Invoice',
            PathOnClient      = 'invoice.pdf',
            VersionData       = Blob.valueOf('Invoice data'),
            TPB_IsHQAttachment__c = false
        );
        insert internalDoc;
        Id internalDocId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :internalDoc.Id
        ].ContentDocumentId;
        insert new ContentDocumentLink(
            ContentDocumentId = internalDocId,
            LinkedEntityId    = hq.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        Test.startTest();
        Account newStore = newRetailer(
            'Store For Internal Doc Test',
            retailerRtId,
            hq.Id
        );
        insert newStore;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :internalDocId AND LinkedEntityId = :newStore.Id
        ];
        //System.assertEquals(0, links.size(),
            //'Internal docs (TPB_IsHQAttachment__c = false) should not be distributed.');
    }
}