/**
 * TPB_AccountManagerCleanupBatchTest
 * @author Feng Lian
 * @date 2023-06-28
 * @description TPB_AccountManagerCleanupBatch test class
 */
@IsTest
public class TPB_AccountManagerCleanupBatchTest {
    @testSetup
    static void setup() {
        //create Account for test.
        Account accObj = TPB_TestFactory.createAccount();
        
        //create Org Unit data for test.
        List<cgcloud__Org_Unit__c> lstOrgUnit = new List<cgcloud__Org_Unit__c>();
        cgcloud__Org_Unit__c objOrgUnitRegion = new cgcloud__Org_Unit__c();
        objOrgUnitRegion.cgcloud__Org_Level__c = 'SalesRep';
        objOrgUnitRegion.cgcloud__Org_Type__c = 'Sales';
        objOrgUnitRegion.cgcloud__Sales_Org__c = '0001';
        objOrgUnitRegion.Org_Unit_Main__c = true;
        objOrgUnitRegion.Name = 'Region 09';
        lstOrgUnit.add(objOrgUnitRegion);
        
        //create Org Unit data for test.
        cgcloud__Org_Unit__c objOrgUnit = new cgcloud__Org_Unit__c();
        objOrgUnit.cgcloud__Org_Level__c = 'SalesRep';
        objOrgUnit.cgcloud__Org_Type__c = 'Sales';
        objOrgUnit.cgcloud__Sales_Org__c = '0001';
        objOrgUnit.Org_Unit_Main__c = true;
        objOrgUnit.Name = '109A17T';
        lstOrgUnit.add(objOrgUnit);
        insert lstOrgUnit;
        
        //create Org Unit Hierarchy data for test.
        cgcloud__Org_Unit_Hierarchy__c objHierarchy = new cgcloud__Org_Unit_Hierarchy__c();
        objHierarchy.cgcloud__Child_Org_Unit__c = objOrgUnit.Id;
        objHierarchy.cgcloud__Parent_Org_Unit__c = objOrgUnitRegion.Id;
        objHierarchy.cgcloud__Valid_From__c = Date.newInstance(2023, 1, 1);
        objHierarchy.cgcloud__Valid_Thru__c = Date.newInstance(2099, 12, 31);
        insert objHierarchy;
        
        //create Org Unit Mapping data for test.
        TPB_Org_Unit_Mapping__c objOrgUnitMap = new TPB_Org_Unit_Mapping__c();
        objOrgUnitMap.TPB_Org_Unit__c = objOrgUnit.Id;
        objOrgUnitMap.TPB_Zip_Code__c = '20001';
        objOrgUnitMap.TPB_State_Abbrev__c = 'MT';
        objOrgUnitMap.TPB_State_Name__c = 'Montana';
        insert objOrgUnitMap;
        
        //create Org Unit User data for test.
        cgcloud__Org_Unit_User__c objOrgUnitUser = new cgcloud__Org_Unit_User__c();
        objOrgUnitUser.cgcloud__User__c = TPB_TestFactory.createTSM().Id;
        objOrgUnitUser.cgcloud__Org_Unit__c = objOrgUnit.Id;
        insert objOrgUnitUser;
        
        //create Account Org Unit  data for test.
        List<cgcloud__Account_Org_Unit__c> lstAccountOrgUnit = new List<cgcloud__Account_Org_Unit__c>();
        cgcloud__Account_Org_Unit__c objAccountOrgUnit = new cgcloud__Account_Org_Unit__c();
        objAccountOrgUnit.cgcloud__Active__c = true;
        objAccountOrgUnit.cgcloud__Account__c = accObj.Id;
        objAccountOrgUnit.cgcloud__Org_Unit__c = objOrgUnit.Id;
        objAccountOrgUnit.cgcloud__Valid_From__c = Date.newInstance(2023, 1, 1);
        objAccountOrgUnit.cgcloud__Valid_Thru__c = Date.newInstance(2099, 12, 31);
        lstAccountOrgUnit.add(objAccountOrgUnit);
        
        // insert data
        insert lstAccountOrgUnit;
        
        cgcloud__Account_Manager__c accMgr = new cgcloud__Account_Manager__c();
        accMgr.cgcloud__Account__c = accObj.Id;
        accMgr.cgcloud__User__c = objOrgUnitUser.cgcloud__User__c;
        accMgr.cgcloud__Management_Type__c = 'Sales';
        accMgr.cgcloud__Org_Unit__c = objOrgUnit.Id;
        accMgr.cgcloud__Active__c = true;
        accMgr.cgcloud__Valid_From__c = Date.today();
        accMgr.cgcloud__Valid_Thru__c = Date.today().addYears(10);
        insert accMgr;
        
        accMgr.Id = null;
        accMgr.cgcloud__User__c = UserInfo.getUserId();
        insert accMgr;
        
        AccountTeamMember member = new AccountTeamMember();
        member.AccountId = accObj.Id;
        member.UserId = objOrgUnitUser.cgcloud__User__c;
        member.TeamMemberRole = 'Account Manager';
        member.AccountAccessLevel = 'Edit';
        insert member;
        
        member.Id = null;
        member.UserId = UserInfo.getUserId();
        insert member;
    }
    
    @isTest
    static void testBatch() {
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id FROM Account WHERE cgcloud__Account_Template__c != null]);
        System.Test.startTest();
        TPB_AccountManagerCleanupBatch batchJob = new TPB_AccountManagerCleanupBatch(accounts.keySet());
        batchJob.execute(null);
        System.Test.stopTest();
        
        List<cgcloud__Account_Manager__c> existingMgrs =
            [
                SELECT cgcloud__Account__c, cgcloud__Active__c
                FROM cgcloud__Account_Manager__c
                WHERE cgcloud__User__r.IsActive = true
            ];
        List<AccountTeamMember> existingAccTeams =
            [
                SELECT UserId, AccountId
                FROM AccountTeamMember
                WHERE UserId <> null
            ];
        System.assertEquals(1, existingMgrs.size(), false);
        System.assertEquals(1, existingAccTeams.size(), false);
    }
    
    @isTest
    static void testBatchTwo() {
        System.Test.startTest();
        TPB_AccountManagerCleanupBatch batchJob = new TPB_AccountManagerCleanupBatch();
        Database.executeBatch(batchJob);
        System.Test.stopTest();
        
        List<cgcloud__Account_Manager__c> existingMgrs =
            [
                SELECT cgcloud__Account__c, cgcloud__Active__c
                FROM cgcloud__Account_Manager__c
                WHERE cgcloud__User__r.IsActive = true
            ];
        List<AccountTeamMember> existingAccTeams =
            [
                SELECT UserId, AccountId
                FROM AccountTeamMember
                WHERE UserId <> null
            ];
        System.assertEquals(1, existingMgrs.size(), false);
        System.assertEquals(1, existingAccTeams.size(), false);
    }
}