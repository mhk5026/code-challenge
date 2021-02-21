/**
 * @description - Handle the business logic for the Case Trigger
 */
public with sharing class CaseTriggerHandler {
  // Constants
  public static final String CLOSED = 'Closed';

  /**
   * @description - Handles the Before Insert triggers
   *
   * @param newList - List of newly inserted Case records
   */
  public static void beforeInsert(List<Case> newList) {
    System.debug('Executing Before Insert');
    addClosedBy(newList);
  }

  /**
   * @description - Handles the Before Update triggers
   *
   * @param oldMap - Map of Case records before the update
   * @param newMap - Map of Case records after the update
   */
  public static void beforeUpdate(Map<Id, Case> oldMap, Map<Id, Case> newMap) {
    System.debug('Before Update');
    addClosedBy(oldMap, newMap);
  }

  /**
   * @description - Adds the current running user to the Closed By
   *                field of the Case record if the Status is equal
   *                to "Closed". This only works on a Before trigger.
   *
   * @param newList - List of newly inserted Case records
   */
  static void addClosedBy(List<Case> newList) {
    for (Case caseRecord : newList) {
      if (caseRecord.Status == CLOSED) {
        System.debug('Add Closed By: ' + UserInfo.getUserId());
        // Add the current running user Id to the Closed By field
        caseRecord.Closed_By__c = UserInfo.getUserId();
      }
    }
  }

  /**
   * @description - Adds the current running user to the Closed By
   *                field of the Case record if the Status is changed
   *                to "Closed". This only works on a Before trigger.
   *
   * @param oldMap - Map of Case records before the update
   * @param newMap - Map of Case records after the update
   */
  static void addClosedBy(Map<Id, Case> oldMap, Map<Id, Case> newMap) {
    // Iterate over each Case record
    for (Id caseId : newMap.keySet()) {
      Case newCase = newMap.get(caseId);
      Case oldCase = oldMap.get(caseId);
      // Check to see if the Status has changed and is now "Closed"
      if (oldCase.Status != CLOSED && newCase.Status == CLOSED) {
        System.debug('Add Closed By: ' + UserInfo.getUserId());
        // Add the current running user Id to the Closed By field
        newCase.Closed_By__c = UserInfo.getUserId();
      }
    }
  }
}
