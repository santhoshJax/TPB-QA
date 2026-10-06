# TPB Pricing Data Flow — Complete Analysis

**Date:** 2026-06-11  
**Org:** TPB-QA (Sandbox — recently refreshed from Production)  
**Scope:** How product base pricing data flows from source through to the CGCloud offline app

---

## 1. Background / Original Question

A statement from another project claimed:

> *"The contracts currently use Product_Condition__c.Value__c for pricing (via System_Setting__c matching). Inventory__c is only used for stock availability — the contracts never read a price from it."*

**Finding for this org:** This statement is **incorrect for TPB**. This org does not use `Product_Condition__c.Value__c` for pricing at all. Pricing is driven by `cgcloud__Inventory__c.TPB_AvgPrice__c`, which flows into `cgcloud__CP_Pricing_Condition_Stage__c` and then into `cgcloud__CP_Pricing_Condition__c`. A search of all contracts confirmed `TPB_AvgPrice__c` is never referenced in contract logic.

---

## 2. Key Objects and Their Roles

| Object | Role |
|---|---|
| `cgcloud__Inventory__c` | Holds per-user/product/state pricing in `TPB_AvgPrice__c`. Also holds stock data. |
| `cgcloud__CP_Pricing_Condition_Stage__c` | Staging table. When `cgcloud__Status__c = 'n'`, CGCloud background engine picks it up and promotes to active Condition. |
| `cgcloud__CP_Pricing_Condition__c` | Active pricing table. This is what CGCloud contracts and the offline app read. |
| `cgcloud__CP_Pricing_Condition_Template__c` | Template named `BasePrice_ext` — identifies which pricing slot to use. |
| `cgcloud__CP_Key_Type__c` | `PS101` (no product group: State+User) and `PS102` (with product group: State+User+Category). |
| `Product2` | `cgcloud__Criterion_5_Product__c` is a self-referential lookup identifying the product's Price Group parent. `TPB_Exclude_From_Base_Pricing__c` flag excludes product from pricing. |
| `TPB_StateClassId__c` | Formula field on Inventory: `CASESAFEID(Product or ProductGroup) + State + CASESAFEID(User)` — upsert key for Stage records. |

---

## 3. Where Each Channel Reads the Price

| Channel | Reads From | Field |
|---|---|---|
| **Online Order Page (LWC)** | `cgcloud__Inventory__c` | `TPB_AvgPrice__c` directly |
| **CGCloud Offline App** | `cgcloud__CP_Pricing_Condition__c` | Promoted from Stage by CGCloud engine |
| **CGCloud Contracts** | `cgcloud__CP_Pricing_Condition__c` | Same as offline |

> **Important:** Manually editing `TPB_AvgPrice__c` on an Inventory record has **no automatic downstream effect** on the offline app or contracts. There is no trigger or record-triggered flow on Inventory UPDATE. The price only reaches `CP_Pricing_Condition__c` through the explicit automations listed below.

---

## 4. Complete Pricing Chain

```
Order Items (Van Load / Advanced)
        │
        ▼
[Batch Apex] TPB_UpdateInvPriceByOrderItemBatch
        │  Reads OrderItem.UnitPrice
        │  Applies UoM conversion (Each/Case/Carton)
        │  Max-price-wins per TPB_StateClassId__c
        │
        ▼
cgcloud__Inventory__c.TPB_AvgPrice__c  ◄── Also updated by Screen Flow / CSV Batch
        │
        ▼
[Apex] TPB_PricingUtility.upsertPricingConditionStage()
        │  Builds Stage records with Value__c and Status='n'
        │  Upserts on cgcloud__External_Id__c (= TPB_StateClassId__c)
        │
        ▼
cgcloud__CP_Pricing_Condition_Stage__c  (Status = 'n')
        │
        ▼
[CGCloud Background Engine — scheduled job]
        │  Reads Status='n' records
        │  Promotes to active pricing
        │
        ▼
cgcloud__CP_Pricing_Condition__c  (live pricing)
        │
        ▼
Offline App Sync  →  Device shows price from CP_Pricing_Condition__c
```

---

## 5. All Automations That Update Pricing

### 5.1 Batch Apex — Order-Driven Price Update (Primary / Automatic)

**Trigger:** Van Load orders activated (`RecordType=Van_Load`, `Status=Activated`, `TPB_Type__c=Purchase`)

