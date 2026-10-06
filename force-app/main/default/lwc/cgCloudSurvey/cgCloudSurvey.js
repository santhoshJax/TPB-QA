import { LightningElement, wire, api, track } from 'lwc';
import getVisitQuestions from '@salesforce/apex/TPBOnlineAppVisitProcess.getVisitQuestions';
import createSurveyVisitJobs from '@salesforce/apex/TPBOnlineAppVisitProcess.createSurveyVisitJobs';
import createSurveyVisitJobsWithFile from '@salesforce/apex/TPBOnlineAppVisitProcess.createSurveyVisitJobsWihtFiles';
//import updateVisitSurveysCheckFlag from '@salesforce/apex/TPBOnlineAppVisitProcess.updateVisitSurveysCheckFlag';
import { updateRecord } from 'lightning/uiRecordApi';
import VISIT_ID from '@salesforce/schema/Visit.Id';
import VISIT_SURVEYS_PROCESSED from '@salesforce/schema/Visit.Surveys_Accessed__c';

import { refreshApex } from '@salesforce/apex';
export default class CgCloudSurvey extends LightningElement {

    showCamera = false;
    videoStream = null;
    @track issurveyQuestions = false;
    @api customerId = '';
    @api recordId = '';
    @track surveyQuestions = [];
    @track isSuverySpinner = true;
    @track wireRefreshSurveyQuestionsData;
    uploadedFileNameByQuestionId = {};
    saveAnswersQueue = Promise.resolve();
    isSurveyFileUploadInProgress = false;

    async connectedCallback() {
        if (this.recordId) {

            const fields = {};
            fields[VISIT_ID.fieldApiName] = this.recordId;
            fields[VISIT_SURVEYS_PROCESSED.fieldApiName] = true;

            const recordInput = { fields };

            try {
                await updateRecord(recordInput);
                console.log('VISIT_SURVEYS_PROCESSED updated successfully');
            } catch (error) {
                console.error('Error updating VISIT_SURVEYS_PROCESSED :', error);
            }

        }
        const isTablet = /iPad|Android(?!.*Mobile)/i.test(navigator.userAgent);
        if (!isTablet) {
            // Optional: hide or redirect
            console.warn('Not a tablet. Camera feature disabled.');
        }
        
    }

    @wire(getVisitQuestions, { customerId: '$customerId', visitId: '$recordId' })
    wiregetVisitQuestions(result) {
        this.wireRefreshSurveyQuestionsData = result;
        const { error, data } = result;
        if (data) {
            this.isSuverySpinner = false;
            const groupedMap = {};
            console.log('data...' + JSON.stringify(data));
            data?.forEach(q => {
                const activity = q?.activityName || 'Unknown';

                if (!groupedMap[activity]) {
                    groupedMap[activity] = [];
                }
                const base = {
                    questionId: q.questionId,
                    questionName: q.questionName,
                    isSelected: q.visitJobAnswer !== null && q.visitJobAnswer !== undefined && q.visitJobAnswer !== '',
                    visitJobAnswer: q.dataType === 'Toggle' ? q.optionId : q.visitJobAnswer,
                    jobDefinationId: q.jobDefinationId,
                    visitJobId: q.visitJobId || '',
                    dataType: q.dataType,
                    showUpload: Boolean(q.pictureTaking),
                    rowKey: `${activity}-${q.questionId}`,
                    fileName: this.uploadedFileNameByQuestionId[q.questionId] || '',
                    options: []
                };

                if (q.dataType === 'Toggle') {
                    base.isPicklist = true;
                    base.options = (q.options || []).map(opt => ({
                        label: opt.description,
                        value: opt.optionId
                    }));
                } else if (q.dataType === 'Decimal') {
                    base.isNumber = true;
                } else if (q.dataType === 'String') {
                    base.isString = true;
                }
                groupedMap[activity].push(base);
            });
            this.surveyQuestions = Object.keys(groupedMap).map(activityName => ({
                activityName,
                items: groupedMap[activityName]
            }));
            this.issurveyQuestions = this.surveyQuestions.length > 0 ? true: false;
            console.log('this.surveyQuestions...' + JSON.stringify(this.surveyQuestions));
        } else if (error) {
            this.isSuverySpinner = false;
            this.issurveyQuestions = false;
            console.log('error...' + JSON.stringify(error));
        }
    }

    navigateToStoreCockpit() {
        this.dispatchEvent(new CustomEvent('navigate'));
    }

