/**
 * @author Mi Li
 * @date 9/14/2023
 * @description CON0001729-1812 Trigger to Update Customer Anchor Set in Real Time
 */
public without sharing class TPB_AccountCustomerSetHandler extends SDF_TGF_TriggerHandler {
  //get Retailer account RecordTypeId
  public static String accountRetailerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Retailer')
    .getRecordTypeId();

  /**
   * @description afterInsert description
   */
  protected override void afterInsert() {
    List<Account> lstAccountNew = (List<Account>) Trigger.new;

    //add account map
    Map<String, Account> mapAccount = new Map<String, Account>();
    for (Integer intSize = 0; intSize < lstAccountNew.size(); intSize++) {
      //RecordTypeId = 'Retailer'
      if (lstAccountNew[intSize].RecordTypeId == accountRetailerRecordTypeId) {
        mapAccount.put(lstAccountNew[intSize].Id, lstAccountNew[intSize]);
      }
    }

    //update Promotion
    if (mapAccount.size() > 0) {
      updateCustomerSetCustomer(mapAccount);
    }
  }

  /**
   * @description queryAccountSetData description
   *  @param setAccountId Set<String>
   * @return  mapAccountSet   Map<String, Set<String>>
   */
  private Map<String, Set<String>> queryAccountSetData(
    Set<String> setAccountId
  ) {
    //get cgcloud__Account_Set__c data
    List<cgcloud__Account_Set__c> lstAccountSet = [
      SELECT Id, TPB_CustomerSetCriteria__c
      FROM cgcloud__Account_Set__c
      WHERE cgcloud__Sales_Org__c != NULL
    ];

    Map<String, Set<String>> mapAccountSet = new Map<String, Set<String>>();
    for (cgcloud__Account_Set__c obj : lstAccountSet) {
      String strQuery = 'SELECT Id FROM Account WHERE ( ';
      if (
        !mapAccountSet.containsKey(obj.Id) &&
        obj.TPB_CustomerSetCriteria__c != null
      ) {
        strQuery +=
          obj.TPB_CustomerSetCriteria__c +
          '  )  AND Id IN: setAccountId LIMIT 5000';

        Set<String> setAccount = new Set<String>();
        //query account data
        List<Account> lstAccount = (List<Account>) Database.query(strQuery);
        for (Account objAcc : lstAccount) {
          setAccount.add(objAcc.id);
        }
        mapAccountSet.put(obj.Id, setAccount);
      }
    }

    //return mapAccountSet
    return mapAccountSet;
  }

  /**
   * @description queryAccountSetAccount description
   * @param   setAccountId      Set<String>
   * @param   setAccountSetId   Set<String>
   * @return  mapAccountSetAccount  Map<String, Map<String, String>>
   */
  private Map<String, Map<String, String>> queryAccountSetAccount(
    Set<String> setAccountId,
    Set<String> setAccountSetId
  ) {
    //get cgcloud__Account_Set_Account__c data
    List<cgcloud__Account_Set_Account__c> lstInsertAccountSetAcc = [
      SELECT Id, cgcloud__Account_Set_Account__c, cgcloud__Account_Set__c
      FROM cgcloud__Account_Set_Account__c
      WHERE
        cgcloud__Account_Set__c IN :setAccountSetId
        AND cgcloud__Account_Set_Account__c IN :setAccountId
    ];

    //Create a map set with Account Set Account as the key
    Map<String, Map<String, String>> mapAccountSetAccount = new Map<String, Map<String, String>>();
    for (cgcloud__Account_Set_Account__c obj : lstInsertAccountSetAcc) {
      if (!mapAccountSetAccount.containsKey(obj.cgcloud__Account_Set__c)) {
        mapAccountSetAccount.put(
          obj.cgcloud__Account_Set__c,
          new Map<String, String>{
            obj.cgcloud__Account_Set_Account__c => obj.Id
          }
        );
      } else {
        Map<String, String> mapAccountSetAcc = mapAccountSetAccount.get(
          obj.cgcloud__Account_Set__c
        );
        mapAccountSetAcc.put(obj.cgcloud__Account_Set_Account__c, obj.Id);
        mapAccountSetAccount.put(obj.cgcloud__Account_Set__c, mapAccountSetAcc);
      }
    }

    //return mapAccountSetAccount
    return mapAccountSetAccount;
  }

  /**
   * @description updateCustomerSetCustomer description
   * @param  mapAccount   Map<String, Account>
   */
  public void updateCustomerSetCustomer(Map<String, Account> mapAccount) {
    // query Account Set  data
    Map<String, Set<String>> mapAccountSet = queryAccountSetData(
      mapAccount.KeySet()
    );

    //get query Account Set Account data
    Map<String, Map<String, String>> mapAccountSetAccount = queryAccountSetAccount(
      mapAccount.KeySet(),
      mapAccountSet.KeySet()
    );

    //delete data list
    List<cgcloud__Account_Set_Account__c> lstDeleteAccountSetAcc = new List<cgcloud__Account_Set_Account__c>();
    //Insert data list
    List<cgcloud__Account_Set_Account__c> lstInsertAccountSetAcc = new List<cgcloud__Account_Set_Account__c>();
    if (mapAccountSet.size() > 0) {
      //foreach data
      for (String strCustomerSet : mapAccountSet.KeySet()) {
        //get all account data
        Set<String> setAccountId = mapAccountSet.get(strCustomerSet);
        if (mapAccountSetAccount.containsKey(strCustomerSet)) {
          //get mapAccountSetAccount data
          Map<String, String> mapAccountSetAccountId = mapAccountSetAccount.get(
            strCustomerSet
          );
          for (String str : setAccountId) {
            if (
              mapAccountSetAccountId.size() == 0 ||
              !mapAccountSetAccountId.containsKey(str)
            ) {
              //create cgcloud__Account_Set_Account__c data
              cgcloud__Account_Set_Account__c obj = new cgcloud__Account_Set_Account__c();
              obj.cgcloud__Account_Set_Account__c = str;
              obj.cgcloud__Account_Set__c = strCustomerSet;
              lstInsertAccountSetAcc.add(obj);
            }
          }
          for (String str : mapAccountSetAccountId.KeySet()) {
            if (setAccountId.size() == 0 || !setAccountId.contains(str)) {
              //create delete data
              cgcloud__Account_Set_Account__c obj = new cgcloud__Account_Set_Account__c();
              obj.Id = mapAccountSetAccountId.get(str);
              lstDeleteAccountSetAcc.add(obj);
            }
          }
        } else {
          //create cgcloud__Account_Set_Account__c data
          lstInsertAccountSetAcc.addAll(
            createCustomerSetCustomer(setAccountId, strCustomerSet)
          );
        }
      }
    }

    //insert lstInsertAccountSetAcc
    if (lstInsertAccountSetAcc.size() > 0) {
      insert lstInsertAccountSetAcc;
    }
    //delete lstDeleteAccountSetAcc
    if (lstDeleteAccountSetAcc.size() > 0) {
      delete lstDeleteAccountSetAcc;
    }
  }

  /**
   * @description createCustomerSetCustomer description
   * @param  setAccountId     Set<String>
   * @param  strCustomerSet   String
   * @return lstInsertList    List<cgcloud__Account_Set_Account__c>
   */
  private List<cgcloud__Account_Set_Account__c> createCustomerSetCustomer(
    Set<String> setAccountId,
    String strCustomerSet
  ) {
    //create cgcloud__Account_Set_Account__c data
    List<cgcloud__Account_Set_Account__c> lstInsertList = new List<cgcloud__Account_Set_Account__c>();
    for (String str : setAccountId) {
      cgcloud__Account_Set_Account__c obj = new cgcloud__Account_Set_Account__c();
      obj.cgcloud__Account_Set_Account__c = str;
      obj.cgcloud__Account_Set__c = strCustomerSet;
      lstInsertList.add(obj);
    }

    //return lstInsertList
    return lstInsertList;
  }
}