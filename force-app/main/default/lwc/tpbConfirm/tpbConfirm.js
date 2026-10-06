import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class TpbConfirm extends LightningModal {
  @api content;
  @api labelYes = 'Yes';
  @api labelNo = 'No';

  handleYes() {
    this.close(true);
  }

  handleNo() {
    this.close(false);
  }
}