/// API Documentation for Wonwonw2 App
/// 
/// This file contains comprehensive documentation for all API endpoints,
/// services, and data models used in the application.

/// ## Authentication API
/// 
/// ### Login
/// - **Endpoint**: `POST /auth/login`
/// - **Description**: Authenticate user with email and password
/// - **Parameters**: 
///   - `email` (String): User's email address
///   - `password` (String): User's password
/// - **Returns**: User object with authentication token
/// 
/// ### Register
/// - **Endpoint**: `POST /auth/register`
/// - **Description**: Create new user account
/// - **Parameters**:
///   - `email` (String): User's email address
///   - `password` (String): User's password
///   - `name` (String): User's display name
/// - **Returns**: User object with authentication token
/// 
/// ### Logout
/// - **Endpoint**: `POST /auth/logout`
/// - **Description**: Sign out current user
/// - **Returns**: Success status

/// ## Shop Management API
/// 
/// ### Get All Shops
/// - **Endpoint**: `GET /shops`
/// - **Description**: Retrieve all approved repair shops
/// - **Query Parameters**:
///   - `approved` (Boolean): Filter by approval status (default: true)
///   - `category` (String): Filter by category
///   - `lat` (Number): User latitude for distance calculation
///   - `lng` (Number): User longitude for distance calculation
///   - `radius` (Number): Search radius in kilometers
/// - **Returns**: Array of RepairShop objects
/// 
/// ### Get Shop by ID
/// - **Endpoint**: `GET /shops/{id}`
/// - **Description**: Retrieve specific shop details
/// - **Parameters**:
///   - `id` (String): Shop unique identifier
/// - **Returns**: RepairShop object
/// 
/// ### Add New Shop
/// - **Endpoint**: `POST /shops`
/// - **Description**: Submit new repair shop for approval
/// - **Parameters**: RepairShop object
/// - **Returns**: Success status and shop ID
/// 
/// ### Update Shop
/// - **Endpoint**: `PUT /shops/{id}`
/// - **Description**: Update existing shop information
/// - **Parameters**:
///   - `id` (String): Shop unique identifier
///   - RepairShop object with updated fields
/// - **Returns**: Success status
/// 
/// ### Delete Shop
/// - **Endpoint**: `DELETE /shops/{id}`
/// - **Description**: Remove shop from database
/// - **Parameters**:
///   - `id` (String): Shop unique identifier
/// - **Returns**: Success status

/// ## Review System API
/// 
/// ### Get Shop Reviews
/// - **Endpoint**: `GET /shops/{id}/reviews`
/// - **Description**: Retrieve all reviews for a specific shop
/// - **Parameters**:
///   - `id` (String): Shop unique identifier
/// - **Returns**: Array of Review objects
/// 
/// ### Add Review
/// - **Endpoint**: `POST /shops/{id}/reviews`
/// - **Description**: Submit new review for a shop
/// - **Parameters**:
///   - `id` (String): Shop unique identifier
///   - `rating` (Number): Rating from 1-5
///   - `comment` (String): Review text
/// - **Returns**: Success status and review ID
/// 
/// ### Update Review
/// - **Endpoint**: `PUT /reviews/{id}`
/// - **Description**: Update existing review
/// - **Parameters**:
///   - `id` (String): Review unique identifier
///   - Updated review data
/// - **Returns**: Success status
/// 
/// ### Delete Review
/// - **Endpoint**: `DELETE /reviews/{id}`
/// - **Description**: Remove review
/// - **Parameters**:
///   - `id` (String): Review unique identifier
/// - **Returns**: Success status

/// ## Forum System API
/// 
/// ### Get Forum Topics
/// - **Endpoint**: `GET /forum/topics`
/// - **Description**: Retrieve all forum topics
/// - **Query Parameters**:
///   - `category` (String): Filter by category
///   - `page` (Number): Page number for pagination
///   - `limit` (Number): Number of topics per page
/// - **Returns**: Array of ForumTopic objects
/// 
/// ### Create Forum Topic
/// - **Endpoint**: `POST /forum/topics`
/// - **Description**: Create new forum topic
/// - **Parameters**:
///   - `title` (String): Topic title
///   - `content` (String): Topic content
///   - `category` (String): Topic category
/// - **Returns**: Success status and topic ID
/// 
/// ### Get Topic Replies
/// - **Endpoint**: `GET /forum/topics/{id}/replies`
/// - **Description**: Retrieve all replies for a topic
/// - **Parameters**:
///   - `id` (String): Topic unique identifier
/// - **Returns**: Array of ForumReply objects
/// 
/// ### Add Reply
/// - **Endpoint**: `POST /forum/topics/{id}/replies`
/// - **Description**: Add reply to forum topic
/// - **Parameters**:
///   - `id` (String): Topic unique identifier
///   - `content` (String): Reply content
///   - `parentReplyId` (String, optional): ID of parent reply for nested replies
/// - **Returns**: Success status and reply ID

