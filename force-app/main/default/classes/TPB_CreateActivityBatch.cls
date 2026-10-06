/**
 * TPB_CreateActivityBatch
 *
 * @author Guanshu Wang
 * @date 2023-03-17
 * @description Create Activity Base on Org_Unit_Account
 *
 */
public with sharing class TPB_CreateActivityBatch implements Database.Batchable<sObject> {
    // String for Param
    String queryStr;
    // Activity Template Name String
    String strActivityTemplate;
    // Visit Template Name String
    String strVisitTemplate;
    /**
     * @description TPB_CreateActivityBatch Input QueryString & Activity Template Name & Visit Template Name
     * @author Guanshu Wang
     * @param  queryStr            queryStr query cgcloud__Account_Org_Unit__c
     * @param  strActivityTemplate strActivityTemplate Activity Template Name
     * @param  strVisitTemplate    strVisitTemplate Visit Template Name
     */
    public TPB_CreateActivityBatch(
        String queryStr,
        String strActivityTemplate,
        String strVisitTemplate
    ) {
        this.queryStr = queryStr;
        this.strActivityTemplate = strActivityTemplate;
        this.strVisitTemplate = strVisitTemplate;
    }
    /**
     * @description TPB_CreateActivityBatch Input Query String
     * @author Guanshu Wang
     * @param  queryStr queryStr query cgcloud__Account_Org_Unit__c
     */
    public TPB_CreateActivityBatch(String queryStr) {
        this.queryStr = queryStr;
        this.strActivityTemplate = 'Distribution Activity Template';
        this.strVisitTemplate = 'Distribution Visit Template';
    }
    /**
     * @description TPB_CreateActivityBatch All Params are Default Value
     * @author Guanshu Wang
     */
    public TPB_CreateActivityBatch() {
        this.queryStr = 'SELECT ID,cgcloud__Account__c FROM cgcloud__Account_Org_Unit__c WHERE cgcloud__Org_Unit__c IN (SELECT ID FROM cgcloud__Org_Unit__c WHERE Org_Unit_Main__c= false) AND cgcloud__Active__c = true';
        this.strActivityTemplate = 'Distribution Activity Template';
        this.strVisitTemplate = 'Distribution Visit Template';
    }
    /**
     * @description QueryLocator Start
     * @author Guanshu Wang
     * @param  bc BatchableContext
     * @return    return getQueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(queryStr);
    }
    /**
     * @description execute
     * @author Guanshu Wang
     * @param  bc                 BatchableContext Input
     * @param  listAccountOrgUnit List Account Org Unit
     */
    public void execute(
        Database.BatchableContext bc,
        List<cgcloud__Account_Org_Unit__c> listAccountOrgUnit
    ) {
        // Get Activity Template ID
        Id itemActivityTemplateId = [
            SELECT Id
            FROM cgcloud__Job_Definition_List_Template__c
            WHERE Name = :strActivityTemplate
            LIMIT 1
        ]
        .Id;
        Id itemVisitTemplateId = [
            SELECT Id
            FROM cgcloud__Visit_Template__c
            WHERE Name = :strVisitTemplate
            LIMIT 1
        ]
        .Id;
        // Create List to Insert
        Map<Id, cgcloud__Job_Definition_List__c> mapJDLToJDLA = new Map<Id, cgcloud__Job_Definition_List__c>();
        List<cgcloud__Job_Definition_List__c> insertJDL = new List<cgcloud__Job_Definition_List__c>();
        List<cgcloud__Job_Definition_List_Account__c> insertJDLA = new List<cgcloud__Job_Definition_List_Account__c>();
        // Create Activity
        for (cgcloud__Account_Org_Unit__c aOUItem : listAccountOrgUnit) {
            // New Activity Record
            cgcloud__Job_Definition_List__c insertJDLItem = new cgcloud__Job_Definition_List__c(
                cgcloud__Active__c = true,
                cgcloud__Approval_State__c = 'Not Relevant',
                cgcloud__Consider_History__c = true,
                cgcloud__Consider_Products__c = true,
                cgcloud__Consider_Score__c = 'No',
                cgcloud__Default_Management_Type__c = 'Sales',
                cgcloud__Description_Language_1__c = 'Standard Survey Activities',
                cgcloud__Job_Definition_List_Template__c = itemActivityTemplateId,
                cgcloud__Sales_Org__c = '0001',
                cgcloud__User_Policy__c = 'All',
                cgcloud__Valid_From__c = Date.newInstance(2023, 2, 20),
                cgcloud__Valid_Thru__c = Date.newInstance(2123, 2, 20),
                cgcloud__Visit_Template__c = itemVisitTemplateId,
                Name = aOUItem.cgcloud__Account__r.Name + ' Activity'
            );
            // Add New Record to InsertList
            insertJDL.add(insertJDLItem);
            // Map New Acitvity Record to Account Id to Create Activity Customer Record
            mapJDLToJDLA.put(aOUItem.cgcloud__Account__c, insertJDLItem);
        }
        // Insert Activity
        insert insertJDL;
        // Create Customer Activity
        for (Id idAccountItem : mapJDLToJDLA.keyset()) {
            cgcloud__Job_Definition_List_Account__c insertJDLAItem = new cgcloud__Job_Definition_List_Account__c(
                cgcloud__Job_Definition_List__c = mapJDLToJDLA.get(
                        idAccountItem
                    )
                    .Id,
                cgcloud__Account__c = idAccountItem,
                cgcloud__Sales_Org__c = '0001'
            );
            // Add New Record to InsertList
            insertJDLA.add(insertJDLAItem);
        }
        // Insert Activity Customer
        insert insertJDLA;
    }
    /**
     * @description Batch Finish
     * @author Guanshu Wang
     * @param  bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
        queryStr = '';
    }
}