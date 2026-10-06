/**
 * @author Mi Li
 * @date 9/25/2023
 * @description CON0001729-1641: "Chain Account Overview" Widget in Store Cockpit
 */
@isTest
public without sharing class TPB_HQAccContentDocumentLinkHand_Test {
  /*
   * @description set up test data
   */
  @TestSetup
  static void setup() {
    //create  HQ Account for test.
    Account headquarter = new Account(
      ShippingCountry = 'US',
      ShippingLatitude = 38.90996,
      ShippingLongitude = -77.01893,
      ShippingPostalCode = '20001',
      ShippingState = 'DC',
      ShippingStreet = 'U.S. Route 66 ',
      ShippingCity = 'Baltimore'
    );
    headquarter.Name = 'Test Headquarter';
    headquarter.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Headquarter')
      .getRecordTypeId();
    //insert headquarter
    insert headquarter;
  }
  /*
   * @description test file uploaded
   */
  @isTest
  static void testFileUpload() {
    //query account data
    List<Account> lstAccount = [
      SELECT ID
      FROM ACCOUNT
      WHERE Name = 'Test Headquarter'
      LIMIT 1
    ];
    //create ContentVersion for test.
    ContentVersion objContentVersion = new ContentVersion(
      VersionData = Blob.valueOf('Test Headquarter uploads files'),
      PathOnClient = 'test.pdf',
      Title = 'test'
    );
    //insert objContentVersion
    insert objContentVersion;

    //create ContentDocumentLink for test.
    List<ContentVersion> lstContentVersion = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :objContentVersion.Id
    ];
    //insert ContentDocumentLink for test.
    insert new ContentDocumentLink(
      LinkedEntityId = lstAccount[0].Id,
      ContentDocumentId = lstContentVersion[0].ContentDocumentId
    );
    //query ContentVersion data
    List<ContentVersion> lstContentVersionDate = [
      SELECT Id, TPB_IsHQAttachment__c
      FROM ContentVersion
      WHERE ContentDocumentId = :lstContentVersion[0].ContentDocumentId
    ];
    //assert Equals
    System.assertEquals(
      true,
      lstContentVersionDate[0].TPB_IsHQAttachment__c,
      false
    );
  }
}