/// ## Admin API
/// 
/// ### Get Admin Dashboard Data
/// - **Endpoint**: `GET /admin/dashboard`
/// - **Description**: Retrieve admin dashboard statistics
/// - **Returns**: Dashboard data object with counts and metrics
/// 
/// ### Approve Shop
/// - **Endpoint**: `POST /admin/shops/{id}/approve`
/// - **Description**: Approve pending shop submission
/// - **Parameters**:
///   - `id` (String): Shop unique identifier
/// - **Returns**: Success status
/// 
/// ### Reject Shop
/// - **Endpoint**: `POST /admin/shops/{id}/reject`
/// - **Description**: Reject shop submission
/// - **Parameters**:
///   - `id` (String): Shop unique identifier
///   - `reason` (String): Rejection reason
/// - **Returns**: Success status
/// 
/// ### Moderate Forum Content
/// - **Endpoint**: `POST /admin/moderate/{type}/{id}`
/// - **Description**: Moderate forum content (hide, delete, etc.)
/// - **Parameters**:
///   - `type` (String): Content type (topic, reply)
///   - `id` (String): Content unique identifier
///   - `action` (String): Moderation action
///   - `reason` (String): Reason for moderation
/// - **Returns**: Success status

/// ## Data Models
/// 
/// ### RepairShop
/// ```dart
/// {
///   "id": "string",
///   "name": "string",
///   "description": "string",
///   "address": "string",
///   "area": "string",
///   "categories": ["string"],
///   "rating": "number",
///   "reviewCount": "number",
///   "amenities": ["string"],
///   "hours": {"string": "string"},
///   "closingDays": ["string"],
///   "latitude": "number",
///   "longitude": "number",
///   "durationMinutes": "number",
///   "requiresPurchase": "boolean",
///   "photos": ["string"],
///   "priceRange": "string",
///   "features": {"string": "boolean"},
///   "approved": "boolean",
///   "irregularHours": "boolean",
///   "subServices": {"string": ["string"]},
///   "phoneNumber": "string",
///   "facebookPage": "string",
///   "buildingNumber": "string",
///   "buildingName": "string",
///   "buildingFloor": "string",
///   "soi": "string",
///   "district": "string",
///   "province": "string",
///   "landmark": "string",
///   "lineId": "string",
///   "instagramPage": "string",
///   "createdAt": "timestamp",
///   "updatedAt": "timestamp"
/// }
/// ```
/// 
/// ### Review
/// ```dart
/// {
///   "id": "string",
///   "shopId": "string",
///   "userId": "string",
///   "userName": "string",
///   "rating": "number",
///   "comment": "string",
///   "createdAt": "timestamp",
///   "updatedAt": "timestamp"
/// }
/// ```
/// 
/// ### ForumTopic
/// ```dart
/// {
///   "id": "string",
///   "title": "string",
///   "content": "string",
///   "authorId": "string",
///   "authorName": "string",
///   "category": "string",
///   "tags": ["string"],
///   "viewCount": "number",
///   "replyCount": "number",
///   "isPinned": "boolean",
///   "isLocked": "boolean",
///   "isHidden": "boolean",
///   "isDeleted": "boolean",
///   "moderationReason": "string",
///   "moderatedBy": "string",
///   "moderatedAt": "timestamp",
///   "createdAt": "timestamp",
///   "updatedAt": "timestamp"
/// }
/// ```
/// 
/// ### ForumReply
/// ```dart
/// {
///   "id": "string",
///   "topicId": "string",
///   "content": "string",
///   "authorId": "string",
///   "authorName": "string",
///   "parentReplyId": "string",
///   "isHidden": "boolean",
///   "isDeleted": "boolean",
///   "moderationReason": "string",
///   "moderatedBy": "string",
///   "moderatedAt": "timestamp",
///   "createdAt": "timestamp",
///   "updatedAt": "timestamp"
/// }
/// ```

/// ## Error Codes
/// 
/// | Code | Description |
/// |------|-------------|
/// | 400 | Bad Request - Invalid parameters |
/// | 401 | Unauthorized - Authentication required |
/// | 403 | Forbidden - Insufficient permissions |
/// | 404 | Not Found - Resource not found |
/// | 409 | Conflict - Resource already exists |
/// | 422 | Unprocessable Entity - Validation failed |
/// | 500 | Internal Server Error - Server error |
/// | 503 | Service Unavailable - Service temporarily unavailable |

/// ## Rate Limiting
/// 
/// - **General API**: 100 requests per minute per IP
/// - **Authentication**: 10 requests per minute per IP
/// - **File Upload**: 5 requests per minute per user
/// - **Admin Operations**: 50 requests per minute per admin

/// ## Caching
/// 
/// - **Shop Data**: Cached for 1 hour
/// - **User Data**: Cached for 30 minutes
/// - **Forum Data**: Cached for 15 minutes
/// - **Admin Data**: Cached for 5 minutes

/// ## Security
/// 
/// - All API endpoints require HTTPS
/// - Authentication tokens expire after 24 hours
/// - Sensitive operations require additional verification
/// - Rate limiting prevents abuse
/// - Input validation prevents injection attacks
