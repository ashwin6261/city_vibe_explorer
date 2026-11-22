/**
 * City Vibe Explorer - Front End Application Logic
 */

// Application State
const state = {
  activeCityKey: 'jaipur',
  userLocation: { lat: 26.9196, lng: 75.8115 }, // Defaults to Jaipur center
  activeMood: 'all',
  onlyVisualFood: false,
  onlyTopVisited: false,
  searchQuery: '',
  activeView: 'map', // 'map' or 'feed'
  savedPlaceIds: new Set(JSON.parse(localStorage.getItem('city_vibe_saved') || '[]')),
  selectedPlaceId: null,
  isSimulatingWalk: false,
  simInterval: null,
  simIndex: 0,
  activeRoutePolyline: null
};

// Simulation Paths for Virtual City Exploration
const SIM_PATHS = {
  jaipur: [
    { lat: 26.9196, lng: 75.8115, name: 'Near Lassiwala, MI Road' },
    { lat: 26.9189, lng: 75.8118, name: 'Passing Gulab Ji Chai Wale' },
    { lat: 26.9188, lng: 75.8234, name: 'Arriving at Bapu Bazaar Chaat Lane' },
    { lat: 26.9239, lng: 75.8267, name: 'Approaching Hawa Mahal & Tattoo Cafe' },
    { lat: 26.9248, lng: 75.8260, name: 'Spotting Pandit Kulfi Stalls' },
    { lat: 26.9115, lng: 75.8202, name: 'Relaxing at Masala Chowk Open-Air Food Court' }
  ],
  delhi: [
    { lat: 28.6558, lng: 77.2312, name: 'Paranthe Wali Gali, Chandni Chowk' },
    { lat: 28.6570, lng: 77.2301, name: 'Natraj Dahi Bhalla' },
    { lat: 28.6562, lng: 77.2410, name: 'Red Fort Lahori Gate' }
  ],
  mumbai: [
    { lat: 18.9220, lng: 72.8347, name: 'Gateway of India Waterfront' },
    { lat: 18.9216, lng: 72.8331, name: 'Bademiya Late Night Street Stalls' }
  ]
};

// Map & Layer references
let mapInstance = null;
let markersLayer = null;
let userMarker = null;

/**
 * Initialize Map and Application
 */
function initApp() {
  const city = CITIES[state.activeCityKey];
  state.userLocation = { ...city.center };

  // 1. Initialize Leaflet Map (100% Free OpenStreetMap + CartoDB High-Res Voyager)
  mapInstance = L.map('map', {
    zoomControl: false,
    maxZoom: 19
  }).setView([city.center.lat, city.center.lng], city.zoom);

  // Modern clean vector map tiles with high-res retina support & fallback (Zero API keys, 100% free forever)
  L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OpenStreetMap contributors & CartoDB',
    subdomains: 'abcd',
    maxZoom: 19
  }).addTo(mapInstance);

  markersLayer = L.layerGroup().addTo(mapInstance);

  updateUserMarker();
  bindEventListeners();
  updateFavoritesBadge();
  renderPlaces();
}

/**
 * Distance Calculation (Haversine Formula in km)
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((R * c).toFixed(1));
}

/**
 * Filter Places according to active city, mood, search, and flags
 */
function getFilteredPlaces() {
  return ALL_PLACES.filter(place => {
    // 1. Match City
    if (place.city !== state.activeCityKey) return false;

    // 2. Match Mood
    if (state.activeMood !== 'all' && !place.moods.includes(state.activeMood)) {
      return false;
    }

    // 3. Match Visual Food Toggle
    if (state.onlyVisualFood && !place.isFood) return false;

    // 4. Match Top Visited Toggle
    if (state.onlyTopVisited && !place.isTop) return false;

    // 5. Match Search Query
    if (state.searchQuery.trim().length > 0) {
      const q = state.searchQuery.toLowerCase();
      const matchName = place.name.toLowerCase().includes(q);
      const matchDesc = place.desc.toLowerCase().includes(q);
      const matchMustTry = place.mustTry.toLowerCase().includes(q);
      const matchCategory = place.category.toLowerCase().includes(q);
      if (!matchName && !matchDesc && !matchMustTry && !matchCategory) return false;
    }

    return true;
  }).map(place => {
    return {
      ...place,
      distance: calculateDistance(
        state.userLocation.lat,
        state.userLocation.lng,
        place.lat,
        place.lng
      )
    };
  }).sort((a, b) => a.distance - b.distance);
}

/**
 * Render Map Markers and Place Cards
 */
