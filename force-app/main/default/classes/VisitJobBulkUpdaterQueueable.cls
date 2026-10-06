public class VisitJobBulkUpdaterQueueable implements Queueable, Database.AllowsCallouts {
@testVisible
    public static Boolean doChainJob = true; 
    
    private List<Id> visitJobIds;

    public VisitJobBulkUpdaterQueueable(List<Id> visitJobIds) {
        this.visitJobIds = visitJobIds;
    }

    public void execute(QueueableContext context) {
        Integer chunkSize = 1000;
        List<Id> currentBatch = new List<Id>();
        List<Id> remaining = new List<Id>();

        // Split into current chunk and remaining
        for (Integer i = 0; i < visitJobIds.size(); i++) {
            if (i < chunkSize) {
                currentBatch.add(visitJobIds[i]);
            } else {
                remaining.add(visitJobIds[i]);
            }
        }

        if (!currentBatch.isEmpty()) {
            List<cgcloud__Visit_Job__c> jobsToUpdate = [
                SELECT Id, ToBeArchived__c
                FROM cgcloud__Visit_Job__c
                WHERE Id IN :currentBatch AND ToBeArchived__c = false
            ];

            for (cgcloud__Visit_Job__c job : jobsToUpdate) {
                job.ToBeArchived__c = true;
            }

            if (!jobsToUpdate.isEmpty()) {
                update jobsToUpdate;
            }
        }

        // Chain next queueable if records remain
        if (!remaining.isEmpty() && doChainJob) {
            System.enqueueJob(new VisitJobBulkUpdaterQueueable(remaining));
        }
    }
}