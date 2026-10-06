/**
* @author Feng Lian
* @date 6/28/2023
* @description cleanup customer manager and account team member based on org unit user
*/
public class TPB_AccountManagerCleanupBatch implements Database.Batchable<sObject>, Schedulable {
    private String query;
    private Set<Id> accountIds;
    
    /**
    * @description default constructor method
    */
    public TPB_AccountManagerCleanupBatch() {
        this.query = 'SELECT Id from Account where cgcloud__Account_Template__c != null';
    }
    
    /**
    * @description Constructor method
    * @param  query   statement
    */
    public TPB_AccountManagerCleanupBatch(Set<Id> accountIds) {
        this.accountIds = accountIds;
        this.query = 'SELECT Id from Account where Id IN : accountIds';
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
        Map<Id, cgcloud__Account_Org_Unit__c> accOrgUnitMap = new Map<Id, cgcloud__Account_Org_Unit__c>();
        Map<Id, Set<Id>> orgUnitUserMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> accountOrgUsers = new Map<Id, Set<Id>>();
        Map<Id, cgcloud__Account_Manager__c> accountMgrs = new Map<Id, cgcloud__Account_Manager__c>();
        Map<Id, AccountTeamMember> accTeams = new Map<Id, AccountTeamMember>();
        List<SObject> deletedList = new List<SObject>();
        
        List<cgcloud__Account_Org_Unit__c> orgUnits =
            [
                SELECT cgcloud__Account__c, cgcloud__Org_Unit__c
                FROM cgcloud__Account_Org_Unit__c
                WHERE cgcloud__Account__c IN : items AND cgcloud__Active__c = true AND
                    (cgcloud__Valid_From__c = null OR cgcloud__Valid_From__c <= TODAY) AND
                    (cgcloud__Valid_Thru__c = null OR cgcloud__Valid_Thru__c >= TODAY)
            ];
        for (cgcloud__Account_Org_Unit__c item : orgUnits) {
            accOrgUnitMap.put(item.cgcloud__Org_Unit__c, item);
        }

        List<cgcloud__Org_Unit_User__c> orgUsers =
            [
                SELECT cgcloud__User__c, cgcloud__Main__c, cgcloud__Org_Unit__c
                FROM cgcloud__Org_Unit_User__c
                WHERE cgcloud__User__r.IsActive = true AND cgcloud__Org_Unit__c IN : accOrgUnitMap.keySet() AND
                    (cgcloud__Valid_From__c = null OR cgcloud__Valid_From__c <= TODAY) AND
                    (cgcloud__Valid_Thru__c = null OR cgcloud__Valid_Thru__c >= TODAY)
                ORDER BY cgcloud__Org_Unit__c
            ];
        
        for (cgcloud__Org_Unit_User__c item : orgUsers) {
            cgcloud__Account_Org_Unit__c orgUnit = accOrgUnitMap.get(item.cgcloud__Org_Unit__c);
            Set<Id> userSet = orgUnitUserMap.get(orgUnit.cgcloud__Account__c);
            
            if (userSet == null) {
                userSet = new Set<Id>();
                orgUnitUserMap.put(orgUnit.cgcloud__Account__c, userSet);
            }
            
            userSet.add(item.cgcloud__User__c);
        }
        
        List<cgcloud__Account_Manager__c> existingMgrs =
            [
                SELECT cgcloud__Account__c, cgcloud__User__c, cgcloud__Active__c, cgcloud__Valid_From__c, cgcloud__Valid_Thru__c
                FROM cgcloud__Account_Manager__c
                WHERE cgcloud__Account__c IN : items
            ];
        
        for (cgcloud__Account_Manager__c item : existingMgrs) {
            Set<Id> userSet = orgUnitUserMap.get(item.cgcloud__Account__c);
            
            if (!userSet.contains(item.cgcloud__User__c) || !item.cgcloud__Active__c || item.cgcloud__Valid_From__c > Date.today() || item.cgcloud__Valid_Thru__c < Date.today()) {
                deletedList.add(item);
            }
        }
        
        List<AccountTeamMember> existingAccTeams =
            [
                SELECT UserId, AccountId
                FROM AccountTeamMember
                WHERE AccountId IN : items
            ];
        
        for (AccountTeamMember item : existingAccTeams) {
            Set<Id> userSet = orgUnitUserMap.get(item.AccountId);
            
            if (!userSet.contains(item.UserId)) {
                deletedList.add(item);
            }
        }
        
        if (deletedList.size() > 0) {
            delete deletedList;
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
        Database.executeBatch(new TPB_AccountManagerCleanupBatch(), 500);
    }
}