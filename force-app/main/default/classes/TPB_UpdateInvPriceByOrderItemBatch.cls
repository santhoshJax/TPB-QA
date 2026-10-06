/**
 * @author Qiyuan Dou
 * @date 6/2/2023
 * @description update inventory avg price by order items
 */
public with sharing class TPB_UpdateInvPriceByOrderItemBatch implements Database.Batchable<sObject>, Database.Stateful {
  //Order Item Type: Purchase
  private static final String WHOLESALERPURCHASE = 'Purchase';
  //Order Item Unit: Each
  private static final String ORDEREACHTYPE = 'Each';
  //UoM: Each
  private static final String UOMEACH = 'ConsumerUnit';
  //Order Item Unit: Carton
  private static final String ORDERCARTONTYPE = 'Carton';
  //UoM: Carton
  private static final String UOMCARTON = 'SalesUnit';
  //Order Item Unit: Case
  private static final String ORDERCASETYPE = 'Case';
  //UoM: Case
  private static final String UOMCASE = 'Layer';
  //Active Order
  private static final String ACTIVEORDER = 'Activated';
  // Order DeveloperName Van_Load
  private static final String RECORDTYPENAME = 'Van_Load';
  // add all OrderitemPrice
  private Map<String, Double> mapAllOrderitemPrice = new Map<String, Double>();
  //OrderId list
  private Set<Id> orderIds;
  // query
  private String query;
  // run Test Class
  public Boolean isRunTest = false;
  // batch query data time
  public String strRunDate = 'TODAY';
  //Product Group Ids
  private Set<Id> setProductGroupIds;

  /**
   * @description Constructor class
   * @param  strRunDate   statement
   * @param  isRunTest    statement
   * @param  setProductGroupIds    statement
   */
  public TPB_UpdateInvPriceByOrderItemBatch(
    String strRunDate,
    Boolean isRunTest,
    Set<Id> setProductGroupIds
  ) {
    //Query purchase order item which is created in TODAY
    this.strRunDate = strRunDate;
    this.isRunTest = isRunTest;
    this.setProductGroupIds = setProductGroupIds;
    if (strRunDate == null || strRunDate == '') {
      if (setProductGroupIds != null && setProductGroupIds.size() > 0) {
        this.query = 'SELECT Id, UoM__c, Product2Id, TPB_StateClassId__c, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c, UnitPrice FROM OrderItem WHERE TPB_Type__c = :WHOLESALERPURCHASE AND Order.Status = :ACTIVEORDER AND ((Product2.cgcloud__Criterion_5_Product__c IN: setProductGroupIds) OR (Product2.cgcloud__Criterion_5_Product__c NOT IN: setProductGroupIds AND UoM__c = : ORDERCARTONTYPE)) AND Order.RecordType.DeveloperName = :RECORDTYPENAME AND Product2.TPB_Exclude_From_Base_Pricing__c = false';
      } else {
        this.query = 'SELECT Id, UoM__c, Product2Id, TPB_StateClassId__c, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c, UnitPrice FROM OrderItem WHERE TPB_Type__c = :WHOLESALERPURCHASE AND Order.Status = :ACTIVEORDER AND Order.RecordType.DeveloperName = :RECORDTYPENAME AND Product2.TPB_Exclude_From_Base_Pricing__c = false';
      }
    } else {
      if (setProductGroupIds != null && setProductGroupIds.size() > 0) {
        this.query =
          'SELECT Id, UoM__c, Product2Id, TPB_StateClassId__c, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c, UnitPrice FROM OrderItem WHERE Order.ActivatedDate = ' +
          strRunDate +
          ' AND TPB_Type__c = :WHOLESALERPURCHASE AND Order.Status = :ACTIVEORDER AND ((Product2.cgcloud__Criterion_5_Product__c IN: setProductGroupIds) OR (Product2.cgcloud__Criterion_5_Product__c NOT IN: setProductGroupIds AND UoM__c = : ORDERCARTONTYPE)) AND Order.RecordType.DeveloperName = :RECORDTYPENAME AND Product2.TPB_Exclude_From_Base_Pricing__c = false';
      } else {
        this.query =
          'SELECT Id, UoM__c, Product2Id, TPB_StateClassId__c, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c, UnitPrice FROM OrderItem WHERE Order.ActivatedDate = ' +
          strRunDate +
          ' AND TPB_Type__c = :WHOLESALERPURCHASE AND Order.Status = :ACTIVEORDER AND Order.RecordType.DeveloperName = :RECORDTYPENAME AND Product2.TPB_Exclude_From_Base_Pricing__c = false';
      }
    }
  }

  /**
   * @description Constructor class
   * @param  orderIds description
   * @param  isRunTest description
   * @param  setProductGroupIds    statement
   */
  public TPB_UpdateInvPriceByOrderItemBatch(
    Set<Id> orderIds,
    Boolean isRunTest,
    Set<Id> setProductGroupIds
  ) {
    //Creating a Parametric Construction Method
    if (orderIds != null && orderIds.size() > 0) {
      this.orderIds = orderIds;
      this.isRunTest = isRunTest;
      this.setProductGroupIds = setProductGroupIds;
      if (setProductGroupIds != null && setProductGroupIds.size() > 0) {
        this.query = 'SELECT Id, UoM__c, Product2Id, TPB_StateClassId__c, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c, UnitPrice FROM OrderItem WHERE OrderId IN : orderIds AND TPB_Type__c = :WHOLESALERPURCHASE AND Order.Status = :ACTIVEORDER AND ((Product2.cgcloud__Criterion_5_Product__c IN: setProductGroupIds) OR (Product2.cgcloud__Criterion_5_Product__c NOT IN: setProductGroupIds AND UoM__c = : ORDERCARTONTYPE)) AND Order.RecordType.DeveloperName = :RECORDTYPENAME AND Product2.TPB_Exclude_From_Base_Pricing__c = false';
      } else {
        this.query = 'SELECT Id, UoM__c, Product2Id, TPB_StateClassId__c, Order.TPB_State__c, Product2.cgcloud__Criterion_5_Product__c, UnitPrice FROM OrderItem WHERE OrderId IN : orderIds AND TPB_Type__c = :WHOLESALERPURCHASE AND Order.Status = :ACTIVEORDER AND Order.RecordType.DeveloperName = :RECORDTYPENAME AND Product2.TPB_Exclude_From_Base_Pricing__c = false';
      }
    }
  }

  /**
   * @description start description
   * @param  bc bc description
   * @return    return description
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  /**
   * @description execute description
   * @param  bc description
   * @param  lstOrderItem  description
   */
  public void execute(
    Database.BatchableContext bc,
    List<OrderItem> lstOrderItem
  ) {
    //List of inventory for update
    List<cgcloud__Inventory__c> lstInvToUpdate = new List<cgcloud__Inventory__c>();
    //Create a map(stateClassId, maxPrice) to store the current maximum price by state and class key for inventory
    Map<String, Double> mapStateClassId2Price = new Map<String, Double>();
    //Query product for UoM
    List<String> lstProduct2Id = new List<String>();
    List<String> lstGroupProduct2Id = new List<String>();
    for (OrderItem objOrderItem : lstOrderItem) {
      if (objOrderItem.Product2.cgcloud__Criterion_5_Product__c != null) {
        lstGroupProduct2Id.add(
          objOrderItem.Product2.cgcloud__Criterion_5_Product__c
        );
      }
      lstProduct2Id.add(objOrderItem.Product2Id);
    }
    //Query all related UoM by Product
    List<cgcloud__Unit_of_Measure__c> lstUoM = new List<cgcloud__Unit_of_Measure__c>();
    lstUoM = [
      SELECT
        Id,
        cgcloud__Unit_Type__c,
        cgcloud__Product__c,
        cgcloud__Pieces_per_Smallest_Unit__c
      FROM cgcloud__Unit_of_Measure__c
      WHERE
        cgcloud__Product__c IN :lstProduct2Id
        OR cgcloud__Product__r.cgcloud__Criterion_5_Product__c IN :lstGroupProduct2Id
    ];
    //add Carton cgcloud__Pieces_per_Smallest_Unit__c value
    Map<String, Double> mapStateClassSmallestUnit = new Map<String, Double>();
    //Map product Id to UoM
    Map<String, List<cgcloud__Unit_of_Measure__c>> mapPrdId2UoM = new Map<String, List<cgcloud__Unit_of_Measure__c>>();
    for (cgcloud__Unit_of_Measure__c objUoM : lstUoM) {
      if (!mapPrdId2UoM.containsKey(objUoM.cgcloud__Product__c)) {
        mapPrdId2UoM.put(
          objUoM.cgcloud__Product__c,
          new List<cgcloud__Unit_of_Measure__c>()
        );
      }
      mapPrdId2UoM.get(objUoM.cgcloud__Product__c).add(objUoM);
      //add all Product Uom Data
      if (
        !mapStateClassSmallestUnit.containsKey(objUoM.cgcloud__Product__c) &&
        objUoM.cgcloud__Unit_Type__c == UOMCARTON
      ) {
        mapStateClassSmallestUnit.put(
          objUoM.cgcloud__Product__c,
          objUoM.cgcloud__Pieces_per_Smallest_Unit__c
        );
      }
    }
    //Carton unit price in current order item
    Double currentOrderItemMaxPrice;
    //Store each, carton, case quantitative relationship
    Double numEachCarton;
    Double numEachCase;
    //Store current order item state + class
    String stateClassId;
    String classId;
    for (OrderItem orderIt : lstOrderItem) {
      //Order item state and class
      stateClassId = orderIt.TPB_StateClassId__c;
      //Orde item class
      classId = orderIt.Product2.cgcloud__Criterion_5_Product__c;
      //Get all UoM
      List<cgcloud__Unit_of_Measure__c> lstUoMFromMap = mapPrdId2UoM.get(
        orderIt.Product2Id
      );
      for (cgcloud__Unit_of_Measure__c objUoM : lstUoMFromMap) {
        //Store current product UoM unit price
        if (objUoM.cgcloud__Unit_Type__c == UOMCARTON) {
          numEachCarton = objUoM.cgcloud__Pieces_per_Smallest_Unit__c;
        } else if (objUoM.cgcloud__Unit_Type__c == UOMCASE) {
          numEachCase = objUoM.cgcloud__Pieces_per_Smallest_Unit__c;
        }
      }
      //if each, multiply
      if (orderIt.UoM__c == ORDEREACHTYPE) {
        currentOrderItemMaxPrice = orderIt.UnitPrice * numEachCarton;
      } else if (orderIt.UoM__c == ORDERCASETYPE) {
        //if each, divide first to get each, then multiply to get carton
        currentOrderItemMaxPrice =
          orderIt.UnitPrice /
          numEachCase *
          numEachCarton;
      } else {
        currentOrderItemMaxPrice = orderIt.UnitPrice;
      }
      //Store the highest price of the current state and class
      if (
        !mapStateClassId2Price.containsKey(stateClassId) ||
        mapStateClassId2Price.get(stateClassId) < currentOrderItemMaxPrice
      ) {
        mapStateClassId2Price.put(stateClassId, currentOrderItemMaxPrice);
      }
    }
    //Query Inventory by state + class
    List<cgcloud__Inventory__c> lstInv = [
      SELECT
        Id,
        TPB_AvgPrice__c,
        TPB_StateClassId__c,
        cgcloud__Product__c,
        cgcloud__Product__r.cgcloud__Criterion_5_Product__c,
        cgcloud__User__c,
        TPB_Tour_State__c
      FROM cgcloud__Inventory__c
      WHERE
        TPB_StateClassId__c IN :mapStateClassId2Price.keySet()
        AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = FALSE
    ];

    Map<String, TPB_PricingStage> stages = new Map<String, TPB_PricingStage>();
    for (cgcloud__Inventory__c objInventory : lstInv) {
      //Get inventory state + class
      String invStateClassId = objInventory.TPB_StateClassId__c;
      //Get the current highest price according to mapAdvancedClassId2Price map
      Double currentMapPrice = 0;
      if (mapStateClassId2Price.containsKey(invStateClassId)) {
        currentMapPrice = mapStateClassId2Price.get(invStateClassId);
      }
      if (currentMapPrice < objInventory.TPB_AvgPrice__c) {
        continue;
      }
      //Update inventory price
      objInventory.TPB_AvgPrice__c = currentMapPrice;
      //Store the final updated list
      lstInvToUpdate.add(objInventory);
      if (!stages.containsKey(objInventory.TPB_StateClassId__c)) {
        TPB_PricingStage stage = new TPB_PricingStage();
        if (
          mapStateClassSmallestUnit.containsKey(
            objInventory.cgcloud__Product__c
          )
        ) {
          stage.basePrice =
            objInventory.TPB_AvgPrice__c /
            mapStateClassSmallestUnit.get(objInventory.cgcloud__Product__c);
          stage.uomType = UOMEACH;
        } else {
          stage.basePrice = objInventory.TPB_AvgPrice__c;
          stage.uomType = UOMCARTON;
        }
        stage.productGroupId = objInventory.cgcloud__Product__r.cgcloud__Criterion_5_Product__c;
        stage.productId = objInventory.cgcloud__Product__c;
        stage.userId = objInventory.cgcloud__User__c;
        stage.state = objInventory.TPB_Tour_State__c;
        stages.put(objInventory.TPB_StateClassId__c, stage);
      }
    }
    mapAllOrderitemPrice.putAll(mapStateClassId2Price);
    //Update
    if (lstInvToUpdate.size() > 0) {
      update lstInvToUpdate;
    }

    if (stages.size() > 0) {
      TPB_PricingUtility.upsertPricingConditionStage(stages);
    }
  }

  /**
   * @description finish description
   * @param  bc bc description
   */
  public void finish(Database.BatchableContext bc) {
    // execute ad order item batch
    if (!isRunTest) {
      TPB_UpdateInvPriceByAdOrderItemBatch ad = new TPB_UpdateInvPriceByAdOrderItemBatch(
        mapAllOrderitemPrice,
        isRunTest,
        strRunDate,
        setProductGroupIds
      );
      Database.executeBatch(ad);
    }
  }
}