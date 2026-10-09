@isTest
private class AuditTrailHandlerTest {

    private class AuditHelperMock implements System.StubProvider {
        public Boolean createSnapshotsCalled = false;
        public List<SObject> capturedNewRecords;
        public Map<Id, SObject> capturedOldMap;

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (stubbedMethodName == 'createSnapshots') {
                this.createSnapshotsCalled = true;
                this.capturedNewRecords = (List<SObject>) listOfArgs[0];
                this.capturedOldMap = (Map<Id, SObject>) listOfArgs[1];
            }
            return null;
        }
    }

    @isTest
    static void testAfterUpdateDelegatesToHelper() {
        AuditHelperMock mockProvider = new AuditHelperMock();

        AuditTrailHelper mockHelper = (AuditTrailHelper) Test.createStub(
            AuditTrailHelper.class, 
            mockProvider
        );

        AuditTrailHandler handler = new AuditTrailHandler(mockHelper);

        Account oldAcc = new Account(Id = '001000000000001AAA', Name = 'Old Name');
        Account newAcc = new Account(Id = '001000000000001AAA', Name = 'New Name');

        List<SObject> newRecords = new List<SObject>{ newAcc };
        Map<Id, SObject> oldMap = new Map<Id,SObject>{ oldAcc.Id => oldAcc };

        Test.startTest();
        handler.afterUpdate(null, newRecords, oldMap, null);
        Test.stopTest();

        Assert.isTrue(mockProvider.createSnapshotsCalled, 'Expected createSnapshots to be called on helper');
        Assert.areEqual(1, mockProvider.capturedNewRecords.size(), 'Expected 1 record in newRecords.');
        Assert.areEqual('New Name', ((Account) mockProvider.capturedNewRecords[0]).Name);
        Assert.isTrue(mockProvider.capturedOldMap.containsKey(oldAcc.Id), 'Expected oldMap to contain old account ID.');
    }

    @isTest
    static void testOptionalHandlerMethod() {
        AuditTrailHandler handler = new AuditTrailHandler();

        Test.startTest();
        handler.afterInsert(null, null);
        handler.afterDelete(null, null);
        Test.stopTest();

        Assert.isNotNull(handler.helper, 'Expected default helper instance to be initialised.');
    }
}