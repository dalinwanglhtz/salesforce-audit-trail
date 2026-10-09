public class AuditTrailHandler implements TriggerHandler {
    @TestVisible
    private AuditTrailHelper helper;

    public AuditTrailHandler () {
        this(new AuditTrailHelper());
    }

    public AuditTrailHandler(AuditTrailHelper helper) {
        this.helper = helper;
    }

    public void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        helper.createSnapshots(newRecords, oldMap);
    }

    public void afterInsert(List<SObject> newRecords, Map<ID, SObject> newRecordMap) {
        // Optional
    }
    public void afterDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap) {
        // Optional
    }
}