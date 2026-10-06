/**
* @author Feng Lian
* @date 6/25/2023
* @description assign org unit user as customer manager
*/
public class TPB_AccountManagerBatch implements Database.Batchable<sObject>, Schedulable {
    private String query;
    
    /**
    * @description default constructor method
    */
    public TPB_AccountManagerBatch() {
        this.query = 'SELECT Id, cgcloud__User__c, cgcloud__Main__c, cgcloud__Org_Unit__c ' +
            ' from cgcloud__Org_Unit_User__c where cgcloud__User__r.IsActive = true order by cgcloud__Org_Unit__c';
    }
    
    /**
    * @description Constructor method
    * @param  query   statement
    */
    public TPB_AccountManagerBatch(String query) {
        this.query = query;
    }
    
    /**
    * @description start description
    * @param  bc bc description
    * @return    return description
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description execute description
    * @param  bc description
    * @param  items  description
    */
    public void execute(Database.BatchableContext bc, List<sObject> items) {
        cgcloud__Org_Unit_User__c orgUser = ((List<cgcloud__Org_Unit_User__c>)items)[0];
        String userId = orgUser.cgcloud__User__c;
        String orgUnit = orgUser.cgcloud__Org_Unit__c;
        Boolean isMain = orgUser.cgcloud__Main__c;
        
        List<cgcloud__Account_Org_Unit__c> accs =
            [
                SELECT cgcloud__Account__c
                FROM cgcloud__Account_Org_Unit__c
                WHERE cgcloud__Org_Unit__c  = : orgUnit
            ];
        Map<Id, sObject> accoundMap = new Map<Id, sObject>();
        
        for (cgcloud__Account_Org_Unit__c acc : accs) {
            accoundMap.put(acc.cgcloud__Account__c, acc);
        }
        List<cgcloud__Account_Manager__c> existingMgrs =
            [
                SELECT cgcloud__Account__c, cgcloud__Active__c
                FROM cgcloud__Account_Manager__c
                WHERE cgcloud__User__c = : userId AND cgcloud__Account__c IN : accoundMap.keySet()
            ];
        
        accoundMap.clear();
        for (cgcloud__Account_Manager__c mgr : existingMgrs) {
            accoundMap.put(mgr.cgcloud__Account__c, mgr);
        }
        
        List<cgcloud__Account_Manager__c> customerMgrs = new List<cgcloud__Account_Manager__c>();
        
        for (cgcloud__Account_Org_Unit__c acc : accs) {
            if (accoundMap.get(acc.cgcloud__Account__c) == null) {
                cgcloud__Account_Manager__c otm = new cgcloud__Account_Manager__c();
                otm.cgcloud__Account__c = acc.cgcloud__Account__c;
                otm.cgcloud__User__c = userId;
                otm.cgcloud__Management_Type__c = 'Sales';
                otm.cgcloud__Org_Unit__c = orgUnit;
                otm.cgcloud__Active__c = true;
                otm.cgcloud__Valid_From__c = Date.today().addDays(-30);
                otm.cgcloud__Valid_Thru__c = Date.today().addYears(10);
                otm.cgcloud__Main__c = isMain;
                customerMgrs.add(otm);
            }
        }

        if (customerMgrs.size() > 0) {
            insert customerMgrs;
        }
    }
    
    /**
    * @description finish description
    * @param  bc bc description
    */
    public void finish(Database.BatchableContext bc) {
        
    }
    
    /**
    * @description execute description
    * @param  sc sc description
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TPB_AccountManagerBatch(), 1);
    }
}