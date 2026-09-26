trigger AccountTrigger on Account (after update) {
    TriggerHandler handler = new AuditTrailHandler();
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            handler.afterUpdate(
                Trigger.old,
                Trigger.new,
                Trigger.oldMap,
                Trigger.newMap
            );
        }
    }
}