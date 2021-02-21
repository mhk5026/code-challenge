/**
 * @description - Batch Job to process closed Case records.
 */
public with sharing class CaseCloseBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
  // Constants
  public static final String CASE_STATUS_CLOSED = 'Closed';
  public static final String STATUS_PROCESSING = 'Processing';
  public static final String STATUS_COMPLETE = 'Complete';
  public static final String STATUS_ERROR = 'Error';
  @TestVisible
  static final String NOTIFICATION_EMAIL_SUBJECT = 'Case Close Integration Max Attempts Reached';
  @TestVisible
  static final String NOTIFICATION_EMAIL_BODY = 'These records have reached their Max Attempts limit:\n';

  Integer batchesProcessed = 0;
  Integer recordsProcessed = 0;
  Integer maxRecords;
  Integer maxAttempts;
  String endpoint;
  Integer timeout;
  String notificationEmail;

  public CaseCloseBatch(Integer maxRecords, Integer maxAttempts) {
    this.maxRecords = maxRecords;
    this.maxAttempts = maxAttempts;
  }

  /**
   * @description - Implements the start method of the Database.BatchableContext interface.
   *                This is executed when the Batch Job is started.
   *
   * @param bc - Context for the Batch Job, contains the Job Id
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    System.debug('Starting batch job');
    Id jobId = bc.getJobId();

    // Get the API endpoint settings for the Workforce Management Platform
    Workforce_Management_Platform_Settings__c settings;
    settings = Workforce_Management_Platform_Settings__c.getOrgDefaults();
    this.timeout = (Integer) settings.Timeout__c;
    this.endpoint = settings.Endpoint__c;
    this.notificationEmail = settings.Notification_Email__c;

    // Define query to get records for batch jobs
    String q = 'SELECT Id, Closed_By__c, Integration_Attempts__c';
    q += ' FROM Case';
    q += ' WHERE Status = \'' + CASE_STATUS_CLOSED + '\'';
    q += ' AND Secret_Key__c = NULL';
    q += ' AND Integration_Status__c != \'' + STATUS_COMPLETE + '\'';
    q += ' AND (Integration_Status__c != \'' + STATUS_PROCESSING + '\'';
    q += ' OR Integration_Job_Id__c = \'' + jobId + '\')';
    q += ' AND Integration_Attempts__c < ' + this.maxAttempts;
    q += ' ORDER BY ClosedDate ASC';
    q += ' LIMIT ' + this.maxRecords;

    System.debug(q);

    // Update case records with Integration Status
    // This will avoid overlapping jobs if running concurrently
    List<Case> caseRecords = Database.query(q);
    for (Case caseRecord : caseRecords) {
      caseRecord.Integration_Job_Id__c = jobId;
      caseRecord.Integration_Status__c = STATUS_PROCESSING;
    }

    // Update records in Database
    update caseRecords;

    // Return QueryLocator for batch job
    return Database.getQueryLocator(q);
  }

  /**
   * @description - Implements the start method of the Database.BatchableContext interface.
   *                This is executed on each iteration of the Batch Job.
   *
   * @param bc - Context for the Batch Job, contains the Job Id
   * @param caseRecords - List of records to be processed in this batch
   */
  public void execute(Database.BatchableContext bc, List<Case> caseRecords) {
    // Increment batches and records processed counter
    this.batchesProcessed++;
    this.recordsProcessed = this.recordsProcessed + caseRecords.size();
    System.debug('Executing batch number ' + this.batchesProcessed);

    // Execute the business logic and API callout for these Case records
    // This will update records in the Database
    if (!Test.isRunningTest()) {
      // Only call if not running test, since contains callouts
      CaseCloseBatchHandler.execute(this.endpoint, this.timeout, caseRecords);
    }
  }

  /**
   * @description - Implements the finish method of the Database.BatchableContext interface.
   *                This is executed when the Batch Job is completed.
   *
   * @param bc - Context for the Batch Job, contains the Job Id
   */
  public void finish(Database.BatchableContext bc) {
    Id jobId = bc.getJobId();

    // Get all Case record from this Batch Job which have now reached their maximum attempts
    List<Case> caseRecords = [
      SELECT Id
      FROM Case
      WHERE
        Integration_Job_Id__c = :jobId
        AND Integration_Attempts__c >= :this.maxAttempts
    ];

    // If there are any records which reached their maximum attempts
    // Send an email to the email address configured in the settings
    if (!caseRecords.isEmpty()) {
      sendMaxAttemptsNotification(jobId, this.notificationEmail, caseRecords);
    }

    System.debug('Completed Job Id: ' + jobId);
  }

  @TestVisible
  static void sendMaxAttemptsNotification(
    Id jobId,
    String email,
    List<Case> caseRecords
  ) {
    // Get Case Record Ids from List of Cases
    List<Id> caseRecordIds = new List<Id>();
    for (Case caseRecord : caseRecords) {
      caseRecordIds.add(caseRecord.Id);
    }
    String serializedIds = JSON.serializePretty(caseRecordIds);

    // Prepare and send email
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String[] toAddresses = new List<String>{ email };
    mail.setToAddresses(toAddresses);
    mail.setSubject(NOTIFICATION_EMAIL_SUBJECT + '- Job Id: ' + jobId);
    mail.setPlainTextBody(NOTIFICATION_EMAIL_BODY + serializedIds);
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
  }
}
