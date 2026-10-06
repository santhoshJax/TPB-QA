/**
 * @author Feng Lian
 * @date 10/5/2023
 * @description Reset the visit count fields at the beginning of new quarter
 */
public with sharing class TPB_AccountResetVisitCountBatch implements Database.Batchable<sObject>, Schedulable {
    // Define the query
    private String query = 'SELECT Planned_Visit_Count__c, Completed_Visit_Count__c FROM Account WHERE Planned_Visit_Count__c > 0 OR Completed_Visit_Count__c > 0';

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
        for (Account acc : lstAccount) {
            acc.Completed_Visit_Count__c = 0;
            acc.Planned_Visit_Count__c = 0;
        }
        
        update lstAccount;
    }
    
    /**
    * @description getPeriod Query the start date and end date of current quarter
    * @return Period the current fiscal quarter
    */
    private Period getPeriod() {
        Period result;
        
        // Query the start date and end date of current quarter
        List<Period> lstPeriod = [
            SELECT StartDate, EndDate
            FROM Period
            WHERE Type = 'Quarter' AND StartDate <= TODAY AND EndDate >= TODAY
            ORDER BY StartDate DESC
            LIMIT 1
        ];
        
        if (lstPeriod.size() > 0) {
            result = lstPeriod[0];
        }
        
        return result;
    }
    
    /**
   * @description finish description
   * @param  bc bc description
   */
    public void finish(Database.BatchableContext bc) {
        // Query the start date and end date of current quarter
        Period curQuarter = getPeriod();
        
        // Determine the next run date, which is the next day after current quarter ends
        if (curQuarter != null) {
            Database.executeBatch(new TPB_AccountCalculateVisitCountBatch(curQuarter.StartDate, curQuarter.EndDate.addDays(1)), 200);
        }
    }
    
    /**
   * @description execute description
   * @param  sc sc description
   */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TPB_AccountResetVisitCountBatch(), 200);
    }
}