# Campus Cafeteria Preorder and Pickup System

A full-stack campus cafeteria preorder and pickup management system built as an academic DBMS project.

The system allows students to browse dated cafeteria menus, place preorder requests for scheduled pickup, track their orders, and cancel eligible orders. Staff members process pickup queues and update order statuses, while administrators manage menus, ingredients, stock, pickup windows, users, staff accounts, and reports.

---

## Features

### Student

- Register and log in
- Browse published menus by date
- Search and filter menu items
- View price, description, ingredients, availability, and stock
- Add items to a cart with stock-aware quantity limits
- Select a pickup window
- Place orders and receive a pickup code
- Track active order status
- Cancel eligible orders
- View order history

### Staff

- Log in using an individual staff account
- View pickup queues by pickup window
- View order and pickup information
- Process orders through:

```text
PLACED → PREPARING → READY → COLLECTED
```

### Admin

- Manage menu dates and menu items
- Manage ingredients
- Manage item-ingredient assignments
- Manage stock
- Manage pickup windows and capacity
- View order and stock reports
- View and search users
- Filter users by role and active status
- Create individual staff accounts
- Activate and deactivate accounts
- Change `STUDENT` and `STAFF` roles
- Reset user passwords
- Prevent modification of the currently logged-in administrator account

---

## Technology Stack

### Frontend

- React
- TypeScript
- Vite
- CSS

### Backend

- Node.js
- Express
- TypeScript
- `pg` / node-postgres
- JWT authentication
- bcrypt password hashing

### Database

- PostgreSQL 18
- SQL
- PL/pgSQL
- PostgreSQL functions
- PostgreSQL triggers
- PostgreSQL views

### Development Tools

- Git
- GitHub
- VS Code
- PowerShell
- Docker
- Docker Compose

---

## Architecture

```text
┌──────────────────────────┐
│     React Frontend       │
│   TypeScript + Vite      │
└────────────┬─────────────┘
             │
             │ HTTP / REST
             ▼
┌──────────────────────────┐
│   Node.js + Express      │
│      TypeScript API      │
└────────────┬─────────────┘
             │
             │ pg / node-postgres
             ▼
┌──────────────────────────┐
│      PostgreSQL 18       │
│                          │
│  SQL Schema              │
│  PL/pgSQL Functions      │
│  Triggers                │
│  Views                   │
│  Reports                 │
└──────────────────────────┘
```

---

## Project Structure

```text
CampusCafeteria/
│
├── backend/
│   ├── src/
│   │   ├── middleware/
│   │   │   └── auth.ts
│   │   │
│   │   ├── routes/
│   │   │   ├── auth.ts
│   │   │   ├── menu.ts
│   │   │   ├── orders.ts
│   │   │   ├── reports.ts
│   │   │   └── users.ts
│   │   │
│   │   ├── check-pickup-windows.ts
│   │   ├── create-today-pickup-windows.ts
│   │   ├── db.ts
│   │   ├── install-order-procedures.ts
│   │   ├── install-order-status.ts
│   │   ├── install-queue-cursor.ts
│   │   ├── install-report-views.ts
│   │   ├── install-status-trigger.ts
│   │   ├── list-tables.ts
│   │   ├── run-reports.ts
│   │   ├── run-schema.ts
│   │   ├── run-seed.ts
│   │   └── server.ts
│   │
│   ├── package.json
│   ├── package-lock.json
│   └── tsconfig.json
│
├── database/
│   ├── postgresql/
│   │   ├── 01_schema.sql
│   │   ├── 02_seed_data.sql
│   │   ├── 03_demo_menu_09_to_13_oct.sql
│   │   ├── 03_order_functions.sql
│   │   ├── 04_queue_function.sql
│   │   ├── 05_status_trigger.sql
│   │   ├── 06_status_function.sql
│   │   └── 07_cancel_function.sql
│   │
│   └── queries/
│       ├── 01_reports.sql
│       └── 02_views.sql
│
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── admin/
│   │   │   ├── auth/
│   │   │   ├── common/
│   │   │   ├── staff/
│   │   │   └── student/
│   │   │
│   │   ├── hooks/
│   │   ├── services/
│   │   ├── styles/
│   │   ├── types/
│   │   └── App.tsx
│   │
│   ├── package.json
│   ├── package-lock.json
│   └── vite.config.ts
│
├── .gitignore
└── README.md
```

---

# Database Design

The database is implemented using PostgreSQL 18.

## Core Entities

```text
roles
users
menu_dates
menu_items
ingredients
item_ingredients
stock
pickup_windows
orders
order_lines
order_status_history
```

### Entity overview

