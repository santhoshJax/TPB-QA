# TPB Online App — Technical Documentation

**Date:** 2026-07-01  
**Scope:** All cgCloud-prefixed LWC components, their Apex controllers, and how they connect to each other  
**Project:** TPB-QA Salesforce CGCloud Implementation

---

## 1. Architecture Overview

The TPB Online App is a custom Salesforce Lightning Web Component suite built on top of CGCloud (Consumer Goods Cloud). It replaces the CGCloud native offline mobile app for online order taking and visit management.

```
cgCloudonlineApptpb (shell/entry point)
        │
        ├── cgCloudUserCockpit         ← User home: visit list, tasks, dashboard
        │       └── cgCloudVisitsList  ← Today's visits: create, cancel, navigate
        │
        └── cgCloudStoreCockpit        ← Per-visit hub: start/end, order, distribution
                ├── cgCloudOrderPage       ← Order entry (main screen)
                │       ├── cgCloudBarcodeScanner
                │       ├── cgCloudTPBPromoPrebook
                │       └── cgCloudMultiselectPicklist
                ├── cgCloudReviewOrderPage ← Order review & completion
                ├── cgCloudProductDistribution ← Distribution status management
                │       └── cgCloudBarcodeScanner
                ├── cgCloudDistributedItems    ← Order lines for Distributed products
                ├── cgCloudOOSOrderItems       ← Order lines for OOS products
                └── cgCloudStorePromotionsList ← Account promotions display

Apex Controllers:
  TPB_OnlineAppController           ← Orders, products, promotions, visit jobs, PDF
  TPBOnlineAppVisitProcess          ← Visit lifecycle, surveys, tasks, files
  TPB_OnlineAppBarcodeScanController ← Barcode scan processing
```

---

## 2. Component Details

---

### 2.1 cgCloudonlineApptpb

**File:** [lwc/cgCloudonlineApptpb/](force-app/main/default/lwc/cgCloudonlineApptpb/)  
**Deployed as:** Lightning Tab + Lightning App Page  
**Purpose:** Root shell/entry-point component. Functions as a container placeholder that hosts child components via its HTML template.

| Item | Detail |
|---|---|
| Exposed | Yes — `lightning__Tab`, `lightning__AppPage` |
| Apex controllers | None |
| Child components | Hosts `cgCloudUserCockpit` and/or `cgCloudStoreCockpit` |
| Key methods | `handleRefresh()` — empty stub |

---

### 2.2 cgCloudUserCockpit

**File:** [lwc/cgCloudUserCockpit/](force-app/main/default/lwc/cgCloudUserCockpit/)  
**Purpose:** User home screen/dashboard. Shows the visit list, customer tasks, and dashboard links. Handles account creation with record type selection.

**Key methods:**

| Method | What it does |
|---|---|
| `handleNewAccount()` | If multiple Account record types exist, opens a selection modal; navigates to standard New Account page with `Created_from_Online_App__c = true` |
| `handlePrevDay()` / `handleNextDay()` / `handleCurrentDay()` | Adjusts `selectedCalendarDate` which re-triggers the `getCustomerTasks` wire |
| `createTask()` | Calls `createCustomerTask` Apex |

**Apex controllers:** `TPBOnlineAppVisitProcess`
- `getCustomerAccounts` — accounts managed by the current user
- `getCustomerTaskTemplates` — active task templates
- `createCustomerTask` — creates `cgcloud__Account_Task__c`
- `getCustomerTasks` — tasks for accounts with visits on selected date
- `getDasboardLinks` — active `cgcloud__Mobile_Link__c` records

**Objects:** `Account`, `cgcloud__Account_Task__c`, `User` (read)

**Child components:** `c-cg-cloud-visits-list`, `c-custom-lookup-search`

---

### 2.3 cgCloudVisitsList

**File:** [lwc/cgCloudVisitsList/](force-app/main/default/lwc/cgCloudVisitsList/)  
**Deployed as:** Lightning Record Page  
**Purpose:** Visit list with full CRUD — displays today's visits sorted by status, supports visit creation, cancellation, customer task creation, and navigation into the Store Cockpit.

**Key methods:**

| Method | What it does |
|---|---|
| `handleVisitClick()` | For Retailer accounts: navigates to Account page with StoreCockpit state params. For non-Retailer: navigates to Visit record |
| `CreateVisit()` | Creates visit with 'Distribution Visit Template' and 'In-Store Visit' type |
| `handleCancelVisit()` | Calls `cancelVisit` — deletes visit jobs and sets status to Abandoned |

**Apex controllers:** `TPBOnlineAppVisitProcess`
- `getMyVisits` — visits for current user on selected date
- `createVisit` — creates Visit record
- `cancelVisit` — deletes all visit jobs, marks visit Abandoned
- `getCustomerAccounts`, `getVisitTemplates`, `getVisitTypePicklistValues`

**Objects:** `Visit` (create/update), `cgcloud__Visit_Job__c` (delete on cancel)

**Events dispatched:** `totalvisits` CustomEvent to parent `cgCloudUserCockpit`

**Business rules:**
- Visits sorted: in-progress → planned → completed
- Retailer account visits use Account page URL with StoreCockpit state params
- Default template: `Distribution Visit Template`; default type: `In-Store Visit`

---

### 2.4 cgCloudStoreCockpit

**File:** [lwc/cgCloudStoreCockpit/](force-app/main/default/lwc/cgCloudStoreCockpit/)  
**Deployed as:** Lightning Record Page  
**Purpose:** Central visit management hub — orchestrates navigation between sub-pages (Order, Review, Product Distribution, Survey, Promotions), manages visit start/end lifecycle with geolocation capture.