function renderPlaces() {
  const places = getFilteredPlaces();
  markersLayer.clearLayers();

  const carousel = document.getElementById('places-carousel');
  const feedGrid = document.getElementById('feed-grid');
  carousel.innerHTML = '';
  feedGrid.innerHTML = '';

  if (places.length === 0) {
    const emptyHtml = `
      <div style="padding: 30px; text-align: center; color: #64748b; width: 100%;">
        <i class="ph-bold ph-magnifying-glass" style="font-size: 36px; margin-bottom: 8px;"></i>
        <p style="font-weight: 700; font-size: 15px;">No places found for this vibe</p>
        <p style="font-size: 12px;">Try switching moods or clearing filters</p>
      </div>
    `;
    carousel.innerHTML = emptyHtml;
    feedGrid.innerHTML = emptyHtml;
    return;
  }

  places.forEach((place, index) => {
    // 1. Determine Marker Hue & Icon
    let pinClass = 'pin-general';
    let iconClass = 'ph-map-pin';
    if (place.isFood) {
      pinClass = 'pin-food';
      iconClass = 'ph-fork-knife';
    } else if (place.isTop) {
      pinClass = 'pin-top';
      iconClass = 'ph-sparkle';
    }

    // 2. Custom Leaflet Pin
    const customIcon = L.divIcon({
      className: 'custom-pin-container',
      html: `
        <div class="custom-pin ${pinClass}" id="marker-${place.id}">
          <i class="ph-fill ${iconClass}"></i>
        </div>
      `,
      iconSize: [42, 42],
      iconAnchor: [21, 21]
    });

    const marker = L.marker([place.lat, place.lng], { icon: customIcon }).addTo(markersLayer);
    marker.on('click', () => {
      selectPlace(place);
    });

    // 3. Build HTML Card
    const cardHtml = createPlaceCardHtml(place, index === 0);

    // Append to Carousel (Map View)
    const carouselCard = document.createElement('div');
    carouselCard.innerHTML = cardHtml;
    const cardEl = carouselCard.firstElementChild;
    cardEl.addEventListener('click', () => selectPlace(place));
    carousel.appendChild(cardEl);

    // Append to Grid (Feed View)
    const gridCard = document.createElement('div');
    gridCard.innerHTML = cardHtml;
    const gridEl = gridCard.firstElementChild;
    gridEl.addEventListener('click', () => selectPlace(place));
    feedGrid.appendChild(gridEl);
  });
}

/**
 * Generate Place Card HTML Template
 */
function createPlaceCardHtml(place, isFirst = false) {
  const isSaved = state.savedPlaceIds.has(place.id);
  const tagClass = place.isFood ? 'food' : 'top';
  const tagLabel = place.isFood ? 'Food Stall' : 'Top Visited';

  return `
    <div class="place-card ${isFirst ? 'selected' : ''}" id="card-${place.id}">
      <div class="card-hero">
        <img src="${place.img}" alt="${place.name}" loading="lazy" />
        <div class="badge-visual">
          <i class="ph-fill ph-camera"></i> ${place.visualScore}% Visual
        </div>
        <div class="card-tag ${tagClass}">${tagLabel}</div>
        <button class="bookmark-btn ${isSaved ? 'saved' : ''}" onclick="event.stopPropagation(); toggleBookmark('${place.id}')" title="Save to Trip">
          <i class="${isSaved ? 'ph-fill' : 'ph-bold'} ph-heart"></i>
        </button>
      </div>
      <div class="card-content">
        <div class="card-header-line">
          <div class="card-title" title="${place.name}">${place.name}</div>
          <div class="card-rating-badge">
            <i class="ph-fill ph-star"></i> ${place.rating}
          </div>
        </div>
        <div class="card-must-try" title="${place.mustTry}">
          <i class="ph-fill ph-flame"></i> ${place.mustTry}
        </div>
        <div class="card-meta-line">
          <span><i class="ph-bold ph-navigation-arrow"></i> ${place.distance} km away</span>
          <button class="card-go-btn" onclick="event.stopPropagation(); navigateToCoordinates(${place.lat}, ${place.lng})">
            Go Here <i class="ph-bold ph-arrow-right"></i>
          </button>
        </div>
      </div>
    </div>
  `;
}

/**
 * Select and Focus on a Place
 */
function selectPlace(place) {
  state.selectedPlaceId = place.id;

  // Fly map to place location
  mapInstance.flyTo([place.lat, place.lng], 16, { duration: 1.2 });

  // Highlight card in carousel
  document.querySelectorAll('.place-card').forEach(c => c.classList.remove('selected'));
  const targetCard = document.getElementById(`card-${place.id}`);
  if (targetCard) {
    targetCard.classList.add('selected');
    targetCard.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
  }

  // Draw active route polyline from user position to place
  drawRoutePolyline(place);

  // Open rich detail drawer
  openPlaceDetail(place);
}

/**
 * Draw Walking Route Polyline
 */
