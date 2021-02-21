@IsTest
public with sharing class CaseCloseBatchHandlerTest {
  static final String COMPLETE = CaseCloseBatchHandler.STATUS_COMPLETE;
  static final String ERROR = CaseCloseBatchHandler.STATUS_ERROR;

  /**
   * @description - Sets up initial test data which is re-used in multiple tests
   */
  @TestSetup
  static void makeData() {
    // Create basic test data
    List<Case> caseRecords;
    caseRecords = CaseTestDataFactory.createCaseRecords(100, 'Closed');

    // Make sure test data included required fields (in case Trigger does not fire)
    for (Case caseRecord : caseRecords) {
      caseRecord.Closed_By__c = UserInfo.getUserId();
    }

    // Insert test data
    insert caseRecords;
  }

  /**
   * @description - Executes a positive test, making a number of callouts
   *                and checking Case records are correctly updated.
   */
  @IsTest
  static void executePositive() {
    // Get a test records
    List<Case> caseRecords = [
      SELECT Id, Closed_By__c, Integration_Attempts__c
      FROM Case
      WHERE Status = 'Closed'
      LIMIT 100
    ];

    // Make sure we have enough test data
    System.assertEquals(
      100,
      caseRecords.size(),
      'Wrong number of test records'
    );

    // Set mock endpoint and timeout
    String endpoint = 'https://example.com/';
    Integer timeout = 30;

    // Start test
    Test.startTest();

    // Create the mock response
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('TestCaseCalloutSuccess');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    CaseCloseBatchHandler.execute(endpoint, timeout, caseRecords);

    // Stop test
    Test.stopTest();

    // Verify results

    // Get updated Case records
    List<Case> newCaseRecords = [
      SELECT
        Id,
        Secret_Key__c,
        Integration_Status__c,
        Integration_Attempts__c,
        Integration_Error__c
      FROM Case
      WHERE Id IN :caseRecords
    ];

    // Make sure we have enough test data
    System.assertEquals(
      100,
      newCaseRecords.size(),
      'Wrong number of test records'
    );

    // Check each record for expected data
    for (Case caseRecord : newCaseRecords) {
      String secretKey = caseRecord.Secret_Key__c;
      System.assertEquals('abc123', secretKey, 'Incorrect Secret Key');

      String status = caseRecord.Integration_Status__c;
      System.assertEquals(COMPLETE, status, 'Incorrect Status');

      Integer attempts = (Integer) caseRecord.Integration_Attempts__c;
      System.assertEquals(1, attempts, 'Incorrect Attempts');

      String error = caseRecord.Integration_Error__c;
      System.assertEquals(null, error, 'Incorrect Error');
    }
  }

  /**
   * @description - Executes a negative test, making a number of callouts
   *                and checking Case records are correctly updated.
   */
  @IsTest
  static void executeNegative() {
    // Get a test records
    List<Case> caseRecords = [
      SELECT Id, Closed_By__c, Integration_Attempts__c
      FROM Case
      WHERE Status = 'Closed'
      LIMIT 100
    ];

    // Make sure we have enough test data
    System.assertEquals(
      100,
      caseRecords.size(),
      'Wrong number of test records'
    );

    // Set mock endpoint and timeout
    String endpoint = 'https://example.com/';
    Integer timeout = 30;

    // Start test
    Test.startTest();

    // Create the mock response
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('TestCaseCalloutFailure');
    mock.setStatusCode(500);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    CaseCloseBatchHandler.execute(endpoint, timeout, caseRecords);

    // Stop test
    Test.stopTest();

    // Verify results

    // Get updated Case records
    List<Case> newCaseRecords = [
      SELECT
        Id,
        Secret_Key__c,
        Integration_Status__c,
        Integration_Attempts__c,
        Integration_Error__c
      FROM Case
      WHERE Id IN :caseRecords
    ];

    // Make sure we have enough test data
    System.assertEquals(
      100,
      newCaseRecords.size(),
      'Wrong number of test records'
    );

    // Check each record for expected data
    for (Case caseRecord : newCaseRecords) {
      String secretKey = caseRecord.Secret_Key__c;
      System.assertEquals(null, secretKey, 'Incorrect Secret Key');

      String status = caseRecord.Integration_Status__c;
      System.assertEquals(ERROR, status, 'Incorrect Status');

      Integer attempts = (Integer) caseRecord.Integration_Attempts__c;
      System.assertEquals(1, attempts, 'Incorrect Attempts');

      String error = caseRecord.Integration_Error__c;
      System.assertEquals('something went wrong', error, 'Incorrect Error');
    }
  }

  /**
   * @description - Executes a negative test, with no records
   */
  @IsTest
  static void executeNegativeNullEmpty() {
    String exMsg;
    // Start test
    try {
      CaseCloseBatchHandler.execute(null, null, null);
    } catch (Exception ex) {
      exMsg = ex.getMessage();
    }
    // Verify results
    // In this case, we just want to avoid any exceptions
    System.assertEquals(null, exMsg, 'Test threw exception');
  }
}
