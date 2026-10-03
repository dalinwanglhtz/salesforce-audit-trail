import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getRecordSnapshots from '@salesforce/apex/AuditTrailController.getRecordSnapshots';

const PAGE_SIZE = 3;
export default class AuditTimeline extends NavigationMixin(LightningElement) {
    @api recordId;
    _allSnapshots = [];
    displayedSnapshots = [];
    _wiredSnapshotResult = [];
    currentPage = 1;
    subscription = {};

    connectedCallback() {
        const channelName = '/data/Audit_Snapshot__ChangeEvent';

        this.registerErrorListener();
        this.handleSubscribe(channelName);
    }

    @wire(getRecordSnapshots, {recordId: '$recordId'})
    wiredSnapshots(result) {
        this._wiredSnapshotResult = result;
        const {error, data} = result;
        if (data) {
            this._allSnapshots = data;
            this.currentPage = 1;
            this.updateDisplayedSnapshots();
        } else {
            console.error('Error fetching snapshots: ', error);
            this._allSnapshots = [];
            this.displayedSnapshots = [];
            this.currentPage = 1;
        }
    }

    get totalPages () {
        return Math.ceil(this._allSnapshots.length / PAGE_SIZE) || 1;
    }

    get isFirstPage () {
        return this.currentPage == 1;
    }

    get isLastPage () {
        return this.currentPage >= this.totalPages;
    }

    get hasMultiplePages () {
        return this._allSnapshots.length > PAGE_SIZE;
    }

    handleSubscribe(channelName) {
        const eventCallback = (response) => {
            console.log("New message received: ", JSON.stringify(response));
            if (response.data.payload.Record_Id__c == this.recordId) {
                refreshApex(this._wiredSnapshotResult);
            }
        };

        subscribe(channelName, -1, eventCallback).then((response) => {
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        if (this.subscription && this.subscription.subscription) {
            unsubscribe(this.subscription, (response) => {
                console.log("unsubscribe() response: ", JSON.stringify(response));
            });
        }
    }

    updateDisplayedSnapshots() {
        let startIndex = (this.currentPage - 1) * PAGE_SIZE;
        let endIndex = startIndex + PAGE_SIZE;
        this.displayedSnapshots = this._allSnapshots.slice(startIndex, endIndex);
    }

    handlePrevious() {
        if(this.currentPage > 1) {
            this.currentPage--;
            this.updateDisplayedSnapshots();
        }
    }

    handleNext() {
        if(this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updateDisplayedSnapshots();
        }
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Audit_Snapshot__c",
                actionName: "home"
            }
        });
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    registerErrorListener() {
        onError((error) => {
            console.log("Received error from server: ", JSON.stringify(error));
        });
    }
}