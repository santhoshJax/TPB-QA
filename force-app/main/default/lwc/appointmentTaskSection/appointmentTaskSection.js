import {LightningElement,api,track} from 'lwc';
import getTasks from '@salesforce/apex/AppointmentTaskSection.getTasks';
import completeTask from '@salesforce/apex/AppointmentTaskSection.completeTask';
import {showToast} from 'c/utils';

export default class AppointmentTaskSection extends LightningElement {
    @api accId;
    spinner = false;
    @track tasks;

    connectedCallback() {
        this.tasks = {
            open: [],
            completed: []
        }
        this.spinner = true;
        this.init();
    }

    async init() {
        try {
            let tasks = await getTasks({'accountId' : this.accId});
            let openTasks = [];
            let completedTasks = [];

            for(let i=0; i < tasks.length; i++) {
                if(tasks[i].IsClosed !== true) {
                    openTasks.push(tasks[i]);
                }
                else {
                    completedTasks.push(tasks[i]);
                }
            }

            this.tasks.open = openTasks;
            this.tasks.completed = completedTasks;
        }
        catch(error) {
            console.log(error);
        }
        finally {
            this.spinner = false;
        }
    }

    updateTask(event) {
        const index = event.target.dataset.index;
        let task = this.tasks.open[index];
        
        task.Description = event.target.value;
        this.tasks.open[index] = task;
    }

    completeTask(event) {
        this.spinner = true;
        const index = event.target.dataset.index;
        let task = this.tasks.open[index];

        completeTask({'taskRecord': task})
        .then(result => {
            if(result !== true) {
                this.showToast(result, 'error', 'dismissable');
                this.spinner = false;
            }
            else {
                this.showToast('Task completed', 'success', 'dismissable');
                this.init();
            }
        })
        .catch(error => {
            this.showToast(error, 'error', 'dismissable');
        });
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