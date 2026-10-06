import { LightningElement, api } from 'lwc';
import { nextId } from 'c/tpbUtils';

export const CodeType = Object.freeze({
  BARCODE: 'BARCODE'
});

export const ScanStatus = Object.freeze({
  IDLE: 'IDLE',
  WORKING: 'WORKING'
});

export const ScanEvents = Object.freeze({
  SOMEONE_TURN_ON: 'someoneturnon'
});

export default class TpbBarcodeScanButton extends LightningElement {
  _disabled = false;
  @api get disabled() {
    return this._disabled;
  }
  set disabled(value) {
    this._disabled = !!value;
  }

  @api autoTurnOff = false;

  _componentId = '';

  scanStatus = ScanStatus.IDLE;
  value = '';

  get buttonInfo() {
    switch (this.scanStatus) {
      case ScanStatus.IDLE: {
        return {
          label: 'Start Scan',
          variant: 'neutral'
        };
      }
      case ScanStatus.WORKING:
      default: {
        return {
          label: 'Scanning / Stop Scan',
          variant: 'success'
        };
      }
    }
  }

  connectedCallback() {
    this._componentId = nextId();
    this.handleKeypress = this.handleKeypress.bind(this);
    this.handleOtherTurnOn = this.handleOtherTurnOn.bind(this);

    // add event handlers
    document.addEventListener(
      ScanEvents.SOMEONE_TURN_ON,
      this.handleOtherTurnOn
    );
  }

  disconnectedCallback() {
    // remove event handlers
    document.removeEventListener(
      ScanEvents.SOMEONE_TURN_ON,
      this.handleOtherTurnOn
    );

    this.turnOff();
  }

  handleKeypress = (event) => {
    if (this.scanStatus === ScanStatus.WORKING) {
      event.preventDefault();

      if (
        event.charCode === '>'.charCodeAt(0) ||
        event.charCode === '》'.charCodeAt(0)
      ) {
        // when '>' 62 or '》' 12299
        this.value = '';
      } else if (
        event.charCode === '\r'.charCodeAt(0) ||
        event.charCode === '\n'.charCodeAt(0) ||
        event.code === 'Enter'
      ) {
        // when '\r' 13
        const code = this.value.trim();

        if (code === '') {
          return;
        }

        // In case of no configured prefix for the scanner,
        // let's reset the code for next scanning manually
        this.value = '';

        this.dispatchEvent(
          new CustomEvent('scan', {
            detail: {
              type: CodeType.BARCODE,
              code
            },
            cancelable: true
          })
        );

        // turn off the button for one time working,
        // and we cannot implement a prevent default function
        // since the event handler could be async or promise.
        if (this.autoTurnOff) {
          this.turnOff();
        }
      } else {
        this.value += String.fromCharCode(event.charCode);
      }
    }
  };

  get isTurnOn() {
    return this.scanStatus === ScanStatus.WORKING;
  }

  get isTurnOff() {
    return this.scanStatus === ScanStatus.IDLE;
  }

  turnOn() {
    // reset the value when reusing the scanner gun
    this.value = '';

    // turn on the status and ready for scannings
    this.scanStatus = ScanStatus.WORKING;
    document.addEventListener('keypress', this.handleKeypress);

    // telling other buttons of scan to turn off themselves
    document.dispatchEvent(
      new CustomEvent(ScanEvents.SOMEONE_TURN_ON, {
        detail: { componentId: this._componentId }
      })
    );
  }

  turnOff() {
    this.scanStatus = ScanStatus.IDLE;
    document.removeEventListener('keypress', this.handleKeypress);
  }

  async handleScan(event) {
    event.preventDefault();
    event.target.blur();

    if (this.isTurnOff) {
      this.turnOn();
    } else {
      this.turnOff();
    }
  }

  handleOtherTurnOn = (event) => {
    const { componentId } = event.detail;

    if (componentId !== this._componentId) {
      this.turnOff();
    }
  };
}