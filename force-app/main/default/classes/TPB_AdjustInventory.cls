/**
 * @author Mi Li
 * @date 4/28/2023
 * @description CON0001729-1249  Inventory Adjustment Screen Flow
 */
public with sharing class TPB_AdjustInventory {
  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;
  private static final String ADDPRODUCT_ERROR = 'Can not find current product in system';
  private static final String ADD_PRICEGROUP_PRODUCT_ERROR = 'No product in this price group is available in stock and cannot be added';
  //Inventory_Control_Template name type
  private static final String CONTROL_TEMPLATE = TPB_TestFactory.INVENTORY_CONTROL_TEMPLATE;
  //cgcloud__Inventory_Transaction_Template__c name type
  private static final String TEMPLATE_ADD = TPB_TestFactory.INVENTORY_TRANSACTION_TEMPLATE_ADD;
  private static final String TEMPLATE_CASHSALE = TPB_TestFactory.INVENTORY_TRANSACTION_TEMPLATE_CASHSALE;
  //Parameter Variables
  private static final String USER_ID = 'userId';
  private static final String PRODUCT_NAME = 'productName';
  private static final String PRODUCT_ID = 'productId';
  private static final String INVERTORY_ID = 'inventoryId';
  private static final String INVERTORY_BALANCE = 'inventoryBalance';
  private static final String INVERTORY_OLD_BALANCE = 'inventoryOldBalance';
  //status active type
  private static final String STATUS_ACTIVE = TPB_TestFactory.STATUS_ACTIVE;

  /**
   * @description  add Product Data
   * @param   strCode        String
   * @param   strState       String
   * @param   strProductId   String
   * @return  mapResult      Map<String, Object>
   */
  private static Map<String, Object> addProductData(
    String strCode,
    String strState,
    String strProductId
  ) {
    Map<String, Object> mapResult = new Map<String, Object>();
    mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
    List<cgcloud__Inventory__c> lstCgcloudInventory = new List<cgcloud__Inventory__c>();
    if (strProductId != null && strProductId != '') {
      // get Inventory data
      lstCgcloudInventory = searchInventory(strState, strProductId, null);
      Product2 objProduct2 = searchProduct2Data(strProductId);

      mapResult.put(PRODUCT_ID, objProduct2.Id);
      mapResult.put(PRODUCT_NAME, objProduct2.Name);
    } else if (strCode != null && strCode != '') {
      // Seciton: get UoM by strCode
      // strCode is an unique value of GTIN field on cgcloud__Unit_of_Measure__c
      List<cgcloud__Unit_of_Measure__c> lCgcUom = TPB_AddCFundAuditService.searchUnitOfMeasure(
        strCode
      );
      if (lCgcUom == null || lCgcUom.size() == 0) {
        // unknown product
        mapResult.put(RTN_KEY_ERR_MSG, ADDPRODUCT_ERROR);
        return mapResult;
      }

      // get Inventory data
      lstCgcloudInventory = searchInventory(
        strState,
        lCgcUom[0].cgcloud__Product__c,
        null
      );

      mapResult.put(PRODUCT_ID, lCgcUom[0].cgcloud__Product__c);
      mapResult.put(PRODUCT_NAME, lCgcUom[0].cgcloud__Product__r.Name);
    }

    //add Inventory
    if (lstCgcloudInventory.size() > 0) {
      mapResult.put(INVERTORY_ID, lstCgcloudInventory[0].Id);
      mapResult.put(
        INVERTORY_BALANCE,
        lstCgcloudInventory[0].cgcloud__Balance__c
      );
    } else {
      //add null Inventory
      mapResult.put(INVERTORY_ID, '');
      mapResult.put(INVERTORY_BALANCE, '');
    }

    //return mapResult data
    return mapResult;
  }

  /**
   * @description  add Scanned Product
   * @param   strCode        String
   * @param   strState       String
   * @param   strProductId   String
   * @return  mapResult      Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> scannedProduct(
    String strCode,
    String strState,
    String strProductId
  ) {
    Map<String, Object> mapResult = new Map<String, Object>();
    mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
    Savepoint sp = Database.setSavepoint();
    try {
      // Return when empty
      if (
        String.isEmpty(strCode) && String.isEmpty(strProductId) ||
        String.isEmpty(strState)
      ) {
        mapResult.put(RTN_KEY_ERR_MSG, ADDPRODUCT_ERROR);
        return mapResult;
      }
      mapResult = addProductData(strCode, strState, strProductId);
      if (mapResult.containsKey(RTN_KEY_ERR_MSG)) {
        return mapResult;
      }

      //return data
      mapResult.put(USER_ID, UserInfo.getUserId());
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      Database.rollback(sp);

      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, objEx.getMessage());

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult data
    return mapResult;
  }

  /**
   * @description search Inventory data
   * @param   strState         String
   * @param   strProduct       String
   * @param   strStateClassId  String
   * @return  lstCgcloudInventory    List<cgcloud__Inventory__c>
   */
  private static List<cgcloud__Inventory__c> searchInventory(
    String strState,
    String strProduct,
    String strStateClassId
  ) {
    List<cgcloud__Inventory__c> lstCgcloudInventory = new List<cgcloud__Inventory__c>();
    if (strStateClassId != null && strStateClassId != '') {
      //query active Inventory data
      lstCgcloudInventory = [
        SELECT
          Id,
          TPB_AvgPrice__c,
          TPB_Tour_State__c,
          cgcloud__User__c,
          cgcloud__Balance__c
        FROM cgcloud__Inventory__c
        WHERE TPB_StateClassId__c = :strStateClassId AND TPB_AvgPrice__c != 0
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];
    } else {
      //query active Inventory data
      lstCgcloudInventory = [
        SELECT
          Id,
          cgcloud__Product__c,
          cgcloud__Product__r.Name,
          TPB_AvgPrice__c,
          TPB_Tour_State__c,
          cgcloud__User__c,
          cgcloud__Balance__c
        FROM cgcloud__Inventory__c
        WHERE
          cgcloud__User__c = :UserInfo.getUserId()
          AND TPB_Tour_State__c = :strState
          AND cgcloud__Product__c = :strProduct
          AND cgcloud__Phase__c = :STATUS_ACTIVE
          AND ((cgcloud__Valid_From__c <= :Date.today()
          AND cgcloud__Valid_Thru__c > :Date.today())
          OR (cgcloud__Valid_From__c < :Date.today()
          AND cgcloud__Valid_Thru__c >= :Date.today()))
        ORDER BY TPB_Tour_State__c, cgcloud__Product__c DESC
        LIMIT 1
      ];
    }

    // return data
    return lstCgcloudInventory;
  }

  /**
   * @description search Tour Data
   * @param   strState           String
   * @return  cgcloud__Tour__c   Tour
   */
  private static cgcloud__Tour__c searchTourData(String strState) {
    //query cgcloud__Tour__c
    return [
      SELECT Id
      FROM cgcloud__Tour__c
      WHERE cgcloud__Start_Warehouse__r.cgcloud__State__c = :strState
      LIMIT 1
    ];
  }

  /**
   * @description upsert Inventory description
   * @param  item         Map<String, String>
   * @return mapResult    Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> upsertInventory(Map<String, String> item) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    //query Tour data
    cgcloud__Tour__c objTour = searchTourData(item.get('state'));
    //query Inventory_Control_Template data
    cgcloud__Inventory_Control_Template__c objInventoryControlTemplate = [
      SELECT Id
      FROM cgcloud__Inventory_Control_Template__c
      WHERE Name = :CONTROL_TEMPLATE
      LIMIT 1
    ];

    //query Criterion_5_Product Product
    Product2 objProduct2 = searchProduct2Data(item.get(PRODUCT_ID));
    //query Inventory StateClassId
    String strStateClassId =
      objProduct2.cgcloud__Criterion_5_Product__c +
      item.get('state') +
      UserInfo.getUserId();
    //get Inventory AvgPrice value
    List<cgcloud__Inventory__c> lstPriceGroupInventory = searchInventory(
      null,
      null,
      strStateClassId
    );
    //no price group product
    if (
      (item.get(INVERTORY_ID) == null ||
      String.isEmpty(item.get(INVERTORY_ID))) &&
      (objProduct2.cgcloud__Criterion_5_Product__c == null ||
      lstPriceGroupInventory.size() == 0)
    ) {
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, ADD_PRICEGROUP_PRODUCT_ERROR);
      return mapResult;
    }

    Savepoint sp = Database.setSavepoint();
    try {
      cgcloud__Inventory__c objInventory = new cgcloud__Inventory__c();
      //Receive data for conversion
      if (
        !String.isEmpty(item.get(INVERTORY_ID)) &&
        item.get(INVERTORY_ID) != null
      ) {
        objInventory.id = item.get(INVERTORY_ID);
      } else {
        //add Inventory data
        objInventory.cgcloud__Description_Language_1__c = 'Inventory description.';
        objInventory.cgcloud__Inventory_Template__c = objInventoryControlTemplate.Id;
        objInventory.cgcloud__Phase__c = STATUS_ACTIVE;
        objInventory.cgcloud__Tour__c = objTour.Id;
        objInventory.cgcloud__User__c = UserInfo.getUserId();
        objInventory.cgcloud__Valid_From__c = Date.today();
        objInventory.cgcloud__Valid_Thru__c = Date.today().addYears(30);
        objInventory.cgcloud__Product__c = item.get(PRODUCT_ID) == null
          ? null
          : item.get(PRODUCT_ID);
        objInventory.TPB_AvgPrice__c = objProduct2.TPB_Exclude_From_Base_Pricing__c ==
          true
          ? null
          : 0;
      }
      //upsert objInventory
      upsert objInventory;

      //add Inventory_Transaction data
      cgcloud__Inventory_Transaction__c objInventoryTransaction = createInventoryTransaction(
        objInventory,
        Decimal.valueOf(item.get(INVERTORY_BALANCE)) -
        Decimal.valueOf(item.get(INVERTORY_OLD_BALANCE))
      );
      insert objInventoryTransaction;

      //query user Inventory Adjustment Amount value
      User objUser = [
        SELECT Id, TPB_Inventory_Adjustment_Amount__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
      ];
      objUser.TPB_Inventory_Adjustment_Amount__c = objUser.TPB_Inventory_Adjustment_Amount__c ==
        null
        ? 0
        : objUser.TPB_Inventory_Adjustment_Amount__c +
          objInventoryTransaction.cgcloud__Amount__c *
          lstPriceGroupInventory[0].TPB_AvgPrice__c;
      update objUser;

      //return data
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      Database.rollback(sp);

      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, objEx.getMessage());

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return data
    return mapResult;
  }

  /**
   * @description search Inventory Transaction
   * @param   objInventory   cgcloud__Inventory__c
   * @param   deciAmount     Decimal
   * @return  objInventoryTransaction   cgcloud__Inventory_Transaction__c
   */
  private static cgcloud__Inventory_Transaction__c createInventoryTransaction(
    cgcloud__Inventory__c objInventory,
    Decimal deciAmount
  ) {
    //add Inventory_Transaction data
    cgcloud__Inventory_Transaction__c objInventoryTransaction = new cgcloud__Inventory_Transaction__c();
    objInventoryTransaction.cgcloud__Inventory__c = objInventory.id;
    objInventoryTransaction.cgcloud__Amount__c = deciAmount;
    //Distinguish whether the number of new or reduced
    if (objInventoryTransaction.cgcloud__Amount__c > 0) {
      objInventoryTransaction.cgcloud__Inventory_Transaction_Template__c = searchInventoryTransactionTemplate(
          TEMPLATE_ADD
        )
        .Id;
    } else if (objInventoryTransaction.cgcloud__Amount__c < 0) {
      objInventoryTransaction.cgcloud__Inventory_Transaction_Template__c = searchInventoryTransactionTemplate(
          TEMPLATE_CASHSALE
        )
        .Id;
    }

    //return objInventoryTransaction data
    return objInventoryTransaction;
  }

  /**
   * @description search Inventory Transaction Template
   * @param   strName        String
   * @return  lstCgcloudInventory    List<cgcloud__Inventory__c>
   */
  private static cgcloud__Inventory_Transaction_Template__c searchInventoryTransactionTemplate(
    String strName
  ) {
    //query Inventory_Transaction_Template
    return [
      SELECT Id
      FROM cgcloud__Inventory_Transaction_Template__c
      WHERE Name = :strName
      LIMIT 1
    ];
  }

  /**
   * @description search Product2 Data
   * @param   strProductId          String
   * @return  lstCgcloudInventory   Product2
   */
  private static Product2 searchProduct2Data(String strProductId) {
    //query Product2
    return [
      SELECT
        Id,
        Name,
        cgcloud__Criterion_5_Product__c,
        TPB_Exclude_From_Base_Pricing__c
      FROM Product2
      WHERE Id = :strProductId AND cgcloud__Product_Level__c = 'Product'
      LIMIT 1
    ];
  }
}