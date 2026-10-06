public with sharing class AccountProductsStatusWrapper {

    @AuraEnabled
    public String recordId;

    @AuraEnabled
    public String family;

    @AuraEnabled
    public Boolean applied;

    @AuraEnabled
    public String name;

    @AuraEnabled
    public String sku;

    @AuraEnabled
    public String productId;

    @AuraEnabled
    public String accountId;

    @AuraEnabled
    public Decimal costPrice;

    @AuraEnabled
    public Decimal sellingPrice;

    public AccountProductsStatusWrapper(Product2 prod, Account_Product__c accProd, String recordType, Id accountId) {
        if(accProd != null) {
            this.recordId = accProd.Id;
            this.family = prod.Display_Group__c;
            this.applied = accProd.Status__c == 'Yes' ? true : false;
            this.name = prod.Name;
            this.sku = recordType == 'Wholesaler' ? accProd.SKU__c : null;
            this.productId = prod.Id;
            this.accountId = accountId;
            this.costPrice = accProd.Cost_Price__c;
            this.sellingPrice = accProd.Selling_Price__c;
        }
        else {
            this.recordId = null;
            this.family = prod.Display_Group__c;
            this.applied = false;
            this.name = prod.Name;
            this.sku = null;
            this.productId = prod.Id;
            this.accountId = accountId;
            this.costPrice = null;
            this.sellingPrice = null;
        }
    }

}