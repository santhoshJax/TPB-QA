global class VisitJobDeleteBatch implements Database.Batchable<SObject>, Database.Stateful {
public string query = system.label.VisitJobDeleteBatch_Query; 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query)  ;
            }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<cgcloud__Visit_Job__c> jobsToDelete = (List<cgcloud__Visit_Job__c>) scope;
        if (!jobsToDelete.isEmpty()) {
            delete jobsToDelete;
            Database.emptyRecycleBin(jobsToDelete);  
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finished deleting Visit_Job__c records marked for archive.');
    }
}