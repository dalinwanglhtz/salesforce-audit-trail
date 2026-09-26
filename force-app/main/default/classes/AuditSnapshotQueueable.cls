public class AuditSnapshotQueueable implements Queueable {
    private List<Audit_Snapshot__c> snapshots;

    public AuditSnapshotQueueable (List<Audit_Snapshot__c> snapshots) {
        this.snapshots = snapshots;
    }

    public void execute(QueueableContext context) {
        insert snapshots;
    }
}