**Key methods:**

| Method | What it does |
|---|---|
| `startVisit()` | Captures geolocation (mobile capabilities or browser fallback); blocks if another in-progress visit exists; calls `startvisitUpdate` |
| `endVisit()` | Multi-step validation via `endvisitValidate`; calls `endvisitUpdate` on pass |
| `handleCreateOrder()` | Checks for existing open order; if one exists, prompts user; otherwise calls `createOrder` |
| `buildUploadPayload()` | Compresses images via Canvas API before upload (max 1600px, 0.75 JPEG) |
| `uploadVisitFileWithRetry()` | Exponential backoff retry on Apex rate limit errors |

**Apex controllers:**
- `TPBOnlineAppVisitProcess`: `startvisitUpdate`, `endvisitUpdate`, `endvisitValidate`, `getVisitInfo`, `getVisitFiles`, `deleteVisitFile`, `uploadVisitFile`
- `TPB_OnlineAppController`: `createOrder`, `getOrder`, `getWholesalePromotions`, `getChainAccountOverview`, `ensureVisitJobsExist`

**Objects:** `Visit` (status, coordinates, timestamps), `cgcloud__Order__c` (create), `ContentVersion`/`ContentDocumentLink`

**Child components:** `c-cg-cloud-order-page`, `c-cg-cloud-review-order-page`, `c-cg-cloud-product-distribution`, `c-cg-cloud-survey`, `c-cg-cloud-store-promotions-list`

**End-visit validation sequence:**

| Step | Block type | Can be overridden? |
|---|---|---|
| Open orders | Hard block | No — must resolve first |
| Pending customer tasks (due ≤ today) | Hard block | No |
| Pending product distribution | Soft block | Yes — rep can override |
| Pending survey questions | Soft block | Yes — rep can override |

---

### 2.5 cgCloudOrderPage

**File:** [lwc/cgCloudOrderPage/](force-app/main/default/lwc/cgCloudOrderPage/)  
**Purpose:** The main order entry screen — the most complex component. Handles product browsing, order line item creation/updating across four order types, promotion/reward logic, tab navigation, and barcode scanning.

**Order types supported:**

| Type | Price behavior | Special rules |
|---|---|---|
| Cash Sale | Base price → special price editable | ±10%/25% band validation |
| Return | Prices negated | Same price bands apply |
| Prebook | Always zero price | Wholesaler selection required |
| Free Item | Zero value | Linked to promotion reward |

**Key methods:**

| Method | What it does |
|---|---|
| `processOrderItems()` | Fetches all order line items, groups by subcategory + typeId |
| `handleTypeChange()` | Tracks `pendingTypeChange` — fromTypeId/toTypeId for migration when user changes type on existing line |
| `resolveTypeChangeForUpdate()` | Merges quantities to target type's item or creates new on quantity update |
| `finalizePendingTypeChange()` | Deletes old-type order items after quantity transfer |
| `generateResponseBody()` | Upserts order line items; handles promotion reward checks |
| `applyDiscountToItems()` / `removeDiscountToItems()` | Recalculates `Reimbursable_Amt__c` for all promoted items |
| `validateSpecialPrice()` | Enforces ±10%/25% special price bands; checks `Max_Limit_Spl_Price__c` custom setting cap |
| `handleDeleteOrder()` | Calls `cancelOrder` — sets phase to 'Cancelled', does NOT hard-delete |
| `getrewardCriteriaCheckbox()` | Checks promotion reward hurdles; sets `isGratis`; triggers Gratis cleanup if hurdle no longer met |
| `callGetRewardsAndHurldes()` | Builds `rewardGroupsUI` model for the reward modal |
| `handleFilterChange()` | Filters product list to active promotion; refreshes tactic products and recalculates rewards |
| `handleGratisCleanup()` | Deletes Free Item line items when Gratis hurdle is no longer fulfilled |
| `adjustProductListHeight()` | Dynamic layout via `requestAnimationFrame` for iPad/desktop responsiveness |

**Apex controllers:** `TPB_OnlineAppController`
- `getProducts`, `getOrderItems`, `createOrderLineItems`, `updateOrder`
- `getOrderItemTemplates`, `getPromotions`, `getTacticProducts`
- `getRewardsAndHurdles`, `rewardCriteriaCheck`, `getRewardProductsGratis`
- `getPrebookWholesaler`, `getRewardDiscount`, `getCustomSettings`
- `getWholesalerAuthProducts`, `cancelOrder`

**Child components:** `c-cg-cloud-multiselect-picklist`, `c-cg-cloud-barcode-scanner`, `c-custom-lookup-search`, `c-cg-cloud-t-p-b-promo-prebook`

**Tabs in the component:**

| Tab | Contents |
|---|---|
| Cart | Main product list — all products with Cash Sale/Return/Prebook |
| OOS | `cgCloudOOSOrderItems` — products with OutOfStock visit job |
| TPB Promo | `cgCloudTPBPromoPrebook` — promo prebook suggested items |
| Distributed | `cgCloudDistributedItems` — products with Distributed visit job |

**Business rules:**
- Type-change migration: switching an existing line's type transfers quantities without data loss
- Promotion filter: when active, only tactic products for that promotion appear; reward criteria evaluated live
- Gratis free items auto-removed if hurdle is no longer met after a line item is deleted
- SAL-253, SAL-281, SAL-310, SAL-328 are ticket references present in code

