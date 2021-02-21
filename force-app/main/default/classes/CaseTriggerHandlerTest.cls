@IsTest
public with sharing class CaseTriggerHandlerTest {
  static final String STATUS_NEW = 'New';
  static final String STATUS_WORKING = 'Working';
  static final String STATUS_CLOSED = CaseTriggerHandler.CLOSED;
  /**
   * @description - Sets up initial test data which is re-used in multiple tests
   */
  @TestSetup
  static void makeData() {
    // Create some test records
    List<Case> caseRecords;
    caseRecords = CaseTestDataFactory.createCaseRecords(200, STATUS_NEW);
    insert caseRecords;
  }

  /**
   * @description - Execute a positive test, where the Closed By
   *                value should get set on all records.
   */
  @IsTest
  static void addClosedByBeforeInsertPositiveTest() {
    // Get current running User Id
    Id userId = UserInfo.getUserId();

    // Create some test records
    List<Case> caseRecords;
    caseRecords = CaseTestDataFactory.createCaseRecords(200, STATUS_CLOSED);

    // Start test
    Test.startTest();

    // Insert records to fire trigger
    insert caseRecords;

    // Stop test
    Test.stopTest();

    // Verify results
    List<Case> newCaseRecords = [
      SELECT Id, Closed_By__c
      FROM CASE
      WHERE Id IN :caseRecords
    ];
    for (Case caseRecord : newCaseRecords) {
      Id closedById = caseRecord.Closed_By__c;
      System.assertEquals(userId, closedById, 'Incorrect Closed By value');
    }
  }

  /**
   * @description - Execute a negative test, where the Closed By
   *                value should NOT get set on any records.
   */
  @IsTest
  static void addClosedByBeforeInsertNegativeTest() {
    // Create some test records
    List<Case> caseRecords;
    caseRecords = CaseTestDataFactory.createCaseRecords(200, STATUS_NEW);

    // Start test
    Test.startTest();

    // Insert records to fire trigger
    insert caseRecords;

    // Stop test
    Test.stopTest();

    // Verify results
    List<Case> newCaseRecords = [
      SELECT Id, Closed_By__c
      FROM CASE
      WHERE Id IN :caseRecords
    ];
    for (Case caseRecord : newCaseRecords) {
      Id closedById = caseRecord.Closed_By__c;
      System.assertEquals(null, closedById, 'Incorrect Closed By value');
    }
  }

  /**
   * @description - Execute a positive test, where the Closed By
   *                value should get set on all records.
   */
  @IsTest
  static void addClosedByBeforeUpdatePositiveTest() {
    // Get current running User Id
    Id userId = UserInfo.getUserId();

    // Get some test records
    List<Case> caseRecords = [
      SELECT Id, Closed_By__c
      FROM Case
      WHERE Status = :STATUS_NEW
      LIMIT 200
    ];

    // Update the Status to 'Closed'
    for (Case caseRecord : caseRecords) {
      caseRecord.Status = STATUS_CLOSED;
    }

    // Start test
    Test.startTest();

    // Update records to fire trigger
    update caseRecords;

    // Stop test
    Test.stopTest();

    // Verify results
    List<Case> newCaseRecords = [
      SELECT Id, Closed_By__c
      FROM CASE
      WHERE Id IN :caseRecords
    ];
    for (Case caseRecord : newCaseRecords) {
      Id closedById = caseRecord.Closed_By__c;
      System.assertEquals(userId, closedById, 'Incorrect Closed By value');
    }
  }

  /**
   * @description - Execute a negative test, where the Closed By
   *                value should NOT get set on any records.
   */
  @IsTest
  static void addClosedByBeforeUpdateNegativeTest() {
    // Get some test records
    List<Case> caseRecords = [
      SELECT Id, Closed_By__c
      FROM Case
      WHERE Status = :STATUS_NEW
      LIMIT 200
    ];

    // Update the Status to WORKING
    for (Case caseRecord : caseRecords) {
      caseRecord.Status = STATUS_WORKING;
    }

    // Start test
    Test.startTest();

    // Update records to fire trigger
    update caseRecords;

    // Stop test
    Test.stopTest();

    // Verify results
    List<Case> newCaseRecords = [
      SELECT Id, Closed_By__c
      FROM CASE
      WHERE Id IN :caseRecords
    ];
    for (Case caseRecord : newCaseRecords) {
      Id closedById = caseRecord.Closed_By__c;
      System.assertEquals(null, closedById, 'Incorrect Closed By value');
    }
  }
}
