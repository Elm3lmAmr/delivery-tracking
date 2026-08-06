import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { useEffect, useRef } from 'react';

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

const truckIconOffline = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/2766/2766156.png',
  iconSize: [32, 32],
  iconAnchor: [16, 32],
  popupAnchor: [0, -32],
  className: 'offline-truck-icon'
});

// A component to automatically fit bounds if needed or pan to a selected delivery
function MapBounds({ deliveries, selectedDeliveryId }) {
  const map = useMap();
  useEffect(() => {
    if (selectedDeliveryId) {
      const selected = deliveries.find(d => d.id === selectedDeliveryId);
      if (selected && selected.lat && selected.lng) {
        map.flyTo([selected.lat, selected.lng], 16, { duration: 1.5 });
      }
    } else if (deliveries.length > 0) {
      const bounds = L.latLngBounds(deliveries.map(d => [d.lat, d.lng]));
      map.fitBounds(bounds, { padding: [50, 50], maxZoom: 16 });
    }
  }, [deliveries, map, selectedDeliveryId]);
  return null;
}

export default function LiveMap({ deliveries, selectedDeliveryId }) {
  // Default center if no deliveries (Eastown, New Cairo)
  const defaultCenter = [30.0089, 31.4959];
  const markerRefs = useRef({});
  
  const activeMarkers = deliveries.filter(d => d.lat && d.lng);

  useEffect(() => {
    if (selectedDeliveryId && markerRefs.current[selectedDeliveryId]) {
      markerRefs.current[selectedDeliveryId].openPopup();
    }
  }, [selectedDeliveryId]);

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
          <Marker 
            key={d.id} 
            position={[d.lat, d.lng]} 
            icon={d.is_offline ? truckIconOffline : truckIcon}
            ref={(ref) => {
              if (ref) markerRefs.current[d.id] = ref;
            }}
          >
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

        <MapBounds deliveries={activeMarkers} selectedDeliveryId={selectedDeliveryId} />
      </MapContainer>
    </div>
  );
}
