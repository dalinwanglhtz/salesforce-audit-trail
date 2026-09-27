public class AuditTrailHandler implements TriggerHandler {
    public AuditTrailHelper helper;

    public AuditTrailHandler () {
        helper = new AuditTrailHelper();
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