@IsTest
public with sharing class CaseCloseBatchTest {
  static final String STATUS_PROCESSING = CaseCloseBatch.STATUS_PROCESSING;
  static final String STATUS_COMPLETE = CaseCloseBatch.STATUS_COMPLETE;
  static final String STATUS_ERROR = CaseCloseBatch.STATUS_ERROR;

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

    // Create Custom Setting record
    Workforce_Management_Platform_Settings__c settings = new Workforce_Management_Platform_Settings__c();
    settings.Enabled__c = true;
    settings.Endpoint__c = 'https://example.com';
    settings.Max_Attempts__c = 3;
    settings.Max_Records__c = 100;
    settings.Batch_Size__c = 10;
    settings.Notification_Email__c = 'test@test.invalid';
    settings.Timeout__c = 30;
    insert settings;
  }

  /**
   * @description - Executes a positive test, making sure the batch query
   *                selected the correct records. Does not test execution
   *                results as they're based on a callout, which cannot be
   *                tested in this class.
   */
  @IsTest
  static void executeBatchTest() {
    Integer maxRecords = 100;
    Integer batchSize = 100;
    Integer maxAttempts = 3;

    // Start test
    Test.startTest();

    // Execute Batch Job
    CaseCloseBatch job = new CaseCloseBatch(maxRecords, maxAttempts);
    Id jobId = Database.executeBatch(job, batchSize);

    // Stop test
    Test.stopTest();

    // Verify results
    // Get updated Case records
    List<Case> newCaseRecords = [
      SELECT
        Id,
        Integration_Job_Id__c,
        Integration_Status__c,
        Integration_Attempts__c
      FROM Case
      WHERE Integration_Status__c != NULL
    ];

    // Make sure we have enough test data
    System.assertEquals(
      100,
      newCaseRecords.size(),
      'WRong number of test records'
    );

    // Check each record for expected data
    for (Case caseRecord : newCaseRecords) {
      String caseJobId = caseRecord.Integration_Job_Id__c;
      System.assertEquals(jobId, caseJobId, 'Incorrect Job Id');

      String status = caseRecord.Integration_Status__c;
      System.assertEquals(STATUS_PROCESSING, status, 'Incorrect Status');
    }
  }

  /**
   * @description - Executes a positive test, to make sure the email
   *                notification method is working.
   */
  @IsTest
  static void sendMaxAttemptsNotificationTest() {
    Id jobId = '7079D00000KuCCVQA3';
    String email = 'test@test.invalid';
    List<Case> caseRecords = [
      SELECT
        Id,
        Integration_Job_Id__c,
        Integration_Status__c,
        Integration_Attempts__c
      FROM Case
      LIMIT 100
    ];

    // Start test
    Test.startTest();

    // Execute method
    CaseCloseBatch.sendMaxAttemptsNotification(jobId, email, caseRecords);

    // Get the number of emails sent in this transaction
    Integer emailInvocations = Limits.getEmailInvocations();

    // Stop test
    Test.stopTest();

    // Verify results
    System.assertEquals(1, emailInvocations, 'Incorrect number of emails sent');
  }
}
