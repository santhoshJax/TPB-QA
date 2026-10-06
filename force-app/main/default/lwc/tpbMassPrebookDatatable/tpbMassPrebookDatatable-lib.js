export const COLUMNS = [
  { fieldName: 'accountNumber', label: 'Account #' },
  { fieldName: 'accountName', label: 'Account Name' },
  { fieldName: 'storeNumber', label: 'Store #' },
  { fieldName: 'address', label: 'Address' },
  { fieldName: 'city', label: 'City' },
  { fieldName: 'state', label: 'State' },
  { fieldName: 'zip', label: 'Zip' },
  { fieldName: 'wholesalerNumber', label: 'Wholesaler #' },
  { fieldName: 'ntcCustomerNumber', label: 'NTC Customer #' },
  { fieldName: 'wholesalerName', label: 'Wholesaler Name' },
  { fieldName: 'wholesaleCustomer', label: 'Wholesaler Customer #' },
  { fieldName: 'brandUPW', label: 'Brand UPW' },
  { fieldName: 'qtyPlanned', label: 'QTY Planned' },
  { fieldName: 'qtyMax', label: 'Max Quantity' },
  { fieldName: 'qtyOrdered', label: 'Qty Ordered' },
  { fieldName: 'qtyRemaining', label: 'Qty Remaining' }
]; // level 1

export const INNER_COLUMNS = [
  { fieldName: 'itemName', label: 'Item Name', initialWidth: 250 },
  { fieldName: 'ntcItemNumber', label: 'NTC Item #', initialWidth: 90 },
  {
    fieldName: 'wholesalerItemNumber',
    label: 'Wholesaler Item #',
    initialWidth: 138
  },
  { fieldName: 'qtyPlanned', label: 'QTY Planned', initialWidth: 128 },
  { fieldName: 'qtyMax', label: 'Max Quantity', initialWidth: 128 },
  {
    fieldName: 'qtyOrdered',
    label: 'Qty Ordered',
    initialWidth: 128,
    editable: true
  },
  { fieldName: 'qtyRemaining', label: 'Qty Remaining', initialWidth: 128 }
]; // level 2

function getStyleVal(el, css) {
  return window.getComputedStyle(el).getPropertyValue(css);
}

function paddingDiff(col) {
  if (getStyleVal(col, 'box-sizing') === 'border-box') {
    return 0;
  }

  const padLeft = getStyleVal(col, 'padding-left');
  const padRight = getStyleVal(col, 'padding-right');
  return parseInt(padLeft, 10) + parseInt(padRight, 10);
}

export function setResizingDivListener(div) {
  let pageX, curCol, /* nxtCol, */ curColWidth /*, nxtColWidth*/;

  div.addEventListener('mousedown', function (e) {
    curCol = e.target.parentElement;
    while (curCol?.tagName && !['TH', 'TD'].includes(curCol.tagName)) {
      curCol = curCol.parentElement;
    }

    // Begin of "no adjustment to the next sibling"
    // nxtCol = curCol.nextElementSibling;
    // End of "no adjustment to the next sibling"
    pageX = e.pageX;

    const padding = paddingDiff(curCol);

    curColWidth = curCol.offsetWidth - padding;

    // Begin of "no adjustment to the next sibling"
    // if (nxtCol) {
    //   nxtColWidth = nxtCol.offsetWidth - padding;
    // }
    // End of "no adjustment to the next sibling"
  });

  document.addEventListener('mousemove', function (e) {
    if (curCol) {
      const diffX = e.pageX - pageX;

      curCol.style.width = curColWidth + diffX + 'px';
      curCol.firstChild.style.width = curCol.style.width; // first child is A tag and its width is the TH width actually

      // Begin of "no adjustment to the next sibling"
      //   if (nxtCol) {
      //     nxtCol.style.width = nxtColWidth - diffX + 'px';
      //     nxtCol.firstChild.style.width = nxtCol.style.width; // first child is A tag and its width is the TH width actually
      //   }
      // End of "no adjustment to the next sibling"
    }
  });

  document.addEventListener('mouseup', function () {
    pageX = undefined;
    curCol = undefined;
    // Begin of "no adjustment to the next sibling"
    // nxtCol = undefined;
    // nxtColWidth = undefined;
    // End of "no adjustment to the next sibling"
    curColWidth = undefined;
  });
}