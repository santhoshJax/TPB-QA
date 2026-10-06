/**************************************************************************************
Apex Class Name:  TPB_ProductPEHandler
Version     : 1.0 
Created Date    : 2023-03-24
Function    : platform event handler class on Product to detect field changes on PricebookEntry include fields as below
OwnerId,
Test Class  : 
Modification Log :
-----------------------------------------------------------------------------
* @description product trigger handler
* Developer              Date                 Description
* ----------------------------------------------------------------------------     
* Tina.wu              2023-03-24            Original Version
*************************************************************************************/
public without sharing class TPB_ProductPEHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description afterUpdate description
     *
     */
    protected override void afterUpdate() {
        updateHiddenFieldAfterUpdate((List<Product2>)Trigger.new, (Map<Id,Product2>)Trigger.oldMap);
    }

    
     /**
     * @description updateHiddenFieldAfterUpdate 
     * Create the method for integration to update hidden fields,
     * so that integrations can merge formula fields in ADW 
     * @param  productNewList productNewList description
     * @param  productOldMap  productOldMap description
     */ 
    private void updateHiddenFieldAfterUpdate(List<Product2> productNewList, 
    Map<Id,Product2> productOldMap) {
        
        Set<Id> productId = new Set<Id>();

        for(Product2 item : productNewList){
            Product2 oldProduct = productOldMap.get(item.Id);
            if(oldProduct.Item_ID__c != item.Item_ID__c 
            || oldProduct.NTC_Price_List_Flag__c != item.NTC_Price_List_Flag__c ){
            	//detect fields changes on Product2: Display_Group__c,Item_ID__c,NTC_Price_List_Flag__c
                productId.add(item.Id);
            }
        }

        if(productId.size() > 0){
        	//product change related Pricebook Entry list
            List<cgcloud__Product_Condition__c> pcList = [SELECT Id FROM cgcloud__Product_Condition__c WHERE cgcloud__Product__c IN : productId];

            if(pcList!=null && pcList.size() > 0){
                for(cgcloud__Product_Condition__c item : pcList){
                    item.TPB_Formula_Rollup_Trigger__c = system.now();
                }
                update pcList;
            }
        }

    }
}