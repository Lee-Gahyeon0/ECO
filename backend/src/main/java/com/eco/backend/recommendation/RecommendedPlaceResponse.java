package com.example.back.recommendation;

public record RecommendedPlaceResponse(
        String placeName,
        String placeType,
        String address,
        Double lat,
        Double lng,
        String reason
) {
}