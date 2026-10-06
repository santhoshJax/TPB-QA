/**
 * @author Mi Li
 * @date 8/2/2023
 * @description CON0001729-1674: Screen flow for Mass Prebook
 */
public without sharing class TPB_MassPrebookControllerUtility {
  public static final String CONTENT_VERSION_CONTENT_LOCATION = 'S'; // S specify this document is in SF
  public static final String CONTENT_DOCUMENT_LINK_SHARETYPE = 'I';
  public static final String CONTENT_DOCUMENT_LINK_VISIBILITY = 'AllUsers';

  // map returns the result of calling
  private static final String RTN_KEY_OK = TPB_TestFactory.RTN_KEY_OK;
  private static final String RTN_KEY_NG = TPB_TestFactory.RTN_KEY_NG;
  private static final String RTN_KEY_DATA = TPB_TestFactory.RTN_KEY_DATA;
  private static final String RTN_KEY_RESULT = TPB_TestFactory.RTN_KEY_RESULT;
  private static final String RTN_KEY_ERR_MSG = TPB_TestFactory.RTN_KEY_ERR_MSG;

  //TPB_Promotion_Allocation_Item__c  recordType Id
  public static String proAllocationItemOrgRecordTypeId = TPB_TestFactory.proAllocationItemOrgRecordTypeId;

  private static final String ORG_UNIT_ERR_MSG = 'You need to maintain the org unit data in the Promotion Allocation Items.';
  /**
   * @description uploadFile
   * @param  lstFileContent List<String>
   * @param  strFileFormat  String
   * @param  strFileName    String
   * @param  strRecordId    String
   * @param  boolAssignName Boolean
   * @return mapRtn          Map<String, String>
   */
  public static Map<String, String> uploadFile(
    List<String> lstFileContent,
    String strFileFormat,
    String strFileName,
    String strRecordId,
    Boolean boolAssignName
  ) {
    Map<String, String> mapRtn = new Map<String, String>();
    Savepoint sp = Database.setSavepoint();
    try {
      //Split up to 2 files to save data
      List<ContentVersion> lstContentVersion = new List<ContentVersion>();
      //If the data exceeds 6MB, split the data into two files and save them
      for (Integer intSize = 0; intSize < lstFileContent.size(); intSize++) {
        //save the file content to ContentVersion
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = CONTENT_VERSION_CONTENT_LOCATION;
        conVer.PathOnClient = boolAssignName == false
          ? strFileFormat + String.valueOf(intSize + 1)
          : strFileFormat;
        conVer.Title = boolAssignName == false
          ? strFileName + String.valueOf(intSize + 1)
          : strFileName;
        conVer.VersionData = Blob.valueOf(lstFileContent[intSize]);
        lstContentVersion.add(conVer);
      }
      //insert lstContentVersion
      insert lstContentVersion;

      //create ContentDocumentLink data
      createContentDocumentLink(lstContentVersion, strRecordId);

      mapRtn.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception objEx) {
      Database.rollback(sp);
      throw new AuraHandledException(
        System.Label.TPB_ErrorOccurred + objEx.getMessage()
      );
    }
    return mapRtn;
  }

  /**
   * @description get ContentDocument Link
   * @param  lstContentVersion    List<ContentVersion>
   * @param  strRecordId          String
   */
  public static void createContentDocumentLink(
    List<ContentVersion> lstContentVersion,
    String strRecordId
  ) {
    Set<Id> setConVerIds = new Set<Id>();
    for (ContentVersion conVer : lstContentVersion) {
      setConVerIds.add(conVer.Id);
    }
    //get the content document Id from ContentVersion
    List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
    for (ContentVersion obj : [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id IN :setConVerIds
    ]) {
      //create ContentDocumentLink
      ContentDocumentLink conDocLink = new ContentDocumentLink();
      conDocLink.ContentDocumentId = obj.ContentDocumentId;
      conDocLink.LinkedEntityId = strRecordId;
      conDocLink.ShareType = CONTENT_DOCUMENT_LINK_SHARETYPE;
      conDocLink.Visibility = CONTENT_DOCUMENT_LINK_VISIBILITY;
      lstContentDocumentLink.add(conDocLink);
    }
    //create ContentDocumentLink
    insert lstContentDocumentLink;
  }

  /**
   * @description get ContentDocument Link
   * @param  strRecordId    String
   * @param  strFileName    String
   * @return setContentDocumentLink  Set<String>
   */
  public static Set<String> getContentDocumentLink(
    String strRecordId,
    String strFileName
  ) {
    Set<String> setContentDocumentLink = new Set<String>();
    //query ContentDocumentLink
    List<ContentDocumentLink> lstContentDocumentLink = [
      SELECT Id, ContentDocumentId, LinkedEntityId
      FROM ContentDocumentLink
      WHERE
        LinkedEntityId = :strRecordId
        AND ContentDocument.Title LIKE :strFileName
      ORDER BY ContentDocument.Title ASC
    ];
    //add ContentDocumentId
    for (ContentDocumentLink obj : lstContentDocumentLink) {
      setContentDocumentLink.add(obj.ContentDocumentId);
    }

    return setContentDocumentLink;
  }

  /**
   * @description get ContentVersion
   * @param  setContentDocumentLink   Set<String>
   * @param  strFileName    String
   * @return lstContentVersion        List<ContentVersion>
   */
  public static List<ContentVersion> getContentVersion(
    Set<String> setContentDocumentLink,
    String strFileName
  ) {
    //query ContentVersion
    List<ContentVersion> lstContentVersion = [
      SELECT Id, VersionData, ContentDocumentId
      FROM ContentVersion
      WHERE
        ContentDocumentId IN :setContentDocumentLink
        AND Title LIKE :strFileName
      ORDER BY Title ASC
    ];

    //return data
    return lstContentVersion;
  }

  /**
   * @description get Data All
   * @param  strRecordId    String
   * @param  strFileName    String
   * @return mapRtn         Map<String, String>
   */
  public static List<String> getDataAll(
    String strRecordId,
    String strFileName
  ) {
    //get ContentDocumentLink
    Set<String> setContentDocumentLink = getContentDocumentLink(
      strRecordId,
      strFileName
    );
    List<String> lstString = new List<String>();
    //get ContentVersion
    List<ContentVersion> lstContentVersion = getContentVersion(
      setContentDocumentLink,
      strFileName
    );

    //return VersionData
    for (ContentVersion obj : lstContentVersion) {
      lstString.add(obj.VersionData.toString());
    }
    return lstString;
  }

  /**
   * @description deleteFile
   * @param  strRecordId    String
   * @param  strFileName    String
   * @return mapRtn         Map<String, String>
   */
  public static Map<String, String> deleteFile(
    String strRecordId,
    String strFileName
  ) {
    Map<String, String> mapResult = new Map<String, String>();
    Savepoint sp = Database.setSavepoint();
    try {
      //get ContentDocumentLink
      Set<String> setContentDocumentId = getContentDocumentLink(
        strRecordId,
        strFileName
      );
      if (setContentDocumentId.size() > 0) {
        //query ContentDocument data
        List<ContentDocument> lstContentDocument = [
          SELECT Id
          FROM ContentDocument
          WHERE Id IN :setContentDocumentId
        ];
        delete lstContentDocument;
      }

      //return data
      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception ex) {
      Database.rollback(sp);
    }
    return mapResult;
  }

  /**
   * @description deleteFile
   * @param  strRecordId    String
   * @param  strFileName    String
   * @param  strNewFileName    String
   * @return mapRtn         Map<String, String>
   */
  public static Map<String, String> updateFile(
    String strRecordId,
    String strFileName,
    String strNewFileName
  ) {
    Map<String, String> mapResult = new Map<String, String>();
    Savepoint sp = Database.setSavepoint();
    try {
      Set<String> setContentDocumentId = getContentDocumentLink(
        strRecordId,
        strFileName + '%'
      );
      if (setContentDocumentId.size() > 0) {
        List<ContentDocument> lstContentDocument = [
          SELECT Id, Title
          FROM ContentDocument
          WHERE Id IN :setContentDocumentId
        ];
        for (ContentDocument obj : lstContentDocument) {
          obj.Title = obj.Title.replace(strFileName, strNewFileName);
        }
        update lstContentDocument;
      }

      mapResult.put(RTN_KEY_RESULT, RTN_KEY_OK);
    } catch (Exception ex) {
      Database.rollback(sp);
    }
    return mapResult;
  }

  /**
   * @description query Retailer Account
   * @param    setAccountId     Account Ids
   * @return   List<Account>    List<Account>
   */
  public static List<Account> queryRetailerAccount(Set<String> setAccountId) {
    return [
      SELECT Id, Ownership__c, Parent.OwnerId
      FROM Account
      WHERE Id IN :setAccountId AND ParentId != NULL AND Ownership__c != NULL
    ];
  }

  /**
   * @description query Org Unit Promotion Allocation
   * @param   strHqOwnerId    Hq Owner Id
   * @param   strHqAccountId  Hq Account Id
   * @param   strWave         Wave
   * @param   strProductId    Product Id
   * @return  mapOrgUnitPromotion Map<String, TPB_Promotion_Allocation_Item__c>
   */
  public static Map<String, TPB_Promotion_Allocation_Item__c> queryOrgUnitPromotionAllocation(
    String strHqOwnerId,
    Set<String> setAccountId,
    String strWave,
    String strProductId
  ) {
    //query Order_Item data
    List<Account> lstRetailerAccount = queryRetailerAccount(setAccountId);
    //Independent map
    Map<String, Account> mapIndependentAcc = new Map<String, Account>();
    //Chain map
    Map<String, Account> mapChainAcc = new Map<String, Account>();
    for (Account obj : lstRetailerAccount) {
      //Ownership__c == 'Independent'
      if (obj.Ownership__c == 'Independent') {
        mapIndependentAcc.put(obj.Id, obj);

        //Ownership__c == 'FSO Chain' || Ownership__c == 'NAM Chain'
      } else if (
        obj.Ownership__c == 'FSO Chain' ||
        obj.Ownership__c == 'NAM Chain'
      ) {
        mapChainAcc.put(obj.Id, obj);
      }
    }

    //get All OrgUnit Allocation
    Map<String, String> mapOrgUnitIds = getAllOrgUnitAllocation(
      mapIndependentAcc.KeySet(),
      mapChainAcc.KeySet(),
      new Set<String>{ strHqOwnerId }
    );

    Map<String, TPB_Promotion_Allocation_Item__c> mapStoreOrgUnitAllocation = new Map<String, TPB_Promotion_Allocation_Item__c>();
    //getAccountOwnerUserData
    Map<String, TPB_Promotion_Allocation_Item__c> mapOrgUnitPromotion = getAccountOwnerUserData(
      strWave,
      strProductId,
      mapOrgUnitIds.values()
    );

    //mapOrgUnitIds.size() > 0
    if (mapOrgUnitIds.size() > 0) {
      //get All Promotion Allocation Item
      for (Account obj : lstRetailerAccount) {
        if (
          mapOrgUnitIds.containsKey(obj.id) &&
          mapIndependentAcc.containsKey(obj.id)
        ) {
          mapStoreOrgUnitAllocation.put(
            obj.id,
            mapOrgUnitPromotion.get(mapOrgUnitIds.get(obj.id))
          );
        } else if (
          mapOrgUnitIds.containsKey(obj.Parent.OwnerId) &&
          mapChainAcc.containsKey(obj.id)
        ) {
          mapStoreOrgUnitAllocation.put(
            obj.id,
            mapOrgUnitPromotion.get(mapOrgUnitIds.get(obj.Parent.OwnerId))
          );
        }
      }
    }
    //return data
    return mapStoreOrgUnitAllocation;
  }

  /**
   * @description getAllOrgUnitAllocation Data
   * @param   setIndependentAcc   Map<String, Account>
   * @param   setChainAcc         Map<String, Account>
   * @param   setHqOwnerId        String
   * @return  mapOrgUnitPromotion  Map<String, TPB_Promotion_Allocation_Item__c>
   */
  public static Map<String, String> getAllOrgUnitAllocation(
    Set<String> setIndependentAcc,
    Set<String> setChainAcc,
    Set<String> setHqOwnerId
  ) {
    //Org Unit Ids
    Map<String, String> mapOrgUnitIds = new Map<String, String>();
    //setIndependentAcc.size() > 0
    if (setIndependentAcc.size() > 0) {
      //searchIndependentOrgUnit
      Map<String, String> mapIndependentOrgUnit = searchIndependentOrgUnit(
        setIndependentAcc
      );
      mapOrgUnitIds.putAll(mapIndependentOrgUnit);
    }

    //setChainAcc.size() > 0
    if (setChainAcc.size() > 0) {
      //searchChainOrgUnit
      Map<String, String> mapChainAcc = searchChainOrgUnit(setHqOwnerId);
      mapOrgUnitIds.putAll(mapChainAcc);
    }

    return mapOrgUnitIds;
  }

  /**
   * @description get Account Owner User Data
   * @param   strWave        String
   * @param   strProductId   String
   * @param   lstOrgUnitIds  Set<String>
   * @return  mapOrgUnitPromotion  Map<String, TPB_Promotion_Allocation_Item__c>
   */
  public static Map<String, TPB_Promotion_Allocation_Item__c> getAccountOwnerUserData(
    String strWave,
    String strProductId,
    List<String> lstOrgUnitIds
  ) {
    Map<String, TPB_Promotion_Allocation_Item__c> mapOrgUnitPromotion = new Map<String, TPB_Promotion_Allocation_Item__c>();
    //query TPB_Promotion_Allocations__c data
    List<TPB_Promotion_Allocation_Item__c> lstPromotionAllocationItem = [
      SELECT
        Id,
        TPB_Total_Max_Allocation__c,
        TPB_Max_Quantity__c,
        TPB_Product__c,
        TPB_Org_Unit__c,
        TPB_Quantity_Planned__c,
        TPB_Total_QTY_Ordered__c,
        TPB_Account__c
      FROM TPB_Promotion_Allocation_Item__c
      WHERE
        RecordTypeId = :proAllocationItemOrgRecordTypeId
        AND TPB_WavePeriod_And_OrderEntry_Date__c = :strWave
        AND TPB_Product__c = :strProductId
        AND TPB_Org_Unit__c IN :lstOrgUnitIds
    ];
    //add mapOrgUnitPromotion
    for (
      TPB_Promotion_Allocation_Item__c objPromotionAllocationItem : lstPromotionAllocationItem
    ) {
      if (
        !mapOrgUnitPromotion.containsKey(
          objPromotionAllocationItem.TPB_Org_Unit__c
        )
      ) {
        mapOrgUnitPromotion.put(
          objPromotionAllocationItem.TPB_Org_Unit__c,
          objPromotionAllocationItem
        );
      }
    }

    //return mapOrgUnitPromotion data
    return mapOrgUnitPromotion;
  }

  /**
   * @description search Independent Org Unit
   * @param   setIndependentAcc      Set<String>
   * @return  mapIndependentOrgUnit  Map<String, String>
   */
  public static Map<String, String> searchIndependentOrgUnit(
    Set<String> setIndependentAcc
  ) {
    Map<String, String> mapIndependentOrgUnit = new Map<String, String>();
    //query cgcloud__Account_Org_Unit__c data
    List<cgcloud__Account_Org_Unit__c> lstAccountOrgUnit = [
      SELECT Id, cgcloud__Account__c, cgcloud__Org_Unit__c
      FROM cgcloud__Account_Org_Unit__c
      WHERE
        cgcloud__Active__c = TRUE
        AND cgcloud__Account__c IN :setIndependentAcc
        AND cgcloud__Org_Unit__c != NULL
        AND ((cgcloud__Valid_From__c <= :System.Date.today()
        AND cgcloud__Valid_Thru__c > :System.Date.today())
        OR (cgcloud__Valid_From__c < :System.Date.today()
        AND cgcloud__Valid_Thru__c >= :System.Date.today()))
    ];
    for (cgcloud__Account_Org_Unit__c obj : lstAccountOrgUnit) {
      mapIndependentOrgUnit.put(
        obj.cgcloud__Account__c,
        obj.cgcloud__Org_Unit__c
      );
    }

    return mapIndependentOrgUnit;
  }

  /**
   * @description search Chain Org Unit
   * @param   setHqOwnerId       Hq account OwnerId
   * @return  mapChainAcc  Map<String, String>
   */
  public static Map<String, String> searchChainOrgUnit(
    Set<String> setHqOwnerId
  ) {
    Map<String, String> mapChainAcc = new Map<String, String>();
    //query cgcloud__Org_Unit_User__c data
    List<cgcloud__Org_Unit_User__c> lstAccountOrgUnit = TPB_MassPrebookService.searchChainOrgUnitData(
      setHqOwnerId
    );
    for (cgcloud__Org_Unit_User__c obj : lstAccountOrgUnit) {
      mapChainAcc.put(obj.cgcloud__User__c, obj.cgcloud__Org_Unit__c);
    }

    return mapChainAcc;
  }

  /**
   * @description verify Order Quantity
   * @param   item   TPB_MassPrebookWrapper.MassPrebookDetail
   * @return  boolValidations  Boolean
   */
  public static Boolean verifyOrderQuantity(
    TPB_MassPrebookWrapper.MassPrebookDetail item
  ) {
    Boolean boolValidations = false;
    //qTO is less than 0
    if (Integer.valueOf(item.qTO) < 0) {
      boolValidations = true;
      //qTP is equal to 0 and qTO is greater than 1
    } else if (
      Integer.valueOf(item.qTP) == 0 &&
      Integer.valueOf(item.qTO) > 1
    ) {
      boolValidations = true;
      //qTP is greater than 1, and qTO is greater than 2 times of qTP
    } else if (
      Integer.valueOf(item.qTP) >= 1 &&
      Integer.valueOf(item.qTO) > Integer.valueOf(item.qTP) * 2
    ) {
      boolValidations = true;
    }
    //qTP is greater than mxQ
    if (Integer.valueOf(item.qTP) > Integer.valueOf(item.mxQ)) {
      boolValidations = true;
    }

    //return boolValidations
    return boolValidations;
  }

  /**
   * @description update Ordered Quantity
   * @param   lstInputItems       List<Map<String, String>>
   * @param   objOrderData        String
   * @param   booIsUpdate         String
   * @param   mapOrgUnitQuantity  String
   *  @param  mapAccOrgUnit       String
   * @return  mapResult           Map<String, Object>
   */
  public static Map<String, Object> verifyQuantityOfProductRemaining(
    List<TPB_MassPrebookWrapper.MassPrebookDetail> lstInputItems,
    Order objOrderData,
    Boolean booIsUpdate,
    Map<String, Double> mapOrgUnitQuantity,
    Map<String, String> mapAccOrgUnit
  ) {
    Map<String, Object> mapResult = new Map<String, Object>{};
    //get All Promotion Allocation Item
    Map<String, TPB_Promotion_Allocation_Item__c> mapAccPromotionAllocationItem = TPB_MassPrebookService.getAllPromotionAllocationItem(
      objOrderData.TPB_HQ_Account__c,
      lstInputItems[0].pId,
      objOrderData.TPB_Wave_Order_Date__c,
      new Set<String>()
    );

    //query OrgUnit Promotion Allocation
    Map<String, TPB_Promotion_Allocation_Item__c> mapOrgUnitPromotion = queryOrgUnitPromotionAllocation(
      objOrderData.TPB_HQ_Account__r.OwnerId,
      mapAccPromotionAllocationItem.KeySet(),
      objOrderData.TPB_Wave_Order_Date__c,
      lstInputItems[0].pId
    );

    if (
      mapAccPromotionAllocationItem.size() != mapOrgUnitPromotion.size() &&
      mapAccPromotionAllocationItem.size() > 0
    ) {
      mapResult.put('boolValidations', true);
      mapResult.put(RTN_KEY_ERR_MSG, ORG_UNIT_ERR_MSG);

      return mapResult;
    }

    //Validations QTY
    Boolean boolValidations = false;
    //Need to update the org unit Promotion
    Map<String, TPB_Promotion_Allocation_Item__c> mapUpdateOrgUnitQuantity = new Map<String, TPB_Promotion_Allocation_Item__c>();
    //Update Promotion Allocation Item
    List<TPB_Promotion_Allocation_Item__c> lstUpdatePromotionAllocationItem = new List<TPB_Promotion_Allocation_Item__c>();
    for (TPB_MassPrebookWrapper.MassPrebookDetail item : lstInputItems) {
      //Receive data for conversion
      boolValidations = verifyOrderQuantity(item);
      if (boolValidations) {
        break;
      }
      //verify store  Quantity
      if (mapAccPromotionAllocationItem.containsKey(item.aId)) {
        //store Promotion Allocation
        TPB_Promotion_Allocation_Item__c obj = mapAccPromotionAllocationItem.get(
          item.aId
        );
        //Total Max Quantity
        Double douTotalMaxQuantity = amountConvert(obj.TPB_Max_Quantity__c);
        //Total QTY Ordered
        Double douTotalQTYOrdered = amountConvert(obj.TPB_Total_QTY_Ordered__c);
        if (douTotalQTYOrdered + (item.qTO - item.qTOO) > douTotalMaxQuantity) {
          boolValidations = true;

          break;
        } else {
          //update Total_QTY_Ordered  QTY
          TPB_Promotion_Allocation_Item__c objAllocationItem = new TPB_Promotion_Allocation_Item__c();
          objAllocationItem.Id = obj.Id;
          objAllocationItem.TPB_Total_QTY_Ordered__c =
            douTotalQTYOrdered + (item.qTO - item.qTOO);
          lstUpdatePromotionAllocationItem.add(objAllocationItem);
        }
      }

      //verify org unit  Quantity
      if (mapOrgUnitPromotion.containsKey(item.aId)) {
        //org unit Promotion Allocation
        TPB_Promotion_Allocation_Item__c objOrgUnit = mapOrgUnitPromotion.get(
          item.aId
        );
        //org unit Total Max Quantity
        Double douOrgUnitTotalMaxQuantity = amountConvert(
          objOrgUnit.TPB_Total_Max_Allocation__c
        );

        //org unit Total QTY Ordered
        Double douOrgUnitTotalQTYOrdered = amountConvert(
          objOrgUnit.TPB_Total_QTY_Ordered__c
        );
        //The current store has the same quota as all previous org units
        Double douAllOrderQTY = (item.qTO - item.qTOO);
        if (mapOrgUnitQuantity.containsKey(objOrgUnit.Id)) {
          douAllOrderQTY += mapOrgUnitQuantity.get(objOrgUnit.Id);
        }
        //If the quota exceeds the maximum, an error message is displayed
        if (
          douOrgUnitTotalQTYOrdered + douAllOrderQTY >
          douOrgUnitTotalMaxQuantity
        ) {
          boolValidations = true;
          break;
        }
        mapAccOrgUnit.put(item.aId, objOrgUnit.Id);
        //Save the amount originally held by org unit
        mapUpdateOrgUnitQuantity.put(objOrgUnit.id, objOrgUnit);
        //Save all org uint to the same store quota
        mapOrgUnitQuantity.put(objOrgUnit.id, douAllOrderQTY);
      }
    }
    //update Promotion_Allocation_Item
    if (!boolValidations && booIsUpdate) {
      Database.executeBatch(
        new TPB_MassPrebookUpdateBatch(lstUpdatePromotionAllocationItem),
        5000
      );

      //update org unit Promotion
      for (String str : mapUpdateOrgUnitQuantity.KeySet()) {
        mapUpdateOrgUnitQuantity.get(str)
          .TPB_Total_QTY_Ordered__c += mapOrgUnitQuantity.get(str);
      }
      //Update Org Unit Quantity
      update mapUpdateOrgUnitQuantity.values();
    }

    //return message
    mapResult.put('boolValidations', boolValidations);
    mapResult.put('mapOrgUnitQuantity', mapOrgUnitQuantity);
    mapResult.put('mapAccOrgUnit', mapAccOrgUnit);

    //return mapResult
    return mapResult;
  }

  /**
   * @description amountConvert
   * @param   intOrderQuantity    Double
   * @return  intOrderQuantity    Double
   */
  public static Double amountConvert(Decimal intOrderQuantity) {
    return intOrderQuantity == null ? 0 : intOrderQuantity;
  }
}