---

### 2.6 cgCloudBarcodeScanner

**File:** [lwc/cgCloudBarcodeScanner/](force-app/main/default/lwc/cgCloudBarcodeScanner/)  
**Purpose:** Modal component that captures barcode/GTIN scans via keyboard events (hardware scanner) or paste. Supports two modes: **order mode** (creates order line items) and **visit mode** (creates/updates visit job distribution records).

**Key methods:**

| Method | What it does |
|---|---|
| `handleKeyDown(event)` | Accumulates characters from hardware scanner; fires `addGtin()` on Enter key |
| `handlePaste(event)` | Splits pasted text on newline/comma/semicolon; adds each code |
| `addGtin(raw)` | Strips whitespace, normalizes to digits, appends to `scannedList` |
| `handleSubmit()` | Routes to correct Apex: order mode → `createOrderItemsFromScannedData`; visit mode → `createVisitJobsFromScannedData` then `prepareEndOfScanReview` |
| `prepareEndOfScanReview(result)` | Diffs scanned products against `productDistributionData`; surfaces Distributed-but-not-scanned products for OOS review (SAL-248) |
| `handleReviewSubmit()` | Calls `TPB_OnlineAppController.createVisitJobs` using parent's `visitJobMap` to avoid duplicate inserts |

**Apex controllers:**
- `TPB_OnlineAppBarcodeScanController.createOrderItemsFromScannedData`
- `TPB_OnlineAppBarcodeScanController.createVisitJobsFromScannedData`
- `TPB_OnlineAppController.createVisitJobs`

**Events:**
- `scanpopupclosed` CustomEvent — dispatched when a refresh is needed after modal closes

**Business rules:**
- SAL-248: after a visit-mode scan, Distributed items not scanned are flagged as possibly OOS for review
- Order mode: duplicate GTINs = increased quantity (not deduplication)
- Visit mode: uses parent's `visitJobMap` to prevent duplicate visit job inserts

---

### 2.7 cgCloudProductDistribution

**File:** [lwc/cgCloudProductDistribution/](force-app/main/default/lwc/cgCloudProductDistribution/)  
**Purpose:** Manages product distribution status (Distributed/OutOfStock) during a visit — ensures visit jobs exist for all activity products, allows status toggling, and supports barcode scanning.

**Key methods:**

| Method | What it does |
|---|---|
| `connectedCallback()` | On first access: calls `ensureVisitJobsExist`; sets `Visit.Product_Distribution_Accessed__c = true` |
| `loadProductDistributionData()` | Fetches products grouped by sub-category; sets `isDeletable` for non-activity products |
| `handleChangeStatus()` | Toggle button: flips Distributed ↔ OutOfStock; calls `createVisitJobs` |
| `handleChangeProductStatus()` | Dropdown: supports 'Delete' (calls `deleteRecord`) or any picklist status value |
| `handleAddProduct()` | Validates selection, filters duplicates, calls `createVisitJobs` with `visitJobAnswer: 'Distributed'` |

**Apex controllers:** `TPB_OnlineAppController`
- `getProductDistributionProducts`, `getProducts`, `createVisitJobs`
- `ensureVisitJobsExist`, `getWholesalerAuthProducts`

**Objects:** `cgcloud__Visit_Job__c` (upsert/delete), `Visit` (`Product_Distribution_Accessed__c`)

**Child components:** `c-cg-cloud-barcode-scanner`, `c-cg-cloud-multiselect-picklist`

**Business rules:**
- Visit jobs initialized lazily on first access to this page
- Products from the activity list have `isDeletable = false` — cannot be removed from distribution screen
- Status changes stamp `Distribution_Source__c = 'Online App'`

---

### 2.8 cgCloudDistributedItems

**File:** [lwc/cgCloudDistributedItems/](force-app/main/default/lwc/cgCloudDistributedItems/)  
**Purpose:** Renders and manages order line items for products with a **Distributed** visit job status, grouped by product sub-category. Supports Cash Sale, Return, and Prebook order types with special price validation.

**Key methods:**

| Method | What it does |
|---|---|
| `processOrderItems()` | Fetches existing order line items; overlays quantities/prices onto distributed product list |
| `populateSelectedProductDetails()` | Resolves order item type, UOM availability, and prices for the selected row |
| `generateResponseBody()` | Upserts order line items; handles type-specific logic and price validation |
| `validateSpecialPrice()` | Enforces ±10%/25% band relative to base price; checks `Max_Limit_Spl_Price__c` cap |
| `orderLineItemCalculation()` | Computes total prices; negates values for Return type |
| `deleteOrderLineItem()` | Calls `deleteRecord` via `lightning/uiRecordApi` |
| `handleSearchChange()` | Client-side product name filter |

**Apex controllers:** `TPB_OnlineAppController`
- `getDistributedItems`, `getOrderItems`, `createOrderLineItems`
- `getOrderItemTemplates`, `getPrebookWholesaler`, `getCustomSettings`

**Objects:** `cgcloud__Order_Item__c` (upsert/delete), `cgcloud__Visit_Job__c` (read)

**Business rules:**
- Only shows products whose visit job answer is 'Distributed'
- Special price within ±10% → soft warning (LightningConfirm dialog)
- Special price outside ±25% → hard block
- Special price cannot exceed `Max_Limit_Spl_Price__c` org default
- Return type negates all prices and values
- Prebook type requires wholesaler selection

---

### 2.9 cgCloudOOSOrderItems

