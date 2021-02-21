/**
 * @description - Test Data Factory for Case records
 */
@IsTest
public with sharing class CaseTestDataFactory {
  /**
   * @description - Creates the number of Case records with the specified Status,
   *                and returns a list, ready to be inserted into the Database.
   *
   * @param count - Number of Case records to create
   * @param status - Status of Case the records
   *
   * @return - A List of Case records, ready to be inserted into the Database
   */
  public static List<Case> createCaseRecords(Integer count, String status) {
    List<Case> caseRecords = new List<Case>();
    for (Integer i = 0; i < count; i++) {
      Case caseRecord = new Case();
      caseRecord.Subject = 'Test Case ' + i;
      caseRecord.Status = status;
      caseRecords.add(caseRecord);
    }
    System.assertEquals(count, caseRecords.size(), 'Incorrect record  count');
    return caseRecords;
  }
}
