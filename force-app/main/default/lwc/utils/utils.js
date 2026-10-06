import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const showToast = (message, variant, mode) => {
     return new ShowToastEvent({
        'message': message,
        'variant': variant,
        'mode': mode
    });
}

export {showToast};