**File:** [lwc/cgCloudOOSOrderItems/](force-app/main/default/lwc/cgCloudOOSOrderItems/)  
**Purpose:** Nearly identical to `cgCloudDistributedItems` but for products with an **OutOfStock** visit job status. Same order line item management pattern with identical price validation rules.

**Apex controllers:** `TPB_OnlineAppController`
- `getOOSItems` *(differs from Distributed — only the data source changes)*
- `getOrderItems`, `createOrderLineItems`, `getOrderItemTemplates`, `getPrebookWholesaler`, `getCustomSettings`

**Business rules:** Identical to `cgCloudDistributedItems` — only the visit job filter (`OutOfStock` vs `Distributed`) differs.

---

### 2.10 cgCloudReviewOrderPage

**File:** [lwc/cgCloudReviewOrderPage/](force-app/main/default/lwc/cgCloudReviewOrderPage/)  
**Purpose:** Order review and completion screen — displays order summary, validates line items, collects payment fields, generates/attaches the PDF invoice, and transitions the order to 'Released'.

**Key methods:**

| Method | What it does |
|---|---|
| `handleCompleteOrder()` | Validates at least one line item; checks zero-value items (SAL-310 exception for PercentageDiscount promotions); calls `completeOrder`; triggers PDF generation |
| `handleGenerateInvoice()` | Opens VF page `CgCloudInvoiceView?orderId=...` in a new tab |
| `generatePDFSave()` | Calls `generateAndAttachInvoice` — renders and stores PDF as `ContentVersion` linked to order and account |
| `buttonDisabled` (getter) | Returns `true` unless `paymentCollected = true` AND `authorizingAgent` is non-empty |

**Apex controllers:** `TPB_OnlineAppController`
- `getReviewOrder`, `completeOrder`, `rewardCriteriaCheck`
- `getPercentageDiscountPromotionIds`, `getPDFValues`, `generateAndAttachInvoice`

**Objects:** `cgcloud__Order__c` (phase → Released, payment fields), `ContentVersion`, `ContentDocumentLink`

**Business rules:**
- Complete button locked until payment collected AND authorizing agent filled
- SAL-310: zero-value Cash Sale items allowed when they belong to a fulfilled PercentageDiscount promotion
- PDF automatically generated and attached to both order and account on successful completion

---

### 2.11 cgCloudTPBPromoPrebook

**File:** [lwc/cgCloudTPBPromoPrebook/](force-app/main/default/lwc/cgCloudTPBPromoPrebook/)  
**Purpose:** TPB Promo Prebook tab — displays suggested order items from `Ideal_Kit__c` records where `Item_Type__c = 'Suggested Order'` and `tpbPromo = true`. Prebook-only ordering at Carton UOM.

**Apex controllers:** `TPB_OnlineAppController`
- `suggestedOrderPrebook`, `getPrebookWholesaler`, `createOrderLineItems`, `getOrderItemTemplates`

**Business rules:**
- Only Carton UOM — no Each quantity entry
- Price always zero (TPB Prebook business rule)
- Wholesaler must be selected before quantities can be entered

---

### 2.12 cgCloudSurvey

**File:** [lwc/cgCloudSurvey/](force-app/main/default/lwc/cgCloudSurvey/)  
**Purpose:** Survey question renderer for visit activities — loads questions from Job Definition Lists, maps existing answers, and saves responses (including file/photo uploads) as visit jobs.

**Key methods:**

| Method | What it does |
|---|---|
| `connectedCallback()` | Sets `Visit.Surveys_Accessed__c = true` via `updateRecord` |
| Wire `getVisitQuestions()` | Groups questions by `activityName`; maps `dataType` to `isPicklist`, `isNumber`, `isString` |
| `handleInputChange()` | On any answer change, queues a save via sequential promise chain to prevent race conditions |
| `handleFileChange()` / `handleFileUpload()` | Handles `pictureTaking` question type; compresses image via Canvas API then uploads |
| `createSurveyVisitJobsWithFileWithRetry()` | Retries on Apex rate limit errors (exponential backoff) |

**Apex controllers:** `TPBOnlineAppVisitProcess`
- `getVisitQuestions`, `createSurveyVisitJobs`, `createSurveyVisitJobsWihtFiles`

**Objects:** `cgcloud__Visit_Job__c` (upsert), `Visit` (`Surveys_Accessed__c`), `ContentVersion`/`ContentDocumentLink`

**Business rules:**
- Sequential promise chain prevents concurrent rapid answer changes from creating duplicate visit jobs
- `pictureTaking` question type: file compressed client-side (max 1600px, 0.75 JPEG), then linked to both the visit and the visit job record

---

### 2.13 cgCloudStorePromotionsList

**File:** [lwc/cgCloudStorePromotionsList/](force-app/main/default/lwc/cgCloudStorePromotionsList/)  
**Deployed as:** Lightning Record Page  
**Purpose:** Read-only component that fetches and displays active promotions for the selected account. Used in the Store Cockpit's Promotions tab.

**Apex controllers:** `TPB_OnlineAppController.getPromotions`

**Objects:** `cgcloud__Promotion__c` (read only)

**Business rules:** No mutations — display only.

---

### 2.14 cgCloudMultiselectPicklist

**File:** [lwc/cgCloudMultiselectPicklist/](force-app/main/default/lwc/cgCloudMultiselectPicklist/)  
**Purpose:** Reusable custom picklist/combobox. Supports single-select, multi-select, and checkbox modes. Fully controlled via `@api` properties.

