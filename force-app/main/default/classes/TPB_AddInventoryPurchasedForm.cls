/**
 * @author Mi Li
 * @date 4/28/2023
 * @description CON0001729-330:Add Inventory Purchased from Wholesaler
 */
public without sharing class TPB_AddInventoryPurchasedForm {
  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;
  private static final String REPEAT_PRODUCT_ERROR = 'The product with this UoM already exists in the order.';
  private static final String ADDPRODUCT_ERROR = 'Cannot find current product in the system';
  private static final String AMOUNT_VERIFICATION_ERROR = 'Invoice total and inventory value total do not match. Please review and correct inventory input.';

  /**
   * @description Delete the selected upload file
   * @param  strDocumentId String
   * @return mapResult   Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> deleteFiles(String strDocumentId) {
    Map<String, String> mapResult = new Map<String, String>{};

    try {
      if (!String.isEmpty(strDocumentId)) {
        //Query ContentDocument data
        List<ContentDocument> lstContentDocument = [
          SELECT Id
          FROM ContentDocument
          WHERE Id = :strDocumentId
        ];
        //delete lstContentDocument data
        if (lstContentDocument.size() > 0) {
          delete lstContentDocument;
        }
      }
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description  Delete OrderItem
   * @param  strOrderItemId String
   * @return mapResult   Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> deleteOrderItem(String strOrderItemId) {
    Map<String, String> mapResult = new Map<String, String>{};

    try {
      if (!String.isEmpty(strOrderItemId)) {
        OrderItem objOrderItem = new OrderItem();
        objOrderItem.id = strOrderItemId;

        // delete Order Item
        delete objOrderItem;
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description  complete Order
   * @param  strOrderId  String
   * @return mapResult   Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> completeOrder(String strOrderId) {
    Map<String, String> mapResult = new Map<String, String>{};

    try {
      if (!String.isEmpty(strOrderId)) {
        //query Order data
        Order objOrder = [
          SELECT Id, Status, TotalAmount, External_Amount__c
          FROM Order
          WHERE Id = :strOrderId
        ];
        //update objOrder
        if (
          objOrder.Status == 'Draft' &&
          objOrder.TotalAmount != null &&
          objOrder.External_Amount__c != null &&
          objOrder.External_Amount__c == objOrder.TotalAmount
        ) {
          objOrder.Status = 'Activated';
          update objOrder;

          //query OrderItem data
          List<OrderItem> lstOrderItem = [
            SELECT
              TPB_Type__c,
              UoM__c,
              Product2Id,
              Quantity,
              Order.TPB_State__c,
              Product2.cgcloud__Criterion_5_Product__c,
              Order.CreatedById,
              Product2.TPB_Exclude_From_Base_Pricing__c,
              CreatedById
            FROM OrderItem
            WHERE OrderId = :strOrderId AND Order.Status = 'Activated'
            ORDER BY Product2Id, Order.TPB_State__c, CreatedById
          ];
          //Calling class methods
          if (lstOrderItem.size() > 0) {
            TPB_InventoryService.createInventory(lstOrderItem);
          }
          mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
        } else {
          mapResult.put(RTN_KEY_ERR_MSG, AMOUNT_VERIFICATION_ERROR);
          mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
        }
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description search PricebookEntry data
   * @param  setProduct            Set<String>
   * @param  strPricebook2Id       String
   * @return  lstPricebookEntry    List<PricebookEntry>
   */
  private static List<PricebookEntry> searchPricebookEntry(
    Set<String> setProduct,
    String strPricebook2Id
  ) {
    //query PricebookEntry data
    List<PricebookEntry> lstPricebookEntry = [
      SELECT Id, Pricebook2Id, Product2Id, IsActive
      FROM PricebookEntry
      WHERE
        Product2Id IN :setProduct
        AND Pricebook2Id = :strPricebook2Id
        AND IsActive = TRUE
    ];

    //return result
    return lstPricebookEntry;
  }

  /**
   * @description  Save Order Detail data
   * @param  strOrderId String
   * @param  inputItems List<Map<String,String>>
   * @return mapResult       Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> saveOrderDetail(
    String strOrderId,
    List<Map<String, String>> inputItems
  ) {
    Map<String, String> mapResult = new Map<String, String>{};
    List<OrderItem> lstOrderItem = new List<OrderItem>();
    Set<String> setProduct = new Set<String>();
    try {
      // query  Standard Price Book  Pricebook2
      List<Pricebook2> lstPricebook2 = TPB_AddInventoryPurchasedFormService.searchPricebook2();
      for (Map<String, String> item : inputItems) {
        //Receive data for conversion
        OrderItem newOrderItem = new OrderItem(
          Product2Id = item.get('Product2Id'),
          UnitPrice = Decimal.valueOf(item.get('UnitPrice')),
          Quantity = Decimal.valueOf(item.get('Quantity')),
          UoM__c = item.get('UoM__c'),
          TPB_Type__c = item.get('TPB_Type__c'),
          OrderId = strOrderId
        );
        lstOrderItem.add(newOrderItem);
        setProduct.add(item.get('Product2Id'));
      }
      //query OrderItem data
      List<OrderItem> lstOrderItems = searchOrderItemsForOrderId(
        strOrderId,
        inputItems[0]
      );
      if (lstOrderItems.size() > 0) {
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
        mapResult.put(RTN_KEY_ERR_MSG, REPEAT_PRODUCT_ERROR);
        return mapResult;
      }

      //search Pricebook Entry Product
      Map<String, String> mapProduct = searchPricebookEntryProduct(
        setProduct,
        lstPricebook2[0].Id
      );
      for (OrderItem objOrderItem : lstOrderItem) {
        //Query relevant PricebookEntry data for association based on product and pricebook
        if (mapProduct.containsKey(objOrderItem.Product2Id)) {
          objOrderItem.PricebookEntryId = mapProduct.get(
            objOrderItem.Product2Id
          );
        } else {
          mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
          mapResult.put(RTN_KEY_ERR_MSG, ADDPRODUCT_ERROR);

          return mapResult;
        }
      }
      // insert lstOrderItem
      if (lstOrderItem.size() > 0) {
        insert lstOrderItem;
      }

      //return data
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }
    return mapResult;
  }

  /**
   * @description search Pricebook Entry Product
   * @param  setProduct        Set<String>
   * @param  strPricebook2Id   String
   * @return mapProduct        Map<String, String>
   */
  public static Map<String, String> searchPricebookEntryProduct(
    Set<String> setProduct,
    String strPricebook2Id
  ) {
    Map<String, String> mapProduct = new Map<String, String>();
    if (setProduct.size() > 0) {
      //query PricebookEntry data
      List<PricebookEntry> lstPricebookEntry = searchPricebookEntry(
        setProduct,
        strPricebook2Id
      );
      for (PricebookEntry objPricebookEntry : lstPricebookEntry) {
        mapProduct.put(objPricebookEntry.Product2Id, objPricebookEntry.Id);
      }
    }

    //return result
    return mapProduct;
  }

  /**
   * @description Search OrderItems data For OrderId
   * @param  strOrderId   String
   * @param  mapOrderData Map<String, String>
   * @return lstOrderItems  List<OrderItem>
   */
  public static List<OrderItem> searchOrderItemsForOrderId(
    String strOrderId,
    Map<String, String> mapOrderData
  ) {
    //query OrderItem data
    List<OrderItem> lstOrderItems = [
      SELECT Id, Quantity
      FROM OrderItem
      WHERE
        OrderId = :strOrderId
        AND Product2Id = :mapOrderData.get('Product2Id')
        AND UoM__c = :mapOrderData.get('UoM__c')
        AND TPB_Type__c = :mapOrderData.get('TPB_Type__c')
    ];

    //return result
    return lstOrderItems;
  }

  /**
   * @description Search OrderItems data
   * @param  strOrderId String
   * @return mapResult  Map<String, Object>
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> searchOrderItems(String strOrderId) {
    Map<String, Object> mapResult = new Map<String, Object>();
    List<TPB_AddInventoryPurchasedFormWrapper.OrderDetail> lstOrderDetail = new List<TPB_AddInventoryPurchasedFormWrapper.OrderDetail>();
    try {
      if (!String.isEmpty(strOrderId)) {
        //query OrderItem data
        List<OrderItem> lstOrderItem = [
          SELECT
            Id,
            Product2Id,
            Product2.Name,
            UoM__c,
            TPB_Type__c,
            Quantity,
            UnitPrice
          FROM OrderItem
          WHERE OrderId = :strOrderId
        ];
        for (OrderItem objOrderItem : lstOrderItem) {
          //Encapsulating data for return
          TPB_AddInventoryPurchasedFormWrapper.OrderDetail objOrderDetail = new TPB_AddInventoryPurchasedFormWrapper.OrderDetail();
          objOrderDetail.setFields(objOrderItem);
          lstOrderDetail.add(objOrderDetail);
        }
      }

      //return data
      mapResult.put(RTN_KEY_DATA, lstOrderDetail);
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description  get PricebookEntry
   * @param   strProductId    String
   * @return  mapOrderData    Map<String, Object>
   */
  public static Map<String, Object> getPricebookEntry(String strProductId) {
    // return Map
    Map<String, Object> mapOrderData = new Map<String, Object>();
    mapOrderData.put(RTN_KEY_RESULT, RTN_KEY_NG);

    //query Pricebook2 data
    List<Pricebook2> lstPricebook2 = TPB_AddInventoryPurchasedFormService.searchPricebook2();
    if (lstPricebook2.size() == 0) {
      return mapOrderData;
    }

    Pricebook2 oPriceBook = lstPricebook2[0];
    List<PricebookEntry> lstPicebookEntry = searchPricebookEntry(
      new Set<String>{ strProductId },
      oPriceBook.Id
    );
    //return mapOrderData
    if (lstPicebookEntry.size() == 0) {
      return mapOrderData;
    }

    //Return Data
    mapOrderData.put(RTN_KEY_RESULT, RTN_KEY_OK);
    mapOrderData.put(RTN_KEY_DATA, lstPicebookEntry[0]);

    return mapOrderData;
  }

  /**
   * @description  add Scanned Product
   * @param   strOrderId    String
   * @param   strCode       String
   * @param   strType       String
   * @return  mapOrderData  Map<String, Object>
   */
  @AuraEnabled
  public static Map<String, String> addScannedProduct(
    String strOrderId,
    String strCode,
    String strType
  ) {
    //add message
    Map<String, String> mapResult = new Map<String, String>{};
    mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);

    try {
      if (String.isEmpty(strOrderId) || String.isEmpty(strCode)) {
        mapResult.put(RTN_KEY_ERR_MSG, ADDPRODUCT_ERROR);
        return mapResult;
      }

      //query cgcloud__Unit_of_Measure__c data
      List<cgcloud__Unit_of_Measure__c> lCgcUom = [
        SELECT cgcloud__GTIN__c, cgcloud__Product__c, cgcloud__Unit_Type__c
        FROM cgcloud__Unit_of_Measure__c
        WHERE cgcloud__GTIN__c = :strCode
        LIMIT 1
      ];
      if (lCgcUom.size() == 0) {
        // unknown product
        mapResult.put(RTN_KEY_ERR_MSG, ADDPRODUCT_ERROR);
        return mapResult;
      }

      //Wrapped into an inner class object
      TPB_AddInventoryPurchasedFormWrapper.TpbUnitOfMeasure oUom = new TPB_AddInventoryPurchasedFormWrapper.TpbUnitOfMeasure();
      oUoM.setFieldsByCgcObject(lCgcUom[0]);

      // check if the product is already in the order item list
      String strProductId = oUom.product;
      String strUnitType = oUom.unitType;
      //query  OrderItem data
      List<OrderItem> lstOrderItem = [
        SELECT Id, Quantity
        FROM OrderItem
        WHERE
          OrderId = :strOrderId
          AND Product2Id = :strProductId
          AND UoM__c = :strUnitType
          AND TPB_Type__c = :strType
      ];

      if (lstOrderItem.size() > 0) {
        OrderItem objOrderItem = lstOrderItem[0];

        // update the quantity if there is one
        objOrderItem.Quantity = objOrderItem.Quantity + 1;
        update objOrderItem;

        //return result
        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
        return mapResult;
      }

      //create OrderItem record data
      OrderItem objNewOrderItem = createOrderItems(
        strProductId,
        strOrderId,
        strUnitType,
        strType
      );
      //insert objNewOrderItem
      if (objNewOrderItem != null) {
        objNewOrderItem.OrderId = strOrderId;
        objNewOrderItem.UoM__c = strUnitType;
        objNewOrderItem.TPB_Type__c = strType;
        insert objNewOrderItem;

        mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    return mapResult;
  }

  /**
   * @description create OrderItems data
   * @param   strProductId        String
   * @param   strOrderId          String
   * @param   strUnitType         String
   * @param   strType             String
   * @return  objNewOrderItem     OrderItem
   */
  private static OrderItem createOrderItems(
    String strProductId,
    String strOrderId,
    String strUnitType,
    String strType
  ) {
    OrderItem objNewOrderItem = null;
    // prepare info
    Map<String, Object> mapOrderData = getPricebookEntry(strProductId);
    if (
      mapOrderData.containsKey(RTN_KEY_DATA) &&
      mapOrderData.get(RTN_KEY_DATA) != null
    ) {
      PricebookEntry oPricebookEntry = (PricebookEntry) mapOrderData.get(
        RTN_KEY_DATA
      );
      if (oPricebookEntry != null) {
        //get Recent UnitPrice
        Decimal unitPrice = getRecentUnitPrice(
          strOrderId,
          strProductId,
          strUnitType
        );
        // add it as an order item if there is none
        objNewOrderItem = new OrderItem();
        objNewOrderItem.PricebookEntryId = oPricebookEntry.Id;
        objNewOrderItem.Product2Id = strProductId;
        objNewOrderItem.Quantity = 1;
        objNewOrderItem.UnitPrice = unitPrice;
        if (strType == 'Return') {
          objNewOrderItem.UnitPrice = -unitPrice;
        }
      }
    }

    //return objNewOrderItem
    return objNewOrderItem;
  }

  /**
   * @description Get Product Recent Unit Price
   * @author Guanshu Wang
   * @param  inputOrderId   Order Id
   * @param  inputProductId Product Id
   * @param  strUnitType    Unit Type
   * @return                Unit Price
   */
  @AuraEnabled
  public static Decimal getRecentUnitPrice(
    String inputOrderId,
    String inputProductId,
    String strUnitType
  ) {
    Decimal returnUnitPriceValue = 0;
    //query Order data
    List<Order> orderObj = [
      SELECT Id, AccountId
      FROM Order
      WHERE Id = :inputOrderId
    ];
    if (orderObj.size() > 0) {
      //query OrderItem data
      List<OrderItem> orderItemList = [
        SELECT id, UnitPrice
        FROM OrderItem
        WHERE
          Order.Status = 'Activated'
          AND Order.AccountId = :orderObj[0].AccountId
          AND Order.ActivatedById = :UserInfo.getUserId()
          AND Product2Id = :inputProductId
          AND UoM__c = :strUnitType
          AND TPB_Type__c = 'Purchase'
        ORDER BY Order.ActivatedDate DESC
      ];
      if (orderItemList.size() > 0) {
        returnUnitPriceValue = orderItemList[0].UnitPrice;
      }
    }

    //return UnitPrice Value
    return returnUnitPriceValue;
  }

  /**
   * @description OrderObject Internal Classes
   */
  public class OrderObject {
    /**
     * @description strOrderId
     */
    @AuraEnabled
    public String strOrderId { get; set; }
    /**
     * @description strVisitId
     */
    @AuraEnabled
    public String strVisitId { get; set; }
    /**
     * @description stateOptionsValue
     */
    @AuraEnabled
    public String stateOptionsValue { get; set; }
    /**
     * @description strInvoiceNumber
     */
    @AuraEnabled
    public String strInvoiceNumber { get; set; }
    /**
     * @description strDollarAmountOfInvoice
     */
    @AuraEnabled
    public String strDollarAmountOfInvoice { get; set; }
  }
}