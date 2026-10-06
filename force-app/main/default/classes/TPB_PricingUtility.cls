/**
 * @author: Mi Li
 * @date 6/24/2023
 * @description TPB_PricingUtility
 */
public without sharing class TPB_PricingUtility {
  //sales org
  public static final String SALES_ORG = TPB_TestFactory.salesOrg;
  //With State KeyType
  public static final String WITHOUT_CATEGORY = 'PS101';
  //Without State KeyType
  public static final String WITH_CATEGORY = 'PS102';
  //Pricing Condition Templates
  public static final String PRICING_CONDITION_TEMPLATES = 'BasePrice_ext';
  //unit ConsumerUnit
  public static final String UNIT_CONSUMERUNITEACH = TPB_TestFactory.CONSUMERUNITEACH;
  private static final String SALES_UNIT_CARTON = TPB_TestFactory.SALESUNITCARTON;

  //UoM: Carton
  private static final String UOMCARTON = 'SalesUnit';
  //UoM: Each
  private static final String UOMEACH = 'ConsumerUnit';

  //Used to distinguish which flow is called
  private static final String PRODUCT_UPDATE = 'ProductUpdate';
  private static final String INVENTORY_UPDATE = 'InventoryUpdate';

  /**
   * @description getKeyType  description
   * @return  key Type value     List<cgcloud__CP_Key_Type__c>
   */
  public static List<cgcloud__CP_Key_Type__c> getKeyType() {
    return [
      SELECT Id, Name
      FROM cgcloud__CP_Key_Type__c
      WHERE Name = :WITH_CATEGORY OR Name = :WITHOUT_CATEGORY
      ORDER BY Name ASC
      LIMIT 2
    ];
  }

  /**
   * @description get Pricing Condition Template  description
   * @return  strPricingConditionTemplateId  description
   */
  public static String getPricingConditionTemplate() {
    String strPricingConditionTemplateId = null;
    List<cgcloud__CP_Pricing_Condition_Template__c> lstCPPricingTemplate = [
      SELECT Id, Name
      FROM cgcloud__CP_Pricing_Condition_Template__c
      WHERE Name = :PRICING_CONDITION_TEMPLATES
      LIMIT 1
    ];
    if (lstCPPricingTemplate.size() > 0) {
      strPricingConditionTemplateId = lstCPPricingTemplate[0].Id;
    }

    return strPricingConditionTemplateId;
  }

  /**
   * @description get Pricing Condition Stage description
   * @param  keys  Map<String, cgcloud__Inventory__c>
   * @return mapCPPricing Map<String, cgcloud__CP_Pricing_Condition_Stage__c>
   */
  public static Map<String, cgcloud__CP_Pricing_Condition_Stage__c> getPricingConditionStage(
    Set<String> keys
  ) {
    //Query existing CP_Pricing_Condition_Stage data
    List<cgcloud__CP_Pricing_Condition_Stage__c> lstCPPricing = [
      SELECT Id, cgcloud__External_Id__c
      FROM cgcloud__CP_Pricing_Condition_Stage__c
      WHERE cgcloud__External_Id__c IN :keys
    ];
    Map<String, cgcloud__CP_Pricing_Condition_Stage__c> mapCPPricing = new Map<String, cgcloud__CP_Pricing_Condition_Stage__c>();
    //map collection is saved with External_Id as the unique key
    for (cgcloud__CP_Pricing_Condition_Stage__c objCPPricing : lstCPPricing) {
      mapCPPricing.put(objCPPricing.cgcloud__External_Id__c, objCPPricing);
    }

    return mapCPPricing;
  }

  /**
   * @description query Inventory
   * @param   lstInventory    List<String>
   * @return  lstInv
   */
  public static List<cgcloud__Inventory__c> queryInventory(
    List<String> lstInventory
  ) {
    List<cgcloud__Inventory__c> lstInv = [
      SELECT
        Id,
        TPB_AvgPrice__c,
        TPB_PricingMergedKey__c,
        TPB_StateClassId__c,
        cgcloud__Product__c,
        cgcloud__User__c,
        cgcloud__Product__r.TPB_Exclude_From_Base_Pricing__c,
        cgcloud__Product__r.cgcloud__Criterion_5_Product__c,
        TPB_Tour_State__c
      FROM cgcloud__Inventory__c
      WHERE Id IN :lstInventory
      LIMIT 5000
    ];

    return lstInv;
  }

  /**
   * @description query CP Pricing Condition
   * @param   setPricingMergedKey  Set<String>
   * @return  lstInv
   */
  public static List<cgcloud__CP_Pricing_Condition__c> queryCPPricingCondition(
    Set<String> setPricingMergedKey
  ) {
    List<cgcloud__CP_Pricing_Condition__c> lstPricingCondition = [
      SELECT id, cgcloud__Merged_Key__c
      FROM cgcloud__CP_Pricing_Condition__c
      WHERE cgcloud__Merged_Key__c IN :setPricingMergedKey
    ];

    //return lstPricingCondition
    return lstPricingCondition;
  }

  /**
   * @description upsert Pricing Condition Stage description
   * @param  stages Map<String, cgcloud__Inventory__c>
   */
  public static void upsertPricingConditionStage(
    Map<String, TPB_PricingStage> stages
  ) {
    //get all PricingConditionStage data
    Map<String, cgcloud__CP_Pricing_Condition_Stage__c> mapCPPricing = getPricingConditionStage(
      stages.keySet()
    );
    //need Upsert CPPricing data set
    List<cgcloud__CP_Pricing_Condition_Stage__c> lstUpsertCPPricing = new List<cgcloud__CP_Pricing_Condition_Stage__c>();
    //get PricingCondition Template
    String strPricingConditionTemplateId = getPricingConditionTemplate();
    //get KeyType
    List<cgcloud__CP_Key_Type__c> lstKeyType = getKeyType();

    for (String strPricingMergedKey : stages.keySet()) {
      //get pricing data
      TPB_PricingStage stage = stages.get(strPricingMergedKey);

      //create Pricing Condition Stage
      cgcloud__CP_Pricing_Condition_Stage__c objStage = createPricingConditionStage(
        strPricingMergedKey,
        stage,
        strPricingConditionTemplateId,
        lstKeyType,
        mapCPPricing
      );

      //add
      if (objStage.cgcloud__External_Id__c != null) {
        lstUpsertCPPricing.add(objStage);
      }
    }

    // upsert lstUpsertCPPricing
    if (lstUpsertCPPricing.size() > 0) {
      upsert lstUpsertCPPricing cgcloud__External_Id__c;
    }
  }

  /**
   * @description upsert Pricing Condition Stage description
   * @param  strPricingMergedKey String
   * @param  stage               TPB_PricingStage
   * @param  strPricingConditionTemplateId String
   * @param  lstKeyType          List<cgcloud__CP_Key_Type__c>
   * @param  mapCPPricing        Map<String, cgcloud__CP_Pricing_Condition_Stage__c>
   * @return objStage            cgcloud__CP_Pricing_Condition_Stage__c
   */
  public static cgcloud__CP_Pricing_Condition_Stage__c createPricingConditionStage(
    String strPricingMergedKey,
    TPB_PricingStage stage,
    String strPricingConditionTemplateId,
    List<cgcloud__CP_Key_Type__c> lstKeyType,
    Map<String, cgcloud__CP_Pricing_Condition_Stage__c> mapCPPricing
  ) {
    cgcloud__CP_Pricing_Condition_Stage__c objStage = new cgcloud__CP_Pricing_Condition_Stage__c();
    //When Inventory has CP_Pricing_Condition_Stage data corresponding to it
    if (mapCPPricing.containsKey(strPricingMergedKey)) {
      objStage = mapCPPricing.get(strPricingMergedKey);
    } else {
      //insert CP_Pricing_Condition_Stage data
      objStage.cgcloud__Currency__c = 'USD';
      objStage.cgcloud__Denominator__c = 1;
      objStage.cgcloud__Pricing_Condition_Template__c = strPricingConditionTemplateId;
      objStage.cgcloud__Valid_From__c = Date.today().addDays(-1);
      objStage.cgcloud__Valid_Thru__c = Date.today().addYears(99);
      objStage.cgcloud__Product__c = stage.productGroupId == null
        ? stage.productId
        : stage.productGroupId;
      objStage.cgcloud__Status__c = 'n';
      if (lstKeyType.size() > 0) {
        objStage.cgcloud__Key_Type__c = stage.productGroupId == null
          ? lstKeyType[0].Id
          : lstKeyType[1].Id;
      }
      objStage.cgcloud__Sales_Org__c = SALES_ORG;
    }
    objStage.cgcloud__Logistic_Unit__c = stage.uomType;
    objStage.cgcloud__Threshold_Unit__c = stage.uomType;
    objStage.cgcloud__Value__c = stage.basePrice;
    objStage.cgcloud__Key_1__c = stage.state != null
      ? stage.state
      : stage.userId;
    objStage.cgcloud__Key_2__c = stage.state != null ? stage.userId : null;
    objStage.cgcloud__External_Id__c = strPricingMergedKey;

    //return objStage data
    return objStage;
  }

  /**
   * @description updatePricingConditionStage
   * @param   inputs      List<InputParameters>
   */
  @InvocableMethod(
    label='TPB_PricingUtility'
    category='UpdatePricingConditionStage'
  )
  public static void updatePricingConditionStage(List<InputParameters> inputs) {
    //Inventory ids
    List<String> lstInventory = new List<String>();
    //Product Exclude from Base Pricing Check
    Boolean boolCheck = false;
    //Product or inventory Update
    String strType = '';
    //Update base price
    Double inventoryBasePrice = 0;
    if (inputs != null && inputs.size() > 0) {
      lstInventory = inputs[0].lstInventory;
      boolCheck = inputs[0].boolCheck;
      strType = inputs[0].strType;
      inventoryBasePrice = inputs[0].inventoryBasePrice;

      //Query Inventory
      List<cgcloud__Inventory__c> lstInv = queryInventory(lstInventory);
      //setString key
      Set<String> setString = new Set<String>();
      //setPricingMergedKey
      Set<String> setPricingMergedKey = new Set<String>();
      Set<String> setGroupProduct2Id = new Set<String>();
      for (cgcloud__Inventory__c obj : lstInv) {
        setString.add(
          obj.cgcloud__Product__c +
          obj.TPB_Tour_State__c +
          obj.cgcloud__User__c
        );
        setGroupProduct2Id.add(
          obj.cgcloud__Product__r.cgcloud__Criterion_5_Product__c
        );
        setPricingMergedKey.add(obj.TPB_PricingMergedKey__c);
      }

      //strType == 'ProductUpdate'
      if (strType == PRODUCT_UPDATE) {
        //query Pricing_Condition_Stage data
        Map<String, cgcloud__CP_Pricing_Condition_Stage__c> mapPricingStage = getPricingConditionStage(
          setString
        );
        if (!boolCheck) {
          List<cgcloud__CP_Pricing_Condition__c> lstPricingCondition = queryCPPricingCondition(
            setPricingMergedKey
          );
          //delete data
          if (mapPricingStage.size() > 0) {
            delete mapPricingStage.values();
          }
          if (mapPricingStage.size() > 0) {
            delete lstPricingCondition;
          }
        } else {
          updatePricingStage(lstInv, mapPricingStage);
        }
        //strType == 'InventoryUpdate'
      } else if (strType == INVENTORY_UPDATE) {
        inventoryBasePriceUpdate(
          lstInv,
          inventoryBasePrice,
          setGroupProduct2Id
        );
      }
    }
  }

  /**
   * @description inventory Base Price Update
   * @param   lstInv       List<cgcloud__Inventory__c>
   * @param   inventoryBasePrice  Double
   * @param   setGroupProduct2Id  Set<String>
   */
  public static void inventoryBasePriceUpdate(
    List<cgcloud__Inventory__c> lstInv,
    Double inventoryBasePrice,
    Set<String> setGroupProduct2Id
  ) {
    //getUnitOfMeasureData
    Map<String, Double> mapStateClassSmallestUnit = getUnitOfMeasureData(
      setGroupProduct2Id
    );
    // create or update
    Map<String, TPB_PricingStage> mapPricingStages = new Map<String, TPB_PricingStage>();
    for (cgcloud__Inventory__c obj : lstInv) {
      //create  TPB_PricingStage
      TPB_PricingStage stage = new TPB_PricingStage();
      if (mapStateClassSmallestUnit.containsKey(obj.cgcloud__Product__c)) {
        stage.basePrice =
          inventoryBasePrice /
          mapStateClassSmallestUnit.get(obj.cgcloud__Product__c);
        stage.uomType = UOMEACH;
      } else {
        stage.basePrice = inventoryBasePrice;
        stage.uomType = UOMCARTON;
      }
      stage.productGroupId = obj.cgcloud__Product__r.cgcloud__Criterion_5_Product__c;
      stage.productId = obj.cgcloud__Product__c;
      stage.userId = obj.cgcloud__User__c;
      stage.state = obj.TPB_Tour_State__c;
      mapPricingStages.put(obj.TPB_StateClassId__c, stage);
    }
    //upsertPricingConditionStage
    if (mapPricingStages.size() > 0) {
      upsertPricingConditionStage(mapPricingStages);
    }
  }

  /**
   * @description get Unit Of Measure Data
   * @param   setGroupProduct2Id  Set<String>
   * @return  mapStateClassSmallestUnit  Map<String, Double>
   */
  public static Map<String, Double> getUnitOfMeasureData(
    Set<String> setGroupProduct2Id
  ) {
    //Query all related UoM by Product
    List<cgcloud__Unit_of_Measure__c> lstUoM = [
      SELECT
        Id,
        cgcloud__Unit_Type__c,
        cgcloud__Product__c,
        cgcloud__Pieces_per_Smallest_Unit__c
      FROM cgcloud__Unit_of_Measure__c
      WHERE
        cgcloud__Product__c != NULL
        AND cgcloud__Product__r.cgcloud__Criterion_5_Product__c IN :setGroupProduct2Id
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

    return mapStateClassSmallestUnit;
  }

  /**
   * @description update Pricing Stage
   * @param   lstInv       List<cgcloud__Inventory__c>
   * @param   mapPricingStage   Map<String, cgcloud__CP_Pricing_Condition_Stage__c>
   */
  public static void updatePricingStage(
    List<cgcloud__Inventory__c> lstInv,
    Map<String, cgcloud__CP_Pricing_Condition_Stage__c> mapPricingStage
  ) {
    // create or update
    Map<String, TPB_PricingStage> mapPricingStages = new Map<String, TPB_PricingStage>();
    List<cgcloud__CP_Pricing_Condition_Stage__c> lstUpdate = new List<cgcloud__CP_Pricing_Condition_Stage__c>();
    for (cgcloud__Inventory__c obj : lstInv) {
      //get External_Id key
      String strStateClassId =
        obj.cgcloud__Product__c +
        obj.TPB_Tour_State__c +
        obj.cgcloud__User__c;
      if (mapPricingStage.containsKey(strStateClassId)) {
        cgcloud__CP_Pricing_Condition_Stage__c objPricing = mapPricingStage.get(
          strStateClassId
        );
        objPricing.cgcloud__Value__c = 0;
        lstUpdate.add(objPricing);
      } else {
        TPB_PricingStage stage = new TPB_PricingStage();
        stage.basePrice = 0;
        stage.uomType = SALES_UNIT_CARTON;
        stage.productGroupId = null;
        stage.productId = obj.cgcloud__Product__c;
        stage.userId = obj.cgcloud__User__c;
        stage.state = obj.TPB_Tour_State__c;
        mapPricingStages.put(strStateClassId, stage);
      }
    }

    //update data
    if (lstUpdate.size() > 0) {
      update lstUpdate;
    }

    if (mapPricingStages.size() > 0) {
      upsertPricingConditionStage(mapPricingStages);
    }
  }

  /**
   * @description Wrapper class for input parameters
   */
  public class InputParameters {
    /**
     * @description Inventory List
     */
    @InvocableVariable(required=true)
    public List<String> lstInventory;

    /**
     * @description boolCheck
     */
    @InvocableVariable(required=true)
    public Boolean boolCheck;

    /**
     * @description inventory BasePrice
     */
    @InvocableVariable(required=true)
    public Double inventoryBasePrice;

    /**
     * @description strType
     */
    @InvocableVariable(required=true)
    public String strType;
  }
}