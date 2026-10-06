/**
 * TPB_CreateInventoryForFlow
 * @author Qiyuan Dou
 * @date 2023-04-24
 * @description Create Inventory by flow
 *
 */
public with sharing class TPB_CreateInventoryForFlow {
  //Inventory template name
  private static final String NEWINVENTORYTEMPLATENAME = 'TPB Control Template';
  //Inventory period
  private static final String CREATEINVENTORYFORFLOWPERIOD = '3650';
  //Inventory transaction name
  private static final String INVTRANTEMPLATENAME = 'TPB_initial';
  //Inventory phase
  private static final String INVENTORYACTIVE = 'Active';

  /**
   * @description create Inventory
   * @param   inputs      List<InputParameters>
   * @return  lstInteger  List<Integer>
   */
  @InvocableMethod(label='TPB_CreateInventoryForFlow' category='Inventory')
  public static List<Integer> createInventory(List<InputParameters> inputs) {
    //Get value from flow
    InputParameters input = new InputParameters();
    List<Integer> lstInteger = new List<Integer>();
    if (inputs.size() > 0) {
      input = inputs[0];
    }
    //Get tour that user choose
    List<String> lstCgcloudTourId = new List<String>(input.lstCgcloudTour);
    //Get product brand that user choose
    List<String> lstCgcloudProductBrandId = new List<String>(
      input.lstCgcloudProduct
    );
    //Get number that user input
    Integer cgcloudInitialNumber = input.cgcloudInitialInventory;
    //Search product by brand
    List<Product2> lstProduct = new List<Product2>();
    lstProduct = [
      SELECT Id, TPB_Exclude_From_Base_Pricing__c
      FROM Product2
      WHERE cgcloud__Criterion_3_Product__c IN :lstCgcloudProductBrandId
    ];
    //Store productId
    Map<String, Boolean> mapCgcloudProductId = new Map<String, Boolean>();
    if (lstProduct.size() > 0) {
      for (Product2 prd : lstProduct) {
        mapCgcloudProductId.put(prd.Id, prd.TPB_Exclude_From_Base_Pricing__c);
      }
    }
    //Get inventory transaction template
    List<cgcloud__Inventory_Transaction_Template__c> invTranTemp = new List<cgcloud__Inventory_Transaction_Template__c>();
    invTranTemp = [
      SELECT Id, Name
      FROM cgcloud__Inventory_Transaction_Template__c
      WHERE Name = :INVTRANTEMPLATENAME
      LIMIT 1
    ];
    //Get inventory template
    List<cgcloud__Inventory_Control_Template__c> invTemplate = new List<cgcloud__Inventory_Control_Template__c>();
    invTemplate = [
      SELECT Id, Name
      FROM cgcloud__Inventory_Control_Template__c
      WHERE Name = :NEWINVENTORYTEMPLATENAME
      LIMIT 1
    ];
    //Create Inventory
    List<cgcloud__Inventory__c> lstCgcloudInventory = new List<cgcloud__Inventory__c>();
    if (
      lstCgcloudTourId.size() > 0 &&
      mapCgcloudProductId.size() > 0 &&
      invTemplate.size() > 0 &&
      invTranTemp.size() > 0
    ) {
      //Loop tour and product
      for (String strTourId : lstCgcloudTourId) {
        for (String strProductId : mapCgcloudProductId.keySet()) {
          cgcloud__Inventory__c objInventory = new cgcloud__Inventory__c();
          //Set Tour, Product, Phase, Inventory template
          objInventory.cgcloud__Tour__c = strTourId;
          objInventory.cgcloud__Product__c = strProductId;
          objInventory.cgcloud__Phase__c = INVENTORYACTIVE;
          objInventory.cgcloud__Inventory_Template__c = invTemplate[0].Id;
          //Set Initial Number, Date, User
          objInventory.cgcloud__Initial_Inventory__c = cgcloudInitialNumber;
          objInventory.cgcloud__Valid_From__c = Date.today();
          objInventory.cgcloud__Valid_Thru__c =
            Date.today() + Integer.ValueOf(CREATEINVENTORYFORFLOWPERIOD);
          objInventory.cgcloud__User__c = UserInfo.getUserId();
          objInventory.TPB_AvgPrice__c = mapCgcloudProductId.get(
              strProductId
            ) == true
            ? null
            : 0;
          //Add to list
          lstCgcloudInventory.add(objInventory);
        }
      }
    }
    //Insert Inventory
    Database.SaveResult[] srList = Database.insert(lstCgcloudInventory, false);
    Integer intSuccess = 0;
    if (srList.size() > 0) {
      for (Database.SaveResult result : srList) {
        //Get success number
        if (result.isSuccess()) {
          intSuccess++;
        }
      }
    }
    //Return success number
    lstInteger.add(intSuccess);
    //Create initial inventory transaction for inventory
    List<cgcloud__Inventory_Transaction__c> invTranToNew = new List<cgcloud__Inventory_Transaction__c>();
    if (invTranTemp.size() > 0) {
      for (cgcloud__Inventory__c inv : lstCgcloudInventory) {
        cgcloud__Inventory_Transaction__c objInvTran = new cgcloud__Inventory_Transaction__c();
        objInvTran.cgcloud__Inventory__c = inv.Id;
        //Set inventory transaction number
        objInvTran.cgcloud__Amount__c = cgcloudInitialNumber;
        objInvTran.cgcloud__Inventory_Transaction_Template__c = invTranTemp[0]
          .Id;
        invTranToNew.add(objInvTran);
      }
      //Insert inventory transactions
      insert invTranToNew;
    }
    return lstInteger;
  }

  /**
   * @description Wrapper class for input parameters
   */
  public class InputParameters {
    /**
     * @description Tour input
     */
    @InvocableVariable(required=true)
    public List<String> lstCgcloudTour;
    /**
     * @description Product Brand input
     */
    @InvocableVariable(required=true)
    public List<String> lstCgcloudProduct;
    /**
     * @description InitialInventory input
     */
    @InvocableVariable(required=true)
    public Integer cgcloudInitialInventory;
  }
}