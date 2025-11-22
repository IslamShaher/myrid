import folium
import json

# Data from the API response and user request
request_data = {
    "start_lat": 30.046,
    "start_lng": 31.23,
    "end_lat": 30.105,
    "end_lng": 31.36
}

api_response = {
    "success": True,
    "start_stop": {
        "id": 10,
        "name": "Ramses Hilton",
        "latitude": "30.0503650",
        "longitude": "31.2320411",
        "distance": 523.6166486966131
    },
    "end_stop": {
        "id": 22,
        "name": "Leonardo Ristorante",
        "latitude": "30.1066692",
        "longitude": "31.3649767",
        "distance": 513.4524867475858
    },
    "matched_routes": [
        {
            "id": 2,
            "name": "Dokki → Sheraton Heliopolis",
            "code": "DSH01",
            "stops": [
                {"id": 6, "name": "Rose Hotel", "latitude": "30.0388148", "longitude": "31.2103418", "pivot": {"order": 1}},
                {"id": 7, "name": "Banque Du Caire", "latitude": "30.0428566", "longitude": "31.2119131", "pivot": {"order": 2}},
                {"id": 8, "name": "Anglo American Hospital", "latitude": "30.0463530", "longitude": "31.2216344", "pivot": {"order": 3}},
                {"id": 9, "name": "Cairo Tower", "latitude": "30.0465220", "longitude": "31.2242989", "pivot": {"order": 4}},
                {"id": 10, "name": "Ramses Hilton", "latitude": "30.0503650", "longitude": "31.2320411", "pivot": {"order": 5}},
                {"id": 11, "name": "El Tawheed El Togareya", "latitude": "30.0508237", "longitude": "31.2518615", "pivot": {"order": 6}},
                {"id": 12, "name": "Khan El-Khalili", "latitude": "30.0477386", "longitude": "31.2622538", "pivot": {"order": 7}},
                {"id": 13, "name": "National Bank of Egypt", "latitude": "30.0485374", "longitude": "31.2717568", "pivot": {"order": 8}},
                {"id": 14, "name": "General Authority for Investments", "latitude": "30.0711765", "longitude": "31.2963999", "pivot": {"order": 9}},
                {"id": 15, "name": "Fair Zone", "latitude": "30.0732570", "longitude": "31.3009800", "pivot": {"order": 10}},
                {"id": 16, "name": "Image Home Department Store", "latitude": "30.0798290", "longitude": "31.3147057", "pivot": {"order": 11}},
                {"id": 17, "name": "Military Factories Club", "latitude": "30.0822406", "longitude": "31.3194895", "pivot": {"order": 12}},
                {"id": 18, "name": "On The Run (Orouba)", "latitude": "30.0848464", "longitude": "31.3257490", "pivot": {"order": 13}},
                {"id": 19, "name": "Baron Hotel Cairo", "latitude": "30.0861069", "longitude": "31.3316670", "pivot": {"order": 14}},
                {"id": 20, "name": "Tolip El Galaa Hotel", "latitude": "30.0984475", "longitude": "31.3489093", "pivot": {"order": 15}},
                {"id": 21, "name": "Le Marche", "latitude": "30.1003244", "longitude": "31.3507396", "pivot": {"order": 16}},
                {"id": 22, "name": "Leonardo Ristorante", "latitude": "30.1066692", "longitude": "31.3649767", "pivot": {"order": 17}},
                {"id": 23, "name": "Sheraton Apartment 41", "latitude": "30.1038995", "longitude": "31.3710777", "pivot": {"order": 18}}
            ]
        }
    ]
}

# Create a map centered between start and end points
center_lat = (request_data["start_lat"] + request_data["end_lat"]) / 2
center_lng = (request_data["start_lng"] + request_data["end_lng"]) / 2
m = folium.Map(location=[center_lat, center_lng], zoom_start=13)

# 1. Plot User Requested Start/End Points (Blue Markers)
folium.Marker(
    [request_data["start_lat"], request_data["start_lng"]],
    popup="User Start Location",
    icon=folium.Icon(color="blue", icon="user")
).add_to(m)

folium.Marker(
    [request_data["end_lat"], request_data["end_lng"]],
    popup="User Destination",
    icon=folium.Icon(color="blue", icon="flag")
).add_to(m)

# 2. Plot Matched Route
route = api_response["matched_routes"][0]
route_coordinates = []

for stop in route["stops"]:
    lat = float(stop["latitude"])
    lng = float(stop["longitude"])
    route_coordinates.append([lat, lng])
    
    # Color code stops: Green for pickup, Red for dropoff, Gray for others
    color = "gray"
    icon = "info-sign"
    popup_text = f"{stop['name']} (Order: {stop['pivot']['order']})"
    
    if stop["id"] == api_response["start_stop"]["id"]:
        color = "green"
        icon = "play"
        popup_text = f"PICKUP: {stop['name']}"
    elif stop["id"] == api_response["end_stop"]["id"]:
        color = "red"
        icon = "stop"
        popup_text = f"DROPOFF: {stop['name']}"
        
    folium.Marker(
        [lat, lng],
        popup=popup_text,
        icon=folium.Icon(color=color, icon=icon)
    ).add_to(m)

# Draw the route path
folium.PolyLine(
    route_coordinates,
    color="purple",
    weight=5,
    opacity=0.7,
    tooltip=route["name"]
).add_to(m)

# 3. Draw Walking Lines (Dashed)
# Walk to Pickup
pickup_lat = float(api_response["start_stop"]["latitude"])
pickup_lng = float(api_response["start_stop"]["longitude"])
folium.PolyLine(
    [[request_data["start_lat"], request_data["start_lng"]], [pickup_lat, pickup_lng]],
    color="green",
    weight=3,
    dash_array="5, 10",
    tooltip="Walk to Pickup"
).add_to(m)

# Walk from Dropoff
dropoff_lat = float(api_response["end_stop"]["latitude"])
dropoff_lng = float(api_response["end_stop"]["longitude"])
folium.PolyLine(
    [[dropoff_lat, dropoff_lng], [request_data["end_lat"], request_data["end_lng"]]],
    color="red",
    weight=3,
    dash_array="5, 10",
    tooltip="Walk to Destination"
).add_to(m)

# Save map
output_file = "shuttle_route_map.html"
m.save(output_file)
print(f"Map saved to {output_file}")