| Table | Purpose |
|---|---|
| `roles` | Defines STUDENT, STAFF, and ADMIN roles |
| `users` | Stores application users and authentication information |
| `menu_dates` | Defines menus available on specific dates |
| `menu_items` | Stores cafeteria dishes |
| `ingredients` | Stores ingredient information |
| `item_ingredients` | Maps menu items to their ingredients |
| `stock` | Tracks available quantities |
| `pickup_windows` | Defines scheduled pickup periods and capacity |
| `orders` | Stores customer orders and their status |
| `order_lines` | Stores items and quantities belonging to an order |
| `order_status_history` | Records order status transitions |

The database uses:

- Primary keys
- Foreign keys
- Unique constraints
- Check constraints
- Indexes
- Transactions
- Row-level locking
- Database functions
- Triggers
- Views

to maintain data integrity and enforce business rules.

---

# Database Business Logic

The project demonstrates database-side business logic using PostgreSQL and PL/pgSQL.

## Order Placement

The `place_order` function:

- Validates the user
- Validates the pickup window
- Validates menu items
- Validates quantities
- Locks relevant stock rows
- Checks available stock
- Calculates the order total
- Creates the order
- Creates order lines
- Deducts stock
- Reserves pickup-window capacity
- Generates a pickup code

The transaction and locking logic is designed to prevent overselling under concurrent order requests.

## Order Cancellation

The `cancel_order` function:

- Locks the order
- Verifies ownership
- Allows cancellation only for eligible `PLACED` orders
- Restores stock
- Releases pickup-window capacity
- Marks the order as `CANCELLED`
- Records the cancellation through the status-history trigger

## Order Status Updates

The `update_order_status` function enforces the staff order lifecycle:

```text
PLACED
   │
   ▼
PREPARING
   │
   ▼
READY
   │
   ▼
COLLECTED
```

Invalid status transitions are rejected.

## Pickup Queue

The `get_pickup_queue` function provides the active queue for a selected pickup window.

Active queue statuses include:

```text
PLACED
PREPARING
READY
```

Orders are returned in pickup-processing order.

## Status History Trigger

The order status history trigger automatically records status changes.

Example:

```text
NULL → PLACED
PLACED → PREPARING
PREPARING → READY
READY → COLLECTED
```

This provides an auditable history of order processing.

---

# Authentication and Authorization

The application supports three roles:

```text
STUDENT
STAFF
ADMIN
```

Authentication uses:

- JWT tokens
- bcrypt password hashing

Passwords are never returned through user-management API responses.

Protected API routes use backend role-based authorization.

Inactive users cannot authenticate or continue using protected application endpoints.

---

# Local Development

## Prerequisites

Install:

- Node.js
- npm
- Docker Desktop
- Git
- PowerShell

The project uses PostgreSQL 18 through Docker for local database development.

---

# PostgreSQL Database

The development database configuration is:

```text
Host:     localhost
Port:     5432
Database: cafeteria
User:     cafeteria
```

The PostgreSQL Docker container used by the project is:

```text
Container: campus-cafeteria-postgres
Image:     postgres:18
Port:      5432
```

The database files are located under:

```text
database/postgresql/
```

---

## Database Setup

The primary database scripts are:

```text
database/postgresql/01_schema.sql
database/postgresql/02_seed_data.sql
database/postgresql/03_order_functions.sql
database/postgresql/04_queue_function.sql
database/postgresql/05_status_trigger.sql
database/postgresql/06_status_function.sql
database/postgresql/07_cancel_function.sql
```

The demonstration menu data for **09-Oct-2026 through 13-Oct-2026** is provided separately:

```text
database/postgresql/03_demo_menu_09_to_13_oct.sql
```

The demonstration data contains:

- 4 dishes per day
- 5 days of menu data
- Ingredient assignments
- Stock data
- 6 pickup windows per day
- Morning, afternoon/noon, and evening pickup periods

---

# Backend Setup

From the project root:

```powershell
cd backend
npm install
```

Create a local `.env` file.

Example:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=cafeteria
DB_USER=cafeteria
DB_PASSWORD=
JWT_SECRET=
FRONTEND_URL=http://localhost:5173
PORT=3000
```

Do not commit the actual `.env` file.

Start the backend using the configured npm script.

The API base URL is:

```text
http://localhost:3000/api
```

Health endpoint:

```text
http://localhost:3000/api/health
```

---

# Frontend Setup

From the project root:

```powershell
cd frontend
npm install
```

Start the Vite development server using the configured npm script.

The frontend normally runs at:

```text
http://localhost:5173
```

The frontend communicates with the backend through:

```text
http://localhost:3000/api
```

---

# Docker

Docker is used for the PostgreSQL development database.

Example container configuration:

```text
Container:
campus-cafeteria-postgres

Image:
postgres:18

Database:
cafeteria

User:
cafeteria