**Key public APIs:**

| API | Type | What it does |
|---|---|---|
| `options` setter | @api | Initializes options; pre-selects any values in `selectedValues` |
| `checkValidity()` | @api method | Reports validity |
| `resetCombo()` / `clearSelections()` | @api methods | Resets all selections |
| `disableSelectedOptions()` / `resetDisabledOptions()` | @api methods | Locks/unlocks options programmatically |

**Events dispatched:** `selectedoption` CustomEvent with payload `{ value, values, label, labels, allSelections }`

**Apex controllers:** None  
**Objects:** None  

**Business rules:** Event payload contains both single (`value`/`label`) and multi (`values`/`labels`) fields simultaneously for flexibility across parent components.

---

## 3. Apex Controller Details

---

### 3.1 TPB_OnlineAppController

**File:** [classes/TPB_OnlineAppController.cls](force-app/main/default/classes/TPB_OnlineAppController.cls)  
**Purpose:** Primary Apex controller for the entire online app — handles order lifecycle, line item management, product/inventory lookup, promotion and reward evaluation, visit job management, and PDF generation.

**Key methods by category:**

#### Order Management

| Method | What it does |
|---|---|
| `createOrder(accountId, visitId)` | Creates `cgcloud__Order__c` with 'Standard' template, '1003' calculation schema; uses `getNextSequence('ONLINE_ORDER')` for padded sequential order ID |
| `getNextSequence(key)` | Pessimistic lock on `TPB_Sequence__c` — increments and returns next padded sequence number; prevents concurrent duplicate order IDs |
| `cancelOrder(orderId)` | Sets `cgcloud__Phase__c = 'Cancelled'` |
| `getOrder(accountId, visitId)` | Returns existing Initial-phase order for the visit |
| `completeOrder(orderBody)` | Sets phase to 'Released'; saves payment fields; calls `createInventoryTransaction` and `generateAndAttachInvoice` |
| `getReviewOrder(orderId)` | Returns `OrderReviewWrapper` with account/shipping/payment info |

#### Order Line Items

| Method | What it does |
|---|---|
| `createOrderLineItems(orderId, responseBody)` | Upserts `cgcloud__Order_Item__c`; Cash Sale sets base/special price + reimbursable; Free Item value = 0; Prebook maps wholesaler to supplier fields; Return negates prices |
| `getOrderItems(orderId)` | Returns `List<OrderItemWrapper>`; normalizes negative prices to positive for Return display |
| `getOrderItemTemplates()` | Returns Cash Sale, Return, Prebook, Free Item templates |
| `getPercentageDiscountPromotionIds(promotionIds)` | Returns promotion IDs where reward type is PercentageDiscount (SAL-310: allows zero-value Cash Sale lines for these) |

#### Products & Inventory

| Method | What it does |
|---|---|
| `getProducts(visitId)` | Joins Product2, PricebookEntry, Inventory (user + tour state filtered), and UOM records |
| `getDistributedItems(visitId)` | Products from visit jobs where status = 'Distributed', enriched with inventory/UOM data |
| `getOOSItems(visitId)` | Products from visit jobs where status = 'OutOfStock', enriched with inventory/UOM data |
| `suggestedOrderPrebook(accountId, orderId, tpbPromo)` | Queries `Ideal_Kit__c` for suggested prebook items joined with existing Prebook order items |
| `getWholesalerAuthProducts(accountId)` | Returns Map of productId → List of authorized wholesalers |
| `getPrebookWholesaler(accountId, productId)` | Returns wholesalers authorized for a specific product; always appends 'TSM VAN' |
| `getCustomSettings()` | Returns `Online_App_Custom_Setting__c.getOrgDefaults()` |

#### Promotions & Rewards

| Method | What it does |
|---|---|
| `getPromotions(accountId)` | Active promotions for account sets the account belongs to, filtered by date range |
| `getTacticProducts(visitId, promotionId, orderId)` | Products from `cgcloud__Tactic_Product__c` for a promotion, enriched with inventory/UOM and existing order item data |
| `getRewardsAndHurdles(promotionId)` | Returns reward groups, hurdles, and rewards for the reward modal |
| `rewardCriteriaCheck(promotionId, orderId)` | Routes to classification-based or non-classification reward evaluation; returns fulfilled status and help text per reward group |
| `rewardCriteriaMatchWithClassification()` | Evaluates per-classification hurdle quantity rules against Cash Sale Carton items per reward group |
| `rewardCriteriaDiscountWithoutClassification()` | Evaluates aggregate quantity hurdles against all promoted order items |
| `getRewardProductsGratis(rewardId, orderId)` | Products linked to a Gratis reward, enriched with inventory balance and any existing Free Item order item |
| `getRewardDiscount(promotionId)` | Returns Map of productId → `cgcloud__Promotion_Reward_Product__c` for discount calculations |

#### Visit Jobs

| Method | What it does |
|---|---|
| `ensureVisitJobsExist(accountId, visitId)` | Inserts `cgcloud__Visit_Job__c` for all activity products not yet tracked; populates job definition template and data type option fields |
| `createVisitJobs(visitId, visitJobWrapper)` | Upserts visit jobs from `ProductDistributionData` wrapper; stamps `Distribution_Source__c = 'Online App'` if not already set |
| `getProductDistributionProducts(accountId, visitId)` | Returns existing visit jobs enriched with `isDeletable` flag and `TPB_EOV__c` picklist values |
| `getActivityProducts(accountId)` | Returns Set of active Job Definition List IDs for the account where `Consider_Products__c = true` |

