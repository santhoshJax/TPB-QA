public with sharing class AppointmentLineItemsSectionWrapper {

    // @AuraEnabled
    // public String workOrderId;

    // @AuraEnabled
    // public String recordId;

    // @AuraEnabled
    // public String entryId;

    // @AuraEnabled
    // public String productName;

    // @AuraEnabled
    // public String itemType;

    // @AuraEnabled
    // public Decimal shelfPrice;

    // @AuraEnabled
    // public String displayGroup;

    // @AuraEnabled
    // public String primarySKU;

    // @AuraEnabled
    // public String secondarySKU;

    // @AuraEnabled
    // public Boolean eOrder;

    // @AuraEnabled
    // public Date prebookDate;

    // @AuraEnabled
    // public Id wholesalerId;

    // @AuraEnabled
    // public Boolean isNotPrebook;

    // @AuraEnabled
    // public String zone;

    // @AuraEnabled
    // public Decimal unitPrice;

    // @AuraEnabled
    // public Decimal quantity;

    // @AuraEnabled
    // public Decimal discount;

    // @AuraEnabled
    // public Decimal totalPrice;

    // @AuraEnabled
    // public Decimal perCarton;

    // @AuraEnabled
    // public Boolean inStock;

    // @AuraEnabled
    // public Decimal eachPrice;

    // @AuraEnabled
    // public String uom;

    // @AuraEnabled
    // public Boolean cartView;

    // @AuraEnabled
    // public Boolean discountNotEnabled;

    // @AuraEnabled
    // public Boolean productDiscountEnabled;

    // @AuraEnabled
    // public Boolean wholesalerNotEnabled;

    // @AuraEnabled
    // public Boolean returnType;

    // @AuraEnabled
    // public Boolean resale;

    // @AuraEnabled
    // public Boolean pricingNotEnabled;

    // @AuraEnabled
    // public Boolean cannotDelete;

    // @AuraEnabled
    // public Boolean uomNotEnabled;

    // public AppointmentLineItemsSectionWrapper(WorkOrderLineItem line, Map<Id,Boolean> eOrderMap, Map<String,String> skuMap, Map<Id,Object> prevLineMap) {
    //     Set<String> groupedTypes = new Set<String>{'Bill Thru', 'Prebook', 'Suggested Order', 'POS Placement'};
    //     Set<String> validDiscountTypes = new Set<String>{'Cash Sale', 'Reimbursable Gratis', 'Non-Reimbursable Gratis'};

    //     //Some are reference fields and some are database fields
    //     this.workOrderId = line.WorkOrderId;
    //     this.recordId = line.Id;
    //     this.entryId = line.PricebookEntryId;
    //     this.productName = line.Product2.Name;
    //     this.itemType = line.Item_Type__c;
    //     this.isNotPrebook = true;
    //     this.displayGroup = line.Product2.Display_Group__c;
    //     this.eOrder = eOrderMap.get(line.Product2Id);
    //     this.primarySKU = skuMap.get('PRIMARY-' + line.Product2Id);
    //     this.secondarySKU = skuMap.get('SECONDARY-' + line.Product2Id);
    //     this.prebookDate = line.Prebook_Date__c;
    //     this.wholesalerId = line.Related_Account__c;
    //     this.wholesalerNotEnabled = !groupedTypes.contains(line.Item_Type__c);
    //     this.quantity = line.Quantity;
    //     this.discount = line.Discount__c;
    //     this.discountNotEnabled = true;
    //     this.productDiscountEnabled = line.Product2.Discount__c;
    //     this.totalPrice = line.Total__c;
    //     this.perCarton = line.Product2.Packs_Carton__c;
    //     this.inStock = line.In_Stock__c;
    //     this.eachPrice = this.uom == 'Carton' ? this.unitPrice / this.perCarton : this.unitPrice;
    //     this.resale = line.Resale__c;
    //     this.returnType = false;
    //     this.pricingNotEnabled = false;
    //     this.cannotDelete = line.Origin__c == 'Previous WO' ? true : false;
    //     this.uomNotEnabled = false;
    //     //These have defaults on creation
    //     this.zone = line.Zone__c;
    //     this.uom = line.UOM__c;
    //     this.unitPrice = line.UnitPrice;
    //     this.shelfPrice = line.Shelf_Price__c;

    //     if(String.isNotEmpty(line.Item_Type__c)) {
    //         this.cartView = true;

    //         if(line.Item_Type__c == 'Prebook') {
    //             this.isNotPrebook = false;
    //         }

    //         if(validDiscountTypes.contains(line.Item_Type__c)) {
    //             this.discountNotEnabled = !this.productDiscountEnabled;
    //         }

    //         if(groupedTypes.contains(line.Item_Type__c)) {
    //             this.pricingNotEnabled = true;
    //         }

    //         if(line.Item_Type__c == 'POS Placement') {
    //             this.uomNotEnabled = true;
    //         }

    //         if(line.Item_Type__c == 'Return') {
    //             this.returnType = true;
    //         }
    //     }
    // }

}