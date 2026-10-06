/**
 * @author Qiyuan Dou
 * @date 6/2/2023
 * @description update inventory avg price by advanced order items
 */
public with sharing class TPB_UpdateInvPriceByAdOrderItemBatch implements Database.Batchable<sObject> {
  private static final String RETAILERCASHSALE = 'Cash Sale';
  private static final String RETAILERRETURN = 'Return';
  //Advanced Order Item Unit: Each, UoM: Each
  private static final String CONSUMERUNITEACH = 'ConsumerUnit';
  //Advanced Order Item Unit: Carton, UoM: Carton
  private static final String SALESUNITCARTON = 'SalesUnit';
  //Advanced Order Phase: Released
  private static final String RELEASEDADORDER = 'Released';
  private String query;
  // add all OrderitemPrice
  private Map<String, Double> mapAllOrderitemPrice = new Map<String, Double>();
  // run Test Class
  public Boolean isRunTest = false;
  //AdOrderId list
  private Set<Id> orderIds;
  //Product Group Ids
  private Set<Id> setProductGroupIds;

  /**
   * @description Constructor class
   * @param  mapAllOrderitemPrice  Map<String, Double>
   * @param  isRunTest             Boolean
   * @param  strRunDate            Boolean
   * @param  setProductGroupIds    statement
   */
  public TPB_UpdateInvPriceByAdOrderItemBatch(
    Map<String, Double> mapAllOrderitemPrice,
    Boolean isRunTest,
    String strRunDate,
    Set<Id> setProductGroupIds
  ) {
    //Query purchase order item which is created in TODAY
    this.mapAllOrderitemPrice = mapAllOrderitemPrice;
    this.isRunTest = isRunTest;
    this.setProductGroupIds = setProductGroupIds;
    if (strRunDate == null || strRunDate == '') {
      if (setProductGroupIds != null && setProductGroupIds.size() > 0) {
        this.query = 'SELECT Id, cgcloud__Order_Item_Template__r.Name, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c, TPB_StateClassId__c, cgcloud__Order__r.cgcloud__Order_Account__r.ShippingState, cgcloud__Product__r.cgcloud__Criterion_5_Product__c, TPB_MaxPrice__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__r.cgcloud__Phase__c = :RELEASEDADORDER AND cgcloud__Order_Item_Template__r.Name = :RETAILERRETURN AND ((cgcloud__Product__r.cgcloud__Criterion_5_Product__c IN: setProductGroupIds) OR (cgcloud__Product__r.cgcloud__Criterion_5_Product__c NOT IN: setProductGroupIds AND cgcloud__UoM__c = : SALESUNITCARTON)) AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = false';
      } else {
        this.query = 'SELECT Id, cgcloud__Order_Item_Template__r.Name, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c, TPB_StateClassId__c, cgcloud__Order__r.cgcloud__Order_Account__r.ShippingState, cgcloud__Product__r.cgcloud__Criterion_5_Product__c, TPB_MaxPrice__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__r.cgcloud__Phase__c = :RELEASEDADORDER AND cgcloud__Order_Item_Template__r.Name = :RETAILERRETURN AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = false';
      }
    } else {
      if (setProductGroupIds != null && setProductGroupIds.size() > 0) {
        this.query =
          'SELECT Id, cgcloud__Order_Item_Template__r.Name, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c, TPB_StateClassId__c, cgcloud__Order__r.cgcloud__Order_Account__r.ShippingState, cgcloud__Product__r.cgcloud__Criterion_5_Product__c, TPB_MaxPrice__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__r.cgcloud__Release_Time__c = ' +
          strRunDate +
          ' AND cgcloud__Order__r.cgcloud__Phase__c = :RELEASEDADORDER AND cgcloud__Order_Item_Template__r.Name = :RETAILERRETURN AND ((cgcloud__Product__r.cgcloud__Criterion_5_Product__c IN: setProductGroupIds) OR (cgcloud__Product__r.cgcloud__Criterion_5_Product__c NOT IN: setProductGroupIds AND cgcloud__UoM__c = : SALESUNITCARTON)) AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = false';
      } else {
        this.query =
          'SELECT Id, cgcloud__Order_Item_Template__r.Name, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c, TPB_StateClassId__c, cgcloud__Order__r.cgcloud__Order_Account__r.ShippingState, cgcloud__Product__r.cgcloud__Criterion_5_Product__c, TPB_MaxPrice__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__r.cgcloud__Release_Time__c = ' +
          strRunDate +
          ' AND cgcloud__Order__r.cgcloud__Phase__c = :RELEASEDADORDER AND cgcloud__Order_Item_Template__r.Name = :RETAILERRETURN AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = false';
      }
    }
  }

  /**
   * @description Constructor class
   * @param  orderIds  Set<Id>
   * @param  isRunTest Boolean
   * @param  setProductGroupIds    statement
   */
  public TPB_UpdateInvPriceByAdOrderItemBatch(
    Set<Id> orderIds,
    Boolean isRunTest,
    Set<Id> setProductGroupIds
  ) {
    //Query purchase order item which is created in TODAY
    if (orderIds != null && orderIds.size() > 0) {
      this.isRunTest = isRunTest;
      this.orderIds = orderIds;
      this.setProductGroupIds = setProductGroupIds;
      if (setProductGroupIds != null && setProductGroupIds.size() > 0) {
        this.query = 'SELECT Id, cgcloud__Order_Item_Template__r.Name, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c, TPB_StateClassId__c, cgcloud__Order__r.cgcloud__Order_Account__r.ShippingState, cgcloud__Product__r.cgcloud__Criterion_5_Product__c, TPB_MaxPrice__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c IN : orderIds AND cgcloud__Order__r.cgcloud__Phase__c = :RELEASEDADORDER AND cgcloud__Order_Item_Template__r.Name = :RETAILERRETURN AND ((cgcloud__Product__r.cgcloud__Criterion_5_Product__c IN: setProductGroupIds) OR (cgcloud__Product__r.cgcloud__Criterion_5_Product__c NOT IN: setProductGroupIds AND cgcloud__UoM__c = : SALESUNITCARTON)) AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = false';
      } else {
        this.query = 'SELECT Id, cgcloud__Order_Item_Template__r.Name, cgcloud__Base_Price__c, cgcloud__Special_Price__c, cgcloud__UoM__c, TPB_StateClassId__c, cgcloud__Order__r.cgcloud__Order_Account__r.ShippingState, cgcloud__Product__r.cgcloud__Criterion_5_Product__c, TPB_MaxPrice__c FROM cgcloud__Order_Item__c WHERE cgcloud__Order__c IN : orderIds AND cgcloud__Order__r.cgcloud__Phase__c = :RELEASEDADORDER AND cgcloud__Order_Item_Template__r.Name = :RETAILERRETURN AND cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c = false';
      }
    }
  }

  /**
   * @description   Constructor class
   * @param  query  Query statement
   * @param  mapAllOrderitemPrice  Map<String, Double>
   * @param  isRunTest             Boolean
   */
  public TPB_UpdateInvPriceByAdOrderItemBatch(
    String query,
    Map<String, Double> mapAllOrderitemPrice,
    Boolean isRunTest
  ) {
    //Creating a Parametric Construction Method
    this.query = query;
    this.mapAllOrderitemPrice = mapAllOrderitemPrice;
    this.isRunTest = isRunTest;
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
   * @param  bc      bc description
   * @param  lstAdOrderItem description
   */
  public void execute(
    Database.BatchableContext bc,
    List<cgcloud__Order_Item__c> lstAdOrderItem
  ) {
    //List of inventory for update
    List<cgcloud__Inventory__c> lstInvToUpdate = new List<cgcloud__Inventory__c>();
    //Create a map(stateClassId, maxPrice) to store the current maximum price by state and class key for inventory with state
    Map<String, Double> mapStateClassId2Price = new Map<String, Double>();
    //Create a list: stateClassId to store the orderitem's state and class for subsequent inventory condition queries
    List<String> lstStateClassId = new List<String>();
    //Query product for UoM
    List<String> lstProduct2Id = new List<String>();
    List<String> lstGroupProduct2Id = new List<String>();
    for (cgcloud__Order_Item__c objAdOrderItem : lstAdOrderItem) {
      if (
        objAdOrderItem.cgcloud__Product__r.cgcloud__Criterion_5_Product__c !=
        null
      ) {
        lstGroupProduct2Id.add(
          objAdOrderItem.cgcloud__Product__r.cgcloud__Criterion_5_Product__c
        );
      }
      lstProduct2Id.add(objAdOrderItem.cgcloud__Product__c);
    }
    //save Carton cgcloud__Pieces_per_Smallest_Unit__c value
    Map<String, Double> mapStateClassSmallestUnit = new Map<String, Double>();
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
        objUoM.cgcloud__Unit_Type__c == SALESUNITCARTON
      ) {
        mapStateClassSmallestUnit.put(
          objUoM.cgcloud__Product__c,
          objUoM.cgcloud__Pieces_per_Smallest_Unit__c
        );
      }
    }
    //Carton unit price in current order item
    Double currentAdOrderItemMaxPrice;
    //Store each, carton quantitative relationship
    Double numEachCarton;
    Double basePrice;
    //Store current order item state + class
    String stateClassId;
    String classId;
    for (cgcloud__Order_Item__c adOrderIt : lstAdOrderItem) {
      if (
        adOrderIt.cgcloud__Order_Item_Template__r.Name == RETAILERRETURN &&
        adOrderIt.cgcloud__Base_Price__c != 0
      ) {
        continue;
      }
      //Order item state and class
      stateClassId = adOrderIt.TPB_StateClassId__c;
      //Orde item class
      classId = adOrderIt.cgcloud__Product__r.cgcloud__Criterion_5_Product__c;
      //Get all UoM
      List<cgcloud__Unit_of_Measure__c> lstUoMFromMap = mapPrdId2UoM.get(
        adOrderIt.cgcloud__Product__c
      );
      for (cgcloud__Unit_of_Measure__c objUoM : lstUoMFromMap) {
        //Store current product UoM unit price
        if (objUoM.cgcloud__Unit_Type__c == SALESUNITCARTON) {
          numEachCarton = objUoM.cgcloud__Pieces_per_Smallest_Unit__c;
        }
      }
      basePrice = adOrderIt.cgcloud__Special_Price__c == 0
        ? adOrderIt.cgcloud__Base_Price__c
        : adOrderIt.cgcloud__Special_Price__c;
      //if each, multiply
      if (adOrderIt.cgcloud__UoM__c == CONSUMERUNITEACH) {
        currentAdOrderItemMaxPrice = basePrice * numEachCarton;
      } else {
        currentAdOrderItemMaxPrice = basePrice;
      }
      //Store the highest price of the current state and class
      if (
        !mapStateClassId2Price.containsKey(stateClassId) ||
        mapStateClassId2Price.get(stateClassId) < currentAdOrderItemMaxPrice
      ) {
        mapStateClassId2Price.put(stateClassId, currentAdOrderItemMaxPrice);
        //Storing stateClassId in the list is convenient for the follow-up inventory with state query
        lstStateClassId.add(stateClassId);
      }
    }
    //Query Inventory
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
        TPB_StateClassId__c IN :lstStateClassId
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
        if (
          mapAllOrderitemPrice.containsKey(invStateClassId) &&
          mapAllOrderitemPrice.get(invStateClassId) >
          mapStateClassId2Price.get(invStateClassId)
        ) {
          currentMapPrice = mapAllOrderitemPrice.get(invStateClassId);
        }
      }
      if (currentMapPrice < objInventory.TPB_AvgPrice__c) {
        continue;
      }
      //Update price
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
          stage.uomType = CONSUMERUNITEACH;
        } else {
          stage.uomType = SALESUNITCARTON;
          stage.basePrice = objInventory.TPB_AvgPrice__c;
        }
        stage.productGroupId = objInventory.cgcloud__Product__r.cgcloud__Criterion_5_Product__c;
        stage.productId = objInventory.cgcloud__Product__c;
        stage.userId = objInventory.cgcloud__User__c;
        stage.state = objInventory.TPB_Tour_State__c;
        stages.put(objInventory.TPB_StateClassId__c, stage);
      }
    }
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
  }
}