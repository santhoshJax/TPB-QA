import { LightningElement, api, wire } from 'lwc';
import getParentFiles from '@salesforce/apex/TPBOnlineAppVisitProcess.getParentAccountHQAttachments';
import { NavigationMixin } from 'lightning/navigation';

export default class ParentAccountFiles extends NavigationMixin(LightningElement) {
    @api recordId;
    columns = [
        {
            label: 'File Name',
            fieldName: 'Title',
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'Title' },
                name: 'preview',
                variant: 'base'
            }
        },
        { label: 'Type', fieldName: 'FileType' },
        { label: 'Size (KB)', fieldName: 'size' },
        { label: 'Created By', fieldName: 'CreatedByName' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];
    files = [];

    @wire(getParentFiles, { recordId: '$recordId' })
    wiredFiles({ data, error }) {
        if (data) { console.log('getParentFiles data...'+JSON.stringify(data));
            this.files = data.map(row => ({
                id: row.ContentDocumentId,
                Title: row.ContentDocument.Title,
                FileType: row.ContentDocument.FileType,
                CreatedDate: row.ContentDocument.CreatedDate,
                CreatedByName: row.ContentDocument.CreatedBy.Name,
                size: Math.round(row.ContentDocument.ContentSize / 1024),
                fileUrl: `/lightning/r/ContentDocument/${row.ContentDocumentId}/view`
            }));
        } else if (error) {
            // optional: handle error
            this.files = [];
            console.error(error);
        }
    }
    handleRowAction(event) {
        const row = event.detail.row;

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: row.id
            }
        });
    }


}