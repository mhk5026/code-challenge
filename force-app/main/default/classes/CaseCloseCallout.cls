/**
 * @description - Used to make callout to HTTP API endpoint and parse the response
 */
public with sharing class CaseCloseCallout {
  /**
   * @description - Class used to thow custom Exceptions
   */
  public class CalloutException extends Exception {
  }

  /**
   * @description - Data model for the HTTP request
   */
  @TestVisible
  class Request {
    public Id id;
    public Id agentid;
  }

  /**
   * @description - Data model for the HTTP response
   */
  @TestVisible
  class Response {
    public Boolean success;
    public String error;
    public String secretKey;
  }

  /**
   * @description - Creates a Request object with the paramters
   *
   * @param caseId- Id of the Case record. Will be sent to the API endpoint
   * @param userId- Id of the User who closed the Case. Will be sent to the API endpoint
   *
   * @return - A Request object ready to be deserialized and sent to the API Endpoint
   */
  @TestVisible
  static Request createRequest(Id caseId, Id userId) {
    Request requestObject = new Request();
    requestObject.id = caseId;
    requestObject.agentid = userId;
    return requestObject;
  }

  /**
   * @description - Processes the HTTP response and creates a Response objecct
   *
   * @param res - The HttpResponse to be process
   *
   * @return - API response deserialised into Response object
   */
  @TestVisible
  static Response processResponse(HttpResponse res) {
    Response responseObject;
    responseObject = (Response) JSON.deserialize(res.getBody(), Response.class);
    if (res.getStatusCode() != 200 || responseObject.success == false) {
      throw new CalloutException(responseObject.error);
    }
    return responseObject;
  }

  /**
   * @description - Make a callout to the Workforce Management Platform API to get the Secret Key.
   *                String will be returned on a successful callout. An Error will be thrown upon
   *                any failed callout.
   *
   * @param endpoint- URL of the API Endpoint to make HTTP callout to
   * @param timeout- Timeout in seconds for the HTTP callout
   * @param caseId- Id of the Case record. Will be sent to the API endpoint
   * @param userId- Id of the User who closed the Case. Will be sent to the API endpoint
   *
   * @return - Secret Key returned from API callout.
   */
  public static String makeCallout(
    String endpoint,
    Integer timeout,
    Id caseId,
    Id userId
  ) {
    // Serialize the request as JSON format
    Request requestObject = createRequest(caseId, userId);
    String body = JSON.serializePretty(requestObject);

    // Prepare the callout request
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('POST');
    req.setTimeout(timeout * 1000);
    req.setHeader('content-type', 'application/json');
    req.setBody(body);
    System.debug('--- Request Body ---');
    System.debug(req.getBody());

    // Make the callout
    HttpResponse res = http.send(req);
    System.debug('--- Response Body ---');
    System.debug(res.getBody());
    Response responseObject = processResponse(res);

    // Return Secret Key from API response
    return responseObject.secretKey;
  }
}
