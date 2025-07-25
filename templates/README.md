# Shop Import Template

This directory contains the Excel import template for bulk importing repair shops into the application.

## Template File

- `shop_import_template.xlsx` - The main template file with all required columns
- `generate_template.py` - Python script to regenerate the template

## Column Structure

The template includes the following 43 columns in exact order:

### Basic Information
1. **name** - Shop name
2. **description** - Shop description
3. **address** - Full address
4. **area** - Area/neighborhood
5. **categories** - Comma-separated list of service categories
6. **latitude** - GPS latitude coordinate
7. **longitude** - GPS longitude coordinate
8. **rating** - Shop rating (0.0-5.0)
9. **amenities** - Comma-separated list of amenities
10. **durationMinutes** - Average service duration in minutes
11. **requiresPurchase** - Whether purchase is required (true/false)
12. **priceRange** - Price range indicator (₿, ₿₿, ₿₿₿)

### Location Details
13. **buildingNumber** - Building number
14. **buildingName** - Building name
15. **soi** - Soi (street lane)
16. **district** - District name
17. **province** - Province name
18. **landmark** - Nearby landmark
19. **lineId** - Line ID for contact
20. **facebookPage** - Facebook page URL
21. **otherContacts** - Additional contact information

### Payment Methods
22. **cash** - Accepts cash (true/false)
23. **QR** - Accepts QR payment (true/false)
24. **credit** - Accepts credit cards (true/false)
25. **paymentMethods** - Comma-separated payment methods (alternative to individual columns)

### Opening Hours
26. **mon** - Monday hours (e.g., "09:00-18:00" or "Closed")
27. **tue** - Tuesday hours
28. **wed** - Wednesday hours
29. **thu** - Thursday hours
30. **fri** - Friday hours
31. **sat** - Saturday hours
32. **sun** - Sunday hours

### Contact & Social Media
33. **instagramPage** - Instagram page URL
34. **phoneNumber** - Phone number
35. **buildingFloor** - Building floor number

### Status & Verification
36. **isapproved** - Approval status (true/false)
37. **verification_status** - Verification status
38. **image_url** - Shop image URL

### Additional Features
39. **tryOnAreaAvailable** - Try-on area available (true/false)
40. **notesOrConditions** - Additional notes or conditions
41. **usualOpeningTime** - Usual opening time

### External Links
42. **gMap link** - Google Maps link
43. **Note** - Additional notes

## Usage

1. Download the template file
2. Fill in the data for each shop
3. Use the "Import from Excel" feature in the admin settings
4. The system will validate and import the shops

## Data Format Guidelines

- **Boolean values**: Use "true" or "false" (case-insensitive)
- **Coordinates**: Use decimal format (e.g., "13.7563" for latitude)
- **Time formats**: Use "HH:MM-HH:MM" format or "Closed"
- **Lists**: Use comma-separated values (e.g., "Electronics, Computers")
- **URLs**: Include full URLs with protocol (e.g., "https://facebook.com/page")

## Validation

The import system will:
- Validate required columns are present
- Check coordinate validity
- Verify data formats
- Generate unique IDs for each shop
- Set verification status based on data quality 