@isTest
public class AccountProductsStatusTest {
    
    public static testMethod void testWholesaler() {
        Account wholesaler = TestDataFactory.createWholesaleAccount();
        Product2 prod = TestDataFactory.createProduct();
        Account_Product__c accProd = TestDataFactory.createAccountProduct(wholesaler.Id, prod.Id);

        AccountProductsStatusWrapper wrapper = new AccountProductsStatusWrapper(prod, accProd, 'Wholesaler', wholesaler.Id);
        
        test.startTest();
        AccountProductsStatusController.getProducts(wholesaler.Id, null, 'Wholesaler');
        AccountProductsStatusController.upsertProducts(JSON.serialize(new List<AccountProductsStatusWrapper>{wrapper}), wholesaler.Id);
        test.stopTest();
    }

    public static testMethod void testNoAccountProd() {
        Account wholesaler = TestDataFactory.createWholesaleAccount();
        Product2 prod = TestDataFactory.createProduct();
        
        test.startTest();
        AccountProductsStatusController.getProducts(wholesaler.Id, null, 'Wholesaler');
        test.stopTest();
    }

}