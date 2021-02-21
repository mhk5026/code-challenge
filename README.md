# Developer Code Challenge

## Requirement

A Case has been updated to be closed. When a Case is closed, the Workforce Planning team need to be notified to ensure they are correctly tracking Case closures and new work assignments. This is currently handled by an API call to the Workforce Management Platform. The environment is a relatively high volume environment with roughly 200 Case closures per minute. The API recently has had some performance issues and every now and again it times out. It’s not necessary for the API to be called immediately after the case is closed, as long as the Workforce Management Platform is notified within the day. The case should be updated with the secretKey returned from the API.

### API Specification

**Method:** POST

**Request Body:**

```json
{
  "id": "the case id",
  "agentid": "the id of the agent that performed the closure"
}
```

**Error Response:**
500

```json
{ "success": false, "error": "error message" }
```

**Success Response:**
200

```json
{ "success": true, "secretKey": "secret key" }
```

## Solution Notes

A critical limitation of this requirement is that the API endpoint does not support multiple records in a single HTTP callout. This means a significant number of API callouts are required, one for every Case record closed. Due to this, the solution cannot be fully bulkified causing the code execution time to be increased, Salesforce Governor limits could easily be hit, and all records may not be processed in a timely manner. The strong recommendation that the API endpoint allow bulk updates in a single POST request. This solution can be easily refactored to do this which would significantly improve overall performance.

A Batch Job was determined to be the best solution as it gives a robust way to control, execute, and monitor large volumes of callouts. Making individual callouts with a @future request from the Apex trigger would only be able to handle 50 records as at a time and would fail on bulk updates. Trying to batch the @future request to bulkify this approach would be messy. The Queueable feature is another possibility but does not have the in-built batch control as Batch Jobs, although one possible solution would be to continuously chain Queueables indefinitely which would be relatively simple to implement, but still does not have the same level of control as a Batch Job.

Initial performance testing of the below solution managed to process around 1000 records in per minute while executing 5 concurrent Batch Jobs. This is sufficient for the volume of Case closures in the requirement.

## Solution Design

Whenever a Case Status is changed to Closed (or a new record is inserted with Status as Closed), a Before trigger will add the user Id to the new Custom field, Closed By. This will then be used to send to the Workforce Management Platform later.

A scheduled Batch Job executes (e.g., every hour) to get all Case records which have been closed. It excludes any Case records which have already been processed (Integration Status = “Complete”) or are being processed by another running batch job (Integration Status = “Processing” and Integration Job Id is for a different job). The query picks up the maximum number of Case records defined in the Custom Settings (Max Records). This Batch Job then executes batches with the maximum number of records defined in the Custom Settings (Batch Size). The Batch Jobs can be turned on/off using a Custom Settting (Enabled) to easily control these jobs.

Here, the current solution attempts to bulkify as much as possible, by making up to 100 (Batch Size) callouts per transaction (100 is the governor limit for callouts). But due to the time it takes to make this many callouts, we might end up processing less records than are being Closed, or hit Apex execution time/timeout Governor Limits. To overcome this, we can schedule concurrent jobs (e.g., every 15 minutes).

A successful HTTP callout will result in the Case record being updated with the Secret Key returned from the Workforce Management Platform API, and any errors will update the Case record with the specific error message (Integration Error) and the number of times the specific record has been attempted (Integration Attempts).

Every time the batch job is executed, it will retry failed records up to the maximum number of times defined in the settings (Max Attempts). Ultimately, some records may fail too many times and at the end of a batch run, if any are found, a notification will be sent to the defined email in the settings (Notification Email). Records are processed in order of Closed Date/Time, so it will retry failed records in the next Batch Job execution.

A Permission Set has been created to assign access to the required Objects, Fields, Custom Settings, and Apex classes.
