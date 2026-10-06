/**************************************************************************************
Apex Class Name:  TPB_GTMOppStatusUpdateHandler
Version     : 1.0
Created Date    : 2023-08-14
Function    : Triggerred by record, Logic to Close GTM Opportunities Based on Selling Activities within a Store
OwnerId     :
Test Class  :
Modification Log :
-----------------------------------------------------------------------------
* Developer              Date                 Description
* ----------------------------------------------------------------------------
* Evonne              2023-08-14           Original Version
*************************************************************************************/

public with sharing class TPB_GTMOppStatusUpdateHandler extends SDF_TGF_TriggerHandler {

    /**
     * @description afterUpdate description
     */
    protected override void afterUpdate() {
        List<cgcloud__Visit_Job__c> lstVisitJob = (List<cgcloud__Visit_Job__c>) Trigger.new;
        processData(lstVisitJob);
    }

    /**
     * @description processData description
     * @param  lstVisitJob lstVisitJob description
     */
    private void processData(List<cgcloud__Visit_Job__c> lstVisitJob) {
        // get accountids, sales cycle, current VisitIds
        List<String> lstAccountIds = new List<String>();
        List<String> lstSalesCycle = new List<String>();
        List<String> lstVisitIds = new List<String>();
        Set<Id> setBaseVisitIds = new Set<Id>();
        for (cgcloud__Visit_Job__c objVisitJob : lstVisitJob) {
            lstVisitIds.add(objVisitJob.cgcloud__Visit__c);
        }
        // Visit
        List<Visit> lstVisit = [
            SELECT Id, AccountId, TPB_Sales_Cycle__c, TPB_Quarterly_Base_Visit__c
            FROM Visit
            WHERE Id IN :lstVisitIds
            AND Last_Call__c = true
        ];
        for (Visit objVisit : lstVisit) {
            lstAccountIds.add(objVisit.AccountId);
            lstSalesCycle.add(objVisit.TPB_Sales_Cycle__c);
            setBaseVisitIds.add((Id)objVisit.TPB_Quarterly_Base_Visit__c);
        }

        // last call visit jobs
        List<cgcloud__Visit_Job__c> lstCurrentVisitJobs = [
            SELECT id, cgcloud__Visit__c, cgcloud__Visit__r.AccountId, cgcloud__Visit__r.TPB_Sales_Cycle__c, cgcloud__Product__c, cgcloud__Visit_Date__c, TPB_Calculated_EOV__c,
            cgcloud__Product__r.cgcloud__Criterion_5_Product__c, cgcloud__Product__r.cgcloud__Criterion_4_Product__c, cgcloud__Product__r.cgcloud__Criterion_3_Product__c,
            cgcloud__Product__r.cgcloud__Criterion_2_Product__c, cgcloud__Product__r.cgcloud__Criterion_1_Product__c, cgcloud__Visit__r.TPB_Quarterly_Base_Visit__c
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__r.AccountId IN :lstAccountIds
            AND cgcloud__Visit__c IN :lstVisitIds
        ];
        // quarterly base call visit jobs
        List<cgcloud__Visit_Job__c> lstVisitJobQuarterlyBase = [
            SELECT id, cgcloud__Visit__c, cgcloud__Visit__r.AccountId, cgcloud__Visit__r.TPB_Sales_Cycle__c, cgcloud__Product__c, cgcloud__Visit_Date__c, TPB_Calculated_EOV__c,
            cgcloud__Product__r.cgcloud__Criterion_5_Product__c, cgcloud__Product__r.cgcloud__Criterion_4_Product__c, cgcloud__Product__r.cgcloud__Criterion_3_Product__c,
            cgcloud__Product__r.cgcloud__Criterion_2_Product__c, cgcloud__Product__r.cgcloud__Criterion_1_Product__c
            FROM cgcloud__Visit_Job__c
            WHERE cgcloud__Visit__r.AccountId IN :lstAccountIds
            // AND cgcloud__Visit__r.TPB_Sales_Cycle__c IN :lstSalesCycle
            AND cgcloud__Visit__c IN :setBaseVisitIds
            AND cgcloud__Visit__r.Quarterly_Base_Call__c = true
        ];



        // GTM opp
        List<TPB_GTM_Opportunity__c> lstGTMOpp = [
            SELECT Id, TPB_Current_Sales_Cycle__c, TPB_Status__c, TPB_Type__c, TPB_Account_ID__c, TPB_Product_ID__c, TPB_Product_Level__c
            FROM TPB_GTM_Opportunity__c
            WHERE TPB_Active__c = true
            AND TPB_Type__c != null
            AND TPB_Product_ID__c != null
            AND TPB_Current_Sales_Cycle__c IN :lstSalesCycle
            AND TPB_Account_ID__c IN :lstAccountIds
        ];

        Map<String, List<Map<String, String>>> mapVisitJobProductsLast = TPB_GTMOppStatusUpdateUtility.getMapVisitJobProductsLast(lstCurrentVisitJobs);
        Map<String, Map<String, List<Map<String, String>>>> mapCurrentBaseProduct = TPB_GTMOppStatusUpdateUtility.getMapCurrentBaseProduct(mapVisitJobProductsLast, lstVisitJobQuarterlyBase);

        List<TPB_GTM_Opportunity__c> lstGTMOppUpdate = TPB_GTMOppStatusUpdateUtility.getLstGTMOppUpdate(lstGTMOpp, mapVisitJobProductsLast, mapCurrentBaseProduct);
        Database.update(lstGTMOppUpdate, false);

    }
}