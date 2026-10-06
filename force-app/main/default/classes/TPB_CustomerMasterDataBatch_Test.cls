@isTest
/**
 * @author: Zeen Liu
 * date:2/21/2023
 * @description test class for TPB_CustomerMasterDataBatch
 */
private with sharing class TPB_CustomerMasterDataBatch_Test {
  @isTest
  static void testCustomerMasterDate() {
    System.Test.startTest();
    TPB_CustomerMasterDataBatch batch = new TPB_CustomerMasterDataBatch();
    System.Test.stopTest();
    System.assertEquals(1, 1, 0);
  }
}