/**
 * @author Mi Li
 * @date 4/28/2023
 * @description CON0001729-330:Add Inventory Purchased from Wholesaler
 */
public with sharing class TPB_AddInventoryPurchasedFormService {
  // map returns the result of calling
  public static String strPriceBook = 'Standard Price Book';
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;
  //Order  Van_Load recordType Id
  public static String orderVanLoadRecordTypeId = TPB_TestFactory.orderVanLoadRecordTypeId;
  // Permission sharing for attachments such as files
  private static final String CONTENT_DOCUMENT_LINK_SHARETYPE = TPB_TestFactory.CONTENT_DOCUMENT_LINK_SHARETYPE;
  private static final String CONTENT_DOCUMENT_LINK_VISIBILITY = TPB_TestFactory.CONTENT_DOCUMENT_LINK_VISIBILITY;

  /**
   * @description search Inventory data
   * @return  mapStateData    Map<String, String>
   */
  private static Map<String, String> searchInventory() {
    Map<String, String> mapStateData = new Map<String, String>();
    //get  Inventory data
    List<cgcloud__Inventory__c> lstCgcloudInventory = [
      SELECT Id, TPB_Tour_State__c
      FROM cgcloud__Inventory__c
      WHERE
        cgcloud__User__c = :UserInfo.getUserId()
        AND cgcloud__Phase__c = 'Active'
        AND ((cgcloud__Valid_From__c <= :Date.today()
        AND cgcloud__Valid_Thru__c > :Date.today())
        OR (cgcloud__Valid_From__c < :Date.today()
        AND cgcloud__Valid_Thru__c >= :Date.today()))
        AND TPB_Tour_State__c != NULL
      ORDER BY TPB_Tour_State__c ASC
    ];
    //add Tour_State map
    for (cgcloud__Inventory__c objInventory : lstCgcloudInventory) {
      mapStateData.put(
        objInventory.TPB_Tour_State__c,
        objInventory.TPB_Tour_State__c
      );
    }

    //return  Tour State  data
    return mapStateData;
  }

  /**
   * @description get All State data
   * @return  mapStateData    Map<String, String>
   */
  private static Map<String, String> getAllState() {
    //add user all State
    Map<String, String> mapStateData = new Map<String, String>();
    //add user OrgUnit
    Set<String> setOrgUnit = new Set<String>();
    //add user ZipCode
    Set<String> setZipCode = new Set<String>();
    //query user cgcloud__Org_Unit_User__c data
    for (cgcloud__Org_Unit_User__c objOrgUnitUser : [
      SELECT Id, cgcloud__User__c, cgcloud__Org_Unit__c
      FROM cgcloud__Org_Unit_User__c
      WHERE
        cgcloud__User__c = :UserInfo.getUserId()
        AND cgcloud__Org_Unit__c != NULL
    ]) {
      setOrgUnit.add(objOrgUnitUser.cgcloud__Org_Unit__c);
    }

    //query user TPB_Org_Unit_Mapping__c data
    for (TPB_Org_Unit_Mapping__c objOrgUnitMapping : [
      SELECT Id, TPB_Zip_Code__c, TPB_Org_Unit__c
      FROM TPB_Org_Unit_Mapping__c
      WHERE TPB_Org_Unit__c IN :setOrgUnit AND TPB_Zip_Code__c != NULL
    ]) {
      setZipCode.add(objOrgUnitMapping.TPB_Zip_Code__c);
    }

    if (setZipCode.size() > 0) {
      //query user Account data
      for (Account objAccount : [
        SELECT Id, ShippingState
        FROM Account
        WHERE ShippingPostalCode IN :setZipCode AND ShippingState != NULL
        ORDER BY ShippingState ASC
      ]) {
        mapStateData.put(objAccount.ShippingState, objAccount.ShippingState);
      }
    }
    //add search Inventory
    mapStateData.putAll(searchInventory());

    //return all State  data
    return mapStateData;
  }

  /**
   * @description  Query current Order and Visit and Account data
   * @return  mapOrderData Map<String, Object>
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> searchUserState() {
    Map<String, Object> mapOrderData = new Map<String, Object>();
    try {
      Map<String, String> mapStateData = getAllState();
      if (mapStateData.size() == 0) {
        //foreach TPB_State__c value
        Schema.DescribeFieldResult fieldResult = Order.TPB_State__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
          mapStateData.put(pickListVal.getLabel(), pickListVal.getValue());
        }
      }

      //Return Data
      mapOrderData.put(RTN_KEY_RESULT, RTN_KEY_OK);
      mapOrderData.put(RTN_KEY_DATA, mapStateData);
    } catch (Exception objEx) {
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapOrderData data
    return mapOrderData;
  }

  /**
   * @description Query current Order and Visit and Account data
   * @param   strRecord    String
   * @return  mapOrderData Map<String, Object>
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> searchDataResult(String strRecord) {
    // return Map
    Map<String, Object> mapOrderData = new Map<String, Object>();
    try {
      if (!String.isEmpty(strRecord)) {
        Id idRecordId = Id.valueOf(strRecord);

        //When the record id is visit
        if (idRecordId.getSObjectType() == Visit.sObjectType) {
          mapOrderData.put(RTN_KEY_DATA + Visit.sObjectType, idRecordId);

          //When the record id is order
        } else if (idRecordId.getSObjectType() == Order.sObjectType) {
          //query Order data
          Order objOrder = [
            SELECT
              Id,
              OrderNumber,
              Status,
              AccountId,
              Quantity__c,
              TPB_State__c,
              Related_Visit__c,
              Related_Visit__r.cgcloud__Tour__r.Name,
              External_Order_Number__c,
              External_Amount__c
            FROM Order
            WHERE Id = :idRecordId
          ];

          //query ContentVersion data
          List<ContentVersion> lstContentVersion = searchContentVersion(
            idRecordId
          );

          //return order data
          mapOrderData.put(RTN_KEY_DATA + 'File', lstContentVersion);
          mapOrderData.put(RTN_KEY_DATA + Order.sObjectType, objOrder);
        }

        //Return Data
        mapOrderData.put(RTN_KEY_RESULT, RTN_KEY_OK);
      }
    } catch (Exception objEx) {
      mapOrderData.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapOrderData.put(RTN_KEY_ERR_MSG, objEx.getMessage());

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }

    //return mapOrderData data
    return mapOrderData;
  }

  /**
   * @description  Save or update Order data
   * @param  objOrderData      OrderObject
   * @return mapResult         Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> saveOrder(
    TPB_AddInventoryPurchasedForm.OrderObject objOrderData
  ) {
    Map<String, String> mapResult = new Map<String, String>{};
    // query  Standard Price Book  Pricebook2
    List<Pricebook2> lstPricebook2 = searchPricebook2();
    Savepoint sp = Database.setSavepoint();
    try {
      //saveAndUpdateOrder
      Order objOrder = saveAndUpdateOrder(
        objOrderData,
        searchVisit(objOrderData.strVisitId)
      );
      //Distinguish whether order is added or modified
      if (
        !String.isEmpty(objOrderData.strOrderId) &&
        objOrderData.strOrderId != null
      ) {
        //query Order data
        Order objOrderValue = [
          SELECT Id, Status, TotalAmount, External_Amount__c
          FROM Order
          WHERE Id = :objOrderData.strOrderId
        ];

        //update objOrder
        objOrder.Id = objOrderData.strOrderId;
        if (objOrderValue.Status == 'Draft') {
          update objOrder;
        }
      } else {
        //Field assignment
        objOrder.Status = 'Draft';
        objOrder.EffectiveDate = Date.today();
        objOrder.Pricebook2Id = lstPricebook2[0].Id;
        objOrder.RecordTypeId = orderVanLoadRecordTypeId;

        //insert objOrder
        insert objOrder;
      }

      //return data
      mapResult.put('RecordId', objOrder.Id);
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      Database.rollback(sp);

      //add message data
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_NG);
      mapResult.put(RTN_KEY_ERR_MSG, objEx.getMessage());

      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }
    return mapResult;
  }

  /**
   * @description save And Update Order
   * @param   objOrderData      OrderObject
   * @param   strAccountId      String
   * @return  objOrder          Order
   */
  private static Order saveAndUpdateOrder(
    TPB_AddInventoryPurchasedForm.OrderObject objOrderData,
    String strAccountId
  ) {
    Order objOrder = new Order();
    //Related_Visit__c = strVisitId  Field assignment
    if (!String.isEmpty(objOrderData.strVisitId)) {
      objOrder.Related_Visit__c = objOrderData.strVisitId;
    }
    //TPB_State__c = stateOptionsValue  Field assignment
    if (!String.isEmpty(objOrderData.stateOptionsValue)) {
      objOrder.TPB_State__c = objOrderData.stateOptionsValue;
    }
    //AccountId = strAccountId  Field assignment
    if (!String.isEmpty(strAccountId) && strAccountId != null) {
      objOrder.AccountId = strAccountId;
    }
    //External_Order_Number__c = strInvoiceNumber  Field assignment
    if (!String.isEmpty(objOrderData.strInvoiceNumber)) {
      objOrder.External_Order_Number__c = objOrderData.strInvoiceNumber;
    }
    //External_Amount__c = strDollarAmountOfInvoice  Field assignment
    if (!String.isEmpty(objOrderData.strDollarAmountOfInvoice)) {
      objOrder.External_Amount__c = Decimal.valueOf(
        objOrderData.strDollarAmountOfInvoice
      );
    }

    return objOrder;
  }

  /**
   * @description search Pricebook2 data
   * @return  lstPricebook2    List<Pricebook2>
   */
  public static List<Pricebook2> searchPricebook2() {
    List<Pricebook2> lstPricebook2 = new List<Pricebook2>();
    //query Pricebook2 data
    if (strPriceBook != null) {
      lstPricebook2 = [
        SELECT Id, Name, IsActive
        FROM Pricebook2
        WHERE Name = :strPriceBook AND IsActive = TRUE
      ];
    } else {
      //Run test classes to provide data
      lstPricebook2.add(
        new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true)
      );
    }

    //return lstPricebook2 data
    return lstPricebook2;
  }

  /**
   * @description search Visit data
   * @param   strVisitId      String
   * @return  strAccountId    String
   */
  private static String searchVisit(String strVisitId) {
    String strAccountId = null;
    //query Visit data
    List<Visit> lstVisit = [
      SELECT Id, AccountId
      FROM Visit
      WHERE Id = :strVisitId AND AccountId != NULL
      LIMIT 1
    ];
    if (lstVisit.size() > 0) {
      strAccountId = lstVisit[0].AccountId;
    }

    return strAccountId;
  }

  /**
   * @description add ContentDocumentLink to Account
   * @param  lstDocumentId List<String>
   * @param  strOrderId    String
   * @return mapResult   Map<String, String>
   */
  @AuraEnabled
  public static Map<String, String> addContentDocumentLink(
    List<String> lstDocumentId,
    String strOrderId
  ) {
    Map<String, String> mapResult = new Map<String, String>{};
    //Data rollback when an exception occurs
    Savepoint sp = Database.setSavepoint();
    try {
      if (!String.isEmpty(strOrderId)) {
        //Query the Account associated with order
        Order objOrder = [
          SELECT
            Id,
            OrderNumber,
            Status,
            AccountId,
            Quantity__c,
            TPB_State__c,
            Related_Visit__c,
            Related_Visit__r.cgcloud__Tour__r.Name,
            External_Order_Number__c,
            External_Amount__c
          FROM Order
          WHERE Id = :strOrderId
        ];
        //lst Insert DocumentLink
        List<ContentDocumentLink> lstInsertDocumentLink = new List<ContentDocumentLink>();
        //lst Update ContentVersion
        List<ContentVersion> lstUpdateContentVersion = new List<ContentVersion>();
        if (lstDocumentId.size() > 0 && objOrder != null) {
          //create ContentDocumentLink data
          for (String strDocumentId : lstDocumentId) {
            ContentDocumentLink objDocumentLink = new ContentDocumentLink();
            objDocumentLink.ContentDocumentId = strDocumentId;
            objDocumentLink.LinkedEntityId = objOrder.AccountId;
            objDocumentLink.ShareType = CONTENT_DOCUMENT_LINK_SHARETYPE;
            objDocumentLink.Visibility = CONTENT_DOCUMENT_LINK_VISIBILITY;
            lstInsertDocumentLink.add(objDocumentLink);
            //Attachments to account for associated uploads
          }

          //query ContentVersion data
          lstUpdateContentVersion = [
            SELECT
            Id,
            TPB_IsWholesaleInvoice__c
          FROM ContentVersion
          WHERE ContentDocumentId IN: lstDocumentId
          AND TPB_IsWholesaleInvoice__c = false];
          for (ContentVersion obj : lstUpdateContentVersion) {
            obj.TPB_IsWholesaleInvoice__c = true;
          }
        }

        //insert data
        if (lstInsertDocumentLink.size() > 0) {
          insert lstInsertDocumentLink;
        }
        //update data
        if (lstUpdateContentVersion.size() > 0) {
          update lstUpdateContentVersion;
        }
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

    return mapResult;
  }

  /**
   * @description search ContentVersion data
   * @param   idRecordId      idRecordId
   * @return  lstContentVersion List<ContentVersion>
   */
  public static List<ContentVersion> searchContentVersion(String idRecordId) {
    //Query order-related attachment information
    Set<String> setContentDocument = new Set<String>();
    List<ContentDocumentLink> lstDocumentLink = [
      SELECT Id, LinkedEntityId, ContentDocumentId
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :idRecordId
        AND IsDeleted = FALSE
        AND ContentDocumentId != NULL
    ];

    for (ContentDocumentLink objLink : lstDocumentLink) {
      setContentDocument.add(objLink.ContentDocumentId);
    }

    //query ContentVersion data
    List<ContentVersion> lstContentVersion = [
      SELECT Id, ContentDocumentId, Title, FileType
      FROM ContentVersion
      WHERE
        ContentDocumentId IN :setContentDocument
        AND ContentDocumentId != NULL
    ];

    return lstContentVersion;
  }
}