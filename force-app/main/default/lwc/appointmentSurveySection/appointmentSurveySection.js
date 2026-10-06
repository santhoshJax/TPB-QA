import {LightningElement, api, wire, track} from 'lwc';
import {showToast} from 'c/utils';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getRecordCreateDefaults, generateRecordInputForCreate} from 'lightning/uiRecordApi';
import SURVEY_OBJECT from '@salesforce/schema/Survey_Account_Questions__c';

export default class AppointmentSurveySection extends LightningElement {
    spinner = false;
    @api accId;
    recordType;
    @track surveyObjectInfo;
    @track surveyCreateDefaults;

    @wire(getObjectInfo, {objectApiName: SURVEY_OBJECT})
    surveyObjectInfo;

    @wire(getRecordCreateDefaults, {objectApiName: SURVEY_OBJECT, recordTypeId: '$recordType'})
    surveyCreateDefaults;

    get recordTypes() {
        let options = [];
        const typeInfos = this.surveyObjectInfo.data.recordTypeInfos;
        const typeValues = Object.values(typeInfos);

        for(let i=0; i < typeValues.length; i++) {
            if(typeValues[i].name != 'Master' && typeValues[i].available === true) {
                options.push({
                    'label': typeValues[i].name,
                    'value': typeValues[i].recordTypeId
                })
            }
        }

        return options;
    }

    get surveyForm() {
        const surveyObjectInfo = this.surveyCreateDefaults.data.objectInfos[
            SURVEY_OBJECT.objectApiName
        ];
        const surveyDefaults = this.surveyCreateDefaults.data.record;
        const surveyInput = generateRecordInputForCreate(
            surveyDefaults,
            surveyObjectInfo
        );

        const fields = Object.keys(surveyInput.fields);
        const accIndex = fields.findIndex(field => field === 'Account__c');
        const recordTypeIndex = fields.findIndex(field => field === 'RecordTypeId');
        fields.splice(accIndex, 1);
        fields.splice(recordTypeIndex, 1);

        const formObj = {
            'sObject': this.surveyObjectInfo.data.apiName,
            'fields': fields
        }

        this.spinner = false;
        return formObj;
    }

    recordTypeHandler(event) {
        this.spinner = true;
        this.recordType = event.target.value;
    }

    handleSubmit(event){
        event.preventDefault();

        const fields = event.detail.fields;
        fields.Account__c = this.accId;

        this.template.querySelector('lightning-record-form').submit(fields);
    }

    handleSuccess() {
        this.showToast('Survey saved', 'success', 'dismissable');
        this.recordType = '';
    }

    showToast(message, variant, mode) {
        const toastEvent = showToast(message, variant, mode);
        this.dispatchEvent(toastEvent);
    }

    close() {
        const closeSection = new CustomEvent('close', {});
        this.dispatchEvent(closeSection);
    }
}