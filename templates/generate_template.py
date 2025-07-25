import pandas as pd
import os

def generate_shop_import_template():
    """Generate a shop import template with the exact column names required by the app."""
    
    # Define the exact column names as provided
    columns = [
        'name',
        'description', 
        'address',
        'area',
        'categories',
        'latitude',
        'longitude',
        'rating',
        'amenities',
        'durationMinutes',
        'requiresPurchase',
        'priceRange',
        'buildingNumber',
        'buildingName',
        'soi',
        'district',
        'province',
        'landmark',
        'lineId',
        'facebookPage',
        'otherContacts',
        'cash',
        'QR',
        'credit',
        'mon',
        'tue',
        'wed',
        'thu',
        'fri',
        'sat',
        'sun',
        'instagramPage',
        'phoneNumber',
        'buildingFloor',
        'isapproved',
        'verification_status',
        'image_url',
        'paymentMethods',
        'tryOnAreaAvailable',
        'notesOrConditions',
        'usualOpeningTime',
        'gMap link',
        'Note'
    ]
    
    # Create an empty DataFrame with the required columns
    df = pd.DataFrame(columns=columns)
    
    # Add a sample row with example data
    sample_data = {
        'name': 'Sample Repair Shop',
        'description': 'A sample repair shop for testing',
        'address': '123 Sample Street',
        'area': 'Sample Area',
        'categories': 'Electronics, Computers',
        'latitude': '13.7563',
        'longitude': '100.5018',
        'rating': '4.5',
        'amenities': 'WiFi, Parking, Air Conditioning',
        'durationMinutes': '60',
        'requiresPurchase': 'false',
        'priceRange': '₿₿',
        'buildingNumber': '123',
        'buildingName': 'Sample Building',
        'soi': 'Sample Soi',
        'district': 'Sample District',
        'province': 'Bangkok',
        'landmark': 'Sample Landmark',
        'lineId': 'sample_line_id',
        'facebookPage': 'https://facebook.com/sample',
        'otherContacts': 'Additional contact info',
        'cash': 'true',
        'QR': 'true',
        'credit': 'false',
        'mon': '09:00-18:00',
        'tue': '09:00-18:00',
        'wed': '09:00-18:00',
        'thu': '09:00-18:00',
        'fri': '09:00-18:00',
        'sat': '09:00-16:00',
        'sun': 'Closed',
        'instagramPage': 'https://instagram.com/sample',
        'phoneNumber': '02-123-4567',
        'buildingFloor': '2',
        'isapproved': 'true',
        'verification_status': 'Verified',
        'image_url': 'https://example.com/image.jpg',
        'paymentMethods': 'cash,qr',
        'tryOnAreaAvailable': 'true',
        'notesOrConditions': 'Sample notes and conditions',
        'usualOpeningTime': '09:00',
        'gMap link': 'https://maps.google.com/?q=13.7563,100.5018',
        'Note': 'Additional notes about the shop'
    }
    
    # Add the sample row
    df = pd.concat([df, pd.DataFrame([sample_data])], ignore_index=True)
    
    # Create the output directory if it doesn't exist
    output_dir = 'assets/templates'
    os.makedirs(output_dir, exist_ok=True)
    
    # Save the template
    output_file = os.path.join(output_dir, 'shop_import_template.xlsx')
    df.to_excel(output_file, index=False, sheet_name='Shops')
    
    print(f"Template generated successfully: {output_file}")
    print(f"Columns included: {len(columns)}")
    print("Column names:")
    for i, col in enumerate(columns, 1):
        print(f"{i:2d}. {col}")
    
    return output_file

if __name__ == "__main__":
    generate_shop_import_template() 