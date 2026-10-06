import { LightningElement, api } from 'lwc';

export default class TpbPicklistConversion extends LightningElement {
    @api inputString; // Comma-separated string input from the flow
    @api selectedValue; // Value selected by the user, to be read by the flow

    get options() {
        // Split the input string by commas and transform into the required format
        return this.inputString.split(',').map(value => {
            return { label: value.trim(), value: value.trim() };
        });
    }

    handleChange(event) {
        this.selectedValue = event.detail.value;
    }
}