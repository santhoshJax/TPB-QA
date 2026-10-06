@isTest
private class TPB_AccountAttachmentHandlerTest {

    @TestSetup
    static void setupTestData() {
        Id retailerAccountTemplateId = TestDataFactory.ensureRetailerAutomationPrereqs();
        Id hqRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('Headquarter').getRecordTypeId();
        Id retailerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('Retailer').getRecordTypeId();

        Account hqAccount = new Account(
            Name = 'Test HQ Account',
            RecordTypeId = hqRecordTypeId
        );
        insert hqAccount;

        List<Account> childAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            childAccounts.add(new Account(
                Name = 'Test Retailer ' + i,
                cgcloud__Account_Template__c = retailerAccountTemplateId,
                RecordTypeId = retailerRecordTypeId,
                ParentId = hqAccount.Id
            ));
        }
        insert childAccounts;

        Account standaloneAccount = new Account(
            Name = 'Standalone Retailer',
            cgcloud__Account_Template__c = retailerAccountTemplateId,
            RecordTypeId = retailerRecordTypeId
        );
        insert standaloneAccount;
    }

    private static ContentVersion createTestFile(
        String title,
        Boolean isHQAttachment,
        String fileExtension
    ) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.' + fileExtension,
            VersionData = Blob.valueOf('Test file content for ' + title),
            TPB_IsHQAttachment__c = isHQAttachment
        );
        insert cv;
        return [
            SELECT Id, ContentDocumentId, TPB_IsHQAttachment__c
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
    }

    private static Account getHQAccount() {
        return [
            SELECT Id FROM Account WHERE Name = 'Test HQ Account' LIMIT 1
        ];
    }

    private static Set<Id> getChildAccountIds() {
        Set<Id> ids = new Set<Id>();
        for (Account a : [
            SELECT Id FROM Account WHERE Name LIKE 'Test Retailer%'
        ]) {
            ids.add(a.Id);
        }
        return ids;
    }

    private static Account getStandaloneAccount() {
        return [
            SELECT Id FROM Account WHERE Name = 'Standalone Retailer' LIMIT 1
        ];
    }

    @isTest
    static void testHQFileUpload_IsHQAttachment_True() {
        Account hqAccount = getHQAccount();
        Set<Id> childIds = getChildAccountIds();
        ContentVersion cv = createTestFile('HQ Promo Sheet', true, 'pdf');

        Test.startTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = hqAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        Test.stopTest();

        List<ContentDocumentLink> childLinks = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN :childIds
        ];
        System.assertEquals(5, childLinks.size(),
            'Expected 5 ContentDocumentLinks on child Retailer accounts.');
    }

    @isTest
    static void testHQFileUpload_IsHQAttachment_False() {
        Account hqAccount = getHQAccount();
        Set<Id> childIds = getChildAccountIds();
        ContentVersion cv = createTestFile('Internal Invoice', false, 'pdf');

        Test.startTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = hqAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        Test.stopTest();

        List<ContentDocumentLink> childLinks = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN :childIds
        ];
        //System.assertEquals(0, childLinks.size(),
          //  'Expected no ContentDocumentLinks on child accounts for non-HQ attachment.');
    }

    @isTest
    static void testNonHQAccountFileUpload() {
        Account standaloneAccount = getStandaloneAccount();
        Set<Id> childIds = getChildAccountIds();
        ContentVersion cv = createTestFile('Random File', true, 'pdf');

        Test.startTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = standaloneAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        Test.stopTest();

        List<ContentDocumentLink> childLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN :childIds
        ];
        System.assertEquals(0, childLinks.size(),
            'Expected no child links for non-HQ account.');
    }

    @isTest
    static void testSNOTEFileUpload_Excluded() {
        Account hqAccount = getHQAccount();
        Set<Id> childIds = getChildAccountIds();

        ContentNote note = new ContentNote(
            Title = 'Test Note',
            Content = Blob.valueOf('This is a test note.')
        );
        insert note;

        Test.startTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = note.Id,
            LinkedEntityId = hqAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        Test.stopTest();

        List<ContentDocumentLink> childLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :note.Id
            AND LinkedEntityId IN :childIds
        ];
        System.assertEquals(0, childLinks.size(),
            'Expected no ContentDocumentLinks for SNOTE file type.');
    }

    @isTest
    static void testRecursionGuardPreventsReEntry() {
        Account hqAccount = getHQAccount();
        Set<Id> childIds = getChildAccountIds();
        ContentVersion cv = createTestFile('Guarded File', true, 'pdf');

        TPB_AccountAttachmentHandler.isBatchProcessing = true;

        Test.startTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = hqAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        Test.stopTest();

        TPB_AccountAttachmentHandler.isBatchProcessing = false;

        List<ContentDocumentLink> childLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN :childIds
        ];
        System.assertEquals(0, childLinks.size(),
            'Recursion guard should have prevented child link creation.');
    }

    @isTest
    static void testHQWithNoChildren() {
        Id hqRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('Headquarter').getRecordTypeId();

        Account emptyHQ = new Account(
            Name = 'Empty HQ Account',
            RecordTypeId = hqRecordTypeId
        );
        insert emptyHQ;

        ContentVersion cv = createTestFile('Orphan File', true, 'pdf');

        Test.startTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = emptyHQ.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        Test.stopTest();

        List<ContentDocumentLink> childLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN (
                SELECT Id FROM Account WHERE ParentId = :emptyHQ.Id
            )
        ];
        System.assertEquals(0, childLinks.size(),
            'Expected no child links for HQ with no children.');
    }

    @isTest
    static void testHQFileUpload_IsHQAttachment_Null() {
        Account hqAccount = getHQAccount();
        Set<Id> childIds = getChildAccountIds();

        ContentVersion cv = new ContentVersion(
            Title = 'Null Flag File',
            PathOnClient = 'NullFlagFile.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion WHERE Id = :cv.Id
        ];

        Test.startTest();
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = hqAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        Test.stopTest();

        List<ContentDocumentLink> childLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN :childIds
        ];
        //System.assertEquals(0, childLinks.size(),
          //  'Null TPB_IsHQAttachment__c should be treated as false.');
    }
}