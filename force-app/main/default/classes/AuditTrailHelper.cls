public with sharing class AuditTrailHelper {
    
    @TestVisible
    private static AuditTrailSelector selector = new AuditTrailSelector();

    public void createSnapshots(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) return;

        List<Audit_Snapshot__c> snapshots = new List<Audit_Snapshot__c>();
        Map<String, Audit_Setting__mdt> settings = selector.getActiveSettings();
        String objAPIName = newRecords[0].getSObjectType().getDescribe().getName();
        Audit_Setting__mdt setting = settings.get(objAPIName);
        if(setting == null || String.isBlank(setting.Tracked_Fields__c)) {
            return;
        }

        for (SObject newRecord : newRecords) {
            SObject oldRecord = oldMap.get(newRecord.Id);
            List<FieldChangeWrapper> fwList = assessAndBuildFieldChangeList(oldRecord, newRecord, setting);
            if (!fwList.isEmpty()) {
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
        if (!snapshots.isEmpty()) {
            System.enqueueJob(new AuditSnapshotQueueable(snapshots));
        }
    }

    private List<FieldChangeWrapper> assessAndBuildFieldChangeList(SObject oldRecord, SObject newRecord, Audit_Setting__mdt setting) {
        List<String> trackedFields = setting.Tracked_Fields__c != null ? setting.Tracked_Fields__c.split(',') : null;
        List<FieldChangeWrapper> fwList = new List<FieldChangeWrapper>();
        if (trackedFields != null) {
            for (String field : trackedFields) {
                field = field.trim();
                Object oldValue = oldRecord.get(field);
                Object newValue = newRecord.get(field);
                if (oldValue != newValue && (oldValue == null || !oldValue.equals(newValue))) {
                    FieldChangeWrapper fw = buildFieldWrapper(oldValue, newValue, field);
                    fwList.add(fw);
                }
            }
        }

        return fwList;
    }

    private FieldChangeWrapper buildFieldWrapper(Object oldVal, Object newVal, String fieldName) {
        FieldChangeWrapper fcw = new FieldChangeWrapper();
        fcw.oldValue = String.valueOf(oldVal);
        fcw.newValue = String.valueOf(newVal);
        fcw.fieldName = fieldName;

        return fcw;
    }

    private class FieldChangeWrapper {
        private String fieldName;
        private String oldValue;
        private String newValue;
    }

}