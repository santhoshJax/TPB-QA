/**
 * @description Test class for TPB_OpportunityAttachmentCountHandler,
 * TPB_OpportunityFileDocDeleteHandler, TPB_OpportunityFileCountUtil and
 * TPB_OpportunityFileCountBatch — verifies Opportunity.TPB_Attached_File_Count__c
 * stays accurate as Files are attached to and removed from an Opportunity directly,
 * whether a file is unlinked or fully deleted.
 *
 * @author Claude Code
 * @date 2026-07-27
 */
@isTest
public without sharing class TPB_OpportunityFileCountTest {
    @TestSetup
    static void setup() {
        Account objRetailer = TPB_TestFactory.createRetailAccount();
        TPB_TestFactory.createOpportunity(objRetailer.Id);
    }

    /*
     * @description creates a ContentDocumentLink attaching a new File to the given
     * record and returns the ContentDocumentId.
     */
    private static Id attachFile(Id linkedEntityId) {
        ContentVersion objVersion = new ContentVersion(
            VersionData = Blob.valueOf('test'),
            PathOnClient = 'test.pdf',
            Title = 'test-' + System.now().getTime()
        );
        insert objVersion;
        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :objVersion.Id
        ].ContentDocumentId;
        insert new ContentDocumentLink(
            LinkedEntityId = linkedEntityId,
            ContentDocumentId = contentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        return contentDocumentId;
    }

    @isTest
    static void testCountStartsAtZero() {
        Opportunity objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity LIMIT 1];
        System.assertEquals(0, objOpp.TPB_Attached_File_Count__c, 'New Opportunity should start with 0 attached files');
    }

    @isTest
    static void testCountIncrementsAsFilesAreAdded() {
        Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        attachFile(objOpp.Id);
        Test.stopTest();

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(1, objOpp.TPB_Attached_File_Count__c, 'Count should be 1 after attaching one file');
    }

    @isTest
    static void testCountReflectsMultipleFilesAddedAtOnce() {
        Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];

        List<ContentVersion> lstVersion = new List<ContentVersion>();
        for (Integer i = 0; i < 3; i++) {
            lstVersion.add(new ContentVersion(
                VersionData = Blob.valueOf('test' + i),
                PathOnClient = 'test' + i + '.pdf',
                Title = 'bulk-test-' + i
            ));
        }

        Test.startTest();
        insert lstVersion;
        Map<Id, Id> mapVersionIdToDocumentId = new Map<Id, Id>();
        for (ContentVersion objVersion : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :lstVersion
        ]) {
            mapVersionIdToDocumentId.put(objVersion.Id, objVersion.ContentDocumentId);
        }
        List<ContentDocumentLink> lstLink = new List<ContentDocumentLink>();
        for (Id documentId : mapVersionIdToDocumentId.values()) {
            lstLink.add(new ContentDocumentLink(
                LinkedEntityId = objOpp.Id,
                ContentDocumentId = documentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert lstLink;
        Test.stopTest();

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(3, objOpp.TPB_Attached_File_Count__c, 'Count should reflect all 3 files added in one bulk operation');
    }

    @isTest
    static void testCountDecrementsWhenLinkRemovedWithoutDeletingFile() {
        Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Id docId1 = attachFile(objOpp.Id);
        attachFile(objOpp.Id);

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(2, objOpp.TPB_Attached_File_Count__c, 'Count should be 2 before any removal');

        ContentDocumentLink objLinkToRemove = [
            SELECT Id FROM ContentDocumentLink
            WHERE LinkedEntityId = :objOpp.Id AND ContentDocumentId = :docId1
        ];

        Test.startTest();
        delete objLinkToRemove;
        Test.stopTest();

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(1, objOpp.TPB_Attached_File_Count__c, 'Count should decrement to 1 after unlinking (not deleting) one file');
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :docId1], 'The unlinked file itself should still exist');
    }

    @isTest
    static void testCountReturnsToZeroWhenAllFilesFullyDeleted() {
        Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Id docId1 = attachFile(objOpp.Id);
        Id docId2 = attachFile(objOpp.Id);

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(2, objOpp.TPB_Attached_File_Count__c, 'Count should be 2 before any deletion');

        Test.startTest();
        delete [SELECT Id FROM ContentDocument WHERE Id = :docId1];
        Test.stopTest();

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(1, objOpp.TPB_Attached_File_Count__c, 'Count should decrement to 1 after fully deleting one file');

        delete [SELECT Id FROM ContentDocument WHERE Id = :docId2];
        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(0, objOpp.TPB_Attached_File_Count__c, 'Count should return to 0 after fully deleting the last file');
    }

    @isTest
    static void testFilesOnRelatedAccountAreNotCounted() {
        Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Test.startTest();
        attachFile(objOpp.AccountId);
        Test.stopTest();

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(0, objOpp.TPB_Attached_File_Count__c, 'Files attached only to the related Account must not be counted');
    }

    @isTest
    static void testBatchBackfillsExistingOpportunities() {
        Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
        attachFile(objOpp.Id);
        attachFile(objOpp.Id);

        // Simulate a pre-existing Opportunity whose count field was never populated.
        objOpp.TPB_Attached_File_Count__c = 0;
        update objOpp;

        Test.startTest();
        Database.executeBatch(new TPB_OpportunityFileCountBatch());
        Test.stopTest();

        objOpp = [SELECT Id, TPB_Attached_File_Count__c FROM Opportunity WHERE Id = :objOpp.Id];
        System.assertEquals(2, objOpp.TPB_Attached_File_Count__c, 'Batch should backfill the count from existing ContentDocumentLinks');
    }
}