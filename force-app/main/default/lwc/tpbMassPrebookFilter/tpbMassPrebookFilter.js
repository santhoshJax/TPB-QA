import { LightningElement, track, api } from 'lwc';

const FilterAll = Object.freeze({
  name: 'All',
  label: 'All',
  value: null
});

export default class TpbMassPrebookFilter extends LightningElement {
  @api filterCriteria = [];

  @track value = {};

  get filters() {
    return this.filterCriteria.map((filter) => {
      let value = this.value[filter.name];

      if (typeof value === 'undefined') {
        value = FilterAll.value;
      }

      return {
        ...filter,
        options: filter.options ? [FilterAll, ...filter.options] : [],
        value: value,
        onChange(event) {
          this.setValue(filter.name, event.detail.value);
          this.triggerChange();
        }
      };
    });
  }

  setValue(name, value) {
    this.value[name] = value;
  }

  getValue(name) {
    // return the real value of field by name
    return this.value[name];
  }

  triggerChange() {
    const result = [];

    Object.keys(this.value).forEach((filedName) => {
      const filterValue = this.getValue(filedName);

      if (
        typeof filterValue !== 'undefined' &&
        filterValue !== FilterAll.value
      ) {
        result.push({
          field: filedName,
          value: this.getValue(filedName),
          op: 'EQ'
        });
      }
    });

    this.dispatchEvent(
      new CustomEvent('select', {
        detail: result
      })
    );
  }
}