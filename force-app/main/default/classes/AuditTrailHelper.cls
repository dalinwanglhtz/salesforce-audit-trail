public with sharing class AuditTrailHelper {
    public AuditTrailHelper() {}

    public void createSnapshots(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Audit_Snapshot__c> snapshots = new List<Audit_Snapshot__c>();
        List<Audit_Setting__mdt> settings = [
            SELECT Object_API_Name__c, Tracked_Fields__c 
            FROM Audit_Setting__mdt
            WHERE Is_Active__c = true
        ];
        for (SObject newRecord : newRecords) {
            SObject oldRecord = oldMap.get(newRecord.Id);
            for (Audit_Setting__mdt setting : settings) {
                if (setting.Object_API_Name__c == newRecord.getSObjectType().getDescribe().getName()) {
                    List<String> trackedFields = setting.Tracked_Fields__c != null ? setting.Tracked_Fields__c.split(',') : null;
                    List<FieldWrapper> fwList = new List<FieldWrapper>();
                    if (trackedFields != null) {
                        for (String field : trackedFields) {
                            field = field.trim();
                            Object oldValue = oldRecord.get(field);
                            Object newValue = newRecord.get(field);
                            if (oldValue != newValue && (oldValue == null || !oldValue.equals(newValue))) {
                                FieldWrapper fw = buildFieldWrapper((String) oldValue, (String) newValue, field);
                                fwList.add(fw);
                            }
                        }
                    }
                    snapshots.add(new Audit_Snapshot__c(
                            Record_Id__c = (Id) newRecord.get('Id'),
                            Object_API_Name__c = newRecord.getSObjectType().getDescribe().getName(),
                            Action__c = 'Update',
                            Changed_Fields_JSON__c = JSON.serialize(fwList),
                            Modified_By__c = (String) newRecord.get('LastModifiedById')
                        )
                    );
                }
            }
        }
        if (!snapshots.isEmpty()) {
            System.enqueueJob(new AuditSnapshotQueueable(snapshots));
        }
    }

    private FieldWrapper buildFieldWrapper(String oldVal, String newVal, String fieldName) {
        FieldChangeWrapper fcw = new FieldChangeWrapper();
        fcw.oldValue = oldVal;
        fcw.newValue = newVal;
        FieldWrapper fw = new FieldWrapper();
        fw.fcw = fcw;
        fw.fieldName = fieldName;

        return fw;
    }

    private class FieldWrapper {
        private String fieldName;
        private FieldChangeWrapper fcw;
    }

    private class FieldChangeWrapper {
        private String oldValue;
        private String newValue;
    }

}