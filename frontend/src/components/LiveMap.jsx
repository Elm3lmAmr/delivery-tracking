import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { useEffect } from 'react';

// Fix for default marker icons in react-leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Create a custom icon for trucks/deliveries
const truckIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/2766/2766156.png',
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
});

// A component to automatically fit bounds if needed
function MapBounds({ deliveries }) {
  const map = useMap();
  useEffect(() => {
    if (deliveries.length > 0) {
      const bounds = L.latLngBounds(deliveries.map(d => [d.lat, d.lng]));
      map.fitBounds(bounds, { padding: [50, 50], maxZoom: 16 });
    }
  }, [deliveries, map]);
  return null;
}

export default function LiveMap({ deliveries }) {
  // Default center if no deliveries (Eastown, New Cairo)
  const defaultCenter = [30.0089, 31.4959];
  
  const activeMarkers = deliveries.filter(d => d.lat && d.lng);

  return (
    <div style={{ height: '100%', width: '100%', minHeight: '400px', background: '#e5e5e5' }}>
      <MapContainer 
        center={activeMarkers.length > 0 ? [activeMarkers[0].lat, activeMarkers[0].lng] : defaultCenter} 
        zoom={13} 
        style={{ height: '100%', width: '100%', zIndex: 1 }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
        />
        
        {activeMarkers.map((d) => (
          <Marker key={d.id} position={[d.lat, d.lng]} icon={truckIcon}>
            <Popup>
              <div style={{ padding: '4px' }}>
                <strong style={{ display: 'block', marginBottom: '4px' }}>{d.driver}</strong>
                <div style={{ fontSize: '12px', color: '#666' }}>
                  Project: {d.project}<br/>
                  Unit: {d.unit}<br/>
                  Plate: {d.plate_number}
                </div>
              </div>
            </Popup>
          </Marker>
        ))}

        <MapBounds deliveries={activeMarkers} />
      </MapContainer>
    </div>
  );
}
