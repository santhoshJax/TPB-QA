import { LightningElement, track, wire, api } from 'lwc';
import processScannedLineItems from '@salesforce/apex/TPB_OnlineAppBarcodeScanController.createOrderItemsFromScannedData';
import processScannedProductDistributions from '@salesforce/apex/TPB_OnlineAppBarcodeScanController.createVisitJobsFromScannedData';
import createVisitJobs from '@salesforce/apex/TPB_OnlineAppController.createVisitJobs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CgCloudBarcodeScanner extends LightningElement {
    @api accountId;
    @api visitId;
    @api orderId;
    _apiProductDistributionData = [];
    @api
    get productDistributionData() {
        return this._apiProductDistributionData;
    }
    set productDistributionData(value) {
        this._apiProductDistributionData = value || [];
        console.log('Child received updated product distribution data:', JSON.stringify(this._apiProductDistributionData));
    }

    @track scanning = false;
    @track scannedList = []; // array of cleaned GTIN strings
    @track scannedText = '';
    @track orderItemResult = null;
    @track visitJobResult = null;
    @track isScannerModalOpen = false;
    @track ScannerSpinner = false;
    @track actionButtons = true;
    @track closeButtons = false;
    @track isParentListRefreshNeeded = false;
    @track showEndOfScanReview = false; // For SAL-248
    @track reviewItems = []; // For SAL-248
    @track scannedCount = 0; // For SAL-248
    @track alreadyOosCount = 0; // For SAL-248
    @track needReviewCount = 0; // For SAL-248
    @track isReviewMode = false; // For SAL-248
    reviewStatusOptions = [ // For SAL-248
        { label: 'Distributed', value: 'Distributed' },
        { label: 'Out Of Stock', value: 'OutOfStock' }
    ];
    @track reviewSubmitResult; // For SAL-248
    buffer = ''; // accumulates characters from scanner
    get scanButtonLabel() {
        return this.scanning ? 'Stop scanning' : 'Start scanning';
    }
    get isSubmitDisabled() {
        //return this.scannedList.length === 0 || !this.orderId;
        return this.scannedList.length === 0 || (!this.orderId && !this.visitId);
    }
    get hasUnmatched() {
        return this.lastResult && this.lastResult.unmatched && this.lastResult.unmatched.length > 0;
    }
    openScannerModel() {
        console.log('openBarcodeScannerModel');
        this.isScannerModalOpen = true;
        this.scanning = false;
        this.actionButtons = true;
        this.closeButtons = false;
        this.buffer = '';
        this.isParentListRefreshNeeded = false;
            this.scannedList = [];
            this.scannedText = '';
    }
    closeScannerModel() {
        this.isScannerModalOpen = false;
        this.ScannerSpinner = true;
        if(this.isParentListRefreshNeeded) this.dispatchEvent(new CustomEvent('scanpopupclosed'));
        this.ScannerSpinner = false;
    }
    toggleScanning() {
        this.scanning = !this.scanning;
        if (this.scanning) {
            const el = this.template.querySelector('input[data-id="scannerInput"]');
            if (el) {
                el.focus();
            }
        }else{
            const el = this.template.querySelector('input[data-id="scannerInput"]');
            if (el) {
                el.blur();
            }
            // Small timeout before refocusing to trigger iPad software keyboard
            setTimeout(() => {
                el.focus();
            }, 200);
        }
    }
    handleOrderIdChange(event) {
        this.orderId = event.target.value;
    }
    handleKeyDown(event) { 
        if (!this.scanning) return;
        // handle Enter: treat buffer as a full scan
        if (event.key === 'Enter') {
            event.preventDefault();
            const code = this.buffer.trim(); 
            this.buffer = '';
            if (code) {
                this.addGtin(code);
            }
            return;
        }
        // Backspace support (allow correction if scanner misfires)
        if (event.key === 'Backspace') {
        event.preventDefault();
        this.buffer = this.buffer.slice(0, -1);
        return;
        }
        // Append printable characters (a scanner will send digits and possibly letters)
        if (event.key.length === 1) {
        this.buffer += event.key;
        }
    }
    handlePaste(event) { 
        event.preventDefault();
        const paste = (event.clipboardData || window.clipboardData).getData('text');
        if (!paste) return;
        // split on newline/comma/semicolon
        const codes = paste.split(/[\r\n,;]+/).map(s => s.trim()).filter(Boolean);
        codes.forEach(c => this.addGtin(c));
    }
    addGtin(raw) {
        const cleaned = raw.replace(/\s|\u200B/g, ''); // remove whitespace, zero-width
        // optional: validate numeric GTIN length (8-14 typically)
        const normalized = cleaned.replace(/\D/g, '');
        if (!normalized) return;
        // optionally check allowed lengths: 8,12,13,14
        // if invalid length, still add but mark later in UI
        //if (!this.scannedList.includes(normalized)) {
        this.scannedList = [...this.scannedList, normalized];
        //} else {
        // if duplicates allowed, you can push again; current logic dedups
        //}
        this.scannedText = this.scannedList.join(', ');
         
    }
    removeGtin(event) {
        const g = event.currentTarget.dataset.gtin;
        this.scannedList = this.scannedList.filter(x => x !== g);
        this.scannedText = this.scannedList.join(', ');
         
    }
    async handleSubmit() {
        this.ScannerSpinner = true;
        this.scannedText = this.scannedList.join(', ');
        
        
        if (this.orderId && !this.visitId) {
            await processScannedLineItems({ scannedValues: this.scannedText, orderId: this.orderId })
            .then(result => {
        
                const el = this.template.querySelector('input[data-id="scannerInput"]');
                if (el) {
                    el.blur();
                }
                // Small timeout before refocusing to trigger iPad software keyboard
                setTimeout(() => {
                    el.focus();
                }, 200);
                this.orderItemResult = result;
                this.scanning = false;
                this.actionButtons = false;
                this.closeButtons = true;
                this.buffer = '';
                this.ScannerSpinner = false;
                this.isParentListRefreshNeeded = true;
            })
            .catch(error => {
                console.error(error);
            });
        } else if (!this.orderId && this.visitId) {


            await processScannedProductDistributions({ scannedValues: this.scannedText, visitId: this.visitId, accountId: this.accountId })
            .then(result => {
     
                const el = this.template.querySelector('input[data-id="scannerInput"]');
                if (el) {
                    el.blur();
                }
                // Small timeout before refocusing to trigger iPad software keyboard
                setTimeout(() => {
                    el.focus();
                }, 200);
                this.visitJobResult = result;
                this.scanning = false;
                this.buffer = '';

                this.actionButtons = false;
                this.closeButtons = true;
                this.scannedList = [];
                this.scannedText = '';
                this.ScannerSpinner = false;
                this.isParentListRefreshNeeded = true;
                this.dispatchEvent(new CustomEvent('scanpopupclosed'));
                if (result?.failedItems?.length) {
                    //const notFound = result.failedItems.filter(item => item.reason === 'GTIN_NOT_FOUND');
                    //const dmlFailed = result.failedItems.filter(item => item.reason === 'DML_FAILED');
                    //let messageParts = [];
                    // if (notFound.length) {
                    //     messageParts.push(`${notFound.length} GTIN(s) not found`);
                    // }
                    // if (dmlFailed.length) {
                    //     messageParts.push(`${dmlFailed.length} item(s) failed to save`);
                    // }
                    // const message = messageParts.length
                    //     ? messageParts.join('. ') + '.'
                    //     : `Failed to process ${result.failedItems.length} scanned item(s).`;
                    // this.dispatchEvent(
                    //     new ShowToastEvent({
                    //         title: 'Some Items Failed',
                    //         message,
                    //         variant: 'warning'
                    //     })
                    // );
                }
                this.prepareEndOfScanReview(result); // For SAL-248
            })
            .catch(error => {
                // console.error(error);
                // this.ScannerSpinner = false;
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Scan Failed',
                //         message: error?.body?.message || error?.message || 'Unexpected error while processing scan.',
                //         variant: 'error'
                //     })
                // );

                console.log('FULL ERROR:', JSON.stringify(error));
                this.ScannerSpinner = false;
                const message =
                    error?.body?.message ||
                    error?.message ||
                    'Unexpected error';

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Scan Failed',
                        message: message,
                        variant: 'error'
                    })
                );
            });
        } else {
            console.error('Please provide either Order Id or Visit Id');
            this.ScannerSpinner = false;

        }
        
    }
    handleSubmit_Old() {
        if (!this.orderId) {
        // show error toast / ui message
        return;
        }
        this.scannedText = this.scannedList.join(', ');
       
        //return;
        // call Apex: pass orderId and scannedList
        processScannedProducts({ scannedValues: this.scannedText,orderId: this.orderId  })
        .then(result => {
            this.lastResult = result;
            // Optionally clear or keep scanned list
            this.scanning = false;
            this.buffer = '';
        })
        .catch(error => {
            // show error toast and log
            console.error(error);
        });
    }

    // For SAL-248: build review list after visit job creation
    prepareEndOfScanReview(result) {
        // keep previous logic commented
        // this.visitJobResult = result;

        const scannedNames = (result?.addedItems || []).map(item => item.productName);
        const distribution = Array.isArray(this.productDistributionData) ? this.productDistributionData : [];
        const alreadyOos = distribution.filter(item => (item.visitJobAnswer || '').toLowerCase() === 'outofstock');
        const distributed = distribution.filter(item => (item.visitJobAnswer || '').toLowerCase() === 'distributed');

        const needReview = distributed
            .filter(item => !scannedNames.includes(item.productName))
            .filter(item => !(alreadyOos.some(o => o.productId === item.productId)));

        this.reviewItems = needReview.map(item => ({
            ...item,
            reviewStatus: 'OutOfStock'
        }));

        this.scannedCount = scannedNames.length;
        this.alreadyOosCount = alreadyOos.length;
        this.needReviewCount = this.reviewItems.length;
        this.showEndOfScanReview = this.reviewItems.length > 0;
        this.isReviewMode = false; // For SAL-248 reset review mode
    }

    // For SAL-248: update review selection
    handleReviewStatusChange(event) {
        const productId = event.currentTarget.dataset.id || event.currentTarget.dataset.name;
        const newValue = event.detail.value;
        this.reviewItems = this.reviewItems.map(row =>
            row.productId === productId ? { ...row, reviewStatus: newValue } : row
        );
    }

    // For SAL-248: enter review mode
    openReviewModal() {
        if (this.reviewItems && this.reviewItems.length) {
            this.reviewSubmitResult = null;
            this.isReviewMode = true;
        }
    }

    // For SAL-248: submit review updates
    async handleReviewSubmit() {
        if (!this.reviewItems || !this.reviewItems.length) {
            this.showEndOfScanReview = false;
            return;
        }
        //New code Added for Duplicate Issue
        const distribution = Array.isArray(this.productDistributionData) ? this.productDistributionData : [];
        const visitJobMap = new Map(
            distribution
                .filter(rec => rec.visitJobId)
                .map(rec => [rec.productId, rec.visitJobId])
        );
        //End
        const payload = this.reviewItems.map(item => ({
            productId: item.productId,
            //visitJobId: item.visitJobId || null,
            visitJobId: visitJobMap.get(item.productId) || item.visitJobId || null, // For SAL-248 ensure update not duplicate
            visitJobAnswer: item.reviewStatus === 'Distributed' ? 'Distributed' : 'OutOfStock'
        }));

        this.ScannerSpinner = true;
        try {
            await createVisitJobs({
                visitId: this.visitId,
                visitJobWrapper: JSON.stringify(payload)
            });
            this.needReviewCount = 0;
            this.showEndOfScanReview = true; // For SAL-248 keep section visible
            this.closeButtons = true;
            this.isParentListRefreshNeeded = true;
            // For SAL-248: show success similar to scan
            const distribution = Array.isArray(this.productDistributionData) ? this.productDistributionData : [];
            const resultItems = payload.map(p => {
                const matched = distribution.find(x => x.productId === p.productId);
                return {
                    productName: matched?.productName || '',
                    status: p.visitJobAnswer
                };
            });
            this.reviewSubmitResult = {
                distributed: resultItems.filter(r => r.status === 'Distributed'),
                outOfStock: resultItems.filter(r => r.status !== 'Distributed')
            };
            this.reviewItems = [];
            this.isReviewMode = true; // keep modal showing review
            this.isParentListRefreshNeeded = true; // For SAL-248 refresh caller
        } catch (error) {
            console.error('handleReviewSubmit error', error);
        } finally {
            this.ScannerSpinner = false;
        }
    }

    // For SAL-248: go back from review to scan results
    handleReviewBack() {
        this.isReviewMode = false;
        this.reviewSubmitResult = null;
    }
}