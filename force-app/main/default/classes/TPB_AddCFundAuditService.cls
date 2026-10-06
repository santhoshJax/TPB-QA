/**
 * @author Mi Li
 * @date 5/19/2023
 * @description CON0001729-1161 RSM C-Fund Audit (TSM View)
 */
public with sharing class TPB_AddCFundAuditService {
  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;

  /**
   * @description Verify if there are duplicate products
   * @param   strCFundAuditId        String
   * @param   lCgcUom                List<cgcloud__Unit_of_Measure__c>
   * @param   strState               String
   * @return  objCFundAuditProduct   TPB_CFund_Audit_Product__c
   */
  public static TPB_CFund_Audit_Product__c duplicateProducts(
    String strCFundAuditId,
    List<cgcloud__Unit_of_Measure__c> lCgcUom,
    String strState
  ) {
    //open the unit type after confirming with requirement
    TPB_CFund_Audit_Product__c objCFundAuditProduct = null;
    List<TPB_CFund_Audit_Product__c> lstProductItem = searchCFundAuditProducts(
      strCFundAuditId,
      strState
    );
    //Loop over lstProductItem to compare for duplicates.
    for (TPB_CFund_Audit_Product__c objAuditProduct : lstProductItem) {
      if (
        objAuditProduct.TPB_Actual_Product__c == lCgcUom[0].cgcloud__Product__c
      ) {
        objCFundAuditProduct = objAuditProduct;
        break;
      }
    }

    //return objCFundAuditProduct data
    return objCFundAuditProduct;
  }

  /**
   * @description search Unit Of Measure
   * @param   strCode       String
   * @return  lstCgcUom  List<cgcloud__Unit_of_Measure__c>
   */
  public static List<cgcloud__Unit_of_Measure__c> searchUnitOfMeasure(
    String strCode
  ) {
    //query Unit_of_Measure data
    List<cgcloud__Unit_of_Measure__c> lstCgcUom = [
      SELECT
        Id,
        cgcloud__GTIN__c,
        cgcloud__Product__c,
        cgcloud__Product__r.Name,
        cgcloud__Unit_Type__c
      FROM cgcloud__Unit_of_Measure__c
      WHERE cgcloud__GTIN__c = :strCode
      LIMIT 1
    ];

    //return data
    return lstCgcUom;
  }

  /**
   * @description search Director Approval User
   * @return  strUserId String
   */
  public static String searchDirectorApproval() {
    String strDirectorApproval = null;
    List<GroupMember> lstGroupMember =  [
      SELECT Id, UserOrGroupId
      FROM GroupMember
      WHERE Group.DeveloperName = 'TPB_Director_Approval'
      LIMIT 1
    ];
    if (lstGroupMember.size() > 0) {
       strDirectorApproval = lstGroupMember[0].UserOrGroupId;
    }
      
      //return GroupMember data
      return strDirectorApproval;
  }

  /**
   * @description search Approved User
   * @return  strUserId String
   */
  public static String searchApprovedUser() {
    String strUserId = null;

    String strTerritory;
    //Query User Data
    User objUser = searchUser();
    //get user Territory
    if (objUser.TPB_Parent_Territory__c != null) {
      strTerritory = objUser.TPB_Parent_Territory__c;
    } else if (objUser.TPB_Territory__c != null) {
      strTerritory = objUser.TPB_Territory__c;
    }

    //query Org Unit User  data
    if (strTerritory != '') {
      List<cgcloud__Org_Unit_User__c> lstOrgUnitUser = [
        SELECT Id, cgcloud__Main__c, cgcloud__User__c, cgcloud__Org_Unit__c
        FROM cgcloud__Org_Unit_User__c
        WHERE cgcloud__Org_Unit__r.Name = :strTerritory
        LIMIT 1
      ];
      if (lstOrgUnitUser.size() > 0) {
        strUserId = lstOrgUnitUser[0].cgcloud__User__c;
      }
    }

    //return data
    return strUserId;
  }

  /**
   * @description search User
   * @return  User
   */
  public static User searchUser() {
    //query User data
    User objUser = [
      SELECT
        Id,
        Base_C_Fund_Amount__c,
        TPB_Balance__c,
        TPB_Inventory_Balance__c,
        Name,
        TPB_Reimbursements_Issued__c,
        TPB_Reimbursements_Pending__c,
        Current_C_Fund_Balance__c,
        TPB_Total_Adjustments__c,
        TPB_Parent_Territory__c,
        TPB_Territory__c,
        TPB_Total_Accountable_C_Fund__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    //return data
    return objUser;
  }

  /**
   * @description search Inventory data
   * @param   strState             String
   * @param   strProduct           String
   * @return  objInventory         cgcloud__Inventory__c
   */
  public static cgcloud__Inventory__c searchInventory(
    String strState,
    String strProduct
  ) {
    cgcloud__Inventory__c objInventory = null;
    //query Inventory data
    List<cgcloud__Inventory__c> lstCgcloudInventory = [
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
        AND cgcloud__Phase__c = 'Active'
        AND ((cgcloud__Valid_From__c <= :Date.today()
        AND cgcloud__Valid_Thru__c > :Date.today())
        OR (cgcloud__Valid_From__c < :Date.today()
        AND cgcloud__Valid_Thru__c >= :Date.today()))
      ORDER BY TPB_Tour_State__c, cgcloud__Product__c DESC
      LIMIT 1
    ];

    //get lstCgcloudInventory[0]
    if (lstCgcloudInventory.size() > 0) {
      objInventory = new cgcloud__Inventory__c();
      objInventory = lstCgcloudInventory[0];
    }

    //return data
    return objInventory;
  }

  /**
   * @description search searchCFundAuditProducts
   * @param   strCFundAuditId        String
   * @param   strState        String
   * @return  lstCFundAuditProduct List<TPB_CFund_Audit_Product__c>
   */
  public static List<TPB_CFund_Audit_Product__c> searchCFundAuditProducts(
    String strCFundAuditId,
    String strState
  ) {
    //query all  CFund Audit Product data
    List<TPB_CFund_Audit_Product__c> lstCFundAuditProduct = [
      SELECT
        Id,
        Name,
        TPB_State__c,
        TPB_CFund_Audit__c,
        TPB_Actual_Product__c,
        TPB_CFund_Audit__r.OwnerId,
        TPB_Actual_Product__r.Name,
        TPB_Quantity__c,
        TPB_Unit_Price__c,
        TPB_Total_Amount__c
      FROM TPB_CFund_Audit_Product__c
      WHERE TPB_CFund_Audit__c = :strCFundAuditId AND TPB_State__c = :strState
    ];

    //return data
    return lstCFundAuditProduct;
  }

  /**
   * @description search Inventory Balance Data
   * @param  strState              String
   * @return mapInventoryBalance   Map<String, Decimal>
   */
  public static Map<String, Decimal> searchInventoryBalance(String strState) {
    //Map product Id to UoM
    Map<String, Decimal> mapInventoryBalance = new Map<String, Decimal>();
    //Query all related UoM by Product
    List<cgcloud__Inventory__c> lstInventory = searchAllInventory(strState);
    for (cgcloud__Inventory__c objInventory : lstInventory) {
      if (
        !mapInventoryBalance.containsKey(objInventory.TPB_PricingMergedKey__c)
      ) {
        mapInventoryBalance.put(
          objInventory.TPB_PricingMergedKey__c,
          objInventory.cgcloud__Balance__c
        );
      }
    }

    //return mapInventoryBalance data
    return mapInventoryBalance;
  }

  /**
   * @description get CFundAudit Products
   * @param strCFundAuditId the id the c-fund audit record
   * @param strState the id the c-fund audit record
   * @return list of c-fund audit product
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getCFundAuditProducts(
    String strCFundAuditId,
    String strState
  ) {
    Map<String, Object> mapResult = new Map<String, Object>();
    List<TPB_AddCFundAuditServiceWrapper.CFundAuditProduct> lstResProducts = new List<TPB_AddCFundAuditServiceWrapper.CFundAuditProduct>();
    try {
      // search CFund Audit Products data
      List<TPB_CFund_Audit_Product__c> lstCFundAuditProduct = searchCFundAuditProducts(
        strCFundAuditId,
        strState
      );
      // get Inventory Balance
      Map<String, Decimal> mapInventoryBalance = searchInventoryBalance(
        strState
      );
      if (lstCFundAuditProduct.size() > 0 && strCFundAuditId != null) {
        for (
          TPB_CFund_Audit_Product__c objCFundAuditProduct : lstCFundAuditProduct
        ) {
          //Inventory Balance
          Decimal decimInventoryBalance = 0;
          String strStateValue = strState != '' ? strState + '+' : '';
          String strPricingMergedKey =
            objCFundAuditProduct.TPB_Actual_Product__c +
            '+' +
            strStateValue +
            objCFundAuditProduct.TPB_CFund_Audit__r.OwnerId;
          if (mapInventoryBalance.containsKey(strPricingMergedKey)) {
            decimInventoryBalance = mapInventoryBalance.get(
              strPricingMergedKey
            );
          }
          //CFundAuditProduct Encapsulated as an inner class
          TPB_AddCFundAuditServiceWrapper.CFundAuditProduct oResProduct = new TPB_AddCFundAuditServiceWrapper.CFundAuditProduct();
          oResProduct.setFields(objCFundAuditProduct, decimInventoryBalance);
          lstResProducts.add(oResProduct);
        }
      }
      //return data
      mapResult.put(RTN_KEY_DATA, lstResProducts);
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult data
    return mapResult;
  }

  /**
   * @description update CFundAuditProduct description
   * @param  lstCFundAuditProduct List<CFundAuditProduct>
   * @param  strState             String
   * @return mapResult    Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> updateCFundAuditProduct(
    List<TPB_AddCFundAuditServiceWrapper.CFundAuditProduct> lstCFundAuditProduct,
    String strState
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    Savepoint sp = Database.setSavepoint();
    try {
      //add CFundAuditProduct data
      List<TPB_CFund_Audit_Product__c> lstProducts = addCFundAuditProduct(
        lstCFundAuditProduct,
        strState
      );

      //upsert lstProducts
      if (lstProducts.size() > 0) {
        update lstProducts;
      }

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
   * @description add CFundAudit Product description
   * @param  lstCFundAuditProduct List<CFundAuditProduct>
   * @param  strState             String
   * @return lstProducts          List<TPB_CFund_Audit_Product__c>
   */
  public static List<TPB_CFund_Audit_Product__c> addCFundAuditProduct(
    List<TPB_AddCFundAuditServiceWrapper.CFundAuditProduct> lstCFundAuditProduct,
    String strState
  ) {
    List<TPB_CFund_Audit_Product__c> lstProducts = new List<TPB_CFund_Audit_Product__c>();
    //update all CFundAuditProduct data
    for (
      TPB_AddCFundAuditServiceWrapper.CFundAuditProduct objCFundAuditProduct : lstCFundAuditProduct
    ) {
      TPB_CFund_Audit_Product__c oProduct = new TPB_CFund_Audit_Product__c();
      //id not null
      if (objCFundAuditProduct.id != null) {
        oProduct.id = objCFundAuditProduct.id;
      }
      //unitPrice not null
      if (objCFundAuditProduct.unitPrice != null) {
        oProduct.TPB_Unit_Price__c = objCFundAuditProduct.unitPrice;
      }
      //quantity not null
      if (objCFundAuditProduct.quantity != null) {
        oProduct.TPB_Quantity__c = objCFundAuditProduct.quantity;
      }
      //variance not null
      if (objCFundAuditProduct.variance != null) {
        if (objCFundAuditProduct.variance.contains('(')) {
          oProduct.TPB_Expected_Quantity__c =
            Decimal.valueOf(
              objCFundAuditProduct.variance.replace('(', '').replace(')', '')
            ) + objCFundAuditProduct.quantity;
        }
      }
      //strState not null
      if (strState != null) {
        oProduct.TPB_State__c = strState;
      }
      //add oProduct
      lstProducts.add(oProduct);
    }

    //return lstProducts data
    return lstProducts;
  }

  /**
   * @description delete CFundAudit Product
   * @param  strCFundAuditProductId String
   * @return mapResult   Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> deleteCFundAuditProduct(
    String strCFundAuditProductId
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    Savepoint sp = Database.setSavepoint();
    try {
      //delete CFundAuditProduct when strCFundAuditProductId not null
      if (!String.isEmpty(strCFundAuditProductId)) {
        TPB_CFund_Audit_Product__c oCFundAuditProduct = new TPB_CFund_Audit_Product__c(
          Id = strCFundAuditProductId
        );

        // delete Order Item
        delete oCFundAuditProduct;
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
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
   * @description search Inventory User State
   * @return  mapResult  Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> searchInventoryUserState() {
    Map<String, Object> mapResult = new Map<String, Object>();
    Set<String> setState = new Set<String>();
    try {
      //query Inventory data
      List<cgcloud__Inventory__c> lstCgcloudInventory = searchAllInventory(
        null
      );
      for (cgcloud__Inventory__c objInventory : lstCgcloudInventory) {
        setState.add(objInventory.TPB_Tour_State__c);
      }

      //return data
      mapResult.put(RTN_KEY_DATA, setState);
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return data
    return mapResult;
  }

  /**
   * @description search All Inventory
   * @param   strState String description
   * @return  lstCgcloudInventory  List<cgcloud__Inventory__c>
   */
  public static List<cgcloud__Inventory__c> searchAllInventory(
    String strState
  ) {
    //query Inventory data
    List<cgcloud__Inventory__c> lstCgcloudInventory = new List<cgcloud__Inventory__c>();
    if (strState != null) {
      //query cgcloud__Inventory__c data
      lstCgcloudInventory = [
        SELECT
          Id,
          cgcloud__Product__c,
          cgcloud__Product__r.Name,
          TPB_AvgPrice__c,
          TPB_Tour_State__c,
          cgcloud__User__c,
          cgcloud__Balance__c,
          TPB_StateClassId__c,
          TPB_PricingMergedKey__c
        FROM cgcloud__Inventory__c
        WHERE
          cgcloud__User__c = :UserInfo.getUserId()
          AND TPB_Tour_State__c = :strState
          AND cgcloud__Phase__c = 'Active'
          AND ((cgcloud__Valid_From__c <= :Date.today()
          AND cgcloud__Valid_Thru__c > :Date.today())
          OR (cgcloud__Valid_From__c < :Date.today()
          AND cgcloud__Valid_Thru__c >= :Date.today()))
          AND TPB_Tour_State__c != NULL
          AND cgcloud__Product__c != NULL
        ORDER BY TPB_Tour_State__c DESC
      ];
    } else {
      //query cgcloud__Inventory__c data
      lstCgcloudInventory = [
        SELECT
          Id,
          cgcloud__Product__c,
          cgcloud__Product__r.Name,
          TPB_AvgPrice__c,
          TPB_Tour_State__c,
          cgcloud__User__c,
          cgcloud__Balance__c,
          TPB_StateClassId__c,
          TPB_PricingMergedKey__c
        FROM cgcloud__Inventory__c
        WHERE
          cgcloud__User__c = :UserInfo.getUserId()
          AND cgcloud__Phase__c = 'Active'
          AND ((cgcloud__Valid_From__c <= :Date.today()
          AND cgcloud__Valid_Thru__c > :Date.today())
          OR (cgcloud__Valid_From__c < :Date.today()
          AND cgcloud__Valid_Thru__c >= :Date.today()))
          AND TPB_Tour_State__c != NULL
          AND cgcloud__Product__c != NULL
        ORDER BY TPB_Tour_State__c DESC
      ];
    }

    //return data
    return lstCgcloudInventory;
  }
}