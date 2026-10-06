/**
 * @description Shared logic to keep Opportunity.TPB_Attached_File_Count__c in sync with
 * the number of Files (ContentDocumentLink) attached directly to the Opportunity. Always
 * fully recomputes from ContentDocumentLink (rather than incrementing/decrementing) so
 * bulk multi-file adds/removes on the same Opportunity stay accurate.
 * Used by TPB_OpportunityAttachmentCountHandler (real-time) and
 * TPB_OpportunityFileCountBatch (backfill).
 *
 * @author Claude Code
 * @date 2026-07-27
 */
public without sharing class TPB_OpportunityFileCountUtil {
    /**
     * @description Recalculates and updates TPB_Attached_File_Count__c for the given
     * Opportunity Ids based on their current ContentDocumentLink records.
     * @param setOpportunityIds Opportunity Ids to recalculate.
     */
    public static void recalculateFileCounts(Set<Id> setOpportunityIds) {
        if (setOpportunityIds == null || setOpportunityIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> mapCountByOpportunityId = new Map<Id, Integer>();
        for (Id oppId : setOpportunityIds) {
            mapCountByOpportunityId.put(oppId, 0);
        }

        for (AggregateResult objResult : [
            SELECT LinkedEntityId oppId, COUNT(Id) fileCount
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :setOpportunityIds
            GROUP BY LinkedEntityId
        ]) {
            mapCountByOpportunityId.put(
                (Id) objResult.get('oppId'),
                (Integer) objResult.get('fileCount')
            );
        }

        List<Opportunity> lstOppToUpdate = new List<Opportunity>();
        for (Opportunity objOpp : [
            SELECT Id, TPB_Attached_File_Count__c
            FROM Opportunity
            WHERE Id IN :setOpportunityIds
        ]) {
            Integer newCount = mapCountByOpportunityId.get(objOpp.Id);
            if (objOpp.TPB_Attached_File_Count__c != newCount) {
                objOpp.TPB_Attached_File_Count__c = newCount;
                lstOppToUpdate.add(objOpp);
            }
        }

        if (!lstOppToUpdate.isEmpty()) {
            update lstOppToUpdate;
        }
    }
}