    async handleInputChange(event) {
        const target = event?.target;
        const qId = target?.name;
        const value = target?.value;
        if (!this.recordId || !qId) return;

        let userAnswers = {};
        const allQuestions = Array.isArray(this.surveyQuestions)
            ? this.surveyQuestions.flatMap(group => (Array.isArray(group.items) ? group.items : []))
            : [];
        const question = allQuestions.find(q => q.questionId === qId);
        if (!question) return;
        const jobDefinationId = question.jobDefinationId;

        // Determine the actual answer
        let actualAnswer = '';
        let optionId = '';
        console.log('question....' + jobDefinationId);
        const selectedOption = question.options?.find(opt => opt.value === value);
        if (question.dataType === 'Toggle') {
            actualAnswer = selectedOption?.label || '';
        } else {
            actualAnswer = typeof value === 'string' ? value.trim() : value;
            if (actualAnswer === '' || actualAnswer === null || actualAnswer === undefined) {
                return;
            }
        }
        // if (!actualAnswer || !actualAnswer.trim()) {
        //     return;
        // }

        optionId = selectedOption?.value || '';

        if (!userAnswers) {
            userAnswers = {};
        }

        userAnswers[qId] = {
            value: actualAnswer,
            optionId: optionId,
            dataType: question.dataType,
            visitJobId: question.visitJobId || '',
            jobDefinationId: question.jobDefinationId || ''
        };
        console.log('userAnswers[qId]:', userAnswers[qId]);

        const payloadList = Object.keys(userAnswers).map(qIdKey => {
            const ans = userAnswers[qIdKey];
            return {
                visitJobId: ans.visitJobId,
                optionId: ans.optionId,
                jobDefinitionId: ans.jobDefinationId,
                questionId: qIdKey,
                visitJobAnswer: ans.value
            };
        });
        console.log('payloadList:', payloadList);
        const wrapperString = JSON.stringify(payloadList);
        console.log('Survey payload:', wrapperString);
        console.log('this.recordId:', this.recordId);

        if (payloadList.length > 0) {
            this.saveAnswersQueue = this.saveAnswersQueue.then(async () => {
                this.isSuverySpinner = true;
                try {
                    const response = await createSurveyVisitJobs({ visitId: this.recordId, visitJobWrapper: wrapperString });
                    userAnswers = {};
                    console.log('Survey response:', response);
                    if (this.wireRefreshSurveyQuestionsData) {
                        await refreshApex(this.wireRefreshSurveyQuestionsData);
                    }
                } catch (error) {
                    console.error('Error submitting survey:', error);
                } finally {
                    // ALWAYS stop spinner
                    this.isSuverySpinner = false;
                }
            }).catch((error) => {
                this.isSuverySpinner = false;
                console.error('Error queuing survey update:', error);
            });

            await this.saveAnswersQueue;
        }

    }

    handleCameraAction() {
        // Programmatically click the hidden file input
        const fileInput = this.template.querySelector('.fileInput');
        if (fileInput) {
            fileInput.click();
        }
    }

    handleUploadClick(event) {
        const uploadContainer = event.currentTarget.closest('.upload-control');
        const fileInput = uploadContainer?.querySelector('.hidden-file-input');
        if (fileInput) {
            fileInput.click();
        }
    }

