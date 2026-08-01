import { useState, useEffect, useCallback } from 'react';
import { useLanguage } from '../context/LanguageContext';

export function useGeolocation(options = {}) {
  let lang = 'en';
  try {
    const langCtx = useLanguage();
    lang = langCtx.lang;
  } catch (e) {
    // Fallback if used outside of LanguageProvider
  }

  const [location, setLocation] = useState({
    lat: null,
    lng: null,
    address: '',
    accuracy: null,
    heading: null,
    speed: null,
    loading: false,
    error: null,
    permission: 'prompt'
  });

  // Reverse geocode lat/lng to readable street address using OSM Nominatim
  const reverseGeocode = async (lat, lng, langCode = 'en') => {
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1&accept-language=${langCode}`);
      if (res.ok) {
        const data = await res.json();
        const display = data.display_name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
        // Extract concise address
        const addr = data.address || {};
        const road = addr.road || addr.pedestrian || addr.street || '';
        const house = addr.house_number ? `${addr.house_number} ` : '';
        const suburb = addr.suburb || addr.neighbourhood || addr.city_district || addr.city || '';
        const concise = road ? `${house}${road}, ${suburb}`.trim() : display.split(',').slice(0, 3).join(',');
        return concise || display;
      }
    } catch (e) {
      console.warn("Reverse geocode fetch failed, using coordinates fallback:", e);
    }
    return `Lat: ${lat.toFixed(4)}, Lng: ${lng.toFixed(4)}`;
  };

  // Direct Geocode: convert address query string to lat/lng
  const geocodeAddress = async (query) => {
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1`);
      if (res.ok) {
        const data = await res.json();
        if (data && data.length > 0) {
          return {
            lat: parseFloat(data[0].lat),
            lng: parseFloat(data[0].lon),
            displayName: data[0].display_name
          };
        }
      }
    } catch (e) {
      console.error("Geocoding failed:", e);
    }
    return null;
  };

  const requestLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setLocation(prev => ({
        ...prev,
        error: 'Geolocation is not supported by your browser',
        loading: false
      }));
      return;
    }

    setLocation(prev => ({ ...prev, loading: true, error: null }));

    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude, accuracy, heading, speed } = position.coords;
        const readableAddress = await reverseGeocode(latitude, longitude, lang);

        setLocation({
          lat: latitude,
          lng: longitude,
          address: readableAddress,
          accuracy: Math.round(accuracy),
          heading,
          speed,
          loading: false,
          error: null,
          permission: 'granted'
        });
      },
      (error) => {
        let errorMsg = 'Failed to retrieve location.';
        if (error.code === error.PERMISSION_DENIED) {
          errorMsg = 'Location permission denied by user.';
        } else if (error.code === error.POSITION_UNAVAILABLE) {
          errorMsg = 'Location information is unavailable.';
        } else if (error.code === error.TIMEOUT) {
          errorMsg = 'The request to get location timed out.';
        }
        
        setLocation(prev => ({
          ...prev,
          loading: false,
          error: errorMsg,
          permission: 'denied'
        }));
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
        ...options
      }
    );
  }, [options, lang]);

  // Update address when language changes
  const latVal = location.lat;
  const lngVal = location.lng;
  useEffect(() => {
    if (latVal !== null && lngVal !== null) {
      reverseGeocode(latVal, lngVal, lang).then(readableAddress => {
        setLocation(prev => ({
          ...prev,
          address: readableAddress
        }));
      });
    }
  }, [lang, latVal, lngVal]);

  useEffect(() => {
    // Initial silent probe if permission previously granted
    if (navigator.permissions && navigator.permissions.query) {
      navigator.permissions.query({ name: 'geolocation' }).then((status) => {
        setLocation(prev => ({ ...prev, permission: status.state }));
        if (status.state === 'granted') {
          requestLocation();
        }
      }).catch(() => {});
    }
  }, []);

  return {
    ...location,
    requestLocation,
    geocodeAddress,
    reverseGeocode
  };
}
