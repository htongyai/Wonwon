
// Open browser console and run these commands to test Google Maps API:

console.log('Testing Google Maps API...');

// Test 1: Check if Google Maps is loaded
if (typeof google !== 'undefined' && google.maps) {
  console.log('✅ Google Maps API is loaded');
  console.log('Maps API Version:', google.maps.version);
} else {
  console.log('❌ Google Maps API not loaded');
}

// Test 2: Try to create a simple map
try {
  const mapDiv = document.createElement('div');
  mapDiv.style.width = '100px';
  mapDiv.style.height = '100px';
  document.body.appendChild(mapDiv);
  
  const map = new google.maps.Map(mapDiv, {
    center: { lat: 13.7563, lng: 100.5018 }, // Bangkok coordinates
    zoom: 10
  });
  
  console.log('✅ Map creation successful');
  document.body.removeChild(mapDiv);
} catch (error) {
  console.log('❌ Map creation failed:', error.message);
}

// Test 3: Check available libraries
if (google.maps.places) {
  console.log('✅ Places library is available');
} else {
  console.log('⚠️ Places library not loaded (may need to be explicitly loaded)');
}

console.log('Google Maps API test completed');