function drawRoutePolyline(place) {
  if (state.activeRoutePolyline) {
    mapInstance.removeLayer(state.activeRoutePolyline);
  }

  const latlngs = [
    [state.userLocation.lat, state.userLocation.lng],
    [place.lat, place.lng]
  ];

  state.activeRoutePolyline = L.polyline(latlngs, {
    color: '#2563eb',
    weight: 4,
    opacity: 0.8,
    dashArray: '8, 8',
    lineCap: 'round'
  }).addTo(mapInstance);
}

/**
 * Open Place Detail Sheet
 */
function openPlaceDetail(place) {
  document.getElementById('modal-img').src = place.img;
  document.getElementById('modal-title').textContent = place.name;
  document.getElementById('modal-category').textContent = `${place.category} • Visual Score: ${place.visualScore}/100`;
  document.getElementById('modal-rating').textContent = `${place.rating} (${place.reviewsCount.toLocaleString()} reviews)`;
  document.getElementById('modal-must-try').textContent = place.mustTry;
  document.getElementById('modal-photo-tip').textContent = place.photoTip || 'Golden hour light gives the best results.';
  document.getElementById('modal-desc').textContent = place.desc;
  document.getElementById('modal-address').textContent = place.address;
  document.getElementById('modal-hours').textContent = place.hours;
  document.getElementById('modal-crowd').textContent = `Crowd: ${place.crowdLevel}`;

  document.getElementById('modal-nav-button').onclick = () => {
    navigateToCoordinates(place.lat, place.lng);
  };

  document.getElementById('place-modal').classList.add('open');
}

/**
 * Google Maps Direct Turn-by-Turn Navigation Launcher
 */
function navigateToCoordinates(lat, lng) {
  const url = `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`;
  window.open(url, '_blank');
}

/**
 * Update User Position Marker on Map
 */
function updateUserMarker() {
  if (userMarker) {
    userMarker.setLatLng([state.userLocation.lat, state.userLocation.lng]);
  } else {
    const userIcon = L.divIcon({
      className: 'custom-user-icon-wrap',
      html: `
        <div class="custom-pin pin-user">
          <i class="ph-bold ph-person-simple-walk"></i>
        </div>
      `,
      iconSize: [42, 42],
      iconAnchor: [21, 21]
    });

    userMarker = L.marker([state.userLocation.lat, state.userLocation.lng], {
      icon: userIcon,
      zIndexOffset: 1000
    }).addTo(mapInstance);
    userMarker.bindTooltip("You are here (Exploring)", { permanent: false, direction: 'top' });
  }
}

/**
 * Toggle Save / Bookmark
 */
function toggleBookmark(placeId) {
  if (state.savedPlaceIds.has(placeId)) {
    state.savedPlaceIds.delete(placeId);
  } else {
    state.savedPlaceIds.add(placeId);
  }
  localStorage.setItem('city_vibe_saved', JSON.stringify(Array.from(state.savedPlaceIds)));
  updateFavoritesBadge();
  renderPlaces();
}

function updateFavoritesBadge() {
  const badge = document.getElementById('saved-count-badge');
  if (badge) {
    badge.textContent = state.savedPlaceIds.size;
  }
}

/**
 * Live Discovery Toast Alert
 */
function showDiscoveryToast(title, message) {
  const toast = document.getElementById('discovery-toast');
  document.getElementById('toast-title').textContent = title;
  document.getElementById('toast-msg').textContent = message;
  toast.classList.add('show');

  setTimeout(() => {
    toast.classList.remove('show');
  }, 4000);
}

/**
 * Bind All UI Event Listeners
 */