#### PDF & Files

| Method | What it does |
|---|---|
| `generateAndAttachInvoice(orderId)` | Renders VF page `CgCloudInvoicePdfGenerator` as PDF blob; stores as `ContentVersion`; links to order and account via `ContentDocumentLink` |
| `getPDFValues(orderId)` / `getPDFValuesVF(orderId)` | Returns order items split into CashSale/Return/Prebook lists with store/org info, invoice terms, and subtotals |
| `getWholesalePromotions(accountId)` | Returns `ContentVersion` (non-invoice) records linked to wholesalers of the account |
| `getChainAccountOverview(accountId)` | Returns `ContentVersion` records flagged `TPB_IsHQAttachment__c = true` linked to the account's parent |
| `uploadFile(base64Data, fileName, orderId)` | Creates `ContentVersion` and `ContentDocumentLink` for an order-level file upload |

**Objects queried/updated:**
`cgcloud__Order__c`, `cgcloud__Order_Item__c`, `cgcloud__Visit_Job__c`, `cgcloud__Inventory__c`, `cgcloud__Unit_of_Measure__c`, `Product2`, `PricebookEntry`, `Account`, `Related_Account__c`, `Account_Product__c`, `Invoice_Term__c`, `TPB_Sequence__c`, `TPB_Distributor_License__c`, `ContentVersion`, `ContentDocumentLink`, `Ideal_Kit__c`, `cgcloud__Job_Definition_List_Account__c`, `cgcloud__Job_Definition_List_Product__c`, `cgcloud__Job_DL_Job_Definition_Template__c`, `cgcloud__Data_Type_Option__c`, `Organization`, `cgcloud__Promotion__c`, `cgcloud__Promotion_Reward_Group__c`, `cgcloud__Promotion_Hurdle__c`, `cgcloud__Promotion_Reward__c`, `cgcloud__Promotion_Reward_Product__c`, `cgcloud__Tactic_Product__c`, `Online_App_Custom_Setting__c`

---

### 3.2 TPBOnlineAppVisitProcess

**File:** [classes/TPBOnlineAppVisitProcess.cls](force-app/main/default/classes/TPBOnlineAppVisitProcess.cls)  
**Purpose:** Visit lifecycle and survey controller — manages visit creation, start, validation, completion, survey question loading, answer saving (including file attachments), customer tasks, and dashboard links.

**Key methods by category:**

#### Visit Lifecycle

| Method | What it does |
|---|---|
| `getMyVisits(selectedDate)` | Returns Planned/Completed visits for current user on selected date |
| `getVisitInfo(visitId)` | Returns visit with `TPB_InProgress__c`, `Product_Distribution_Accessed__c`, notes, responsible user |
| `createVisit(...)` | Creates Visit with 'Editable' record type, 'Default Location' place, 30-minute duration |
| `startvisitUpdate(visitId, accountId, lat, lon)` | Blocks if another in-progress visit exists for the user; sets `TPB_InProgress__c = true`; records start time and coordinates |
| `endvisitValidate(visitId, accountId, validateDist, validateSurvey)` | Returns validation status string: `open_orders`, `open_customerTasks`, `pending_product_distribution`, `pending_survey_questions`, or `validated` |
| `endvisitUpdate(visitId, lat, lon, accountId)` | Calls `ensureVisitJobsExist`; sets Visit to 'Read_Only' record type, status = 'Completed'; records end coordinates |
| `cancelVisit(visitId)` | Deletes ALL visit jobs for the visit; sets status to 'Abandoned' |

#### Surveys

| Method | What it does |
|---|---|
| `getVisitQuestions(customerId, visitId)` | Loads survey questions from Job Definition Lists — direct account assignments AND via Account Sets (with deduplication); maps existing visit job answers |
| `getActivitySurveys(accountId)` | Returns survey-type (non-product) Job Definition List IDs |
| `createSurveyVisitJobs(visitId, visitJobWrapper)` | Upserts visit jobs for survey answers |
| `createSurveyVisitJobsWihtFiles(visitId, wrapper, fileName, base64Data)` | Upserts visit jobs AND creates `ContentVersion` linked to the first visit job |

#### Tasks & Files

| Method | What it does |
|---|---|
| `getCustomerTaskTemplates()` | Active task templates ordered by sort |
| `getCustomerTasks(selectedDate)` | Open tasks for accounts with Planned visits on the selected date |
| `createCustomerTask(...)` | Creates `cgcloud__Account_Task__c` with 'Customer_Task_Editable' record type |
| `getVisitFiles(visitId)` / `uploadVisitFile(...)` / `deleteVisitFile(...)` | Manage `ContentVersion`/`ContentDocumentLink` for visit file attachments |
| `getDasboardLinks()` | Returns active `cgcloud__Mobile_Link__c` records for 'Your Day' display |

**Objects queried/updated:**
`Visit`, `cgcloud__Visit_Template__c`, `cgcloud__Account_Manager__c`, `Account`, `cgcloud__Account_Task__c`, `cgcloud__Account_Task_Template__c`, `cgcloud__Visit_Job__c`, `cgcloud__Job_Definition_List_Account__c`, `cgcloud__Job_Definition_List_Account_Set__c`, `cgcloud__Account_Set_Account__c`, `cgcloud__Job_DL_Job_Definition_Template__c`, `cgcloud__Job_Definition_Template__c`, `cgcloud__Data_Type_Option__c`, `ContentVersion`, `ContentDocumentLink`, `cgcloud__Mobile_Link__c`, `RecordType`, `Location`

