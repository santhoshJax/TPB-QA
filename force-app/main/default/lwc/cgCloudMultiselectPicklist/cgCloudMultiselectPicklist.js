import { LightningElement ,api,track} from 'lwc';

export default class CgCloudMultiselectPicklist extends LightningElement {
    @api required;
    @api labeldata;
    @api placeholder;
    @api selectedValue;
    @api selectedValues = [];
    @api label;
    @api disabled = false;
    @api multiSelect = false;
    @track value;
    @track values = [];
    @track labels = [];
    @track optionData;
    @track searchString;
    @track message;
    @track enabled = false;
    @track showDropdown = false;
    @track allSelections = {};
    _options;
    @api checkValidity() {

        var inputCmp = this.template.querySelector(".inputBox");
        let selV = JSON.parse(JSON.stringify(this.allSelections));
        if (Object.keys(selV).length === 0) {
            inputCmp.value = '';

        }
        inputCmp.reportValidity();
        return inputCmp.reportValidity();
    }
    @api
    get options() {
        return this._options;
    }

    set options(value) {
        this._options = value;
        this.showDropdown = false;
        var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
        var value = this.selectedValue ? (JSON.parse(JSON.stringify(this.selectedValue))) : null;
        var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : [];
        this.value = value;
        this.values = values;
        this.optionData = optionData;
        if (this.selectedValues != undefined) {
            for (var i = 0; i < this.selectedValues.length; i++) {
                this.selectItemMethod(this.selectedValues[i])
            }

        }
    }

    connectedCallback() {
        this.showDropdown = false;
        var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
        var value = this.selectedValue ? (JSON.parse(JSON.stringify(this.selectedValue))) : null;
        var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : [];

        this.value = value;
        this.values = values;
        this.optionData = optionData;
        if (this.selectedValues != undefined) {
            for (var i = 0; i < this.selectedValues.length; i++) {
                const selectedId = this.selectedValues[i];
                this.selectItemMethod(this.selectedValues[i]);
                const matched = this.optionData.find(opt => opt.value === selectedId);
                if (matched) {
                    matched.disabled = true;
                    matched.selected = true;
                }
                if (this.allSelections[this.selectedValues[i]]) {
                    delete this.allSelections[this.selectedValues[i]];
                } else {
                    this.allSelections[this.selectedValues[i]] = this.selectedValues[i];
                }
            }

        }
        this.showDropdown = this.optionData.length > 0 ? true : false;
    }
    get filteredOptions() {
        if (!this.searchString || this.searchString.length < 2) {
            return this.optionData;
        }
        const search = this.searchString.toLowerCase();
        return this.optionData.filter(opt =>
            (opt.label && opt.label.toLowerCase().includes(search))
        );
    }

    filterOptions(event) {
        this.searchString = event.target.value;
        // if (this.searchString && this.searchString.length > 0) {
        //     this.message = '';
        //     if (this.searchString.length >= 2) {
        //         var flag = true;
        //         for (var i = 0; i < this.optionData.length; i++) {
        //             if (this.optionData[i].label.toLowerCase().trim().includes(this.searchString.toLowerCase().trim())) {
        //                 this.optionData[i].isVisible = true;
        //                 flag = false;
        //             } else {
        //                 this.optionData[i].isVisible = false;
        //             }
        //         }
        //         if (flag) {
        //             this.message = "No results found for '" + this.searchString + "'";
        //         }
        //     }
        //     this.showDropdown = true;
        // } else {
        //     this.showDropdown = false;
        // }
    }

    selectItem(event) {
        var selectedVal = event.currentTarget.dataset.id;

        var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : [];
        this.values = values;

        if (selectedVal) {
            this.selectItemMethod(selectedVal);


            if (this.allSelections[selectedVal]) {
                delete this.allSelections[selectedVal];
            } else {
                this.allSelections[selectedVal] = selectedVal;
            }


            if (this.multiSelect) {

                this.dispatchEvent(new CustomEvent('selectedoption', {
                    detail: {
                        'payload': {
                            'value': this.value,
                            'values': this.values,
                            'label': this.label,
                            'labels': this.labels,
                            'allSelections': this.allSelections,
                        }
                    }
                }));
            }


            if (!this.multiSelect) {
                this.dispatchEvent(new CustomEvent('selectedoption', {
                    detail: {
                        'payload': {
                            'value': this.value,
                            'values': this.values,
                            'label': this.label,
                            'labels': this.labels
                        }
                    }
                }));
            }
            if (this.multiSelect)
                event.preventDefault();
            else
                this.showDropdown = false;
        }
    }

    selectItemMethod(selectedVal) {
        // if (selectedVal) {
        //     var count = 0;
        //     var options = this.optionData;
        //     if (options != null) {
        //         for (var i = 0; i < options.length; i++) {
        //             if (options[i].value === selectedVal) {
        //                 if (this.multiSelect) {
        //                     if (this.values.includes(options[i].value)) {
        //                         this.values.splice(this.values.indexOf(options[i].value), 1);
        //                     } else {
        //                         this.values.push(options[i].value);
        //                         this.labels.push(options[i].label);
        //                     }
        //                     options[i].selected = options[i].selected ? false : true;
        //                 } else {
        //                     this.value = options[i].value;
        //                     this.searchString = options[i].label;
        //                     //this.label = options[i].label;
        //                 }
        //             }
        //             if (options[i].selected) {
        //                 count++;
        //             }
        //         }
        //     }

        //     this.optionData = options;
        //     // if (this.multiSelect) {
        //     //     this.searchString = count + ' Option(s) Selected';
        //     // }

        // }
        if (selectedVal) {
            let count = 0;
            let options = this.optionData;
    
            if (options != null) {
                for (let i = 0; i < options.length; i++) {
                    if (options[i].value === selectedVal) {
                        if (this.multiSelect) {
                            // Toggle selected state
                            if (this.values.includes(options[i].value)) {
                                this.values.splice(this.values.indexOf(options[i].value), 1);
                                options[i].selected = false;
                                options[i].disabled = false; // Enable if deselected
                            } else {
                                this.values.push(options[i].value);
                                this.labels.push(options[i].label);
                                options[i].selected = true;
                                options[i].disabled = true; // Disable after selection
                            }
                        } else {
                            this.value = options[i].value;
                            this.searchString = options[i].label;
                            options[i].selected = true;
                            options[i].disabled = true; // Optional for single select
                        }
                    }
    
                    if (options[i].selected) {
                        count++;
                    }
                }
            }
    
            this.optionData = options;
        }
    }

