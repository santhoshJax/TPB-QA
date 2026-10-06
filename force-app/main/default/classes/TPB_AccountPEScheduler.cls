/**************************************************************************************
Apex Class Name:  TPB_AccountPEScheduler
Version     : 1.0 
Created Date    : 2023-03-24
Function    : platform event schedule class  to detect run batch TPB_AccountPEBatch daily
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description CON0001729-902 ERP_ARCustomer_Integration_PE batch scheduler
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Jeff.xu              2023-03-24            Original Version
*************************************************************************************/
public with sharing class TPB_AccountPEScheduler implements Schedulable {
    /**
     * @description execute batch job
     * @param  sc sc description
     */
    public void execute(SchedulableContext sc) {
        //set how many records to batch run in once
        Database.executeBatch(new TPB_AccountPEBatch(),2000);
    }
}