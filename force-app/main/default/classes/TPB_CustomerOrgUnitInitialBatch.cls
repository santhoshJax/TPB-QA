/**
 * @author Guanshu Wang
 * @date 2023-03-02
 * @description Assign Account to org unit
 */
public with sharing class TPB_CustomerOrgUnitInitialBatch implements Database.Batchable<sObject> {
    String queryStr;
    /**
     * @description TPB_CustomerOrgUnitInitialBatch description
     * @author Guanshu Wnag
     */
    public TPB_CustomerOrgUnitInitialBatch() {
        // Initial Query String
        this.queryStr = 'SELECT ID,ShippingPostalCode,ShippingState,OwnerId,TPB_Org_Unit_Flag__c FROM Account WHERE cgcloud__Sales_Org__c = \'0001\' AND TPB_Org_Unit_Flag__c = false';
    }
    /**
     * @description TPB_CustomerOrgUnitInitialBatch description
     * @author Guanshu Wang
     * @param  queryStr queryStr
     */
    public TPB_CustomerOrgUnitInitialBatch(String queryStr) {
        this.queryStr = queryStr;
    }
    /**
     * @description start Batch
     * @author Guanshu Wang
     * @param  bc bc description
     * @return    return description
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(queryStr);
    }
    /**
     * @description Get Account Id Map to Customer Org Unit
     * @author Guanshu Wang
     * @param  listAccountId Account id list
     * @return               Map
     */
    public Map<Id, cgcloud__Account_Org_Unit__c> getAccountIdToCustomerOrgUnitMap(
        List<Id> listAccountId
    ) {
        List<cgcloud__Account_Org_Unit__c> listCustomerOrgUnit = [
            SELECT cgcloud__Account__c, cgcloud__Org_Unit__c
            FROM cgcloud__Account_Org_Unit__c
            WHERE cgcloud__Account__c = :listAccountId
        ];
        Map<Id, cgcloud__Account_Org_Unit__c> mapAccountIdToCustomerOrgUnit = new Map<Id, cgcloud__Account_Org_Unit__c>();
        for (
            cgcloud__Account_Org_Unit__c itemCustomerOrgUnit : listCustomerOrgUnit
        ) {
            mapAccountIdToCustomerOrgUnit.put(
                itemCustomerOrgUnit.cgcloud__Account__c,
                itemCustomerOrgUnit
            );
        }
        return mapAccountIdToCustomerOrgUnit;
    }
    /**
     * @description Get Org Unit To User Map
     * @author Guanshu Wang
     * @param  listOrgUnit Org Unit Lit
     * @return             User Id to Org Unit User Map
     */
    public Map<Id, cgcloud__Org_Unit_User__c> getOrgUnitToUserMap(
        List<String> listOrgUnit
    ) {
        List<cgcloud__Org_Unit_User__c> listOrgUnitUser = [
            SELECT cgcloud__Org_Unit__c, cgcloud__User__c
            FROM cgcloud__Org_Unit_User__c
            WHERE cgcloud__Org_Unit__c = :listOrgUnit
        ];
        Map<Id, cgcloud__Org_Unit_User__c> mapOrgUnitToUser = new Map<Id, cgcloud__Org_Unit_User__c>();
        for (cgcloud__Org_Unit_User__c itemOrgUnitUser : listOrgUnitUser) {
            mapOrgUnitToUser.put(
                itemOrgUnitUser.cgcloud__Org_Unit__c,
                itemOrgUnitUser
            );
        }
        return mapOrgUnitToUser;
    }
    /**
     * @description Get Account ID List
     * @author Guanshu Wang
     * @param  listAccount Account List
     * @param  listAccountZipCode Account Zip Code List
     * @return             Id List
     */
    public List<Id> getAccountIdLIst(
        List<Account> listAccount,
        List<String> listAccountZipCode
    ) {
        List<Id> listAccountId = new List<Id>();
        for (Account itemAccount : listAccount) {
            listAccountZipCode.add(itemAccount.ShippingPostalCode);
            listAccountId.add(itemAccount.Id);
        }
        return listAccountId;
    }
    /**
     * @description execute Batch
     * @author Guanshu Wnag
     * @param  bc          bc description
     * @param  listAccount Account In 0001
     */
    public void execute(
        Database.BatchableContext bc,
        List<Account> listAccount
    ) {
        // Get Account ZipCode List
        List<String> listAccountZipCode = new List<String>();
        // Get Account Id List
        List<Id> listAccountId = getAccountIdList(
            listAccount,
            listAccountZipCode
        );
        // Get Org Unit Map for Loop
        Map<String, TPB_Org_Unit_Mapping__c> mapZipcodeToOrgUnit = new Map<String, TPB_Org_Unit_Mapping__c>();
        List<TPB_Org_Unit_Mapping__c> listOrgUnitMap = [
            SELECT TPB_Org_Unit__c, TPB_State_Abbrev__c, TPB_Zip_Code__c
            FROM TPB_Org_Unit_Mapping__c
            WHERE TPB_Zip_Code__c = :listAccountZipCode
        ];
        List<String> listOrgUnit = new List<String>();
        for (TPB_Org_Unit_Mapping__c itemOrgUnitMap : listOrgUnitMap) {
            mapZipcodeToOrgUnit.put(
                itemOrgUnitMap.TPB_Zip_Code__c,
                itemOrgUnitMap
            );
            listOrgUnit.add(itemOrgUnitMap.TPB_Org_Unit__c);
        }
        // Get Org Unit User for Loop
        Map<Id, cgcloud__Org_Unit_User__c> mapOrgUnitToUser = getOrgUnitToUserMap(
            listOrgUnit
        );
        // Get Customer Org Unit for Loop
        Map<Id, cgcloud__Account_Org_Unit__c> mapAccountIdToCustomerOrgUnit = getAccountIdToCustomerOrgUnitMap(
            listAccountId
        );
        // Update Record List
        List<cgcloud__Account_Org_Unit__c> insertListCustomerOrgUnit = new List<cgcloud__Account_Org_Unit__c>();
        List<Account> updateListAccount = new List<Account>();
        List<cgcloud__Account_Org_Unit__c> deleteListCustomerOrgUnit = new List<cgcloud__Account_Org_Unit__c>();
        for (Account itemAccount : listAccount) {
            // Get Org Unit Map Item
            TPB_Org_Unit_Mapping__c itemOrgUnitMapInLoop = new TPB_Org_Unit_Mapping__c();
            if (
                mapZipcodeToOrgUnit.containsKey(itemAccount.ShippingPostalCode)
            ) {
                itemOrgUnitMapInLoop = mapZipcodeToOrgUnit.get(
                    itemAccount.ShippingPostalCode
                );
            }
            // Check Account ZipCode & State Null
            // Check ZipCode & State
            if (
                itemOrgUnitMapInLoop.TPB_State_Abbrev__c !=
                itemAccount.ShippingState ||
                itemOrgUnitMapInLoop.TPB_Zip_Code__c !=
                itemAccount.ShippingPostalCode
            ) {
                continue;
            }
            // Check Customer Org Unit Item Exist
            cgcloud__Account_Org_Unit__c itemCustomerOrgUnitInLoop = new cgcloud__Account_Org_Unit__c();
            if (mapAccountIdToCustomerOrgUnit.containsKey(itemAccount.Id)) {
                // Exist Old Customer Org Unit
                itemCustomerOrgUnitInLoop = mapAccountIdToCustomerOrgUnit.get(
                    itemAccount.Id
                );
                // Check Existing Customer Org Unit's Org Unit
                if (
                    itemCustomerOrgUnitInLoop.cgcloud__Org_Unit__c !=
                    itemOrgUnitMapInLoop.TPB_Org_Unit__c
                ) {
                    // Old Customer Org Unit Record is Incorrect
                    deleteListCustomerOrgUnit.add(itemCustomerOrgUnitInLoop);
                }
            }
            // Create New Customer Org Unit to Insert
            cgcloud__Account_Org_Unit__c itemCustomerOrgUnitInsert = new cgcloud__Account_Org_Unit__c(
                cgcloud__Org_Unit__c = itemOrgUnitMapInLoop.TPB_Org_Unit__c,
                cgcloud__Account__c = itemAccount.Id,
                cgcloud__Active__c = true,
                cgcloud__Valid_From__c = date.today().addDays(-1),
                cgcloud__Valid_Thru__c = date.today().addYears(100)
            );
            // Add New Customer Org Unit Record to Insert List
            insertListCustomerOrgUnit.add(itemCustomerOrgUnitInsert);
            // Check Org Unit User Record Item Exist
            if (
                mapOrgUnitToUser.containsKey(
                    itemOrgUnitMapInLoop.TPB_Org_Unit__c
                )
            ) {
                itemAccount.OwnerId = mapOrgUnitToUser.get(
                        itemOrgUnitMapInLoop.TPB_Org_Unit__c
                    )
                    .cgcloud__User__c;
            }
            itemAccount.TPB_Org_Unit_Flag__c = true;
            updateListAccount.add(itemAccount);
        }
        // Update or Insert Records
        delete deleteListCustomerOrgUnit;
        update updateListAccount;
        insert insertListCustomerOrgUnit;
    }
    /**
     * @description finish Batch
     * @author Guanshu Wang
     * @param  bc bc description
     */
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
        queryStr = ' ';
    }
}