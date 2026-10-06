/**
 * @author Feng Lian
 * @date 10/5/2023
 * @description Recalculate the planned visit count fields at the beginning of new quarter
 */
public with sharing class TPB_AccountCalculateVisitCountBatch implements Database.Batchable<sObject> {
    private Date startDate;
    private Date endDate;
    // Define the query
    private String query = 'SELECT Planned_Visit_Count__c FROM Account WHERE Id IN (' +
        'SELECT AccountId FROM Visit WHERE Status IN (\'Planned\',\'InProgress\') and ' +
        'PlannedVisitStartTime >= : startDate and PlannedVisitEndTime < : endDate)';

    /**
    * @description TPB_AccountCalculateVisitCountBatch constructor
    * @param  startDate    the start date of current fiscal quarter
    * @param  endDate    the start date of next fiscal quarter
    */
    public TPB_AccountCalculateVisitCountBatch(Date startDate, Date endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }
    /**
    * @description start description
    * @param   bc     description
    * @return  return description
    */
    public Database.QueryLocator start (Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description execute description
    * @param  bc           description
    * @param  lstAccount   description
    */
    public void execute (Database.BatchableContext bc, List<Account> lstAccount) {
        List<Account> updAccounts = new List<Account>();
        Map<Id, Integer> visitCountByAccount = new Map<Id, Integer>();

        // Query the aggregated visit count by account
        List<AggregateResult> results =
            [
                SELECT count(Id) visitCount, AccountId
                FROM Visit
                WHERE AccountId IN : lstAccount AND Status IN ('Planned','InProgress') AND PlannedVisitStartTime >= : startDate AND
                    PlannedVisitEndTime < : endDate
                GROUP BY AccountId
            ];

        for (AggregateResult result : results) {
            visitCountByAccount.put((Id)result.get('AccountId'), (Integer)result.get('visitCount'));
        }

        for (Account acc : lstAccount) {
            // Recalculate the planned visit count
            Integer visitCount = visitCountByAccount.get(acc.Id);

            if (visitCount == null) {
                visitCount = 0;
            }

            if (acc.Planned_Visit_Count__c != visitCount) {
                acc.Planned_Visit_Count__c = visitCount;
                updAccounts.add(acc);
            }
        }

        if (updAccounts.size() > 0) {
            update updAccounts;
        }
    }

    /**
    * @description finish description
    * @param  bc bc description
    */
    public void finish(Database.BatchableContext bc) {
        // Schedule next job
        List<String> lstString = String.valueOf(endDate).split('-');
        String strNextRunDate = '0 30 2 ';
        strNextRunDate +=
            Integer.valueOf(lstString[2]) +
            ' ' +
            Integer.valueOf(lstString[1]) +
            ' ? ' +
            lstString[0];
        String jobName = 'TPB_AccountResetVisitCountBatch Quarterly Job on ' + String.valueOf(endDate);
        List<CronTrigger> jobList = [SELECT CronJobDetail.Name FROM CronTrigger  where CronJobDetail.Name = : jobName];

        if (jobList.size() == 0) {
            System.schedule(jobName, strNextRunDate, new TPB_AccountResetVisitCountBatch());
        }
    }
}