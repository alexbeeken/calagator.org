module MappingHelper
  def map_provider
    (SECRETS.mapping && SECRETS.mapping["provider"]) || 'stamen'
  end

  def leaflet_js
    if Rails.env.production?
      ["https://d591zijq8zntj.cloudfront.net/leaflet-0.6.4/leaflet.js"]
    else
      ["leaflet"]
    end
  end

  def map_provider_dependencies
    case map_provider
      when "stamen"
        ["http://maps.stamen.com/js/tile.stamen.js?v1.2.3"]
      when "mapbox"
        ["https://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.standalone.js"]
      when "esri"
        ["http://cdn-geoweb.s3.amazonaws.com/esri-leaflet/0.0.1-beta.5/esri-leaflet.js"]
      when "google"
        [
          "https://maps.googleapis.com/maps/api/js?key=#{SECRETS.mapping["google_maps_api_key"]}&sensor=false",
          "leaflet_google_layer",
        ]
    end
  end

  def mapping_js_includes
    leaflet_js + map_provider_dependencies
  end

  def map(items, options = {})
    options.symbolize_keys!
    Map.new(items, self, options).render
  end

  class Map < Struct.new(:items, :context, :options)
    def render
      return if locatable_items.empty?
      script = <<-JS
        var map = function(layer_constructor, map_tiles, div_id, center, zoom, marker_color, rawMarkers, should_fit_bounds) {
          var layer = new layer_constructor(map_tiles);
          var map = new L.Map(div_id, {
              center: new L.LatLng(center[0], center[1]),
              zoom: zoom,
              attributionControl: false
          });
          L.control.attribution ({
            position: 'bottomright',
            prefix: false
          }).addTo(map);

          map.addLayer(layer);

          var venueIcon = L.AwesomeMarkers.icon({
            icon: 'star',
            color: marker_color
          })

          var markers = rawMarkers.map(function(m) {
            return L.marker([m.latitude, m.longitude], { title: m.title, icon: venueIcon}).bindPopup(m.popup);
          });
          var markerGroup = L.featureGroup(markers);
          markerGroup.addTo(map);

          if(should_fit_bounds) {
            map.fitBounds(markerGroup.getBounds());
          }
        };
        map(#{layer_constructor}, "#{map_tiles}", "#{div_id}", #{center}, #{zoom}, "#{marker_color}", #{markers.to_json}, #{should_fit_bounds});
      JS

      map_div + context.javascript_tag(script)
    end

    private

    def map_div
      context.content_tag(:div, "", id: div_id)
    end

    def div_id
      options[:id] || 'map'
    end

    def zoom
      options[:zoom] || 14
    end

    def center
      (options[:center] || locatable_items.first.location)
    end

    def should_fit_bounds
      locatable_items.count > 1 && options[:center].blank?
    end

    def markers
      Array(locatable_items).map { |locatable_item|
        if location = locatable_item.location
          {
            latitude: location[0],
            longitude: location[1],
            title: locatable_item.title,
            popup: context.link_to(locatable_item.title, locatable_item)
          }
        end
      }.compact
    end

    def marker_color
      SECRETS.mapping['marker_color']
    end

    def locatable_items
      @locatable_items ||= Array(items).select {|i| i.location.present? }
    end

    def layer_constructor
      constructor_map = {
        "stamen"  => "L.StamenTileLayer",
        "mapbox"  => "L.mapbox.tileLayer",
        "esri"    => "L.esri.basemapLayer",
        "google"  => "L.Google",
        "leaflet" => "L.tileLayer",
      }
      constructor_map[context.map_provider]
    end

    def map_tiles
      (SECRETS.mapping && SECRETS.mapping["tiles"]) || 'terrain'
    end
  end

  alias_method :google_map, :map
end
