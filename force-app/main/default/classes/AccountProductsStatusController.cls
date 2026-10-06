public with sharing class AccountProductsStatusController {

    @auraEnabled
    public static List<AccountProductsStatusWrapper> getProducts(Id accountId, Id parentId, String recordType) {
        List<AccountProductsStatusWrapper> finalWrapper = new List<AccountProductsStatusWrapper>();
        Map<Id, Account_Product__c> accProdMap = new Map<Id, Account_Product__c>();

        String correctAccountId = String.isNotEmpty(parentId) && recordType == 'Retailer' ? parentId : accountId;

        for(Account_Product__c accProd : [SELECT Id, Name, Product__c, Product__r.Name, Product__r.Display_Group__c, Account__c, Selling_Price__c, Cost_Price__c, Status__c, SKU__c FROM Account_Product__c WHERE Account__c = :correctAccountId]) {
            accProdMap.put(accProd.Product__c, accProd);
        }

        //We need to iterate over all active products and compare against what is at the account level
        for(Product2 prod : [SELECT Id, Name, Display_Group__c FROM Product2 WHERE IsActive = true and Display_Group__c != null ORDER BY Display_Group__c ASC, Product2.Sort_Order__c ASC]) {
            Account_Product__c accProd = accProdMap.get(prod.Id);
            AccountProductsStatusWrapper wrapper = new AccountProductsStatusWrapper(prod, accProd, recordType, accountId);
            finalWrapper.add(wrapper);
        }

        return finalWrapper;
    }

    @auraEnabled
    public static String upsertProducts(String rawProducts, Id accountId) {
        List<AccountProductsStatusWrapper> items = (List<AccountProductsStatusWrapper>)JSON.deserialize(rawProducts, List<AccountProductsStatusWrapper>.class);
        List<Account_Product__c> accProdUpserts = new List<Account_Product__c>();

        for(AccountProductsStatusWrapper wrapper : items) {
            Account_Product__c accProd = new Account_Product__c();
            //Update
            if(wrapper.recordId != null) {
                accProd.Id = wrapper.recordId;
            }
            //Insert only
            else {
                accProd.Account__c = accountId;
                accProd.Product__c = wrapper.productId;
            }

            if(wrapper.applied != true) {
                accProd.Status__c = 'No';
            }
            else {
                accProd.Status__c = 'Yes';
            }

            accProd.Cost_Price__c = wrapper.costPrice;
            accProd.Selling_Price__c = wrapper.sellingPrice;
            accProd.SKU__c = wrapper.sku;
            accProd.Unique_Id__c = accountId + '-' + wrapper.productId;
            accProdUpserts.add(accProd);
        }

        try {
            upsert accProdUpserts Unique_Id__c;
        }
        catch(DmlException e) {
            return e.getMessage();
        }

        return 'SUCCESS';
    }

}