Port:
5432
```

The PostgreSQL data is persisted through a Docker volume.

---

# API Overview

The backend exposes REST API modules for:

```text
/api/auth
/api/menu
/api/orders
/api/reports
/api/users
/api/health
```

### Authentication

```text
/api/auth
```

Handles registration and login.

### Menu

```text
/api/menu
```

Handles:

- Published menus
- Menu dates
- Menu items
- Ingredients
- Stock
- Pickup windows

### Orders

```text
/api/orders
```

Handles:

- Order placement
- Order history
- Order cancellation
- Staff pickup queue
- Order status transitions

### Reports

```text
/api/reports
```

Provides reporting information for administrative use.

### Users

```text
/api/users
```

Handles administrative user management.

---

# Security

The application uses several security controls:

- JWT-based authentication
- bcrypt password hashing
- Role-based authorization
- Inactive-account protection
- Database transactions
- Row-level locking
- Stock validation
- Pickup-window capacity validation
- Ownership validation for order cancellation
- Strict order status transitions

Do not commit:

```text
.env
database passwords
JWT secrets
private keys
database credentials
other credentials
```

Use `.env.example` to document required environment variables without exposing real credentials.

---

# Demonstration Workflow

A complete demonstration can follow this sequence:

1. Administrator logs in.
2. Administrator configures menu dates.
3. Administrator configures menu items.
4. Administrator configures stock.
5. Administrator configures pickup windows.
6. Administrator creates a staff account.
7. Staff member logs in independently.
8. Student registers or logs in.
9. Student browses the dated menu.
10. Student searches or filters menu items.
11. Student adds items to the cart.
12. Student selects a pickup window.
13. Student places an order.
14. System validates stock and pickup capacity.
15. Student receives a pickup code.
16. Staff views the pickup queue.
17. Staff changes the order from `PLACED` to `PREPARING`.
18. Staff changes the order from `PREPARING` to `READY`.
19. Student sees the updated order status.
20. Staff marks the order as `COLLECTED`.
21. Pickup-window reservation is released.
22. Administrator reviews reports.

---

# Validation Scenarios

The system can demonstrate the following database and application scenarios:

### Successful Order

A student places an order when sufficient stock and pickup capacity are available.

### Insufficient Stock

An order exceeding available stock is rejected.

### Unavailable Menu Item

An unavailable menu item cannot be ordered.

### Pickup Capacity

Orders cannot exceed the configured pickup-window capacity.

### Cancellation

An eligible `PLACED` order can be cancelled and its reserved stock restored.

### Staff Status Transitions

Staff can process orders through:

```text
PLACED
→ PREPARING
→ READY
→ COLLECTED
```

Invalid transitions are rejected.

### Status History

Every status change is recorded in:

```text
order_status_history
```

### Transaction Rollback

Failed order operations roll back database changes rather than leaving partially completed orders.

### User Management

Administrators can:

- Create staff accounts
- Activate/deactivate accounts
- Change roles
- Reset passwords

### Administrative Protection

An administrator cannot modify their own administrator account through the protected user-management operations.

---

# Database Files

The active database implementation is PostgreSQL.

```text
database/
├── postgresql/
│   ├── 01_schema.sql
│   ├── 02_seed_data.sql
│   ├── 03_demo_menu_09_to_13_oct.sql
│   ├── 03_order_functions.sql
│   ├── 04_queue_function.sql
│   ├── 05_status_trigger.sql
│   ├── 06_status_function.sql
│   └── 07_cancel_function.sql
│
└── queries/
    ├── 01_reports.sql
    └── 02_views.sql
```

The previous Oracle-specific database implementation has been removed from the project.

---

# Development Validation

Before committing changes, validate the backend with:

```powershell
cd backend
npm run build
```

Check the Git working tree with:

```powershell
git status
```

Commit changes with an appropriate commit message and push them to the configured remote repository.

---

# Project Status

## Current Status

**Final academic project scope**

The core student, staff, and administrator workflows are implemented.

The database has been migrated from Oracle AI Database Free to **PostgreSQL 18**, and the backend now uses **`pg` / node-postgres**.

The active project architecture is:

```text
React
  ↓
Node.js + Express
  ↓
pg / node-postgres
  ↓
PostgreSQL 18
```

The project is currently focused on:

- End-to-end testing
- Frontend/backend validation
- Database validation
- Documentation
- Deployment preparation
- Maintenance

Feature expansion should be avoided unless required by the academic project scope.

---

# Open Source

This project is intended to be published as an open-source academic project.

Before public distribution:

- Add an appropriate open-source license
- Verify that no `.env` files or credentials are committed
- Review database seed credentials
- Review documentation for development-only information

---

# Author

**Freejo**

GitHub:

https://github.com/freejo2003/CampusCafeteria