/**
 * @description One-time backfill batch that recalculates
 * Opportunity.TPB_Attached_File_Count__c for existing Opportunities, so the field
 * reflects Files already attached before TPB_OpportunityAttachmentCountHandler existed.
 * Run once after deployment: Database.executeBatch(new TPB_OpportunityFileCountBatch());
 *
 * @author Claude Code
 * @date 2026-07-27
 */
public without sharing class TPB_OpportunityFileCountBatch implements Database.Batchable<sObject> {
    /**
     * @description start description
     * @param bc description
     * @return QueryLocator over all Opportunities
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Opportunity]);
    }

    /**
     * @description execute description
     * @param bc description
     * @param lstOpportunity batch scope of Opportunities to recalculate
     */
    public void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunity) {
        TPB_OpportunityFileCountUtil.recalculateFileCounts(
            new Map<Id, Opportunity>(lstOpportunity).keySet()
        );
    }

    /**
     * @description finish description
     * @param bc description
     */
    public void finish(Database.BatchableContext bc) {
    }
}