public with sharing class AuditTrailController {
    @TestVisible
    private static AuditTrailSelector selector = new AuditTrailSelector();

    @AuraEnabled(cacheable=true)
    public static List<SnapshotWrapper> getRecordSnapshots(Id recordId){
        try {
            if (recordId == null) {
                return new List<SnapshotWrapper>();
            }

            List<Audit_Snapshot__c> snapshots = selector.getSnapshots(recordId);

            if(!snapshots.isEmpty()) {
                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(snapshots[0].Object_API_Name__c);
                Map<String, Schema.SObjectField> fieldMap = (targetType != null)
                    ? targetType.getDescribe().fields.getMap()
                    : new Map<String, Schema.SObjectField>();
                List<SnapshotWrapper> results = new List<SnapshotWrapper>();
                for (Audit_Snapshot__c snapshot : snapshots) {
                    SnapshotWrapper sw = new SnapshotWrapper();
                    sw.id = snapshot.Id;
                    sw.timestamp = snapshot.CreatedDate;
                    sw.action = snapshot.Action__c;
                    sw.modifiedBy = snapshot.Modified_By__r.Name;
                    if(String.isNotBlank(snapshot.Changed_Fields_JSON__c)) {
                        sw.changes = getFieldChanges(fieldMap, (List<Object>) System.JSON.deserializeUntyped(snapshot.Changed_Fields_JSON__c));
                    } else {
                        sw.changes = new List<FieldChangeDisplayWrapper>();
                    }
                    results.add(sw);
                }
                return results;
            } else {
                return new List<SnapshotWrapper>();
            }
        } catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage()); // prevent Salesforce from stripping the error message so set again
            throw ahe;
        }
    }

    private static List<FieldChangeDisplayWrapper> getFieldChanges(Map<String, Schema.SObjectField> fieldMap, List<Object> changedFields) {
        List<FieldChangeDisplayWrapper> changes = new List<FieldChangeDisplayWrapper>();
        for (Object obj : changedFields) {
            Map<String, Object> changedField = (Map<String, Object>) obj;
            FieldChangeDisplayWrapper fcdw = new FieldChangeDisplayWrapper();
            fcdw.fieldApiName = String.valueOf(changedField.get('fieldName'));
            fcdw.oldValue = changedField.get('oldValue') != null ? String.valueOf(changedField.get('oldValue')) : '';
            fcdw.newValue = changedField.get('newValue') != null ? String.valueOf(changedField.get('newValue')) : '';
            if(fieldMap.containsKey(fcdw.fieldApiName.toLowerCase())) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fcdw.fieldApiName).getDescribe();
                fcdw.fieldLabel = fieldDescribe.getLabel();
            } else {
                fcdw.fieldLabel = fcdw.fieldApiName;
            }
            changes.add(fcdw);
        }

        return changes;
    }

    public class SnapshotWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public Datetime timestamp;
        @AuraEnabled public String action;
        @AuraEnabled public String modifiedBy;
        @AuraEnabled public List<FieldChangeDisplayWrapper> changes;
    }

    public class FieldChangeDisplayWrapper {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String oldValue;
        @AuraEnabled public String newValue;
    }
}