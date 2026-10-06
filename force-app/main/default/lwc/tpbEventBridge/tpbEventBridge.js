import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TpbEventBridge extends LightningElement {
  @api showToast(detail) {
    this.dispatchEvent(new ShowToastEvent(detail));
  }
}