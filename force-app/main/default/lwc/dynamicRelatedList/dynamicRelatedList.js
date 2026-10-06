import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getConfiguration from '@salesforce/apex/DynamicRelatedListController.getConfiguration';
import getRecords from '@salesforce/apex/DynamicRelatedListController.getRecords';
import updateRecords from '@salesforce/apex/DynamicRelatedListController.updateRecords';

export default class DynamicRelatedList extends NavigationMixin(LightningElement) {
    @api recordId; // Parent record Id (e.g., Opportunity Id)
    @api configName; // Developer Name of the config
    @api debugMode = false; // Enable debug logging

    @track data = [];
    @track columns = [];
    @track draftValues = [];
    @track isLoading = true;
    @track error;

    config;
    wiredRecordsResult;

    // Wire to get configuration
    @wire(getConfiguration, { configName: '$configName' })
    wiredConfig({ error, data }) {
        if (data) {
            this.config = data;
            this.columns = this.buildColumns(data.columns);
            this.error = undefined;

            if (this.debugMode) {
                console.log('Configuration loaded:', data);
                console.log('Columns built:', this.columns);
            }
        } else if (error) {
            this.error = error;
            this.config = undefined;
            this.showToast('Error', 'Failed to load configuration: ' + this.getErrorMessage(error), 'error');
            console.error('Configuration error:', error);
        }
    }

    // Wire to get records
    @wire(getRecords, {
        configName: '$configName',
        parentRecordId: '$recordId'
    })
    wiredRecords(result) {
        this.wiredRecordsResult = result;
        this.isLoading = true;

        if (result.data) {
            // Process records to handle relationship fields and create URLs
            this.data = this.processRecords(result.data);
            this.error = undefined;
            this.isLoading = false;

            if (this.debugMode) {
                console.log('Records loaded:', this.data);
            }
        } else if (result.error) {
            this.error = result.error;
            this.data = [];
            this.showToast('Error', 'Failed to load records: ' + this.getErrorMessage(result.error), 'error');
            console.error('Records error:', result.error);
            this.isLoading = false;
        }
    }

    /**
     * Process records to handle relationship fields and create clickable URLs
     */
    processRecords(records) {
        if (!records || !this.config) return [];

        return records.map(record => {
            const processedRecord = { ...record };

            // For each column, check if it needs special processing
            this.config.columns.forEach(col => {
                if (col.fieldName && col.fieldName.includes('.')) {
                    // This is a relationship field like "Product__r.Name"
                    const parts = col.fieldName.split('.');
                    const relationshipName = parts[0]; // e.g., "Product__r"
                    const displayField = parts[1];     // e.g., "Name"

                    // Get the lookup ID field name
                    let lookupIdField;
                    if (relationshipName.endsWith('__r')) {
                        // Custom relationship: Product__r → Product__c
                        lookupIdField = relationshipName.replace('__r', '__c');
                    } else if (relationshipName === 'Owner' ||
                        relationshipName === 'CreatedBy' ||
                        relationshipName === 'LastModifiedBy') {
                        // Standard User lookup: Owner → OwnerId
                        lookupIdField = relationshipName + 'Id';
                    } else {
                        // Standard relationship: Account → AccountId
                        lookupIdField = relationshipName + 'Id';
                    }

                    // Get the relationship data
                    const relationshipData = record[relationshipName];
                    const lookupId = record[lookupIdField];

                    if (col.type === 'url') {
                        // Create URL field for clickable links
                        if (lookupId) {
                            processedRecord[col.fieldName + '_URL'] = '/' + lookupId;
                        }

                        // Store the display label
                        if (relationshipData && relationshipData[displayField]) {
                            processedRecord[col.fieldName + '_LABEL'] = relationshipData[displayField];
                        } else {
                            processedRecord[col.fieldName + '_LABEL'] = '';
                        }
                    } else {
                        // Regular text display for relationship fields
                        if (relationshipData && relationshipData[displayField]) {
                            processedRecord[col.fieldName] = relationshipData[displayField];
                        } else {
                            processedRecord[col.fieldName] = null;
                        }
                    }
                }else if (col.type === 'url') { //New section for Name Auto Number field

                    processedRecord[col.fieldName + '_URL'] = '/' + record.Id;
                    processedRecord[col.fieldName + '_LABEL'] = record[col.fieldName];
                }
            });

            return processedRecord;
        });
    }