**Business rules:**
- Visit start blocked if any other visit is `TPB_InProgress__c = true` for the current user
- Survey questions resolved from both direct account assignments AND Account Set memberships, with deduplication
- `endvisitUpdate` always calls `ensureVisitJobsExist` — guarantees distribution records are created even if the rep skipped the distribution screen
- `cancelVisit` deletes all visit jobs before marking Abandoned — ensures clean data

---

### 3.3 TPB_OnlineAppBarcodeScanController

**File:** [classes/TPB_OnlineAppBarcodeScanController.cls](force-app/main/default/classes/TPB_OnlineAppBarcodeScanController.cls)  
**Purpose:** Handles all barcode scan data processing — visit distribution mode (creates/updates visit jobs) and order mode (creates order line items).

**Key methods:**

| Method | What it does |
|---|---|
| `createVisitJobsFromScannedData(scannedValues, visitId, accountId)` | Parses GTINs via `cgcloud__GTIN__c` on UOM records. If visit jobs exist: updates scanned products to 'Distributed' with `Via_Scanner__c = true`, `Distribution_Source__c = 'Scanner'`. If NO visit jobs exist yet: bootstraps distribution records for ALL activity products in one shot (scanned = Distributed, others = their default `TPB_EOV__c`). Returns `ScannedOrderItemsResult` |
| `createOrderItemsFromScannedData(scannedValues, orderId)` | Counts GTIN occurrences (duplicates = multiple units); maps GTINs to products/UOMs; creates/updates `cgcloud__Order_Item__c` as Cash Sale using inventory average price. Returns `ScannedOrderItemsResult` |

**Objects queried/updated:**
`cgcloud__Unit_of_Measure__c`, `cgcloud__Visit_Job__c` (upsert), `cgcloud__Order_Item__c` (upsert), `cgcloud__Order__c`, `cgcloud__Inventory__c`, `cgcloud__Job_Definition_List_Product__c`, `cgcloud__Job_DL_Job_Definition_Template__c`, `cgcloud__Data_Type_Option__c`, `cgcloud__Order_Item_Template__c`

**Business rules:**
- GTIN lookup via `cgcloud__GTIN__c` on UOM records — products without matching GTIN go to `failedItems`
- First-scan bootstrap: if no visit jobs exist, creates records for ALL activity products in one shot
- `Via_Scanner__c = true` marks visit jobs set via scanner (preserves vs manual toggle attribution)
- `Distribution_Source__c = 'Scanner'` is set only if not already set (preserves existing source)
- Duplicate GTINs in scan list → increased quantity for order items (not deduplication)
- ConsumerUnit UOM → Each; SalesUnit UOM → Carton

---

## 4. Cross-Component Data Flow

### 4.1 Order Creation Flow

```
Rep taps "New Order" in cgCloudStoreCockpit
    → TPB_OnlineAppController.createOrder()
        → cgcloud__Order__c created (Phase=Initial, Template=Standard)
        → TPB_Sequence__c pessimistic lock → padded sequential order ID
    → cgCloudOrderPage loads
        → getProducts() → Product2 + PricebookEntry + Inventory (user+state filtered) + UOM
        → getOrderItemTemplates() → Cash Sale / Return / Prebook / Free Item
        → getPromotions() → active promotions for account's account sets
```

### 4.2 Order Line Item Creation Flow

```
Rep enters quantity in cgCloudOrderPage
    → validateSpecialPrice() → ±10% warn / ±25% block / Max_Limit_Spl_Price__c cap
    → generateResponseBody()
        → TPB_OnlineAppController.createOrderLineItems()
            → cgcloud__Order_Item__c upserted
            → Cash Sale: base price + special price + reimbursable amt
            → Return: prices negated
            → Prebook: price = 0, wholesaler mapped
            → Free Item: value = 0, linked to promotion reward
        → rewardCriteriaCheck() → evaluate hurdles → isGratis check
        → if Gratis hurdle fails → handleGratisCleanup() → delete Free Item lines
```

### 4.3 Barcode Scan → Order Flow

```
Rep scans barcode in cgCloudBarcodeScanner (order mode)
    → GTINs accumulated via keyboard events
    → handleSubmit()
        → TPB_OnlineAppBarcodeScanController.createOrderItemsFromScannedData()
            → GTIN → UOM lookup → Product2
            → Inventory.TPB_AvgPrice__c used as base price
            → cgcloud__Order_Item__c upserted (Cash Sale, ConsumerUnit/SalesUnit UOM)
    → scanpopupclosed event → cgCloudOrderPage refreshes, selects newly added item
```

### 4.4 Barcode Scan → Distribution Flow (SAL-248)

```
Rep scans barcode in cgCloudBarcodeScanner (visit mode)
    → TPB_OnlineAppBarcodeScanController.createVisitJobsFromScannedData()
        → If first scan (no visit jobs): bootstraps ALL activity products
        → If visit jobs exist: updates scanned → Distributed (Via_Scanner__c=true)
    → prepareEndOfScanReview()
        → Diffs scanned list against productDistributionData
        → Distributed-but-not-scanned → flagged as possibly OOS
    → Review screen shown → rep confirms OOS items
        → TPB_OnlineAppController.createVisitJobs() → sets OOS status
```

### 4.5 Visit End Validation Flow