    setUploadedFileName(questionId, fileName) {
        this.uploadedFileNameByQuestionId = {
            ...this.uploadedFileNameByQuestionId,
            [questionId]: fileName || ''
        };
        this.surveyQuestions = this.surveyQuestions.map(group => ({
            ...group,
            items: group.items.map(item =>
                item.questionId === questionId
                    ? { ...item, fileName: fileName || '' }
                    : item
            )
        }));
    }

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const result = typeof reader.result === 'string' ? reader.result : '';
                const parts = result.split(',');
                const base64 = parts.length > 1 ? parts[1] : '';
                if (!base64) {
                    reject(new Error('Unable to read file data'));
                    return;
                }
                resolve(base64);
            };
            reader.onerror = () => reject(reader.error || new Error('Unable to read file'));
            reader.readAsDataURL(file);
        });
    }

    readFileAsDataUrl(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(typeof reader.result === 'string' ? reader.result : '');
            reader.onerror = () => reject(reader.error || new Error('Unable to read file'));
            reader.readAsDataURL(file);
        });
    }

    async compressImageFile(file, maxDimension = 1600, quality = 0.75) {
        const dataUrl = await this.readFileAsDataUrl(file);
        if (!dataUrl) {
            throw new Error('Unable to read image');
        }

        const image = await new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => resolve(img);
            img.onerror = () => reject(new Error('Unable to process image'));
            img.src = dataUrl;
        });

        let targetWidth = image.width;
        let targetHeight = image.height;
        const larger = Math.max(targetWidth, targetHeight);
        if (larger > maxDimension) {
            const scale = maxDimension / larger;
            targetWidth = Math.round(targetWidth * scale);
            targetHeight = Math.round(targetHeight * scale);
        }

        const canvas = document.createElement('canvas');
        canvas.width = targetWidth;
        canvas.height = targetHeight;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
            throw new Error('Canvas not supported on this browser');
        }
        ctx.drawImage(image, 0, 0, targetWidth, targetHeight);

        const compressedDataUrl = canvas.toDataURL('image/jpeg', quality);
        const parts = compressedDataUrl.split(',');
        const base64Data = parts.length > 1 ? parts[1] : '';
        if (!base64Data) {
            throw new Error('Unable to compress image');
        }

        const fileName = (file.name || 'survey-photo.jpg').replace(/\.[^.]+$/, '') + '.jpg';
        return {
            fileName,
            base64Data
        };
    }

    async buildSurveyFilePayload(file) {
        const isImage = (file.type || '').startsWith('image/');
        if (isImage) {
            return this.compressImageFile(file);
        }

        return {
            fileName: file.name,
            base64Data: await this.readFileAsBase64(file)
        };
    }

    sleep(ms) {
        return new Promise(resolve => window.setTimeout(resolve, ms));
    }

    isApexRateLimitError(error) {
        const message = (error?.body?.message || error?.message || '').toLowerCase();
        return message.includes('hit rate limit while running apex action')
            || message.includes('rate limit');
    }

    async createSurveyVisitJobsWithFileWithRetry(params, retries = 2) {
        let attempt = 0;
        let waitMs = 400;
        while (true) {
            try {
                return await createSurveyVisitJobsWithFile(params);
            } catch (error) {
                const shouldRetry = this.isApexRateLimitError(error) && attempt < retries;
                if (!shouldRetry) {
                    throw error;
                }
                await this.sleep(waitMs);
                waitMs = Math.min(waitMs * 2, 1600);
                attempt++;
            }
        }
    }

    async handleFileChange(event) {
        const file = event.target.files[0];
        if (!this.recordId) return;
        if (this.isSurveyFileUploadInProgress) {
            event.target.value = '';
            return;
        }
        if (file) {
            console.log('Selected file:', file.name);
            // TODO: Upload the file via Apex or directly to a ContentVersion endpoint
        }
        if (!file) return;
        //
        const qId = event.target.name;
        const value = event.target.value;
        let userAnswers = {};
        const allQuestions = this.surveyQuestions.flatMap(group => group.items);
        const question = allQuestions.find(q => q.questionId === qId);
        if (!question) return;
        const jobDefinationId = question.jobDefinationId;

        // Determine the actual answer
        let actualAnswer = '';
        let optionId = '';
        console.log('question....' + jobDefinationId);
        const selectedOption = question.options?.find(opt => opt.value === value);
        if (question.dataType === 'Toggle') {
            actualAnswer = selectedOption?.label || '';
        } else {
            // File input value contains a browser path, keep current survey answer.
            actualAnswer = question.visitJobAnswer || '';
        }

        optionId = selectedOption?.value || '';

        if (!userAnswers) {
            userAnswers = {};
        }

        userAnswers[qId] = {
            value: actualAnswer,
            optionId: optionId,
            dataType: question.dataType,
            visitJobId: question.visitJobId || '',
            jobDefinationId: question.jobDefinationId || ''
        };
        console.log('userAnswers[qId]:', userAnswers[qId]);

        const payloadList = Object.keys(userAnswers).map(qIdKey => {
            const ans = userAnswers[qIdKey];
            return {
                visitJobId: ans.visitJobId,
                optionId: ans.optionId,
                jobDefinitionId: ans.jobDefinationId,
                questionId: qIdKey,
                visitJobAnswer: ans.value
            };
        });
        console.log('payloadList:', payloadList);
        const wrapperString = JSON.stringify(payloadList);
        console.log('Survey payload:', wrapperString);
        console.log('this.recordId:', this.recordId);
        if (payloadList.length > 0) {
            this.isSuverySpinner = true;
            this.isSurveyFileUploadInProgress = true;
            try {
                const payload = await this.buildSurveyFilePayload(file);
                const response = await this.createSurveyVisitJobsWithFileWithRetry({
                    visitId: this.recordId,
                    visitJobWrapper: wrapperString,
                    fileName: payload.fileName,
                    base64Data: payload.base64Data
                });
                userAnswers = {};
                console.log('Survey response:', response);
                await refreshApex(this.wireRefreshSurveyQuestionsData);
            } catch (error) {
                console.error('Error submitting survey:', error);
            } finally {
                this.isSuverySpinner = false;
                this.isSurveyFileUploadInProgress = false;
                event.target.value = '';
            }
        }
    }

    ////
    @track fileData;
    @track imageUrl;

    async handleFileUpload(event) {
        const file = event.target.files[0];
        if (!this.recordId) return;
        if (this.isSurveyFileUploadInProgress) {
            event.target.value = '';
            return;
        }
        //
        const qId = event.target.name;
        if (file) {
            this.setUploadedFileName(qId, file.name);
        }
        const value = event.target.value;
        let userAnswers = {};
        const allQuestions = this.surveyQuestions.flatMap(group => group.items);
        const question = allQuestions.find(q => q.questionId === qId);
        if (!question) return;
        const jobDefinationId = question.jobDefinationId;

        // Determine the actual answer
        let actualAnswer = '';
        let optionId = '';
        console.log('question....' + jobDefinationId);
        const selectedOption = question.options?.find(opt => opt.value === value);
        if (question.dataType === 'Toggle') {
            actualAnswer = selectedOption?.label || '';
        } else {
            // File input value contains a browser path, keep current survey answer.
            actualAnswer = question.visitJobAnswer || '';
        }

        optionId = selectedOption?.value || '';

        if (!userAnswers) {
            userAnswers = {};
        }

        userAnswers[qId] = {
            value: actualAnswer,
            optionId: optionId,
            dataType: question.dataType,
            visitJobId: question.visitJobId || '',
            jobDefinationId: question.jobDefinationId || ''
        };
        console.log('userAnswers[qId]:', userAnswers[qId]);

        const payloadList = Object.keys(userAnswers).map(qIdKey => {
            const ans = userAnswers[qIdKey];
            return {
                visitJobId: ans.visitJobId,
                optionId: ans.optionId,
                jobDefinitionId: ans.jobDefinationId,
                questionId: qIdKey,
                visitJobAnswer: ans.value
            };
        });
        console.log('payloadList:', payloadList);
        const wrapperString = JSON.stringify(payloadList);
        console.log('Survey payload:', wrapperString);
        console.log('this.recordId:', this.recordId);
        if (file) {
            this.fileData = {
                name: file.name,
                size: file.size,
                type: file.type,
                base64: ''  // You'll need to handle base64 conversion here
            };
            if (payloadList.length > 0) {
                this.isSuverySpinner = true;
                this.isSurveyFileUploadInProgress = true;
                try {
                    const payload = await this.buildSurveyFilePayload(file);
                    this.fileData.name = payload.fileName;
                    this.fileData.base64 = payload.base64Data;
                    console.log('this.fileData:', this.fileData);
                    const response = await this.createSurveyVisitJobsWithFileWithRetry({
                        visitId: this.recordId,
                        visitJobWrapper: wrapperString,
                        fileName: payload.fileName,
                        base64Data: payload.base64Data
                    });
                    userAnswers = {};
                    console.log('Survey response:', response);
                    await refreshApex(this.wireRefreshSurveyQuestionsData);
                } catch (error) {
                    console.error('Error submitting survey:', error);
                } finally {
                    this.isSuverySpinner = false;
                    this.isSurveyFileUploadInProgress = false;
                    event.target.value = '';
                }
            }
        }
    }

    @track photoCaptured = false;
    @track photoSource = '';

    async handleTakePhoto() {

        try {
            const stream = await navigator.mediaDevices.getUserMedia({ video: true });
            const video = document.createElement('video');
            video.srcObject = stream;
            await video.play();

            const canvas = document.createElement('canvas');
            canvas.width = video.videoWidth || 640;
            canvas.height = video.videoHeight || 480;
            const context = canvas.getContext('2d');
            context.drawImage(video, 0, 0, canvas.width, canvas.height);
            this.photoSource = canvas.toDataURL('image/png');
            this.photoCaptured = true;
            stream.getTracks().forEach(track => track.stop());

        } catch (error) {
            console.error('Error accessing camera:', error);
        }
    }


}