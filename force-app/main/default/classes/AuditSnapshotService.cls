public with sharing virtual class AuditSnapshotService {
    public virtual void insertSnapshots(List<Audit_Snapshot__c> snapshots) {
        if (snapshots != null && !snapshots.isEmpty()) {
            insert snapshots;
        }
    }
}