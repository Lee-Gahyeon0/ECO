package com.example.back.recommendation;

import java.util.List;

public record RecommendationRequest(
        List<String> items,
        Double lat,
        Double lng
) {
}