```
Rep taps "End Visit" in cgCloudStoreCockpit
    → TPBOnlineAppVisitProcess.endvisitValidate()
        → Check: open orders (cgcloud__Order__c Phase=Initial) → hard block
        → Check: open customer tasks due ≤ today → hard block
        → Check: product distribution coverage → soft block (overrideable)
        → Check: survey question completion → soft block (overrideable)
        → Returns: 'open_orders' | 'open_customerTasks' | 'pending_product_distribution'
                 | 'pending_survey_questions' | 'validated'
    → If 'validated':
        → TPBOnlineAppVisitProcess.endvisitUpdate()
            → ensureVisitJobsExist() → creates any missing distribution records
            → Visit: status=Completed, record type=Read_Only, end coords + timestamp
```

### 4.6 Order Completion & PDF Flow

```
Rep taps "Complete Order" in cgCloudReviewOrderPage
    → Validates: paymentCollected=true AND authorizingAgent filled
    → Validates: at least 1 line item
    → Validates: no zero-value Cash Sale items
        (SAL-310 exception: allowed if PercentageDiscount promotion fulfilled)
    → TPB_OnlineAppController.completeOrder()
        → cgcloud__Order__c Phase → Released
        → Payment fields saved
        → createInventoryTransaction() → inventory records updated
        → generateAndAttachInvoice()
            → VF page CgCloudInvoicePdfGenerator rendered as PDF
            → ContentVersion created
            → ContentDocumentLink to Order + Account
    → completeorder CustomEvent → parent StoreCockpit navigates back
```

---

## 5. Key Business Rules Summary

| Rule | Where enforced |
|---|---|
| Special price ±10% → soft warning dialog | `cgCloudOrderPage`, `cgCloudDistributedItems`, `cgCloudOOSOrderItems` |
| Special price ±25% → hard block | Same three components |
| Special price cap via `Max_Limit_Spl_Price__c` | Same three components |
| Return type: all prices negated | `TPB_OnlineAppController.createOrderLineItems` |
| Prebook: price always zero, wholesaler required | `cgCloudOrderPage`, `cgCloudTPBPromoPrebook` |
| Sequential order IDs via pessimistic lock | `TPB_OnlineAppController.getNextSequence` |
| Visit start blocked if another in-progress visit exists | `TPBOnlineAppVisitProcess.startvisitUpdate` |
| Distribution source preserved ('Scanner' > 'Online App') | `TPB_OnlineAppController.createVisitJobs`, `TPB_OnlineAppBarcodeScanController` |
| `isDeletable = false` for activity-list products | `TPB_OnlineAppController.getProductDistributionProducts` |
| Gratis free items auto-removed when hurdle not met | `cgCloudOrderPage.handleGratisCleanup` |
| SAL-310: zero-value lines allowed for PercentageDiscount fulfilled promotions | `cgCloudReviewOrderPage.handleCompleteOrder` |
| `endvisitUpdate` always calls `ensureVisitJobsExist` | `TPBOnlineAppVisitProcess.endvisitUpdate` |
| Image compression before upload (max 1600px, JPEG 0.75) | `cgCloudStoreCockpit`, `cgCloudSurvey` |

---

## 6. Files Referenced

| File | Purpose |
|---|---|
| [lwc/cgCloudonlineApptpb/](force-app/main/default/lwc/cgCloudonlineApptpb/) | Shell entry point |
| [lwc/cgCloudUserCockpit/](force-app/main/default/lwc/cgCloudUserCockpit/) | User home screen |
| [lwc/cgCloudVisitsList/](force-app/main/default/lwc/cgCloudVisitsList/) | Visit list |
| [lwc/cgCloudStoreCockpit/](force-app/main/default/lwc/cgCloudStoreCockpit/) | Visit hub |
| [lwc/cgCloudOrderPage/](force-app/main/default/lwc/cgCloudOrderPage/) | Main order entry |
| [lwc/cgCloudBarcodeScanner/](force-app/main/default/lwc/cgCloudBarcodeScanner/) | Barcode scan modal |
| [lwc/cgCloudProductDistribution/](force-app/main/default/lwc/cgCloudProductDistribution/) | Distribution management |
| [lwc/cgCloudDistributedItems/](force-app/main/default/lwc/cgCloudDistributedItems/) | Distributed product order lines |
| [lwc/cgCloudOOSOrderItems/](force-app/main/default/lwc/cgCloudOOSOrderItems/) | OOS product order lines |
| [lwc/cgCloudReviewOrderPage/](force-app/main/default/lwc/cgCloudReviewOrderPage/) | Order review & completion |
| [lwc/cgCloudTPBPromoPrebook/](force-app/main/default/lwc/cgCloudTPBPromoPrebook/) | Promo prebook tab |
| [lwc/cgCloudSurvey/](force-app/main/default/lwc/cgCloudSurvey/) | Survey renderer |
| [lwc/cgCloudStorePromotionsList/](force-app/main/default/lwc/cgCloudStorePromotionsList/) | Promotions display |
| [lwc/cgCloudMultiselectPicklist/](force-app/main/default/lwc/cgCloudMultiselectPicklist/) | Reusable picklist component |
| [classes/TPB_OnlineAppController.cls](force-app/main/default/classes/TPB_OnlineAppController.cls) | Primary Apex controller |
| [classes/TPBOnlineAppVisitProcess.cls](force-app/main/default/classes/TPBOnlineAppVisitProcess.cls) | Visit lifecycle Apex controller |
| [classes/TPB_OnlineAppBarcodeScanController.cls](force-app/main/default/classes/TPB_OnlineAppBarcodeScanController.cls) | Barcode scan Apex controller |
