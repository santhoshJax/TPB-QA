/**
 * @author Evonne
 * @date 2023-08-01
 * @description Common component for customized navigation
 */
import { LightningElement, api, track } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';

export default class TpbNavigationButton extends LightningElement {
    @api availableActions=[];
    @api label='Button';
    @api buttonId='Button1';
    /* eslint-disable */
    @api selectedButtonId;
    @api outputValue; // Output value
    /* eslint-disable */
    @api variant='brand';
    @api buttonAction='Next'; // Input to determine button action
    @api autoNext=0;
    @track hidden=true;

    handleNavigation() {
        this.selectedButtonId = this.buttonId;
        this.outputValue = this.selectedButtonId; // Set output value here
        if (this.buttonAction === 'Back' && this.availableActions.find(action => action === 'BACK')) {
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        } else if (this.availableActions.find(action => action === 'NEXT')) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    connectedCallback() {
        const navigateNextEvent = new FlowNavigationNextEvent();
        if (this.autoNext>0 && this.availableActions.find(action => action === 'NEXT')) {
            this.dispatchEvent(navigateNextEvent);
        } else {
            this.hidden=false;
        }
    }

}