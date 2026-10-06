export { reduceErrors } from './reduceErrors';
export { OrderRecordElement } from './orderRecordElement';
export * from './orderUtils';

export function sleep(ms = 0) {
  return new Promise((resolve) => {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(resolve, ms);
  });
}

export function nextId() {
  return Array.from(new Array(32), () =>
    String.fromCharCode(
      'a'.charCodeAt(0) + (Math.floor(Math.random() * 26) % 26)
    )
  ).join('');
}

export function formatUSD(number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(number);
}