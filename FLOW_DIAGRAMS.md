# 🔄 Wonwonw2 Flow Diagrams

## **Table of Contents**
1. [User Authentication Flow](#user-authentication-flow)
2. [Shop Discovery Flow](#shop-discovery-flow)
3. [Review Submission Flow](#review-submission-flow)
4. [Admin Moderation Flow](#admin-moderation-flow)
5. [Location Services Flow](#location-services-flow)
6. [Cache Management Flow](#cache-management-flow)
7. [Error Handling Flow](#error-handling-flow)
8. [Deployment Flow](#deployment-flow)

---

## **User Authentication Flow**

### **Complete Authentication Process**
```
┌─────────────────┐
│   App Starts    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ AuthManager     │
│ Initializes     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Firebase Auth   │
│ State Listener  │
│ Starts          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Check Current   │
│ User Exists?    │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│   Yes   │ │   No    │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Set     │ │ Set     │
│ Logged  │ │ Guest   │
│ In      │ │ State   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────────────┐
│ Start Token     │
│ Refresh Timer   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Load User Data  │
│ from Firestore  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Notify All      │
│ UI Components   │
└─────────────────┘
```

### **Login Process**
```
┌─────────────────┐
│ User Clicks     │
│ Login Button    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Validate Email  │
│ & Password      │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Invalid │ │ Valid   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Show    │ │ Check   │
│ Error   │ │ Rate    │
│ Message │ │ Limit   │
└─────────┘ └────┬────┘
                  │
            ┌─────┴─────┐
            │           │
            ▼           ▼
        ┌─────────┐ ┌─────────┐
        │ Rate    │ │ Within  │
        │ Limited │ │ Limit   │
        └────┬────┘ └────┬────┘
             │           │
             ▼           ▼
        ┌─────────┐ ┌─────────┐
        │ Show    │ │ Call    │
        │ Lockout │ │ Firebase│
        │ Message │ │ Auth    │
        └─────────┘ └────┬────┘
                         │
                   ┌─────┴─────┐
                   │           │
                   ▼           ▼
               ┌─────────┐ ┌─────────┐
               │ Success │ │ Failed  │
               └────┬────┘ └────┬────┘
                    │           │
                    ▼           ▼
               ┌─────────┐ ┌─────────┐
               │ Update  │ │ Record  │
               │ Auth    │ │ Failed  │
               │ State   │ │ Attempt │
               └─────────┘ └─────────┘
```

---

## **Shop Discovery Flow**

### **Complete Shop Loading Process**
```
┌─────────────────┐
│ User Opens      │
│ Home Screen     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Request         │
│ Location        │
│ Permission      │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Granted │ │ Denied  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Get GPS │ │ Show    │
│ Coords  │ │ All     │
│         │ │ Shops   │
└────┬────┘ └────┬────┘
     │           │
     ▼           │
┌─────────┐      │
│ Check   │      │
│ Memory  │      │
│ Cache   │      │
└────┬────┘      │
     │           │
┌─────┴─────┐    │
│           │    │
▼           ▼    │
┌─────────┐ ┌─────────┐ │
│ Cache   │ │ Cache   │ │
│ Hit     │ │ Miss    │ │
└────┬────┘ └────┬────┘ │
     │           │      │
     ▼           ▼      │
┌─────────┐ ┌─────────┐ │
│ Display │ │ Check   │ │
│ Cached  │ │ Persistent│
│ Shops   │ │ Cache   │ │
└─────────┘ └────┬────┘ │
                 │      │
           ┌─────┴─────┐│
           │           ││
           ▼           ▼│
       ┌─────────┐ ┌─────────┐│
       │ Cache   │ │ Cache   ││
       │ Hit     │ │ Miss    ││
       └────┬────┘ └────┬────┘│
            │           │    │
            ▼           ▼    │
       ┌─────────┐ ┌─────────┐│
       │ Load    │ │ Fetch   ││
       │ from    │ │ from    ││
       │ Cache   │ │ Firestore│
       └────┬────┘ └────┬────┘
            │           │
            ▼           ▼
       ┌─────────────────┐
       │ Update All      │
       │ Caches          │
       └─────────┬───────┘
                 │
                 ▼
       ┌─────────────────┐
       │ Sort by         │
       │ Distance        │
       └─────────┬───────┘
                 │
                 ▼
       ┌─────────────────┐
       │ Display Shops   │
       │ on Map & List   │
       └─────────────────┘
```

### **Search and Filter Process**
```
┌─────────────────┐
│ User Types      │
│ Search Query    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Debounce        │
│ Input (300ms)   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Filter Shops    │
│ by Query        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Apply Category  │
│ Filter          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Sort by         │
│ Distance/Rating │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Update UI       │
│ with Results    │
└─────────────────┘
```

---

## **Review Submission Flow**

### **Complete Review Process**
```
┌─────────────────┐
│ User Clicks     │
│ Write Review    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Show Review     │
│ Dialog          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ User Fills      │
│ Rating &        │
│ Comment         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Validate Input  │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Invalid │ │ Valid   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Show    │ │ Create  │
│ Error   │ │ Review  │
│ Message │ │ Object  │
└─────────┘ └────┬────┘
                 │
                 ▼
┌─────────────────┐
│ Save to         │
│ Firestore       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Update Shop's   │
│ Average Rating  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Notify UI of    │
│ Change          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Show Success    │
│ Message         │
└─────────────────┘
```

### **Review Reply Process**
```
┌─────────────────┐
│ User Clicks     │
│ Reply Button    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Show Reply      │
│ Input Field     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ User Types      │
│ Reply Text      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Validate Reply  │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Invalid │ │ Valid   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Show    │ │ Create  │
│ Error   │ │ Reply   │
│ Message │ │ Object  │
└─────────┘ └────┬────┘
                 │
                 ▼
┌─────────────────┐
│ Save Reply to   │
│ Firestore       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Update Review   │
│ UI              │
└─────────────────┘
```

---

## **Admin Moderation Flow**

### **Content Moderation Process**
```
┌─────────────────┐
│ Content Gets    │
│ Flagged/Reported│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Admin Sees      │
│ Flagged Content │
│ in Dashboard    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Admin Reviews   │
│ Content         │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Approve │ │ Moderate│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Content │ │ Choose  │
│ Stays   │ │ Action  │
│ Visible │ │ (Hide/  │
└─────────┘ │ Delete) │
            └────┬────┘
                 │
                 ▼
        ┌─────────────────┐
        │ Provide Reason  │
        │ for Action      │
        └─────────┬───────┘
                  │
                  ▼
        ┌─────────────────┐
        │ Update Content  │
        │ with Moderation │
        │ Status          │
        └─────────┬───────┘
                  │
                  ▼
        ┌─────────────────┐
        │ Log Moderation  │
        │ Action          │
        └─────────┬───────┘
                  │
                  ▼
        ┌─────────────────┐
        │ Notify User of  │
        │ Action          │
        └─────────────────┘
```

### **Shop Approval Process**
```
┌─────────────────┐
│ User Submits    │
│ New Shop        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Shop Goes to    │
│ Pending Queue   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Admin Reviews   │
│ Shop Details    │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Approve │ │ Reject  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Shop    │ │ Shop    │
│ Becomes │ │ Stays   │
│ Visible │ │ Hidden  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Notify  │ │ Notify  │
│ User of │ │ User of │
│ Approval│ │ Rejection│
└─────────┘ └─────────┘
```

---

## **Location Services Flow**

### **Location Permission and Retrieval**
```
┌─────────────────┐
│ App Requests    │
│ Location        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Check if        │
│ Location        │
│ Services        │
│ Enabled         │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Enabled │ │ Disabled│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Check   │ │ Show    │
│ Current │ │ Error   │
│ Permission│ │ Message│
└────┬────┘ └─────────┘
     │
┌─────┴─────┐
│           │
▼           ▼
┌─────────┐ ┌─────────┐
│ Granted │ │ Denied  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Get     │ │ Request │
│ Current │ │ Permission│
│ Location│ └────┬────┘
└────┬────┘      │
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Use     │ │ Check   │
│ Location│ │ Result  │
│ for     │ └────┬────┘
│ Sorting │      │
└─────────┘      │
                 │
           ┌─────┴─────┐
           │           │
           ▼           ▼
       ┌─────────┐ ┌─────────┐
       │ Granted │ │ Denied  │
       └────┬────┘ └────┬────┘
            │           │
            ▼           ▼
       ┌─────────┐ ┌─────────┐
       │ Get     │ │ Show    │
       │ Location│ │ Manual  │
       │ & Sort  │ │ Location│
       │ Shops   │ │ Input   │
       └─────────┘ └─────────┘
```

### **Location Timeout Handling**
```
┌─────────────────┐
│ Start Location  │
│ Request with    │
│ 10s Timeout     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Wait for        │
│ Location        │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Success │ │ Timeout │
│ (< 10s) │ │ (≥ 10s) │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Use     │ │ Log     │
│ Location│ │ Timeout │
│ for     │ │ Message │
│ Sorting │ └────┬────┘
└─────────┘      │
                 ▼
        ┌─────────────────┐
        │ Set Location    │
        │ Permission      │
        │ Denied Flag     │
        └─────────┬───────┘
                  │
                  ▼
        ┌─────────────────┐
        │ Show All Shops  │
        │ (Unsorted)      │
        └─────────────────┘
```

---

## **Cache Management Flow**

### **Multi-Layer Cache Strategy**
```
┌─────────────────┐
│ Request for     │
│ Shop Data       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Check Memory    │
│ Cache (L1)      │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Cache   │ │ Cache   │
│ Hit     │ │ Miss    │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Return  │ │ Check   │
│ Data    │ │ Persistent│
│ from    │ │ Cache   │
│ Memory  │ │ (L2)    │
└─────────┘ └────┬────┘
                 │
           ┌─────┴─────┐
           │           │
           ▼           ▼
       ┌─────────┐ ┌─────────┐
       │ Cache   │ │ Cache   │
       │ Hit     │ │ Miss    │
       └────┬────┘ └────┬────┘
            │           │
            ▼           ▼
       ┌─────────┐ ┌─────────┐
       │ Load    │ │ Fetch   │
       │ from    │ │ from    │
       │ Persistent│ │ Firestore│
       │ Cache   │ │ (L3)    │
       └────┬────┘ └────┬────┘
            │           │
            ▼           ▼
       ┌─────────┐ ┌─────────┐
       │ Update  │ │ Update  │
       │ Memory  │ │ All     │
       │ Cache   │ │ Caches  │
       └────┬────┘ └────┬────┘
            │           │
            ▼           ▼
       ┌─────────────────┐
       │ Return Data     │
       │ to UI           │
       └─────────────────┘
```

### **Cache Invalidation Process**
```
┌─────────────────┐
│ Shop Data       │
│ Updated         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Clear Memory    │
│ Cache (L1)      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Clear Persistent│
│ Cache (L2)      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Notify UI of    │
│ Cache           │
│ Invalidation    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ UI Refreshes    │
│ Data from       │
│ Firestore       │
└─────────────────┘
```

---

## **Error Handling Flow**

### **Comprehensive Error Handling**
```
┌─────────────────┐
│ Operation       │
│ Executes        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Try-Catch       │
│ Block Catches   │
│ Error           │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Classify Error  │
│ Type            │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Network │ │ Auth    │
│ Error   │ │ Error   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Timeout │ │ Invalid │
│ Error   │ │ Creds   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────────────┐
│ Convert to      │
│ User-Friendly   │
│ Message         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Show SnackBar   │
│ with Message    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Log Error for   │
│ Debugging       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Show Retry      │
│ Button (if      │
│ applicable)     │
└─────────────────┘
```

### **Error Recovery Process**
```
┌─────────────────┐
│ Error Occurs    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Check if        │
│ Retryable       │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Yes     │ │ No      │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Show    │ │ Show    │
│ Retry   │ │ Error   │
│ Button  │ │ Message │
└────┬────┘ └─────────┘
     │
     ▼
┌─────────────────┐
│ User Clicks     │
│ Retry           │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Execute         │
│ Operation       │
│ Again           │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Check Result    │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Success │ │ Failed  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Continue│ │ Show    │
│ Normal  │ │ Final   │
│ Flow    │ │ Error   │
└─────────┘ └─────────┘
```

---

## **Deployment Flow**

### **CI/CD Pipeline Process**
```
┌─────────────────┐
│ Developer       │
│ Pushes Code     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ GitHub Actions  │
│ Triggered       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Run Tests       │
│ (Unit +         │
│ Integration)    │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Tests   │ │ Tests   │
│ Pass    │ │ Fail    │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Run     │ │ Stop    │
│ Code    │ │ Pipeline│
│ Analysis│ └─────────┘
└────┬────┘
     │
┌─────┴─────┐
│           │
▼           ▼
┌─────────┐ ┌─────────┐
│ Analysis│ │ Analysis│
│ Pass    │ │ Fail    │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Build   │ │ Stop    │
│ App     │ │ Pipeline│
└────┬────┘ └─────────┘
     │
     ▼
┌─────────────────┐
│ Upload Build    │
│ Artifacts       │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Deploy to       │
│ Firebase        │
│ Hosting         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Update DNS      │
│ Records         │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ App is Live     │
│ and Accessible  │
└─────────────────┘
```

### **Multi-Environment Deployment**
```
┌─────────────────┐
│ Code Pushed to  │
│ Main Branch     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Build User App  │
│ (app.fixwonwon.com)│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Deploy User App │
│ to Firebase     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Build Admin     │
│ Portal          │
│ (admin.fixwonwon.com)│
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Deploy Admin    │
│ Portal to       │
│ Firebase        │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Both Apps       │
│ Live and        │
│ Accessible      │
└─────────────────┘
```

---

## **Key Flow Patterns**

### **1. Reactive UI Pattern**
```
State Change → Notify Listeners → UI Rebuilds → User Sees Update
```

### **2. Error Recovery Pattern**
```
Error → Classify → User Message → Retry Option → Success/Final Error
```

### **3. Cache-First Pattern**
```
Request → Memory Cache → Persistent Cache → Network → Update Caches
```

### **4. Permission Pattern**
```
Request → Check Status → Request if Needed → Handle Response → Proceed
```

### **5. Validation Pattern**
```
Input → Validate → Success Path / Error Path → User Feedback
```

---

**These flow diagrams provide a visual understanding of how different processes work in the Wonwonw2 app. They help developers understand the sequence of operations and make it easier to debug issues or add new features.**
