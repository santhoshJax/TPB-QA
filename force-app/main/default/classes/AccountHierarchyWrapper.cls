public with sharing class AccountHierarchyWrapper {

    @AuraEnabled
    public String accId;

    @AuraEnabled
    public String accName;

    @AuraEnabled
    public String recordType;

    @AuraEnabled
    public String recordLink;

    @AuraEnabled
    public String ownerName;

    @AuraEnabled
    public String billingCity;

    @AuraEnabled
    public String billingState;

    @AuraEnabled
    public Boolean cashSales;

    @AuraEnabled
    public String iconName;

    @AuraEnabled
    public List<Child> children_RESERVED;

    public class Child {
        @AuraEnabled
        public String accId;

        @AuraEnabled
        public String accName;

        @AuraEnabled
        public String recordType;

        @AuraEnabled
        public String recordLink;

        @AuraEnabled
        public String ownerName;

        @AuraEnabled
        public String billingCity;

        @AuraEnabled
        public String billingState;

        @AuraEnabled
        public Boolean cashSales;

        @AuraEnabled
        public String iconName;

        @AuraEnabled
        public String wholesaleType;
    }

    public AccountHierarchyWrapper(List<Account> accounts, Id accountId, String recordType) {
        List<Child> children = new List<Child>();

        for(Account acc : accounts) {
            if(acc.RecordType.Name == 'Headquarter' && recordType != 'Wholesaler') {
                this.accId = acc.Id;
                this.accName = acc.Name;
                this.recordType = acc.RecordType.Name;
                this.recordLink = '/' + acc.Id;
                this.ownerName = acc.Owner.Alias;
                this.billingCity = acc.BillingCity;
                this.billingState = acc.BillingState;
                this.cashSales = acc.Cash_Sales__c;
                this.iconName = acc.Id == accountId ? 'utility:company' : '';
            }
            else if(acc.RecordType.Name == 'Wholesaler' && recordType == 'Wholesaler') {
                this.accId = acc.Id;
                this.accName = acc.Name;
                this.recordType = acc.RecordType.Name;
                this.recordLink = '/' + acc.Id;
                this.ownerName = acc.Owner.Alias;
                this.billingCity = acc.BillingCity;
                this.billingState = acc.BillingState;
                this.cashSales = acc.Cash_Sales__c;
                this.iconName = acc.Id == accountId ? 'utility:company' : '';
            }
            else {
                Child childRecord = new Child();
                childRecord.accId = acc.Id;
                childRecord.accName = acc.Name;
                childRecord.recordType = acc.RecordType.Name;
                childRecord.recordLink = '/' + acc.Id;
                childRecord.ownerName = acc.Owner.Alias;
                childRecord.billingCity = acc.BillingCity;
                childRecord.billingState = acc.BillingState;
                childRecord.cashSales = acc.Cash_Sales__c;
                childRecord.iconName = acc.Id == accountId ? 'utility:company' : '';
                childRecord.wholesaleType = acc.RecordType.Name != 'Wholesaler' ? '' : acc.Type;
                children.add(childRecord);
            }
        }

        this.children_RESERVED = children;
    }

}