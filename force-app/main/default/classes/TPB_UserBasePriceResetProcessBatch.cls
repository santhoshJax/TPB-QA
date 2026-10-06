/**************************************************************************************************   
Apex Class Name      :  TPB_UserBasePriceResetProcessBatch
Version              :  1.0                                                                          
Created Date         :  August 12, 2024                                                               
Function             :  this batch class process user base price reset on inventory on file uploaded through UI
Test Class Name      :  TpbUserBasePriceResetProcessCtrlTest                                                                           
Modification Log     :    
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* ------------------------------------------------------------------------------------------------- 
*                             12/08/2024             Initial Version
*/
global class TPB_UserBasePriceResetProcessBatch implements Database.Batchable<Object> {
    
    global List<Object> lstCSVDataToProcess = new List<Object>();

    global TPB_UserBasePriceResetProcessBatch(List<Object> lstCSVData){
        lstCSVDataToProcess = lstCSVData;
    }

    /**
    * Method name  : start
    * Description  : Called on Start of Batch Job
    * Return Type  : Database.QueryLocator
    * Parameter    : BatchableContext
    **/
    global Iterable<Object> start(Database.BatchableContext BC){
        return lstCSVDataToProcess;
    }

     /**
    * Method name  : execute 
    * Description  : Called to Porcess record getting from Start method and called flow to process 1 by 1
    * Return Type  : vid
    * Parameter    : BatchableContext,scope
    **/
    global void execute(Database.BatchableContext BC , List<Object> lstCSVData){
        List<cgcloud__Inventory__c> lstInventoryToUpdate = new List<cgcloud__Inventory__c>();
        for(Object csvData : lstCSVData){
            Map<String,Object> csvDataMap = (Map<String,Object>)JSON.deserializeUntyped( JSON.serialize(csvData));

            lstInventoryToUpdate.add( createInventoryRecord(csvDataMap) );
            
            //calling existing class logic to process records as we were doing in flow
            TPB_PricingUtility.InputParameters inputParamWrapper = buildInputParameters(csvDataMap);
            TPB_PricingUtility.updatePricingConditionStage( new List<TPB_PricingUtility.InputParameters>{inputParamWrapper} );
        }

        if(!lstInventoryToUpdate.isEmpty()){
            update lstInventoryToUpdate;
        }
    }

    /**
    * Method name  : finish
    * Description  : Called after processing all records
    * Return Type  : vid
    * Parameter    : BatchableContext
    **/
    global void finish(Database.BatchableContext BC){

    }

    /**
    * Method name  : createInventoryRecord
    * Description  : This method creates and returns a new cgcloud__Inventory__c record based on the data provided in the map.
    *                The map contains key-value pairs where the key is the CSV column header, and the value is the corresponding data.
    * Return Type  : cgcloud__Inventory__c
    * Parameters   : - csvDataMap (Map<String, Object>): A map containing the CSV data, with column headers as keys and the corresponding values.
    **/
    private cgcloud__Inventory__c createInventoryRecord(Map<String, Object> csvDataMap) {
        cgcloud__Inventory__c objInventory = new cgcloud__Inventory__c();
        objInventory.put('Id',              csvDataMap.get('InventoryId'));
        objInventory.put('TPB_AvgPrice__c', csvDataMap.get('NewBasePrice') != null ? Decimal.valueOf(String.valueOf(csvDataMap.get('NewBasePrice'))) : null);
        objInventory.put('TPB_Reson__c',    csvDataMap.get('Reason'));
        return objInventory;
    }

    /**
    * Method name  : buildInputParameters
    * Description  : This method constructs and returns an instance of TPB_PricingUtility.InputParameters based on the data provided in the CSV data map.
    *                The map contains key-value pairs where the key is the CSV column header, and the value is the corresponding data.
    * Return Type  : TPB_PricingUtility.InputParameters
    * Parameters   : - csvDataMap (Map<String, Object>): A map containing the CSV data, with column headers as keys and the corresponding values.
    **/
    private TPB_PricingUtility.InputParameters buildInputParameters(Map<String, Object> csvDataMap) {
        TPB_PricingUtility.InputParameters inputParamWrapper = new TPB_PricingUtility.InputParameters();
        inputParamWrapper.lstInventory       = new List<String>{ String.valueOf(csvDataMap.get('InventoryId')) };
        inputParamWrapper.boolCheck          = false;
        inputParamWrapper.inventoryBasePrice = csvDataMap.get('NewBasePrice') != null ? Double.valueOf(String.valueOf(csvDataMap.get('NewBasePrice'))) : null;
        inputParamWrapper.strType            = 'InventoryUpdate';
        return inputParamWrapper;
    }
}