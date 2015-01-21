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
    Map.new(items, self, options).render
  end

  class Map < Struct.new(:items, :context, :options)
    def render
      options.symbolize_keys!

      if locatable_items.present?
        script = <<-JS
          var layer = new #{layer_constructor}("#{map_tiles}");
          var map = new L.Map("#{div_id}", {
              center: new L.LatLng(#{center}),
              zoom: #{zoom},
              attributionControl: false
          });
          L.control.attribution ({
            position: 'bottomright',
            prefix: false
          }).addTo(map);

          map.addLayer(layer);

          var venueIcon = L.AwesomeMarkers.icon({
            icon: 'star',
            color: '#{marker_color}'
          })

          var markers = [#{markers}];
          var markerGroup = L.featureGroup(markers);
          markerGroup.addTo(map);

          if(#{should_fit_bounds}) {
            map.fitBounds(markerGroup.getBounds());
          }
        JS

        map_div + context.javascript_tag(script)
      end
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
      (options[:center] || locatable_items.first.location).join(", ")
    end

    def should_fit_bounds
      locatable_items.count > 1 && options[:center].blank?
    end

    def markers
      Array(locatable_items).map { |locatable_item|
        location = locatable_item.location

        if location
          latitude = location[0]
          longitude = location[1]
          title = locatable_item.title
          popup = context.link_to(locatable_item.title, locatable_item)

          "L.marker([#{latitude}, #{longitude}], {title: '#{context.j title}', icon: venueIcon}).bindPopup('#{context.j popup}')"
        end
      }.compact.join(", ")
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
