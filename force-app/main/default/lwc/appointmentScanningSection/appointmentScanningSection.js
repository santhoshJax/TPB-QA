import {LightningElement, track, api} from 'lwc';
// import {getBarcodeScanner} from 'lightning/mobileCapabilities';
// import {showToast} from 'c/utils';
// import getProductCodes from '@salesforce/apex/AppointmentScanningSectionController.getProductCodes';
// import upsertRecords from '@salesforce/apex/AppointmentScanningSectionController.upsertRecords';

export default class BarcodeScannerExample extends LightningElement {
    // sessionScanner;
    // scannerDisabled = false;
    // @track scannedBarcodes = [];
    // @track productCodes = [];
    // error;
    // @api workOrderId;
    // @api pricebookId;
    // spinner = false;
    // scanningOptions = {};

    // connectedCallback() {
    //     this.sessionScanner = getBarcodeScanner();

    //     if(this.sessionScanner == null || !this.sessionScanner.isAvailable()) {
    //         this.scannerDisabled = true;
    //     }
    //     else {
    //         this.scanningOptions = {
    //             'barcodeTypes': [
    //                 this.sessionScanner.barcodeTypes.QR,
    //                 this.sessionScanner.barcodeTypes.UPC_E,
    //                 this.sessionScanner.barcodeTypes.CODE_128,
    //                 this.sessionScanner.barcodeTypes.CODE_39,
    //                 this.sessionScanner.barcodeTypes.CODE_93,
    //                 this.sessionScanner.barcodeTypes.DATA_MATRIX,
    //                 this.sessionScanner.barcodeTypes.EAN_13,
    //                 this.sessionScanner.barcodeTypes.EAN_8,
    //                 this.sessionScanner.barcodeTypes.ITF,
    //                 this.sessionScanner.barcodeTypes.PDF_417
    //             ]
    //         };

    //         this.init();
    //     }
    // }

    // async init() {
    //     this.spinner = true;

    //     try {
    //         let productCodes = await getProductCodes({'pricebookId' : this.pricebookId});
    //         this.productCodes = productCodes;
    //     }
    //     catch(error) {
    //         console.log(error);
    //     }
    //     finally {
    //         this.spinner = false;
    //     }
    // }

    // startScanning() {
    //     this.error = '';
    //     this.sessionScanner.beginCapture(this.scanningOptions)
    //     .then(results =>
    //         this.processScannedBarcode(results)
    //     )
    //     .catch(error => {
    //         this.error = JSON.stringify(error);
    //     })
    //     .finally(() => {
    //         this.sessionScanner.endCapture();
    //     });
    // }

    // processScannedBarcode(barcode) {
    //     let code = barcode.value;

    //     if(barcode.type === 'ean13' && code.length === 13 && code.charAt(0) === '0') {
    //         code = code.substring(1);
    //     }

    //     const productCodes = this.productCodes;
    //     const scannedCodes = this.scannedBarcodes.map(b => b.code);

    //     if(!scannedCodes.includes(code)) {
    //         const product = productCodes.find(p => p.UPC__c === code);

    //         if(product !== undefined) {
    //             this.scannedBarcodes.push({
    //                 'code': code,
    //                 'name': product.Product__r.Name
    //             });
    //         }
    //     }
    // }

    // save() {
    //     this.spinner = true;
    //     const scannedCodes = this.scannedBarcodes.map(b => b.code);

    //     upsertRecords({
    //         'workOrderId': this.workOrderId,
    //         'pricebookId': this.pricebookId,
    //         'scannedBarcodes': scannedCodes
    //     })
    //     .then(results => {
    //         if(results !== 'SUCCESS') {
    //             this.showToast(results, 'error', 'sticky');
    //         }
    //         else {
    //             this.showToast('The Line Items have been updated.', 'success', 'dismissable');
    //             this.close();
    //         }
    //     })
    //     .catch(error => {
    //         this.showToast(error, 'error', 'sticky');
    //     })
    //     .finally(() => {
    //         this.spinner = false;
    //     });
    // }

    // showToast(message, variant, mode) {
    //     const toastEvent = showToast(message, variant, mode);
    //     this.dispatchEvent(toastEvent);
    // }

    // close() {
    //     const closeSection = new CustomEvent('close', {});
    //     this.dispatchEvent(closeSection);
    // }
}