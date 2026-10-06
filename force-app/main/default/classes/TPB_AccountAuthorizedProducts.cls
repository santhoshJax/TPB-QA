/**
 * @author Mi Li
 * @date 5/15/2023
 * @description CON0001729-300: Product Capture at HQ and Wholesale
 */
public with sharing class TPB_AccountAuthorizedProducts {
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;
  /**
   * @description Query current Account_Product__c and Product2 data
   * @param   accountId       String
   * @param   strRecordType   String
   * @return  finalWrapper  List<TPB_AccountAuthorizedProductsWrapper>
   */
  @AuraEnabled
  public static List<TPB_AccountAuthorizedProductsWrapper> searchProducts(
    Id accountId,
    String strRecordType
  ) {
    List<TPB_AccountAuthorizedProductsWrapper> finalWrapper = new List<TPB_AccountAuthorizedProductsWrapper>();
    Map<Id, Account_Product__c> accProdMap = new Map<Id, Account_Product__c>();
    Map<Id, Product2> accProdBrandMap = new Map<Id, Product2>();
    try {
      //Query Account_Product__c information
      for (Account_Product__c accProd : [
        SELECT
          Id,
          Name,
          Product__c,
          SKU__c,
          Product__r.Name,
          Product__r.cgcloud__Product_Level__c,
          Status__c
        FROM Account_Product__c
        WHERE Account__c = :accountId
      ]) {
        accProdMap.put(accProd.Product__c, accProd);
      }

      //Query cgcloud__Product_Level__c = 'Flavor' Product2 information
      for (Product2 prod : [
        SELECT Id, Name, Item_ID__c, cgcloud__Product_Level__c
        FROM Product2
        WHERE cgcloud__Product_Level__c = 'Flavor'
        ORDER BY cgcloud__Product_Level__c ASC, Product2.Sort_Order__c ASC
      ]) {
        accProdBrandMap.put(prod.Id, prod);
      }

      //Query cgcloud__Criterion_4_Product__c IN: accProdBrandMap  Product2 information
      if (accProdBrandMap.size() > 0) {
        List<Product2> lstProduct2 = [
          SELECT
            Id,
            Name,
            Item_ID__c,
            cgcloud__Product_Level__c,
            cgcloud__Criterion_4_Product__r.Name,
            cgcloud__Criterion_4_Product__r.Sort_Order__c,
            cgcloud__Criterion_4_Product__c
          FROM Product2
          WHERE
            cgcloud__Criterion_4_Product__c IN :accProdBrandMap.KeySet()
            AND cgcloud__Product_Level__c = 'Product'
          ORDER BY
            cgcloud__Criterion_4_Product__r.Sort_Order__c ASC,
            Product2.Sort_Order__c ASC
        ];
        for (Product2 prod : lstProduct2) {
          //get Account_Product__c data
          Account_Product__c accProd = accProdMap.get(prod.Id);
          //Packaging Method
          TPB_AccountAuthorizedProductsWrapper wrapper = new TPB_AccountAuthorizedProductsWrapper(
            prod,
            accProd,
            accountId,
            strRecordType
          );
          finalWrapper.add(wrapper);
        }
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return data
    return finalWrapper;
  }

  /**
   * @description Insert or update data
   * @param   rawProducts    String
   * @param   accountId      String
   * @return  String
   */
  @AuraEnabled
  public static String upsertProducts(String rawProducts, Id accountId) {
    //Receive conversion data
    List<TPB_AccountAuthorizedProductsWrapper> items = (List<TPB_AccountAuthorizedProductsWrapper>) JSON.deserialize(
      rawProducts,
      List<TPB_AccountAuthorizedProductsWrapper>.class
    );
    List<Account_Product__c> accProdUpserts = new List<Account_Product__c>();

    //Save modified data
    for (TPB_AccountAuthorizedProductsWrapper wrapper : items) {
      Account_Product__c accProd = new Account_Product__c();
      //Update
      if (wrapper.recordId != null) {
        accProd.Id = wrapper.recordId;
      } else {
        // insert
        accProd.Account__c = accountId;
        accProd.Product__c = wrapper.productId;
      }

      //save Status__c
      if (wrapper.applied != true) {
        accProd.Status__c = 'No';
      } else {
        accProd.Status__c = 'Yes';
      }
      // save SKU__c
      if (wrapper.itemCode != null) {
        accProd.SKU__c = wrapper.itemCode;
      }
      //save data
      accProd.Unique_Id__c = accountId + '-' + wrapper.productId;
      accProdUpserts.add(accProd);
    }

    //Data Rollback
    Savepoint sp = Database.setSavepoint();
    try {
      // upsert data
      upsert accProdUpserts Unique_Id__c;
    } catch (DmlException objEx) {
      Database.rollback(sp);

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return data
    return 'SUCCESS';
  }
}