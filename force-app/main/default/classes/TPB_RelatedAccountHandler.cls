/**
 * @description TPB_RelatedAccountHandler
 *
 * @author Jie Yu
 * @date 2023-07-19
 *
 */
public without sharing class TPB_RelatedAccountHandler extends SDF_TGF_TriggerHandler {
    /**
     * @description after delete trigger handler
     */
    protected override void beforeInsert() {
        //Get Wholesaler from Related Account
        //Get attachment from whole saler and update to related account
        List<Related_Account__c> lstRA = (List<Related_Account__c>) Trigger.new;
        processData(lstRA);
    }
    /*
    * @description process insert data
    * @param list of related account
    */
    private void processData(List<Related_Account__c> lstRA) {
        Set<Id> setAccId = new Set<Id>();
        for(Related_Account__c objRA : lstRA){
            setAccId.add(objRA.Wholesaler__c);
        }
        //whole saler must exists
        setAccId.remove(null);
        //Get document from wholesaler
        List<ContentDocumentLink> lstLink = [SELECT ID, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :setAccId ];
        Set<Id> setDocId = new Set<Id>();
        for(ContentDocumentLink objLink : lstLink){
            setDocId.add(objLink.ContentDocumentId);
        }
        if(setDocId.size()>0){
            //Get latest document for account
            List<ContentVersion> lstVer = [ SELECT ContentDocumentId, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :setDocId order by CreatedDate asc];
            Map<Id, DateTime> mapDocDate = new Map<Id, DateTime>();
            for(ContentVersion objVer : lstVer) {
                mapDocDate.put(objVer.ContentDocumentId, objVer.CreatedDate);
            }
            Map<Id, Id> mapAccDoc = new Map<Id, Id>();
            for(ContentDocumentLink objLink : lstLink){
                if(!mapAccDoc.containsKey(objLink.LinkedEntityId)){
                    //map for wholesaler and document
                    mapAccDoc.put(objLink.LinkedEntityId, objLink.ContentDocumentId);
                } else {
                    //If multiple, get latest one
                    Id idDocOld = mapAccDoc.get(objLink.LinkedEntityId);
                    DateTime datOld = mapDocDate.get(idDocOld);
                    DateTime datNew = mapDocDate.get(objLink.ContentDocumentId);
                    if(datNew > datOld) {
                        mapAccDoc.put(objLink.LinkedEntityId, objLink.ContentDocumentId);
                    }
                }
            }
            //Update the id to relate account
            for(Related_Account__c objRA : lstRA){
                if(mapAccDoc.containsKey(objRA.Wholesaler__c)){
                    objRA.TPB_Wholesaler_File__c = mapAccDoc.get(objRA.Wholesaler__c) ;
                }
            }
        }
    }
}