public class CoverageStatusBatch implements Database.Batchable<sObject> {

    private Map<Id, List<Coverage_Period__c>> periodMap;

    public CoverageStatusBatch() {
        Map<Id, List<Coverage_Period__c>> periodMap = new Map<Id, List<Coverage_Period__c>>();

        for(Coverage_Plan__c plan : [SELECT Id, (SELECT Id, Start_Date__c, End_Date__c FROM Coverage_Periods__r WHERE Start_Date__c = THIS_YEAR) FROM Coverage_Plan__c]) {
            periodMap.put(plan.Id, plan.Coverage_Periods__r);
        }

        this.periodMap = periodMap;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Account WHERE Coverage_Plan__c != null]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> accountUpdates = new List<Account>();
        Date today = Date.today();

        // for(Account acc : [SELECT Id, Coverage_Plan__c, Coverage_Completed__c,
        //                   (SELECT Id, EndDate FROM WorkOrders WHERE EndDate = THIS_YEAR AND Status = 'Completed' AND Completed_Sales_Appointment__r.Call_Type__c = 'In-Store Visit')
        //                   FROM Account WHERE Id IN :scope]) {
        //     Date startDate;
        //     Date endDate;
        //     Boolean coverageCompleted = false;

        //     for(Coverage_Period__c periodo : this.periodMap.get(acc.Coverage_Plan__c)) {
        //         if(today >= period.Start_Date__c && today <= period.End_Date__c) {
        //             startDate = period.Start_Date__c;
        //             endDate = period.End_Date__c;
        //             break;
        //         }
        //     }

        //     if(startDate != null && endDate != null) {
        //         for(WorkOrder order : acc.WorkOrders) {
        //             //If work order was completed during the current period
        //             if(order.EndDate >= startDate && order.EndDate <= endDate) {
        //                 //Make sure it doesn't get set to No even if no DML
        //                 coverageCompleted = true;

        //                 if(acc.Coverage_Completed__c != 'Yes') {
        //                     acc.Coverage_Completed__c = 'Yes';
        //                     accountUpdates.add(acc);
        //                 }
        //             }
        //         }

        //         if(coverageCompleted != true && acc.Coverage_Completed__c != 'No') {
        //             acc.Coverage_Completed__c = 'No';
        //             accountUpdates.add(acc);
        //         }
        //     }
        // }

        Database.update(accountUpdates, false);
    }

    public void finish(Database.BatchableContext bc) {}

}