library(sf)
library(osmdata)
library(dplyr)
library(leaflet)
library(sfnetworks)
library(lwgeom)
library(tidygraph)
library(igraph)

city_name <- "Bucharest"
river_name <- "Dâmbovița"
epsg_code <- 32635  # UTM zone 35N
bbox_buffer <- 2000

bb <- osmdata::getbb(city_name)
# bb |> class()

bbox <- bb |> as.vector()
names(bbox) <- c("xmin", "ymin", "xmax", "ymax")
# class(bbox)
bbox <- st_bbox(bbox, crs = st_crs(4326)) |>
    st_as_sfc() |> 
    st_transform(epsg_code)
bbox_expanded <- bbox |> 
    st_buffer(bbox_buffer)

# plot(bbox_expanded, border = "red")
# plot(bbox, add = TRUE, border = "blue")

osmdata_as_sf <- function(key, value, bb){
    bb |>
        opq() |>
        add_osm_feature(key = key, value = value) |>
        osmdata_sf()
}

getGeomLatLon <- function(x) st_transform(x, 4326) |> st_geometry()

waterways <- osmdata_as_sf("waterway", "river", bb)
waterways

waterway <- waterways$osm_multilines |>
    filter(name == river_name) |>
    st_transform(epsg_code) |>
    st_geometry() |> 
    st_intersection(st_buffer(bbox, bbox_buffer + 1000))

leaflet() |>
    addTiles() |>
    addPolylines(data = getGeomLatLon(waterway), color="blue")

water <- osmdata_as_sf("natural", "water", bb)

leaflet() |>
    addTiles() |>
    addPolylines(data = getGeomLatLon(water$osm_lines), color="blue", group="osm_lines") |>
    addPolygons(data = getGeomLatLon(water$osm_polygons), color="red", group="osm_polygons") |>
    addPolygons(data = getGeomLatLon(water$osm_multipolygons), color="black", group="osm_multipolygons") |>
    addLayersControl(overlayGroups=c("osm_lines", "osm_polygons", "osm_multipolygons"))

waterbody <- bind_rows(water$osm_polygons, water$osm_multipolygons) |>
    st_transform(epsg_code) |>
    st_filter(waterway, .predicate = st_intersects) |>
    st_geometry() |>
    st_union()

leaflet() |>
    addTiles() |>
    addPolylines(data = getGeomLatLon(waterway), color="blue") |>
    addPolygons(data = getGeomLatLon(waterbody), color="red")

buffer_dist <- 500  # distance (in m) from the water stream

corridor_initial <- c(waterway, waterbody) |>
    st_buffer(buffer_dist) |>
    st_union()

leaflet() |>
    addTiles() |>
    addPolygons(data = getGeomLatLon(corridor_initial))

# ----

highways_value <- c("motorway", "primary", "secondary", "tertiary")
highways <- osmdata_as_sf("highway", highways_value, bb)

# route_value <- c("road")
# route <- osmdata_as_sf("route", route_value, bb)

# cast polygons (closed streets) into lines
poly_to_lines <- highways$osm_polygons |>
    st_cast("LINESTRING")
# include road segments found as route:road in OSM
# routes <- route$osm_lines |>
    # st_intersection(st_transform(bbox_expanded, 4326)) |> 
    # filter(highway %in% highways_value) |> 
    # st_cast("LINESTRING")
# combine all features in one data frame
highways_lines <- highways$osm_lines |>
    bind_rows(poly_to_lines) 

# create network, only keeping "highway" column
net <- highways_lines |>
    select("highway") |>
    as_sfnetwork(directed = FALSE) |> 
    st_transform(epsg_code)

getNodes <- function(net) net |> activate("nodes") |> st_geometry()
getEdges <- function(net) net |> activate("edges") |> st_geometry()

leaflet() |>
    addTiles() |>
    addPolylines(data = getEdges(net) |> getGeomLatLon(), color = "black") |>
    addCircles(data = getNodes(net) |> getGeomLatLon(), color = "red") |>
    addPolygons(data = getGeomLatLon(corridor_initial), color = "blue")

