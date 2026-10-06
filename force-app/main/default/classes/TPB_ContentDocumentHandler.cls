/**
 * @description TPB_ContentDocumentHandler
 *
 * @author Jie Yu
 * @date 2023-07-19
 *
 */
public without sharing class TPB_ContentDocumentHandler extends SDF_TGF_TriggerHandler {
    /**
     * @description after delete trigger handler
     */
    protected override void afterDelete() {
        List<ContentDocument> lstDoc = (List<ContentDocument>) Trigger.old;
        Set<Id> setDocId = new Set<Id>();
        for (ContentDocument objDoc : lstDoc) {
            setDocId.add(objDoc.Id);
        }
        //Process delete data
        if(setDocId!=null && setDocId.size()>0){
            processData(setDocId);
        }
    }
    /*
    * @description process deleted data
    */
    private void processData(Set<Id> setDocId) {
        //If file is deleted, remove the link on Related Account
        List<Related_Account__c> lstRA = [ SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c FROM Related_Account__c WHERE TPB_Wholesaler_File__c IN :setDocId ];
        for(Related_Account__c objRA : lstRA){
            objRA.TPB_Wholesaler_File__c = null ;
        }
        //Update list
        update lstRA;
    }
}