**Flow:**
1. `TPB_UpdateInvPriceByOrderItemBatch` — reads `OrderItem.UnitPrice`, applies UoM conversion, picks max price per `TPB_StateClassId__c`, updates `Inventory.TPB_AvgPrice__c`, then calls `TPB_PricingUtility.upsertPricingConditionStage()`
2. `finish()` chains into `TPB_UpdateInvPriceByAdOrderItemBatch` — handles Advanced orders (`Phase=Released`, `Template=Return`), compares against Batch 1 prices, picks overall max, updates Inventory and Stage

**UoM Conversion Logic:**
- `ConsumerUnit` (Each): price ÷ carton pieces
- `Case`: price ÷ case size × carton pieces
- `Carton`: price used as-is

### 5.2 Screen Flow — Admin Manual Reset

**Name:** `TPB_User_Base_Price_Reset_Process`  
**Type:** Screen Flow (manually launched)  
**Access:** System Administrator or Junior System Administrator only

**Inputs:**
- Select User (lookup on `cgcloud__Inventory__c.CreatedById`)
- Select State (picklist from `Order.TPB_State__c`)
- Select Price Group (lookup on `Product2` via `cgcloud__Criterion_5_Product__c`) — see Section 6
- Input New Base Price (must be > 0)
- Reason (picklist from `TPB_CFund_Transaction__c.TPB_Reson__c`, default: "Pricing Data Entry Error")

**What it does:**
1. Queries all `cgcloud__Inventory__c` for selected User + State where `TPB_AvgPrice__c >= 0`
2. Loops and filters records matching: correct User + Price Group + not excluded + has State
3. Sets `TPB_AvgPrice__c = new base price` and `TPB_Reson__c = reason`
4. Bulk updates inventory records
5. Calls `TPB_PricingUtility` Apex (`strType='InventoryUpdate'`) → upserts Stage records with UoM-converted value

**Launch point:** Not found in retrieved metadata. Needs client clarification (likely a Quick Action or Lightning App Page not yet retrieved).

### 5.3 LWC CSV Upload Tool — Bulk Admin Reset

**Component:** `tpbUserBasePriceResetProcess`  
**Launch point:** Lightning Custom Tab named **"User Base Price Reset CSV"** (`User_Base_Price_Reset_CSV` tab, `lightning__Tab` target)

**Required CSV headers:** `UserId, TourState, PriceGroupId, NewBasePrice, Reason`

**What it does:**
1. Reads and validates CSV headers
2. Calls `TpbUserBasePriceResetProcessCtrl.fetchUserInventories()` to validate each row (checks inventory exists)
3. Shows preview table with "Inventory Exist" / error status per row
4. On "Process" click: calls `executeBatch()` → launches `TPB_UserBasePriceResetProcessBatch` (batch size 1)
5. Batch updates `Inventory.TPB_AvgPrice__c` from CSV `NewBasePrice`, then calls `TPB_PricingUtility.updatePricingConditionStage()` (`strType='InventoryUpdate'`)

**Access:** System Administrator profile only

### 5.4 Before-Insert Flow — Stamp Price on New CGCloud Inventory

**Name:** `TPB_BeforeInsert_Inventory_Update_Base_Price`  
**Type:** Record-Triggered Flow — Before Save — **CREATE only** (not update)  
**Object:** `cgcloud__Inventory__c`

**What it does:** When CGCloud offline creates a new Inventory record, this flow looks up an existing Inventory with the same `TPB_StateClassId__c` where `TPB_AvgPrice__c > 0`, and copies that price to the new record.

**Does NOT** call `TPB_PricingUtility` — does not push to Stage or Condition.

**Purpose:** Ensures new offline-created inventory records inherit the existing base price rather than starting at 0.

### 5.5 Product Exclude/Include Flow — Admin Product Flag Change

**Name:** `TPB_Product2_Update_Exclude_From_Base_Price`  
**Type:** Screen Flow — launched from Product record  
**Launch point:** Quick Action `Product2.TPB_Inclusivity_Base_Price_Calculation` ("Inclusivity Base Price Calculation")  
**Access:** System Administrator only

