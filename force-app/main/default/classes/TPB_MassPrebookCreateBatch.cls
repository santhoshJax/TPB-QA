/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screen flow for Mass Prebook
 */
public without sharing class TPB_MassPrebookCreateBatch implements Database.Batchable<sObject>, Database.Stateful {
  private String query;
  //Receiving parameter
  private Order objOrder;
  private String strOrderId;
  //Order Type
  private String strOrderType;
  //Cancel or Complete or Update
  private String strUpdateType;

  //is run Test class
  public boolean boolRunTest = false;

  //order status cancel
  private static final String ORDER_STATUS_CANCEL = 'Cancelled';
  private static final String ORDER_STATUS_COMPLETE = 'Complete';
  private static final String ORDER_STATUS_UPDATE = 'Update';

  private static final String ORDER_TYPE = 'Promo';
  private static final String ORDER_TYPE_STOCK = 'Straight Stock';
  //Mass Prebook Order File name
  private static final String MASS_PREBOOK_ORG_UNIT_ORDER_FILE = 'MassPrebookOrderOrgUnitFile';
  private static final String MASS_PREBOOK_ORDER_FILE = 'MassPrebookOrderFile%';

  //private Double totalOrgUnitOrdered = 0;
  private Map<String, Double> mapAccOrgUnitAllocation = new Map<String, Double>();

  //Order  Van_Load recordType Id
  public static String orderMassPrebookRecordTypeId = TPB_TestFactory.orderMassPrebookRecordTypeId;

  /**
   * @description Constructor class
   * @param  objOrder        Order
   * @param  strOrderType    String
   * @param  strUpdateType   String
   * @param  boolRunTest     String
   */
  public TPB_MassPrebookCreateBatch(
    Order objOrder,
    String strOrderType,
    String strUpdateType,
    Boolean boolRunTest
  ) {
    this.objOrder = objOrder;
    this.strOrderType = strOrderType;
    this.strUpdateType = strUpdateType;
    this.boolRunTest = boolRunTest;
    this.strOrderId = objOrder.Id;
    //query ContentDocumentLink data
    this.query = 'SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId =: strOrderId AND ContentDocument.Title LIKE :MASS_PREBOOK_ORDER_FILE ORDER BY ContentDocument.Title ASC';
  }

  /**
   * @description start description
   * @param  bc description
   * @return    return description
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    //return  data
    return Database.getQueryLocator(query);
  }

  /**
   * @description  getMassPrebookOrderData
   * @param  strOrderId     String
   * @param  setAccountIds  Set<String>
   * @return lstOrderData   List<Order>
   */
  public static List<Order> getMassPrebookOrderData(
    String strOrderId,
    Set<String> setAccountIds
  ) {
    //query order data
    List<Order> lstOrderData = [
      SELECT Id, Status
      FROM Order
      WHERE
        TPB_Child_Order__c = :strOrderId
        AND AccountId IN :setAccountIds
        AND Status = 'Activated'
    ];
    //update status
    for (Order obj : lstOrderData) {
      obj.Status = 'Cancelled';
    }

    return lstOrderData;
  }

  /**
   * @description  getMassPrebookDetailData
   * @param  lstContentDocumentLink  List<ContentDocumentLink>
   * @return lstDetail    List<TPB_MassPrebookWrapper.MassPrebookDetail>
   */
  public static List<TPB_MassPrebookWrapper.MassPrebookDetail> getMassPrebookDetailData(
    List<ContentDocumentLink> lstContentDocumentLink
  ) {
    // getContentVersion
    List<ContentVersion> lstContentVersion = TPB_MassPrebookControllerUtility.getContentVersion(
      new Set<String>{ lstContentDocumentLink[0].ContentDocumentId },
      MASS_PREBOOK_ORDER_FILE
    );

    //Forced to be an internal class
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstDetail = (List<TPB_MassPrebookWrapper.MassPrebookDetail>) JSON.deserialize(
      lstContentVersion[0].VersionData.toString(),
      List<TPB_MassPrebookWrapper.MassPrebookDetail>.class
    );

    //return lstDetail data
    return lstDetail;
  }

  /**
   * @description  completeData
   * @param  lstInputItems  List<TPB_MassPrebookWrapper.MassPrebookDetail>
   */
  public void completeData(
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstInputItems
  ) {
    Set<String> setAccountId = new Set<String>();
    //search PricebookEntryProduct
    Map<String, String> mapProductPricebookEntry = TPB_MassPrebookService.searchPricebookEntryProduct(
      new Set<String>{ objOrder.TPB_Mass_Prebook_Product__c }
    );
    for (TPB_MassPrebookWrapper.MassPrebookDetail obj : lstInputItems) {
      //Order and orderitem are not generated when quantity is 0.
      if (obj.qTO == 0 && obj.qTOO == 0) {
        continue;
      }
      setAccountId.add(obj.aId);
    }
    //create order data
    Map<String, Order> mapAccountOrder = TPB_MassPrebookController.createOrderData(
      objOrder.Id,
      setAccountId,
      objOrder.TPB_Mass_Prebook_Product__c,
      null,
      null,
      TPB_AddInventoryPurchasedFormService.searchPricebook2()[0].Id
    );
    // insert mapAccountOrder.values()
    insert mapAccountOrder.values();

    if (mapAccountOrder.size() > 0 && setAccountId.size() > 0) {
      //createOrderItem
      List<OrderItem> lstOrderItem = createOrderItem(
        lstInputItems,
        objOrder.TPB_Mass_Prebook_Product__c,
        strOrderType,
        mapProductPricebookEntry,
        mapAccountOrder
      );
      //insert lstOrderItem
      insert lstOrderItem;

      List<Order> lstUpdateOrder = new List<Order>();
      for (Order objOrderData : mapAccountOrder.values()) {
        objOrderData.Status = 'Activated';
        lstUpdateOrder.add(objOrderData);
      }
      //update lstUpdateOrder
      update lstUpdateOrder;
    }
  }

  /**
   * @description  updateOrCancelData
   * @param  lstInputItems  List<TPB_MassPrebookWrapper.MassPrebookDetail>
   * @param  strUpdateType  String
   * @param  mapAccOrgUnit  Map<String, String>
   */
  public void updateOrCancelData(
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstInputItems,
    String strUpdateType,
    Map<String, String> mapAccOrgUnit
  ) {
    Set<String> strAccountIds = new Set<String>();
    for (TPB_MassPrebookWrapper.MassPrebookDetail obj : lstInputItems) {
      strAccountIds.add(obj.aId);
    }
    //get All Promotion Allocation Item
    Map<String, TPB_Promotion_Allocation_Item__c> mapAccPromotionAllocationItem = TPB_MassPrebookService.getAllPromotionAllocationItem(
      null,
      objOrder.TPB_Mass_Prebook_Product__c,
      objOrder.TPB_Wave_Order_Date__c,
      strAccountIds
    );

    //getMassPrebookOrderData
    List<Order> lstOrderData = getMassPrebookOrderData(
      strOrderId,
      strAccountIds
    );

    //update Promotion_Allocation_Item list
    List<TPB_Promotion_Allocation_Item__c> lstUpdatePromotionAllocationItem = new List<TPB_Promotion_Allocation_Item__c>();
    for (TPB_MassPrebookWrapper.MassPrebookDetail item : lstInputItems) {
      //doubleOrgUnit
      Double doubleOrgUnit = 0;
      if (mapAccPromotionAllocationItem.containsKey(item.aId)) {
        TPB_Promotion_Allocation_Item__c obj = mapAccPromotionAllocationItem.get(
          item.aId
        );
        //Total QTY Ordered
        Double douTotalQTYOrdered = TPB_MassPrebookControllerUtility.amountConvert(
          obj.TPB_Total_QTY_Ordered__c
        );

        //update Total_QTY_Ordered  QTY
        TPB_Promotion_Allocation_Item__c objAllocationItem = new TPB_Promotion_Allocation_Item__c();
        objAllocationItem.Id = obj.Id;
        //update data
        if (strUpdateType == ORDER_STATUS_UPDATE) {
          objAllocationItem.TPB_Total_QTY_Ordered__c =
            douTotalQTYOrdered + (item.qTO - item.qTOO);
          doubleOrgUnit += (item.qTO - item.qTOO);

          //cancel data
        } else if (strUpdateType == ORDER_STATUS_CANCEL) {
          objAllocationItem.TPB_Total_QTY_Ordered__c =
            douTotalQTYOrdered - item.qTO;
          doubleOrgUnit += item.qTO;
        }

        //Add up all org units with the same amount
        String strAccOrgUnit = mapAccOrgUnit.get(item.aId);
        if (
          mapAccOrgUnit.containsKey(item.aId) &&
          !mapAccOrgUnitAllocation.containsKey(strAccOrgUnit)
        ) {
          mapAccOrgUnitAllocation.put(strAccOrgUnit, doubleOrgUnit);
        } else if (
          mapAccOrgUnit.containsKey(item.aId) &&
          mapAccOrgUnitAllocation.containsKey(strAccOrgUnit)
        ) {
          mapAccOrgUnitAllocation.put(
            strAccOrgUnit,
            mapAccOrgUnitAllocation.get(strAccOrgUnit) + doubleOrgUnit
          );
        }
        lstUpdatePromotionAllocationItem.add(objAllocationItem);
      }
    }

    //Aggregate all quantities
    //totalOrgUnitOrdered += doubleOrgUnit;

    //update Promotion_Allocation_Item
    if (lstUpdatePromotionAllocationItem.size() > 0) {
      update lstUpdatePromotionAllocationItem;
    }
    //update order status
    if (lstOrderData.size() > 0) {
      update lstOrderData;
    }
  }

  /**
   * @description
   * @param  bc              A reference to the Database.BatchableContext context
   * @param  lstContentDocumentLink   List<ContentDocumentLink>
   */
  public void execute(
    Database.BatchableContext bc,
    List<ContentDocumentLink> lstContentDocumentLink
  ) {
    Savepoint sp = Database.setSavepoint();
    try {
      //getMassPrebookDetailData
      List<TPB_MassPrebookWrapper.MassPrebookDetail> lstInputItems = getMassPrebookDetailData(
        lstContentDocumentLink
      );
      if (strUpdateType == ORDER_STATUS_COMPLETE) {
        completeData(lstInputItems);

        //strUpdateType == 'Update'
      } else if (
        strUpdateType == ORDER_STATUS_UPDATE ||
        strUpdateType == ORDER_STATUS_CANCEL
      ) {
        List<String> lstString = TPB_MassPrebookControllerUtility.getDataAll(
          strOrderId,
          MASS_PREBOOK_ORG_UNIT_ORDER_FILE
        );
        //get all account and org unit data
        Map<String, String> mapAccOrgUnit = (Map<String, String>) JSON.deserialize(
          lstString[0],
          Map<String, String>.class
        );
        updateOrCancelData(lstInputItems, strUpdateType, mapAccOrgUnit);
      }
    } catch (Exception objEx) {
      Database.rollback(sp);
    }
  }

  /**
   * @description create OrderItem
   * @param  lstObj List<TPB_MassPrebookWrapper.MassPrebookDetail>
   * @param  strProductId String
   * @param  strOrderType String
   * @param  mapProductPricebookEntry Map<String, String>
   * @param  mapAccountOrder Map<String, Order>
   * @return  lstOrderItem   List<OrderItem>
   */
  public static List<OrderItem> createOrderItem(
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstObj,
    String strProductId,
    String strOrderType,
    Map<String, String> mapProductPricebookEntry,
    Map<String, Order> mapAccountOrder
  ) {
    //create OrderItem List
    List<OrderItem> lstOrderItem = new List<OrderItem>();
    for (TPB_MassPrebookWrapper.MassPrebookDetail obj : lstObj) {
      //Order and orderitem are not generated when quantity is 0.
      if (
        (obj.qTO == 0 && obj.qTOO == 0) || !mapAccountOrder.containsKey(obj.aId)
      ) {
        continue;
      }

      //create OrderItem
      OrderItem objOrderItem = new OrderItem();
      objOrderItem.Product2Id = strProductId;
      objOrderItem.UnitPrice = 0;
      objOrderItem.Quantity = obj.qTO;
      //get PricebookEntryId
      objOrderItem.PricebookEntryId = mapProductPricebookEntry.get(
        strProductId
      );
      objOrderItem.OrderId = mapAccountOrder.get(obj.aId).Id;
      //strOrderType == ORDER_TYPE
      if (strOrderType == ORDER_TYPE) {
        objOrderItem.TPB_QTY_Planned__c = obj.qTP;
        objOrderItem.TPB_QTY_Remaining__c =
          objOrderItem.TPB_QTY_Planned__c - objOrderItem.Quantity;
        objOrderItem.TPB_Max_Quantity__c = obj.mxQ;

        //strOrderType not is ORDER_TYPE
      } else {
        objOrderItem.TPB_Max_Quantity__c = null;
        objOrderItem.TPB_QTY_Planned__c = null;
        objOrderItem.TPB_QTY_Remaining__c = null;
      }
      lstOrderItem.add(objOrderItem);
    }

    // return lstOrderItem data
    return lstOrderItem;
  }

  /**
   * @description This method will be called after all execution ended to run a batch job
   * @param  objBC A reference to the Database.BatchableContext objBC
   */
  public void finish(Database.BatchableContext objBC) {
    //get Account Owner User Data
    List<TPB_Promotion_Allocation_Item__c> lstPromotionOrgUnit = [
      SELECT Id, TPB_Total_QTY_Ordered__c
      FROM TPB_Promotion_Allocation_Item__c
      WHERE Id IN :mapAccOrgUnitAllocation.KeySet()
    ];
    //Completed update status
    if (strUpdateType == ORDER_STATUS_COMPLETE) {
      //update order Status
      Order objUpdateOrder = new Order();
      objUpdateOrder.Id = objOrder.Id;
      objUpdateOrder.Status = 'Completed';
      if (!boolRunTest) {
        update objUpdateOrder;
      }
    }
    //update org unit Promotion_Allocation TPB_Total_QTY_Ordered__c
    if (
      lstPromotionOrgUnit.size() > 0 &&
      (strUpdateType == ORDER_STATUS_CANCEL ||
      strUpdateType == ORDER_STATUS_UPDATE)
    ) {
      for (TPB_Promotion_Allocation_Item__c obj : lstPromotionOrgUnit) {
        Double doubleOrgUnit = TPB_MassPrebookControllerUtility.amountConvert(
          obj.TPB_Total_QTY_Ordered__c
        );
        if (strUpdateType == ORDER_STATUS_CANCEL) {
          obj.TPB_Total_QTY_Ordered__c =
            doubleOrgUnit - mapAccOrgUnitAllocation.get(obj.Id);
        } else if (strUpdateType == ORDER_STATUS_UPDATE) {
          obj.TPB_Total_QTY_Ordered__c =
            doubleOrgUnit + mapAccOrgUnitAllocation.get(obj.Id);
        }
      }
      if (strUpdateType == ORDER_STATUS_CANCEL) {
        //update order Status
        Order objUpdateOrder = new Order();
        objUpdateOrder.Id = objOrder.Id;
        objUpdateOrder.Status = ORDER_STATUS_CANCEL;
        if (!boolRunTest) {
          update objUpdateOrder;
        }
      }
      //update lstPromotionOrgUnit[0]
      update lstPromotionOrgUnit;
    }
  }
}