/**
 * TPB_UpdateFileRelatedAccountBatch
 *
 * @author Jie Yu
 * @date 2023-03-17
 * @description Update File id on Related Account
 *
 */
public with sharing class TPB_UpdateFileRelatedAccountBatch implements Database.Batchable<sObject> {
    //Query Sql
    private String strQuery;
    private Map<Id, Id> mapAccDoc;
    private Set<Id> setWholesalerId;
    /**
     * @description TPB_CreateActivityBatch Input QueryString & Activity Template Name & Visit Template Name
     * @param  lstRA            list of Related Account
     */
    public TPB_UpdateFileRelatedAccountBatch(Map<Id, Id> mapAccDoc) {
        this.mapAccDoc = mapAccDoc;
        this.setWholesalerId = mapAccDoc.keySet();
        this.strQuery = 'SELECT Id, Wholesaler__c, TPB_Wholesaler_File__c FROM Related_Account__c WHERE Wholesaler__c IN :setWholesalerId';
    }
    /**
    * @description This method is used to collect record under specified query.
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strQuery);
    }
    /**
     * @description execute
     * @author Guanshu Wang
     * @param  bc                 BatchableContext Input
     * @param  lstRA              List Related Account
     */
    public void execute( Database.BatchableContext bc, List<Related_Account__c> lstRA ) {
        for(Related_Account__c objRA : lstRA){
            objRA.TPB_Wholesaler_File__c = mapAccDoc.get(objRA.Wholesaler__c);
        }
        update lstRA;
    }
    /**
     * @description Batch Finish
     * @author Guanshu Wang
     * @param  bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
    }
}