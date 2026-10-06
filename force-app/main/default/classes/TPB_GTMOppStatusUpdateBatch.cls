/**
 * @author: Evonne
 * date:4/8/2023
 * @description Logic to Close GTM Opportunities Based on Selling Activities within a Store
 */
public with sharing class TPB_GTMOppStatusUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    List<Period> lstPeriod = [
            SELECT StartDate, EndDate, FullyQualifiedLabel, Number
            FROM Period
            WHERE Type = 'Quarter' AND StartDate <= TODAY AND EndDate >= TODAY
            ORDER BY StartDate DESC
            LIMIT 1
        ];
    String strQuarter = lstPeriod[0].FullyQualifiedLabel.right(4) + ' ' + String.valueOf(lstPeriod[0].Number);
    String query = 'SELECT Id, TPB_Current_Sales_Cycle__c, TPB_Status__c, TPB_Type__c, TPB_Account_ID__c, TPB_Product_ID__c, TPB_Product_Level__c FROM TPB_GTM_Opportunity__c WHERE TPB_Active__c = true AND TPB_Type__c != null AND TPB_Product_ID__c != null';
    /**
     * @description TPB_GTMOppStatusUpdateBatch description
     */
    public TPB_GTMOppStatusUpdateBatch() {
        this.query = query + ' AND TPB_Current_Sales_Cycle__c = :strQuarter';
    }

    /**
     * @description TPB_GTMOppStatusUpdateBatch description
     * @param  strQuarter strQuarter description
     */
    public TPB_GTMOppStatusUpdateBatch(String strQuarter) {
        this.strQuarter = strQuarter;
        // this.blYear = blYear;
        this.query = query + ' AND TPB_Current_Sales_Cycle__c = :strQuarter';
        // if (blYear == true) {
        //     this.query = query + ' AND TPB_Opportunity__r.TPB_Year__c = :strYear';
        // } else {
        //     this.query = query + ' AND TPB_Current_Sales_Cycle__c = :strQuarter';
        // }
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
     * @param  bc        bc description
     * @param  lstGTMOppBC lstGTMOppBC description
     */
    public void execute(Database.BatchableContext bc, List<TPB_GTM_Opportunity__c> lstGTMOppBC) {
        List<TPB_GTM_Opportunity__c> lstGTMOpp = new List<TPB_GTM_Opportunity__c>();
        List<String> lstAccountId = new List<String>();
        for (TPB_GTM_Opportunity__c objGTMOpp : lstGTMOppBC) {
            lstGTMOpp.add(objGTMOpp);
            if (objGTMOpp.TPB_Type__c == 'New Distribution') {
                lstAccountId.add(objGTMOpp.TPB_Account_ID__c);
            }
        }


        List<Id> lstVisitIds = new List<Id>();
        List<AggregateResult> lstAR = [SELECT MAX(Id)Id FROM Visit WHERE TPB_Sales_Cycle__c = :strQuarter AND AccountId IN :lstAccountId Group By AccountId];
        for (AggregateResult objAR : lstAR) {
            lstVisitIds.add((Id)objAR.get('Id'));
        }

        List<cgcloud__Visit_Job__c> lstVisitJob = getlstVisitJob(false, true, lstAccountId, lstVisitIds, null);
        Set<Id> setBaseVisitIds = new Set<Id>();
        for (cgcloud__Visit_Job__c objVisitJob : lstVisitJob) {
            setBaseVisitIds.add((Id)objVisitJob.cgcloud__Visit__r.TPB_Quarterly_Base_Visit__c);
        }
        List<cgcloud__Visit_Job__c> lstVisitJobQuarterlyBase = getlstVisitJob(true, false, lstAccountId, lstVisitIds, setBaseVisitIds);

        Map<String, List<Map<String, String>>> mapVisitJobProductsLast = TPB_GTMOppStatusUpdateUtility.getMapVisitJobProductsLast(lstVisitJob);
        Map<String, Map<String, List<Map<String, String>>>> mapCurrentBaseProduct = TPB_GTMOppStatusUpdateUtility.getMapCurrentBaseProduct(mapVisitJobProductsLast, lstVisitJobQuarterlyBase);

        List<TPB_GTM_Opportunity__c> lstGTMOppUpdate = TPB_GTMOppStatusUpdateUtility.getLstGTMOppUpdate(lstGTMOpp, mapVisitJobProductsLast, mapCurrentBaseProduct);
        Database.update(lstGTMOppUpdate, false);

    }

    /**
     * @description finish description
     * @param  bc bc description
     */
    public void finish(Database.BatchableContext bc) {
        query = '';
    }

    /**
     * @description getlstVisitJob description
     * @param  blBase       blBase description
     * @param  blLast       blLast description
     * @param  lstAccountId lstAccountId description
     * @param  lstVisitIds lstVisitIds description
     * @param  setBaseVisitIds setBaseVisitIds description
     * @return              return description
     */
    public List<cgcloud__Visit_Job__c> getlstVisitJob(Boolean blBase, Boolean blLast, List<String> lstAccountId, List<Id> lstVisitIds, Set<Id> setBaseVisitIds) {
        List<cgcloud__Visit_Job__c> lstVisitJobs = new List<cgcloud__Visit_Job__c>();
        String strQuery = 'SELECT id, cgcloud__Visit__c, cgcloud__Visit__r.AccountId, cgcloud__Visit__r.TPB_Sales_Cycle__c, cgcloud__Product__c, cgcloud__Visit_Date__c, TPB_Calculated_EOV__c, ' +
        'cgcloud__Product__r.cgcloud__Criterion_5_Product__c, cgcloud__Product__r.cgcloud__Criterion_4_Product__c, cgcloud__Product__r.cgcloud__Criterion_3_Product__c, ' +
        'cgcloud__Product__r.cgcloud__Criterion_2_Product__c, cgcloud__Product__r.cgcloud__Criterion_1_Product__c,  cgcloud__Visit__r.TPB_Quarterly_Base_Visit__c ' +
        'FROM cgcloud__Visit_Job__c ' +
        'WHERE cgcloud__Visit__r.AccountId IN :lstAccountId ' +
        'AND cgcloud__Visit__r.Status = \'Completed\' ';
        if (blBase == true) {
            strQuery += ' AND cgcloud__Visit__r.Quarterly_Base_Call__c = :blBase AND cgcloud__Visit__c IN :setBaseVisitIds';
            lstVisitJobs = Database.query(strQuery);
        }
        if (blLast == true) {
            strQuery += ' AND cgcloud__Visit__c = :lstVisitIds';
            lstVisitJobs = Database.query(strQuery);
        }
        return lstVisitJobs;
    }
}