import { LightningElement, api, wire } from 'lwc';
import getRecordSnapshots from '@salesforce/apex/AuditTrailController.getRecordSnapshots';

export default class AuditTimeline extends LightningElement {
    @api recordId;
    snapshots = [];

    @wire(getRecordSnapshots, {recordId: '$recordId'})
    wiredSnapshots({error, data}) {
        if (data) {
            this.snapshots = data;
            console.log('Snapshot: ', this.snapshots);
        } else {
            console.error('Error fetching snapshots: ', error);
            this.snapshots = [];
        }
    }
}