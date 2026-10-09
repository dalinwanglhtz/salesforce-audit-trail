@isTest
private class AuditTrailSelectorTest {

    @isTest
    static void testGetSnapshots() {
        Audit_Snapshot__c snapshot = new Audit_Snapshot__c(
            Record_Id__c = '001000000000001AAA',
            Object_API_Name__c = 'Account',
            Action__c = 'Update',
            Changed_Fields_JSON__c = '[]'
        );
        insert snapshot;

        AuditTrailSelector selector = new AuditTrailSelector();

        Test.startTest();
        List<Audit_Snapshot__c> results = selector.getSnapshots('001000000000001AAA');
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Expected 1 snapshot record to be returned by selector');
        Assert.areEqual(snapshot.Id, results[0].Id);
    }

    @isTest
    static void testGetActiveSettings() {
        AuditTrailSelector selector = new AuditTrailSelector();

        Test.startTest();
        Map<String, Audit_Setting__mdt> settingsMap = selector.getActiveSettings();
        Test.stopTest();

        Assert.isNotNull(settingsMap, 'Expected settings map to be returned (can be empty if no active metadata exists).');
    }
}