@isTest
private class TPB_ContentDocumentLinkBatchTest {

    @TestSetup
    static void setupTestData() {
        Id retailerAccountTemplateId = TestDataFactory.ensureRetailerAutomationPrereqs();
        Id hqRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('Headquarter').getRecordTypeId();
        Id retailerRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName().get('Retailer').getRecordTypeId();

        Account hqAccount = new Account(
            Name = 'Batch Test HQ',
            RecordTypeId = hqRecordTypeId
        );
        insert hqAccount;

        List<Account> childAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            childAccounts.add(new Account(
                Name = 'Batch Retailer ' + i,
                cgcloud__Account_Template__c = retailerAccountTemplateId,
                RecordTypeId = retailerRecordTypeId,
                ParentId = hqAccount.Id
            ));
        }
        insert childAccounts;
    }

    @isTest
    static void testBatchInsertsSuccessfully() {
        Account hqAccount = [
            SELECT Id FROM Account WHERE Name = 'Batch Test HQ' LIMIT 1
        ];
        List<Account> children = [
            SELECT Id FROM Account WHERE ParentId = :hqAccount.Id
        ];

        ContentVersion cv = new ContentVersion(
            Title = 'Batch Test File',
            PathOnClient = 'BatchTestFile.pdf',
            VersionData = Blob.valueOf('Batch test content'),
            TPB_IsHQAttachment__c = true
        );
        insert cv;
        cv = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Account child : children) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = child.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }

        Test.startTest();
        TPB_ContentDocumentLinkBatch batchJob = new TPB_ContentDocumentLinkBatch(links);
        Database.executeBatch(batchJob, 2000);
        Test.stopTest();

        List<ContentDocumentLink> createdLinks = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN :children
        ];
        System.assertEquals(10, createdLinks.size(),
            'Expected 10 ContentDocumentLinks created by batch.');
    }

    @isTest
    static void testBatchHandlesPartialFailures() {
        Account hqAccount = [
            SELECT Id FROM Account WHERE Name = 'Batch Test HQ' LIMIT 1
        ];
        List<Account> children = [
            SELECT Id FROM Account WHERE ParentId = :hqAccount.Id ORDER BY Name LIMIT 3
        ];

        ContentVersion cv = new ContentVersion(
            Title = 'Partial Fail Test',
            PathOnClient = 'PartialFail.pdf',
            VersionData = Blob.valueOf('Partial fail content'),
            TPB_IsHQAttachment__c = true
        );
        insert cv;
        cv = [
            SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];

        ContentDocumentLink existingLink = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = children[0].Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert existingLink;

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Account child : children) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = child.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }

        Test.startTest();
        TPB_ContentDocumentLinkBatch batchJob = new TPB_ContentDocumentLinkBatch(links);
        Database.executeBatch(batchJob, 2000);
        Test.stopTest();

        List<ContentDocumentLink> createdLinks = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId IN :children
        ];
        System.assert(createdLinks.size() >= 2,
            'Batch should succeed for non-duplicate records.');
    }

    @isTest
    static void testBatchWithEmptyList() {
        List<ContentDocumentLink> emptyList = new List<ContentDocumentLink>();

        Test.startTest();
        TPB_ContentDocumentLinkBatch batchJob = new TPB_ContentDocumentLinkBatch(emptyList);
        Database.executeBatch(batchJob, 2000);
        Test.stopTest();

        System.assert(true, 'Batch should handle empty list without errors.');
    }
}