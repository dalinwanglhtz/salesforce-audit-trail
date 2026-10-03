public with sharing class AuditSnapshotQueueable implements Queueable {
    private List<Audit_Snapshot__c> snapshots;
    private AuditSnapshotService service;

    public AuditSnapshotQueueable (List<Audit_Snapshot__c> snapshots) {
        this(snapshots, new AuditSnapshotService());
    }

    public AuditSnapshotQueueable (List<Audit_Snapshot__c> snapshots, AuditSnapshotService service) {
        this.snapshots = snapshots;
        this.service = service;
    }

    public void execute(QueueableContext context) {
        service.insertSnapshots(snapshots);
    }
}