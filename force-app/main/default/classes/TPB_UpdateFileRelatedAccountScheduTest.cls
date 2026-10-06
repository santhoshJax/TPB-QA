/**
 * @description TPB_UpdateFileRelatedAccountScheduler test class
 *
 * @author Jie Yu
 * @date 2023-09-24
 *
 */
@isTest
public without sharing class TPB_UpdateFileRelatedAccountScheduTest{
    /**
     * @description setup data
     */
    @TestSetup
    static void setup() {
        //Create retailer
        Account objRetailer = TPB_TestFactory.createRetailAccount();
        //Create wholesaler
        Account objWholesaler = TPB_TestFactory.createWholesaleAccount();
        //Create document
        TPB_TestFactory.createWholeSalerDocument(objWholesaler);
        //Create related account
        Related_Account__c objRA = TPB_TestFactory.createRelatedAccount(objRetailer, objWholesaler);
        objRA.TPB_Wholesaler_File__c = null;
        update objRA;
    }
    /**
     * @description test batch
     */
    @isTest
    static void testScheduler() {
        //Get wholesaler's document link
        List<ContentDocumentLink> lstLink = [SELECT ID, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT ID FROM ACCOUNT WHERE RecordType.Name = 'Wholesaler')];
        Set<Id> setDocId = new Set<Id>();
        for(ContentDocumentLink objLink : lstLink){
            setDocId.add(objLink.ContentDocumentId);
        }
        //Get file from document link
        List<ContentVersion> lstVer = [ SELECT ContentDocumentId, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :setDocId order by CreatedDate asc];
        Map<Id, DateTime> mapDocDate = new Map<Id, DateTime>();
        for(ContentVersion objVer : lstVer) {
            mapDocDate.put(objVer.ContentDocumentId, objVer.CreatedDate);
        }
        //Get latest file for wholesaler
        Map<Id, Id> mapAccDoc = new Map<Id, Id>();
        for(ContentDocumentLink objLink : lstLink){
            if(!mapAccDoc.containsKey(objLink.LinkedEntityId)){
                mapAccDoc.put(objLink.LinkedEntityId, objLink.ContentDocumentId);
            } else {
                Id idDocOld = mapAccDoc.get(objLink.LinkedEntityId);
                DateTime datOld = mapDocDate.get(idDocOld);
                DateTime datNew = mapDocDate.get(objLink.ContentDocumentId);
                if(datNew > datOld) {
                    mapAccDoc.put(objLink.LinkedEntityId, objLink.ContentDocumentId);
                }
            }
        }
        List<Related_Account__c> lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c FROM Related_Account__c WHERE TPB_Wholesaler_File__c = null AND Wholesaler__c IN :mapAccDoc.keySet() ];
        for(Related_Account__c objRA : lstRA){
            objRA.TPB_Wholesaler_File__c = mapAccDoc.get(objRA.Wholesaler__c);
        }
        //Check batch workable
        Test.startTest();
        new TPB_UpdateFileRelatedAccountScheduler().execute(null);
        Test.stopTest();
        lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c FROM Related_Account__c WHERE TPB_Wholesaler_File__c = null AND Wholesaler__c IN :mapAccDoc.keySet() ];
        System.assertEquals(lstRA.size(), 0);
    }
}