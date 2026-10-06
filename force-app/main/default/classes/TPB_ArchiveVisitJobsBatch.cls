public class TPB_ArchiveVisitJobsBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Start with querying all accounts that have more than one visit
        Date startDate = System.today().addMonths(-7);
        Date endDate = System.today().addMonths(-6);
        String sQuery='SELECT Id FROM Account WHERE Id IN (SELECT accountId FROM Visit WHERE ActualVisitEndTime >= :startDate AND ActualVisitEndTime <= :endDate)';
        System.debug('TPB_ArchiveVisitJobsBatch Query: ' + sQuery);
        return Database.getQueryLocator(sQuery);
    }

    public void execute(Database.BatchableContext bc, List<Account> accountList) {
        Map<Id, Visit> latestVisitMap = new Map<Id, Visit>();
        List<Visit> visits = [SELECT Id, ActualVisitEndTime , accountId 
                                 FROM Visit 
                                 WHERE accountId IN :accountList
                                 ORDER BY ActualVisitEndTime     DESC];

        // Identify latest Visit per Account
        for (Visit visit : visits) {
            if (!latestVisitMap.containsKey(visit.accountId)) {
                latestVisitMap.put(visit.accountId, visit);
            }
        }

        // Fetch all Visit Jobs for these visits
        List<cgcloud__Visit_Job__c> jobsToUpdate = new List<cgcloud__Visit_Job__c>();
        List<cgcloud__Visit_Job__c> visitJobs = [
            SELECT Id, cgcloud__Visit__c, ToBeArchived__c, cgcloud__Visit__r.accountId
            FROM cgcloud__Visit_Job__c 
            WHERE cgcloud__Visit__r.accountId IN :accountList
        ];

        for (cgcloud__Visit_Job__c job : visitJobs) {
            Visit latestVisit = latestVisitMap.get(job.cgcloud__Visit__r.accountId);
            if (latestVisit != null && job.cgcloud__Visit__c != latestVisit.Id) {
                job.ToBeArchived__c = true;
                jobsToUpdate.add(job);
            }
        }

        if (!jobsToUpdate.isEmpty() && jobsToUpdate.size()<=1000) {
            update jobsToUpdate;
        }
        if(jobsToUpdate.size()>2000){
            list<id> vjIds = new list<id>();
            for(cgcloud__Visit_Job__c j : jobsToUpdate){
                vjIds.add(j.id);
        }
        System.enqueueJob(new VisitJobBulkUpdaterQueueable(vjIds));
        }
        
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: logging or notifications
    }
}