**What it does:**
- Shows Product Name + `TPB_Exclude_From_Base_Pricing__c` checkbox (pre-filled with current value)
- Only proceeds if the flag actually changed
- Queries ALL Inventory for that product (`cgcloud__User__c != null`, `TPB_Tour_State__c != null`)
- If newly **EXCLUDED** (false → true): sets `TPB_AvgPrice__c = null`
- If newly **INCLUDED** (true → false): sets `TPB_AvgPrice__c = 0`
- Calls `TPB_PricingUtility` (`strType='ProductUpdate'`, `boolCheck=new flag value`)
  - `boolCheck=false` (excluded): **DELETES** Stage and Condition records
  - `boolCheck=true` (included): sets `Value__c = 0` on Stage records
- Updates `Product2.TPB_Exclude_From_Base_Pricing__c`

### 5.6 Batch Schedule — Populate Tour on Offline Inventory

**Class:** `TBP_PopulateInventoryTourBatchSchedule`  
**Purpose:** Handles Inventory records created by CGCloud offline (where `cgcloud__Tour__c = null`, `Phase = Active`). Populates `cgcloud__Tour__c` and copies `TPB_AvgPrice__c` from an existing reference inventory record.

### 5.7 Inventory Trigger — INACTIVE (Dead Code)

**Trigger:** `TPB_InventoryTrigger` — fires `after update, after insert` on `cgcloud__Inventory__c`  
**Status:** Body is completely commented out. Does nothing.

**Handler:** `TPB_InventoryTriggerHandler.cls` — contains only `// TO be deleted`. Empty.

---

## 6. Understanding "Select Price Group"

In CGCloud, `Product2.cgcloud__Criterion_5_Product__c` is a **self-referential lookup** — individual products point to a parent Product2 record that acts as the price group/category.

**Example structure:**

| Individual Product | Criterion_5_Product__c (Price Group) |
|---|---|
| FRE POUCHES 330ml | → FRE POUCHES Group |
| FRE POUCHES 500ml | → FRE POUCHES Group |
| STOKERS TUBS NON PROMO | → Tobacco Group |

When "Select Price Group" is used in the Screen Flow or CSV tool, you are selecting one of these **parent Product2 records**. The automation then resets `TPB_AvgPrice__c` on ALL inventory records for that user+state where the product belongs to that group.

The `TPB_StateClassId__c` formula on Inventory reflects this:
```
IF(ISBLANK(Criterion_5_Product__c),
   CASESAFEID(Product__c),               ← PS101: no group
   CASESAFEID(Criterion_5_Product__c)    ← PS102: use group ID
) + TEXT(State) + CASESAFEID(User__c)
```

---

## 7. TPB_PricingUtility — Core Apex Class

**Class:** `TPB_PricingUtility.cls` (without sharing)

**Key constants:**
- `PRICING_CONDITION_TEMPLATES = 'BasePrice_ext'`
- `WITHOUT_CATEGORY = 'PS101'`
- `WITH_CATEGORY = 'PS102'`
- `SALES_ORG = '0001'`

**Key methods:**

| Method | Called By | Purpose |
|---|---|---|
| `inventoryBasePriceUpdate()` | Screen Flow, CSV Batch, Order Batch | Converts price by UoM then upserts Stage |
| `updatePricingStage()` | Product Exclude Flow | Zeros or deletes Stage/Condition for excluded products |
| `upsertPricingConditionStage()` | Order Batches directly | Main upsert — creates Stage records with Status='n' |
| `@InvocableMethod updatePricingConditionStage()` | All Flows | Flow entry point; routes to InventoryUpdate or ProductUpdate path |

**Stage record construction (on INSERT):**
- Currency: USD
- Denominator: 1
- Template: `BasePrice_ext`
- ValidFrom: today − 1 day
- ValidThru: today + 99 years
- Status: `'n'`
- Key_1: State
- Key_2: UserId
- KeyType: PS101 (no group) or PS102 (with group)

---

## 8. Test Execution — Screen Flow with Real Values

**Input values used:**
- User: `0053i00000398X2AAI`
- State: `KY`
- Price Group: `01t6T000006XZqIQAW` ("FRE POUCHES")
- New Base Price: `30`
- Reason: `test`

**Result: Success**

### Stage Query Result (after flow)

Only **one Stage record** was updated by this flow run:

