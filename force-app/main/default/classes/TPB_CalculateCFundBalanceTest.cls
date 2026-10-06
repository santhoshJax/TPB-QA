/**
* @author Feng Lian
* @date 7/4/2023
* @description TPB_CalculateCFundBalance test class
*/
@isTest
public class TPB_CalculateCFundBalanceTest {
    @TestSetup
    static void setup() {
        //create User data
        User userOne = [SELECT Id FROM User WHERE Profile.Name = 'CG Cloud Mobile - TSM' AND IsActive = true LIMIT 1];
        
        //create Account for test.
        Account accObj = TPB_TestFactory.createAccount();
        accObj.OwnerId = userOne.Id;
        update accObj;
        
        //create Visit for test.
        Visit objVisit = TPB_TestFactory.createVisit(accObj);
        cgcloud__Order__c objOrder = TPB_TestFactory.createAdOrder(objVisit);
        System.runAs(userOne) {
            //create Order Item for test.
            cgcloud__Order_Item__c objOrderItem = new cgcloud__Order_Item__c();
            objOrderItem.cgcloud__Special_Price__c = 12;
            objOrderItem.cgcloud__Order__c = objOrder.id;
            objOrderItem.cgcloud__Value__c = 12;
            objOrderItem.Reimbursable_Amt__c = 12;
            objOrderItem.cgcloud__Pricing_Info_1__c = 12;
            objOrderItem.Reimbursement_Status__c = 'In Progress';
            insert objOrderItem;
        }
        
        objOrder.cgcloud__Phase__c = 'Released';
        objOrder.cgcloud__Value__c = 12;
        objOrder.cgcloud__Release_Time__c = Date.today();
        objOrder.cgcloud__Order_Account__c = accObj.id;
        objOrder.cgcloud__Delivery_Recipient__c = accObj.id;
        objOrder.cgcloud__Accountable__c = userOne.Id;
        update objOrder;
        
        //create Order for test
        Order objOrder1;
        System.runAs(userOne) {
            objOrder1 = new Order();
            objOrder1.Related_Visit__c = objVisit.Id;
            objOrder1.AccountId = accObj.id;
            objOrder1.External_Order_Number__c = 'OD000001';
            objOrder1.External_Amount__c = 100;
            objOrder1.Status = 'Draft';
            objOrder1.TPB_State__c = 'NY';
            objOrder1.EffectiveDate = Date.today();
            objOrder1.Pricebook2Id = Test.getStandardPricebookId();
            insert objOrder1;
        }
        
        //create Product2 data
        Product2 prod = TPB_TestFactory.createProduct();
        
        //create PricebookEntry data
        PricebookEntry entry = TPB_TestFactory.createPricebookEntry(prod.Id);
        
        //create OrderItem data
        OrderItem objOrderItem1 = new OrderItem();
        objOrderItem1.OrderId = objOrder1.Id;
        objOrderItem1.Product2Id = prod.Id;
        objOrderItem1.UoM__c = 'Carton';
        objOrderItem1.Quantity = 10;
        objOrderItem1.UnitPrice = 10.99;
        objOrderItem1.TPB_Type__c = 'Purchase';
        objOrderItem1.PricebookEntryId = entry.Id;
        insert objOrderItem1;
        //create Inventory
        TPB_TestFactory.createInventory(UserInfo.getUserId(), prod.Id);
        
        objOrder1.Status = 'Activated';
        update objOrder1;
    }
    
    @isTest
    static void testBatch() {
        User userOne = [SELECT Id FROM User WHERE Profile.Name = 'CG Cloud Mobile - TSM' AND IsActive = true LIMIT 1];
        System.Test.startTest();
        //run batch
        TPB_CalculateCFundBalance batch = new TPB_CalculateCFundBalance(new Set<Id>{userOne.Id});
        Database.executeBatch(batch);
        System.Test.stopTest();
        
        //assert batch job result.
        userOne = [SELECT Id, TPB_Balance__c FROM User WHERE Id = : userOne.Id];
        System.assertEquals(97.9, userOne.TPB_Balance__c, false);
    }
}