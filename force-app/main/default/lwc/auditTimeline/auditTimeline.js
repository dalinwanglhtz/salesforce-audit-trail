import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecordSnapshots from '@salesforce/apex/AuditTrailController.getRecordSnapshots';

const PAGE_SIZE = 3;
export default class AuditTimeline extends NavigationMixin(LightningElement) {
    @api recordId;
    snapshots = [];
    _allSnapshots = [];
    displayedSnapshots = [];
    currentPage = 1;

    @wire(getRecordSnapshots, {recordId: '$recordId'})
    wiredSnapshots({error, data}) {
        if (data) {
            this._allSnapshots = data;
            this.currentPage = 1;
            this.updateDisplayedSnapshots();
        } else {
            console.error('Error fetching snapshots: ', error);
            this._allSnapshots = [];
            this.displayedSnapshots = [];
        }
    }

    get totalPages () {
        return Math.ceil(this._allSnapshots.length / PAGE_SIZE);
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
}