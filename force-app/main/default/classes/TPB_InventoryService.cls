/**
 * @author Feng Lian
 * @date 6/25/2023
 * @description TPB_InventoryService
 */
public class TPB_InventoryService {
  //Order Item Type: Purchase
  private static final String WHOLESALERPURCHASE = 'Purchase';
  //Order Item Unit: Each
  private static final String ORDEREACHTYPE = 'Each';
  //UoM: Each
  private static final String UOMEACH = 'ConsumerUnit';
  //Order Item Unit: Carton
  private static final String ORDERCARTONTYPE = 'Carton';
  //UoM: Carton
  private static final String UOMCARTON = 'SalesUnit';
  //Order Item Unit: Case
  private static final String ORDERCASETYPE = 'Case';
  //UoM: Case
  private static final String UOMCASE = 'Layer';

  /**
   * @description createInventory
   * @param  items   List<OrderItem>
   */
  public static void createInventory(List<OrderItem> items) {
    Set<Id> productSet = new Set<Id>();
    Map<String, cgcloud__Inventory__c> invMap = new Map<String, cgcloud__Inventory__c>();
    Map<String, cgcloud__Tour__c> tourMap = new Map<String, cgcloud__Tour__c>();
    Map<String, List<cgcloud__Unit_of_Measure__c>> uomMap = new Map<String, List<cgcloud__Unit_of_Measure__c>>();
    Map<String, cgcloud__Inventory__c> newInvMap = new Map<String, cgcloud__Inventory__c>();
    List<cgcloud__Inventory_Transaction__c> transList = new List<cgcloud__Inventory_Transaction__c>();
    Map<String, List<cgcloud__Inventory_Transaction__c>> newTransMap = new Map<String, List<cgcloud__Inventory_Transaction__c>>();
    List<cgcloud__Inventory_Transaction__c> deletedTrans = new List<cgcloud__Inventory_Transaction__c>();

    for (OrderItem item : items) {
      String mergedKey =
        item.Product2Id +
        '+' +
        item.Order.TPB_State__c +
        '+' +
        item.Order.CreatedById;
      productSet.add(item.Product2Id);
      invMap.put(mergedKey, null);
      tourMap.put(item.Order.TPB_State__c, null);
    }

    List<cgcloud__Inventory_Transaction__c> existingTrans = [
      SELECT TPB_Wholesale_Order_Item__c, cgcloud__Amount__c
      FROM cgcloud__Inventory_Transaction__c
      WHERE TPB_Wholesale_Order_Item__c IN :items
    ];

    Map<Id, cgcloud__Inventory_Transaction__c> existingTransMap = new Map<Id, cgcloud__Inventory_Transaction__c>();
    for (cgcloud__Inventory_Transaction__c trans : existingTrans) {
      existingTransMap.put(trans.TPB_Wholesale_Order_Item__c, trans);
    }

    List<cgcloud__Tour__c> tours = [
      SELECT cgcloud__Start_Warehouse__r.cgcloud__State__c
      FROM cgcloud__Tour__c
      WHERE cgcloud__Start_Warehouse__r.cgcloud__State__c IN :tourMap.keySet()
    ];
    tourMap.clear();
    for (cgcloud__Tour__c tour : tours) {
      tourMap.put(tour.cgcloud__Start_Warehouse__r.cgcloud__State__c, tour);
    }

    List<cgcloud__Inventory_Control_Template__c> invTemplates = [
      SELECT Id
      FROM cgcloud__Inventory_Control_Template__c
      WHERE Name = 'TPB Control Template' AND cgcloud__Active__c = TRUE
      LIMIT 1
    ];

    List<cgcloud__Inventory_Transaction_Template__c> invTransTemplates = [
      SELECT Id
      FROM cgcloud__Inventory_Transaction_Template__c
      WHERE
        Name IN (
          'TPB Transaction Template (Cashsale)',
          'TPB Transaction Template (Add)'
        )
        AND cgcloud__Active__c = TRUE
      ORDER BY Name
      LIMIT 2
    ];

    List<cgcloud__Unit_of_Measure__c> uoms = [
      SELECT
        cgcloud__Product__c,
        cgcloud__Unit_Type__c,
        cgcloud__Pieces_per_Smallest_Unit__c
      FROM cgcloud__Unit_of_Measure__c
      WHERE cgcloud__Product__c IN :productSet
    ];
    for (cgcloud__Unit_of_Measure__c uom : uoms) {
      if (!uomMap.containsKey(uom.cgcloud__Product__c)) {
        uomMap.put(
          uom.cgcloud__Product__c,
          new List<cgcloud__Unit_of_Measure__c>()
        );
      }
      uomMap.get(uom.cgcloud__Product__c).add(uom);
    }

    List<cgcloud__Inventory__c> inventories = [
      SELECT cgcloud__Product__c, TPB_PricingMergedKey__c
      FROM cgcloud__Inventory__c
      WHERE TPB_PricingMergedKey__c IN :invMap.keySet()
    ];

    invMap.clear();
    for (cgcloud__Inventory__c inv : inventories) {
      invMap.put(inv.TPB_PricingMergedKey__c, inv);
    }

    for (OrderItem item : (List<OrderItem>) items) {
      String mergedKey =
        item.Product2Id +
        '+' +
        item.Order.TPB_State__c +
        '+' +
        item.Order.CreatedById;
      Decimal quantity;
      Decimal numEachCarton;
      Decimal numEachCase;
      String transTemplateId = item.TPB_Type__c == WHOLESALERPURCHASE
        ? invTransTemplates[0].Id
        : invTransTemplates[1].Id;

      List<cgcloud__Unit_of_Measure__c> uomList = uomMap.get(item.Product2Id);
      for (cgcloud__Unit_of_Measure__c uom : uomList) {
        //Store current product UoM unit price
        if (uom.cgcloud__Unit_Type__c == UOMCARTON) {
          numEachCarton = uom.cgcloud__Pieces_per_Smallest_Unit__c;
        } else if (uom.cgcloud__Unit_Type__c == UOMCASE) {
          numEachCase = uom.cgcloud__Pieces_per_Smallest_Unit__c;
        }
      }

      quantity = item.Quantity;

      if (item.UoM__c == ORDEREACHTYPE) {
        quantity = item.Quantity / numEachCarton;
      } else if (item.UoM__c == ORDERCASETYPE) {
        quantity = item.Quantity * (numEachCase / numEachCarton);
      }

      quantity = quantity * (item.TPB_Type__c == WHOLESALERPURCHASE ? 1 : -1);
      cgcloud__Inventory__c inv = invMap.get(mergedKey);

      if (inv == null) {
        inv = newInvMap.get(mergedKey);
      }

      if (inv == null) {
        inv = new cgcloud__Inventory__c(
          cgcloud__Description_Language_1__c = 'New inventory from flow'
        );
        inv.cgcloud__Inventory_Template__c = invTemplates[0].Id;
        inv.cgcloud__Phase__c = 'Active';
        inv.cgcloud__Product__c = item.Product2Id;
        inv.cgcloud__Sales_Org__c = '0001';
        inv.cgcloud__Valid_From__c = Date.newInstance(2023, 6, 1);
        inv.cgcloud__Valid_Thru__c = Date.newInstance(2099, 12, 31);
        inv.cgcloud__User__c = item.Order.CreatedById;
        inv.cgcloud__Tour__c = tourMap.get(item.Order.TPB_State__c).Id;
        inv.TPB_AvgPrice__c = item.Product2.TPB_Exclude_From_Base_Pricing__c ==
          true
          ? null
          : 0;
        newInvMap.put(mergedKey, inv);
      }

      cgcloud__Inventory_Transaction__c trans = existingTransMap.get(item.Id);

      if (trans == null || trans.cgcloud__Amount__c != quantity) {
        if (trans != null) {
          deletedTrans.add(trans);
        }

        trans = new cgcloud__Inventory_Transaction__c();
        trans.TPB_Wholesale_Order_Item__c = item.Id;
        trans.cgcloud__Amount__c = quantity;
        trans.cgcloud__Inventory_Transaction_Template__c = transTemplateId;
        trans.cgcloud__Inventory__c = inv.Id;

        if (trans.cgcloud__Inventory__c != null) {
          transList.add(trans);
        } else {
          List<cgcloud__Inventory_Transaction__c> transactionList = newTransMap.get(
            mergedKey
          );

          if (transactionList == null) {
            transactionList = new List<cgcloud__Inventory_Transaction__c>();
            newTransMap.put(mergedKey, transactionList);
          }

          transactionList.add(trans);
        }
      }
    }

    if (deletedTrans.size() > 0) {
      delete deletedTrans;
    }

    if (newInvMap.size() > 0) {
      insert newInvMap.values();
    }

    if (newTransMap.size() > 0) {
      for (String key : newTransMap.keySet()) {
        cgcloud__Inventory__c inv = newInvMap.get(key);
        List<cgcloud__Inventory_Transaction__c> transactionList = newTransMap.get(
          key
        );
        for (cgcloud__Inventory_Transaction__c trans : transactionList) {
          trans.cgcloud__Inventory__c = inv.Id;
          transList.add(trans);
        }
      }
    }

    if (transList.size() > 0) {
      insert transList;
    }
  }
}