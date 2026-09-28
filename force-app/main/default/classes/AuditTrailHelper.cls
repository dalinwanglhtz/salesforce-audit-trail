public with sharing class AuditTrailHelper {
    public AuditTrailHelper() {}

    public void createSnapshots(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Audit_Snapshot__c> snapshots = new List<Audit_Snapshot__c>();
        Map<String, Audit_Setting__mdt> settings = getFieldsForTracking();
        String objAPIName = newRecords[0].getSObjectType().getDescribe().getName();
        Audit_Setting__mdt setting = settings.get(objAPIName);
        if(setting == null || String.isBlank(setting.Tracked_Fields__c)) {
            return;
        }

        for (SObject newRecord : newRecords) {
            SObject oldRecord = oldMap.get(newRecord.Id);
            List<FieldWrapper> fwList = assessAndBuildFieldChangeList(oldRecord, newRecord, setting);
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

    private Map<String, Audit_Setting__mdt> getFieldsForTracking() {
        Map<String, Audit_Setting__mdt> settingsMap = new Map<String, Audit_Setting__mdt>();
        for (Audit_Setting__mdt setting : [
                SELECT Object_API_Name__c, Tracked_Fields__c 
                FROM Audit_Setting__mdt
                WHERE Is_Active__c = true    
        ]) {
            settingsMap.put(setting.Object_API_Name__c, setting);
        }
        return settingsMap;
    }

    private List<FieldWrapper> assessAndBuildFieldChangeList(SObject oldRecord, SObject newRecord, Audit_Setting__mdt setting) {
        List<String> trackedFields = setting.Tracked_Fields__c != null ? setting.Tracked_Fields__c.split(',') : null;
        List<FieldWrapper> fwList = new List<FieldWrapper>();
        if (trackedFields != null) {
            for (String field : trackedFields) {
                field = field.trim();
                Object oldValue = oldRecord.get(field);
                Object newValue = newRecord.get(field);
                if (oldValue != newValue && (oldValue == null || !oldValue.equals(newValue))) {
                    FieldWrapper fw = buildFieldWrapper(oldValue, newValue, field);
                    fwList.add(fw);
                }
            }
        }

        return fwList;
    }

    private FieldWrapper buildFieldWrapper(Object oldVal, Object newVal, String fieldName) {
        FieldChangeWrapper fcw = new FieldChangeWrapper();
        fcw.oldValue = String.valueOf(oldVal);
        fcw.newValue = String.valueOf(newVal);
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