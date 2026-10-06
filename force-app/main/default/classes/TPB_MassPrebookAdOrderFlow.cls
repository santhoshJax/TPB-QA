/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screen flow for Mass Prebook
 */
public without sharing class TPB_MassPrebookAdOrderFlow {
  //TPB_Promotion_Allocation_Item__c  recordType Id
  public static String proAllocationItemOrgRecordTypeId = TPB_TestFactory.proAllocationItemOrgRecordTypeId;
  public static String proAllocationItemStoreRecordTypeId = TPB_TestFactory.proAllocationItemStoreRecordTypeId;

  //Advanced Order Phase: Released
  private static final String RELEASED_ORDER = 'Released';

  //UoM: Case
  private static final String LAYER = 'Layer';
  private static final String CONSUMERUNITEACH = 'ConsumerUnit';
  //Advanced Order Item Unit: Carton, UoM: Carton
  private static final String SALES_UNIT_CARTON = 'SalesUnit';

  /**
   * @description query Order Item
   * @param   lstOrder      List<String>
   * @return  lstOrderItem  List<cgcloud__Order_Item__c>
   */
  public static List<cgcloud__Order_Item__c> queryOrderItem(
    List<String> lstOrder
  ) {
    //query Order_Item data
    List<cgcloud__Order_Item__c> lstOrderItem = [
      SELECT
        Id,
        cgcloud__Product__c,
        cgcloud__Quantity__c,
        cgcloud__UoM__c,
        cgcloud__Order__r.cgcloud__Order_Account__c,
        cgcloud__Order__r.cgcloud__Order_Account__r.Parent.OwnerId,
        cgcloud__Order__r.cgcloud__Order_Account__r.Ownership__c,
        TPB_Promotion_Waves__c
      FROM cgcloud__Order_Item__c
      WHERE
        cgcloud__Order__c IN :lstOrder
        AND cgcloud__Order__r.cgcloud__Phase__c = :RELEASED_ORDER
        AND cgcloud__Product__c != NULL
        AND cgcloud__Order__r.cgcloud__Order_Account__c != NULL
        AND TPB_Promotion_Waves__c != NULL
      ORDER BY cgcloud__Order__c DESC
    ];

    //return data
    return lstOrderItem;
  }

  /**
   * @description get All Promotion Allocation Item Data
   * @param   setAccountId    String
   * @param   setProductId    String
   * @param   setWave         String
   * @param   lstOrgUnitIds   String
   * @return  mapAccPromotionAllocationItem  Map<String, TPB_Promotion_Allocation_Item__c>
   */
  public static Map<String, TPB_Promotion_Allocation_Item__c> getAllPromotionAllocationItem(
    Set<String> setAccountId,
    Set<String> setProductId,
    Set<String> setWave,
    List<String> lstOrgUnitIds
  ) {
    Map<String, TPB_Promotion_Allocation_Item__c> mapAccPromotionAllocationItem = new Map<String, TPB_Promotion_Allocation_Item__c>();
    //query TPB_Promotion_Allocation_Item__c data
    List<TPB_Promotion_Allocation_Item__c> lstPromotionAllocationItem = [
      SELECT
        Id,
        TPB_Total_QTY_Ordered__c,
        TPB_Org_Unit__c,
        TPB_Product__c,
        TPB_Account__c,
        TPB_Promotion_Waves__c,
        RecordType.Name
      FROM TPB_Promotion_Allocation_Item__c
      WHERE
        TPB_Product__c IN :setProductId
        AND TPB_Promotion_Waves__c IN :setWave
        AND (TPB_Account__c IN :setAccountId
        OR TPB_Org_Unit__c IN :lstOrgUnitIds)
        AND RecordTypeId != NULL
      ORDER BY TPB_Promotion_Waves__c DESC
    ];

    //add map
    for (TPB_Promotion_Allocation_Item__c obj : lstPromotionAllocationItem) {
      //Create a map with Promotion_Waves and product as keys
      String strKey =
        String.valueOf(obj.TPB_Promotion_Waves__c) + obj.TPB_Product__c;
      //Org_Unit is not null
      if (obj.TPB_Org_Unit__c != null) {
        strKey += obj.TPB_Org_Unit__c;
        //account is null
      } else if (obj.TPB_Account__c != null) {
        strKey += obj.TPB_Account__c;
      }
      if (!mapAccPromotionAllocationItem.containsKey(strKey)) {
        mapAccPromotionAllocationItem.put(strKey, obj);
      }
    }

    //return mapAccPromotionAllocationItem
    return mapAccPromotionAllocationItem;
  }

  /**
   * @description updatePricingConditionStage
   * @param   inputs      List<InputParameters>
   */
  @InvocableMethod(
    label='TPB_MassPrebookAdOrderFlow'
    category='promotionAllocationItem'
  )
  public static void promotionAllocationItem(List<InputParameters> inputs) {
    List<String> lstAdvancedOrder = new List<String>();
    if (inputs != null && inputs.size() > 0) {
      //get ad order id
      for (InputParameters obj : inputs) {
        lstAdvancedOrder.addAll(obj.lstAdvancedOrder);
      }

      //query Order Item data
      List<cgcloud__Order_Item__c> lstOrderItem = queryOrderItem(
        lstAdvancedOrder
      );
      if (lstOrderItem.size() > 0) {
        //crate set list
        Set<String> setHqOwnerId = new Set<String>();
        Set<String> setProductId = new Set<String>();
        Set<String> setWave = new Set<String>();
        Set<String> setAccountId = new Set<String>();

        //Independent Set
        Set<String> setIndependentAcc = new Set<String>();
        //Chain Set
        Set<String> setChainAcc = new Set<String>();
        for (cgcloud__Order_Item__c obj : lstOrderItem) {
          //add product、account、wave data
          setProductId.add(obj.cgcloud__Product__c);
          setAccountId.add(obj.cgcloud__Order__r.cgcloud__Order_Account__c);
          setWave.add(obj.TPB_Promotion_Waves__c);
          setHqOwnerId.add(
            obj.cgcloud__Order__r.cgcloud__Order_Account__r.Parent.OwnerId
          );

          //Ownership__c == 'Independent'
          if (
            obj.cgcloud__Order__r.cgcloud__Order_Account__r.Ownership__c ==
            'Independent'
          ) {
            setIndependentAcc.add(
              obj.cgcloud__Order__r.cgcloud__Order_Account__c
            );
            //Ownership__c == 'FSO Chain' || Ownership__c == 'NAM Chain'
          } else if (
            obj.cgcloud__Order__r.cgcloud__Order_Account__r.Ownership__c ==
            'FSO Chain' ||
            obj.cgcloud__Order__r.cgcloud__Order_Account__r.Ownership__c ==
            'NAM Chain'
          ) {
            setChainAcc.add(obj.cgcloud__Order__r.cgcloud__Order_Account__c);
          }
        }

        //query account data
        List<Account> lstAccount = [
          SELECT Id, Parent.OwnerId
          FROM Account
          WHERE Id IN :setAccountId AND Parent.OwnerId != NULL
        ];
        for (Account obj : lstAccount) {
          setHqOwnerId.add(obj.Parent.OwnerId);
        }

        //getAllOrgUnitAllocation
        Map<String, String> mapOrgUnitIds = TPB_MassPrebookControllerUtility.getAllOrgUnitAllocation(
          setIndependentAcc,
          setChainAcc,
          setHqOwnerId
        );

        //get All Promotion Allocation Item
        Map<String, TPB_Promotion_Allocation_Item__c> mapAccPromotionAllocationItem = getAllPromotionAllocationItem(
          setAccountId,
          setProductId,
          setWave,
          mapOrgUnitIds.values()
        );

        Map<String, String> mapStoreOrgUnitAllocation = new Map<String, String>();
        for (cgcloud__Order_Item__c obj : lstOrderItem) {
          if (
            mapOrgUnitIds.containsKey(
              obj.cgcloud__Order__r.cgcloud__Order_Account__c
            ) &&
            setIndependentAcc.contains(
              obj.cgcloud__Order__r.cgcloud__Order_Account__c
            )
          ) {
            mapStoreOrgUnitAllocation.put(
              obj.cgcloud__Order__r.cgcloud__Order_Account__c,
              mapOrgUnitIds.get(obj.cgcloud__Order__r.cgcloud__Order_Account__c)
            );
          } else if (
            mapOrgUnitIds.containsKey(
              obj.cgcloud__Order__r.cgcloud__Order_Account__r.Parent.OwnerId
            ) &&
            setChainAcc.contains(
              obj.cgcloud__Order__r.cgcloud__Order_Account__c
            )
          ) {
            mapStoreOrgUnitAllocation.put(
              obj.cgcloud__Order__r.cgcloud__Order_Account__c,
              mapOrgUnitIds.get(
                obj.cgcloud__Order__r.cgcloud__Order_Account__r.Parent.OwnerId
              )
            );
          }
        }

        //update Promotion Allocation Item
        updatePromotionAllocationItem(
          setProductId,
          mapStoreOrgUnitAllocation,
          mapAccPromotionAllocationItem,
          lstOrderItem
        );
      }
    }
  }

  /**
   * @description get All Promotion Allocation Item Data
   * @param   objPromotion   TPB_Promotion_Allocation_Item__c
   * @param   obj            cgcloud__Order_Item__c
   * @return  objPromotion   TPB_Promotion_Allocation_Item__c
   */
  public static TPB_Promotion_Allocation_Item__c updateStorePromotionAllocationItem(
    TPB_Promotion_Allocation_Item__c objPromotion,
    Double doubleNumber
  ) {
    objPromotion.TPB_Total_QTY_Ordered__c = objPromotion.TPB_Total_QTY_Ordered__c ==
      null
      ? 0
      : objPromotion.TPB_Total_QTY_Ordered__c + doubleNumber;

    return objPromotion;
  }

  /**
   * @description get All Promotion Allocation Item Data
   * @param   setProductId    Set<String>
   * @param   mapStoreOrgUnitAllocation       Map<String, String>
   * @param   mapAccPromotionAllocationItem   Map<String, TPB_Promotion_Allocation_Item__c>
   * @param   lstOrderItem    List<cgcloud__Order_Item__c>
   */
  public static void updatePromotionAllocationItem(
    Set<String> setProductId,
    Map<String, String> mapStoreOrgUnitAllocation,
    Map<String, TPB_Promotion_Allocation_Item__c> mapAccPromotionAllocationItem,
    List<cgcloud__Order_Item__c> lstOrderItem
  ) {
    Map<String, Double> mapAllUserQuantity = new Map<String, Double>();
    Map<String, TPB_Promotion_Allocation_Item__c> mapUpdateAccPromotion = new Map<String, TPB_Promotion_Allocation_Item__c>();
    Map<String, TPB_Promotion_Allocation_Item__c> mapOrgUnitPromotion = new Map<String, TPB_Promotion_Allocation_Item__c>();
    //get all product uom
    Map<String, List<cgcloud__Unit_of_Measure__c>> mapPrdId2UoM = searchUomData(
      setProductId
    );

    for (cgcloud__Order_Item__c obj : lstOrderItem) {
      //account + Wave + Product  key
      String strAccountKey =
        String.valueOf(obj.TPB_Promotion_Waves__c) +
        obj.cgcloud__Product__c +
        obj.cgcloud__Order__r.cgcloud__Order_Account__c;

      //org uint + Wave + Product key
      String strOrgUnitKey =
        String.valueOf(obj.TPB_Promotion_Waves__c) +
        obj.cgcloud__Product__c +
        mapStoreOrgUnitAllocation.get(
          obj.cgcloud__Order__r.cgcloud__Order_Account__c
        );

      //calculation Of Commuted Quantities
      Double doubleNumber = calculationOfCommutedQuantities(
        obj,
        mapPrdId2UoM.get(obj.cgcloud__Product__c)
      );

      //account key
      if (mapAccPromotionAllocationItem.containsKey(strAccountKey)) {
        //update Store PromotionAllocationItem
        TPB_Promotion_Allocation_Item__c objPromotion = updateStorePromotionAllocationItem(
          mapAccPromotionAllocationItem.get(strAccountKey),
          doubleNumber
        );
        mapUpdateAccPromotion.put(strAccountKey, objPromotion);
        //Org Unit Key
      }
      if (mapAccPromotionAllocationItem.containsKey(strOrgUnitKey)) {
        //update Store PromotionAllocationItem
        mapOrgUnitPromotion.put(
          strOrgUnitKey,
          mapAccPromotionAllocationItem.get(strOrgUnitKey)
        );
        //Add up all org units with the same amount
        if (mapAllUserQuantity.containsKey(strOrgUnitKey)) {
          mapAllUserQuantity.put(
            strOrgUnitKey,
            mapAllUserQuantity.get(strOrgUnitKey) + doubleNumber
          );
        } else {
          mapAllUserQuantity.put(strOrgUnitKey, doubleNumber);
        }
      }
    }

    try {
      //updateOrgUnitPromotion
      if (mapOrgUnitPromotion.size() > 0 && mapAllUserQuantity.size() > 0) {
        updateOrgUnitPromotion(mapOrgUnitPromotion, mapAllUserQuantity);
      }

      //update mapUpdateAccPromotion
      if (mapUpdateAccPromotion.size() > 0) {
        update mapUpdateAccPromotion.values();
      }
    } catch (Exception objEx) {
    }
  }

  /**
   * @description calculationOfCommutedQuantities
   * @param   orderIt          cgcloud__Order_Item__c
   * @param   lstUoMFromMap    List<cgcloud__Unit_of_Measure__c>
   * @return  currentOrderItemQuantity   Double
   */
  public static Double calculationOfCommutedQuantities(
    cgcloud__Order_Item__c orderIt,
    List<cgcloud__Unit_of_Measure__c> lstUoMFromMap
  ) {
    //Carton unit price in current order item
    Double currentOrderItemQuantity = orderIt.cgcloud__Quantity__c;
    //Store each, carton, case quantitative relationship
    Double numCase;
    Double numCarton;
    for (cgcloud__Unit_of_Measure__c objUoM : lstUoMFromMap) {
      //Store current product UoM unit price
      if (objUoM.cgcloud__Unit_Type__c == SALES_UNIT_CARTON) {
        numCarton = objUoM.cgcloud__Pieces_per_Smallest_Unit__c;
      } else if (objUoM.cgcloud__Unit_Type__c == LAYER) {
        numCase = objUoM.cgcloud__Pieces_per_Smallest_Unit__c;
      }
    }
    //if each, multiply
    if (orderIt.cgcloud__UoM__c == CONSUMERUNITEACH) {
      currentOrderItemQuantity = currentOrderItemQuantity / numCarton;
    } else if (orderIt.cgcloud__UoM__c == LAYER) {
      //if each, divide first to get each, then multiply to get carton
      currentOrderItemQuantity =
        currentOrderItemQuantity * (numCase / numCarton);
    }

    return currentOrderItemQuantity;
  }

  /**
   * @description get All Promotion Allocation Item Data
   * @param   mapOrgUnitPromotion   Map<String, TPB_Promotion_Allocation_Item__c>
   * @param   mapAllUserQuantity    Map<String, Double>
   */
  public static void updateOrgUnitPromotion(
    Map<String, TPB_Promotion_Allocation_Item__c> mapOrgUnitPromotion,
    Map<String, Double> mapAllUserQuantity
  ) {
    //update org uint Quantity
    for (String str : mapOrgUnitPromotion.KeySet()) {
      if (mapAllUserQuantity.containsKey(str)) {
        mapOrgUnitPromotion.get(str).TPB_Total_QTY_Ordered__c =
          mapOrgUnitPromotion.get(str).TPB_Total_QTY_Ordered__c +
          mapAllUserQuantity.get(str);
      }
    }

    //update org unit and acc Promotion
    update mapOrgUnitPromotion.values();
  }

  /**
   * @description search Uom Data
   * @param   setProductId     Set<String>
   * @return   mapPrdId2UoM     Map<String, List<cgcloud__Unit_of_Measure__c>>
   */
  public static Map<String, List<cgcloud__Unit_of_Measure__c>> searchUomData(
    Set<String> setProductId
  ) {
    //Query all related UoM by Product
    List<cgcloud__Unit_of_Measure__c> lstUoM = [
      SELECT
        Id,
        cgcloud__Unit_Type__c,
        cgcloud__Product__c,
        cgcloud__Pieces_per_Smallest_Unit__c
      FROM cgcloud__Unit_of_Measure__c
      WHERE cgcloud__Product__c IN :setProductId
      ORDER BY cgcloud__Product__c DESC
    ];
    //Map product Id to UoM
    Map<String, List<cgcloud__Unit_of_Measure__c>> mapPrdId2UoM = new Map<String, List<cgcloud__Unit_of_Measure__c>>();
    for (cgcloud__Unit_of_Measure__c objUoM : lstUoM) {
      if (!mapPrdId2UoM.containsKey(objUoM.cgcloud__Product__c)) {
        mapPrdId2UoM.put(
          objUoM.cgcloud__Product__c,
          new List<cgcloud__Unit_of_Measure__c>{ objUoM }
        );
      } else {
        mapPrdId2UoM.get(objUoM.cgcloud__Product__c).add(objUoM);
      }
    }

    return mapPrdId2UoM;
  }

  /**
   * @description Wrapper class for input parameters
   */
  public class InputParameters {
    /**
     * @description Advanced Order List
     */
    @InvocableVariable(required=true)
    public List<String> lstAdvancedOrder;
  }
}