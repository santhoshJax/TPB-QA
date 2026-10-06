/**
 * @description TPB_ContentDocumentLinkHandler
 *
 * @author Jie Yu
 * @date 2023-07-19
 *
 */
public without sharing class TPB_ContentDocumentLinkHandler extends SDF_TGF_TriggerHandler {
    /**
     * @description after insert trigger handler
     */
    protected override void afterInsert() {
        //when insert document, the link on related acccount is updated
        List<ContentDocumentLink> lstLink = (List<ContentDocumentLink>) Trigger.new;
        Map<Id, Id> mapDocIds = new Map<Id, Id>();
        for (ContentDocumentLink objLink : lstLink) {
            //AccountId, DocId
            mapDocIds.put(objLink.LinkedEntityId, objLink.ContentDocumentId);
        }
        //Make sure only wholesaler account's file are proccessed
        List<Account> lstAcc = [ SELECT Id FROM Account WHERE RecordType.Name = 'Wholesaler' AND Id IN :mapDocIds.keySet() ];
        Map<Id, Id> mapDocIdsProcessed = new Map<Id, Id>();
        for(Account objAcc : lstAcc){
            mapDocIdsProcessed.put(objAcc.Id, mapDocIds.get(objAcc.Id));
        }
        //Process data
        if(mapDocIdsProcessed!=null && mapDocIdsProcessed.size()>0){
            processData(mapDocIdsProcessed);
        }
    }
    /**
     * @description after delete trigger handler
     */
    protected override void afterDelete() {
        //After document deleted, the link of related account should be cleaned.
        List<ContentDocumentLink> lstLink = (List<ContentDocumentLink>) Trigger.old;
        Map<Id, Id> mapDocIds = new Map<Id, Id>();
        for (ContentDocumentLink objLink : lstLink) {
            //AccountId, DocId
            mapDocIds.put(objLink.LinkedEntityId, objLink.ContentDocumentId);
        }
        //Make sure only wholesaler account's file are proccessed
        List<Account> lstAcc = [ SELECT Id FROM Account WHERE RecordType.Name = 'Wholesaler' AND Id IN :mapDocIds.keySet() ];
        Map<Id, Id> mapDocIdsProcessed = new Map<Id, Id>();
        for(Account objAcc : lstAcc){
            mapDocIdsProcessed.put(objAcc.Id, mapDocIds.get(objAcc.Id));
        }
        //Process data
        if(mapDocIdsProcessed!=null && mapDocIdsProcessed.size()>0){
            processDeleteData(mapDocIdsProcessed);
        }
    }
    /*
    * @description process data
    * @param map of accountid, doc id
    */
    private void processData(Map<Id, Id> mapDocIdsProcessed) {
        //update the link with inserted document
        List<Related_Account__c> lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c FROM Related_Account__c WHERE Wholesaler__c IN :mapDocIdsProcessed.keySet() ];
        for(Related_Account__c objRA : lstRA){
            objRA.TPB_Wholesaler_File__c = mapDocIdsProcessed.get(objRA.Wholesaler__c);
        }
        update lstRA;
    }
    /*
    * @description process delete data
    * @param map of accountid, doc id
    */
    private void processDeleteData(Map<Id, Id> mapDocIdsProcessed) {
        //remove the link from related account
        List<Related_Account__c> lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c FROM Related_Account__c WHERE Wholesaler__c IN :mapDocIdsProcessed.keySet() ];
        for(Related_Account__c objRA : lstRA){
            if( objRA.TPB_Wholesaler_File__c == mapDocIdsProcessed.get(objRA.Wholesaler__c) ){
                objRA.TPB_Wholesaler_File__c = null;
            }
        }
        update lstRA;
    }
}