/**
* @author Feng Lian
* @date 6/25/2023
* @description assign org unit user as account team member
*/
public class TPB_AccountTeamBatch implements Database.Batchable<sObject>, Schedulable {
    private String query;
    
    /**
    * @description default constructor method
    */
    public TPB_AccountTeamBatch() {
        this.query = 'SELECT Id, cgcloud__User__c, cgcloud__Main__c, cgcloud__Org_Unit__c ' +
            ' from cgcloud__Org_Unit_User__c where cgcloud__User__r.IsActive = true order by cgcloud__Org_Unit__c';
    }
    
    /**
    * @description Constructor method
    * @param  query   statement
    */
    public TPB_AccountTeamBatch(String query) {
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
        List<AccountTeamMember> existingMgrs =
            [
                SELECT AccountId
                FROM AccountTeamMember
                WHERE UserId = : userId AND AccountId IN : accoundMap.keySet()
            ];
        
        accoundMap.clear();
        for (AccountTeamMember mgr : existingMgrs) {
            accoundMap.put(mgr.AccountId, mgr);
        }
        
        List<AccountTeamMember> customerMgrs = new List<AccountTeamMember>();
        
        for (cgcloud__Account_Org_Unit__c acc : accs) {
            if (accoundMap.get(acc.cgcloud__Account__c) == null) {                
                AccountTeamMember member = new AccountTeamMember();
                member.AccountId = acc.cgcloud__Account__c;
                member.UserId = userId;
                member.TeamMemberRole = 'Account Manager';
                member.AccountAccessLevel = 'Edit';
                customerMgrs.add(member);
            }
        }
        
        System.debug(customerMgrs);
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
        Database.executeBatch(new TPB_AccountTeamBatch(), 1);
    }
}