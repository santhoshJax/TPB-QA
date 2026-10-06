/**
 * @description ContentDocumentLink trigger handler that keeps
 * Opportunity.TPB_Attached_File_Count__c current as Files are attached to or removed
 * from an Opportunity directly. Registered via SDF_TGF_Trigger_Config__mdt on
 * ContentDocumentLink (after insert / after delete).
 *
 * @author Claude Code
 * @date 2026-07-27
 */
public without sharing class TPB_OpportunityAttachmentCountHandler extends SDF_TGF_TriggerHandler {
    private static final String OPPORTUNITY_ID_PREFIX = '006';

    /**
     * @description after insert trigger handler
     */
    protected override void afterInsert() {
        recalculate((List<ContentDocumentLink>) Trigger.new);
    }

    /**
     * @description after delete trigger handler
     */
    protected override void afterDelete() {
        recalculate((List<ContentDocumentLink>) Trigger.old);
    }

    /*
     * @description Filters the ContentDocumentLink records down to the ones linked
     * directly to an Opportunity, then recalculates the file count on those Opportunities.
     */
    private void recalculate(List<ContentDocumentLink> lstLink) {
        Set<Id> setOpportunityIds = new Set<Id>();
        for (ContentDocumentLink objLink : lstLink) {
            String strLinkedEntityId = objLink.LinkedEntityId;
            if (strLinkedEntityId.startsWith(OPPORTUNITY_ID_PREFIX)) {
                setOpportunityIds.add(objLink.LinkedEntityId);
            }
        }
        TPB_OpportunityFileCountUtil.recalculateFileCounts(setOpportunityIds);
    }
}