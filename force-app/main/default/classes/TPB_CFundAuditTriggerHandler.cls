/**
 * @author: Mi Li
 * date:6/29/2023
 * @description  CFund Audit Trigger
 */
public without sharing class TPB_CFundAuditTriggerHandler extends SDF_TGF_TriggerHandler {
  /**
   * @description afterUpdate description
   */
  protected override void afterUpdate() {
    //get CFundAudit new data
    List<TPB_CFund_Audit__c> lstCFundAuditNew = (List<TPB_CFund_Audit__c>) Trigger.new;
    //get CFundAudit old data
    List<TPB_CFund_Audit__c> lstCFundAuditOld = (List<TPB_CFund_Audit__c>) Trigger.old;

    //add update CFundAudit
    Set<String> setCFundAuditId = new Set<String>();
    for (Integer intSize = 0; intSize < lstCFundAuditNew.size(); intSize++) {
      //When the value of any of the following fields changes
      if (
        (lstCFundAuditOld[intSize].TPB_Status__c == 'Draft' &&
        lstCFundAuditNew[intSize].TPB_Status__c == 'Approved') ||
        (lstCFundAuditOld[intSize].TPB_Status__c == 'Approval In Progress' &&
        lstCFundAuditNew[intSize].TPB_Status__c == 'Approved')
      ) {
        setCFundAuditId.add(lstCFundAuditNew[intSize].Id);
      }
    }
    //insert or update inventory
    if (setCFundAuditId.size() > 0) {
      //upsert Inventory Data
      upsertInventoryData(setCFundAuditId);
    }
  }

  /**
   * @description get CFund Audit Product  description
   * @param   setCFundAuditId  Set<String>
   * @return  lstCFundAuditProduct List<TPB_CFund_Audit_Product__c> description
   */
  private List<TPB_CFund_Audit_Product__c> getCFundAuditProduct(
    Set<String> setCFundAuditId
  ) {
    //query TPB_CFund_Audit_Product__c data
    List<TPB_CFund_Audit_Product__c> lstCFundAuditProduct = [
      SELECT
        Id,
        CreatedById,
        TPB_Actual_Product__c,
        TPB_Quantity__c,
        TPB_CFund_Audit__c,
        TPB_Expected_Quantity__c,
        TPB_State__c,
        TPB_Actual_Product__r.TPB_Exclude_From_Base_Pricing__c
      FROM TPB_CFund_Audit_Product__c
      WHERE TPB_CFund_Audit__c IN :setCFundAuditId AND TPB_Variance__c != 0
    ];

    // return lstCFundAuditProduct data
    return lstCFundAuditProduct;
  }

  /**
   * @description get Tour  description
   * @param   tourMap Map<String, cgcloud__Tour__c> description
   * @return  lstTours List<cgcloud__Tour__c> description
   */
  private List<cgcloud__Tour__c> getTour(
    Map<String, cgcloud__Tour__c> tourMap
  ) {
    //Query Tour data
    List<cgcloud__Tour__c> lstTours = [
      SELECT Id, cgcloud__Start_Warehouse__r.cgcloud__State__c
      FROM cgcloud__Tour__c
      WHERE cgcloud__Start_Warehouse__r.cgcloud__State__c IN :tourMap.keySet()
    ];

    //return lstTours data
    return lstTours;
  }

  /**
   * @description get Inventory Control Template  description
   * @return  lstInvTemplates  List<cgcloud__Inventory_Control_Template__c> description
   */
  private List<cgcloud__Inventory_Control_Template__c> getInventoryControlTemplate() {
    //query cgcloud__Inventory_Control_Template__c data
    List<cgcloud__Inventory_Control_Template__c> lstInvTemplates = [
      SELECT Id
      FROM cgcloud__Inventory_Control_Template__c
      WHERE Name = 'TPB Control Template' AND cgcloud__Active__c = TRUE
      LIMIT 1
    ];

    //return lstInvTemplates data
    return lstInvTemplates;
  }

  /**
   * @description get Inventory Transaction Template  description
   * @return  invTransTemplates  List<cgcloud__Inventory_Transaction_Template__c> description
   */
  private List<cgcloud__Inventory_Transaction_Template__c> getInventoryTransactionTemplate() {
    //query cgcloud__Inventory_Transaction_Template__c data
    List<cgcloud__Inventory_Transaction_Template__c> invTransTemplates = [
      SELECT Id
      FROM cgcloud__Inventory_Transaction_Template__c
      WHERE
        Name IN (
          'TPB Transaction Template (Cashsale)',
          'TPB Transaction Template (Add)'
        )
        AND cgcloud__Active__c = TRUE
      ORDER BY Name
      LIMIT 2
    ];

    //return lstInvTemplates data
    return invTransTemplates;
  }

  /**
   * @description get Inventory  description
   * @param   invMap Map<String, cgcloud__Inventory__c> description
   * @return  inventories  List<cgcloud__Inventory__c> description
   */
  private List<cgcloud__Inventory__c> getInventory(
    Map<String, cgcloud__Inventory__c> invMap
  ) {
    //Query Inventory data
    List<cgcloud__Inventory__c> inventories = [
      SELECT Id, cgcloud__Product__c, TPB_PricingMergedKey__c
      FROM cgcloud__Inventory__c
      WHERE TPB_PricingMergedKey__c IN :invMap.keySet()
    ];

    //return lstInvTemplates data
    return inventories;
  }

  /**
   * @description upsert Inventory Data description
   * @param  setCFundAuditId Set<String>
   */
  public void upsertInventoryData(Set<String> setCFundAuditId) {
    //Query the CFund_Audit_Product data that matches the criteria
    List<TPB_CFund_Audit_Product__c> lstCFundAuditProduct = getCFundAuditProduct(
      setCFundAuditId
    );
    if (lstCFundAuditProduct.size() > 0) {
      Set<Id> productSet = new Set<Id>();
      Map<String, cgcloud__Inventory__c> invMap = new Map<String, cgcloud__Inventory__c>();
      Map<String, cgcloud__Tour__c> tourMap = new Map<String, cgcloud__Tour__c>();
      Map<String, cgcloud__Inventory__c> newInvMap = new Map<String, cgcloud__Inventory__c>();
      List<cgcloud__Inventory_Transaction__c> transList = new List<cgcloud__Inventory_Transaction__c>();
      Map<String, List<cgcloud__Inventory_Transaction__c>> newTransMap = new Map<String, List<cgcloud__Inventory_Transaction__c>>();

      //Set unique key value
      for (TPB_CFund_Audit_Product__c item : lstCFundAuditProduct) {
        String mergedKey =
          item.TPB_Actual_Product__c +
          '+' +
          item.TPB_State__c +
          '+' +
          item.CreatedById;
        productSet.add(item.TPB_Actual_Product__c);
        invMap.put(mergedKey, null);
        tourMap.put(item.TPB_State__c, null);
      }

      //Query Tour data
      List<cgcloud__Tour__c> tours = getTour(tourMap);
      tourMap.clear();
      for (cgcloud__Tour__c tour : tours) {
        tourMap.put(tour.cgcloud__Start_Warehouse__r.cgcloud__State__c, tour);
      }

      //Query Inventory Control Template data
      List<cgcloud__Inventory_Control_Template__c> invTemplates = getInventoryControlTemplate();

      //Query Inventory Transaction Template data
      List<cgcloud__Inventory_Transaction_Template__c> invTransTemplates = getInventoryTransactionTemplate();

      //Query Inventory data
      List<cgcloud__Inventory__c> inventories = getInventory(invMap);
      invMap.clear();
      for (cgcloud__Inventory__c inv : inventories) {
        invMap.put(inv.TPB_PricingMergedKey__c, inv);
      }

      //Generate Inventory or Inventory Transaction data
      for (
        TPB_CFund_Audit_Product__c item : (List<TPB_CFund_Audit_Product__c>) lstCFundAuditProduct
      ) {
        String mergedKey =
          item.TPB_Actual_Product__c +
          '+' +
          item.TPB_State__c +
          '+' +
          item.CreatedById;
        Decimal quantity = item.TPB_Quantity__c - item.TPB_Expected_Quantity__c;
        String transTemplateId = quantity > 0
          ? invTransTemplates[0].Id
          : invTransTemplates[1].Id;

        // get Inventory
        cgcloud__Inventory__c inv = invMap.get(mergedKey);
        if (inv == null) {
          inv = newInvMap.get(mergedKey);
        }
        //create Inventory
        if (inv == null) {
          inv = new cgcloud__Inventory__c(
            cgcloud__Description_Language_1__c = 'New inventory from flow'
          );
          inv.cgcloud__Inventory_Template__c = invTemplates[0].Id;
          inv.cgcloud__Phase__c = 'Active';
          inv.cgcloud__Product__c = item.TPB_Actual_Product__c;
          inv.cgcloud__Sales_Org__c = '0001';
          inv.cgcloud__Valid_From__c = Date.newInstance(2023, 6, 1);
          inv.cgcloud__Valid_Thru__c = Date.newInstance(2099, 12, 31);
          inv.cgcloud__User__c = item.CreatedById;
          inv.cgcloud__Tour__c = tourMap.get(item.TPB_State__c).Id;
          inv.TPB_AvgPrice__c = item.TPB_Actual_Product__r.TPB_Exclude_From_Base_Pricing__c ==
            true
            ? null
            : 0;
          newInvMap.put(mergedKey, inv);
        }

        //create Inventory Transaction
        cgcloud__Inventory_Transaction__c trans = new cgcloud__Inventory_Transaction__c();
        trans.cgcloud__Amount__c = quantity;
        trans.TPB_TSM_Adjustment__c = true;
        trans.cgcloud__Inventory_Transaction_Template__c = transTemplateId;
        trans.cgcloud__Inventory__c = inv.Id;

        if (trans.cgcloud__Inventory__c != null) {
          transList.add(trans);
        } else {
          List<cgcloud__Inventory_Transaction__c> transactionList = newTransMap.get(
            mergedKey
          );
          if (transactionList == null) {
            transactionList = new List<cgcloud__Inventory_Transaction__c>();
            newTransMap.put(mergedKey, transactionList);
          }
          transactionList.add(trans);
        }
      }

      //insert Inventory
      if (newInvMap.size() > 0) {
        insert newInvMap.values();
      }

      //Inventory Transaction Associated Inventory ID
      transList = addInventoryTransaction(newTransMap, newInvMap, transList);
      //insert Inventory Transaction
      if (transList.size() > 0) {
        insert transList;
      }
    }
  }

  /**
   * @description add Inventory Transaction  description
   * @param   newTransMap Map<String, List<cgcloud__Inventory_Transaction__c>> description
   * @param   newInvMap   Map<String, cgcloud__Inventory__c>   description
   * @param   transList   List<cgcloud__Inventory_Transaction__c>   description
   * @return  transList   List<cgcloud__Inventory_Transaction__c> description
   */
  private static List<cgcloud__Inventory_Transaction__c> addInventoryTransaction(
    Map<String, List<cgcloud__Inventory_Transaction__c>> newTransMap,
    Map<String, cgcloud__Inventory__c> newInvMap,
    List<cgcloud__Inventory_Transaction__c> transList
  ) {
    if (newTransMap.size() > 0) {
      for (String key : newTransMap.keySet()) {
        cgcloud__Inventory__c inv = newInvMap.get(key);
        List<cgcloud__Inventory_Transaction__c> transactionList = newTransMap.get(
          key
        );
        for (cgcloud__Inventory_Transaction__c trans : transactionList) {
          trans.cgcloud__Inventory__c = inv.Id;
          transList.add(trans);
        }
      }
    }

    //return transList data
    return transList;
  }
}