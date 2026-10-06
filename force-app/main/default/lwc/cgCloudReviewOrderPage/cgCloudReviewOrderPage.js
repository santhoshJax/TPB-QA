import { LightningElement, track, api } from 'lwc';
import getReviewOrder from '@salesforce/apex/TPB_OnlineAppController.getReviewOrder';
import completeOrder from '@salesforce/apex/TPB_OnlineAppController.completeOrder';
import rewardCriteriaCheck from '@salesforce/apex/TPB_OnlineAppController.rewardCriteriaCheck';
import getPercentageDiscountPromotionIds from '@salesforce/apex/TPB_OnlineAppController.getPercentageDiscountPromotionIds';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPDFValues from '@salesforce/apex/TPB_OnlineAppController.getPDFValues';
import generateAndAttachInvoice from '@salesforce/apex/TPB_OnlineAppController.generateAndAttachInvoice';

import LightningAlert from "lightning/alert";

export default class CgCloudReviewOrderPage extends LightningElement {
    // Reactive properties to store form input values
    @api orderId // Initial value from screenshot
    @track accountName = 'Retail Store Test Kelly'; // Initial value from screenshot
    @track orderDate = '2025-05-26'; // Initial value from screenshot
    @track deliveryDate = '2025-05-26'; // Initial value from screenshot
    @track totalValue = 0.00;
    @track currency = 'USD';
    @track paymentMethod = 'Cash';
    @track paidAmount = 0.00;
    @track paymentCollected = false;
    @track isSpinnerCompleted = false;
    @track isGenerateInvoice = false;
    @track authorizingAgent;
    @track accountShippingAddress = 'Retail Store Test Kelly , 5760 Dorinda Drive , , Louisville , KY';
    @track accountPhone = 'Account Phone';
    @track accountStateTobaccoNumber = '12345';
    @track accountStateTaxNumber = '12345';
    @track fein = 'FEIN';

    // Options for Payment Method combobox
    paymentMethodOptions = [
        { label: 'Cash', value: 'Cash' },
        // { label: 'Credit Card', value: 'Credit Card' },
        // { label: 'Bank Transfer', value: 'Bank Transfer' },
        // { label: 'Other', value: 'Other' },
    ];

