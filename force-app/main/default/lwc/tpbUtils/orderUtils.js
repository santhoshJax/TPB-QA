export function getOrderItemsSubtotal(items) {
  return yuan(
    items.reduce((subtotal, orderItem) => {
      return subtotal + fen(orderItem.unitPrice) * orderItem.quantity;
    }, 0)
  );
}

export function fen(origYuan) {
  return origYuan * 100;
}

export function yuan(origFen) {
  return origFen / 100;
}