    /**
     * Build columns array for lightning-datatable with URL support
     */
    buildColumns(columnDefinitions) {
        if (!columnDefinitions) return [];

        return columnDefinitions.map(col => {
            const column = {
                label: col.label,
                sortable: col.sortable || false
            };

            // Handle URL type for clickable links
            // if (col.type === 'url' && col.fieldName && col.fieldName.includes('.')) {
            //     column.type = 'url';
            //     column.fieldName = col.fieldName + '_URL'; // Point to URL field
            //     column.typeAttributes = {
            //         label: { fieldName: col.fieldName + '_LABEL' }, // Display name
            //         target: '_self', // Open in same tab (use '_blank' for new tab)
            //         tooltip: { fieldName: col.fieldName + '_LABEL' } // Show tooltip
            //     };
            // }
            if (col.type === 'url') { //New section for Name Auto Number field

                column.type = 'url';
                column.fieldName = col.fieldName + '_URL';

                column.typeAttributes = {
                    label: { fieldName: col.fieldName + '_LABEL' },
                    target: '_self',
                    tooltip: { fieldName: col.fieldName + '_LABEL' }
                };
            } else {
                // Regular field
                column.type = col.type;
                column.fieldName = col.fieldName;
                column.editable = col.editable;

                if (col.typeAttributes) {
                    column.typeAttributes = col.typeAttributes;
                }
            }

            if (col.initialWidth) {
                column.initialWidth = col.initialWidth;
            }

            if (col.wrapText) {
                column.wrapText = true;
            }

            if (col.cellAttributes) {
                column.cellAttributes = col.cellAttributes;
            }

            return column;
        });
    }

    /**
     * Handle New button click - Navigate to new record page
     */
    handleNew() {
        if (!this.config) {
            this.showToast('Error', 'Configuration not loaded', 'error');
            return;
        }

        if (this.debugMode) {
            console.log('Creating new record for:', this.config.objectApiName);
            console.log('Parent field:', this.config.parentFieldApiName);
            console.log('Parent record ID:', this.recordId);
        }

        // Pre-populate the parent field
        const defaultValues = encodeDefaultFieldValues({
            [this.config.parentFieldApiName]: this.recordId
        });

        // Navigate to new record page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.config.objectApiName,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                navigationLocation: 'RELATED_LIST',
                backgroundContext: `/lightning/r/${this.recordId}/view`
            }
        });
    }

    /**
     * Handle Refresh button click
     */
    handleRefresh() {
        this.isLoading = true;

        if (this.debugMode) {
            console.log('Refreshing data...');
        }

        return refreshApex(this.wiredRecordsResult)
            .then(() => {
                this.showToast('Success', 'Data refreshed', 'success');

                if (this.debugMode) {
                    console.log('Data refreshed successfully');
                }
            })
            .catch(error => {
                this.showToast('Error', 'Failed to refresh: ' + this.getErrorMessage(error), 'error');
                console.error('Refresh error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle save action
     */
    handleSave(event) {
        this.isLoading = true;
        const draftValues = event.detail.draftValues;

        if (this.debugMode) {
            console.log('Draft values to save:', JSON.stringify(draftValues));
        }

        // Prepare records for update
        const recordsToUpdate = draftValues.map(draft => {
            const record = {
                Id: draft.Id,
                sobjectType: this.config.objectApiName
            };

            // Add all changed fields
            Object.keys(draft).forEach(key => {
                if (key !== 'Id') {
                    record[key] = draft[key];

                    if (this.debugMode) {
                        console.log(`Setting field ${key} = ${draft[key]}`);
                    }
                }
            });

            return record;
        });

        if (this.debugMode) {
            console.log('Records to update:', JSON.stringify(recordsToUpdate));
        }

        // Call Apex to update records
        updateRecords({ recordsToUpdate: recordsToUpdate })
            .then(() => {
                this.showToast('Success', 'Records updated successfully', 'success');
                this.draftValues = [];
                return refreshApex(this.wiredRecordsResult);
            })
            .catch(error => {
                const errorMsg = this.getErrorMessage(error);
                this.showToast('Error', 'Failed to update records: ' + errorMsg, 'error', 'sticky');
                console.error('Update error:', error);

                if (this.debugMode) {
                    console.error('Full error:', JSON.stringify(error));
                }
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle cancel action
     */
    handleCancel() {
        this.draftValues = [];

        if (this.debugMode) {
            console.log('Edit cancelled, draft values cleared');
        }
    }

    /**
     * Extract error message from error object
     */
    getErrorMessage(error) {
        if (!error) return 'Unknown error';

        if (error.body) {
            if (error.body.message) {
                return error.body.message;
            } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors[0].message;
            } else if (error.body.fieldErrors) {
                const fieldErrors = [];
                Object.keys(error.body.fieldErrors).forEach(field => {
                    error.body.fieldErrors[field].forEach(err => {
                        fieldErrors.push(`${field}: ${err.message}`);
                    });
                });
                return fieldErrors.join(', ');
            }
        } else if (error.message) {
            return error.message;
        }

        return 'Unknown error occurred';
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant, mode = 'dismissable') {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    /**
     * Getters
     */
    get hasRecords() {
        return this.data && this.data.length > 0;
    }

    get recordCount() {
        return this.data ? this.data.length : 0;
    }

    get componentTitle() {
        return this.config ? this.config.title : 'Records';
    }

    get iconName() {
        return this.config ? this.config.iconName : 'standard:record';
    }

    get hasError() {
        return this.error !== undefined;
    }
}