    // Options for Currency combobox
    currencyOptions = [
        { label: 'USD', value: 'USD' },
        { label: 'EUR', value: 'EUR' },
        { label: 'GBP', value: 'GBP' },
        { label: 'JPY', value: 'JPY' },
        { label: 'INR', value: 'INR' },
    ];
    async connectedCallback() {
        await getReviewOrder({ orderId: this.orderId })
                .then(result => {
                    this.accountName = result.accountName;
                    this.orderDate = result.orderDate;
                    this.deliveryDate = result.deliveryDate;
                    this.totalValue = result.totalValue;
                    this.currency = result.orderCurrency;
                    this.paymentMethod = result.paymentMethod;
                    this.paidAmount = result.paidAmount;
                    this.authorizingAgent = result.authorizingAgent;
                    this.accountShippingAddress = result.shippingStreet + ', ' + result.shippingCity + ', ' + result.shippingState + ', ' + result.shippingCountry; //+ ', ' + result.shipping;
                    this.accountPhone = result.accountPhone;
                    console.log('result...', result);
                }).catch(error => {
                    console.error('getReviewOrder error...' + JSON.stringify(error));
                });
        await this.generatePDFValues();
    }
    handleGenerateInvoice() {
        const vfPageName = 'CgCloudInvoiceView'; // Replace with your actual VF page name
        const vfPageUrl = `/apex/${vfPageName}?orderId=${this.orderId}`;
        window.open(vfPageUrl, '_blank');
    }
    get buttonDisabled() {
        return (!this.paymentCollected || this.authorizingAgent === null || this.authorizingAgent === '')
    }
    
    
    handleFieldChange(event) {
        const fieldName = event.target.dataset.field;
        if (!fieldName) return;

        this[fieldName] = event.target.type === 'toggle'
            ? event.target.checked
            : event.target.type === 'number'
                ? parseFloat(event.target.value)
                : event.target.value;
    }
    validateForm() {
        const inputs = this.template.querySelectorAll('.validate');
        let isValid = true;

        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });

        return isValid;
    }
    async handleCompleteOrder() {
       
            
            //await this.generatePDFValues();
            if (this.pdfResponse) {
                let allInvalid = [];
                let isCashSaleLineItemsExist = false;
                let isReturnLineItemsExist = false;
                let isPrebookLineItemsExist = false;

                // Get references for convenience
                const cashSaleItems = this.pdfResponse.orderItemsCashSale || [];
                const returnItems = this.pdfResponse.orderItemsReturn || [];
                const prebookItems = this.pdfResponse.orderItemsPrebook || [];

                console.log('cashSaleItems...', JSON.stringify(cashSaleItems));

                // Step 1: Check if line items exist
                isCashSaleLineItemsExist = Array.isArray(cashSaleItems) && cashSaleItems.length > 0;
                isReturnLineItemsExist = Array.isArray(returnItems) && returnItems.length > 0;
                isPrebookLineItemsExist = Array.isArray(prebookItems) && prebookItems.length > 0;

                if (!isCashSaleLineItemsExist && !isReturnLineItemsExist && !isPrebookLineItemsExist) {
                    await LightningAlert.open({
                        label: 'Order could not be saved.\n\n',
                        message: "You must add at least one Cash Sale or Return or Prebook item before completing the order"
                    });
                    this.isSpinnerCompleted = false;
                    return;
                }
                // For SAL-310: allow zero-value cash sale items only when PercentageDiscount promo is fulfilled
                const promotionIds = [
                    ...new Set(
                        cashSaleItems
                            .map(item => item.cgcloud__Promotion__c)
                            .filter(Boolean)
                    )
                ];
                console.log('promotionIds...', JSON.stringify(promotionIds));
                let fulfilledPercentageDiscountPromos = new Set();
                if (promotionIds.length) {
                    const percentageDiscountPromos = await getPercentageDiscountPromotionIds({ promotionIds });
                    console.log('percentageDiscountPromos...', JSON.stringify(percentageDiscountPromos));
                    const promoIdsToCheck = Array.isArray(percentageDiscountPromos) ? percentageDiscountPromos : [];
                    const checks = await Promise.all(
                        promoIdsToCheck.map(promoId =>
                            rewardCriteriaCheck({ promotionId: promoId, orderId: this.orderId })
                                .then(result => ({ promoId, result }))
                                .catch(() => null)
                        )
                    );
                    checks.forEach(entry => {
                        console.log('entry?.result?...', JSON.stringify(entry?.result));
                        const resultVal = Array.isArray(entry?.result) ? entry.result[0] : entry?.result;
                        if (resultVal?.rewardFulfilled) {
                            fulfilledPercentageDiscountPromos.add(entry.promoId);
                        }
                    });
                }
                

                // For SAL-310: old validation kept for reference
                // const invalidCashSale = cashSaleItems.filter(item =>
                //     item.cgcloud__Value__c === 0 &&
                //     item.cgcloud__Order_Item_Template__r?.Name !== 'Free Item'
                // );
                const invalidCashSale = cashSaleItems.filter(item =>
                    item.cgcloud__Value__c === 0 &&
                    item.cgcloud__Order_Item_Template__r?.Name !== 'Free Item' &&
                    !(item.cgcloud__Promotion__c && fulfilledPercentageDiscountPromos.has(item.cgcloud__Promotion__c))
                );

                const invalidReturn = returnItems.filter(item =>
                    item.cgcloud__Value__c === 0 &&
                    item.cgcloud__Order_Item_Template__r?.Name !== 'Free Item'
                );

                allInvalid = [...invalidCashSale, ...invalidReturn];


              

                console.log('allInvalid...', allInvalid);

                if (allInvalid.length > 0) {


                    let alertMessage = "";
                    //let alertProducts = [];
                    let cntr = 1;
                    allInvalid.forEach(item => {
                        alertMessage += `${cntr++}) ${item.cgcloud__Product__r && item.cgcloud__Product__r.Name ? item.cgcloud__Product__r.Name : 'Unknown Product'}, `;
                    });
                   


           

                    const resultErr = LightningAlert.open({
                        label: 'You cannot complete this order as the following order items have zero prices:\n\n',
                        message: alertMessage
                    });
                    this.isSpinnerCompleted = false;
                    return;
                }else{
                    if (this.validateForm()) {
                        this.isSpinnerCompleted = true;
                        const orderBody = {
                            orderId: this.orderId,
                            orderDate: this.orderDate,
                            deliveryDate: this.deliveryDate,
                            totalValue: this.totalValue,
                            currency: this.currency,
                            paymentMethod: this.paymentMethod,
                            paidAmount: this.paidAmount,
                            authorizingAgent: this.authorizingAgent
                        };
                        console.log('orderBody...' + JSON.stringify(orderBody));
                        
                        //this.isSpinnerCompleted = true;
                        await completeOrder({ orderBody: JSON.stringify(orderBody) })
                            .then(async (result) => {
                                await this.generatePDFSave();

                                this.isSpinnerCompleted = false;
                                console.log('result...' + JSON.stringify(result));
                                this.dispatchEvent(new ShowToastEvent({
                                    title: "Success",
                                    message: "Order Created Successfully",
                                    variant: "Success"
                                }));
                                this.dispatchEvent(new CustomEvent('completeorder'));
                                //this.dispatchEvent(new CustomEvent('storenavigation'));
                                
                            }).catch(error => {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: "Error",
                                    message: "Error Occured",
                                    variant: "Error"
                                }));
                                console.error('error...' + JSON.stringify(error));
                            });
                    } else {
                        console.log('Form is invalid');
                    }
                    

                }

                
            } else {
                this.isSpinnerCompleted = false;
                console.warn('this.pdfResponse is undefined. Cannot perform validation.');
            } 
    }
    async generatePDFValues() { console.log('Here Parent...333');
        //this.orderId = 'a51bc00000CB52JAAT';
        console.log('this.orderId...'+this.orderId);
        await getPDFValues({ orderId: this.orderId })
            .then(result => {
                console.log('generatePDFValues...' + JSON.stringify(result));
                console.log('Here Parent...444');
                this.pdfResponse = result;
                //this.generatePDFSave();
            }).catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Error",
                    message: "Error Occured",
                    variant: "Error"
                }));
                console.error('Parent generatePDFValues error...' + JSON.stringify(error));
            });
    }

    async generatePDFSave(){
        await generateAndAttachInvoice({
            orderId: this.orderId
        })
        .then(result => {

        })
        .catch(error => {
            console.error(error);
            // alert('Upload failed: ' + error.body.message);
        });
    }
    navigateToStoreCockpit() {
        this.dispatchEvent(new CustomEvent('storenavigation'));
    }
    calculateTotal(item) {
        const price = item.cgcloud__Value__c || 0;
        const discount = item.cgcloud__Discount__c || 0;
        const quantity = item.cgcloud__Quantity__c || 0;
        const total = (price * quantity) - discount;
        return total.toFixed(2);
    }

}