    showOptions() {
        if (this.disabled == false && this.options) {
            this.message = '';
            this.searchString = '';
            var options = JSON.parse(JSON.stringify(this.optionData));
            for (var i = 0; i < options.length; i++) {
                options[i].isVisible = true;
            }
            if (options.length > 0) {
                this.showDropdown = true;
            }
            this.optionData = options;
        }
    }

    closePill(event) {
        var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : [];
        this.values = values;
        var value = event.currentTarget.name;
        var count = 0;
        var options = JSON.parse(JSON.stringify(this.optionData));
        delete this.allSelections[value];

        for (var i = 0; i < options.length; i++) {
            if (options[i].value === value) {
                options[i].selected = false;
                this.values.splice(this.values.indexOf(options[i].value), 1);
            }
            if (options[i].selected) {
                count++;
            }
        }
        this.optionData = options;
        if (this.multiSelect) {
            this.searchString = count + ' Option(s) Selected';

            this.dispatchEvent(new CustomEvent('selectedoption', {
                detail: {
                    'payload': {
                        'value': this.value,
                        'values': this.values,
                        'label': this.label,
                        'labels': this.labels,
                        'allSelections': this.allSelections,
                    }
                }
            }));
        }
    }

    blurEvent() {
        var previousLabel;
        var count = 0;

        for (var i = 0; i < this.optionData.length; i++) {
            if (this.optionData[i].value === this.value) {
                previousLabel = this.optionData[i].label;
            }
            if (this.optionData[i].selected) {
                count++;
            }
        }

        // if (this.multiSelect) {
        //     this.searchString = count + ' Option(s) Selected';
        // } else {
        //     this.searchString = previousLabel;
        // }

        this.showDropdown = this.optionData.length > 0 ? true : false;
    }

    @api resetCombo() {
        console.log('reset from combo');
        this.selectedValues = [];
        this.selectedValue = [];
        this.allSelections = {};
        this.searchString = '';
    }

    handleCheckboxChange(event) {
        const selectedVal = event.target.dataset.id;
        const isChecked = event.target.checked;
    
        this.optionData = this.optionData.map(opt => {
            if (opt.value === selectedVal) {
                opt.selected = isChecked;
    
                if (isChecked) {
                    if (!this.values.includes(opt.value)) {
                        this.values.push(opt.value);
                        this.labels.push(opt.label);
                        this.allSelections[opt.value] = opt.value;
                    }
                } else {
                    const index = this.values.indexOf(opt.value);
                    if (index > -1) {
                        this.values.splice(index, 1);
                        this.labels.splice(index, 1);
                        delete this.allSelections[opt.value];
                    }
                }
            }
            return opt;
        });
    
        // Dispatch event (like selectItem)
        this.dispatchEvent(new CustomEvent('selectedoption', {
            detail: {
                payload: {
                    value: this.value,
                    values: this.values,
                    label: this.label,
                    labels: this.labels,
                    allSelections: this.allSelections
                }
            }
        }));
    }
    @api
    disableSelectedOptions() {
        const updated = this.optionData.map(opt => ({
            ...opt,
            disabled: opt.selected // if selected → disable it
        }));
        this.optionData = [...updated]; 
        console.log('optionData....' + JSON.stringify(this.optionData));
    }

    // Select/Deselect All
    // toggleSelectAll(event) {
    //     const isChecked = event.target.checked;
    
    //     this.optionData = this.optionData.map(opt => {
    //         opt.selected = isChecked;
    
    //         if (isChecked) {
    //             if (!this.values.includes(opt.value)) {
    //                 this.values.push(opt.value);
    //                 this.labels.push(opt.label);
    //                 this.allSelections[opt.value] = opt.value;
    //             }
    //         } else {
    //             const index = this.values.indexOf(opt.value);
    //             if (index > -1) {
    //                 this.values.splice(index, 1);
    //                 this.labels.splice(index, 1);
    //                 delete this.allSelections[opt.value];
    //             }
    //         }
    
    //         return opt;
    //     });
    
    //     // Dispatch event
    //     this.dispatchEvent(new CustomEvent('selectedoption', {
    //         detail: {
    //             payload: {
    //                 value: this.value,
    //                 values: this.values,
    //                 label: this.label,
    //                 labels: this.labels,
    //                 allSelections: this.allSelections
    //             }
    //         }
    //     }));
    // }
    @api
    clearSelections() {
        this.values = [];
        this.labels = [];
        this.value = null;
        this.allSelections = {};
    
        // Clear selected & disabled flags from optionData
        this.optionData = (this.options || []).map(opt => ({
            ...opt,
            selected: false,
            disabled: false
        }));
    
        this.searchString = '';
        this.showDropdown = this.optionData.length > 0;
    }
    @api
resetDisabledOptions() {
    const updated = this.optionData.map(opt => ({
        ...opt,
        disabled: false // Always enable all options
    }));
    this.optionData = [...updated];
}
}