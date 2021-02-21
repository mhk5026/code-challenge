/**
 * @description - Schedule the Batch Job to process closed Case records.
 */
global class CaseCloseSchedulable implements Schedulable {
  /**
   * @description - Implements the execute method of the Schedulable interface.
   *                This then starts the desired Batch Job to process the
   *                closed Case records.
   *
   * @param context - Context for the Scheduled Job, contains the Job Id
   */
  global void execute(SchedulableContext context) {
    // Get the Batch Job settings for the Workforce Management Platform
    Workforce_Management_Platform_Settings__c settings;
    settings = Workforce_Management_Platform_Settings__c.getOrgDefaults();
    Boolean enabled = settings.Enabled__c;
    Integer maxRecords = (Integer) settings.Max_Records__c;
    Integer batchSize = (Integer) settings.Batch_Size__c;
    Integer maxAttempts = (Integer) settings.Max_Attempts__c;

    // Check the Batch Job settings to see if it's enabled or disabled
    if (enabled == false) {
      System.debug(LoggingLevel.WARN, 'Job has been disabled');
      return;
    }

    // Create a new Batch Job
    CaseCloseBatch job = new CaseCloseBatch(maxRecords, maxAttempts);
    Id jobId = Database.executeBatch(job, batchSize);
    System.debug('Job Id: ' + jobId);
  }
}