# ----
# split the AoI using the waterway
areas <- bbox_expanded |>
    st_split(waterway) |>
    st_collection_extract()

vertices <- bbox_expanded |>
    st_boundary() |>
    st_intersection(corridor_initial) |>
    st_cast("POINT")

area <- areas[1]

not_intersects <- function(x, y) !st_intersects(x, y)

trim <- function(net, area, corridor_initial){
    net |>
        activate("nodes") |>
        # select all nodes in the given areas
        st_filter(area, .predicate = st_intersects) |>
        # drop all nodes in the initial corridor
        st_filter(corridor_initial, .predicate = not_intersects)
}

trimmed <- trim(net, area, corridor_initial)

#' Simplify the graph
#'
#' Remove loops and double-edge connections
#' https://luukvdmeer.github.io/sfnetworks/articles/sfn02_preprocess_clean.html#simplify-network
simplify <- function(net){
    net|>
        activate("edges") |>
        # reorder the edges so that the shortest is kept
        arrange(edge_length()) |>
        filter(!edge_is_multiple()) |>
        filter(!edge_is_loop())
}


clean <- function(net){
    net |>
        simplify() |>
        # subdivide edges by adding missing nodes
        # https://luukvdmeer.github.io/sfnetworks/articles/sfn02_preprocess_clean.html#subdivide-edges
        convert(to_spatial_subdivision) |>
        # remove pseudo-nodes
        # https://luukvdmeer.github.io/sfnetworks/articles/sfn02_preprocess_clean.html#smooth-pseudo-nodes
        convert(to_spatial_smooth)
}

cleaned <- clean(trimmed)

calc_weights <- function(net){
    net |>
        activate("edges") |>
        mutate(weight = edge_length())
}

network <- calc_weights(cleaned) |> 
    activate("nodes") |> 
    filter(group_components() == 1)

get_target_points <- function(vertices, area, threshold = 0.0001){
    vertices |>
        st_as_sf() |>
        # keep threshold to check which points  intersect the polygons
        st_filter(area, .predicate = st_is_within_distance, dist = threshold) |>
        st_geometry()
}

get_corridor_edge <- function(network, area, vertices){
    # determine start and endpoint
    target_points <- get_target_points(vertices, area)
    
    # find shortest path
    paths <- st_network_paths(
        network,
        from = target_points[1],
        to = target_points[2],
        weights = "weight",
        type = "shortest"
    )
    
    edges <- network |> activate("edges") |> st_geometry()
    edge_path <- paths |> pull(edge_paths) |> unlist()
    edges[edge_path]
}

corridor_edge_1 <- get_corridor_edge(network, area, vertices)

area <- areas[2]

trimmed <- trim(net, area, corridor_initial)
cleaned <- clean(trimmed)
network <- calc_weights(cleaned) |> 
    activate("nodes") |> 
    filter(group_components() == 1)
corridor_edge_2 <- get_corridor_edge(network_connected, area, vertices)

city_boundary <- osmdata_as_sf("place", "city", bb)

city_boundary <- city_boundary$osm_multipolygons |> 
    st_geometry() |> st_transform(epsg_code)

opq(getbb("Bucharest")) |> 
    add_osm_feature("place", "city")

# river <- corridor_edge_2 |>
#     st_union() |>
#     st_cast("POINT") |>
#     st_sf(ID = "river")
# 
# start <- river[1, ]
# end <- river[nrow(river), ]
# 
# net_lines <- net |> 
#     activate("edges")
# 
# start_line <- st_filter(net_lines, start) |> 
#     st_as_sf() |> 
#     st_geometry()
# 
# end_line <- st_filter(net_lines, end) |> 
#     st_as_sf() |> 
#     st_geometry()


plot(city_boundary |> st_boundary())
plot(st_union(corridor_edge_1, corridor_edge_2), col = "red", add = TRUE)

corridor_edges <- st_union(corridor_edge_1, corridor_edge_2)

city_boundary |> 
    st_split(corridor_edges) |> 
    st_collection_extract("POLYGON") |> 
    st_as_sf() |> 
    st_filter(waterway, .predicate = st_intersects)
  