| Record | Product | Value__c | Last Modified |
|---|---|---|---|
| PCS-0009510 | FRE POUCHES | **6** | 2026-06-11T13:00:27 ← today |
| PCS-0000820 | STOKERS CANS NON PROMO | 8 | 2026-06-02 |
| PCS-0016805 | FRE POUCHES POWERSET KDF | 146.25 | 2026-05-13 |
| PCS-0000819 | STOKERS TUBS NON PROMO | 38 | 2026-05-12 |
| *(others...)* | various | various | 2023–2025 |

**Why Value__c = 6 and not 30?**

`TPB_PricingUtility.inventoryBasePriceUpdate()` applies UoM conversion before writing to Stage:
```
30 (base price input) ÷ 5 (pieces per carton for FRE POUCHES) = 6
```
The offline app receives the per-unit price (6). The carton price (30) stays on `Inventory.TPB_AvgPrice__c`.

**Why only one product updated?**

Only one inventory record for this user in KY had `cgcloud__Product__r.cgcloud__Criterion_5_Product__c = '01t6T000006XZqIQAW'` and passed all filter conditions (not excluded, has state, AvgPrice >= 0).

### Condition Query Result

`cgcloud__CP_Pricing_Condition__c` records exist for this user/state with `Merged_Key` format:
```
ProductId + KY + UserId
```
These are the live pricing records the offline app reads on sync.

---

## 9. Key Observations and Open Questions

### Observation 1 — ALL Stage records have Status = 'n'

Every Stage record — including records dating back to **2023** — shows `cgcloud__Status__c = 'n'`. This is **after a sandbox refresh from Production**.

If Status='n' means "unprocessed/pending" and these records were created in 2023, they should have been processed long ago and their status changed. The fact that they are still 'n' in production data (copied via sandbox refresh) raises a question about how CGCloud actually handles this field.

**Two possible explanations:**

| Scenario | What it means |
|---|---|
| **A — CGCloud never changes Status** | Engine reads 'n' records and promotes to Condition but leaves Stage as 'n' permanently. 'n' is a persistent dirty flag, not a one-time trigger. |
| **B — CGCloud changes Status after processing** | Then all these 'n' records in production are genuinely unprocessed — but this contradicts the existence of active CP_Pricing_Condition__c records. |

**Scenario A is most likely** given that Condition records do exist. But client confirmation is needed.

### Observation 2 — CP_Pricing_Condition records exist but are dated weeks/months ago

Active Condition records exist with Merged_Keys matching Stage records, confirming CGCloud DID process Stage records at some point. However their `LastModifiedDate` is weeks/months old, suggesting the CGCloud engine may not be running in the sandbox since the refresh.

### Observation 3 — Screen Flow launch point not found in metadata

`TPB_User_Base_Price_Reset_Process` screen flow is not referenced in any retrieved metadata — no quick action, no flexipage, no tab points to it. The launch configuration may not have been deployed to source control.

### Observation 4 — Inventory Trigger is dead code

`TPB_InventoryTrigger` fires `after update, after insert` but its body is 100% commented out. The handler class has only `// TO be deleted`. This trigger serves no purpose.

### Observation 5 — Manual Inventory edits do not propagate automatically

If an admin manually edits `Inventory.TPB_AvgPrice__c` directly in Salesforce UI, **nothing automatically pushes that change to CP_Pricing_Condition__c**. The trigger is dead and there is no record-triggered flow on Inventory UPDATE. The Before Save flow only runs on CREATE.

This means a manual edit will show on the online order page (LWC reads directly) but will NOT reach the offline app until one of the official admin tools is used.

---

## 10. Questions for Client

| # | Question | Context |
|---|---|---|
| Q1 | Does `cgcloud__CP_Pricing_Condition_Stage__c.cgcloud__Status__c` stay `'n'` after the CGCloud engine processes it, or does it change to another value? | All records show 'n' including ones from 2023. Need to know if this is expected. |
| Q2 | Is the CGCloud pricing background scheduled job configured and running in this sandbox after the refresh? | Condition records exist but are weeks/months old. The Stage-to-Condition promotion may not be running in sandbox. |
| Q3 | Where is the `TPB_User_Base_Price_Reset_Process` screen flow launched from in the UI? | Not found in any retrieved metadata. Check via Setup → Flows → row dropdown → "Where is this used?" |
| Q4 | Is `TPB_InventoryTrigger` safe to delete? Was it intentionally disabled? | Body is completely commented out, handler has `// TO be deleted`. |
| Q5 | Is there a plan to implement logic on Inventory UPDATE? | Currently no automation fires when `TPB_AvgPrice__c` is manually changed. Admins may not realize their direct edits don't reach the offline app. |

