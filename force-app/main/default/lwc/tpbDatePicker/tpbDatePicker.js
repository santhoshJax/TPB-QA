import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import MOMENT_JS from '@salesforce/resourceUrl/moment';

export default class TpbDatePicker extends LightningElement {
    momentJS;
    momentJSInitialized = false;
    lastClass;
    @track dateContext;
    @track selectedDate;
    @track dates = [];
    @api selectedDatesList = [];
    renderedCallback() {
        if (this.momentJSInitialized) {
            return;
        }
        this.momentJSInitialized = true;  // Set to avoid multiple loads
        loadScript(this, MOMENT_JS)
            .then(() => {
                this.momentJS = window.moment; // Use a local variable instead of window.moment
                this.initializeDates();
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.error("Error loading moment.js", error);
                throw new Error("Error loading moment.js");
            });
    }

    initializeDates() {
        this.dateContext = this.momentJS().clone();
        this.selectedDate = this.momentJS().clone();
        this.refreshDateNodes();
    }

    get formattedSelectedDate() {
        return this.selectedDate ? this.selectedDate.format('YYYY-MM-DD') : '';
    }
    get year() {
        return this.dateContext ? this.dateContext.format('Y') : '';
    }
    get month() {
        return this.dateContext ? this.dateContext.format('MMMM') : '';
    }
    previousMonth() {
        if (this.momentJSInitialized) {
            this.dateContext = window.moment(this.dateContext).subtract(1, 'month');
            this.refreshDateNodes();
        }
    }
    nextMonth() {
        if (this.momentJSInitialized) {
            this.dateContext = window.moment(this.dateContext).add(1, 'month');
            this.refreshDateNodes();
        }
    }
    // goToday() {
    //     if (this.momentJSInitialized) {
    //         this.selectedDate = window.today;
    //         this.dateContext = window.today;
    //         this.refreshDateNodes();
    //     }
    // }
    @api
    // setSelected(e) {
    //     if (this.momentJSInitialized) {
    //         const selectedDate = this.template.querySelector('.selected');
    //         if (selectedDate) {
    //             selectedDate.className = this.lastClass;
    //         }
    //         const { date } = e.target.dataset;
    //         this.selectedDate = window.moment(date);
    //         this.dateContext = window.moment(date);
    //         this.lastClass = e.target.className;
    //         e.target.className = 'selected';
    //     }
    // }
    setSelected(e) {
        if (this.momentJSInitialized) {
            const { date } = e.target.dataset;
            const dateIndex = this.selectedDatesList.indexOf(date);

            if (dateIndex === -1) {
                // Date is not in the list, add it
                this.selectedDatesList.push(date);
                e.target.className = 'selected';
            } else {
                // Date is already in the list, remove it
                this.selectedDatesList.splice(dateIndex, 1);
                e.target.className = 'date'; // or any other default class you want
            }
        }
    }
    get listOfSelectedDates() {
        return this.selectedDatesList.join(', ');
    }


    refreshDateNodes() {
        if (this.momentJSInitialized) {
            this.dates = [];
            const monthStart = this.dateContext.clone().startOf('month');
            const monthEnd = this.dateContext.clone().endOf('month');
            // Build grid from the first visible week to the last, without isoWeek year rollover
            const gridStart = monthStart.clone().startOf('week');
            const gridEnd = monthEnd.clone().endOf('week');
            const totalDays = gridEnd.diff(gridStart, 'days') + 1; // inclusive
            const numWeeks = Math.ceil(totalDays / 7);

            for (let week = 0; week < numWeeks; week++) {
                Array(7)
                    .fill(0)
                    .forEach((n, i) => {
                        const day = gridStart.clone().add(week * 7 + i, 'day');
                        let className = '';
                        if (day.month() === this.dateContext.month()) {
                            if (day.isSame(window.today, 'day')) {
                                className = 'today';
                            } else if (day.isSame(this.selectedDate, 'day')) {
                                className = 'selected';
                            } else {
                                className = 'date';
                            }
                        } else {
                            className = 'padder';
                        }
                        this.dates.push({
                            className,
                            formatted: day.format('YYYY-MM-DD'),
                            text: day.format('DD')
                        });
                    });
            }
        }
    }


}