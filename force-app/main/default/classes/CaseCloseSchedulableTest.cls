@isTest
private class CaseCloseSchedulableTest {
  // Dummy CRON expression
  static final String CRON_EXP = '0 0 * * * ?';
  /**
   * @description - Sets up initial test data which is re-used in multiple tests
   */
  @TestSetup
  static void makeData() {
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
   * @description - Tests the Schedulable class with the job being 'enabled'
   *                in the Custom Settings. Expect a Batch Job to be queued.
   */
  @IsTest
  static void testScheduledJobEnabled() {
    // Start test
    Test.startTest();

    // Schedule the job
    String jobId = System.schedule(
      'CaseCloseSchedulableTest',
      CRON_EXP,
      new CaseCloseSchedulable()
    );

    // Stop test
    Test.stopTest();

    // Verify results

    // Get the Apex Class for the Batch Job
    List<ApexClass> apexClass = [
      SELECT Id
      FROM ApexClass
      WHERE Name = :CaseCloseBatch.class.getName()
      LIMIT 1
    ];

    // Check if there are any queued job for the Apex Class
    Integer enqueuedJobs = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE
        JobType = 'BatchApex'
        AND Status IN ('Processing', 'Preparing', 'Queued')
        AND ApexClassId = :apexClass
    ];

    System.assertEquals(1, enqueuedJobs, 'Incorrect number of enqueuedJobs');
  }

  /**
   * @description - Tests the Schedulable class with the job being 'enabled'
   *                in the Custom Settings. Expect a Batch Job to be queued.
   */
  @IsTest
  static void testScheduledJobDisabled() {
    // Disable the job, so that no batches get executed
    Workforce_Management_Platform_Settings__c settings;
    settings = [
      SELECT Id, Enabled__c
      FROM Workforce_Management_Platform_Settings__c
      LIMIT 1
    ];
    settings.Enabled__c = false;
    update settings;

    // Start test
    Test.startTest();

    // Schedule the job
    String jobId = System.schedule(
      'CaseCloseSchedulableTest',
      CRON_EXP,
      new CaseCloseSchedulable()
    );

    // Stop test
    Test.stopTest();

    // Verify results

    // Get the Apex Class for the Batch Job
    List<ApexClass> apexClass = [
      SELECT Id
      FROM ApexClass
      WHERE Name = :CaseCloseBatch.class.getName()
      LIMIT 1
    ];

    // Check if there are any queued job for the Apex Class
    Integer enqueuedJobs = [
      SELECT COUNT()
      FROM AsyncApexJob
      WHERE
        JobType = 'BatchApex'
        AND Status IN ('Processing', 'Preparing', 'Queued')
        AND ApexClassId = :apexClass
    ];

    System.assertEquals(0, enqueuedJobs, 'Incorrect number of enqueuedJobs');
  }
}
