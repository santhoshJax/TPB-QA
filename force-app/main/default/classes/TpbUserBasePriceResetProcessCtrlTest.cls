/**
* @File Name : TpbUserBasePriceResetProcessCtrlTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 25, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 25, 2024 |   | Initial Version
**/
@isTest
public class TpbUserBasePriceResetProcessCtrlTest {
    
    
    
    @isTest(SeeAllData=true)
    static void testBatchExecution() {
        List<Object> mockCSVData = new List<Object>{
            new Map<String, Object>{
                'InventoryId' => [SELECT Id FROM cgcloud__Inventory__c LIMIT 1].Id,
                    'NewBasePrice' => 120.0,
                    'Reason' => 'List Price Increase'
                    },
                        new Map<String, Object>{
                            'InventoryId' => [SELECT Id FROM cgcloud__Inventory__c LIMIT 1 OFFSET 1].Id,
                                'NewBasePrice' => 160.0,
                                'Reason' => 'List Price Increase'
                                }
        };
            TPB_UserBasePriceResetProcessBatch batchInstance = new TPB_UserBasePriceResetProcessBatch(mockCSVData);
        Test.startTest();
        Database.executeBatch(batchInstance, mockCSVData.size());
        Test.stopTest();
    }
    
    
    
    
    @isTest
    public static void fetchUserInventoriesTest(){        
        List<String> userIds = new List<String>{ 'testuser1@test.com', 'testuser2@test.com' };
            List<String> states = new List<String>{ 'California', 'Nevada' };
                List<String> priceGroupIds = new List<String>{ 'PG1', 'PG2' };
                    Test.startTest();
        Map<String, List<cgcloud__Inventory__c>> result = TpbUserBasePriceResetProcessCtrl.fetchUserInventories(userIds, states, priceGroupIds);
        Test.stopTest();
    }
    
    @isTest
    static void executeBatchTest(){
        List<Object> mockCSVData = new List<Object>{'Test,Test,100','Test2,Test2,150'};
            Test.startTest();
        TpbUserBasePriceResetProcessCtrl.executeBatch(mockCSVData);
        Test.stopTest();
    } 
    
    
}