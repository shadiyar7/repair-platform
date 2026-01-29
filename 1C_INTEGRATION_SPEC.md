# 📦 1C Integration: Warehouse Stock Synchronization
**Status:** DRAFT
**Version:** 1.0

## 1. Overview
This document describes the asynchronous integration flow between the Repair Platform (Backend) and the 1C System for synchronizing warehouse stocks.
The synchronization is **On-Demand** with a **15-minute TTL cache**.

---

## 2. Architecture Flow

1.  **Trigger:** User views the Catalog (Frontend).
2.  **Check Cache:** Backend checks the `warehouse_stocks` table.
    -   **IF** data is fresher than 15 minutes -> Return Cached Data.
    -   **IF** data is stale (>15 mins) or missing -> Trigger Async Sync.
3.  **Async Request:** Backend sends `POST` request to 1C (Trigger Endpoint).
    -   Backend returns current (stale) data to Frontend immediately to avoid blocking UI.
4.  **Processing:** 1C System calculates stocks (background job).
5.  **Webhook:** 1C finishes and sends `POST /api/v1/integrations/one_c/stocks` to our Backend.
6.  **Update:** Backend updates `warehouse_stocks` table.

---

## 3. Database Design (New Tables)

### 3.1. `warehouses`
To normalize warehouse management (instead of hardcoded strings).

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `bigint` | PK |
| `name` | `string` | e.g. "Main Warehouse (Astana)" |
| `external_id_1c` | `string` | ID used by 1C (e.g. "000000001") |
| `address` | `string` | Physical location |
| `created_at` | `datetime` | |

### 3.2. `warehouse_stocks`
Stores the actual cache of products per warehouse.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `bigint` | PK |
| `warehouse_id` | `fk` | Reference to `warehouses` |
| `product_sku` | `string` | SKU/Nomenclature code (matches `products.sku`) |
| `quantity` | `decimal` | Available stock amount |
| `synced_at` | `datetime` | Exact time when 1C sent this data |
| `updated_at` | `datetime` | System timestamp |

---

## 4. API Endpoints

### 4.1. Trigger Endpoint (Our Backend -> 1C)
**URL:** `[1C_SERVER_URL]/api/stocks/sync` (Placeholder, need from 1C dev)
**Method:** `POST`
**Payload:**
```json
{
  "warehouse_id_1c": 1,
  "callback_url": "https://repair-platform.onrender.com/api/v1/integrations/one_c/stocks"
}
```

### 4.2. Callback Webhook (1C -> Our Backend)
**URL:** `https://repair-platform.onrender.com/api/v1/integrations/one_c/stocks`
**Method:** `POST`
**Headers:**
- `Content-Type: application/json`
- `Authorization`: **REMOVED** (No longer required)

**Expected Payload:**
```json
{
  "warehouse_id_1c": 1,
  "items": [
    {
      "nomenclature_code": "SKU-12345",
      "quantity": 150.0
    },
    {
      "nomenclature_code": "SKU-67890",
      "quantity": 0.0
    }
  ]
}
```

**Response (from us):**
- `200 OK`: Data received and queued for processing.

---

## 5. Implementation Plan

### Step 1: Database Migration
- Create `warehouses` table.
- Create `warehouse_stocks` table.
- Seed initial Warehouse (ID: 1, Name: "Atyrau Main", ExternalID: "001").

### Step 2: Backend Logic
- Create `Integrations::OneC::StocksController` to handle the webhook.
- Create `SyncStocksJob` (Sidekiq/ActiveJob) to send the request to 1C.
- Update `ProductsController#index` to check `warehouse_stocks` TTL and decide whether to trigger the Job.

### Step 3: Security
- Add a shared secret check to the Webhook controller to prevent fake data injection.

---

## 6. Frontend Implications
- Frontend does **not** need to change drastically.
- Calling `GET /products` will simply return data.
- If data is updating in background, user might see old data -> Refresh page after a few minutes -> See new data.
- Optional: Add a `last_updated` field to the response so Frontend can show "Data actual as of [Time]".
