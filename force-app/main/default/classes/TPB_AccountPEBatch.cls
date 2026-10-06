/**************************************************************************************
Apex Class Name:  TPB_AccountPEBatch
Version     : 1.0 
Created Date    : 2023-03-24
Function    : platform event batch class  to query all related account and run logic

OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description CON0001729-902 ERP_ARCustomer_Integration_PE
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Jeff.xu              2023-03-24            Original Version
*************************************************************************************/
public class TPB_AccountPEBatch implements Database.Batchable<sObject> {
    //query string
    public String query;
    /**
     * @description TPB_AccountPEBatch constructor
     */
    public TPB_AccountPEBatch() {
        //build up query string by TPB_AR_Customer_Trigger__c is equals to today
        this.query = 'SELECT Id,Internal_Customer_ID__c,OwnerId,Owner.ADP_Employee_Number__c'
                    +' FROM Account WHERE TPB_AR_Customer_Trigger__c = TODAY';
    }
    /**
   * @description start description
   * @param   bc     description
   * @return  return description
   */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //get all qualified account records by query string
        return Database.getQueryLocator(query);
    }
     /**
   * @description execute description
   * @param  bc               description
   * @param  accList  description
   */
    public void execute(Database.BatchableContext bc, list<Account> accList) {
        
        if(accList!= null && accList.size() > 0){
            //initial event list for event publish
            List<TPB_PE_ADW_Account__e> accEventList = new List<TPB_PE_ADW_Account__e>();
            //loop all qualified account records 
            for(Account accItem : accList){
                //create event records 
                TPB_PE_ADW_Account__e accEvItem = new TPB_PE_ADW_Account__e();
                accEvItem.TPB_ObjectAPIName__c = 'Account';
                accEvItem.TPB_RecordId__c = accItem.Id;
                accEvItem.TPB_ADP_Employee_Number__c = accItem.Owner.ADP_Employee_Number__c;
                accEvItem.TPB_Internal_Customer_ID__c = accItem.Internal_Customer_ID__c;
               
                accEventList.add(accEvItem);
            }
            //invoke platform event publish function
            String rtnVal = TPB_PlatformEventUtility.publishAccountEventsADW(accEventList);
            //for code scan
            if(String.isEmpty(rtnVal)){rtnVal = '';}
        }
    }
     /**
   * @description finish description
   * @param  bc bc description
   */
    public void finish(Database.BatchableContext bc) {
        query = '';
    }
}