function bindEventListeners() {
  // City Select Dropdown
  const citySelect = document.getElementById('city-select');
  citySelect.addEventListener('change', (e) => {
    const cityKey = e.target.value;
    state.activeCityKey = cityKey;
    const city = CITIES[cityKey];
    state.userLocation = { ...city.center };
    updateUserMarker();
    mapInstance.flyTo([city.center.lat, city.center.lng], city.zoom, { duration: 1.5 });
    renderPlaces();
  });

  // Mood Filter Pills
  document.querySelectorAll('.mood-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.mood-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      state.activeMood = chip.dataset.mood;
      renderPlaces();
    });
  });

  // Quick Filter: Visual Food Stalls
  const foodToggle = document.getElementById('toggle-food');
  foodToggle.addEventListener('click', () => {
    state.onlyVisualFood = !state.onlyVisualFood;
    foodToggle.classList.toggle('active-food', state.onlyVisualFood);
    renderPlaces();
  });

  // Quick Filter: Top Visited Places
  const topToggle = document.getElementById('toggle-top');
  topToggle.addEventListener('click', () => {
    state.onlyTopVisited = !state.onlyTopVisited;
    topToggle.classList.toggle('active-top', state.onlyTopVisited);
    renderPlaces();
  });

  // Search Input
  const searchInput = document.getElementById('search-input');
  searchInput.addEventListener('input', (e) => {
    state.searchQuery = e.target.value;
    renderPlaces();
  });

  // View Mode Switcher (Map vs Feed)
  const viewToggleBtn = document.getElementById('btn-toggle-view');
  viewToggleBtn.addEventListener('click', () => {
    state.activeView = state.activeView === 'map' ? 'feed' : 'map';
    const isFeed = state.activeView === 'feed';
    document.getElementById('feed-view').classList.toggle('active', isFeed);
    viewToggleBtn.classList.toggle('active', isFeed);
    viewToggleBtn.innerHTML = isFeed
      ? '<i class="ph-bold ph-map-trifold"></i>'
      : '<i class="ph-bold ph-squares-four"></i>';
    viewToggleBtn.title = isFeed ? 'Switch to Map View' : 'Switch to Grid Feed';
  });

  // GPS Location Trigger
  const gpsBtn = document.getElementById('btn-gps');
  gpsBtn.addEventListener('click', () => {
    if ('geolocation' in navigator) {
      showDiscoveryToast('GPS Syncing', 'Acquiring real-time satellite location...');
      navigator.geolocation.getCurrentPosition(
        pos => {
          state.userLocation = {
            lat: pos.coords.latitude,
            lng: pos.coords.longitude
          };
          updateUserMarker();
          mapInstance.flyTo([state.userLocation.lat, state.userLocation.lng], 16);
          showDiscoveryToast('Location Updated', 'Distances recalculated from your position.');
          renderPlaces();
        },
        () => {
          alert('Location permission denied or unavailable. Centering on city center.');
        }
      );
    }
  });

  // Virtual Walking Simulation
  const walkBtn = document.getElementById('btn-simulate-walk');
  const walkStatusPill = document.getElementById('walk-status-pill');

  walkBtn.addEventListener('click', () => {
    state.isSimulatingWalk = !state.isSimulatingWalk;
    walkBtn.classList.toggle('active', state.isSimulatingWalk);

    if (state.isSimulatingWalk) {
      walkStatusPill.style.display = 'flex';
      const path = SIM_PATHS[state.activeCityKey] || SIM_PATHS.jaipur;

      state.simInterval = setInterval(() => {
        state.simIndex = (state.simIndex + 1) % path.length;
        const currentStop = path[state.simIndex];
        state.userLocation = { lat: currentStop.lat, lng: currentStop.lng };
        updateUserMarker();
        mapInstance.panTo([currentStop.lat, currentStop.lng], { animate: true, duration: 1.2 });
        showDiscoveryToast('Walking Tour', `Arriving near ${currentStop.name}`);
        renderPlaces();
      }, 3500);
    } else {
      walkStatusPill.style.display = 'none';
      clearInterval(state.simInterval);
    }
  });

  // Modal Close Handlers
  document.getElementById('modal-close-btn').addEventListener('click', () => {
    document.getElementById('place-modal').classList.remove('open');
  });

  document.getElementById('place-modal').addEventListener('click', (e) => {
    if (e.target.id === 'place-modal') {
      document.getElementById('place-modal').classList.remove('open');
    }
  });

  // Saved / Favorites Drawer Handlers
  const favoritesBtn = document.getElementById('btn-favorites');
  const drawer = document.getElementById('favorites-drawer');
  const drawerClose = document.getElementById('drawer-close-btn');

  favoritesBtn.addEventListener('click', () => {
    renderSavedDrawer();
    drawer.classList.add('open');
  });

  drawerClose.addEventListener('click', () => {
    drawer.classList.remove('open');
  });

  drawer.addEventListener('click', (e) => {
    if (e.target.id === 'favorites-drawer') {
      drawer.classList.remove('open');
    }
  });
}

/**
 * Render Saved Places in Favorites Drawer
 */
function renderSavedDrawer() {
  const container = document.getElementById('drawer-items-list');
  container.innerHTML = '';

  const savedPlaces = ALL_PLACES.filter(p => state.savedPlaceIds.has(p.id));

  if (savedPlaces.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; color: #94a3b8; padding: 40px 20px;">
        <i class="ph-bold ph-heart-break" style="font-size: 40px; margin-bottom: 10px;"></i>
        <p style="font-weight: 700; font-size: 16px;">No saved spots yet</p>
        <p style="font-size: 13px;">Tap the heart on any card to add it to your trip bucket list.</p>
      </div>
    `;
    return;
  }

  savedPlaces.forEach(place => {
    const item = document.createElement('div');
    item.className = 'place-card';
    item.style.marginBottom = '12px';
    item.innerHTML = createPlaceCardHtml(place);
    item.addEventListener('click', () => {
      document.getElementById('favorites-drawer').classList.remove('open');
      selectPlace(place);
    });
    container.appendChild(item);
  });
}

// Start app on DOM load
window.addEventListener('DOMContentLoaded', initApp);

