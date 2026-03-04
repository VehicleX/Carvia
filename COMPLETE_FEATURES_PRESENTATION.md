# CARVIA - COMPLETE FEATURES & SCREENS PRESENTATION
## Comprehensive Guide for Faculty Presentation - March 4, 2026

---

# 📱 COMPLETE APP WALKTHROUGH

## TABLE OF CONTENTS
1. [Authentication Module](#authentication-module)
2. [Buyer Module - All Features](#buyer-module)
3. [Seller Module - All Features](#seller-module)
4. [Police Module - All Features](#police-module)
5. [AI Assistant Features](#ai-assistant)
6. [Additional Features](#additional-features)
7. [Demo Script](#demo-script)

---

# 🔐 AUTHENTICATION MODULE

## Screen 1: Splash Screen
**File:** `lib/presentation/splash/`

### Features:
- **App Logo Display**: Carvia branding with animation
- **Loading Indicator**: Shows app initialization
- **Auto Navigation**: Redirects to login/home based on auth state

### Functionality:
1. Check if user is already logged in
2. Verify Firebase connection
3. Load user preferences and theme
4. Route to appropriate screen (Login or Home)

### Technical Details:
- Uses Firebase Auth to check authentication state
- Implements delayed navigation (2-3 seconds)
- Smooth fade-in animations with flutter_animate

---

## Screen 2: Login Page
**File:** `lib/presentation/auth/login_page.dart`

### Features:
- **Email/Password Login**: Traditional authentication
- **Google Sign-In**: OAuth with Google account
- **Remember Me**: Persistent login option
- **Forgot Password**: Password recovery link
- **Register Redirect**: Navigate to registration

### Form Fields:
1. **Email Input**
   - Email validation
   - Real-time error checking
   - Auto-lowercase conversion

2. **Password Input**
   - Secure text (masked)
   - Show/hide password toggle
   - Minimum length validation

### Functionality:
```
User Flow:
1. Enter email and password
2. Click "Login" button
3. Firebase Authentication validates credentials
4. On success: Navigate to role-based home screen
5. On failure: Show error message
```

### Google Sign-In Flow:
```
1. Click "Sign in with Google" button
2. Google account picker opens
3. User selects account
4. OAuth authentication
5. Create/update user in Firestore
6. Navigate to home screen
```

### Error Handling:
- Invalid email format
- Wrong password
- User not found
- Network errors
- Account disabled

---

## Screen 3: Register Page
**File:** `lib/presentation/auth/register_page.dart`

### Features:
- **Full Registration Form**: Complete user details
- **Role Selection**: Choose between Buyer, Seller, Police
- **Email/Password Registration**: Create new account
- **Profile Setup**: Basic profile information

### Form Fields:
1. **Full Name**: Text input with validation
2. **Email**: Unique email validation
3. **Phone Number**: 10-digit validation
4. **Password**: Minimum 6 characters
5. **Confirm Password**: Match validation
6. **Role Selection**: Dropdown (Buyer/Seller/Police)

### Functionality:
```
Registration Flow:
1. User fills all required fields
2. Form validation checks all inputs
3. Create Firebase Auth account
4. Create user document in Firestore
5. Assign role-based permissions
6. Navigate to Complete Profile page
```

### Validation Rules:
- Name: Minimum 3 characters
- Email: Valid email format, unique
- Phone: Exactly 10 digits
- Password: Minimum 6 characters, at least 1 number
- Role: Must select one option

---

## Screen 4: Forgot Password Page
**File:** `lib/presentation/auth/forgot_password_page.dart`

### Features:
- **Email Input**: Enter registered email
- **Send Reset Link**: Firebase password reset email
- **Success Confirmation**: Email sent notification

### Functionality:
```
Password Reset Flow:
1. Enter registered email address
2. Click "Send Reset Link"
3. Firebase sends password reset email
4. User clicks link in email
5. Redirected to reset password page
6. Enter new password and confirm
7. Login with new password
```

---

## Screen 5: Complete Profile Page
**File:** `lib/presentation/auth/complete_profile_page.dart`

### Features:
- **Profile Picture Upload**: Camera/gallery selection
- **Address Details**: Complete address form
- **Preferences**: User preferences setup
- **Account Type** (for sellers): Individual/Company
- **Seller Details** (for sellers): Business information

### Form Fields:

#### For All Users:
1. Profile Picture (optional)
2. City
3. State
4. PIN Code
5. Complete Address

#### For Sellers (Additional):
1. Account Type: Individual/Company
2. Business Name (if company)
3. GST Number (if company)
4. Showroom Address
5. Years in Business

#### For Buyers (Additional):
1. Preferred Vehicle Type
2. Budget Range
3. Preferred Brands

### Functionality:
```
Profile Completion Flow:
1. Upload profile picture (optional)
2. Fill address details
3. Role-specific fields appear
4. Submit profile
5. Update user document in Firestore
6. Navigate to role-based dashboard
```

---

# 🛒 BUYER MODULE - ALL FEATURES

## Screen 6: Buyer Home Dashboard
**File:** `lib/presentation/home/home_page.dart`

### Top Bar Features:
1. **Location Display**
   - Current city/location
   - Tap to change location
   - Opens map location picker

2. **Notification Bell**
   - Red dot for unread notifications
   - Badge count display
   - Tap to open notifications page

3. **Search Bar**
   - Real-time search
   - Search by brand, model, type
   - Search debouncing (optimized)

### Filter Section:
1. **Brand Filter**
   - Dropdown list of all brands
   - Multi-select capability
   - "All Brands" option

2. **Vehicle Type Filter**
   - Sedan, SUV, Hatchback, etc.
   - Icon-based selection
   - "All Types" option

3. **Price Range Slider**
   - Min: ₹0, Max: ₹50,00,000
   - Dual handle slider
   - Real-time price display
   - Format: Indian currency (₹)

4. **Fuel Type Filter**
   - Petrol, Diesel, Electric, Hybrid, CNG
   - Chip-based selection
   - Multiple selection allowed

5. **Transmission Filter**
   - Manual, Automatic
   - Toggle buttons
   - Single selection

6. **Year Filter**
   - Slider for manufacturing year
   - Range: 2000 - 2026
   - "All Years" option

### Vehicle Listing Section:
1. **Grid/List View Toggle**
   - Switch between grid and list layout
   - Preference saved locally

2. **Sort Options**
   - Price: Low to High
   - Price: High to Low
   - Year: Newest First
   - Year: Oldest First
   - Mileage: Best First
   - Recently Added

3. **Vehicle Cards Display**
   Each card shows:
   - Primary vehicle image
   - Brand & Model name
   - Year of manufacture
   - Price (formatted)
   - Key specs (Fuel, Transmission, Mileage)
   - Wishlist heart icon
   - Compare checkbox icon
   - "View Details" button

### Quick Actions (Floating Action Buttons):
1. **AI Chat Assistant**
   - Bottom-right floating button
   - Opens AI chat interface
   - Gemini AI icon

2. **Voice Assistant**
   - Microphone icon button
   - Opens voice assistant bottom sheet
   - Speech-to-text enabled

3. **Compare Button**
   - Shows selected vehicle count badge
   - Quick access to comparison page
   - Maximum 2 vehicles allowed

### Functionality Details:

#### Real-time Filtering:
```
Filter Logic:
1. User selects filters
2. Query rebuilds automatically
3. Firestore query with combined filters
4. Results update in real-time
5. Shows "No vehicles found" if empty
6. Reset filters option available
```

#### Wishlist Toggle:
```
Wishlist Flow:
1. User taps heart icon on vehicle card
2. Check if user is logged in
3. Add/remove vehicle ID to user's wishlist array
4. Update Firestore document
5. UI updates immediately (Provider)
6. Show snackbar confirmation
```

#### Add to Compare:
```
Compare Flow:
1. User taps compare checkbox
2. Add vehicle to compare list (max 2)
3. If already 2 vehicles, show "Remove one first"
4. Compare button badge updates
5. Navigate to compare page
```

---

## Screen 7: Vehicle Detail Page
**File:** `lib/presentation/vehicle/vehicle_detail_page.dart`

### Header Section:
1. **Back Button**: Navigate back
2. **Wishlist Icon**: Add/remove from wishlist
3. **Share Button**: Share vehicle details

### Image Gallery:
1. **Full-Screen Image Slider**
   - Swipeable image carousel
   - Multiple vehicle images
   - Zoom capability
   - Page indicator dots
   - Full-screen view on tap

2. **Image Count**: Shows "1/5" format
3. **Placeholder**: Default car icon if no images

### Vehicle Information Sections:

#### Basic Details:
```
Display:
- Brand & Model (Large title)
- Year of Manufacture
- Price (Prominent, formatted)
- Location (City with pin icon)
- Registration Number
- Status (Available/Sold badge)
```

#### Key Specifications Card:
```
Grid Layout (2 columns):
1. Fuel Type (icon + label)
2. Transmission (icon + label)
3. Mileage (km/l)
4. Engine Capacity (cc)
5. Kilometers Driven
6. Number of Owners
7. Color
8. Seating Capacity
```

#### Detailed Specifications:

1. **Engine & Performance**
   - Engine Type
   - Engine Capacity (cc)
   - Power (bhp)
   - Torque (Nm)
   - Top Speed
   - Acceleration (0-100 km/h)

2. **Dimensions & Capacity**
   - Length
   - Width
   - Height
   - Wheelbase
   - Ground Clearance
   - Boot Space
   - Fuel Tank Capacity

3. **Features & Comfort**
   - Air Conditioning
   - Power Steering
   - Power Windows
   - Central Locking
   - Airbags (count)
   - ABS/EBS
   - Parking Sensors
   - Reverse Camera
   - Touchscreen Infotainment
   - Music System
   - Bluetooth
   - USB Ports
   - Sunroof
   - Leather Seats
   - Cruise Control

4. **Safety Features**
   - Airbags count
   - ABS (Anti-lock Braking)
   - EBD (Electronic Brake Distribution)
   - Traction Control
   - Stability Control
   - Hill Assist
   - ISOFIX Child Seat Mounts
   - Seat Belt Warning
   - Speed Alert

### Seller Information Card:
```
Display:
- Seller name
- Seller type (Individual/Dealer)
- Verification badge (if verified)
- Phone number
- Location
- "Call Seller" button
- "Message" button (future)
```

### View Counter:
- Shows total views count
- Increments on page load
- Displayed with eye icon

### Action Buttons (Bottom Bar):

1. **Add to Wishlist**
   - Heart icon
   - Toggle animation
   - Updates immediately

2. **Add to Compare**
   - Compare icon
   - Shows count badge
   - Max 2 vehicles limit

3. **Book Test Drive**
   - Primary action button
   - Opens test drive booking page
   - Requires login

4. **Buy Now**
   - Prominent CTA button
   - Opens checkout page
   - Check if vehicle available

### AI Assistant Integration:
- **"Ask AI about this vehicle"** button
- Context-aware questions
- Pre-filled prompts:
  - "Tell me more about this car"
  - "Is this a good deal?"
  - "What are similar vehicles?"
  - "Compare with [another car]"

### Functionality:

#### View Count Tracking:
```
1. Page loads
2. Vehicle ID sent to VehicleService
3. Firestore increment view count
4. Update happens in background
5. Displayed to user
```

#### Call Seller:
```
1. User taps "Call Seller"
2. Permission check (phone)
3. Launch phone dialer
4. Pre-filled with seller number
5. Track call initiation (analytics)
```

#### Test Drive Booking:
```
1. Check user authentication
2. Check vehicle availability
3. Open BookTestDrivePage
4. Pre-fill vehicle details
5. User selects date/time
6. Submit booking request
```

---

## Screen 8: Vehicle Comparison Page
**File:** `lib/presentation/vehicle/compare_page.dart`

### Header:
1. **Title**: "Compare Vehicles"
2. **Clear All Button**: Remove all vehicles from comparison
3. **Back Button**: Return to previous screen

### Empty State:
```
Display when no vehicles:
- Icon: Compare arrows
- Message: "No vehicles to compare"
- "Add Vehicle" button
- Opens vehicle selection bottom sheet
```

### Comparison Table Layout:

#### Table Structure:
```
| Specification    | Vehicle 1        | Vehicle 2        |
|------------------|------------------|------------------|
| Image            | [Image]          | [Image]          |
| Brand & Model    | Honda City       | Maruti Ciaz      |
| Price            | ₹12,50,000 ✓     | ₹13,00,000       |
| Year             | 2023             | 2022 ✓           |
| Fuel Type        | Petrol           | Petrol           |
| Transmission     | Automatic        | Manual ✓         |
| Mileage          | 18.5 km/l ✓      | 17.2 km/l        |
| Engine           | 1498 cc          | 1462 cc ✓        |
| Power            | 119 bhp ✓        | 103 bhp          |
| Kilometers       | 15,000 ✓         | 25,000           |
| Color            | White            | Silver           |
| Owners           | 1 ✓              | 2                |
```

### Features:

1. **Smart Highlighting**
   - Better value highlighted in green
   - Lower price = green
   - Better mileage = green
   - Lower kilometers = green
   - Higher power = green
   - Fewer owners = green

2. **Horizontal Scroll**
   - Table scrolls horizontally
   - Sticky first column (specifications)
   - Smooth scrolling

3. **Quick Actions on Each Vehicle**
   - View Details button
   - Remove from comparison
   - Add to Wishlist
   - Book Test Drive
   - Buy Now

4. **Add/Replace Vehicle**
   - "+" button below each vehicle
   - Opens vehicle selection sheet
   - Search and filter
   - Select new vehicle

5. **Comparison Insights** (AI-Powered)
   - "Ask AI to Compare" button
   - Generates comparison summary
   - Pros/cons of each vehicle
   - Recommendation based on value

### Bottom Sheet: Vehicle Selection
```
Features:
- Search bar
- Brand filter
- Price filter
- List of all available vehicles
- Checkbox selection
- "Add to Compare" button
- Close button
```

### Functionality:

#### Add Vehicle to Compare:
```
1. User clicks "Add to Compare" on any vehicle
2. CompareService checks current count
3. If < 2: Add to list
4. If = 2: Show "Remove one first" message
5. Update UI with Provider
6. Navigate to comparison page
```

#### Comparison Logic:
```
For each specification:
1. Get values from both vehicles
2. Determine which is "better"
3. Apply highlighting style
4. Handle ties (no highlight)
5. Handle missing data (show N/A)
```

---

## Screen 9: Book Test Drive Page
**File:** `lib/presentation/vehicle/book_test_drive_page.dart`

### Header:
- Vehicle image preview
- Vehicle name (Brand + Model)
- Price display

### Form Fields:

1. **Your Name**
   - Auto-filled from user profile
   - Editable

2. **Phone Number**
   - Auto-filled from user profile
   - 10-digit validation
   - Editable

3. **Email** (optional)
   - Auto-filled from user profile
   - Email validation

4. **Preferred Date**
   - Date picker
   - Cannot select past dates
   - Minimum: Tomorrow
   - Maximum: 30 days from now

5. **Preferred Time**
   - Time picker
   - Business hours only (9 AM - 6 PM)
   - 30-minute intervals

6. **Meeting Location Preference**
   - Radio buttons:
     - Seller's location
     - My location
     - Custom location
   
7. **Custom Location** (if selected)
   - Text input
   - "Pick on Map" button
   - Opens map location picker

8. **Additional Notes** (optional)
   - Multiline text input
   - Max 500 characters
   - Placeholder: "Any specific requirements?"

### Seller Information Display:
```
- Seller name
- Seller contact
- Seller address
- "Call Seller" button
```

### Action Buttons:
1. **Cancel**: Go back
2. **Submit Request**: Book test drive

### Functionality:

#### Booking Flow:
```
1. User fills form
2. Validate all required fields
3. Create TestDriveModel object
4. Save to Firestore 'test_drives' collection
5. Send notification to seller
6. Show success dialog
7. Navigate back to home
```

#### TestDrive Document Structure:
```javascript
{
  id: "auto-generated",
  userId: "buyer-uid",
  sellerId: "seller-uid",
  vehicleId: "vehicle-id",
  buyerName: "John Doe",
  buyerPhone: "+91 9876543210",
  buyerEmail: "john@example.com",
  scheduledDate: Timestamp,
  scheduledTime: "14:30",
  status: "pending", // pending, confirmed, completed, cancelled
  sellerLocation: {
    address: "...",
    coordinates: GeoPoint
  },
  meetingLocation: {
    address: "...",
    coordinates: GeoPoint
  },
  notes: "...",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Success Dialog:
```
Display:
- Success icon
- "Test Drive Booked!"
- Booking details summary
- "View My Bookings" button
- "Back to Home" button
```

---

## Screen 10: Test Drives Page (Buyer)
**File:** `lib/presentation/vehicle/test_drives_page.dart`

### Tab Structure:
1. **Upcoming** - Pending & Confirmed bookings
2. **Past** - Completed & Cancelled bookings

### Test Drive Card Display:

#### Card Information:
```
Display:
- Vehicle image
- Vehicle name (Brand + Model)
- Scheduled date & time
- Status badge:
  - Pending (Orange)
  - Confirmed (Green)
  - Completed (Blue)
  - Cancelled (Red)
- Seller name
- Seller phone
- Meeting location
- Notes (if any)
```

#### Action Buttons (Based on Status):

**For Pending:**
- "Contact Seller" - Call/message
- "Cancel Booking" - Cancel test drive

**For Confirmed:**
- "Get Directions" - Open in maps
- "Contact Seller" - Call/message
- "Reschedule" - Change date/time
- "Cancel Booking" - Cancel test drive

**For Completed:**
- "Book Again" - New booking
- "Buy This Vehicle" - Checkout
- "View Vehicle" - Detail page

**For Cancelled:**
- "Book Again" - New booking
- Cancellation reason display

### Filters & Sorting:
1. **Filter by Status**: All, Pending, Confirmed, Completed, Cancelled
2. **Sort by Date**: Newest first, Oldest first
3. **Search**: By vehicle name

### Empty States:
```
Upcoming: "No upcoming test drives"
Past: "No past test drives"
CTA: "Browse Vehicles" button
```

### Functionality:

#### Cancel Booking:
```
1. Show confirmation dialog
2. Ask for cancellation reason
3. Update status to 'cancelled'
4. Send notification to seller
5. Refresh list
```

#### Reschedule:
```
1. Open date/time picker
2. Validate new date/time
3. Update Firestore document
4. Send notification to seller
5. Show success message
```

---

## Screen 11: Checkout Page
**File:** `lib/presentation/vehicle/checkout_page.dart`

### Order Summary Section:
```
Display:
- Vehicle image
- Vehicle name
- Vehicle price
- Platform fee (if any)
- Taxes (calculated)
- Total amount (bold, large)
```

### Buyer Information:
```
Auto-filled from profile:
- Full name
- Email
- Phone number
- Delivery address
Edit option available
```

### Credits Section:
```
Display:
- Available credits
- Credit value (₹1 per credit)
- "Use Credits" checkbox
- Credits to use (slider)
- Final amount after credits
```

### Payment Method Selection:
```
Options:
1. Credit/Debit Card (future)
2. UPI (future)
3. Net Banking (future)
4. Cash on Delivery
5. Pay at Dealership
```

### Terms & Conditions:
- Checkbox: "I agree to terms and conditions"
- Link to T&C document

### Action Buttons:
1. **Back**: Return to vehicle detail
2. **Place Order**: Confirm purchase

### Functionality:

#### Place Order Flow:
```
1. Validate all fields
2. Check vehicle availability
3. Calculate final amount
4. Deduct credits from user account
5. Create OrderModel document
6. Update vehicle status (if direct purchase)
7. Send notification to seller
8. Earn purchase credit bonus
9. Show order confirmation
10. Navigate to orders page
```

#### Order Document Structure:
```javascript
{
  id: "auto-generated",
  userId: "buyer-uid",
  sellerId: "seller-uid",
  vehicleId: "vehicle-id",
  vehicleName: "Honda City 2023",
  vehiclePrice: 1250000,
  platformFee: 5000,
  taxes: 12500,
  creditsUsed: 1000,
  finalAmount: 1266500,
  paymentMethod: "Pay at Dealership",
  status: "pending", // pending, confirmed, delivered, cancelled
  buyerDetails: {...},
  deliveryAddress: {...},
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Order Confirmation Dialog:
```
Display:
- Success animation
- "Order Placed Successfully!"
- Order ID
- Order summary
- "Track Order" button
- "Continue Shopping" button
```

---

## Screen 12: Wishlist Page
**File:** `lib/presentation/vehicle/wishlist_page.dart`

### Header:
- Title: "My Wishlist"
- Count badge: Number of vehicles
- "Clear All" button

### Vehicle List Display:
```
Each wishlist item shows:
- Vehicle image
- Brand & Model
- Year
- Price
- Status (Available/Sold)
- "View Details" button
- "Remove" icon
- "Add to Compare" checkbox
- "Book Test Drive" button
- "Buy Now" button (if available)
```

### Quick Actions:
1. **Sort**: Price, date added, name
2. **Filter**: Available only, price range
3. **Compare Selected**: Add up to 2 to compare
4. **Share Wishlist**: Share list with others

### Empty State:
```
Display:
- Heart icon
- "Your wishlist is empty"
- "Browse Vehicles" button
```

### Functionality:

#### Remove from Wishlist:
```
1. User taps remove icon
2. Show confirmation (optional)
3. Remove vehicle ID from user's wishlist array
4. Update Firestore
5. Update UI
6. Show snackbar: "Removed from wishlist"
```

#### Price Change Notification:
```
Feature (Future Enhancement):
- Track price changes
- Notify if wishlist vehicle price drops
- Show "Price Dropped" badge
```

---

## Screen 13: My Orders Page
**File:** `lib/presentation/profile/orders_page.dart`

### Tab Structure:
1. **Active** - Pending & Confirmed orders
2. **Completed** - Delivered orders
3. **Cancelled** - Cancelled orders

### Order Card Display:

#### Card Information:
```
Display:
- Order ID
- Order date
- Vehicle image
- Vehicle name
- Price paid
- Status badge (color-coded)
- Seller information
- Delivery address
- Payment method
- Timeline tracker
```

#### Status Timeline:
```
Visual timeline showing:
1. Order Placed ✓
2. Confirmed by Seller (pending/completed)
3. Ready for Delivery (pending/completed)
4. Delivered (pending/completed)
```

#### Action Buttons (Based on Status):

**For Pending:**
- "Contact Seller"
- "Cancel Order"

**For Confirmed:**
- "Contact Seller"
- "Track Delivery"
- "Cancel Order" (with penalty)

**For Delivered:**
- "View Invoice"
- "Rate & Review" (future)
- "Buy Again" (same model)

**For Cancelled:**
- "Reorder"
- "View Cancellation Details"

### Filters & Search:
1. Filter by status
2. Filter by date range
3. Search by order ID or vehicle name
4. Sort: Recent first, oldest first

### Empty States:
```
Active: "No active orders"
Completed: "No completed orders"
Cancelled: "No cancelled orders"
CTA: "Start Shopping" button
```

---

## Screen 14: Insurance Page
**File:** `lib/presentation/vehicle/insurance_page.dart`

### Features:
1. **Insurance Information**
   - What is vehicle insurance?
   - Types of insurance
   - Why you need it

2. **Insurance Calculator**
   - Vehicle type selection
   - Vehicle value input
   - Coverage type selection
   - Premium estimate

3. **Insurance Providers**
   - List of partner insurance companies
   - Features comparison
   - "Get Quote" buttons
   - External links to providers

4. **For Your Vehicles**
   - List of user's vehicles
   - Insurance status (Active/Expired)
   - Renewal reminders
   - "Buy Insurance" CTA

### Functionality:
```
1. Informational content display
2. Premium calculation (basic)
3. External links to insurance providers
4. Save insurance details (future)
```

---

## Screen 15: E-Challan Page (Buyer)
**File:** `lib/presentation/challan/e_challan_page.dart`

### Features:

1. **Search by Vehicle Number**
   - Input field for registration number
   - "Search" button
   - Recent searches saved

2. **Your Vehicles Section**
   - List of vehicles owned by user
   - "Check Challans" button for each
   - Total unpaid challans badge

3. **Challan List Display**
   ```
   Each challan shows:
   - Challan number
   - Vehicle number
   - Violation type
   - Fine amount
   - Issue date
   - Status (Paid/Unpaid)
   - Issued by (Police station/Officer)
   - Payment due date
   - "View Details" button
   - "Pay Now" button (if unpaid)
   ```

4. **Challan Details Modal**
   ```
   Full information:
   - Challan image/photo
   - Violation details
   - Location of violation
   - Officer name & badge number
   - Fine breakdown
   - Payment options
   - "Download Challan" option
   ```

5. **Payment Integration**
   - Pay online (future)
   - Payment confirmation
   - Receipt generation

### Filters:
1. Status: All, Paid, Unpaid, Overdue
2. Date range
3. Violation type
4. Sort by date/amount

### Empty State:
```
"No challans found"
"Drive safe!" message
```

---

## Screen 16: Ownership Transfer Page
**File:** `lib/presentation/vehicle/transfer_ownership_page.dart`

### Features:

1. **Select Vehicle**
   - Dropdown of user's vehicles
   - Vehicle details display

2. **New Owner Information**
   ```
   Form fields:
   - New owner name
   - New owner phone
   - New owner email
   - New owner address
   - Aadhar number
   - PAN number (optional)
   ```

3. **Document Upload**
   ```
   Required documents:
   - Transfer form (signed)
   - Insurance transfer
   - PUC certificate
   - NOC from bank (if loan)
   - Photo ID of new owner
   ```

4. **Transfer Fee**
   - RTO fee calculation
   - Platform service fee
   - Total amount display

5. **Initiate Transfer**
   - Submit request
   - Generate transfer request ID
   - Track transfer status

### Functionality:
```
Transfer flow:
1. Select vehicle to transfer
2. Enter new owner details
3. Upload required documents
4. Pay transfer fees
5. Submit to RTO (simulated)
6. Track approval status
7. Receive transfer confirmation
```

---

## Screen 17: Profile Page (Buyer)
**File:** `lib/presentation/profile/profile_page.dart`

### Profile Header:
```
Display:
- Profile picture (editable)
- Name
- Email
- Phone number
- Member since date
- Credits balance (prominent)
- Verification status badge
```

### Menu Options:

1. **My Wishlist**
   - Count badge
   - Navigate to wishlist page

2. **My Orders**
   - Count of active orders
   - Navigate to orders page

3. **Test Drives**
   - Upcoming count badge
   - Navigate to test drives page

4. **My Vehicles** (if owns vehicles)
   - Count of vehicles
   - Navigate to vehicle management

5. **Credits & Rewards**
   - Current balance
   - Transaction history
   - How to earn more
   - Navigate to credits page

6. **Settings**
   - Navigate to settings page

7. **About & Help**
   - Navigate to about page

8. **Logout**
   - Logout confirmation
   - Clear local data
   - Navigate to login

### Quick Stats Card:
```
Display:
- Total orders
- Active test drives
- Wishlist count
- Credits earned
```

---

## Screen 18: Settings Page
**File:** `lib/presentation/profile/settings_page.dart`

### Sections:

#### Account Settings:
1. Edit Profile
2. Change Password
3. Linked Accounts (Google)
4. Delete Account

#### App Settings:
1. **Theme**
   - Dark Mode (default)
   - Light Mode
   - System Default

2. **Notifications**
   - Push notifications toggle
   - Email notifications toggle
   - SMS notifications toggle
   - Notification preferences

3. **Language** (future)
   - English (default)
   - Hindi
   - Regional languages

4. **Location**
   - Current location
   - Change location
   - Auto-detect location

#### Privacy & Security:
1. Privacy Policy
2. Terms of Service
3. Data & Privacy
4. Security Settings

#### Other:
1. About App
2. Rate App
3. Share App
4. Help & Support
5. App Version

---

## Screen 19: About & Credits Page
**File:** `lib/presentation/profile/about_credits_page.dart`

### Credit System Information:

#### How to Earn Credits:
```
Display list:
1. Sign up bonus: 100 credits
2. Complete profile: 50 credits
3. First purchase: 200 credits
4. Each purchase: 1% of amount
5. Refer a friend: 100 credits
6. Daily login: 5 credits
7. Add vehicle review: 20 credits
8. Share vehicle: 10 credits
```

#### How to Use Credits:
```
- 1 credit = ₹1
- Redeem on purchases
- Minimum 100 credits to redeem
- Maximum 50% of purchase value
- No expiry
```

#### Credit History:
```
Transaction list showing:
- Date
- Description
- Credits earned/used
- Balance after transaction
- Filter by type (earned/used)
```

### About App Section:
```
- App version
- Last updated
- Developer information
- Contact details
- Social media links
- Open source licenses
```

---

## Screen 20: Notifications Page
**File:** `lib/presentation/home/notifications_page.dart`

### Notification Types:

1. **Test Drive Updates**
   - Booking confirmed
   - Booking rescheduled
   - Booking cancelled
   - Reminder (1 day before)

2. **Order Updates**
   - Order confirmed
   - Ready for delivery
   - Out for delivery
   - Delivered
   - Order cancelled

3. **Wishlist Alerts**
   - Price drop notification
   - Vehicle sold out
   - Back in stock

4. **System Notifications**
   - Welcome message
   - Profile completion reminder
   - Credit earned
   - New features

5. **Promotional**
   - Special offers
   - New arrivals
   - Seasonal sales

### Notification Card:
```
Display:
- Icon (type-based)
- Title
- Message
- Time ago
- Read/unread indicator
- Action buttons (if applicable)
- Swipe to delete
```

### Actions:
1. Mark as read
2. Mark all as read
3. Delete notification
4. Clear all
5. Filter by type
6. Navigate to relevant page

---

## Screen 21: Map Location Picker
**File:** `lib/presentation/home/map_location_picker.dart`

### Features:

1. **Interactive Map**
   - Google Maps integration
   - Current location marker
   - Draggable pin
   - Zoom controls
   - Map type toggle (Normal/Satellite)

2. **Location Search**
   - Search bar
   - Autocomplete suggestions
   - Recent searches
   - Nearby places

3. **Address Display**
   - Auto-reverse geocoding
   - Complete address shown
   - Edit address option

4. **Actions**
   - "Use Current Location" button
   - "Confirm Location" button
   - "Cancel" button

### Functionality:
```
1. Request location permission
2. Get current location
3. Display on map
4. User can drag pin or search
5. Reverse geocode to get address
6. Confirm and return address
```

---

## Screen 22: Add External Vehicle
**File:** `lib/presentation/vehicle/add_external_vehicle_page.dart`

### Purpose:
Allow buyers to add their currently owned vehicles to their profile for:
- Ownership transfer management
- E-challan checking
- Insurance tracking
- Service reminders

### Form Fields:

1. **Basic Information**
   - Brand (dropdown)
   - Model (dropdown based on brand)
   - Year of manufacture
   - Registration number
   - Color

2. **Purchase Details**
   - Purchase date
   - Purchase price
   - Kilometers at purchase

3. **Current Details**
   - Current kilometers
   - Last service date

4. **Documents** (optional)
   - RC copy upload
   - Insurance copy upload
   - PUC certificate

5. **Add Photos** (optional)
   - Multiple vehicle photos

### Functionality:
```
1. Fill vehicle details
2. Upload documents
3. Save to user's vehicles collection
4. Use for challan checking
5. Use for ownership transfer
```

---

# 💼 SELLER MODULE - ALL FEATURES

## Screen 23: Seller Dashboard
**File:** `lib/presentation/seller/seller_dashboard.dart`

### Header Section:
```
Display:
- Welcome message with seller name
- Profile picture
- Credits balance (prominent)
- Seller rating (future)
- Verification badge
```

### Analytics Cards (4 Cards):

1. **Total Listings**
   - Count of active vehicles
   - Icon: Car
   - "Manage" button

2. **Total Orders**
   - Count of received orders
   - Pending orders badge
   - "View All" button

3. **Test Drive Requests**
   - Pending count
   - Confirmed today count
   - "Manage" button

4. **Revenue**
   - Total earnings
   - This month earnings
   - "View Analytics" button

### Chart Section:

1. **Sales Chart**
   - Bar chart: Monthly sales
   - Last 6 months data
   - Toggle: Revenue/Orders count

2. **Performance Metrics**
   - Response rate
   - Conversion rate
   - Average deal time

### Recent Activity:
```
Timeline display:
- Recent orders
- Test drive confirmations
- New inquiries
- Reviews received
- Vehicles view count updates
```

### Quick Actions (Floating Action Buttons):

1. **Add Vehicle**
   - Primary FAB
   - Opens add vehicle page

2. **View Orders**
   - Navigate to orders page

3. **Analytics**
   - Navigate to analytics page

### Top Performing Vehicles:
```
Card display:
- Vehicle image
- Name
- Views count
- Inquiries count
- Orders count
- "View Details" button
```

---

## Screen 24: Add Vehicle Page
**File:** `lib/presentation/seller/add_vehicle_page.dart`

### Form Structure:

#### Step 1: Basic Information
```
Fields:
1. Brand (Dropdown)
   - Honda, Maruti, Hyundai, Tata, etc.
   - "Other" option with text input

2. Model (Dropdown - based on brand)
   - Dynamic list
   - "Other" option with text input

3. Year (Number input/Dropdown)
   - Range: 2000-2026
   - Validation: Cannot be future year

4. Vehicle Type (Dropdown)
   - Sedan, SUV, Hatchback, MPV, Luxury, Sports

5. Registration Number
   - Text input
   - Format: XX-00-XX-0000
   - Validation for format
   - Must be unique

6. Color (Dropdown)
   - Common colors
   - "Other" option

7. Price (Number input)
   - In Indian Rupees
   - Validation: > 0
   - Format helper (lakhs/crores)

8. Status (Dropdown)
   - Available
   - Sold
   - Reserved
```

#### Step 2: Specifications
```
Engine & Performance:
1. Fuel Type (Dropdown)
   - Petrol, Diesel, Electric, Hybrid, CNG

2. Transmission (Dropdown)
   - Manual, Automatic, CVT, DCT

3. Mileage (Number input)
   - km/l or km/charge
   - Validation: > 0

4. Engine Capacity (Number input)
   - In CC
   - Validation: 500-5000

5. Power (Number input)
   - In bhp
   - Optional

6. Torque (Number input)
   - In Nm
   - Optional

Condition:
1. Kilometers Driven (Number input)
   - Current odometer reading
   - Validation: >= 0

2. Number of Owners (Dropdown)
   - 1st, 2nd, 3rd, 4th, 5+

3. Service History (Dropdown)
   - Full, Partial, Not Available

4. Accident History (Yes/No toggle)
   - If yes: text description

5. Insurance Valid Till (Date picker)
   - Must be valid date

6. PUC Valid Till (Date picker)
   - Must be valid date
```

#### Step 3: Features & Comfort
```
Checkboxes for:
Safety:
- Airbags (number input if checked)
- ABS/EBS
- Traction Control
- Stability Control
- Hill Assist
- Parking Sensors
- Reverse Camera
- ISOFIX Mounts

Comfort:
- Air Conditioning (Manual/Automatic)
- Power Steering
- Power Windows (Front/All)
- Central Locking
- Keyless Entry
- Push Button Start
- Cruise Control
- Climate Control

Entertainment:
- Music System
- Touchscreen Infotainment
- Screen Size (if applicable)
- Bluetooth
- USB Ports
- Wireless Charging
- Speaker Count

Interior:
- Leather Seats
- Adjustable Seats
- Sunroof/Moonroof
- Ambient Lighting
- Cup Holders

Exterior:
- Alloy Wheels
- LED Headlights
- LED Taillights
- Fog Lights
- Roof Rails
```

#### Step 4: Dimensions
```
Optional fields:
1. Length (mm)
2. Width (mm)
3. Height (mm)
4. Wheelbase (mm)
5. Ground Clearance (mm)
6. Boot Space (liters)
7. Fuel Tank Capacity (liters)
8. Seating Capacity (number)
9. Weight (kg)
```

#### Step 5: Photos
```
Image Upload:
- Minimum 1 image required
- Maximum 10 images
- Sources:
  - Camera
  - Gallery
  - Multiple selection
- Image requirements:
  - Max size: 5MB per image
  - Formats: JPG, PNG
  - Compression applied
- Drag to reorder
- Set primary image
- Delete option
- Image preview
```

#### Step 6: Location & Contact
```
Fields:
1. Vehicle Location (Auto-filled from seller profile)
   - City
   - State
   - Complete address
   - "Change" button
   - Map integration

2. Seller Contact (Auto-filled)
   - Name
   - Phone
   - Alternate phone (optional)
   - Preferred contact time

3. Shipping Available (Yes/No toggle)
   - If yes: Shipping charges

4. Home Delivery Available (Yes/No toggle)
   - If yes: Delivery radius
```

#### Step 7: Additional Information
```
Fields:
1. Description (Multiline text)
   - Max 1000 characters
   - Key highlights
   - Special features
   - Reason for selling (optional)

2. Best Time to View
   - Text input
   - Example: "Mon-Sat, 10 AM - 6 PM"

3. Negotiable (Yes/No toggle)

4. Exchange Offer (Yes/No toggle)

5. Finance Available (Yes/No toggle)
   - Partner banks/finance companies

6. Test Drive Available (Yes/No toggle)
   - Default: Yes
```

### Form Actions:

1. **Save as Draft**
   - Save incomplete form
   - Continue later

2. **Preview**
   - Show how listing will look
   - Edit before publishing

3. **Publish Listing**
   - Validate all required fields
   - Upload images to Firebase Storage
   - Create vehicle document in Firestore
   - Show success message
   - Navigate to manage listings

### Validation:
```
Required fields:
- Brand, Model, Year
- Vehicle Type
- Registration Number (unique)
- Price
- Fuel Type, Transmission
- Kilometers Driven
- At least 1 photo
- Location

Optional but recommended:
- Complete specifications
- All features
- Detailed description
- Multiple photos
```

### Image Upload Process:
```
1. User selects images
2. Compress images (client-side)
3. Show upload progress
4. Upload to Firebase Storage
5. Get download URLs
6. Save URLs in vehicle document
7. Handle errors (retry option)
```

---

## Screen 25: Manage Listings Page
**File:** `lib/presentation/seller/manage_listings_page.dart`

### Header:
- Total listings count
- "Add New Vehicle" button
- Filter and sort options

### Vehicle Cards Display:
```
Each card shows:
- Primary image
- Brand & Model
- Year, Price
- Status badge (Available/Sold/Reserved)
- View count (eye icon)
- Inquiry count
- Order count
- Last updated

Action buttons:
- Edit (pencil icon)
- Delete (trash icon)
- Mark as Sold/Available (toggle)
- Boost/Promote (future)
```

### Filters:
1. Status: All, Available, Sold, Reserved, Draft
2. Sort: Recent, Oldest, Price (H-L), Price (L-H), Most Viewed

### Bulk Actions:
1. Select multiple vehicles
2. Delete selected
3. Change status (batch)
4. Export data

### Analytics Per Vehicle:
```
Tap vehicle card to see:
- Total views
- Unique views
- Views this week
- Test drive requests
- Wishlisted by (count)
- In comparison (count)
- Inquiries
- Orders
- Revenue generated
- Days listed
```

### Edit Vehicle:
- Opens add vehicle form
- Pre-filled with current data
- Auto-save changes
- Version history (future)

### Delete Vehicle:
```
Confirmation dialog:
- "Are you sure?"
- Warning if has pending orders
- Reason for deletion (optional)
- Confirm button
- Soft delete (archived, not permanent)
```

---

## Screen 26: Seller Test Drives Page
**File:** `lib/presentation/seller/seller_test_drives_page.dart`

### Tab Structure:
1. **Pending** - Awaiting confirmation
2. **Confirmed** - Accepted bookings
3. **Today** - Today's scheduled drives
4. **Past** - Completed & cancelled

### Test Drive Request Card:

#### Display Information:
```
- Buyer name
- Buyer phone number
- Buyer photo (if available)
- Vehicle name & image
- Requested date & time
- Meeting location preference
- Special notes (if any)
- Request received time
```

#### Action Buttons (for Pending):

1. **Accept**
   - Confirm the booking
   - Set final meeting location
   -Optional: Suggest alternate time
   - Send confirmation to buyer
   - Move to "Confirmed" tab

2. **Suggest New Time**
   - Open date/time picker
   - Send counter-proposal
   - Buyer can accept/reject

3. **Reject**
   - Reason selection (required)
   - Notify buyer
   - Move to cancelled

4. **Contact Buyer**
   - Call directly
   - Send message (future)

#### For Confirmed Test Drives:
```
Actions:
- View buyer details
- Get directions to meeting location
- Call buyer
- Reschedule
- Cancel (with reason)
- Mark as Completed
- No-show (if buyer doesn't arrive)
```

#### For Today's Test Drives:
```
Special features:
- Time-sorted list
- Next appointment highlighted
- Countdown timer
- "Start Navigation" button
- Quick call button
- Checklist before test drive:
  - Vehicle cleaned ✓
  - Fuel/charge sufficient ✓
  - Documents ready ✓
  - Keys ready ✓
```

### Calendar View:
- Toggle to calendar layout
- See all bookings in month view
- Color-coded by status
- Tap date to see that day's bookings

### Filters & Search:
1. Search by buyer name
2. Filter by vehicle
3. Date range filter
4. Meeting location filter

### Statistics:
```
Display:
- Total test drives this month
- Conversion rate (test drive → sale)
- Average rating received
- Most requested vehicle
- Peak booking times
```

---

## Screen 27: Seller Orders Page
**File:** `lib/presentation/seller/seller_orders_page.dart`

### Tab Structure:
1. **New** - Pending confirmation
2. **Processing** - Confirmed orders
3. **Delivered** - Completed sales
4. **Cancelled** - Cancelled orders

### Order Card Display:

#### Card Information:
```
- Order ID & date
- Buyer name & contact
- Buyer photo
- Vehicle details
- Order amount
- Payment method
- Credits used by buyer
- Status timeline
- Delivery address
- Special instructions
```

#### Action Buttons (for New Orders):

1. **Accept Order**
   - Confirm availability
   - Set delivery date
   - Send confirmation to buyer
   - Move to "Processing"

2. **Reject Order**
   - Reason required
   - Notify buyer
   - Initiate refund (if paid)

3. **Contact Buyer**
   - Call buyer
   - Discuss delivery
   - Clarify details

#### For Processing Orders:
```
Actions:
- Update status
  - Preparing vehicle
  - Ready for delivery
  - Out for delivery
  - Delivered

- Schedule delivery
- Upload delivery photos
- Get buyer signature (future)
- Mark as delivered
- Cancel order (with reason & refund)
```

#### For Delivered Orders:
```
Display:
- Delivery date & time
- Delivery confirmation
- Payment received status
- Credits earned
- Buyer rating (future)
- "View Invoice" button
- "Repeat Customer" tag (if applicable)
```

### Order Details Modal:
```
Complete information:
- Full buyer details
- Complete vehicle info
- Payment breakdown
- Order timeline
- Communication log
- Documents uploaded
- Signatures
- Delivery proof
```

### Revenue Tracking:
```
Per order display:
- Vehicle price
- Platform commission
- Taxes
- Net earnings
- Credits earned as seller
- Payment status
- Expected payout date
```

### Filters & Search:
1. Search by order ID, buyer name, vehicle
2. Date range
3. Payment method
4. Amount range
5. Sort: Recent, oldest, amount

---

## Screen 28: Seller Analytics Page
**File:** `lib/presentation/seller/seller_analytics_page.dart`

### Overview Section:
```
Key Metrics Cards:
1. Total Revenue
   - This month
   - All time
   - Growth percentage

2. Total Sales
   - Orders count
   - This month
   - Growth percentage

3. Active Listings
   - Available vehicles
   - Draft listings
   - Sold vehicles

4. Conversion Rate
   - Views to inquiries
   - Inquiries to test drives
   - Test drives to sales
```

### Charts & Graphs:

#### 1. Revenue Chart
```
- Line/Bar chart
- Time periods: Week, Month, Year, All Time
- Filters: By vehicle type, date range
- Y-axis: Revenue
- X-axis: Time
- Hover: Show exact values
- Download chart as image
```

#### 2. Sales Chart
```
- Bar chart
- Monthly sales count
- Last 12 months
- Color-coded by status
- Comparison with previous period
```

#### 3. Vehicle Performance
```
- Pie chart
- Sales by vehicle type
- Revenue by vehicle
- Most profitable vehicles
```

#### 4. Traffic Analysis
```
- Line chart
- Daily views
- Unique visitors
- Bounce rate
- Time on listing
```

### Performance Metrics:

#### Seller Rating (Future):
```
- Overall rating (out of 5)
- Number of ratings
- Rating breakdown (5★, 4★, 3★, etc.)
- Recent reviews
```

#### Response Time:
```
- test drive requests
- Order confirmations
- Buyer inquiries
- Benchmark: < 24 hours
```

#### Popular Listings:
```
Table showing:
- Vehicle name
- Views
- Wishlisted count
- Test drives
- Conversion rate
- Revenue generated
```

### Customer Insights:

#### Buyer Demographics:
```
- Location distribution (map)
- Age groups (if available)
- Preferred vehicle types
- Budget ranges
- Repeat customers
```

#### Peak Times:
```
- Best days for views
- Best time for test drives
- Seasonal trends
- Month-wise analysis
```

### Export Options:
1. Export as PDF
2. Export as Excel
3. Email report
4. Schedule automated reports

### Date Range Selector:
- Today
- Last 7 days
- Last 30 days
- Last 3 months
- Last 6 months
- Last year
- All time
- Custom range

---

## Screen 29: Seller Profile Page
**File:** `lib/presentation/seller/seller_profile_page.dart`

### Profile Header:
```
Display:
- Large profile picture (editable)
- Seller name
- Business name (if company)
- Verification badge
- Seller since date
- Total listings
- Total sales
- Rating (future)
- Credits balance
```

### Business Information:
```
Display/Edit:
- Account Type: Individual/Company
- Business Name
- GST Number
- Business Address
- Phone Number (primary)
- Alternate Phone
- Email
- Website (optional)
- Operating Hours
- Years in Business
```

### Documents & Verification:
```
Upload/View:
- Business License
- GST Certificate
- PAN Card
- Aadhar Card
- Shop Act License
- Address Proof
- Bank Account Details

Verification Status:
- Pending, Verified, Rejected
- Request verification
- View verification history
```

### Bank Details (for payouts):
```
Fields:
- Account Holder Name
- Bank Name
- Account Number
- IFSC Code
- Branch Name
- Account Type (Savings/Current)
- Cancel cheque/Passbook upload
```

### Performance Summary:
```
- Total vehicles listed
- Total vehicles sold
- Active listings
- Revenue this month
- All-time revenue
- Average sale time
- Response rate
- Customer satisfaction
```

### Settings:
1. Edit Profile
2. Change Password
3. Notification Preferences
4. Privacy Settings
5. Payout Settings

### Actions:
1. Request Verification
2. Upgrade Account (future: premium seller)
3. View Public Profile
4. Share Profile

---

## Screen 30: Seller Main Wrapper
**File:** `lib/presentation/seller/seller_main_wrapper.dart`

### Bottom Navigation Bar (5 Tabs):

1. **Dashboard** (Home Icon)
   - Seller dashboard screen

2. **Listings** (Car Icon)
   - Manage listings page

3. **Add Vehicle** (Plus Icon)
   - Add vehicle page
   - Larger, centered FAB style

4. **Orders** (Shopping Bag Icon)
   - Seller orders page
   - Badge: pending orders count

5. **Profile** (User Icon)
   - Seller profile page

### Additional Features:
- Notification icon (top-right, all screens)
- Consistent app bar across tabs
- Smooth tab transitions
- Maintain state across tabs

---

# 👮 POLICE MODULE - ALL FEATURES

## Screen 31: Police Dashboard
**File:** `lib/presentation/police/police_dashboard.dart`

### Header Section:
```
Display:
- Welcome message
- Officer name
- Badge number
- Police station/Zone
- Rank/Designation
- Duty status toggle
- Profile picture
```

### Quick Stats Cards:

1. **Challans Issued**
   - Today's count
   - This month count
   - Total count
   - "View All" button

2. **Revenue Collected**
   - Today's amount
   - This month
   - Total
   - "View Report" button

3. **Pending Payments**
   - Count of unpaid challans
   - Total pending amount
   - Overdue count
   - "View Details" button

4. **Vehicles Searched**
   - Today's searches
   - This month
   - Recent searches
   - "Search Vehicle" button

### Quick Actions (Large Buttons):

1. **Search Vehicle**
   - Icon: Search
   - Navigate to vehicle search page

2. **Issue E-Challan**
   - Icon: Document
   - Navigate to issue challan page

3. **View All Challans**
   - Icon: List
   - Navigate to challan list

4. **Analytics**
   - Icon: Chart
   - Navigate to police analytics

### Recent Activity:
```
Timeline showing:
- Recent challans issued
- Recent vehicle searches
- Payments received
- Violations by type
- Last 10 activities
```

### Violation Statistics:
```
Pie chart or bar chart:
- Most common violations
- By violation type
- By location
- By time of day
```

### Today's Schedule:
```
- Duty hours
- Check posts assigned
- Special drives/campaigns
- Meetings/briefings
```

---

## Screen 32: Vehicle Search Page
**File:** `lib/presentation/police/police_search_vehicle.dart`

### Search Section:

#### Search Input:
```
Fields:
1. Registration Number
   - Text input
   - Format: XX-00-XX-0000
   - Auto-format as user types
   - "Search" button
   - "Scan" button (future: OCR)

2. Recent Searches
   - List of last 10 searches
   - Tap to search again
   - Clear option
```

### Search Results Display:

#### Vehicle Information:
```
Display:
- Vehicle image (if available)
- Registration number (large)
- Brand & Model
- Year of manufacture
- Color
- Fuel Type
- Owner status (Current/Previous)
```

#### Owner Details:
```
Display:
- Owner name
- Phone number
- Email
- Address
- Aadhar number (masked)
- Owner since date
- Previous owners count
```

#### Vehicle History:

1. **Challan History**
   ```
   List showing:
   - All challans on this vehicle
   - Violation type
   - Fine amount
   - Issue date
   - Payment status
   - Issued by (station/officer)
   - Total unpaid amount (highlighted)
   ```

2. **Ownership History**
   ```
   - Previous owners list
   - Transfer dates
   - Duration of ownership
   - "View Transfer Documents"
   ```

3. **Insurance Status**
   ```
   - Insurance company
   - Policy number
   - Valid from - till
   - Status: Active/Expired
   - "View Policy" (if available)
   ```

4. **PUC Status**
   ```
   - Last PUC date
   - Valid till
   - Status: Valid/Expired
   - PUC center details
   ```

5. **Fitness Certificate**
   ```
   - Last fitness test date
   - Valid till
   - Status: Valid/Expired
   - Testing center
   ```

6. **Vehicle Status**
   ```
   - Active/Stolen/Lost
   - Any pending dues
   - Court cases (if any)
   - Restrictions (if any)
   ```

### Actions:

1. **Issue E-Challan**
   - Pre-fill vehicle details
   - Navigate to issue challan page

2. **Call Owner**
   - Direct call to registered number

3. **View Full History**
   - Complete vehicle timeline

4. **Flag Vehicle**
   - Mark as suspicious
   - Add to watchlist
   - Add notes

5. **Export Report**
   - PDF of vehicle details
   - Share via email

### Alerts & Flags:
```
Visual indicators:
🔴 Stolen vehicle
🟡 Multiple unpaid challans
🟡 Expired insurance
🟡 Expired PUC
🔴 Court case pending
🟡 Multiple ownership transfers (fraud alert)
```

---

## Screen 33: Issue E-Challan Page
**File:** `lib/presentation/police/police_issue_challan.dart`

### Form Structure:

#### Step 1: Vehicle Details
```
Fields:
1. Registration Number
   - Manual input OR
   - Search from database OR
   - Scan (future)
   - Auto-fill other details if found

2. Vehicle Type (Dropdown)
   - Two Wheeler
   - Car/Jeep
   - Auto
   - Truck
   - Bus
   - Other

3. Owner Name
   - Auto-filled if vehicle found
   - Manual input allowed

4. Owner Phone
   - Auto-filled
   - Manual input

5. Owner Address
   - Auto-filled
   - Manual input
```

#### Step 2: Violation Details
```
Fields:
1. Violation Type (Dropdown)
   Common violations:
   - Over Speeding
   - Wrong Parking
   - No Helmet (Two Wheeler)
   - No Seat Belt
   - Triple Riding
   - Signal Jump
   - Wrong Side Driving
   - No Valid Insurance
   - No PUC
   - No Driving License
   - Drunk Driving
   - Using Phone While Driving
   - No Registration Certificate
   - Dangerous Driving
   - Overloading
   - Tinted Glass
   - Illegal Modification
   - No Number Plate
   - Other (specify)

2. Violation Description
   - Multiline text area
   - Detailed description
   - Max 500 characters

3. Fine Amount
   - Auto-calculated based on violation type
   - Manual override allowed
   - Validation: > 0
   - Maximum limit check

4. Location of Violation
   - Current location (auto-detected)
   - OR select on map
   - OR manual address input
   - Landmark (optional)

5. Date & Time
   - Auto-filled with current
   - Can edit if needed
   - Cannot be future date
```

#### Step 3: Evidence Upload
```
Features:
1. Take Photo
   - Camera integration
   - Multiple photos (up to 5)
   - Vehicle front
   - Violation evidence
   - License plate clear photo

2. Select from Gallery
   - Multiple selection
   - Image compression

3. Photo Preview
   - View before upload
   - Delete option
   - Reorder

4. Video Upload (future)
   - For serious violations
   - Max 30 seconds
```

#### Step 4: Officer Details
```
Auto-filled from logged-in officer:
- Officer Name
- Badge Number
- Police Station
- Zone/Division
- Rank
- Contact Number

Editable (if another officer):
- Co-officer details
- Senior officer authorization
```

#### Step 5: Additional Information
```
Fields:
1. Witness Details (optional)
   - Name
   - Phone
   - Statement

2. Arrest Made (Yes/No toggle)
   - If yes: Arrest details
   - Case number

3. Vehicle Seized (Yes/No toggle)
   - If yes: Seizure details
   - Release conditions

4. Special Notes
   - Any additional information
   - Officer remarks

5. Court Appearance Required (Yes/No)
   - If yes: Court date
   - Court location
```

### Review & Submit:

#### Preview Page:
```
Display all entered information:
- Vehicle details summary
- Violation details
- Fine amount (large)
- Photos preview
- Officer details
- Location on map

Edit buttons for each section
```

#### Actions:

1. **Issue E-Challan**
   - Generate unique challan number
   - Save to Firestore
   - Upload photos to Storage
   - Send SMS to owner (future)
   - Send email to owner (future)
   - Print option

2. **Save as Draft**
   - Save incomplete challan
   - Continue later

3. **Cancel**
   - Discard challan
   - Confirmation dialog

### Success Screen:
```
Display:
- Success animation
- Challan number (large)
- "E-Challan Issued Successfully!"
- QR code (for challan)
- Fine amount
- Payment due date
- Actions:
  - View Challan
  - Send to Owner
  - Print
  - Issue Another
  - Back to Dashboard
```

### Challan Document Structure:
```javascript
{
  challanNumber: "auto-generated",
  vehicleNumber: "MH-12-AB-1234",
  vehicleType: "Car/Jeep",
  ownerName: "John Doe",
  ownerPhone: "+91 9876543210",
  ownerAddress: "...",
  violationType: "Over Speeding",
  violationDescription: "...",
  fineAmount: 2000,
  location: {
    address: "...",
    coordinates: GeoPoint,
    landmark: "..."
  },
  dateTime: Timestamp,
  evidence: {
    photos: ["url1", "url2", ...],
    videos: [] // future
  },
  officerDetails: {
    name: "Officer Name",
    badgeNumber: "12345",
    policeStation: "...",
    rank: "...",
    phone: "..."
  },
  status: "unpaid", // unpaid, paid, disputed, cancelled
  paymentDetails: {
    paidOn: null,
    paymentMethod: null,
    transactionId: null
  },
  witness: {...}, // optional
  courtRequired: false,
  vehicleSeized: false,
  issuedAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## Screen 34: Challan List Page (Police)
**File:** `lib/presentation/police/police_challan_list_page.dart`

### Filter & Search Section:

#### Search:
```
- By challan number
- By vehicle number
- By owner name
- By officer name
```

#### Filters:
```
1. Status
   - All
   - Unpaid
   - Paid
   - Overdue
   - Disputed
   - Cancelled

2. Violation Type
   - Multi-select dropdown
   - All violation categories

3. Date Range
   - Date picker
   - Presets: Today, Last 7 days, Last month
   - Custom range

4. Amount Range
   - Slider
   - Input fields

5. Issued By
   - All officers
   - Current officer only
   - Select specific officer

6. Location/Zone
   - Dropdown of zones
   - Police station wise
```

#### Sort Options:
```
- Date: Newest first
- All Date: Oldest first
- Amount: High to Low
- Amount: Low to High
- Status
- Violation Type
```

### Challan Cards Display:

#### Card Design:
```
Display:
- Challan number (large)
- Vehicle number (prominent)
- Status badge (color-coded)
- Violation type
- Fine amount (large, colored)
- Issue date & time
- Issued by (officer name)
- Payment status icon
- Photo thumbnail (if available)

Tap to expand:
- Owner details
- Complete violation description
- Location
- Photos (full size)
- Officer details
- Payment details (if paid)
```

### List Actions:

#### Individual Challan Actions:
```
- View Full Details
- Edit (if unpaid)
- Cancel (with reason)
- Mark as Paid (manual)
- Resend to Owner
- Print/Download PDF
- Share
```

#### Bulk Actions:
```
- Select multiple challans
- Export selected
- Generate report
- Send reminders
- Mark as paid (batch)
```

### Summary Statistics (Top of page):
```
Quick Stats Cards:
- Total showing (from filter)
- Total fine amount
- Paid amount
- Pending amount
- Collection rate %
```

### Export & Reports:
```
Options:
- Export as Excel
- Export as PDF
- Print list
- Email report
- Generate monthly report
- Generate officer-wise report
```

---

## Screen 35: Police Analytics Page
**File:** `lib/presentation/police/police_analytics_page.dart`

### Overview Cards:

```
Key Metrics:
1. Total Challans Issued
   - Today
   - This month
   - All time
   - Growth %

2. Total Revenue Generated
   - Today
   - This month
   - All time
   - Growth %

3. Collection Rate
   - Paid vs Issued ratio
   - Current month %
   - Trend graph

4. Average Fine Amount
   - Per challan
   - By violation type
   - Comparison
```

### Charts & Visualizations:

#### 1. Challans Issued Timeline
```
- Line chart
- Daily/Weekly/Monthly view
- Last 30 days default
- Compare with previous period
```

#### 2. Violation Distribution
```
- Pie chart
- By violation type
- Top 10 violations
- Percentage breakdown
```

#### 3. Revenue Collection
```
- Bar chart
- Monthly comparison
- Paid vs Pending
- Collection trends
```

#### 4. Geographic Distribution
```
- Heat map
- Violations by location
- Hotspot areas
- Zone-wise breakdown
```

#### 5. Time Analysis
```
- Bar chart
- Violations by hour of day
- Peak violation times
- Day of week analysis
```

#### 6. Officer Performance
```
- Table/Chart
- Challans by officer
- Collection rate per officer
- Response time
- Leaderboard
```

### Detailed Reports:

#### Violation Analysis:
```
Table showing:
- Violation type
- Count
- Total fine amount
- Paid amount
- Pending amount
- Repeat offenders
- Trend (up/down)
```

#### Payment Analysis:
```
- Payment timeline
- Payment methods used
- Delayed payments
- Defaulters list
- Recovery rate
```

#### Location Intelligence:
```
- Top violation zones
- Safe zones
- Accident-prone areas
- Suggested patrol points
```

### Filter Options:
```
1. Date Range
   - Custom picker
   - Presets

2. Police Station/Zone
   - Dropdown selection
   - Multi-select

3. Officer
   - All or specific
   - Team/division

4. Violation Type
   - Multi-select

5. Amount Range
   - Slider
```

### Export & Share:
```
- Download PDF report
- Export Excel
- Email report
- Schedule Auto-reports
- Print
```

---

## Screen 36: Police Main Wrapper
**File:** `lib/presentation/police/police_main_wrapper.dart`

### Bottom Navigation Bar (4 Tabs):

1. **Dashboard** (Home Icon)
   - Police dashboard

2. **Search** (Search Icon)
   - Vehicle search page

3. **Issue Challan** (Document Icon)
   - Direct to issue e-challan

4. **Profile** (User Icon)
   - Police profile

### Top App Bar (All screens):
- Police badge icon
- Current zone/station
- Duty status indicator
- Notification bell
- Menu (overflow)

---

# 🤖 AI ASSISTANT FEATURES

## Screen 37: AI Chat Page
**File:** `lib/presentation/ai/ai_chat_page.dart`

### Chat Interface:

#### Header:
```
- Title: "Carvia AI Assistant"
- Subtitle: "Powered by Gemini AI"
- Clear chat button
- Help button (shows example queries)
```

#### Chat Display:

**Message Types:**

1. **User Messages**
   - Right-aligned
   - Blue background
   - User icon
   - Timestamp

2. **AI Responses**
   - Left-aligned
   - Gray background
   - AI robot icon
   - Timestamp
   - Copy text button
   - Share button

3. **System Messages**
   - Centered
   - Light background
   - Welcome message
   - Error messages
   - Loading indicators

#### Message Content Types:

1. **Text Responses**
   - Formatted text
   - Markdown support
   - Clickable links
   - Bold, italic support

2. **Vehicle Recommendations**
   - Rich cards with:
     - Vehicle image
     - Name, price
     - Key specs
     - "View Details" button
     - "Add to Compare" button

3. **Comparison Results**
   - Side-by-side summary
   - Pros/cons list
   - Recommendation
   - "View Full Comparison" button

4. **Lists**
   - Bullet points
   - Numbered lists
   - Structured information

### Input Section:

#### Text Input:
```
Features:
- Multiline text field
- Auto-growing (up to 5 lines)
- Character count
- Emoji support
- @ mention vehicles
```

#### Vehicle Mention Feature:
```
How it works:
1. User types @ symbol
2. Vehicle search popup appears
3. Search/select vehicle
4. Vehicle name inserted in message
5. AI gets context about specific vehicle
```

#### Input Actions:
```
1. Send Button
   - Active when text entered
   - Tap or Enter key
   - Send icon

2. Voice Input Button
   - Microphone icon
   - Opens voice assistant
   - Speech-to-text
```

### AI Capabilities:

#### Vehicle Search:
```
Example queries:
- "Show me SUVs under 15 lakhs"
- "Find manual transmission cars"
- "What cars have best mileage?"
- "Show petrol cars in Mumbai"
- "Cars with sunroof under 20 lakhs"

Response: List of matching vehicles
```

#### Vehicle Comparison:
```
Example queries:
- "Compare Honda City and Maruti Ciaz"
- "Which is better: @Honda City or @Maruti Ciaz?"
- "Compare fuel efficiency of these cars"

Response: Detailed comparison with recommendation
```

#### Vehicle Information:
```
Example queries:
- "Tell me about @Honda City"
- "What are the features of @BMW X5?"
- "Is @Maruti Swift a good car?"
- "Pros and cons of @Tata Nexon"

Response: Detailed information, specs, pros/cons
```

#### Price & Value:
```
Example queries:
- "Is @Honda City VX priced well?"
- "What's a good price for 2020 Hyundai Creta?"
- "Should I buy @Vehicle or wait?"
- "Best value cars under 10 lakhs"

Response: Price analysis, market insights, advice
```

#### General Questions:
```
Example queries:
- "What should I check before buying used car?"
- "How to book a test drive?"
- "What documents do I need?"
- "How does the credit system work?"
- "What is transfer of ownership?"

Response: Helpful information and guidance
```

#### Personalized Recommendations:
```
Example queries:
- "Best car for family of 5"
- "I need an automatic car under 12 lakhs"
- "Suggest a car for daily commute"
- "Best first car to buy"
- "Fuel efficient cars for long drives"

Response: Tailored suggestions based on requirements
```

### Smart Features:

#### Context Awareness:
```
- Remembers conversation history
- References previous messages
- Maintains context across questions
- Personalized based on user profile
```

#### Quick Suggestions:
```
Suggested prompts:
- "Show popular cars"
- "Compare my wishlist"
- "What's trending?"
- "Best deals this month"
- "Help me choose"
```

#### Typing Indicator:
```
- Shows when AI is thinking
- "AI is typing..." message
- Animated dots
```

### Error Handling:
```
When AI can't answer:
- Apologize politely
- Suggest rephrase
- Offer alternative help
- Contact support option
```

### Data Privacy:
```
- Clear chat option
- Chat history saved locally
- Option to disable chat history
- No sensitive data shared with AI
```

---

## Screen 38: Voice Assistant Bottom Sheet
**File:** `lib/presentation/ai/voice_assistant_bottom_sheet.dart`

### UI Layout:

#### Header:
```
- Title: "Voice Assistant"
- Subtitle: "Speak your request"
- Close button
```

#### Microphone Animation:
```
Visual feedback:
- Large microphone icon (center)
- Pulsing animation while listening
- Sound wave visualization
- Color changes:
  - Gray: Inactive
  - Blue: Listening
  - Green: Processing
  - Red: Error
```

#### Status Text:
```
Messages:
- "Tap to speak"
- "Listening..."
- "Processing your request..."
- "Here's what I found..."
- "Sorry, I didn't catch that. Try again."
```

### Functionality:

#### Speech-to-Text:
```
Process:
1. User taps microphone icon
2. Request microphone permission
3. Start voice recognition
4. Display live transcription
5. User stops speaking (auto-detect silence)
6. Or tap to manually stop
7. Confirm transcription
8. Send to AI
9. Receive response
```

#### Text-to-Speech Response:
```
Process:
1. AI generates text response
2. TTS converts to speech
3. Play audio response
4. Show text simultaneously
5. Pause/Stop controls available
```

#### Voice Commands:
```
Direct actions:
- "Show me cars under 10 lakhs"
  → Execute filter and show results

- "Compare Honda City and Maruti Ciaz"
  → Navigate to comparison page

- "Book test drive for [vehicle]"
  → Open test drive booking

- "Add [vehicle] to wishlist"
  → Add to wishlist

- "Show my orders"
  → Navigate to orders page

- "Go to home"
  → Navigate to home page
```

#### Supported Languages:
```
Future enhancement:
- English
- Hindi
- Regional languages
```

### Controls:

#### Bottom Controls:
```
1. Language Selector
   - Dropdown
   - Change recognition language

2. Microphone Toggle
   - Start/Stop listening
   - Large tap target

3. Keyboard Toggle
   - Switch to text input
   - Opens AI chat page

4. Settings
   - TTS speed
   - Voice selection
   - Auto-speak responses
```

### Features:

#### Smart Wake Words (Future):
```
- "Hey Carvia"
- Always listening mode
- Privacy toggle
```

#### Conversation Mode:
```
- Continuous conversation
- No need to tap repeatedly
- Context maintained
- "That's all" to end
```

### Error Handling:
```
Scenarios:
1. No microphone permission
   → Show permission request dialog

2. Network error
   → Show offline message
   → Retry option

3. Speech not recognized
   → "Sorry, please repeat"
   → Show keyboard option

4. AI error
   → Fallback to text chat
   → Error message
```

---

# 🎯 ADDITIONAL FEATURES

## Screen 39: Vehicle List Page
**File:** `lib/presentation/home/vehicle_list_page.dart`

### Purpose:
Full-screen dedicated vehicle listing for specific categories

### Use Cases:
- "All Honda Cars"
- "SUVs in Mumbai"
- "Cars under 10 lakhs"
- "Recently Added"
- "Popular Vehicles"
- Search results

### Layout Options:

1. **Grid View**
   - 2 columns
   - Vehicle cards
   - Image-focused

2. **List View**
   - Single column
   - More details visible
   - Compact design

3. **Compact View**
   - Smaller cards
   - More vehicles per screen
   - Less details

### Sorting & Filters:
- Inherited from home page
- Quick filter chips at top
- Advanced filter bottom sheet
- Active filter count badge

### Infinite Scroll:
- Load more on scroll
- Pagination (20 per page)
- Loading indicator
- "No more vehicles" message

---

## My Vehicles Page (Buyer)
**File:** `lib/presentation/vehicle/my_vehicles_page.dart`

### Display User's Owned Vehicles:

#### Vehicle Cards:
```
Info shown:
- Vehicle image
- Name, year
- Registration number
- Purchase date
- Current kilometers
- Insurance status
- PUC status
- Service due (if tracked)
```

#### Actions:
1. Check E-Challans
2. Transfer Ownership
3. Update Insurance
4. Update PUC
5. Service Reminders
6. View Complete History
7. Sell on Platform

---

## Splash Screen
**File:** `lib/presentation/splash/`

### Elements:
- App logo (animated)
- App name (Carvia)
- Tagline (if any)
- Loading indicator
- Version number

### Duration: 2-3 seconds

### Navigation Logic:
```
Check Firebase Auth:
If user logged in:
  → Check user role
  → Navigate to role-specific dashboard
If not logged in:
  → Navigate to Login/OnBoarding
```

---

## Landing/Onboarding Page
**File:** `lib/presentation/landing/`

### Purpose:
First-time user introduction

### Slides (3-4):

#### Slide 1:
```
- Title: "Welcome to Carvia"
- Subtitle: "Your Smart Vehicle Marketplace"
- Image: App logo with car illustration
```

#### Slide 2:
```
- Title: "Browse & Compare"
- Subtitle: "Thousands of vehicles at your fingertips"
- Image: Vehicle listing illustration
```

#### Slide 3:
```
- Title: "AI-Powered Search"
- Subtitle: "Find your perfect vehicle with AI assistance"
- Image: AI chat illustration
```

#### Slide 4:
```
- Title: "Seamless Buying"
- Subtitle: "Test drive to ownership, all in one app"
- Image: Transaction illustration
```

### Actions:
- Skip button
- Next button
- "Get Started" on last slide

---

# 🎬 COMPLETE DEMO SCRIPT FOR PRESENTATION

## DEMO SCENARIO 1: BUYER JOURNEY (10 minutes)

### Part 1: Browse & Search (2 min)
```
Script:
"Let me show you the buyer experience. When a user opens Carvia..."

Actions:
1. Open app → Show splash screen
2. Auto-login → Show home dashboard
3. Point out:
   - "Here's the vehicle listing with real-time data from Firestore"
   - "User can see their current location"
   - "Search bar for quick search"
   - "Multiple filter options"

4. Apply filters:
   - Select "Honda" from brand
   - Select "Sedan" type
   - Set price range ₹8L - ₹12L
   - Show filtered results update instantly

5. Demonstrate search:
   - Type "City" in search
   - Show real-time results
```

### Part 2: Vehicle Details & Wishlist (2 min)
```
Script:
"Now let's explore a vehicle in detail..."

Actions:
1. Tap on Honda City card
2. Show vehicle detail page:
   - Swipe through images
   - Scroll to show complete specifications
   - Point out seller information
   - View count increment

3. Add to Wishlist:
   - Tap heart icon
   - Show instant update with Provider
   - Show snackbar confirmation

4. Add to Compare:
   - Tap compare icon
   - Show "1 vehicle selected" badge
```

### Part 3: AI Assistant (2 min)
```
Script:
"One of our unique features is the AI-powered assistant..."

Actions:
1. Tap AI chat FAB
2. Ask question: "Which car has better mileage, Honda City or Maruti Ciaz?"
3. Show AI thinking...
4. Display AI response with detailed comparison
5. Show vehicle mention feature:
   - Type "@Honda"
   - Show dropdown
   - Select vehicle
   - Ask specific question

6. Demonstrate voice assistant:
   - Tap microphone icon
   - Speak: "Show me SUVs under 15 lakhs"
   - Show speech recognition
   - Display results
```

### Part 4: Compare & Test Drive (2 min)
```
Script:
"Let's compare some vehicles and book a test drive..."

Actions:
1. Go back to home
2. Add another car to compare (Maruti Ciaz)
3. Navigate to compare page
4. Show:
   - Side-by-side comparison table
   - Highlighted better specs
   - Price comparison
   - Detailed specifications scroll

5. Book Test Drive:
   - From comparison, select Honda City
   - Tap "View Details" → "Book Test Drive"
   - Show pre-filled form
   - Select date (tomorrow)
   - Select time (2:00 PM)
   - Choose location
   - Submit
   - Show success dialog
```

### Part 5: Checkout (2 min)
```
Script:
"Finally, let's complete a purchase..."

Actions:
1. From vehicle detail, tap "Buy Now"
2. Show checkout page:
   - Order summary
   - Vehicle details
   - Price breakdown
   - Credits system (show balance)
   - Use 500 credits
   - Final amount updated
   - Payment method selection

3. Place Order:
   - Tap "Place Order"
   - Show processing
   - Display success confirmation
   - Navigate to orders page
   - Show order status
```

---

## DEMO SCENARIO 2: SELLER JOURNEY (7 minutes)

### Part 1: Seller Dashboard (1 min)
```
Script:
"Let me show you the seller dashboard... Sellers have a completely different interface"

Actions:
1. Logout from buyer account
2. Login as seller
3. Show seller dashboard:
   - Analytics cards
   - Revenue metrics
   - Active listings count
   - Recent orders
   - Charts and graphs
```

### Part 2: Add Vehicle (3 min)
```
Script:
"Sellers can easily list vehicles with complete details..."

Actions:
1. Tap "Add Vehicle" FAB
2. Fill Step 1 (Basic Info):
   - Brand: "Maruti"
   - Model: "Swift"
   - Year: 2022
   - Type: "Hatchback"
   - Reg: "MH-12-XX-1234"
   - Color: "Red"
   - Price: "₹7,50,000"

3. Fill Step 2 (Specs):
   - Fuel: "Petrol"
   - Transmission: "Manual"
   - Mileage: "22 km/l"
   - Engine: "1197 cc"
   - KM Driven: "15,000"
   - Owners: "1st"

4. Fill Step 3 (Features):
   - Check: AC, Power Steering, ABS, Airbags
   - Show extensivelist

5. Skip Step 4 (Dimensions) - optional

6. Step 5 (Photos):
   - Tap "Add Photos"
   - Select 3-4 images from gallery
   - Show upload progress
   - Drag to reorder

7. Step 6 (Location):
   - Auto-filled from profile
   - Show on map

8. Step 7 (Description):
   - "Well-maintained Swift, single owner, full service history"
   - Test drive: Yes
   - Negotiable: Yes

9. Tap "Publish Listing"
10. Show success message
11. Navigate to manage listings
12. Show new vehicle in list
```

### Part 3: Manage Test Drives (2 min)
```
Script:
"When buyers request test drives, sellers can manage them here..."

Actions:
1. Navigate to Test Drives tab
2. Show pending requests list
3. Select one request:
   - View buyer details
   - See requested time
   - View notes

4. Accept request:
   - Tap "Accept"
   - Confirm meeting location
   - Submit
   - Show moved to "Confirmed" tab
   - Indicate notification sent to buyer
```

### Part 4: Orders Management (1 min)
```
Script:
"Sellers receive and process orders through this interface..."

Actions:
1. Navigate to Orders tab
2. Show orders list
3. Select a "Pending" order:
   - View complete details
   - Buyer information
   - Payment details
   - Delivery address

4. Accept Order:
   - Tap "Accept Order"
   - Set delivery date
   - Confirm
   - Show moved to "Processing"
   - Update status to "Ready for Delivery"
```

---

## DEMO SCENARIO 3: POLICE MODULE (5 minutes)

### Part 1: Police Dashboard (1 min)
```
Script:
"The police module enables law enforcement to search vehicles and issue e-challans..."

Actions:
1. Logout and login as police user
2. Show police dashboard:
   - Statistics cards
   - Today's challans
   - Revenue collection
   - Recent activity
```

### Part 2: Vehicle Search (2 min)
```
Script:
"Officers can quickly search any vehicle by registration number..."

Actions:
1. Navigate to Search Vehicle
2. Enter registration: "MH-12-XX-1234"
3. Tap Search
4. Show results:
   - Vehicle details
   - Owner information
   - Insurance status
   - PUC status
   - Challan history
   - "No pending challans" message

5. Point out:
   - Call owner button
   - Issue challan button
   - Complete history
```

### Part 3: Issue E-Challan (2 min)
```
Script:
"Issuing a digital challan is simple and paperless..."

Actions:
1. From search results, tap "Issue E-Challan"
   OR Navigate to Issue Challan from dashboard

2. Fill form:
   - Vehicle No: "DL-123-XX-5678"
   - Owner: "Rahul Sharma"
   - Phone: "9876543210"
   - Violation: "Over Speeding"
   - Description: "Speed: 85 km/h in 60 km/h zone"
   - Fine: ₹2,000 (auto-filled)
   - Location: Current (auto-detected)

3. Add Photo:
   - Take photo with camera OR select from gallery
   - Show image preview

4. Officer details: Auto-filled

5. Review:
   - Show preview page
   - All details summary
   - Fine amount prominent

6. Issue Challan:
   - Tap "Issue E-Challan"
   - Show success screen
   - Unique challan number generated
   - "SMS sent to owner"
   - Print/Share options

7. Navigate to Challan List:
   - Show newly issued challan
   - Status: "Unpaid"
```

---

## DEMO SCENARIO 4: Special Features (3 minutes)

### Part 1: Dark Mode & Theme (30 sec)
```
Actions:
1. Go to Settings
2. Show dark mode (default)
3. Toggle to light mode
4. Show how entire app theme changes
5. Toggle back to dark mode
```

### Part 2: Location Services (30 sec)
```
Actions:
1. From home page, tap location
2. Open map picker
3. Drag pin to new location
4. Show address update
5. Confirm location
6. Show vehicles filtered by new location
```

### Part 3: Credits System (30 sec)
```
Actions:
1. Navigate to Profile
2. Tap " Credits & Rewards"
3. Show:
   - Current balance
   - How to earn credits list
   - Transaction history
   - Redeem guidelines
```

### Part 4: Real-time Sync (30 sec)
```
Actions:
1. Have a second device ready (if possible)
2. Add vehicle to wishlist on device 1
3. Show it appears on device 2 immediately
4. Demonstrate Firestore real-time listener

OR

1. Show vehicle status change
2. Seller marks as "Sold"
3. Buyer's screen updates instantly
4. Badge changes color
5. "Buy Now" button disabled
```

### Part 5: E-Challan (Buyer View) (30 sec)
```
Actions:
1. Login as buyer
2. Navigate to E-Challan page
3. Check challans for a vehicle
4. Show issued challan (from police demo)
5. View details
6. "Pay Now" option (UI only)
```

---

# 📝 PRESENTATION SPEAKING POINTS

## Introduction (1 min)
```
"Good morning/afternoon.

Today I present Carvia - a comprehensive vehicle marketplace platform that serves three distinct user roles: Buyers, Sellers, and Police officers.

Unlike traditional vehicle listing apps, Carvia is a complete ecosystem that handles everything from browsing and comparing vehicles to test drive booking, ownership transfer, and even traffic violation management.

Let me walk you through every feature and screen of this application."
```

## Technology Highlights (30 sec)
```
"Carvia is built with:
- Flutter for cross-platform mobile development
- Firebase for real-time cloud backend
- Google Gemini AI for intelligent assistance
- Clean Architecture for maintainability
- Provider for state management

This tech stack ensures scalability, performance, and a smooth user experience."
```

## Feature Count Summary (30 sec)
```
"The app includes:
- 38+ distinct screens
- 20+ buyer features
- 10+ seller features
- 8+ police features
- AI-powered search and chat
- Voice assistant
- Real-time notifications
- Credit reward system
- E-challan management
- And much more..."
```

## Key Differentiators (1 min)
```
"What makes Carvia unique:

1. Multi-Role Ecosystem: One app serves buyers, sellers, AND law enforcement

2. AI Integration: Google Gemini powers intelligent search, voice commands, and personalized recommendations

3. E-Challan System: Built-in traffic violation management - a first for vehicle marketplace apps

4. Real-time Everything: Thanks to Firestore, all data syncs instantly across devices

5. Complete Features: From browsing to ownership transfer, everything is integrated

6. User Rewards: Credit system incentivizes engagement

7. Professional Design: Modern UI with dark mode, smooth animations, and intuitive navigation"
```

## Conclusion (1 min)
```
"In summary, Carvia is not just a vehicle listing app - it's a comprehensive ecosystem that digitizes and streamlines the entire vehicle lifecycle.

Through this project, I've demonstrated proficiency in:
- Mobile app development with Flutter
- Cloud architecture with Firebase
- AI/ML integration
- Clean Code principles
- UI/UX design
- Problem-solving

The application is fully functional, well-architected, and ready for real-world deployment.

Thank you. I'm ready for questions."
```

---

# 📊 SCREEN COUNT SUMMARY

## Authentication: 5 screens
1. Splash Screen
2. Login Page
3. Register Page
4. Forgot Password
5. Complete Profile

## Buyer Module: 17 screens
6. Home Dashboard
7. Vehicle Detail Page
8. Compare Page
9. Book Test Drive
10. Test Drives Page (Buyer)
11. Checkout Page
12. Wishlist Page
13. My Orders
14. Insurance Page
15. E-Challan (Buyer)
16. Ownership Transfer
17. Profile Page
18. Settings Page
19. About & Credits
20. Notifications
21. Map Location Picker
22. Add External Vehicle

## Seller Module: 8 screens
23. Seller Dashboard
24. Add Vehicle Page
25. Manage Listings
26. Seller Test Drives
27. Seller Orders
28. Seller Analytics
29. Seller Profile
30. Seller Main Wrapper

## Police Module: 6 screens
31. Police Dashboard
32. Vehicle Search
33. Issue E-Challan
34. Challan List (Police)
35. Police Analytics
36. Police Main Wrapper

## AI Features: 2 screens
37. AI Chat Page
38. Voice Assistant

## Additional: 2 screens
39. Vehicle List Page
40. My Vehicles (Buyer)

**TOTAL: 40 Complete Screens**

---

# ✅ FINAL CHECKLIST FOR PRESENTATION

## Before Presentation:
- [ ] Read this entire document
- [ ] Test all features on your device
- [ ] Charge phone fully
- [ ] Clear app cache for smooth performance
- [ ] Have backup screenshots/screen recordings
- [ ] Test internet connectivity
- [ ] Prepare sample data (test vehicles, users, challans)
- [ ] Practice demo flow 2-3 times
- [ ] Time your demo (15-20 minutes)

## During Presentation:
- [ ] Start with splash screen
- [ ] Show authentication flow briefly
- [ ] Demonstrate buyer module thoroughly
- [ ] Showcase AI assistant (impressive feature)
- [ ] Show seller dashboard and Add vehicle
- [ ] Demo police module (unique feature)
- [ ] Highlight real-time sync
- [ ] Mention dark mode and theme
- [ ] Show clean, organized code architecture
- [ ] Explain Firebase integration
- [ ] Discuss scalability

## After Demo:
- [ ] Summarize key features
- [ ] Mention screen count (40+)
- [ ] Highlight unique features
- [ ] Discuss future enhancements
- [ ] Technical achievements
- [ ] Learning outcomes
- [ ] Thank audience
- [ ] Ready for Q&A

---

**YOU HAVE AN AMAZING PROJECT! SHOW IT WITH CONFIDENCE! 🚀**

*Good luck with your presentation tomorrow!*
