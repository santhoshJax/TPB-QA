/**
 * @description ContentDocument trigger handler that keeps
 * Opportunity.TPB_Attached_File_Count__c current when a File is deleted entirely
 * (not just unlinked from the Opportunity). Deleting a ContentDocument
 * cascade-deletes its ContentDocumentLink rows without firing ContentDocumentLink
 * triggers, so the affected Opportunity Ids are captured in beforeDelete (while the
 * links still exist) and the recalculation runs in afterDelete (once the cascade
 * delete of the links has completed).
 * Registered via SDF_TGF_Trigger_Config__mdt on ContentDocument (before delete / after delete).
 *
 * @author Claude Code
 * @date 2026-07-27
 */
public without sharing class TPB_OpportunityFileDocDeleteHandler extends SDF_TGF_TriggerHandler {
    private static final String OPPORTUNITY_ID_PREFIX = '006';

    @TestVisible
    private static Set<Id> setPendingOpportunityIds;

    /**
     * @description before delete trigger handler - capture linked Opportunities
     * before the ContentDocumentLink rows are cascade-deleted.
     */
    protected override void beforeDelete() {
        Set<Id> setDocumentIds = new Map<Id, ContentDocument>(
            (List<ContentDocument>) Trigger.old
        ).keySet();
        setPendingOpportunityIds = collectLinkedOpportunityIds(setDocumentIds);
    }

    /**
     * @description after delete trigger handler - recalculate once the cascade
     * delete of the ContentDocumentLink rows has completed.
     */
    protected override void afterDelete() {
        TPB_OpportunityFileCountUtil.recalculateFileCounts(setPendingOpportunityIds);
        setPendingOpportunityIds = null;
    }

    private Set<Id> collectLinkedOpportunityIds(Set<Id> setDocumentIds) {
        Set<Id> setOpportunityIds = new Set<Id>();
        for (ContentDocumentLink objLink : [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :setDocumentIds
        ]) {
            String strLinkedEntityId = objLink.LinkedEntityId;
            if (strLinkedEntityId.startsWith(OPPORTUNITY_ID_PREFIX)) {
                setOpportunityIds.add(objLink.LinkedEntityId);
            }
        }
        return setOpportunityIds;
    }
}