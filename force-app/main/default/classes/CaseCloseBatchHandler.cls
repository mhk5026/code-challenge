/**
 * @description - Processes the business logic for closed Cases
 */
public with sharing class CaseCloseBatchHandler {
  // Constants
  public static final String STATUS_COMPLETE = 'Complete';
  public static final String STATUS_PROCESSING = 'Processing';
  public static final String STATUS_ERROR = 'Error';

  /**
   * @description - Executes the business logic and makes HTTP callout to
   *                the Workforce Management Platform for closed Case records.
   *
   * @param endpoint - The URL of the API endpoint used to make callouts to the Workforce Management Platform
   * @param timeout - The timeout in seconds for each API callout request
   * @param caseRecords - The records to be processed
   */
  public static void execute(
    String endpoint,
    Integer timeout,
    List<Case> caseRecords
  ) {
    // Make sure we have records to process, otherwise for loop or DML will fail
    if (caseRecords == null || caseRecords.isEmpty()) {
      System.debug('No Case records to be processed.');
      return;
    }

    System.debug('No. Cases:' + caseRecords.size());

    // Iterate over each Case record and execute business logic
    for (Case caseRecord : caseRecords) {
      try {
        // Get the current number of integration attempts for this record
        Integer attempts = (Integer) caseRecord.Integration_Attempts__c;

        // If value is blank/null, will become 0
        attempts = (attempts == null ? 0 : attempts);

        // Increment this number of attempts for this record
        caseRecord.Integration_Attempts__c = attempts + 1;

        // Prepare the data for the callout request
        Id caseId = caseRecord.Id;
        Id userId = caseRecord.Closed_By__c;

        // Get the Secret Key by making a callout to the Workforce Management Platform
        String secretKey = CaseCloseCallout.makeCallout(
          endpoint,
          timeout,
          caseId,
          userId
        );

        // Update this Case record with the Secret Key and Integration Status
        caseRecord.Secret_Key__c = secretKey;
        caseRecord.Integration_Status__c = STATUS_COMPLETE;
        caseRecord.Integration_Error__c = '';
      } catch (Exception e) {
        // Catch all exceptions to allow job to continue and update Case records
        System.debug(LoggingLevel.WARN, 'Exception: ' + e.getMessage());

        // Update the this Case record with the Integration Error details
        caseRecord.Integration_Status__c = STATUS_ERROR;
        caseRecord.Integration_Error__c = e.getMessage();
      }
    }

    // Once all records have been processed, update all of the Case records in the Database
    // This will include both successful and unsucccessful records.
    update caseRecords;
  }
}
