/**
 * @author Mi Li
 * @date 5/19/2023
 * @description CON0001729-1161 RSM C-Fund Audit (TSM View)
 */
public with sharing class TPB_AddCFundAudit {
  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;
  private static final String ADDPRODUCT_ERROR = 'Can not find current product in system.';
  private static final String INVALID_ERROR = 'Invalid function params.';
  private static final String SUBMIT_ERROR = 'No higher level approver can not be submitted for approval!';

  //UoM: Case
  private static final String LAYER = 'Layer';
  private static final String CONSUMERUNITEACH = 'ConsumerUnit';
  //Advanced Order Item Unit: Carton, UoM: Carton
  private static final String SALES_UNIT_CARTON = 'SalesUnit';

  /**
   * @description search CFund Audit
   * @param   strRecord    String
   * @return  TPB_CFund_Audit__c
   */
  private static TPB_CFund_Audit__c searchCFundAudit(String strRecord) {
    TPB_CFund_Audit__c objCFundAudit;
    //query CFund Audit data
    List<TPB_CFund_Audit__c> lstCFundAudit = [
      SELECT
        Id,
        Name,
        TPB_RSM_Name__c,
        TPB_Total_Adjustments__c,
        TPB_Total_Accountable_C_Fund__c,
        TPB_Pending_Reimbursements__c,
        TPB_Promo_Value__c,
        TPB_Cash_On_Hand__c,
        TPB_Actual_Cash_And_Cash_Equivalent__c,
        TPB_Cash_Variance__c,
        TPB_Product_Variance__c,
        TPB_Audit_Result__c,
        TPB_Bank_Balance__c,
        TPB_Status__c,
        TPB_Base_CFund_New__c,
        TPB_Expected_Cash_Equivalents_New__c,
        TPB_Expected_Product_Value_New__c
      FROM TPB_CFund_Audit__c
      WHERE Id = :strRecord
    ];
    if (lstCFundAudit.size() > 0) {
      objCFundAudit = lstCFundAudit[0];
    }

    //return data
    return objCFundAudit;
  }

  /**
   * @description init query CFund Audit data
   * @param   strRecord    String
   * @return  mapResult Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> init(String strRecord) {
    Map<String, Object> mapResult = new Map<String, Object>();
    try {
      //query User data
      User objUser = TPB_AddCFundAuditService.searchUser();
      //Define Inner class to encapsulate data
      TPB_AddCFundAuditWrapper.CFundAudit objCFundAuditClass = new TPB_AddCFundAuditWrapper.CFundAudit();
      objCFundAuditClass.baseCFund = objUser.Base_C_Fund_Amount__c;
      objCFundAuditClass.expectedProductValue = objUser.TPB_Inventory_Balance__c;
      objCFundAuditClass.totalAccountableCFund = objUser.TPB_Total_Accountable_C_Fund__c;
      objCFundAuditClass.totalAdjustments = objUser.TPB_Total_Adjustments__c;
      objCFundAuditClass.expectedCashAndCashEquivalents = objUser.Current_C_Fund_Balance__c;
      objCFundAuditClass.promoValue = objUser.TPB_Reimbursements_Issued__c;
      objCFundAuditClass.pendingReimbursements = objUser.TPB_Reimbursements_Pending__c;

      //When CFund_ Assign data when Audit is not empty
      TPB_CFund_Audit__c objCFundAudit = searchCFundAudit(strRecord);
      if (objCFundAudit != null) {
        objCFundAuditClass.totalAdjustments = objCFundAudit.TPB_Total_Adjustments__c;
        objCFundAuditClass.totalAccountableCFund = objCFundAudit.TPB_Total_Accountable_C_Fund__c;
        objCFundAuditClass.promoValue = objCFundAudit.TPB_Promo_Value__c;
        objCFundAuditClass.pendingReimbursements = objCFundAudit.TPB_Pending_Reimbursements__c;
        objCFundAuditClass.expectedCashAndCashEquivalents = objCFundAudit.TPB_Expected_Cash_Equivalents_New__c;
        objCFundAuditClass.baseCFund = objCFundAudit.TPB_Base_CFund_New__c;
        objCFundAuditClass.expectedProductValue = objCFundAudit.TPB_Expected_Product_Value_New__c;
        mapResult.put(
          RTN_KEY_DATA + TPB_CFund_Audit__c.sObjectType,
          objCFundAudit
        );
      }

      //Return Data
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      mapResult.put(RTN_KEY_DATA, objCFundAuditClass);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description save And Submit
   * @param   cFundAuditData    CFundAudit
   * @return  mapResult         Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> saveAndSubmit(
    TPB_AddCFundAuditWrapper.CFundAudit cFundAuditData
  ) {
    Map<String, String> mapResult = new Map<String, String>{};
    Savepoint sp = Database.setSavepoint();
    try {
      TPB_CFund_Audit__c objCFundAudit = new TPB_CFund_Audit__c();
      //totalAdjustments not null
      objCFundAudit.TPB_Total_Adjustments__c = cFundAuditData.totalAdjustments;
      // bankBalance not null
      objCFundAudit.TPB_Bank_Balance__c = cFundAuditData.bankBalance;
      // pendingReimbursements not null
      objCFundAudit.TPB_Pending_Reimbursements__c = cFundAuditData.pendingReimbursements;
      // promoValue not null
      objCFundAudit.TPB_Promo_Value__c = cFundAuditData.promoValue;
      // actualCashOnHand not null
      objCFundAudit.TPB_Cash_On_Hand__c = cFundAuditData.actualCashOnHand;
      // totalAccountableCFund not null
      objCFundAudit.TPB_Total_Accountable_C_Fund__c = cFundAuditData.totalAccountableCFund;
      // baseCFund not null
      objCFundAudit.TPB_Base_CFund_New__c = cFundAuditData.baseCFund;
      // expectedProductValue not null
      objCFundAudit.TPB_Expected_Product_Value_New__c = cFundAuditData.expectedProductValue;
      // expectedCashAndCashEquivalents not null
      objCFundAudit.TPB_Expected_Cash_Equivalents_New__c = cFundAuditData.expectedCashAndCashEquivalents;
      //get RSM user
      objCFundAudit.TPB_RSM_Name__c = TPB_AddCFundAuditService.searchApprovedUser();
      //get Director Approval
      objCFundAudit.TPB_Director_Approval__c = TPB_AddCFundAuditService.searchDirectorApproval();

      //recordId not null
      if (
        !String.isEmpty(cFundAuditData.recordId) &&
        cFundAuditData.recordId != null
      ) {
        objCFundAudit.Id = cFundAuditData.recordId;

        //update CFundAudit
        update objCFundAudit;
      } else {
        objCFundAudit.TPB_Status__c = 'Draft';

        //insert CFundAudit
        insert objCFundAudit;

        insertCFundAuditProduct(objCFundAudit.Id);
      }

      //Return Data
      mapResult.put(RTN_KEY_DATA, objCFundAudit.Id);
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      Database.rollback(sp);

      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, objEx.getMessage());

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description submit And Process Approval Request
   * @param   cFundAuditData       CFundAudit
   * @return  mapResult            Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> submitAndProcessApprovalRequest(
    TPB_AddCFundAuditWrapper.CFundAudit cFundAuditData
  ) {
    Map<String, String> mapResult = new Map<String, String>{};
    try {
      //Save the modified data first before submitting for approval
      Map<String, String> mapSaveResult = saveAndSubmit(cFundAuditData);
      if (mapSaveResult.get(RTN_KEY_RESULT) == RTN_KEY_OK) {
        //query TPB_CFund_Audit__c data
        TPB_CFund_Audit__c objCFundAudit = [
          SELECT
            Id,
            Name,
            TPB_Status__c,
            TPB_RSM_Name__c,
            TPB_Total_Variance_Amount__c
          FROM TPB_CFund_Audit__c
          WHERE Id = :cFundAuditData.recordId
        ];
        //Entering the Approval Stream
        if (
          objCFundAudit.TPB_Total_Variance_Amount__c <= -100 ||
          objCFundAudit.TPB_Total_Variance_Amount__c >= 250
        ) {
          //Error message indicating no approver
          if (objCFundAudit.TPB_RSM_Name__c == null) {
            mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
            mapResult.put(RTN_KEY_ERR_MSG, SUBMIT_ERROR);

            return mapResult;
          }
          // Create an approval request
          Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
          // record Id
          req.setObjectId(cFundAuditData.recordId);
          // Submit on behalf of a specific submitter
          req.setSubmitterId(UserInfo.getUserId());
          req.setProcessDefinitionNameOrId('TPB_CFund_Audit_Approval2');

          // Submit the approval request for the
          Approval.process(req);
          //Successfully submitted for approval
        } else {
          //update objCFundAudit data
          objCFundAudit.TPB_Status__c = 'Approved';
          update objCFundAudit;
        }

        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
    } catch (Exception objEx) {
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, objEx.getMessage());

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    // return data
    return mapResult;
  }

  /**
   * @description insert CFund Audit Product
   * @param   strCFundAuditId   String
   */
  private static void insertCFundAuditProduct(String strCFundAuditId) {
    //query Unit_of_Measure data
    List<TPB_CFund_Audit_Product__c> lstInsertCFundAuditProduct = new List<TPB_CFund_Audit_Product__c>();
    Savepoint sp = Database.setSavepoint();
    try {
      // search Inventory data
      List<cgcloud__Inventory__c> lstCgcloudInventory = TPB_AddCFundAuditService.searchAllInventory(
        null
      );
      for (cgcloud__Inventory__c objInventory : lstCgcloudInventory) {
        TPB_CFund_Audit_Product__c ojbAuditProduct = new TPB_CFund_Audit_Product__c();
        ojbAuditProduct.TPB_Actual_Product__c = objInventory.cgcloud__Product__c;
        ojbAuditProduct.TPB_CFund_Audit__c = strCFundAuditId;
        ojbAuditProduct.TPB_Quantity__c = 0;
        ojbAuditProduct.TPB_State__c = objInventory.TPB_Tour_State__c;
        ojbAuditProduct.TPB_Unit_Price__c = objInventory.TPB_AvgPrice__c;
        ojbAuditProduct.TPB_Expected_Quantity__c = objInventory.cgcloud__Balance__c;
        lstInsertCFundAuditProduct.add(ojbAuditProduct);
      }

      if (lstInsertCFundAuditProduct.size() > 0) {
        insert lstInsertCFundAuditProduct;
      }
    } catch (Exception objEx) {
      Database.rollback(sp);

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }
  }

  /**
   * @description  add Scanned Product
   * @param   strCFundAuditId  String
   * @param   strCode          String
   * @param   strState         String
   * @return  mapOrderData     Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> addScannedProduct(
    String strCFundAuditId,
    String strCode,
    String strState
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
    Savepoint sp = Database.setSavepoint();
    try {
      //Determine if it is empty, return if it is empty
      if (String.isEmpty(strCFundAuditId) || String.isEmpty(strCode)) {
        mapResult.put(RTN_KEY_ERR_MSG, INVALID_ERROR);
        return mapResult;
      }

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

      // Seciton: check product duplication
      TPB_CFund_Audit_Product__c objCFundAuditProduct = TPB_AddCFundAuditService.duplicateProducts(
        strCFundAuditId,
        lCgcUom,
        strState
      );
      //calculationOfCommutedQuantities
      Double dolQuantity = calculationOfCommutedQuantities(lCgcUom[0]);
      //Found that the added product already exists, directly return
      if (objCFundAuditProduct != null) {
        objCFundAuditProduct.TPB_Quantity__c += dolQuantity;
        update objCFundAuditProduct;

        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
        return mapResult;
      }

      // Seciton: get UnitPrice
      // TODO: complet the get unit price section
      // Seciton: add a c-fund audit product finally
      TPB_CFund_Audit_Product__c oNewProduct = addCFundAuditProduct(
        strState,
        lCgcUom[0].cgcloud__Product__c,
        strCFundAuditId,
        dolQuantity
      );
      insert oNewProduct;

      //return data
      mapResult.put(RTN_KEY_DATA, oNewProduct);
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      Database.rollback(sp);

      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, objEx.getMessage());

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description calculationOfCommutedQuantities
   * @param   objUoMFromMap    cgcloud__Unit_of_Measure__c
   * @return  currentOrderItemQuantity   Double
   */
  public static Double calculationOfCommutedQuantities(
    cgcloud__Unit_of_Measure__c objUoMFromMap
  ) {
    Double currentOrderItemQuantity = 1;
    if (objUoMFromMap.cgcloud__Unit_Type__c == SALES_UNIT_CARTON) {
      return currentOrderItemQuantity;
    }

    //get search Uom Data
    Map<String, List<cgcloud__Unit_of_Measure__c>> mapPrdId2UoM = TPB_MassPrebookAdOrderFlow.searchUomData(
      new Set<String>{ objUoMFromMap.cgcloud__Product__c }
    );
    //Store each, carton, case  relationship
    Double numCase;
    Double numCarton;
    for (
      cgcloud__Unit_of_Measure__c objUoM : mapPrdId2UoM.get(
        objUoMFromMap.cgcloud__Product__c
      )
    ) {
      //Store current product UoM unit price
      if (objUoM.cgcloud__Unit_Type__c == SALES_UNIT_CARTON) {
        numCarton = objUoM.cgcloud__Pieces_per_Smallest_Unit__c;
      } else if (objUoM.cgcloud__Unit_Type__c == LAYER) {
        numCase = objUoM.cgcloud__Pieces_per_Smallest_Unit__c;
      }
    }
    //if each, multiply
    if (objUoMFromMap.cgcloud__Unit_Type__c == CONSUMERUNITEACH) {
      currentOrderItemQuantity = currentOrderItemQuantity / numCarton;
    } else if (objUoMFromMap.cgcloud__Unit_Type__c == LAYER) {
      //if each, divide first to get each, then multiply to get carton
      currentOrderItemQuantity =
        currentOrderItemQuantity * (numCase / numCarton);
    }

    return currentOrderItemQuantity;
  }

  /**
   * @description add CFund Audit Product
   * @param   strState          String
   * @param   strProductId      String
   * @param   strCFundAuditId   String
   * @param   dolQuantity       Double
   * @return  oNewProduct       TPB_CFund_Audit_Product__c
   */
  private static TPB_CFund_Audit_Product__c addCFundAuditProduct(
    String strState,
    String strProductId,
    String strCFundAuditId,
    Double dolQuantity
  ) {
    cgcloud__Inventory__c objInventory = TPB_AddCFundAuditService.searchInventory(
      strState,
      strProductId
    );
    // Seciton: get UnitPrice
    // TODO: complet the get unit price section
    // Seciton: add a c-fund audit product finally
    TPB_CFund_Audit_Product__c oNewProduct = new TPB_CFund_Audit_Product__c(
      TPB_CFund_Audit__c = strCFundAuditId,
      TPB_Actual_Product__c = strProductId,
      TPB_Quantity__c = objInventory != null
        ? objInventory.cgcloud__Balance__c
        : dolQuantity, // requirement: default 1
      TPB_Expected_Quantity__c = objInventory != null
        ? objInventory.cgcloud__Balance__c
        : dolQuantity, // requirement: default 1
      TPB_State__c = strState,
      TPB_Unit_Price__c = objInventory != null
        ? objInventory.TPB_AvgPrice__c
        : 0 // TODO: read from db
    );

    return oNewProduct;
  }
}