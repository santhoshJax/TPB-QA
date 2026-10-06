import { LightningElement,track,api } from 'lwc';

export default class CustomLookupSearch extends LightningElement {
    @api placeholder;
    @api options;
    @api selectedValue;
    @api selectedValues = [];
    required = true;
    @api label;
    @api minChar = 2;

    @api isorder = 1;
    @api enabled = false;
    @track value;
    @track values = [];
    @track optionData;
    @track searchString;
    @track message;
    @track labels = [];
    @track showDropdown = false;
    @track listofData;
    @track selectedLabel;

    @api refreshOptions(options) {

        if (this.isorder == 1) {
            
            options=JSON.parse(JSON.stringify(options));
            options = options.sort((a, b) => a.label.localeCompare(b.label, undefined, { numeric: true }));
        }

        this.enabled = true;
        this.optionData = JSON.parse(JSON.stringify(options));
        this.listofData = JSON.parse(JSON.stringify(options));

        if (this.selectedValue != undefined && this.selectedValue != '') {
            let count = 1;
            for (var key in this.optionData) {
                if (count > 1) {
                    if (this.optionData[key].value === this.selectedValue) {
                        this.searchString = this.optionData[key].label;
                    }
                } else {
                    this.searchString = this.optionData[key].label;
                }
                count++;
            }
        } else {
            this.searchString = '';
        }


    }

    @api checkValidity() {
        var inputCmp = this.template.querySelector('.className');
        console.log('child input '+inputCmp);
        if (inputCmp) {

            inputCmp.reportValidity();
            return inputCmp.reportValidity();
        }

    }

    @api getSelectedValue() {
        const searchText = typeof this.searchString === 'string' ? this.searchString.trim() : '';
        const hasSelectedValue = Array.isArray(this.values)
            ? this.values.length > 0
            : this.values !== null && this.values !== undefined && String(this.values).trim() !== '';

        if (!hasSelectedValue && searchText && Array.isArray(this.optionData)) {
            const matchedOption = this.optionData.find(option => option.label === searchText);
            if (matchedOption) {
                this.value = matchedOption.value;
                this.values = matchedOption.value;
                this.labels = matchedOption.label;
            }
        }
        return this.values;
    }

    connectedCallback() {
        this.showDropdown = false;
        var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
        if (this.options !== undefined) {
            this.optionData = optionData;
            if (this.selectedValue != undefined && this.selectedValue != '') {
                let count = 1;
                for (var key in this.optionData) {
                    if (count > 1) {
                        if (this.optionData[key].value === this.selectedValue) {
                            this.searchString = this.optionData[key].label;
                        }
                    } else {
                        this.searchString = this.optionData[key].label;
                    }
                    count++;
                }
            }


        } else {
            this.optionData = this.listofData;
        }
        if (this.optionData
            && Object.keys(this.optionData).length > 0
        ) {
            this.enabled = true;
        }

    }
    hanleChangeFilter(event) {

        if (event.detail.value === '') {
            this.values = '';

        }
    }
    handleClear(event) {
        try {

            if (!event.target.value.length) {

                this.values = '';
                this.value = '';

            }
        } catch (error) {
            console.log(error);
        }

    }
    filterOptions(event) {
        this.searchString = event.target.value;
        if (this.searchString && this.searchString.length > 0) {
            this.message = '';
            if (this.searchString.length >= this.minChar) {
                const searchLower = this.searchString.toLowerCase().trim();
                let flag = true;
            
                this.optionData.forEach(option => {
                    let isMatch = false;
            
                    for (let key in option) {
                        if (
                            typeof option[key] === 'string' &&
                            option[key].toLowerCase().includes(searchLower)
                        ) {
                            isMatch = true;
                            break;
                        }
                    }
            
                    option.isVisible = isMatch;
                    if (isMatch) flag = false;
                });
            
                if (flag) {
                    this.message = `No results found for '${this.searchString}'`;
                }
            }
            this.showDropdown = true;
        } else {
            this.showDropdown = false;
        }
    }

    selectItem(event) {
        var selectedVal = event.currentTarget.dataset.id;
        if (selectedVal) {

            var options = JSON.parse(JSON.stringify(this.optionData));
            for (var i = 0; i < options.length; i++) {
                if (options[i].value === selectedVal) {

                    this.value = options[i].value;
                    this.values = options[i].value;
                    this.searchString = options[i].label;
                    this.labels = options[i].label;
                }

            }
            this.optionData = options;

            this.showDropdown = false;
            this.emitSelection();
        }
    }

    showOptions(event) {

        if (this.enabled == true && this.options) {
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


    blurEvent() {
        var previousLabel;

        for (var i = 0; i < this.optionData.length; i++) {
            if (this.optionData[i].value === this.value) {
                if (this.values === '') {
                    previousLabel = '';
                } else {
                    previousLabel = this.optionData[i].label;
                }

            }

        }
        this.searchString = previousLabel;
        this.emitSelection();
    }

    emitSelection() {
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                payload: {
                    value: this.value,
                    values: this.values,
                    labels: this.labels
                }
            }
        }));
    }
    mouseOutHandler() {
        this.showDropdown = false;
    }
    @api resetUser() {
        this.selectedValue = [];
        this.selectedValues = [];
        this.searchString = '';

    }
}