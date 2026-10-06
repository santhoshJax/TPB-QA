/**************************************************************************************
Apex Class Name : TPB_ContentDocumentLinkBatch
Version         : 1.0
Created Date    : 2026-03-05
Function        : Batch class to insert ContentDocumentLink records asynchronously.
                  Called from TPB_AccountAttachmentHandler to avoid governor limits
                  when sharing HQ files to thousands of child Retailer accounts.
Test Class      : TPB_ContentDocumentLinkBatchTest
Modification Log:
-----------------------------------------------------------------------------
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* [Developer]            2026-03-05           Original Version
*************************************************************************************/
public class TPB_ContentDocumentLinkBatch implements Database.Batchable<ContentDocumentLink>, Database.Stateful {

    private List<ContentDocumentLink> linksToInsert;
    private Integer successCount = 0;
    private Integer failCount = 0;

    public TPB_ContentDocumentLinkBatch(List<ContentDocumentLink> linksToInsert) {
        this.linksToInsert = linksToInsert;
    }

    public Iterable<ContentDocumentLink> start(Database.BatchableContext bc) {
        return this.linksToInsert;
    }

    public void execute(Database.BatchableContext bc, List<ContentDocumentLink> scope) {
        TPB_AccountAttachmentHandler.isBatchProcessing = true;

        try {
            Database.SaveResult[] results = Database.insert(scope, false);
            List<SDF_LGR_Log__c> chunkLogs = new List<SDF_LGR_Log__c>();
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successCount++;
                } else {
                    failCount++;
                    for (Database.Error err : results[i].getErrors()) {
                        String errorMsg = 'ContentDocumentId: ' + scope[i].ContentDocumentId
                            + ' | LinkedEntityId: ' + scope[i].LinkedEntityId
                            + ' | Error: ' + err.getStatusCode() + ' - ' + err.getMessage();
                        System.debug(LoggingLevel.ERROR,
                            'TPB_ContentDocumentLinkBatch insert error: ' + errorMsg);
                        chunkLogs.add(new SDF_LGR_Log__c(
                            Level__c     = 'ERROR',
                            Class__c     = 'TPB_ContentDocumentLinkBatch',
                            Message__c   = errorMsg,
                            Reference__c = bc.getJobId()
                        ));
                    }
                }
            }
            if (!chunkLogs.isEmpty()) {
                insert chunkLogs;
            }
        } finally {
            TPB_AccountAttachmentHandler.isBatchProcessing = false;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'TPB_ContentDocumentLinkBatch completed. Success: ' + successCount + ' | Failed: ' + failCount);
        if (failCount > 0) {
            System.debug(LoggingLevel.ERROR,
                'TPB_ContentDocumentLinkBatch finished with failures. See SDF_LGR_Log__c for details.');
        }
    }
}