@isTest
private class AuditTrailHelperTest {

    private class AuditTrailSelectorMock implements System.StubProvider {
        public Map<String, Audit_Setting__mdt> mockSettings = new Map<String, Audit_Setting__mdt>();

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (stubbedMethodName == 'getActiveSettings') {
                return mockSettings;
            }

            return null;
        }
    }

    @isTest
    static void testCreateSnapshotsNoSetting() {
        AuditTrailSelectorMock mockProvider = new AuditTrailSelectorMock();
        AuditTrailSelector mockSelector = (AuditTrailSelector) Test.createStub(
            AuditTrailSelector.class, 
            mockProvider
        );
        AuditTrailHelper.selector = mockSelector;

        Account oldAcc = new Account(Id = '001000000000001AAA', Name = 'Old Name');
        Account newAcc = new Account(Id = '001000000000001AAA', Name = 'New Name');

        Test.startTest();
        AuditTrailHelper helper = new AuditTrailHelper();
        helper.createSnapshots(
            new List<SObject> { newAcc },
            new Map<Id, SObject> { oldAcc.Id => oldAcc }
        );
        Test.stopTest();

        Assert.areEqual(0, Limits.getQueueableJobs(), 'Expected no Queueable job to be enqueued when setting is missing.');
    }

    @isTest
    static void testCreateSnapshotsFieldChange() {
        String settingJson = '{"attributes":{"type":"Audit_Setting__mdt"},' +
            '"Object_API_Name__c":"Account",' +
            '"Tracked_Fields__c":"Name",' +
            '"Is_Active__c":true}';
        
        Audit_Setting__mdt mockSetting = (Audit_Setting__mdt) JSON.deserialize(settingJson, Audit_Setting__mdt.class);
        AuditTrailSelectorMock mockProvider = new AuditTrailSelectorMock();
        mockProvider.mockSettings.put('Account', mockSetting);

        AuditTrailHelper.selector = (AuditTrailSelector) Test.createStub(
            AuditTrailSelector.class,
            mockProvider
        );

        Account oldAcc = new Account(Id = '001000000000001AAA', Name = 'Old Name');
        Account newAcc = new Account(Id = '001000000000001AAA', Name = 'New Name');

        Test.startTest();
        AuditTrailHelper helper = new AuditTrailHelper();
        helper.createSnapshots(
            new List<SObject> { newAcc },
            new Map<Id, SObject> { oldAcc.Id => oldAcc }
        );

        Assert.areEqual(1, Limits.getQueueableJobs(), 'Expected 1 Queueable job to be enqueued.');
        Test.stopTest();
    }
}