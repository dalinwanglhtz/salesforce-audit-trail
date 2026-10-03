/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AuditSnapshotQueueableTest {

    private class AuditServiceMock implements System.StubProvider {
        public Boolean insertSnapshotsCalled = false;
        public List<Audit_Snapshot__c> capturedSnapshots = new List<Audit_Snapshot__c>();

        public Object handleMethodCall (
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (stubbedMethodName == 'insertSnapshots') {
                this.insertSnapshotsCalled = true;
                this.capturedSnapshots = (List<Audit_Snapshot__c>) listOfArgs[0];
            }
            return null;
        }
    }

    @isTest
    static void testQueueableExecutionWithMock() {
        List<Audit_Snapshot__c> mockSnapshots = new List<Audit_Snapshot__c> {
            new Audit_Snapshot__c(Action__c = 'Update')
        };

        AuditServiceMock mockProvider = new AuditServiceMock();
        AuditSnapshotService mockService = (AuditSnapshotService) Test.createStub(
            AuditSnapshotService.class, 
            mockProvider
        );

        AuditSnapshotQueueable queueable = new AuditSnapshotQueueable(mockSnapshots, mockService);

        queueable.execute(null);

        Assert.isTrue(mockProvider.insertSnapshotsCalled, 'Expected insertSnapshots to be called.');
        Assert.areEqual(1, mockProvider.capturedSnapshots.size(), 'Expected 1 snapshot record passed to service');
    }
}