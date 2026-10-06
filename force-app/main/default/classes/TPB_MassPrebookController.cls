/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screen flow for Mass Prebook
 */
public without sharing class TPB_MassPrebookController {
  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;

  //is run Test class
  public static boolean boolRunTest = false;

  //Order  Van_Load recordType Id
  public static String orderMassPrebookRecordTypeId = TPB_TestFactory.orderMassPrebookRecordTypeId;

  //Interface transfer variable
  private static final String ORDER_TYPE = 'Promo';
  private static final String ORDER_TYPE_STOCK = 'Straight Stock';
  private static final String MASS_PREBOOK_ORDER_FILE = 'MassPrebookOrderFile';
  private static final String MASS_PREBOOK_ORG_UNIT_ORDER_FILE = 'MassPrebookOrderOrgUnitFile';
  private static final String MASS_PREBOOK_FILE_NAME = 'Frame';

  private static final String ORDER_ID = 'OrderId';
  private static final String ORDER_TYPE_API = 'OrderType';
  private static final String ACCOUNT_ORG_UNIT = 'mapAccOrgUnit';
  private static final String ACCOUNT_ORG_UNIT_QUANTITY = 'mapOrgUnitQuantity';

  //error message
  private static final String HQ_ACCOUNT_ERR_MSG = 'Error occurred, give your Admin these details: Allocation could not be deducted because the parent owner of this account is the Main user of Org Units. Please clean up Org Unit Data to allow for proper allocation deduction.';
  private static final String PROMOTION_ERR_MSG = 'The selected promotion has no allocations for this HQ.';
  private static final String COMPLETE_ERR_MSG = 'The current Mass Prebook Order is complete.';
  private static final String MAX_QUANTITY_ERR_MSG = 'User cannot order more than the max quantity for this product at this store';
  private static final String SHIPDATE_ERR_MSG = 'Ship Date must be later than today’s date and within the Start and End Dates';

  /**
   * @description get All Wholesaler Account data
   * @param   strHqAccountId    String
   * @param   strProductId      String
   * @param   strShipDateFrom   String
   * @param   strProductPromotion   String
   * @param   strWave   String
   * @return  mapResult         Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> getAllWholesalerAccount(
    String strHqAccountId,
    String strProductId,
    String strShipDateFrom,
    String strProductPromotion,
    String strWave
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
    try {
      // select product
      if (
        String.isNotBlank(strHqAccountId) && String.isNotBlank(strProductId)
      ) {
        if (
          ORDER_TYPE_STOCK == strProductPromotion &&
          Date.valueOf(strShipDateFrom) <= Date.today()
        ) {
          mapResult.put(RTN_KEY_ERR_MSG, SHIPDATE_ERR_MSG);

          return mapResult;
        }

        if (ORDER_TYPE == strProductPromotion) {
          Account objHQAccountOwnerId = [
            SELECT Id, OwnerId
            FROM Account
            WHERE id = :strHqAccountId
          ];
          //query cgcloud__Org_Unit_User__c data
          List<cgcloud__Org_Unit_User__c> lstAccountOrgUnit = TPB_MassPrebookService.searchChainOrgUnitData(
            new Set<String>{ objHQAccountOwnerId.OwnerId }
          );
          //return data
          if (lstAccountOrgUnit.size() > 1 || lstAccountOrgUnit.size() == 0) {
            mapResult.put(RTN_KEY_ERR_MSG, HQ_ACCOUNT_ERR_MSG);

            return mapResult;
          }
        }

        //create partner Order Data
        Map<String, Order> mapPartnerAccountOrder = createOrderData(
          null,
          new Set<String>{ strHqAccountId },
          strProductId,
          strShipDateFrom,
          strWave,
          TPB_AddInventoryPurchasedFormService.searchPricebook2()[0].Id
        );
        //insert data
        insert mapPartnerAccountOrder.values();

        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
        mapResult.put(
          RTN_KEY_DATA + ORDER_ID,
          mapPartnerAccountOrder.get(strHqAccountId).Id
        );
        mapResult.put(RTN_KEY_DATA + 'AccountId', strHqAccountId);
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description search DataResult data
   * @param   strOrderId        String
   * @param   strHqAccountId    String
   * @return  mapResult         Map<String, Object>
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> searchDataResult(
    String strOrderId,
    String strHqAccountId
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    //getOrderData
    if (String.isBlank(strOrderId) || String.isBlank(strHqAccountId)) {
        mapResult.put(RTN_KEY_DATA, null);
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
  
        return mapResult;
    }
    try {
      //getOrderData
      Order objOrderData = TPB_MassPrebookService.getOrderData(strOrderId);
      //getDataAll
      List<String> lstString = TPB_MassPrebookControllerUtility.getDataAll(
        strOrderId,
        MASS_PREBOOK_ORDER_FILE + '%'
      );
      if (lstString.size() > 0) {
        //return file data
        mapResult.put(RTN_KEY_DATA, lstString);
      } else {
        //get All Wholesaler Account
        Map<String, Account> mapWholesalerAccount = TPB_MassPrebookService.getAllWholesalerAccount(
          strHqAccountId
        );
        //get all Promotion Allocation Item data
        Map<String, TPB_Promotion_Allocation_Item__c> mapProductPromotionAllocationItem = new Map<String, TPB_Promotion_Allocation_Item__c>();
        //order type is Promo
        if (
          objOrderData.TPB_Mass_Prebook_Product__r.NTC_Item_Classification__c ==
          ORDER_TYPE
        ) {
          mapProductPromotionAllocationItem = TPB_MassPrebookService.getAllPromotionAllocationItem(
            strHqAccountId,
            objOrderData.TPB_Mass_Prebook_Product__c,
            objOrderData.TPB_Wave_Order_Date__c,
            new Set<String>()
          );
        }

        //create OrderItem Data
        Map<String, OrderItem> mapAccOrderItem = createOrderItemData(
          objOrderData.TPB_Mass_Prebook_Product__c,
          mapWholesalerAccount.KeySet(),
          mapProductPromotionAllocationItem,
          objOrderData.TPB_Mass_Prebook_Product__r.NTC_Item_Classification__c
        );
        //get Wholesaler Account
        Map<String, TPB_MassPrebookWrapper.WholesalerAccount> mapRetailerAccount = TPB_MassPrebookService.getWholesalerAccount(
          strHqAccountId
        );

        //data Encapsulation
        List<TPB_MassPrebookWrapper.MassPrebookDetail> lstMassPrebookWrapper = dataEncapsulation(
          mapAccOrderItem,
          mapRetailerAccount,
          strHqAccountId,
          mapWholesalerAccount
        );
        //return file data
        mapResult.put(RTN_KEY_DATA, lstMassPrebookWrapper);
      }

      //return result
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description data Encapsulation data
   * @param   mapAccOrderItem         Map<String, OrderItem>
   * @param   mapRetailerAccount      Map<String, TPB_MassPrebookWrapper.WholesalerAccount>
   * @param   strHqAccount            String
   * @param   mapWholesalerAccount    Map<String, Account>
   * @return  lstMassPrebookWrapper   List<TPB_MassPrebookWrapper.MassPrebookDetail>
   */
  public static List<TPB_MassPrebookWrapper.MassPrebookDetail> dataEncapsulation(
    Map<String, OrderItem> mapAccOrderItem,
    Map<String, TPB_MassPrebookWrapper.WholesalerAccount> mapRetailerAccount,
    String strHqAccount,
    Map<String, Account> mapWholesalerAccount
  ) {
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstMassPrebookWrapper = new List<TPB_MassPrebookWrapper.MassPrebookDetail>();
    for (String strAccount : mapAccOrderItem.KeySet()) {
      //Encapsulated as an inner class
      TPB_MassPrebookWrapper.MassPrebookDetail objMassPrebookWrapper = new TPB_MassPrebookWrapper.MassPrebookDetail();
      if (mapRetailerAccount.containsKey(strAccount)) {
        objMassPrebookWrapper.setProductFields(
          mapRetailerAccount.get(strAccount),
          mapAccOrderItem.get(strAccount),
          strAccount
        );
      } else {
        //Retailer account not WholesalerAccount
        TPB_MassPrebookWrapper.WholesalerAccount objWholesaler = new TPB_MassPrebookWrapper.WholesalerAccount();
        if (mapWholesalerAccount != null && mapWholesalerAccount.size() > 0) {
          objWholesaler.acNu = mapWholesalerAccount.get(strAccount)
            .Account_Number_old__c;
          objWholesaler.acNm = mapWholesalerAccount.get(strAccount).Name;
          objWholesaler.ads = mapWholesalerAccount.get(strAccount)
            .ShippingStreet;
          objWholesaler.cty = mapWholesalerAccount.get(strAccount).ShippingCity;
          objWholesaler.sta = mapWholesalerAccount.get(strAccount)
            .ShippingState;
          objWholesaler.zip = mapWholesalerAccount.get(strAccount)
            .ShippingPostalCode;
          objWholesaler.wsNm = '';
          objWholesaler.ws = '';
          objWholesaler.nTNu = mapWholesalerAccount.get(strAccount)
            .Internal_Customer_ID__c;
          objWholesaler.wsCt = '';
          objWholesaler.rAcId = '';
        } else {
          objWholesaler.acNu = mapAccOrderItem.get(strAccount)
            .Order.Account.Account_Number_old__c;
          objWholesaler.acNm = mapAccOrderItem.get(strAccount)
            .Order.Account.Name;
          objWholesaler.ads = mapAccOrderItem.get(strAccount)
            .Order.Account.ShippingStreet;
          objWholesaler.cty = mapAccOrderItem.get(strAccount)
            .Order.Account.ShippingCity;
          objWholesaler.sta = mapAccOrderItem.get(strAccount)
            .Order.Account.ShippingState;
          objWholesaler.zip = mapAccOrderItem.get(strAccount)
            .Order.Account.ShippingPostalCode;
          objWholesaler.wsNm = '';
          objWholesaler.ws = '';
          objWholesaler.nTNu = mapAccOrderItem.get(strAccount)
            .Order.Account.Internal_Customer_ID__c;
          objWholesaler.wsCt = '';
          objWholesaler.rAcId = '';
        }

        //set Product Fields
        objMassPrebookWrapper.setProductFields(
          objWholesaler,
          mapAccOrderItem.get(strAccount),
          strAccount
        );
      }
      lstMassPrebookWrapper.add(objMassPrebookWrapper);
    }

    //return lstMassPrebookWrapper
    return lstMassPrebookWrapper;
  }

  /**
   * @description create OrderData
   * @param   strOrderId        String
   * @param   setAccountId      Set<String>
   * @param   strProductId      String
   * @param   strShipDateFrom   String
   * @param   strWave           String
   * @param   strPriceBookId    String
   * @return  mapAccountOrder   Map<String, Order>
   */
  public static Map<String, Order> createOrderData(
    String strOrderId,
    Set<String> setAccountId,
    String strProductId,
    String strShipDateFrom,
    String strWave,
    String strPriceBookId
  ) {
    Map<String, Order> mapAccountOrder = new Map<String, Order>();
    //create order data
    for (String strAccountId : setAccountId) {
      Order objOrder = new Order();
      objOrder.Status = 'Draft';
      objOrder.TPB_Child_Order__c = strOrderId;
      objOrder.EffectiveDate = Date.today();
      objOrder.AccountId = strAccountId;
      objOrder.TPB_Mass_Prebook_Product__c = strProductId;
      //strOrderId not null
      if (strOrderId == null || String.isBlank(strOrderId)) {
        objOrder.TPB_HQ_Account__c = strAccountId;
      }
      //strShipDateFrom not null
      if (strShipDateFrom != null && String.isNotBlank(strShipDateFrom)) {
        objOrder.TPB_Ship_Date__c = Date.valueOf(strShipDateFrom);
      }
      //strWave not null
      if (strWave != null && String.isNotBlank(strWave)) {
        objOrder.TPB_Wave_Order_Date__c = strWave;
      }
      objOrder.Pricebook2Id = strPriceBookId;
      objOrder.RecordTypeId = orderMassPrebookRecordTypeId;

      mapAccountOrder.put(strAccountId, objOrder);
    }

    //return mapAccountOrder
    return mapAccountOrder;
  }

  /**
   * @description getOrder RecordType
   * @param   strRecordId        String
   * @return  mapResult          Map<String, Order>
   */
  @AuraEnabled
  public static Map<String, Object> getOrderRecordType(String strRecordId) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
    try {
      //get Orde rData
      Order objOrder = TPB_MassPrebookService.getOrderData(strRecordId);
      //return data DeveloperName value
      if (objOrder != null) {
        mapResult.put(RTN_KEY_DATA, objOrder.RecordType.DeveloperName);
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return mapResult;
  }

  /**
   * @description validations Promotion
   * @param   strProductId    String
   * @param   strHqAccountId  String
   * @return  mapResult       Map<String, Order>
   */
  @AuraEnabled
  public static Map<String, Object> validationsPromotion(
    String strProductId,
    String strHqAccountId
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
    try {
      //get All Wave Date
      Set<String> setDateWave = TPB_MassPrebookService.getAllWaveDate(
        strHqAccountId,
        strProductId
      );
      //return data
      if (setDateWave.size() > 0) {
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
        mapResult.put(RTN_KEY_DATA, setDateWave);
      } else {
        mapResult.put(RTN_KEY_ERR_MSG, PROMOTION_ERR_MSG);
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return mapResult;
  }

  /**
   * @description get Order Data
   * @param   strOrderId     String
   * @return  mapResult      Map<String, Order>
   */
  @AuraEnabled
  public static Map<String, Object> getOrderData(String strOrderId) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    try {
      //get Order Data For Partner Order
      Order objOrder = TPB_MassPrebookService.getOrderData(strOrderId);

      //return data
      mapResult.put(
        RTN_KEY_DATA + ORDER_TYPE_API,
        objOrder.TPB_Mass_Prebook_Product__r.NTC_Item_Classification__c
      );
      mapResult.put(RTN_KEY_DATA, objOrder);
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return mapResult;
  }

  /**
   * @description update OrderItems data
   * @param   lstInputItems    List<Map<String, String>>
   * @param   strOrderType     String
   * @param   strOrderId       String
   * @return  mapResult        Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> updateOrderItems(
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstInputItems,
    String strOrderType,
    String strOrderId
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    Savepoint sp = Database.setSavepoint();
    try {
      Boolean boolValidations = false;
      Map<String, String> mapAccOrgUnit = new Map<String, String>();
      Map<String, Object> mapVerifyResult = new Map<String, Object>{};
      //order type is Promo
      if (strOrderType == ORDER_TYPE) {
        Order objOrderData = TPB_MassPrebookService.getOrderData(strOrderId);

        //get Verification Result
        mapVerifyResult = TPB_MassPrebookControllerUtility.verifyQuantityOfProductRemaining(
          lstInputItems,
          objOrderData,
          true,
          new Map<String, Double>(),
          new Map<String, String>()
        );

        //get Validations result
        boolValidations = Boolean.valueOf(
          mapVerifyResult.get('boolValidations')
        );
        //get mapAccount Org Unit result
        mapAccOrgUnit = (Map<String, String>) mapVerifyResult.get(
          ACCOUNT_ORG_UNIT
        );
      }

      //return err message
      if (boolValidations && strOrderType == ORDER_TYPE) {
        String strError = mapVerifyResult.get(RTN_KEY_ERR_MSG) == null
          ? MAX_QUANTITY_ERR_MSG
          : String.valueOf(mapVerifyResult.get(RTN_KEY_ERR_MSG));
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
        mapResult.put(RTN_KEY_ERR_MSG, strError);

        return mapResult;
      } else {
        //delete old File
        TPB_MassPrebookControllerUtility.deleteFile(
          strOrderId,
          MASS_PREBOOK_ORDER_FILE + '%'
        );
        //add new MassPrebook File
        TPB_MassPrebookControllerUtility.uploadFile(
          new List<String>{ JSON.serialize(lstInputItems) },
          MASS_PREBOOK_ORDER_FILE,
          MASS_PREBOOK_ORDER_FILE,
          strOrderId,
          false
        );

        if (strOrderType == ORDER_TYPE) {
          //delete old File
          TPB_MassPrebookControllerUtility.deleteFile(
            strOrderId,
            MASS_PREBOOK_ORG_UNIT_ORDER_FILE + '%'
          );

          //add account and org unit data
          TPB_MassPrebookControllerUtility.uploadFile(
            new List<String>{ JSON.serialize(mapAccOrgUnit) },
            MASS_PREBOOK_ORG_UNIT_ORDER_FILE,
            MASS_PREBOOK_ORG_UNIT_ORDER_FILE,
            strOrderId,
            true
          );
        }

        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
    } catch (Exception objEx) {
      Database.rollback(sp);
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return mapResult;
  }

  /**
   * @description saveOrderByFrame
   * @param   intFrameIndex   Current batch
   * @param   intFrameTotal   countOfBatch,  How many batches there are in total
   * @param   lstRows         Data of the current batch
   * @param   mapOrderData    Map<String, String>
   * @return  mapResult       Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, Object> saveOrderByFrame(
    Integer intFrameIndex,
    Integer intFrameTotal,
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstRows,
    Map<String, Object> mapOrderData
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    Map<String, Object> mapResultVerify = new Map<String, Object>{};
    Savepoint sp = Database.setSavepoint();
    try {
      //boolValidations
      Boolean boolValidations = false;
      Map<String, Double> mapOrgUnitQuantity = new Map<String, Double>();
      Map<String, String> mapAccOrgUnit = new Map<String, String>();
      //The amount of org unit used by all the same stores
      if (mapOrderData.containsKey(ACCOUNT_ORG_UNIT_QUANTITY)) {
        Map<Object, Object> mapOrgUnitQuantityValue = (Map<Object, Object>) mapOrderData.get(
          ACCOUNT_ORG_UNIT_QUANTITY
        );
        for (Object str : mapOrgUnitQuantityValue.KeySet()) {
          mapOrgUnitQuantity.put(
            String.valueOf(str),
            mapOrgUnitQuantityValue.get(str) == null
              ? 0
              : Double.valueOf(mapOrgUnitQuantityValue.get(str))
          );
        }
      }
      if (mapOrderData.containsKey(ACCOUNT_ORG_UNIT)) {
        Map<Object, Object> mapOrderDataValue = (Map<Object, Object>) mapOrderData.get(
          ACCOUNT_ORG_UNIT
        );
        for (Object str : mapOrderDataValue.KeySet()) {
          mapAccOrgUnit.put(
            String.valueOf(str),
            mapOrderDataValue.get(str) == null
              ? ''
              : String.valueOf(mapOrderDataValue.get(str))
          );
        }
      }

      //getOrderData
      Order objOrderData = TPB_MassPrebookService.getOrderData(
        String.valueOf(mapOrderData.get(ORDER_ID))
      );
      //order type is Promo
      if (String.valueOf(mapOrderData.get(ORDER_TYPE_API)) == ORDER_TYPE) {
        //verifyQuantityOfProductRemaining
        mapResultVerify = TPB_MassPrebookControllerUtility.verifyQuantityOfProductRemaining(
          lstRows,
          objOrderData,
          false,
          mapOrgUnitQuantity,
          mapAccOrgUnit
        );
        //get  Validations result
        boolValidations = Boolean.valueOf(
          mapResultVerify.get('boolValidations')
        );
        mapOrgUnitQuantity = (Map<String, Double>) mapResultVerify.get(
          ACCOUNT_ORG_UNIT_QUANTITY
        );
        mapAccOrgUnit = (Map<String, String>) mapResultVerify.get(
          ACCOUNT_ORG_UNIT
        );
      }

      //return err message
      if (
        boolValidations &&
        String.valueOf(mapOrderData.get(ORDER_TYPE_API)) == ORDER_TYPE
      ) {
        //delete old File
        TPB_MassPrebookControllerUtility.deleteFile(
          String.valueOf(mapOrderData.get(ORDER_ID)),
          MASS_PREBOOK_FILE_NAME +
          MASS_PREBOOK_ORDER_FILE +
          '%'
        );

        String strError = mapResultVerify.get(RTN_KEY_ERR_MSG) == null
          ? MAX_QUANTITY_ERR_MSG
          : String.valueOf(mapResultVerify.get(RTN_KEY_ERR_MSG));
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
        mapResult.put(RTN_KEY_ERR_MSG, strError);

        return mapResult;
      } else {
        //add new File
        String strFileName =
          MASS_PREBOOK_FILE_NAME +
          MASS_PREBOOK_ORDER_FILE +
          String.valueOf(intFrameIndex);
        //upload File
        TPB_MassPrebookControllerUtility.uploadFile(
          new List<String>{ JSON.serialize(lstRows) },
          strFileName,
          strFileName,
          String.valueOf(mapOrderData.get(ORDER_ID)),
          true
        );

        if (intFrameIndex == intFrameTotal && intFrameTotal > 1) {
          saveFileData(mapOrderData, mapAccOrgUnit, objOrderData);
        }

        //add totalQuantity
        mapOrderData.put(ACCOUNT_ORG_UNIT_QUANTITY, mapOrgUnitQuantity);
        mapOrderData.put(ACCOUNT_ORG_UNIT, mapAccOrgUnit);
        //return mapResult
        mapResult.put('mapOrderData', mapOrderData);
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
    } catch (Exception objEx) {
      //Database.rollback(sp);
      //delete old File
      TPB_MassPrebookControllerUtility.deleteFile(
        String.valueOf(mapOrderData.get(ORDER_ID)),
        MASS_PREBOOK_FILE_NAME +
        MASS_PREBOOK_ORDER_FILE +
        '%'
      );

      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, objEx.getMessage());
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return mapResult;
  }

  /**
   * @description saveFileData
   * @param   mapOrderData   Map<String, Object>
   * @param   mapAccOrgUnit  Map<String, String>
   * @param   objOrderData   Order
   */
  public static void saveFileData(
    Map<String, Object> mapOrderData,
    Map<String, String> mapAccOrgUnit,
    Order objOrderData
  ) {
    //delete old File
    TPB_MassPrebookControllerUtility.deleteFile(
      String.valueOf(mapOrderData.get(ORDER_ID)),
      MASS_PREBOOK_ORDER_FILE + '%'
    );

    //update File name
    TPB_MassPrebookControllerUtility.updateFile(
      String.valueOf(mapOrderData.get(ORDER_ID)),
      MASS_PREBOOK_FILE_NAME + MASS_PREBOOK_ORDER_FILE,
      MASS_PREBOOK_ORDER_FILE
    );

    //mapOrderData.get( ORDER_TYPE_API ) == ORDER_TYPE
    if (String.valueOf(mapOrderData.get(ORDER_TYPE_API)) == ORDER_TYPE) {
      TPB_MassPrebookControllerUtility.deleteFile(
        String.valueOf(mapOrderData.get(ORDER_ID)),
        MASS_PREBOOK_ORG_UNIT_ORDER_FILE
      );

      //add account and org unit data
      TPB_MassPrebookControllerUtility.uploadFile(
        new List<String>{ JSON.serialize(mapAccOrgUnit) },
        MASS_PREBOOK_ORG_UNIT_ORDER_FILE,
        MASS_PREBOOK_ORG_UNIT_ORDER_FILE,
        String.valueOf(mapOrderData.get(ORDER_ID)),
        true
      );

      //Update Database.executeBatch
      Database.executeBatch(
        new TPB_MassPrebookCreateBatch(
          objOrderData,
          String.valueOf(mapOrderData.get(ORDER_TYPE_API)),
          'Update',
          boolRunTest
        ),
        1
      );
    }
  }

  /**
   * @description  cancel Order Data
   * @param  strOrderId     String
   * @param  strOrderType   String
   * @param  strWave        String
   * @return mapResult    Map<String, String>
   */
  @AuraEnabled
  public static Map<String, Object> cancelOrderData(
    String strOrderId,
    String strOrderType,
    String strWave
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    try {
      //get Order Data
      Order objOrderData = TPB_MassPrebookService.getOrderData(strOrderId);
      if (strOrderType == ORDER_TYPE) {
        //getWave Promotion Allocation Item
        TPB_Promotion_Allocation_Item__c obj = TPB_MassPrebookService.getWavePromotionAllocationItem(
          objOrderData.TPB_HQ_Account__c,
          objOrderData.TPB_Mass_Prebook_Product__c,
          strWave
        );
        if (obj != null) {
          //get ContentDocumentLink
          Set<String> setContentDocumentLink = TPB_MassPrebookControllerUtility.getContentDocumentLink(
            strOrderId,
            MASS_PREBOOK_ORDER_FILE + '%'
          );
          if (setContentDocumentLink.size() > 0) {
            //Cancel Database.executeBatch
            Database.executeBatch(
              new TPB_MassPrebookCreateBatch(
                objOrderData,
                strOrderType,
                'Cancelled',
                boolRunTest
              ),
              1
            );
          } else {
            //update order Status
            objOrderData.Status = 'Cancelled';
            update objOrderData;
          }

          mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
        } else {
          //return err message
          mapResult.put(
            RTN_KEY_ERR_MSG,
            'The order entry end date for the band has passed and cancellation is not allowed.'
          );
          mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);

          return mapResult;
        }
      } else {
        //order type is Straight Stock
        if (objOrderData.TPB_Ship_Date__c > System.Date.today()) {
          objOrderData.Status = 'Cancelled';
          update objOrderData;

          mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
        } else {
          mapResult.put(
            RTN_KEY_ERR_MSG,
            'The Ship Date must be greater than today to cancel the order.'
          );
          mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);

          return mapResult;
        }
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return mapResult;
  }

  /**
   * @description  complete Order
   * @param  strOrderId      String
   * @param  strHqAccountId  String
   * @param  strOrderType    String
   * @return mapResult       Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> completeOrder(
    String strOrderId,
    String strHqAccountId,
    String strOrderType
  ) {
    Map<String, String> mapResult = new Map<String, String>{};
    try {
      if (!String.isEmpty(strOrderId) && !String.isEmpty(strOrderType)) {
        //get Orde rData
        Order objOrder = TPB_MassPrebookService.getOrderData(strOrderId);

        //create order and orderitem data
        Database.executeBatch(
          new TPB_MassPrebookCreateBatch(
            objOrder,
            strOrderType,
            'Complete',
            boolRunTest
          ),
          1
        );

        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      } else {
        //return err message
        mapResult.put(RTN_KEY_ERR_MSG, COMPLETE_ERR_MSG);
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);

        return mapResult;
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return mapResult;
  }

  /**
   * @description create OrderData
   * @param   strProductIds       String
   * @param   setAccountId        Set<String>
   * @param   mapProductPromotionAllocationItem    Map<String, TPB_Promotion_Allocation_Item__c>
   * @param   strOrderType        strOrderType
   * @return  mapAccOrderItem     Map<String, OrderItem>
   */
  public static Map<String, OrderItem> createOrderItemData(
    String strProductIds,
    Set<String> setAccountId,
    Map<String, TPB_Promotion_Allocation_Item__c> mapProductPromotionAllocationItem,
    String strOrderType
  ) {
    Map<String, OrderItem> mapAccOrderItem = new Map<String, OrderItem>();
    if (strOrderType == ORDER_TYPE) {
      //order type is Promo. create orderitem
      for (String strAccount : mapProductPromotionAllocationItem.KeySet()) {
        OrderItem objOrderItem = new OrderItem();
        objOrderItem.Product2Id = strProductIds;
        objOrderItem.Quantity = 0;
        objOrderItem.TPB_QTY_Planned__c = mapProductPromotionAllocationItem.get(
            strAccount
          )
          .TPB_Quantity_Planned__c;
        objOrderItem.TPB_QTY_Remaining__c = mapProductPromotionAllocationItem.get(
            strAccount
          )
          .TPB_Quantity_Planned__c;
        objOrderItem.TPB_Max_Quantity__c = mapProductPromotionAllocationItem.get(
            strAccount
          )
          .TPB_Max_Quantity__c;
        mapAccOrderItem.put(strAccount, objOrderItem);
        //add OrderItem
      }
    } else {
      //order type is Straight Stock. create orderitem
      for (String strAccountId : setAccountId) {
        OrderItem objOrderItem = new OrderItem();
        objOrderItem.Product2Id = strProductIds;
        objOrderItem.Quantity = 0;
        objOrderItem.TPB_Max_Quantity__c = null;
        objOrderItem.TPB_QTY_Planned__c = null;
        objOrderItem.TPB_QTY_Remaining__c = null;
        mapAccOrderItem.put(strAccountId, objOrderItem);
        //add OrderItem
      }
    }

    //return mapAccOrderItem
    return mapAccOrderItem;
  }

  /**
   * @description getRelatedAccountsByRetailerId
   * @param   strRetailerAccountId   String
   * @return  lstRelatedAccount      List<Related_Account__c>
   */
  @AuraEnabled
  public static List<Related_Account__c> getRelatedAccountsByRetailerId(
    String strRetailerAccountId
  ) {
    List<Related_Account__c> lstRelatedAccount = new List<Related_Account__c>();
    try {
      //query Related_Account__c data
      lstRelatedAccount = TPB_MassPrebookService.getRelatedAccountsByRetailerId(
        strRetailerAccountId
      );
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapResult
    return lstRelatedAccount;
  }
}