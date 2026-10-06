/**
 * @author Mi Li
 * @date 5/15/2023
 * @description CON0001729-300: Product Capture at HQ and Wholesale
 */
public with sharing class TPB_AccountAuthorizedProductsWrapper {
  //recordId
  @AuraEnabled
  public String recordId;
  //family
  @AuraEnabled
  public String family;
  //applied
  @AuraEnabled
  public Boolean applied;
  //name
  @AuraEnabled
  public String name;
  //itemCode
  @AuraEnabled
  public String itemCode;
  //productId
  @AuraEnabled
  public String productId;
  //accountId
  @AuraEnabled
  public String accountId;

  /**
   * @description
   * @param   prod           Product2
   * @param   accProd        Account_Product__c
   * @param   accountId      Id
   * @param   strRecordType  String
   */
  public TPB_AccountAuthorizedProductsWrapper(
    Product2 prod,
    Account_Product__c accProd,
    Id accountId,
    String strRecordType
  ) {
    //Receiving parameter assignment
    this.name = prod.Name;
    this.productId = prod.Id;
    this.accountId = accountId;
    this.family = prod.cgcloud__Criterion_4_Product__r.Name;

    //Determine if Account_Product__c is empty
    if (accProd != null) {
      this.recordId = accProd.Id;
      this.applied = accProd.Status__c == 'No' ? false : true;
      //Determine if SKU__c is empty
      this.itemCode = (accProd.SKU__c != null &&
        this.applied &&
        strRecordType == 'Wholesaler')
        ? accProd.SKU__c
        : null;
    } else {
      //Default value is empty
      this.recordId = null;
      this.applied = false;
      this.itemCode = null;
    }
  }
}