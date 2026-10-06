/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screen flow for Mass Prebook
 */
public without sharing class TPB_MassPrebookService {
  //Order  Van_Load recordType Id
  public static String orderMassPrebookRecordTypeId = TPB_TestFactory.orderMassPrebookRecordTypeId;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;

  //TPB_Promotion_Allocation_Item__c  recordType Id
  public static String proAllocationItemOrgRecordTypeId = TPB_TestFactory.proAllocationItemOrgRecordTypeId;
  public static String proAllocationItemStoreRecordTypeId = TPB_TestFactory.proAllocationItemStoreRecordTypeId;

  /**
   * @description get All Date Wave data
   * @param   strHqAccountId  String
   * @param   strProductId    String
   * @return  setDateWave       Set<String>
   */
  public static Set<String> getAllWaveDate(
    String strHqAccountId,
    String strProductId
  ) {
    //Find the Org Units that need to be split
    List<TPB_Promotion_Allocation_Item__c> lstPromotionAllocationItem = [
      SELECT Id, TPB_WavePeriod_And_OrderEntry_Date__c
      FROM TPB_Promotion_Allocation_Item__c
      WHERE
        TPB_Account__r.ParentId = :strHqAccountId
        AND TPB_Product__c = :strProductId
        AND ((TPB_Order_Entry_Date_From__c <= :System.Date.today()
        AND TPB_Order_Entry_Date_Thru__c > :System.Date.today())
        OR (TPB_Order_Entry_Date_From__c < :System.Date.today()
        AND TPB_Order_Entry_Date_Thru__c >= :System.Date.today()))
        AND RecordTypeId = :proAllocationItemStoreRecordTypeId
      ORDER BY TPB_Wave_Period_Date_From__c, TPB_Account__r.Name ASC
    ];

    //Wave 1: 1/1/23-1/31/23​
    Set<String> setDateWave = new Set<String>();
    for (
      TPB_Promotion_Allocation_Item__c objItem : lstPromotionAllocationItem
    ) {
      setDateWave.add(objItem.TPB_WavePeriod_And_OrderEntry_Date__c);
    }

    //return setDateWave data
    return setDateWave;
  }

  /**
   * @description search Chain OrgUnit Data
   * @param   setHqOwnerId       Hq account OwnerId
   * @return  mapChainAcc  Map<String, String>
   */
  public static List<cgcloud__Org_Unit_User__c> searchChainOrgUnitData(
    Set<String> setHqOwnerId
  ) {
    //query cgcloud__Org_Unit_User__c data
    List<cgcloud__Org_Unit_User__c> lstAccountOrgUnit = [
      SELECT Id, cgcloud__User__c, cgcloud__Org_Unit__c
      FROM cgcloud__Org_Unit_User__c
      WHERE
        cgcloud__User__c IN :setHqOwnerId
        AND cgcloud__Org_Unit__c != NULL
        AND cgcloud__Main__c = TRUE
        AND ((cgcloud__Valid_From__c <= :System.Date.today()
        AND cgcloud__Valid_Thru__c > :System.Date.today())
        OR (cgcloud__Valid_From__c < :System.Date.today()
        AND cgcloud__Valid_Thru__c >= :System.Date.today()))
    ];

    //return lstAccountOrgUnit
    return lstAccountOrgUnit;
  }

  /**
   * @description getRelatedAccountsByRetailerId
   * @param   strRetailerAccountId   String
   * @return  lstRelatedAccount      List<Related_Account__c>
   */
  public static List<Related_Account__c> getRelatedAccountsByRetailerId(
    String strRetailerAccountId
  ) {
    //query Related_Account__c data
    List<Related_Account__c> lstRelatedAccount = [
      SELECT
        Id,
        Retailer__c,
        Retailer__r.Name,
        Retailer__r.Account_Number_old__c,
        Retailer__r.Internal_Customer_ID__c,
        Wholesaler__c,
        Wholesaler__r.Account_Number_old__c,
        Wholesaler__r.Name,
        Supplier_Id__c
      FROM Related_Account__c
      WHERE Retailer__c = :strRetailerAccountId AND Wholesaler__c != NULL
      ORDER BY
        TPB_Promotional_Wholesaler__c DESC,
        TPB_MSA_Wholesaler__c DESC,
        Wholesaler__r.Name ASC
      LIMIT 5000
    ];

    //return lstRelatedAccount
    return lstRelatedAccount;
  }

  /**
   * @description get All Wholesaler Account data
   * @param   strHqAccountId    String
   * @return  lstWholesalerAccount  List<Account>
   */
  public static Map<String, Account> getAllWholesalerAccount(
    String strHqAccountId
  ) {
    //create map save mapWholesalerAccount
    Map<String, Account> mapWholesalerAccount = new Map<String, Account>();
    //query Account data
    List<Account> lstWholesalerAccount = [
      SELECT
        Id,
        Name,
        Account_Number_old__c,
        ParentId,
        Parent.Name,
        ShippingStreet,
        ShippingCity,
        ShippingState,
        ShippingPostalCode,
        Internal_Customer_ID__c
      FROM Account
      WHERE ParentId = :strHqAccountId
    ];
    //add mapWholesalerAccount map
    for (Account obj : lstWholesalerAccount) {
      mapWholesalerAccount.put(obj.id, obj);
    }

    //return mapWholesalerAccount data
    return mapWholesalerAccount;
  }

  /**
   * @description search Pricebook EntryProduct
   * @param   setProduct    Set<String>
   * @return  mapProduct    Map<String, String>
   */
  public static Map<String, String> searchPricebookEntryProduct(
    Set<String> setProduct
  ) {
    // query  Standard Price Book  Pricebook2
    List<Pricebook2> lstPricebook2 = TPB_AddInventoryPurchasedFormService.searchPricebook2();
    //searchPricebookEntryProduct
    Map<String, String> mapProduct = TPB_AddInventoryPurchasedForm.searchPricebookEntryProduct(
      setProduct,
      lstPricebook2[0].Id
    );

    //return mapProduct data
    return mapProduct;
  }

  /**
   * @description get Wholesaler Account
   * @param   strHqAccountId       String
   * @return  mapRetailerAccount   Map<String, TPB_MassPrebookWrapper.WholesalerAccount>>
   */
  public static Map<String, TPB_MassPrebookWrapper.WholesalerAccount> getWholesalerAccount(
    String strHqAccountId
  ) {
    Map<String, TPB_MassPrebookWrapper.WholesalerAccount> mapRetailerAccount = new Map<String, TPB_MassPrebookWrapper.WholesalerAccount>();
    //query Related_Account__c data
    List<Related_Account__c> lstRelatedAccount = [
      SELECT
        Id,
        Retailer__c,
        Retailer__r.Name,
        Retailer__r.Account_Number_old__c,
        Retailer__r.Internal_Customer_ID__c,
        Wholesaler__c,
        TPB_MSA_Wholesaler__c,
        Wholesaler__r.Account_Number_old__c,
        Retailer__r.ShippingStreet,
        Retailer__r.ShippingCity,
        Retailer__r.ShippingState,
        Retailer__r.ShippingPostalCode,
        Wholesaler__r.Name,
        Supplier_Id__c
      FROM Related_Account__c
      WHERE Retailer__r.ParentId = :strHqAccountId AND Wholesaler__c != NULL
      ORDER BY
        TPB_Promotional_Wholesaler__c DESC,
        TPB_MSA_Wholesaler__c DESC,
        Wholesaler__r.Name ASC
      LIMIT 5000
    ];
    //Encapsulated as an inner class
    for (Related_Account__c objRelatedAccount : lstRelatedAccount) {
      if (!mapRetailerAccount.containsKey(objRelatedAccount.Retailer__c)) {
        //add mapRetailerAccount  WholesalerAccount
        TPB_MassPrebookWrapper.WholesalerAccount objWholesalerAccount = new TPB_MassPrebookWrapper.WholesalerAccount();
        objWholesalerAccount.acNu = objRelatedAccount.Retailer__r.Account_Number_old__c;
        objWholesalerAccount.acNm = objRelatedAccount.Retailer__r.Name;
        objWholesalerAccount.ads = objRelatedAccount.Retailer__r.ShippingStreet;
        objWholesalerAccount.cty = objRelatedAccount.Retailer__r.ShippingCity;
        objWholesalerAccount.sta = objRelatedAccount.Retailer__r.ShippingState;
        objWholesalerAccount.zip = objRelatedAccount.Retailer__r.ShippingPostalCode;
        objWholesalerAccount.wsNm = objRelatedAccount.Wholesaler__r.Name;
        objWholesalerAccount.ws = objRelatedAccount.Wholesaler__r.Account_Number_old__c;
        objWholesalerAccount.nTNu = objRelatedAccount.Retailer__r.Internal_Customer_ID__c;
        objWholesalerAccount.wsCt = objRelatedAccount.Supplier_Id__c;
        objWholesalerAccount.rAcId = objRelatedAccount.Id;
        mapRetailerAccount.put(
          objRelatedAccount.Retailer__c,
          objWholesalerAccount
        );
      }
    }

    //return mapRetailerAccount data
    return mapRetailerAccount;
  }

  /**
   * @description get Order Data
   * @param   strRecordId   String
   * @return  objOrder      Order
   */
  public static Order getOrderData(String strRecordId) {
    //query Order data
    Order objOrder = [
      SELECT
        Id,
        RecordType.DeveloperName,
        TPB_Mass_Prebook_Product__c,
        TPB_HQ_Account__c,
        TPB_HQ_Account__r.OwnerId,
        TPB_Ship_Date__c,
        Status,
        TPB_Wave_Order_Date__c,
        TPB_Mass_Prebook_Product__r.NTC_Item_Classification__c,
        CreatedBy.TPB_Territory__c
      FROM Order
      WHERE Id = :strRecordId AND RecordTypeId = :orderMassPrebookRecordTypeId
    ];

    //return objOrder data
    return objOrder;
  }

  /**
   * @description getAll OrderItem Data
   * @param   strHqAccountId    Set<String>
   * @param   strOrderId        String
   * @return  mapAccOrderItem   Map<String, OrderItem>
   */
  public static Map<String, OrderItem> getAllOrderItemData(
    String strHqAccountId,
    String strOrderId
  ) {
    Map<String, OrderItem> mapAccOrderItem = new Map<String, OrderItem>();
    //query OrderItem data
    List<OrderItem> lstOrderItem = [
      SELECT
        Id,
        Order.Account.Account_Number_old__c,
        Order.Account.ShippingStreet,
        Order.Account.ShippingCity,
        Order.Account.ShippingState,
        Order.Account.ShippingPostalCode,
        Order.Account.Internal_Customer_ID__c,
        Product2Id,
        Product2.Name,
        Product2.Item_ID__c,
        Product2.NTC_Case_ID__c,
        Product2.TPB_Brand_UPW__c,
        Order.Account.Name,
        Order.AccountId,
        OrderId,
        Order.Account.cgcloud__Account_Number__c,
        Quantity,
        TPB_QTY_Planned__c,
        TPB_Max_Quantity__c,
        TPB_QTY_Remaining__c
      FROM OrderItem
      WHERE
        Order.Account.ParentId = :strHqAccountId
        AND Order.RecordTypeId = :orderMassPrebookRecordTypeId
        AND Order.TPB_Child_Order__c = :strOrderId
    ];
    //Save to the map collection with account as the key
    for (OrderItem objOrderItem : lstOrderItem) {
      if (!mapAccOrderItem.containsKey(objOrderItem.Order.AccountId)) {
        mapAccOrderItem.put(objOrderItem.Order.AccountId, objOrderItem);
      }
    }

    //return mapAccOrderItem data
    return mapAccOrderItem;
  }

  /**
   * @description get Wave Promotion Allocation Item
   * @param   strHqAccountId  String
   * @param   strProductId    String
   * @param   strWave         String
   * @return  objPromotionAllocationItem   TPB_Promotion_Allocation_Item__c
   */
  public static TPB_Promotion_Allocation_Item__c getWavePromotionAllocationItem(
    String strHqAccountId,
    String strProductId,
    String strWave
  ) {
    //query TPB_Promotion_Allocation_Item__c data
    TPB_Promotion_Allocation_Item__c objPromotionAllocationItem = [
      SELECT
        Id,
        TPB_Max_Quantity__c,
        TPB_Product__c,
        TPB_Product__r.Name,
        TPB_Product__r.NTC_Case_ID__c,
        TPB_Product__r.TPB_Brand_UPW__c,
        TPB_Quantity_Planned__c,
        TPB_Total_QTY_Ordered__c,
        TPB_Account__c,
        TPB_Account__r.Name
      FROM TPB_Promotion_Allocation_Item__c
      WHERE
        TPB_Account__r.ParentId = :strHqAccountId
        AND TPB_Product__c = :strProductId
        AND TPB_WavePeriod_And_OrderEntry_Date__c = :strWave
        AND TPB_Order_Entry_Date_Thru__c > :System.Date.today()
        AND RecordTypeId = :proAllocationItemStoreRecordTypeId
      ORDER BY TPB_Account__c DESC
      LIMIT 1
    ];

    //return objPromotionAllocationItem data
    return objPromotionAllocationItem;
  }

  /**
   * @description get All Promotion Allocation Item Data
   * @param   strHqAccountId  String
   * @param   strProductId    String
   * @param   strWave         String
   * @param   strAccountIds   Account Ids
   * @return  mapAccPromotionAllocationItem     Map<String, TPB_Promotion_Allocation_Item__c>
   */
  public static Map<String, TPB_Promotion_Allocation_Item__c> getAllPromotionAllocationItem(
    String strHqAccountId,
    String strProductId,
    String strWave,
    Set<String> strAccountIds
  ) {
    List<TPB_Promotion_Allocation_Item__c> lstPromotionAllocationItem = new List<TPB_Promotion_Allocation_Item__c>();
    Map<String, TPB_Promotion_Allocation_Item__c> mapAccPromotionAllocationItem = new Map<String, TPB_Promotion_Allocation_Item__c>();
    //query TPB_Promotion_Allocation_Item__c data
    if (strAccountIds.size() > 0) {
      //Account Ids not null
      lstPromotionAllocationItem = [
        SELECT
          Id,
          TPB_Max_Quantity__c,
          TPB_Product__c,
          TPB_Product__r.Name,
          TPB_Product__r.NTC_Case_ID__c,
          TPB_Product__r.TPB_Brand_UPW__c,
          TPB_Quantity_Planned__c,
          TPB_Total_QTY_Ordered__c,
          TPB_Account__c,
          TPB_Account__r.Name
        FROM TPB_Promotion_Allocation_Item__c
        WHERE
          TPB_Account__c IN :strAccountIds
          AND TPB_Product__c = :strProductId
          AND TPB_WavePeriod_And_OrderEntry_Date__c = :strWave
          AND RecordTypeId = :proAllocationItemStoreRecordTypeId
        ORDER BY TPB_Account__c DESC
      ];
    } else if (strHqAccountId != null) {
      //Hq AccountId not null
      lstPromotionAllocationItem = [
        SELECT
          Id,
          TPB_Max_Quantity__c,
          TPB_Product__c,
          TPB_Product__r.Name,
          TPB_Product__r.NTC_Case_ID__c,
          TPB_Product__r.TPB_Brand_UPW__c,
          TPB_Quantity_Planned__c,
          TPB_Total_QTY_Ordered__c,
          TPB_Account__c,
          TPB_Account__r.Name
        FROM TPB_Promotion_Allocation_Item__c
        WHERE
          TPB_Account__r.ParentId = :strHqAccountId
          AND TPB_Product__c = :strProductId
          AND TPB_WavePeriod_And_OrderEntry_Date__c = :strWave
          AND RecordTypeId = :proAllocationItemStoreRecordTypeId
        ORDER BY TPB_Account__c DESC
      ];
    }

    //add mapAccPromotionAllocationItem
    for (
      TPB_Promotion_Allocation_Item__c objPromotionAllocationItem : lstPromotionAllocationItem
    ) {
      if (
        !mapAccPromotionAllocationItem.containsKey(
          objPromotionAllocationItem.TPB_Account__c
        )
      ) {
        mapAccPromotionAllocationItem.put(
          objPromotionAllocationItem.TPB_Account__c,
          objPromotionAllocationItem
        );
      }
    }

    //return mapAccPromotionAllocationItem data
    return mapAccPromotionAllocationItem;
  }
}