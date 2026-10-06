/**
 * @author Mi Li
 * @date 3/10/2023
 * @description TPB_UoMGenerateScriptBatch test class
 *  Standard order type
    products will come from TSM van
    Business decision on 2/15 demo to remove discount field in the AC
    Must be in an active visit to create an order of this type
    Order type = Cash Sale
    Total is automatically updated based on unit price, quantity, and any discount applied
    End-of-visit distribution will reflect any updates from this order
    If product was 'OOS' at the beginning of the visit but was ordered during the visit, it should be marked as 'In Distribution' for end-of-visit distribution
    Price of product needs to be > $0.00 on the line item level in order in order for "OOS" to be toggled to "Distributed" on EOV
 */

public class TPB_UoMGenerateScriptBatchTest {
  
}