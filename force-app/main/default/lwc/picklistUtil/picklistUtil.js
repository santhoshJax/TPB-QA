import {LightningElement, api} from 'lwc';

export default class PicklistUtil extends LightningElement {
    @api lineValue;
    @api familyIndex;
    @api productIndex;
    @api index;
    @api fieldName;
    @api disabled = false;
    @api objectType;
    itemsList = [];

    get items() {
        return this.itemsList;
    }

    @api
    set items(current) {
        //Read-only
        this.itemsList = JSON.parse(JSON.stringify(current));

        for(let i=0; i < current.length; i++) {
            if(this.lineValue === current[i].value) {
                this.itemsList[i].selected = true;
            }
        }
    }

    lineUpdateHandler(event) {
        //Mimic JS event
        const changes = {
            target : {
                dataset : {
                    index: this.index,
                    index1: this.familyIndex,
                    index2: this.productIndex
                },
                name: this.fieldName,
                value: event.target.value,
                sObject: this.objectType
            }
        };
        const lineUpdate = new CustomEvent('select', {detail: changes});
        this.dispatchEvent(lineUpdate);
    }
}