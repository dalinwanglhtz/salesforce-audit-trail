public with sharing virtual class AuditTrailSelector {
    public virtual List<Audit_Snapshot__c> getSnapshots (Id recordId) {
        return [
            SELECT Id, Record_Id__c, Object_API_Name__c, Action__c, Changed_Fields_JSON__c, Modified_By__r.Name, CreatedDate 
            FROM Audit_Snapshot__c
            WHERE Record_Id__c = :recordId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }
}