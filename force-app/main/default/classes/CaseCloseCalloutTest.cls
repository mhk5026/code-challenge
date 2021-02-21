@IsTest
public with sharing class CaseCloseCalloutTest {
  /**
   * @description - Sets up initial test data which is re-used in multiple tests
   */
  @TestSetup
  static void makeData() {
    // Create basic test data
    List<Case> caseRecords;
    caseRecords = CaseTestDataFactory.createCaseRecords(1, 'Closed');

    // Make sure test data included required fields (in case Trigger does not fire)
    for (Case caseRecord : caseRecords) {
      caseRecord.Closed_By__c = UserInfo.getUserId();
    }

    // Insert test data
    insert caseRecords;
  }

  /**
   *
   */
  @IsTest
  static void createRequestTest() {
    // Get a test record
    Case caseRecord = [
      SELECT Id, Closed_By__c
      FROM Case
      WHERE Status = 'Closed'
      LIMIT 1
    ];
    // Set test  data
    Id caseId = caseRecord.Id;
    Id userId = caseRecord.Closed_By__c;

    // Start Test
    Test.startTest();

    // Create request object
    CaseCloseCallout.Request req;
    req = CaseCloseCallout.createRequest(caseId, userId);

    //  Stop Test
    Test.stopTest();

    // Verify results
    System.assertEquals(caseId, req.id, 'Incorrect Case Id');
    System.assertEquals(userId, req.agentid, 'Incorrect Case Id');
  }

  /**
   * @description - Executes a positive test, expecting a successful response
   */
  @IsTest
  static void calloutPositiveTest() {
    // Get a test record
    Case caseRecord = [
      SELECT Id, Closed_By__c
      FROM Case
      WHERE Status = 'Closed'
      LIMIT 1
    ];

    // Set mock endpoint and timeout
    String endpoint = 'https://example.com/';
    Integer timeout = 30;

    // Set mock data for callout
    Id caseId = caseRecord.Id;
    Id userId = caseRecord.Closed_By__c;

    // Start test
    Test.startTest();

    // Create the mock response
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('TestCaseCalloutSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    // Make the callout
    String secretKey;
    secretKey = CaseCloseCallout.makeCallout(endpoint, timeout, caseId, userId);

    // Stop test
    Test.stopTest();

    // Verify results
    String expected = 'abc123';
    System.assertEquals(expected, secretKey, 'Incorrect Secret Key');
  }

  /**
   * @description - Executes a negative test, expecting an exception
   */
  @IsTest
  static void calloutNegativeTest() {
    // Get a test record
    Case caseRecord = [
      SELECT Id, Closed_By__c
      FROM Case
      WHERE Status = 'Closed'
      LIMIT 1
    ];

    // Set mock endpoint and timeout
    String endpoint = 'https://example.com/';
    Integer timeout = 30;

    // Set mock data for callout
    Id caseId = caseRecord.Id;
    Id userId = caseRecord.Closed_By__c;

    // Start test
    Test.startTest();

    // Create the mock response
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('TestCaseCalloutFailure');
    mock.setStatusCode(500);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    // Make the callout
    String errorMsg;
    try {
      CaseCloseCallout.makeCallout(endpoint, timeout, caseId, userId);
    } catch (CaseCloseCallout.CalloutException ex) {
      errorMsg = ex.getMessage();
    }

    // Stop test
    Test.stopTest();

    // Verify results
    String expected = 'something went wrong';
    System.assertEquals(expected, errorMsg, 'Incorrect Error Message');
  }
}
