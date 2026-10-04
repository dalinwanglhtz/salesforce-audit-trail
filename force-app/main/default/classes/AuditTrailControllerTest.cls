@isTest
private class AuditTrailControllerTest {

    private class SelectorMock implements System.StubProvider {
        public Boolean getSnapshotsCalled = false;
        public List<Audit_Snapshot__c> mockRetuurnSnapshots = new List<Audit_Snapshot__c>();

        public Object handleMethodCall (
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (stubbedMethodName == 'getSnapshots') {
                getSnapshotsCalled = true;
                return mockRetuurnSnapshots;
            }
            return null;
        }
    }

    @isTest
    static void testGetRecordSnapshotsNullId() {
        Test.startTest();
        List<AuditTrailController.SnapshotWrapper> results = AuditTrailController.getRecordSnapshots(null);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Expected empty list for null recordId');
    }

    @isTest
    static void testGetRecordSnapshotsWithMockData() {
        String jsonRecord = '{"attributes":{"type":"Audit_Snapshot__c"},' +
            '"Id":"a01000000000001AAA",' +
            '"Object_API_Name__c":"Account",' +
            '"Action__c":"Update",' +
            '"Changed_Fields_JSON__c":"[{\\"fieldName\\":\\"Name\\",\\"oldValue\\":\\"Old Account\\",\\"newValue\\":\\"New Account\\"}]",' +
            '"Modified_By__r":{"Name":"Test User"}}';
        
        Audit_Snapshot__c mockSnapshot = (Audit_Snapshot__c) JSON.deserialize(jsonRecord, Audit_Snapshot__c.class);

        SelectorMock mockProvider = new SelectorMock();
        mockProvider.mockRetuurnSnapshots = new List<Audit_Snapshot__c> {mockSnapshot};
        AuditTrailSelector mockSelector = (AuditTrailSelector) Test.createStub(
            AuditTrailSelector.class, 
            mockProvider
        );
        AuditTrailController.selector = mockSelector;

        Test.startTest();
        List<AuditTrailController.SnapshotWrapper> results = AuditTrailController.getRecordSnapshots('a01000000000001AAA');
        Test.stopTest();

        Assert.isTrue(mockProvider.getSnapshotsCalled, 'Expected getSnapshots to be called on mock selector');
        Assert.areEqual(1, results.size(), 'Expect 1 wrapper returned');
        Assert.areEqual('Update', results[0].action);
        Assert.areEqual('Test User', results[0].modifiedBy);
        Assert.areEqual(1, results[0].changes.size());
        Assert.areEqual('Account Name', results[0].changes[0].fieldLabel);
    }
}