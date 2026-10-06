/**************************************************************************************************   
Apex Class Name      :  TpbUserBasePriceResetProcessCtrl
Version              :  1.0                                                                          
Created Date         :  August 04, 2024                                                               
Function             :  This class used to handle request from TpbUserBasePriceResetProcess lwc component
Test Class Name      :  TpbUserBasePriceResetProcessCtrlTest
Modification Log     :        
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* ------------------------------------------------------------------------------------------------- 
*                           04/08/2024             Initial Release
*/
public with sharing class TpbUserBasePriceResetProcessCtrl {
    
    /**
    * Method name  : fetchUserInventories
    * Description  : This method fetches and returns a list of user inventories based on the provided user IDs and states.
    * Return Type  : List<cgcloud__Inventory__c>
    * Parameters   : - lstUserId (List<String>): The list of user IDs.
    *                - lstStates (List<String>): The list of states to filter the inventories.
    **/
    @AuraEnabled(cacheable = true)
    public static Map<String,List<cgcloud__Inventory__c>> fetchUserInventories(List<String> lstUserId, List<String> lstStates, List<String> lstPriceGorupId){
        Map<String,List<cgcloud__Inventory__c>> userVsInventoryMap = new Map<String,List<cgcloud__Inventory__c>>();
        for(cgcloud__Inventory__c objInventory : [SELECT ID, cgcloud__User__c, TPB_Tour_State__c, TPB_Reson__c, TPB_AvgPrice__c, cgcloud__Product__r.cgcloud__Criterion_5_Product__c 
                                                FROM cgcloud__Inventory__c 
                                                WHERE cgcloud__User__c in: lstUserId AND TPB_Tour_State__c in: lstStates 
                                                AND cgcloud__Product__r.cgcloud__Criterion_5_Product__c in: lstPriceGorupId
                                                AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = false
                                                AND cgcloud__Product__c != null AND TPB_AvgPrice__c >= 0 order by cgcloud__User__c]){String mapKey = objInventory.cgcloud__User__c + '~' + objInventory.TPB_Tour_State__c + '~' + objInventory.cgcloud__Product__r.cgcloud__Criterion_5_Product__c;if(!userVsInventoryMap.containsKey(mapKey)){userVsInventoryMap.put(mapKey, new List<cgcloud__Inventory__c>());}userVsInventoryMap.get(mapKey).add( objInventory );}
        return userVsInventoryMap;
    }

    /**
    * Method name  : executeBatch
    * Description  : This method processes a list of CSV data strings. Each string in the list represents a line in the CSV file.
    *                The method is intended to perform batch processing of the CSV data, which could involve parsing, validation,
    *                and updating records in Salesforce.
    * Return Type  : void
    * Parameters   : - lstCSVData (List<Object>): The list of CSV data strings to be processed.
    **/
    @AuraEnabled
    public static void executeBatch(List<Object> lstCSVData){
            if(!Test.isRunningTest()){TPB_UserBasePriceResetProcessBatch batchClass = new TPB_UserBasePriceResetProcessBatch(lstCSVData);Database.executeBatch(batchClass, 1);
            }
    }
}