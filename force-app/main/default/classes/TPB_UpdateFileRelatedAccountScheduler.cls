/**
 * @author Jie Yu
 * @date 9/14/2023
 * @description TPB_UpdateFileRelatedAccountBatch:   Performed at 2:30 a.m. daily.
 * system.schedule('TPB_UpdateFileRelatedAccountBatch', '0 30 2 * * ?', new TPB_UpdateFileRelatedAccountScheduler());
 */
public with sharing class TPB_UpdateFileRelatedAccountScheduler implements Schedulable {
    // run Test Class
    public Boolean isRunTest = false;
    /**
     * @description execute description
     * @param  sc        SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        List<ContentDocumentLink> lstLink = [ SELECT ID, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT ID FROM ACCOUNT WHERE RecordType.Name = 'Wholesaler') AND SystemModstamp = TODAY ];
        Set<Id> setDocId = new Set<Id>();
        for(ContentDocumentLink objLink : lstLink){
            setDocId.add(objLink.ContentDocumentId);
        }
        List<ContentVersion> lstVer = [ SELECT ContentDocumentId, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :setDocId order by CreatedDate asc];
        Map<Id, DateTime> mapDocDate = new Map<Id, DateTime>();
        for(ContentVersion objVer : lstVer) {
            mapDocDate.put(objVer.ContentDocumentId, objVer.CreatedDate);
        }
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
        Database.executeBatch(new TPB_UpdateFileRelatedAccountBatch(mapAccDoc), 2000);
    }
}