---

## 11. Summary — Who Updates What

| Trigger | Updates Inventory | Updates Stage/Condition |
|---|---|---|
| Van Load order activated | ✓ via Batch 1 + 2 | ✓ via TPB_PricingUtility |
| Admin runs Screen Flow | ✓ | ✓ via TPB_PricingUtility |
| Admin uploads CSV via LWC tab | ✓ | ✓ via TPB_PricingUtility |
| Product excluded/included (Quick Action on Product) | ✓ (null or 0) | ✓ (delete or zero) |
| New Inventory created by offline app | ✓ (copies existing price) | ✗ |
| Manual direct edit in Salesforce UI | ✓ only | ✗ does NOT propagate |
| Inventory Trigger (after update/insert) | — | — (dead, commented out) |

---

## 12. Files Referenced

| File | Purpose |
|---|---|
| [classes/TPB_PricingUtility.cls](force-app/main/default/classes/TPB_PricingUtility.cls) | Core pricing utility — UoM conversion, Stage upsert |
| [classes/TPB_UpdateInvPriceByOrderItemBatch.cls](force-app/main/default/classes/TPB_UpdateInvPriceByOrderItemBatch.cls) | Batch 1 — Van Load order price update |
| [classes/TPB_UpdateInvPriceByAdOrderItemBatch.cls](force-app/main/default/classes/TPB_UpdateInvPriceByAdOrderItemBatch.cls) | Batch 2 — Advanced order price update |
| [classes/TPB_UserBasePriceResetProcessBatch.cls](force-app/main/default/classes/TPB_UserBasePriceResetProcessBatch.cls) | Batch for CSV upload tool |
| [classes/TpbUserBasePriceResetProcessCtrl.cls](force-app/main/default/classes/TpbUserBasePriceResetProcessCtrl.cls) | Controller for CSV LWC |
| [classes/TPB_InventoryService.cls](force-app/main/default/classes/TPB_InventoryService.cls) | Creates inventory from wholesale orders |
| [classes/TBP_PopulateInventoryTourBatchSchedule.cls](force-app/main/default/classes/TBP_PopulateInventoryTourBatchSchedule.cls) | Populates Tour on offline-created inventory |
| [classes/TPB_OnlineAppController.cls](force-app/main/default/classes/TPB_OnlineAppController.cls) | Online order page — reads TPB_AvgPrice__c directly |
| [flows/TPB_BeforeInsert_Inventory_Update_Base_Price.flow-meta.xml](force-app/main/default/flows/TPB_BeforeInsert_Inventory_Update_Base_Price.flow-meta.xml) | Before-save flow on Inventory CREATE |
| [flows/TPB_User_Base_Price_Reset_Process.flow-meta.xml](force-app/main/default/flows/TPB_User_Base_Price_Reset_Process.flow-meta.xml) | Admin Screen Flow — manual price reset |
| [flows/TPB_Product2_Update_Exclude_From_Base_Price.flow-meta.xml](force-app/main/default/flows/TPB_Product2_Update_Exclude_From_Base_Price.flow-meta.xml) | Admin Screen Flow — exclude/include product |
| [lwc/tpbUserBasePriceResetProcess/](force-app/main/default/lwc/tpbUserBasePriceResetProcess/) | CSV upload LWC tool |
| [tabs/User_Base_Price_Reset_CSV.tab-meta.xml](force-app/main/default/tabs/User_Base_Price_Reset_CSV.tab-meta.xml) | Lightning Tab wrapping the CSV LWC |
| [quickActions/Product2.TPB_Inclusivity_Base_Price_Calculation.quickAction-meta.xml](force-app/main/default/quickActions/Product2.TPB_Inclusivity_Base_Price_Calculation.quickAction-meta.xml) | Quick Action launching Product exclude flow |
| [triggers/TPB_InventoryTrigger.trigger](force-app/main/default/triggers/TPB_InventoryTrigger.trigger) | Dead trigger — body commented out |
