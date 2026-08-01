import React, { useEffect, useRef, useState } from 'react';
import ReactDOM from 'react-dom';
import L from 'leaflet';
import { 
  MapPin, 
  Layers, 
  Navigation, 
  Search, 
  Clock, 
  Compass, 
  Maximize2, 
  Minimize2,
  RotateCcw,
  CheckCircle2,
  AlertTriangle,
  Siren,
  Route,
  X
} from 'lucide-react';
import { useLanguage } from '../context/LanguageContext';

// Modal Portal Component for Full Screen Expanded Map
function ExpandedMapModal({ center, zoom, origin, destination, markers, selectable, onLocationSelect, activeLayer: initialLayer, onClose, t, title }) {
  const modalContainerRef = useRef(null);
  const mapRef = useRef(null);
  const tileRef = useRef(null);
  const markersGroupRef = useRef(null);
  const routePolylineRef = useRef(null);

  const [activeLayer, setActiveLayer] = useState(initialLayer || 'roadmap');
  const [searchQuery, setSearchQuery] = useState('');
  const [searching, setSearching] = useState(false);
  const [routeInfo, setRouteInfo] = useState(null);
  const [turnDirections, setTurnDirections] = useState([]);
  const [showDirections, setShowDirections] = useState(true);

  // Tile layers
  const TILE_LAYERS = {
    roadmap: {
      name: 'Roadmap',
      url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      attribution: '&copy; CARTO &copy; OpenStreetMap'
    },
    satellite: {
      name: 'Satellite',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      attribution: '&copy; Esri, Maxar'
    },
    dark: {
      name: 'Dark Mode',
      url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      attribution: '&copy; CARTO &copy; OpenStreetMap'
    }
  };

  useEffect(() => {
    if (!modalContainerRef.current) return;

    const map = L.map(modalContainerRef.current, {
      center: origin ? [origin.lat, origin.lng] : center,
      zoom: zoom,
      zoomControl: false
    });

    L.control.zoom({ position: 'bottomright' }).addTo(map);

    const layer = L.tileLayer(TILE_LAYERS[activeLayer].url, {
      attribution: TILE_LAYERS[activeLayer].attribution,
      maxZoom: 19
    }).addTo(map);

    tileRef.current = layer;
    markersGroupRef.current = L.layerGroup().addTo(map);
    mapRef.current = map;

    map.on('click', async (e) => {
      if (selectable && onLocationSelect) {
        const { lat, lng } = e.latlng;
        try {
          const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18`);
          if (res.ok) {
            const data = await res.json();
            onLocationSelect({ lat, lng, address: data.display_name || `${lat.toFixed(5)}, ${lng.toFixed(5)}` });
            return;
          }
        } catch (err) {}
        onLocationSelect({ lat, lng, address: `Lat: ${lat.toFixed(4)}, Lng: ${lng.toFixed(4)}` });
      }
    });

    setTimeout(() => {
      map.invalidateSize();
    }, 150);

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (mapRef.current && tileRef.current) {
      mapRef.current.removeLayer(tileRef.current);
      const newLayer = L.tileLayer(TILE_LAYERS[activeLayer].url, {
        attribution: TILE_LAYERS[activeLayer].attribution,
        maxZoom: 19
      }).addTo(mapRef.current);
      tileRef.current = newLayer;
    }
  }, [activeLayer]);

  useEffect(() => {
    if (!mapRef.current || !markersGroupRef.current) return;
    markersGroupRef.current.clearLayers();
    if (routePolylineRef.current) {
      mapRef.current.removeLayer(routePolylineRef.current);
      routePolylineRef.current = null;
    }

    const bounds = L.latLngBounds();

    markers.forEach(m => {
      if (m.lat && m.lng) {
        const marker = L.marker([m.lat, m.lng], {
          icon: L.divIcon({
            html: `<div style="position: relative; display: flex; align-items: center; justify-content: center;">
              <div style="width: 36px; height: 36px; background: ${m.type === 'sos' ? '#ef4444' : '#14b8a6'}; border: 2.5px solid #fff; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #fff; font-weight: 800; font-size: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.5);">📍</div>
            </div>`,
            className: 'custom-pin',
            iconSize: [36, 36]
          })
        });
        marker.bindPopup(`<div style="padding:4px; font-weight:700;">${m.title}</div>`);
        markersGroupRef.current.addLayer(marker);
        bounds.extend([m.lat, m.lng]);
      }
    });

    if (origin && origin.lat && origin.lng) {
      bounds.extend([origin.lat, origin.lng]);
    }
    if (destination && destination.lat && destination.lng) {
      bounds.extend([destination.lat, destination.lng]);
    }

    if (bounds.isValid()) {
      mapRef.current.fitBounds(bounds, { padding: [60, 60], maxZoom: 16 });
    }
  }, [markers, origin, destination]);

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;
    setSearching(true);
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&limit=1`);
      if (res.ok) {
        const data = await res.json();
        if (data && data.length > 0) {
          const lat = parseFloat(data[0].lat);
          const lng = parseFloat(data[0].lon);
          if (mapRef.current) mapRef.current.flyTo([lat, lng], 16, { duration: 1.5 });
          if (selectable && onLocationSelect) {
            onLocationSelect({ lat, lng, address: data[0].display_name });
          }
        }
      }
    } catch (err) {} finally {
      setSearching(false);
    }
  };

  return (
    <div 
      onClick={onClose}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 9999999,
        background: 'rgba(15, 23, 42, 0.65)',
        backdropFilter: 'blur(8px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-end',
        padding: '24px'
      }}
    >
      <div 
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '56vw',
          maxWidth: '850px',
          minWidth: '380px',
          height: '82vh',
          background: 'rgba(15, 23, 42, 0.96)',
          border: '1px solid rgba(20, 184, 166, 0.4)',
          borderRadius: '24px',
          boxShadow: '0 25px 60px rgba(0,0,0,0.8), 0 0 30px rgba(20,184,166,0.2)',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
          position: 'relative'
        }}
      >
        {/* Header bar inside medium window */}
        <div style={{
          position: 'absolute',
          top: '14px',
          left: '14px',
          right: '14px',
          zIndex: 10000,
          display: 'flex',
          alignItems: 'center',
          justify: 'space-between',
          gap: '10px',
          pointerEvents: 'none'
        }}>
          <div style={{ pointerEvents: 'auto', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <button
              onClick={onClose}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                background: 'rgba(239, 68, 68, 0.95)',
                color: '#ffffff',
                border: 'none',
                padding: '8px 16px',
                borderRadius: '9999px',
                fontSize: '0.82rem',
                fontWeight: 800,
                cursor: 'pointer',
                boxShadow: '0 4px 16px rgba(0,0,0,0.5)',
                backdropFilter: 'blur(12px)'
              }}
              title={t('minimizeMap')}
            >
              <Minimize2 size={16} />
              <span>{t('minimizeMap')}</span>
            </button>

            {title && (
              <div style={{ background: 'rgba(15, 23, 42, 0.9)', padding: '6px 12px', borderRadius: '9999px', color: '#fff', fontSize: '0.78rem', fontWeight: 700 }}>
                📍 {title}
              </div>
            )}
          </div>

          <form onSubmit={handleSearch} style={{ pointerEvents: 'auto', flex: 1, maxWidth: '320px' }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              background: 'rgba(15, 23, 42, 0.92)',
              backdropFilter: 'blur(16px)',
              border: '1px solid rgba(255, 255, 255, 0.2)',
              borderRadius: '9999px',
              padding: '6px 12px',
              boxShadow: '0 4px 16px rgba(0,0,0,0.4)'
            }}>
              <Search size={14} color="#94a3b8" style={{ marginRight: '6px' }} />
              <input
                type="text"
                placeholder="Search location..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ background: 'transparent', border: 'none', outline: 'none', color: '#f8fafc', fontSize: '0.82rem', width: '100%' }}
              />
              <button type="submit" style={{ background: 'none', border: 'none', color: '#14b8a6', cursor: 'pointer', fontWeight: 800, fontSize: '0.78rem' }}>
                {searching ? '...' : 'Go'}
              </button>
            </div>
          </form>

          <div style={{ pointerEvents: 'auto', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div style={{ display: 'flex', gap: '2px', background: 'rgba(15, 23, 42, 0.9)', padding: '3px', borderRadius: '9999px', border: '1px solid rgba(255,255,255,0.15)' }}>
              {Object.keys(TILE_LAYERS).map(key => (
                <button
                  key={key}
                  onClick={() => setActiveLayer(key)}
                  style={{
                    background: activeLayer === key ? '#14b8a6' : 'transparent',
                    color: activeLayer === key ? '#ffffff' : '#94a3b8',
                    border: 'none',
                    padding: '5px 10px',
                    borderRadius: '9999px',
                    fontSize: '0.72rem',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  {key === 'roadmap' ? t('roadMap') : key === 'satellite' ? t('satellite') : t('darkMode')}
                </button>
              ))}
            </div>

            <button
              onClick={onClose}
              style={{ background: 'rgba(239, 68, 68, 0.9)', color: '#fff', border: 'none', width: '32px', height: '32px', borderRadius: '50%', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            >
              <X size={16} />
            </button>
          </div>
        </div>

        <div ref={modalContainerRef} style={{ width: '100%', height: '100%', background: '#020617' }} />
      </div>
    </div>
  );
}

// Tile Layer configurations (Google Maps-like styles)
const TILE_LAYERS = {
  roadmap: {
    name: 'Roadmap',
    url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    attribution: '&copy; <a href="https://carto.com/">CARTO</a> &copy; OpenStreetMap contributors'
  },
  satellite: {
    name: 'Satellite',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '&copy; Esri, Maxar, GeoEye, Earthstar Geographics'
  },
  dark: {
    name: 'Dark Mode',
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution: '&copy; CARTO &copy; OpenStreetMap contributors'
  }
};

// Create custom SVG markers
const createCustomIcon = (type = 'user', label = '') => {
  let color = '#3b82f6';
  let iconSvg = '';

  if (type === 'sos') {
    color = '#ef4444';
    iconSvg = `
      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 2v20M2 12h20"/>
      </svg>`;
  } else if (type === 'responder') {
    color = '#10b981';
    iconSvg = `
      <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5">
        <path d="M12 22s-8-4.5-8-11.8A8 8 0 0 1 12 2a8 8 0 0 1 8 8.2c0 7.3-8 11.8-8 11.8z"/>
        <circle cx="12" cy="10" r="3"/>
      </svg>`;
  } else {
    // User / Current Location
    color = '#3b82f6';
    iconSvg = `
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="white">
        <circle cx="12" cy="12" r="8"/>
      </svg>`;
  }

  const html = `
    <div style="position: relative; display: flex; align-items: center; justify-content: center;">
      ${type === 'sos' ? '<div style="position: absolute; width: 44px; height: 44px; background: rgba(239, 68, 68, 0.4); border-radius: 50%; animation: pulse-sos 1.5s infinite;"></div>' : ''}
      ${type === 'user' ? '<div style="position: absolute; width: 36px; height: 36px; background: rgba(59, 130, 246, 0.35); border-radius: 50%; animation: pulse-user 2s infinite;"></div>' : ''}
      <div style="
        width: ${type === 'sos' ? '36px' : '30px'};
        height: ${type === 'sos' ? '36px' : '30px'};
        background: ${color};
        border: 2.5px solid #ffffff;
        border-radius: 50%;
        box-shadow: 0 4px 12px rgba(0,0,0,0.4);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 2;
      ">
        ${iconSvg}
      </div>
      ${label ? `<div style="position: absolute; top: -24px; background: rgba(15,23,42,0.9); color: #fff; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 700; border: 1px solid rgba(255,255,255,0.2); white-space: nowrap; box-shadow: 0 2px 6px rgba(0,0,0,0.3);">${label}</div>` : ''}
    </div>
  `;

  return L.divIcon({
    html,
    className: 'custom-map-pin',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -20]
  });
};

export default function RealisticMap({
  center = [28.6139, 77.2090], // Default center
  zoom = 14,
  origin = null,
  destination = null,
  markers = [],
  selectable = false,
  onLocationSelect = null,
  height = '240px',
  showDirectionsPanel = true,
  isExpandable = true,
  title = null
}) {
  const { t } = useLanguage();
  const mapContainerRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const tileLayerRef = useRef(null);
  const markersGroupRef = useRef(null);
  const routePolylineRef = useRef(null);

  const [isExpanded, setIsExpanded] = useState(false);
  const [activeLayer, setActiveLayer] = useState('roadmap');
  const [searchQuery, setSearchQuery] = useState('');
  const [searching, setSearching] = useState(false);

  // Routing State
  const [routeInfo, setRouteInfo] = useState(null);
  const [turnDirections, setTurnDirections] = useState([]);
  const [showDirections, setShowDirections] = useState(showDirectionsPanel);

  // Initialize Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: origin ? [origin.lat, origin.lng] : center,
        zoom: zoom,
        zoomControl: false
      });

      L.control.zoom({ position: 'bottomright' }).addTo(map);

      // Default tile layer
      const layer = L.tileLayer(TILE_LAYERS[activeLayer].url, {
        attribution: TILE_LAYERS[activeLayer].attribution,
        maxZoom: 19
      }).addTo(map);

      tileLayerRef.current = layer;
      markersGroupRef.current = L.layerGroup().addTo(map);
      mapInstanceRef.current = map;

      // Handle map clicks in selectable mode
      map.on('click', async (e) => {
        if (selectable && onLocationSelect) {
          const { lat, lng } = e.latlng;
          // Reverse geocode clicked location
          try {
            const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18`);
            if (res.ok) {
              const data = await res.json();
              onLocationSelect({
                lat,
                lng,
                address: data.display_name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`
              });
              return;
            }
          } catch (err) {}
          onLocationSelect({ lat, lng, address: `Lat: ${lat.toFixed(4)}, Lng: ${lng.toFixed(4)}` });
        }
      });
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // Update Tile Layer when layer toggled
  useEffect(() => {
    if (mapInstanceRef.current && tileLayerRef.current) {
      mapInstanceRef.current.removeLayer(tileLayerRef.current);
      const newLayer = L.tileLayer(TILE_LAYERS[activeLayer].url, {
        attribution: TILE_LAYERS[activeLayer].attribution,
        maxZoom: 19
      }).addTo(mapInstanceRef.current);
      tileLayerRef.current = newLayer;
    }
  }, [activeLayer]);

  // Render Markers & Calculate Route
  useEffect(() => {
    if (!mapInstanceRef.current || !markersGroupRef.current) return;

    markersGroupRef.current.clearLayers();
    if (routePolylineRef.current) {
      mapInstanceRef.current.removeLayer(routePolylineRef.current);
      routePolylineRef.current = null;
    }

    const bounds = L.latLngBounds();

    // 1. Add Custom Markers array
    markers.forEach(m => {
      if (m.lat && m.lng) {
        const marker = L.marker([m.lat, m.lng], {
          icon: createCustomIcon(m.type || 'user', m.title)
        });

        const popupContent = `
          <div style="font-family: 'Plus Jakarta Sans', sans-serif; padding: 6px;">
            <div style="font-weight: 800; font-size: 14px; color: #0f172a; margin-bottom: 4px;">
              ${m.title || 'Location Pin'}
            </div>
            ${m.description ? `<div style="font-size: 12px; color: #475569; margin-bottom: 6px;">${m.description}</div>` : ''}
            ${m.status ? `<span style="background: #10b98120; color: #059669; font-weight: 700; font-size: 10px; padding: 2px 6px; border-radius: 4px;">STATUS: ${m.status}</span>` : ''}
          </div>
        `;
        marker.bindPopup(popupContent);
        markersGroupRef.current.addLayer(marker);
        bounds.extend([m.lat, m.lng]);
      }
    });

    // 2. Add Origin marker if provided
    let origLatLng = null;
    if (origin && origin.lat && origin.lng) {
      origLatLng = [origin.lat, origin.lng];
      const origMarker = L.marker(origLatLng, {
        icon: createCustomIcon('user', origin.title || 'Your Location')
      }).bindPopup(`<b>${origin.title || 'Start Location'}</b><br/>${origin.address || ''}`);
      markersGroupRef.current.addLayer(origMarker);
      bounds.extend(origLatLng);
    }

    // 3. Add Destination marker if provided
    let destLatLng = null;
    if (destination && destination.lat && destination.lng) {
      destLatLng = [destination.lat, destination.lng];
      const destMarker = L.marker(destLatLng, {
        icon: createCustomIcon('sos', destination.title || 'Destination SOS')
      }).bindPopup(`<b>${destination.title || 'Destination'}</b><br/>${destination.address || ''}`);
      markersGroupRef.current.addLayer(destMarker);
      bounds.extend(destLatLng);
    }

    // 4. Fetch turn-by-turn route if both Origin and Destination exist
    if (origLatLng && destLatLng) {
      fetchRouteAndDirections(origLatLng, destLatLng);
    } else if (bounds.isValid()) {
      mapInstanceRef.current.fitBounds(bounds, { padding: [50, 50], maxZoom: 16 });
    }
  }, [origin, destination, markers]);

  // Fetch real OSRM turn-by-turn driving route
  const fetchRouteAndDirections = async (start, end) => {
    try {
      // OSRM Public routing service (lng,lat format)
      const url = `https://router.project-osrm.org/route/v1/driving/${start[1]},${start[0]};${end[1]},${end[0]}?overview=full&geometries=geojson&steps=true`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        if (data.routes && data.routes.length > 0) {
          const route = data.routes[0];
          const distanceKm = (route.distance / 1000).toFixed(1);
          const durationMins = Math.ceil(route.duration / 60);

          setRouteInfo({
            distanceKm,
            distanceMiles: (route.distance / 1609.34).toFixed(1),
            durationMins,
            etaTime: new Date(Date.now() + route.duration * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
          });

          // Extract steps
          const steps = route.legs[0].steps.map((step, idx) => ({
            id: idx,
            instruction: step.maneuver.modifier 
              ? `${capitalize(step.maneuver.type)} ${step.maneuver.modifier} onto ${step.name || 'unnamed road'}`
              : `${capitalize(step.maneuver.type)} onto ${step.name || 'route path'}`,
            distance: (step.distance / 1000).toFixed(2)
          }));
          setTurnDirections(steps);

          // Draw realistic polyline (Google Blue style)
          const coordinates = route.geometry.coordinates.map(c => [c[1], c[0]]);
          
          if (routePolylineRef.current && mapInstanceRef.current) {
            mapInstanceRef.current.removeLayer(routePolylineRef.current);
          }

          const polyline = L.polyline(coordinates, {
            color: '#3b82f6',
            weight: 6,
            opacity: 0.85,
            lineCap: 'round',
            lineJoin: 'round'
          }).addTo(mapInstanceRef.current);

          routePolylineRef.current = polyline;

          // Fit bounds to show entire route
          mapInstanceRef.current.fitBounds(polyline.getBounds(), { padding: [60, 60] });
          return;
        }
      }
    } catch (err) {
      console.warn("OSRM routing API error, drawing direct straight-line fallback route:", err);
    }

    // Direct fallback straight-line polyline if offline/OSRM fails
    const straightDist = calculateDistance(start[0], start[1], end[0], end[1]);
    const fallbackMins = Math.ceil((straightDist / 30) * 60);

    setRouteInfo({
      distanceKm: straightDist.toFixed(1),
      distanceMiles: (straightDist * 0.621371).toFixed(1),
      durationMins: fallbackMins,
      etaTime: new Date(Date.now() + fallbackMins * 60000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    });

    setTurnDirections([
      { id: 1, instruction: `Head towards ${destination?.title || 'Incident Emergency Point'}`, distance: (straightDist * 0.4).toFixed(1) },
      { id: 2, instruction: `Turn into Facility Entry & Proceed to ${destination?.address || 'Target Location'}`, distance: (straightDist * 0.6).toFixed(1) }
    ]);

    if (mapInstanceRef.current) {
      const polyline = L.polyline([start, end], {
        color: '#ef4444',
        weight: 5,
        dashArray: '10, 10',
        opacity: 0.8
      }).addTo(mapInstanceRef.current);

      routePolylineRef.current = polyline;
      mapInstanceRef.current.fitBounds(polyline.getBounds(), { padding: [60, 60] });
    }
  };

  // Helper math for fallback distance
  const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  };

  const capitalize = s => s && s.charAt(0).toUpperCase() + s.slice(1);

  // Search Address on Map
  const handleMapSearch = async (e) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;
    setSearching(true);
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&limit=1`);
      if (res.ok) {
        const data = await res.json();
        if (data && data.length > 0) {
          const lat = parseFloat(data[0].lat);
          const lng = parseFloat(data[0].lon);

          if (mapInstanceRef.current) {
            mapInstanceRef.current.flyTo([lat, lng], 16, { duration: 1.5 });
          }

          if (selectable && onLocationSelect) {
            onLocationSelect({
              lat,
              lng,
              address: data[0].display_name
            });
          }
        } else {
          alert('Location not found. Try entering a city or landmark name.');
        }
      }
    } catch (err) {
      alert('Error searching location.');
    } finally {
      setSearching(false);
    }
  };
  // Handle Leaflet canvas resize when expanding / minimizing
  useEffect(() => {
    const timer = setTimeout(() => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.invalidateSize();
      }
    }, 200);
    return () => clearTimeout(timer);
  }, [isExpanded]);

  // Handle ESC key to exit expanded full screen map
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && isExpanded) {
        setIsExpanded(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isExpanded]);

  const toggleExpand = (e) => {
    if (e) e.stopPropagation();
    setIsExpanded(prev => !prev);
  };

  return (
    <>
      <div style={{
        position: 'relative',
        width: '100%',
        height: height,
        borderRadius: '16px',
        overflow: 'hidden',
        border: '1px solid rgba(255,255,255,0.12)',
        boxShadow: '0 8px 32px rgba(0,0,0,0.4)',
        transition: 'height 0.3s ease'
      }}>
        {/* 1. Floating Header & Controls Bar */}
        <div style={{
          position: 'absolute',
          top: '12px',
          left: '12px',
          right: '12px',
          zIndex: 1000,
          display: 'flex',
          alignItems: 'center',
          justify: 'space-between',
          gap: '12px',
          pointerEvents: 'none'
        }}>
          {/* Left Side: Expand Map Button Badge */}
          <div style={{ pointerEvents: 'auto', display: 'flex', alignItems: 'center', gap: '8px' }}>
            {isExpandable && (
              <button
                onClick={toggleExpand}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  background: 'linear-gradient(135deg, #14b8a6 0%, #0d9488 100%)',
                  color: '#ffffff',
                  border: 'none',
                  padding: '8px 16px',
                  borderRadius: '9999px',
                  fontSize: '0.82rem',
                  fontWeight: 800,
                  cursor: 'pointer',
                  boxShadow: '0 4px 16px rgba(0,0,0,0.5)',
                  backdropFilter: 'blur(12px)',
                  transition: 'all 0.2s ease'
                }}
                title={t('expandMap')}
              >
                <Maximize2 size={16} />
                <span>{t('expandMap')}</span>
              </button>
            )}

            {title && (
              <div style={{
                background: 'rgba(15, 23, 42, 0.88)',
                backdropFilter: 'blur(12px)',
                border: '1px solid rgba(255, 255, 255, 0.15)',
                padding: '6px 14px',
                borderRadius: '9999px',
                color: '#f8fafc',
                fontSize: '0.8rem',
                fontWeight: 700
              }}>
                📍 {title}
              </div>
            )}
          </div>

          {/* Right Side: Map View Mode Switcher (Roadmap / Satellite / Dark) */}
          <div style={{ pointerEvents: 'auto', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{
              display: 'flex',
              gap: '4px',
              background: 'rgba(15, 23, 42, 0.88)',
              backdropFilter: 'blur(12px)',
              padding: '4px',
              borderRadius: '9999px',
              border: '1px solid rgba(255, 255, 255, 0.15)',
              boxShadow: '0 4px 20px rgba(0,0,0,0.4)'
            }}>
              {Object.keys(TILE_LAYERS).map(key => (
                <button
                  key={key}
                  onClick={() => setActiveLayer(key)}
                  style={{
                    background: activeLayer === key ? '#14b8a6' : 'transparent',
                    color: activeLayer === key ? '#ffffff' : '#94a3b8',
                    border: 'none',
                    padding: '5px 10px',
                    borderRadius: '9999px',
                    fontSize: '0.72rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                >
                  {key === 'roadmap' ? t('roadMap') : key === 'satellite' ? t('satellite') : t('darkMode')}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* 2. Map Container DOM */}
        <div ref={mapContainerRef} style={{ width: '100%', height: '100%', background: '#0f172a' }} />
        {/* 3. Floating Route Summary Overlay */}
        {routeInfo && (
          <div style={{
            position: 'absolute',
            bottom: '16px',
            left: '16px',
            zIndex: 1000,
            background: 'rgba(15, 23, 42, 0.92)',
            backdropFilter: 'blur(16px)',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            borderRadius: '16px',
            padding: '16px 20px',
            minWidth: '280px',
            boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
            color: '#f8fafc'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Route size={20} color="#3b82f6" />
                <span style={{ fontWeight: 800, fontSize: '1rem', color: '#14b8a6' }}>
                  {routeInfo.durationMins} min
                </span>
                <span style={{ fontSize: '0.82rem', color: '#94a3b8' }}>
                  ({routeInfo.distanceKm} km / {routeInfo.distanceMiles} mi)
                </span>
              </div>
              <button
                onClick={() => setShowDirections(!showDirections)}
                style={{
                  background: 'rgba(255,255,255,0.1)',
                  border: 'none',
                  color: '#3b82f6',
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  padding: '4px 10px',
                  borderRadius: '9999px',
                  cursor: 'pointer'
                }}
              >
                {showDirections ? 'Hide Turns' : 'Turn-by-Turn'}
              </button>
            </div>

            <div style={{ fontSize: '0.8rem', color: '#cbd5e1', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Clock size={14} color="#f59e0b" />
              <span>Est. Arrival: <strong>{routeInfo.etaTime}</strong> • Fast emergency dispatch route</span>
            </div>

            {showDirections && turnDirections.length > 0 && (
              <div style={{
                marginTop: '12px',
                paddingTop: '12px',
                borderTop: '1px solid rgba(255,255,255,0.1)',
                maxHeight: '160px',
                overflowY: 'auto'
              }}>
                <div style={{ fontSize: '0.75rem', fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', marginBottom: '6px' }}>
                  Turn-by-Turn Navigation:
                </div>
                {turnDirections.map((step, idx) => (
                  <div key={idx} style={{ display: 'flex', alignItems: 'flex-start', gap: '8px', fontSize: '0.78rem', color: '#e2e8f0', marginBottom: '6px' }}>
                    <span style={{ background: '#3b82f620', color: '#3b82f6', fontWeight: 700, padding: '1px 6px', borderRadius: '4px', fontSize: '0.7rem' }}>
                      {idx + 1}
                    </span>
                    <span>{step.instruction} ({step.distance} km)</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* 4. Selectable Pin Notice */}
        {selectable && (
          <div style={{
            position: 'absolute',
            top: '64px',
            left: '50%',
            transform: 'translateX(-50%)',
            zIndex: 1000,
            background: 'rgba(20, 184, 166, 0.9)',
            color: '#ffffff',
            padding: '6px 16px',
            borderRadius: '9999px',
            fontSize: '0.8rem',
            fontWeight: 700,
            boxShadow: '0 4px 14px rgba(0,0,0,0.3)',
            display: 'flex',
            alignItems: 'center',
            gap: '6px'
          }}>
            <MapPin size={14} /> Click anywhere on map to select location
          </div>
        )}
      </div>

      {/* FULL SCREEN EXPANDED MAP PORTAL (ATTACHED DIRECTLY TO DOCUMENT.BODY TO ESCAPE ALL GLASS-CARD STACKING CONTEXTS) */}
      {isExpanded && ReactDOM.createPortal(
        <ExpandedMapModal
          center={center}
          zoom={zoom}
          origin={origin}
          destination={destination}
          markers={markers}
          selectable={selectable}
          onLocationSelect={onLocationSelect}
          activeLayer={activeLayer}
          onClose={() => setIsExpanded(false)}
          t={t}
          title={title}
        />,
        document.body
      )}
    </>
  );
}
