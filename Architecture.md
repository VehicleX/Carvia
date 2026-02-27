# Carvia System Architecture

## Entity Reference (ER) Diagram
This diagram outlines the primary NoSQL data structures mapped within Cloud Firestore. Although Firestore is schema-less, the app enforces these relational structures through data models.

```mermaid
erDiagram
    UserModel ||--o{ VehicleModel : "posts (if role=seller)"
    UserModel ||--o{ TestDriveModel : "books"
    UserModel ||--o{ OrderModel : "places"
    VehicleModel ||--o{ TestDriveModel : "receives"
    VehicleModel ||--o{ OrderModel : "associated with"

    UserModel {
        string uid PK
        string name
        string email
        string phone
        string role "buyer, seller, police"
        string accountType "individual, company"
        int credits
        bool isVerified
        map address
        map preferences
        map sellerDetails 
    }

    VehicleModel {
        string id PK
        string sellerId FK
        string brand
        string model
        int year
        string fuel
        string transmission
        double price
        int mileage
        string status "available, sold"
        string type
        string location
        map specs
    }

    TestDriveModel {
        string id PK
        string userId FK
        string sellerId FK
        string vehicleId FK
        string buyerName
        string buyerPhone
        datetime scheduledTime
        string status "pending, confirmed, completed, cancelled"
        string sellerLocation
        string meetingLocation
    }

    OrderModel {
        string id PK
        string userId FK
        string sellerId FK
        string vehicleId FK
        double amount
        datetime date
        string status "pending, confirmed, delivered, cancelled"
        string paymentMethod
        int creditsUsed
        int creditsEarned
    }
```

## Application Architecture

Carvia utilizes a **Clean Architecture** approach combined seamlessly with **Provider** for state management. This ensures maximum separation of concerns.

### Presentation Layer
- **UI Widgets:** Standard Flutter components (e.g., `ComparePage`, `HomeView`).
- **State Holders:** Providers that manage logical state bindings connecting pure UI to business processes.

### Domain Layer
- **Models:** Strongly typed Dart classes directly representing Core Entities (`VehicleModel.dart`, `UserModel.dart`). 
- **Business Logic Services:** Handlers like `CompareService.dart` taking atomic user intents and processing pure logic (e.g., maximum cap rules).

### Data Layer
- **Repositories & Apis:** Classes dedicated to abstracting away `cloud_firestore` logic (e.g., `VehicleService.dart`).
- **External Dependencies:** Firebase Auth, Firebase Storage, and Google Generative AI (Gemini).
