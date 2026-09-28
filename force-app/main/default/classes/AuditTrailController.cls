public class AuditTrailController {
    @AuraEnabled(cacheable=true)
    public static List<SnapshotWrapper> getRecordSnapshots(Id recordId){
        try {
            List<Audit_Snapshot__c> snapshots = [
                SELECT Id, Record_Id__c, Object_API_Name__c, Action__c, Changed_Fields_JSON__c, Modified_By__r.Name, CreatedDate 
                FROM Audit_Snapshot__c
                WHERE Record_Id__c = :recordId
                ORDER BY CreatedDate DESC
            ];
            List<SnapshotWrapper> results = new List<SnapshotWrapper>();
            for (Audit_Snapshot__c snapshot : snapshots) {
                Schema.SObjectType targetType = Schema.getGlobalDescribe().get(snapshot.Object_API_Name__c);
                SnapshotWrapper sw = new SnapshotWrapper();
                sw.id = snapshot.Id;
                sw.timestamp = snapshot.CreatedDate;
                sw.action = snapshot.Action__c;
                sw.modifiedBy = snapshot.Modified_By__r.Name;
                List<Object> changedFields = (List<Object>) System.JSON.deserializeUntyped(snapshot.Changed_Fields_JSON__c);
                List<FieldChangeDisplayWrapper> changes = new List<FieldChangeDisplayWrapper>();
                for (Object obj : changedFields) {
                    Map<String, Object> changedField = (Map<String, Object>) obj;
                    FieldChangeDisplayWrapper fcdw = new FieldChangeDisplayWrapper();
                    fcdw.fieldApiName = (String) changedField.get('fieldName');
                    fcdw.oldValue = (String) changedField.get('oldValue');
                    fcdw.newValue = (String) changedField.get('newValue');
                    Schema.DescribeFieldResult fieldDescribe = targetType.getDescribe().fields.getMap().get(fcdw.fieldApiName).getDescribe();
                    fcdw.fieldLabel = fieldDescribe.getLabel();
                    changes.add(fcdw);
                }
                sw.changes = changes;
                results.add(sw);
            }
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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