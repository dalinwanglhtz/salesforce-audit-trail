public interface TriggerHandler {
    void afterInsert(List<SObject> newRecords, Map<ID, SObject> newRecordMap);
    void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldMap, Map<Id, SObject> oldRecordMap, Map<ID, SObject> newRecordMap);
    void afterDelete(List<SObject> oldRecords, Map<ID, SObject> oldRecordMap);
}