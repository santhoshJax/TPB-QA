/**
 * @author Mi Li
 * @date 4/25/2023
 * @description TPB_AccountRelationPDFBatch test class
 */
@isTest
private class TPB_AccountRelationPDFBatch_Test {
  //Variable Definition
  private static String strTest = 'test';
  private static String strTestDotPdf = 'test.pdf';

  @testSetup
  static void setup() {
    //create Account for test.
    Account accObj = TPB_TestFactory.createAccount();
    //create Vsisit for test.
    Visit objVisit = TPB_TestFactory.createVisit(accObj);
    //create Order for test.
    cgcloud__Order__c objOrder = TPB_TestFactory.createAdOrder(objVisit);
    objOrder.cgcloud__Phase__c = 'Released';
    objOrder.cgcloud__Release_Time__c = Datetime.now();
    objOrder.cgcloud__Order_Account__c = accObj.id;
    objOrder.cgcloud__Delivery_Recipient__c = accObj.id;
    update objOrder;
    //create ContentVersion for test.
    ContentVersion objContentVersion = new ContentVersion(
      VersionData = Blob.valueOf(strTest),
      PathOnClient = strTestDotPdf,
      Title = strTest
    );
    insert objContentVersion;
    //create ContentDocumentLink for test.
    List<ContentVersion> lstContentVersion = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :objContentVersion.Id
    ];
    insert new ContentDocumentLink(
      LinkedEntityId = objOrder.Id,
      ContentDocumentId = lstContentVersion[0].ContentDocumentId
    );
  }

  @isTest
  static void testAccountRelationPdfBatch() {
    //Execute batch to determine expected returns
    System.Test.startTest();
    TPB_AccountRelationPDFBatch batch = new TPB_AccountRelationPDFBatch();
    Database.executeBatch(batch);
    System.Test.stopTest();
    //assert batch job result.
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Order__c
        WHERE cgcloud__Order_Account__c != NULL
      ],
      0
    );
  }

  @isTest
  static void testAccountRelationPdfScheduler2() {
    //Execute batch to determine expected returns
    System.Test.startTest();
    TPB_AccountRelationPDFScheduler objScheduleJob = new TPB_AccountRelationPDFScheduler();
    objScheduleJob.execute(null);
    System.Test.stopTest();
    //assert batch job result.
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM cgcloud__Order__c
        WHERE cgcloud__Order_Account__c != NULL
      ],
      0
    );
  }
}