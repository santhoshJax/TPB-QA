/**
 * @author Mi Li
 * @date 9/25/2023
 * @description CON0001729-1641: "Chain Account Overview" Widget in Store Cockpit
 */
public without sharing class TPB_HQAccContentDocumentLinkHandler extends SDF_TGF_TriggerHandler {
  //Account Id Prefix
  private static final String ACCOUNT_ID_PREFIX = '001';

  /**
   * @description after insert trigger handler
   */
  protected override void afterInsert() {
    //when insert document, the link on hq account is updated
    List<ContentDocumentLink> lstLink = (List<ContentDocumentLink>) Trigger.new;
    Map<String, String> mapDocIds = new Map<String, String>();
    for (ContentDocumentLink objLink : lstLink) {
      String linkedEntityId = objLink.LinkedEntityId;
      //AccountId, DocId
      if (linkedEntityId.startsWith(ACCOUNT_ID_PREFIX)) {
        mapDocIds.put(objLink.LinkedEntityId, objLink.ContentDocumentId);
      }
    }

    //Process data
    if (mapDocIds.size() > 0) {
      processData(mapDocIds);
    }
  }

  /*
   * @description process data
   * @param map of account id, doc id
   */
  private void processData(Map<String, String> mapDocIds) {
    //Execute logic only when HQ Account uploads files
    List<Account> lstAcc = [
      SELECT Id
      FROM Account
      WHERE RecordType.Name = 'Headquarter' AND Id IN :mapDocIds.keySet()
    ];
    Set<String> setContentDocumentId = new Set<String>();
    if (lstAcc.size() > 0) {
      for (Account objAcc : lstAcc) {
        setContentDocumentId.add(mapDocIds.get(objAcc.Id));
      }
      //query ContentVersion data
      List<ContentVersion> lstUpdateContentVersion = [
        SELECT Id, TPB_IsHQAttachment__c
        FROM ContentVersion
        WHERE
          ContentDocumentId IN :setContentDocumentId
          AND IsLatest = TRUE
          AND TPB_IsHQAttachment__c = FALSE
      ];
      for (ContentVersion obj : lstUpdateContentVersion) {
        obj.TPB_IsHQAttachment__c = true;
      }

      //update data
      if (lstUpdateContentVersion.size() > 0) {
        update lstUpdateContentVersion;
      }
    }
  }
}